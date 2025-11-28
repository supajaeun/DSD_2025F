/*******************************************************************
  - Project          : 2024 Team Project
  - File name        : Mul.v
  - Description      : Performs multiply operations for FIR filter (10 taps).
  - Owner            : seoyeonKim
  - Revision history : 1) 2024.11.19  
*******************************************************************/
module Mul #(parameter WIDTH = 16, ADDR_WIDTH = 5) ( // ADDR_WIDTH를 5로 설정
    input wire iClk12M,                  // 클럭 신호
    input wire iRsn,                     // 리셋 신호
    input wire signed [2:0] wDelay1, wDelay2, wDelay3, wDelay4, wDelay5, wDelay6, wDelay7, wDelay8, wDelay9, wDelay10, // 딜레이 입력
    input wire signed [WIDTH-1:0] wCoeff, // 계수 입력
    input wire signed wEnMul,                   // 곱셈 활성화 신호
    output reg signed [WIDTH-1:0] Mul          // 최종 MUL 출력
);

    // 내부 레지스터 선언
    reg [WIDTH-1:0] Mul_FF;
    reg [WIDTH-1:0] rDelay;

    // 곱셈 활성화 블록
    always @(posedge iClk12M or negedge iRsn) begin
        if (!iRsn) begin
            Mul <= 0;
        end 
	else if (wEnMul) begin
            Mul <= Mul_FF;
    	end
            // Selection 값을 증가시켜 순차적으로 Mul 및 Addr 출력 변경
	else begin
            	Mul <= 0;
	end
    end

    // 선택 상태에 따라 Mul 및 Addr 출력 결정
    always @(*) begin
            Mul_FF = (wDelay1 + wDelay2 + wDelay3 + wDelay4 + wDelay5 + wDelay6 + wDelay7 + wDelay8 + wDelay9 + wDelay10) * wCoeff;
    end

endmodule
