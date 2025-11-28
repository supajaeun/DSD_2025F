/*******************************************************************
  - Project          : Reconfigurable FIR Filter (Team Project)
  - Module           : CtrlFsm.v (Updated)
  - Description      : 2-MAC Optimization & Timing Safe FSM
*******************************************************************/

/*
전달 시 강조 포인트 
카운터 분리: 쓰기용(rCoeff_cnt, 21번)과 읽기용(rAddr_cnt, 11번) 카운터를 헷갈리지 않게 따로 만들었습니다.
SRAM 주소 출력 (oAddr_Fsm):
**쓰기 모드(COEFFWR)**에서는 0~20까지 쭉 나옵니다.
**읽기 모드(LOOP)**에서는 0~10까지만 나옵니다.
(SRAM 모듈 쪽에서 이 주소를 받아서 SRAM1/SRAM2 중 어디를 활성화할지 결정하는 로직은 Top 모듈이나 SRAM Wrapper에서 처리해야 합니다.)
Timing Fix: OUTPUT 상태 이후 rNxtState = S_WREND로 가는 부분이 코드에 반영되어 있습니다. 이 부분을 꼭 살려야 합니다.
*/


`timescale 1ns/10ps

module CtrlFsm (
    // Clock & Reset
    input  wire       iClk,
    input  wire       iRsn,

    // Control Flags
    input  wire       iUpdateFlag,   // 계수 업데이트 요청
    input  wire       iEnSample600k, // 600kHz 샘플링 타이밍 신호

    // SRAM Control Output
    output reg        oCsn_Fsm,      // Chip Select
    output reg        oWrn_Fsm,      // Write Enable (Low Active)
    output reg  [4:0] oAddr_Fsm,     // Address (0~20까지 커버해야 하므로 5bit)

    // Accumulator & Output Control
    output reg        oEnOut         // 최종 결과 출력 Enable
    
    // (필요 시 MAC 제어 신호 등 추가)
);

    // ====================================================
    // 1. State Definition
    // ====================================================
    localparam S_IDLE    = 3'd0;
    localparam S_COEFFWR = 3'd1;
    localparam S_WREND   = 3'd2;
    localparam S_FETCH   = 3'd3;
    localparam S_LOOP    = 3'd4; // 2-MAC 최적화 핵심 구간
    localparam S_FLUSH   = 3'd5;
    localparam S_SUM     = 3'd6;
    localparam S_OUTPUT  = 3'd7;

    reg [2:0] rCurState, rNxtState;

    // ====================================================
    // 2. Internal Counters
    // ====================================================
    reg [4:0] rCoeff_cnt; // 계수 쓰기용 카운터 (0~20)
    reg [3:0] rAddr_cnt;  // 읽기 루프용 카운터 (0~10) -> 2 MAC 구조

    // ====================================================
    // 3. Sequential Logic: State Update
    // ====================================================
    always @(posedge iClk) begin
        if (!iRsn) rCurState <= S_IDLE;
        else       rCurState <= rNxtState;
    end

    // ====================================================
    // 4. Combinational Logic: Next State Logic
    // ====================================================
    always @(*) begin
        case (rCurState)
            S_IDLE: begin
                if (iUpdateFlag) rNxtState = S_COEFFWR;
                else             rNxtState = S_IDLE;
            end

            S_COEFFWR: begin
                // 계수 21개(0~20) 다 썼으면 WREND로 이동
                if (rCoeff_cnt == 5'd21) rNxtState = S_WREND;
                else                     rNxtState = S_COEFFWR;
            end

            S_WREND: begin
                if (iUpdateFlag)       rNxtState = S_COEFFWR; // 업데이트 요청 시 복귀
                else if (iEnSample600k) rNxtState = S_FETCH;   // [수정1] 타이밍 신호 감지 시 시작
                else                   rNxtState = S_WREND;
            end

            S_FETCH: begin
                rNxtState = S_LOOP;
            end

            S_LOOP: begin
                // [수정2] 2-MAC 최적화: 11번(0~10)만 돌고 종료
                if (rAddr_cnt == 4'd10) rNxtState = S_FLUSH;
                else                    rNxtState = S_LOOP;
            end

            S_FLUSH:  rNxtState = S_SUM;

            S_SUM:    rNxtState = S_OUTPUT;

            S_OUTPUT: begin
                // [수정3] 중복 계산 방지를 위해 무조건 WREND로 복귀
                if (iUpdateFlag) rNxtState = S_COEFFWR;
                else             rNxtState = S_WREND;
            end

            default: rNxtState = S_IDLE;
        endcase
    end

    // ====================================================
    // 5. Output Logic & Counter Control
    // ====================================================
    
    // (1) rCoeff_cnt 제어 (쓰기 카운터)
    always @(posedge iClk) begin
        if (!iRsn) rCoeff_cnt <= 0;
        else if (rCurState == S_COEFFWR) begin
            if (rCoeff_cnt < 21) rCoeff_cnt <= rCoeff_cnt + 1;
        end
        else if (rCurState == S_WREND) begin 
            // WREND 상태에서 다시 쓰기 모드로 갈 준비 (초기화)
            if (iUpdateFlag) rCoeff_cnt <= 0;
        end
    end

    // (2) rAddr_cnt 제어 (읽기 카운터)
    always @(posedge iClk) begin
        if (!iRsn) rAddr_cnt <= 0;
        else if (rCurState == S_FETCH) rAddr_cnt <= 0; // 초기화
        else if (rCurState == S_LOOP) begin
            if (rAddr_cnt < 10) rAddr_cnt <= rAddr_cnt + 1;
        end
    end

    // (3) SRAM Interface Output
    always @(*) begin
        // 기본값
        oCsn_Fsm  = 1'b1; // Disable
        oWrn_Fsm  = 1'b1; // Read mode
        oAddr_Fsm = 5'd0;

        case (rCurState)
            S_COEFFWR: begin
                oCsn_Fsm  = 1'b0; // Active
                oWrn_Fsm  = 1'b0; // Write mode
                oAddr_Fsm = rCoeff_cnt;
            end
            
            S_LOOP, S_FETCH: begin
                oCsn_Fsm  = 1'b0; // Active
                oWrn_Fsm  = 1'b1; // Read mode
                oAddr_Fsm = {1'b0, rAddr_cnt}; // 0~10번지 읽기
            end
        endcase
    end

    // (4) Output Enable
    always @(*) begin
        if (rCurState == S_OUTPUT) oEnOut = 1'b1;
        else                       oEnOut = 1'b0;
    end

endmodule