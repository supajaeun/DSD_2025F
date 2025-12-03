`timescale 1ns/10ps

module Mac #(
    parameter WIDTH = 16,
    parameter OUT_WIDTH = 25 
) (
    input                         iClk12M,
    input                         iRsn,

    // Enable input (지연된 신호를 받아야 함)
    input                         iEnAdd,           // 1: Load (초기화)
    input                         iEnAcc,           // 1: Accumulate (누적)
    input                         iEnMul,           // [추가] 1: Multiply (곱셈)
    
    input  signed  [2:0]          iDelay,
    input  signed  [WIDTH-1:0]    iCoeff,

    output signed  [OUT_WIDTH-1:0] oMac
);

    // 내부 레지스터
    reg  signed [WIDTH+2:0]       rMulResult; // [18:0] (3bit * 16bit)
    reg  signed [OUT_WIDTH-1:0]   rAccResult; // [24:0]

    // 1. Multiply & Register (1 Clock Latency)
    // [수정] iEnMul 신호가 1일 때만 곱셈 수행
    always @(posedge iClk12M or negedge iRsn) begin
        if(!iRsn) begin
            rMulResult <= 0;
        end
        else begin
            if (iEnMul) rMulResult <= iCoeff * iDelay; // Enable: 곱하기 수행
            else        rMulResult <= 0;               // Disable: 0으로 클리어
        end
    end

    // 2. Accumulator (1 Clock Latency after Mul)
    // 저장된 곱셈 결과(rMulResult)를 더함
    always @(posedge iClk12M or negedge iRsn) begin
        if(!iRsn) begin
            rAccResult  <= {OUT_WIDTH{1'b0}};
        end
        else begin
            if (iEnAdd) begin
                rAccResult <= rMulResult; // Load (첫 번째 값은 그냥 대입)
            end
            else if (iEnAcc) begin
                rAccResult <= rAccResult + rMulResult; // Accumulate (이후 값은 더하기)
            end
        end
    end

    assign oMac = rAccResult;

endmodule