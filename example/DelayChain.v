/*******************************************************************
  - Project          : 2024 Team Project
  - File name        : DelayChain.v
  - Description      : Implements a delay chain with 40 delays of fixed 3-bit width.
  - Owner            : Kimseoyeon
  - Revision history : 1) 2024.11.17 : Initial release
*******************************************************************/
module DelayChain #(parameter WIDTH = 3, DEPTH = 40) (
    input wire iClk12M,                  // 클럭 신호
    input wire iRsn,                     // 리셋 신호
    input wire iEnSample600k,            // 딜레이 활성화 신호
    input wire wEnDelay,
    input wire [2:0] iFirIn,             // 3비트 입력 신호
    output reg [WIDTH-1:0] rDelay1,
    output reg [WIDTH-1:0] rDelay2, 
    output reg [WIDTH-1:0] rDelay3, 
    output reg [WIDTH-1:0] rDelay4,
    output reg [WIDTH-1:0] rDelay5,
    output reg [WIDTH-1:0] rDelay6, 
    output reg [WIDTH-1:0] rDelay7, 
    output reg [WIDTH-1:0] rDelay8,
    output reg [WIDTH-1:0] rDelay9,
    output reg [WIDTH-1:0] rDelay10,
    output reg [WIDTH-1:0] rDelay11, 
    output reg [WIDTH-1:0] rDelay12,
    output reg [WIDTH-1:0] rDelay13, 
    output reg [WIDTH-1:0] rDelay14,
    output reg [WIDTH-1:0] rDelay15,
    output reg [WIDTH-1:0] rDelay16, 
    output reg [WIDTH-1:0] rDelay17, 
    output reg [WIDTH-1:0] rDelay18,
    output reg [WIDTH-1:0] rDelay19,
    output reg [WIDTH-1:0] rDelay20,
    output reg [WIDTH-1:0] rDelay21,
    output reg [WIDTH-1:0] rDelay22, 
    output reg [WIDTH-1:0] rDelay23, 
    output reg [WIDTH-1:0] rDelay24,
    output reg [WIDTH-1:0] rDelay25,
    output reg [WIDTH-1:0] rDelay26, 
    output reg [WIDTH-1:0] rDelay27, 
    output reg [WIDTH-1:0] rDelay28,
    output reg [WIDTH-1:0] rDelay29,
    output reg [WIDTH-1:0] rDelay30,
    output reg [WIDTH-1:0] rDelay31,
    output reg [WIDTH-1:0] rDelay32, 
    output reg [WIDTH-1:0] rDelay33, 
    output reg [WIDTH-1:0] rDelay34,
    output reg [WIDTH-1:0] rDelay35,
    output reg [WIDTH-1:0] rDelay36, 
    output reg [WIDTH-1:0] rDelay37, 
    output reg [WIDTH-1:0] rDelay38,
    output reg [WIDTH-1:0] rDelay39,
    output reg [WIDTH-1:0] rDelay40
);
   reg [WIDTH-1:0] rDelay0;
   reg [WIDTH-1:0] rDelay;

  /*********************************************
   Fir filter delay chain with Sample rate (600kHz) 
  *********************************************/
  always @(posedge iClk12M or negedge iRsn) begin
    if (!iRsn) begin
      // 리셋 시 모든 딜레이 초기화
      rDelay   <= 3'b0; rDelay0  <= 3'b0;
      rDelay1  <= 3'b0; rDelay2  <= 3'b0; rDelay3  <= 3'b0; rDelay4  <= 3'b0;
      rDelay5  <= 3'b0; rDelay6  <= 3'b0; rDelay7  <= 3'b0; rDelay8  <= 3'b0;
      rDelay9  <= 3'b0; rDelay10 <= 3'b0; rDelay11 <= 3'b0; rDelay12 <= 3'b0;
      rDelay13 <= 3'b0; rDelay14 <= 3'b0; rDelay15 <= 3'b0; rDelay16 <= 3'b0;
      rDelay17 <= 3'b0; rDelay18 <= 3'b0; rDelay19 <= 3'b0; rDelay20 <= 3'b0;
      rDelay21 <= 3'b0; rDelay22 <= 3'b0; rDelay23 <= 3'b0; rDelay24 <= 3'b0;
      rDelay25 <= 3'b0; rDelay26 <= 3'b0; rDelay27 <= 3'b0; rDelay28 <= 3'b0;
      rDelay29 <= 3'b0; rDelay30 <= 3'b0; rDelay31 <= 3'b0; rDelay32 <= 3'b0;
      rDelay33 <= 3'b0; rDelay34 <= 3'b0; rDelay35 <= 3'b0; rDelay36 <= 3'b0;
      rDelay37 <= 3'b0; rDelay38 <= 3'b0; rDelay39 <= 3'b0; rDelay40 <= 3'b0;
    end else begin
      // 딜레이 체인
      rDelay  <= iFirIn;
      rDelay0  <= rDelay;
      rDelay1  <= rDelay0;
      rDelay2  <= rDelay1;
      rDelay3  <= rDelay2;
      rDelay4  <= rDelay3;
      rDelay5  <= rDelay4;
      rDelay6  <= rDelay5;
      rDelay7  <= rDelay6;
      rDelay8  <= rDelay7;
      rDelay9  <= rDelay8;
      rDelay10 <= rDelay9;
      rDelay11 <= rDelay10;
      rDelay12 <= rDelay11;
      rDelay13 <= rDelay12;
      rDelay14 <= rDelay13;
      rDelay15 <= rDelay14;
      rDelay16 <= rDelay15;
      rDelay17 <= rDelay16;
      rDelay18 <= rDelay17;
      rDelay19 <= rDelay18;
      rDelay20 <= rDelay19;
      rDelay21 <= rDelay20;
      rDelay22 <= rDelay21;
      rDelay23 <= rDelay22;
      rDelay24 <= rDelay23;
      rDelay25 <= rDelay24;
      rDelay26 <= rDelay25;
      rDelay27 <= rDelay26;
      rDelay28 <= rDelay27;
      rDelay29 <= rDelay28;
      rDelay30 <= rDelay29;
      rDelay31 <= rDelay30;
      rDelay32 <= rDelay31;
      rDelay33 <= rDelay32;
      rDelay34 <= rDelay33;
      rDelay35 <= rDelay34;
      rDelay36 <= rDelay35;
      rDelay37 <= rDelay36;
      rDelay38 <= rDelay37;
      rDelay39 <= rDelay38;
      rDelay40 <= rDelay39;
      end
  end
endmodule
