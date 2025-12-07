/*******************************************************************
  - Project          : 2025 Team Project
  - File name        : DelayChain.v
  - Description      : 40-tap Delay Chain (Shift Register)
  - Owner            : JunSuKo
  - Revision history : 2025.11.30
                       2025.12.06 
                       2025.12.08
*******************************************************************/
`timescale 1ns/10ps

module DelayChain #(
  // Parameter
  parameter WIDTH = 3, 
  parameter DEPTH = 32
) (
  // Clock & Reset
  input                 iClk12M,                
  input                 iRsn,   

  // Shift Enable Signal (from FSM)
  input                 iEnDelay,

  // Filter Input (Sample Data)
  input     [WIDTH-1:0] iFirIn, 

  // Delay Chain Outputs (To MAC)         
  // [수정] rDelay -> oDelay (Output Port Naming)
  output reg [WIDTH-1:0] oDelay1,  oDelay2,  oDelay3,  oDelay4,
  output reg [WIDTH-1:0] oDelay5,  oDelay6,  oDelay7,  oDelay8,
  output reg [WIDTH-1:0] oDelay9,  oDelay10, oDelay11, oDelay12,
  output reg [WIDTH-1:0] oDelay13, oDelay14, oDelay15, oDelay16,
  output reg [WIDTH-1:0] oDelay17, oDelay18, oDelay19, oDelay20,
  output reg [WIDTH-1:0] oDelay21, oDelay22, oDelay23, oDelay24,
  output reg [WIDTH-1:0] oDelay25, oDelay26, oDelay27, oDelay28,
  output reg [WIDTH-1:0] oDelay29, oDelay30, oDelay31, oDelay32,
  output reg [WIDTH-1:0] oDelay33
);

  // ====================================================================
  // Fir filter delay chain with Sample rate (600kHz) 
  // ====================================================================
  always @(posedge iClk12M or negedge iRsn)
  begin
    if (!iRsn) begin
      // 리셋 시 모든 딜레이 0으로 초기화
      oDelay1  <= 0; oDelay2  <= 0; oDelay3  <= 0; oDelay4  <= 0;
      oDelay5  <= 0; oDelay6  <= 0; oDelay7  <= 0; oDelay8  <= 0;
      oDelay9  <= 0; oDelay10 <= 0; oDelay11 <= 0; oDelay12 <= 0;
      oDelay13 <= 0; oDelay14 <= 0; oDelay15 <= 0; oDelay16 <= 0;
      oDelay17 <= 0; oDelay18 <= 0; oDelay19 <= 0; oDelay20 <= 0;
      oDelay21 <= 0; oDelay22 <= 0; oDelay23 <= 0; oDelay24 <= 0;
      oDelay25 <= 0; oDelay26 <= 0; oDelay27 <= 0; oDelay28 <= 0;
      oDelay29 <= 0; oDelay30 <= 0; oDelay31 <= 0; oDelay32 <= 0;
      oDelay33 <= 0;
    end 
    else if (iEnDelay) begin
      // Shift Operation
      oDelay1  <= iFirIn;
      oDelay2  <= oDelay1;
      oDelay3  <= oDelay2;
      oDelay4  <= oDelay3;
      oDelay5  <= oDelay4;
      oDelay6  <= oDelay5;
      oDelay7  <= oDelay6;
      oDelay8  <= oDelay7;
      oDelay9  <= oDelay8;
      oDelay10 <= oDelay9;
      oDelay11 <= oDelay10;
      oDelay12 <= oDelay11;
      oDelay13 <= oDelay12;
      oDelay14 <= oDelay13;
      oDelay15 <= oDelay14;
      oDelay16 <= oDelay15;
      oDelay17 <= oDelay16;
      oDelay18 <= oDelay17;
      oDelay19 <= oDelay18;
      oDelay20 <= oDelay19;
      oDelay21 <= oDelay20;
      oDelay22 <= oDelay21;
      oDelay23 <= oDelay22;
      oDelay24 <= oDelay23;
      oDelay25 <= oDelay24;
      oDelay26 <= oDelay25;
      oDelay27 <= oDelay26;
      oDelay28 <= oDelay27;
      oDelay29 <= oDelay28;
      oDelay30 <= oDelay29;
      oDelay31 <= oDelay30;
      oDelay32 <= oDelay31;
      oDelay33 <= oDelay32;
    end
  end

endmodule