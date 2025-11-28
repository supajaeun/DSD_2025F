/*******************************************************************
  - Project          : 2024 Team Project
  - File name        : Accumulator.v
  - Description      : Accumulator
  - Owner            : Inchul.song
  - Revision history : 1) 2024.11.14 : Initial release
*******************************************************************/

`timescale 1ns/10ps

module Accumulator (

  // Clock & reset
  input                 iClk,     // Rising edge
  input                 iRsn,     // Sync. & low reset

  // SpSram read data from SpSram.v
  input       [15:0]    iRdDt,

  // Accumulator's input selection from CtrlFsm.v
  input       [1:0]     iInSel,

  // Final out enable form CtrlFsm.v
  input                 iEnOut,   // 2'b00: iRdDt & 16'h0
                                  // else : iRdDt & rAccDt[15:0]

  // Final out
  output reg  [15:0]    oAccOut

  );



  // wire & reg declaration
  wire   [15:0]         wAccInA;
  wire   [15:0]         wAccInB;
  wire   [15:0]         wAccSum;

  wire                  wSatCon_1;
  wire                  wSatCon_2;
  reg    [15:0]         wAccSumSat;

  reg    [15:0]         rAccDt;



  /*************************************************************/
  // Accumulator function
  /*************************************************************/
  // wAccInA : 16'h0        @ iInSel == 2'b00
  //           rAccDt[15:0] @ else
  assign wAccInA = (iInSel == 2'b00) ? 16'h0 : rAccDt[15:0];


  // wAccInB : iRdDt[15:0]
  assign wAccInB = (iInSel == 2'b00) ? 16'h0 : iRdDt[15:0];


  // wAccOut
  assign wAccSum = wAccInA[15:0] + wAccInB[15:0];



  /*************************************************************/
  // Saturation condition check
  /*************************************************************/
  // Condition #1
  assign wSatCon_1 =  (  wAccInA[15] == 1'b0
                      && wAccInB[15] == 1'b0
                      && wAccSum[15] == 1'b1) ? 1'b1 : 1'b0;

  // Condition #2
  assign wSatCon_2 =  (  wAccInA[15] == 1'b1
                      && wAccInB[15] == 1'b1
                      && wAccSum[15] == 1'b0) ? 1'b1 : 1'b0;


  // Output decision @ saturation condition
  // Condition #1 -> + Max
  // Condition #2 -> - Min
  // else         -> Normal result
  always @(*) begin
    if (wSatCon_1 == 1'b1)
        wAccSumSat = 16'h7FFF;  
    else if (wSatCon_2 == 1'b1)
        wAccSumSat = 16'h8000;
    else
        wAccSumSat = wAccSum[15:0];
  end



  /*************************************************************/
  // Accumulator update
  /*************************************************************/
  always @(posedge iClk)
  begin

    // Synchronous & low reset
    if (!iRsn)
      rAccDt <= 16'h0;
    else if (iInSel[1:0] == 2'h3)
      rAccDt <= wAccSumSat[15:0];
    else
      rAccDt <= 16'h0;
  end


  /*************************************************************/
  // Final output
  /*************************************************************/
  always @(posedge iClk)
  begin

    // Synchronous & low reset
    if (!iRsn)
      oAccOut <= 16'h0;
    else if (iEnOut == 1'b1)
      oAccOut <= wAccSumSat[15:0];
    else
      oAccOut <= 16'h0;
  end


endmodule
