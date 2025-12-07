/*******************************************************************
  - Project          : 2025 Team Project
  - File name        : PreAdd_MacUnit.v
  - Description      : MAC with Pre-adder for Symmetric FIR
  - Owner            : JunSuKo
  - Revision history : 2025.11.30
                       2025.12.06
                       2025.12.08
*******************************************************************/
`timescale 1ns/10ps

module Mac #(
    parameter WIDTH      = 16,   // Coefficient Width
    parameter DATA_WIDTH = 3,    // Input Data Width (Symbol)
    parameter OUT_WIDTH  = 23    // Output Accumulator Width
) (
    // Clock & Reset
    input  wire                     iClk12M,
    input  wire                     iRsn,

    // Control Signals
    input  wire                     iEnAdd,     // New Calc Start (Load)
    input  wire                     iEnAcc,     // Accumulate
    input  wire                     iEnMul,     // Multiply Enable
    input  wire                     iIsCenter,  // 1: Center Tap (No add), 0: Symmetric Pair (Pre-add)

    // Data Inputs
    input  signed [DATA_WIDTH-1:0]  iDelayHead, // Delay chain 대칭 데이터 (예: x[n])
    input  signed [DATA_WIDTH-1:0]  iDelayTail, // Delay chain 대칭 데이터 (예: x[n-32])
    input  signed [WIDTH-1:0]       iCoeff,     // Coefficient

    // Output
    output wire signed [OUT_WIDTH-1:0]  oMac
);

    //==========================================================================
    // Variable Declaration
    //==========================================================================
    // 1. Sign Extension & Pre-adder Wires
    wire signed [DATA_WIDTH:0]      wDelayHead_ex; // 저장을 4bit로 하기 때문에 1bit 확장 (3bit -> 4bit)
    wire signed [DATA_WIDTH:0]      wDelayTail_ex; // 저장을 4bit로 하기 때문에 1bit 확장 (3bit -> 4bit)
    wire signed [DATA_WIDTH:0]      wPreAddResult; // 덧셈 결과 (최대 4bit)

    // 2. Multiplier Wires
    wire signed [WIDTH+DATA_WIDTH:0] wMulResult;   // 16bit * 4bit = 20bit result

    // 3. Accumulator Register
    reg  signed [OUT_WIDTH-1:0]     rAcc;

    //==========================================================================
    // Functional Logic
    //==========================================================================

    // 1. Pre-Adder Logic
    // 오버플로우 방지를 위해 1비트 sign extension하여 계산
    assign wDelayHead_ex = {iDelayHead[DATA_WIDTH-1], iDelayHead};
    assign wDelayTail_ex = {iDelayTail[DATA_WIDTH-1], iDelayTail};

    // iIsCenter가 1이면 Tail을 더하지 않음 (Center Tap 처리), 0이면 Head + Tail
    assign wPreAddResult = (iIsCenter) ? wDelayHead_ex : (wDelayHead_ex + wDelayTail_ex);

    // 2. Multiplier Logic
    // (Pre-added Value) * Coefficient
    // iEnMul이 0일 때는 0을 출력하여 불필요한 스위칭 방지
    assign wMulResult = (iEnMul) ? (wPreAddResult * iCoeff) : {(WIDTH+DATA_WIDTH+1){1'b0}};

    // 3. Accumulator Logic
    always @(posedge iClk12M or negedge iRsn) begin
        if (!iRsn) begin
            rAcc <= {(OUT_WIDTH){1'b0}};
        end else begin
            if (iEnAdd) begin
                // 새로운 연산 시작: 기존 값 무시하고 현재 곱셈 결과 Load
                rAcc <= {{ (OUT_WIDTH-(WIDTH+DATA_WIDTH+1)){wMulResult[WIDTH+DATA_WIDTH]} }, wMulResult}; // wMulResult(20bit)를 rAcc(23bit)에 sign-extension 하여 할당
            end else if (iEnAcc) begin
                // 누적 연산: 기존 rAcc + 현재 곱셈 결과
                rAcc <= rAcc + {{ (OUT_WIDTH-(WIDTH+DATA_WIDTH+1)){wMulResult[WIDTH+DATA_WIDTH]} }, wMulResult};
            end
        end
    end

    // 4. Output Assignment
    assign oMac = rAcc;

endmodule