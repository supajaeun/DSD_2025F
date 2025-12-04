`timescale 1ns/10ps

module FSM (
    input                 iClk12M,
    input                 iRsn,
    input                 iEnSample600k,
    input                 iCoeffUpdateFlag,
    input       [5:0]     iAddrRam,       
    input       [15:0]    iWrDtRam,
    input       [5:0]     iNumOfCoeff,
    input       [2:0]     iFirIn, // (사용되지 않음 - 경고 방지 위해 놔둠)

    output wire           oCsnRam1, oCsnRam2, oCsnRam3, oCsnRam4,
    output wire           oWrnRam1, oWrnRam2, oWrnRam3, oWrnRam4,
    output wire [3:0]     oAddrRam1, oAddrRam2, oAddrRam3, oAddrRam4,
    output wire [15:0]    oWrDtRam1, oWrDtRam2, oWrDtRam3, oWrDtRam4,

    output wire           oEnAdd1, oEnAdd2, oEnAdd3, oEnAdd4,
    output wire           oEnAcc1, oEnAcc2, oEnAcc3, oEnAcc4,
    output wire           oEnMul1, oEnMul2, oEnMul3, oEnMul4, 

    output wire           oEnDelay,
    output wire           oEnSum 
);

    // State Encoding
    localparam  IDLE        = 4'd0;
    localparam  COEFFWR     = 4'd1; 
    localparam  WREND       = 4'd2;
    localparam  LOOP        = 4'd3; 
    localparam  FLUSH       = 4'd4;
    localparam  SUM         = 4'd5;
    localparam  OUTPUT      = 4'd6; 

    reg    [3:0]    state, next_state;
    reg    [5:0]    rCoeff_cnt;
    reg    [5:0]    rNumOfCoeff;
    
    // [수정] for loop 대신 개별 레지스터로 선언 (합성 최적화)
    reg    [3:0]    rRdRam1, rRdRam2, rRdRam3, rRdRam4; 

    // for write logic
    wire   [1:0]    wWrBank = iAddrRam[1:0];
    wire   [3:0]    wWrAddr = iAddrRam[5:2];

    // --- State Register ---
    always @(posedge iClk12M or negedge iRsn) begin
        if (!iRsn) state <= IDLE;
        else       state <= next_state;
    end

    // --- Next State Logic ---
    always @(*) begin
        case (state)
            IDLE: 
                if (iCoeffUpdateFlag) next_state = COEFFWR;
                else if (iEnSample600k) next_state = LOOP; 
                else next_state = IDLE;
            COEFFWR: 
                if (!iCoeffUpdateFlag) next_state = WREND;
                else next_state = COEFFWR;
            WREND: 
                if (iCoeffUpdateFlag) next_state = COEFFWR;
                else if (iEnSample600k) next_state = LOOP; 
                else next_state = WREND;
            
            LOOP: 
                if (rCoeff_cnt >= rNumOfCoeff) next_state = FLUSH;
                else next_state = LOOP;
            FLUSH: next_state = SUM;
            SUM:   next_state = OUTPUT;
            OUTPUT: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // --- Output Logic (Combinational) ---
    assign oCsnRam1 = (state == LOOP || (state == COEFFWR && wWrBank == 0)) ? 1'b0 : 1'b1;
    assign oCsnRam2 = (state == LOOP || (state == COEFFWR && wWrBank == 1)) ? 1'b0 : 1'b1;
    assign oCsnRam3 = (state == LOOP || (state == COEFFWR && wWrBank == 2)) ? 1'b0 : 1'b1;
    assign oCsnRam4 = (state == LOOP || (state == COEFFWR && wWrBank == 3)) ? 1'b0 : 1'b1;

    assign oWrnRam1 = (state == COEFFWR && wWrBank == 0) ? 1'b1 : 1'b0;
    assign oWrnRam2 = (state == COEFFWR && wWrBank == 1) ? 1'b1 : 1'b0;
    assign oWrnRam3 = (state == COEFFWR && wWrBank == 2) ? 1'b1 : 1'b0;
    assign oWrnRam4 = (state == COEFFWR && wWrBank == 3) ? 1'b1 : 1'b0;

    // [수정] 배열 대신 개별 레지스터 사용
    assign oAddrRam1 = (state == COEFFWR && wWrBank == 0) ? wWrAddr : rRdRam1;
    assign oAddrRam2 = (state == COEFFWR && wWrBank == 1) ? wWrAddr : rRdRam2;
    assign oAddrRam3 = (state == COEFFWR && wWrBank == 2) ? wWrAddr : rRdRam3;
    assign oAddrRam4 = (state == COEFFWR && wWrBank == 3) ? wWrAddr : rRdRam4;

    assign oWrDtRam1 = (state == COEFFWR && wWrBank == 0) ? iWrDtRam : 16'd0;
    assign oWrDtRam2 = (state == COEFFWR && wWrBank == 1) ? iWrDtRam : 16'd0;
    assign oWrDtRam3 = (state == COEFFWR && wWrBank == 2) ? iWrDtRam : 16'd0;
    assign oWrDtRam4 = (state == COEFFWR && wWrBank == 3) ? iWrDtRam : 16'd0;

    // MAC Control Logic
    assign oEnMul1 = (state == LOOP || state == FLUSH);
    assign oEnMul2 = oEnMul1;
    assign oEnMul3 = oEnMul1;
    assign oEnMul4 = oEnMul1;

    assign oEnAcc1 = (state == LOOP || state == FLUSH); 
    assign oEnAcc2 = oEnAcc1;
    assign oEnAcc3 = oEnAcc1;
    assign oEnAcc4 = oEnAcc1;

    assign oEnAdd1 = ((state == LOOP || state == FLUSH) && rCoeff_cnt == 0); 
    assign oEnAdd2 = oEnAdd1;
    assign oEnAdd3 = oEnAdd1; 
    assign oEnAdd4 = oEnAdd1;

    assign oEnDelay = ((state == IDLE || state == WREND) && next_state == LOOP); 
    assign oEnSum   = (state == SUM);

    // --- Counter Logic (Sequential) ---
    // [수정] 비동기 리셋(negedge iRsn) 추가 (합성 필수)
    always @(posedge iClk12M or negedge iRsn) begin
        if (!iRsn) begin
            rCoeff_cnt  <= 6'd0;
            rNumOfCoeff <= 6'd0;
            // [수정] 명시적 초기화
            rRdRam1 <= 4'd0; rRdRam2 <= 4'd0; rRdRam3 <= 4'd0; rRdRam4 <= 4'd0;
        end
        else if (state == IDLE) begin
            rCoeff_cnt  <= 6'd0;
            rRdRam1 <= 4'd0; rRdRam2 <= 4'd0; rRdRam3 <= 4'd0; rRdRam4 <= 4'd0;
            
            if (iCoeffUpdateFlag) begin
                // 비트 연산자 우선순위 명확화
                rNumOfCoeff <= (iNumOfCoeff[1:0] == 0) ? (iNumOfCoeff >> 2) : ((iNumOfCoeff >> 2) + 1);
            end
        end
        
        else if ((state == IDLE || state == WREND) && next_state == LOOP) begin
            rCoeff_cnt <= 6'd0;
            rRdRam1 <= 4'd0; rRdRam2 <= 4'd0; rRdRam3 <= 4'd0; rRdRam4 <= 4'd0;
        end
        
        else if (state == LOOP) begin
            if (rCoeff_cnt < rNumOfCoeff) begin 
                rCoeff_cnt <= rCoeff_cnt + 6'd1;
                rRdRam1 <= rRdRam1 + 4'd1;
                rRdRam2 <= rRdRam2 + 4'd1;
                rRdRam3 <= rRdRam3 + 4'd1;
                rRdRam4 <= rRdRam4 + 4'd1;
            end
        end
        else if (state == OUTPUT) begin
            rCoeff_cnt <= 6'd0;
        end
    end

endmodule