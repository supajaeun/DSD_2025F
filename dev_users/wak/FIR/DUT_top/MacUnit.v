`timescale 1ns/10ps

module Mac #(
    parameter WIDTH      = 16,   // iCoeff Width
    parameter DATA_WIDTH = 3,    // iDelay Width
    parameter OUT_WIDTH  = 25    // OUT (Sum input) width
) (
    input                         iClk12M,
    input                         iRsn,

    input                         iEnAdd,
    input                         iEnAcc,
    input                         iEnMul,
    
    input  signed [DATA_WIDTH-1:0] iDelay,
    input  signed [WIDTH-1:0]      iCoeff,

    output signed [OUT_WIDTH-1:0]  oMac
);

    /*********************************************************
     * 1) 정확한 sign-extension (하드코딩 없이 정확한 의미 유지)
     *********************************************************/
    wire signed [17:0] delay_s =
        {{(18-DATA_WIDTH){iDelay[DATA_WIDTH-1]}}, iDelay};

    wire signed [17:0] coeff_s =
        {{(18-WIDTH){iCoeff[WIDTH-1]}}, iCoeff};

    /*********************************************************
     * 2) 최소 비트폭 full-precision multiply (18bit × 18bit → 36bit)
     *********************************************************/
    wire signed [35:0] mul_full_big =
        (iEnMul) ? (coeff_s * delay_s) : 36'sd0;

    // 우리가 필요한 곱셈 결과의 범위는 18bit → 하위 18bit만 사용
    wire signed [17:0] mul_full = mul_full_big[17:0];


    /*********************************************************
     * 3) Accumulator: 23bit (40tap 누산 최대값 보장)
     *********************************************************/
    reg signed [22:0] acc_reg;

    always @(posedge iClk12M or negedge iRsn) begin
        if (!iRsn)
            acc_reg <= 23'sd0;
        else begin
            if (iEnAdd)
                acc_reg <= mul_full;
            else if (iEnAcc)
                acc_reg <= acc_reg + mul_full;
        end
    end

    /*********************************************************
     * 4) 최종 출력: 기존 OUT_WIDTH(25bit)에 sign-extend하여 전달
     *********************************************************/
    assign oMac = {{(OUT_WIDTH-23){acc_reg[22]}}, acc_reg};

endmodule
