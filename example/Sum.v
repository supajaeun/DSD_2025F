
/*******************************************************************
  - Project          : 2024 Team Project
  - File name        : Sum.v
  - Description      : Aggregates concatenated MAC outputs to produce FIR filter result.
  - Owner            : seoyeonKim
  - Revision history : 1) 2024.11.19 : Added support for concatenated MAC inputs.
*******************************************************************/
module Sum #(parameter WIDTH = 16) (
    input wire iClk12M,                   // 클럭 신호
    input wire iRsn,                      // 리셋 신호
    input wire [WIDTH-1:0] wMac1,         // MAC1의 전체 출력
    input wire [WIDTH-1:0] wMac2,         // MAC2의 전체 출력
    input wire [WIDTH-1:0] wMac3,         // MAC3의 전체 출력
    input wire [WIDTH-1:0] wMac4,         // MAC4의 전체 출력
    input wire iEnSample600k,             // 샘플링 활성화 신호
    input wire wEnDelay,                  // 딜레이 활성화 신호
    output reg [WIDTH-1:0] oFirOut        // FIR 필터 최종 출력
);

    // 내부 레지스터 선언
    reg [WIDTH-1:0] finalSum;             // 최종 합산 결과
    
    // 합산 연산
        always @(posedge iClk12M or negedge iRsn) begin
            if (!iRsn) begin
                finalSum <= {WIDTH{1'b0}};    // 리셋 시 초기화
                oFirOut <= {WIDTH{1'b0}};    // 출력 초기화
            end else if (wEnDelay) begin
                 oFirOut <= wMac1 + wMac2 + wMac3 + wMac4; // 합산
            end
        end

endmodule
