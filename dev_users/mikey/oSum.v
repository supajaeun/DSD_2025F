/*******************************************************************
  - Project          : 2025 Team Project
  - File name        : Sum.v
  - Description      : Sum + Saturation Logic
  - Owner            : JunSuKo
  - Revision history : 2025.11.30
                       2025.12.06 
                       2025.12.08
*******************************************************************/
`timescale 1ns/10ps

module Sum #(
    parameter IN_WIDTH  = 23, //
    parameter OUT_WIDTH = 16  // Final Output Width (16bit)
) (
    input                       iClk12M,
    input                       iRsn,

    input signed [IN_WIDTH-1:0] iMac1,
    input signed [IN_WIDTH-1:0] iMac2,

    input                       iEnSum,

    output reg signed [OUT_WIDTH-1:0] oFirOut
);

    //==========================================================================
    // Variable Declaration
    //==========================================================================
    
    // 덧셈 결과: 입력(23bit) 2개를 더하면 최대 24bit가 되므로 +1 bit 확장
    wire signed [IN_WIDTH:0] wSumResult;

    // Saturation을 위한 최대/최소값 (16비트 범위 자동 계산)
    // 16비트일 경우: 32767, -32768
    localparam signed [IN_WIDTH:0] MAX_VAL =  (1 <<< (OUT_WIDTH-1)) - 1;
    localparam signed [IN_WIDTH:0] MIN_VAL = -(1 <<< (OUT_WIDTH-1));

    //==========================================================================
    // Functional Logic
    //==========================================================================
    
    assign wSumResult = $signed(iMac1) + $signed(iMac2);

    always @(posedge iClk12M or negedge iRsn) begin
        if (!iRsn) begin
            oFirOut <= {OUT_WIDTH{1'b0}};
        end else if (iEnSum) begin
            // Saturation Logic (Overflow Check)
            if (wSumResult > MAX_VAL)
                oFirOut <= MAX_VAL[OUT_WIDTH-1:0]; // 16'h7FFF (Max Positive)
            else if (wSumResult < MIN_VAL)
                oFirOut <= MIN_VAL[OUT_WIDTH-1:0]; // 16'h8000 (Min Negative)
            else
                oFirOut <= wSumResult[OUT_WIDTH-1:0];
        end
    end

endmodule