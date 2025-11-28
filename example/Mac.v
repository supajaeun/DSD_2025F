/*******************************************************************
  - Project          : 2024 Team Project
  - File name        : Mac.v
  - Description      : Mac Top file
  - Owner            : Hwajeong.kim
  - Revision history : 1) 2024.11.26 : Initial release
*******************************************************************/

`timescale 1ns/10ps

module Mac(

  // Clock & reset
  input                 iClk12M,          // Rising edge
  input                 iRsn,          // Sync. & low reset

  // Enable input
  input                 wEnMul, 
  input                 wEnAdd,
  input                 wEnAcc,

  //delay input
  input  [2:0]          wDelay1,
  input  [2:0]          wDelay2,
  input  [2:0]          wDelay3,
  input  [2:0]          wDelay4,
  input  [2:0]          wDelay5,
  input  [2:0]          wDelay6,
  input  [2:0]          wDelay7,
  input  [2:0]          wDelay8,
  input  [2:0]          wDelay9,
  input  [2:0]          wDelay10,

  //coefficient input
  input  [15:0]         wCoeff, 

  //output 
  output  [15:0]        oOutMul,
  output  [15:0]        oMac

  );



  /*********************************************/
  // 내부 wire 선언.
  /*********************************************/
  wire    [15:0]      wOutMul; // Mul output wire
  wire    [1:0]       iInSel;
  
  //Acc에 필요한 신호 생성
  assign iInSel={wEnAdd, wEnAcc};
  assign wEnOut= (iInSel==2'b11) ? 1'b1 : 1'b0;
  assign oOutMul = wOutMul;
  /*********************************************/
  // Mul.v instantiation
  /*********************************************/
  Mul Mul (

  // Clock & reset
  .iClk12M         (iClk12M),
  .iRsn            (iRsn),

  //Enable
  .wEnMul         (wEnMul),

  // Delay chain to Mul inst
  .wDelay1       (wDelay1),
  .wDelay2       (wDelay2),
  .wDelay3       (wDelay3),
  .wDelay4       (wDelay4),
  .wDelay5       (wDelay5),
  .wDelay6       (wDelay6),
  .wDelay7       (wDelay7),
  .wDelay8       (wDelay8),
  .wDelay9       (wDelay9),
  .wDelay10      (wDelay10),
  
  .wCoeff        (wCoeff),

  //Mul output
  .Mul           (wOutMul)


  );

   /*********************************************/
  // Accumulator.v instantiation
  /*********************************************/
  Accumulator Acc (

  // Clock & reset
  .iClk           (iClk12M),
  .iRsn           (iRsn),

  // mul output
  .iRdDt          (wOutMul[15:0]),

  //Acc control
  .iInSel         (iInSel),

  //Enable 
  .iEnOut         (wEnOut),

  //Acc output
  .oAccOut        (oMac[15:0])

  );






endmodule
