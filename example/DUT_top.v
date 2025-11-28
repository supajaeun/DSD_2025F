/*********************************************************************
  - Project          : FIR filter with Kaiser window
                       Digital System Design : final team project
  - File name        : DUT_top
  - Description      : top file for FIR filter
  - Owner            : Hwajeong.kim
  - Revision history : 1) 2024.11.26 : Initial release
*********************************************************************/

`timescale 1ns/10ps

module DUT_top(

  // Clock & reset
  input                 iClk12M,
  input                 iRsn,

  // In & out enable signals
  input                 iEnSample600k,
  input                 iCoeffUpdateFlag,

  // Data input  signals
  input       [5:0]     iAddrRam,
  input       [15:0]    iWrDtRam,
  input       [5:0]     iNumOfCoeff,
  input       [2:0]     iFirIn,
 
  //Data output
  output      [15:0]    oFirOut,
  output      [15:0]    oWaveform

  );


  /*********************************************
  // wire & reg declaration 
  *********************************************/

  //FSM ->sum, delay chain
  wire            wEnDelay;

  //SpSram wire declaration
  wire            wCsnRam1;
  wire            wWrnRam1;
  wire    [3:0]   wAddrRam1;
  wire    [15:0]  wWrDtRam1;
  wire    [15:0]  wRdDtRam1;

  wire            wCsnRam2;
  wire            wWrnRam2;
  wire    [3:0]   wAddrRam2;
  wire    [15:0]  wWrDtRam2;
  wire    [15:0]  wRdDtRam2;

  wire            wCsnRam3;
  wire            wWrnRam3;
  wire    [3:0]   wAddrRam3;
  wire    [15:0]  wWrDtRam3;
  wire    [15:0]  wRdDtRam3;

  wire            wCsnRam4;
  wire            wWrnRam4;
  wire    [3:0]   wAddrRam4;
  wire    [15:0]  wWrDtRam4;
  wire    [15:0]  wRdDtRam4;


  //First MAC wire declaration
  wire      wEnMul1;
  wire      wEnAdd1;
  wire      wEnAcc1;

  wire    [2:0]   wDelay1;
  wire    [2:0]   wDelay2;
  wire    [2:0]   wDelay3;
  wire    [2:0]   wDelay4;
  wire    [2:0]   wDelay5;
  wire    [2:0]   wDelay6;
  wire    [2:0]   wDelay7;
  wire    [2:0]   wDelay8;
  wire    [2:0]   wDelay9;
  wire    [2:0]   wDelay10;



  //Second MAC wire declaration
  wire      wEnMul2;
  wire      wEnAdd2;
  wire      wEnAcc2;

  wire    [2:0]   wDelay11;
  wire    [2:0]   wDelay12;
  wire    [2:0]   wDelay13;
  wire    [2:0]   wDelay14;
  wire    [2:0]   wDelay15;
  wire    [2:0]   wDelay16;
  wire    [2:0]   wDelay17;
  wire    [2:0]   wDelay18;
  wire    [2:0]   wDelay19;
  wire    [2:0]   wDelay20;



  //Third MAC wire declaration
  wire      wEnMul3;
  wire      wEnAdd3;
  wire      wEnAcc3;

  wire    [2:0]   wDelay21;
  wire    [2:0]   wDelay22;
  wire    [2:0]   wDelay23;
  wire    [2:0]   wDelay24;
  wire    [2:0]   wDelay25;
  wire    [2:0]   wDelay26;
  wire    [2:0]   wDelay27;
  wire    [2:0]   wDelay28;
  wire    [2:0]   wDelay29;
  wire    [2:0]   wDelay30;




  //Fourth MAC wire declaration
  wire      wEnMul4;
  wire      wEnAdd4;
  wire      wEnAcc4;

  wire    [2:0]   wDelay31;
  wire    [2:0]   wDelay32;
  wire    [2:0]   wDelay33;
  wire    [2:0]   wDelay34;
  wire    [2:0]   wDelay35;
  wire    [2:0]   wDelay36;
  wire    [2:0]   wDelay37;
  wire    [2:0]   wDelay38;
  wire    [2:0]   wDelay39;
  wire    [2:0]   wDelay40;


  //Sum wire declaration (MAC->SUM)
  wire    [15:0]    wMac1;
  wire    [15:0]    wMac2;
  wire    [15:0]    wMac3;
  wire    [15:0]    wMac4;


  //rMem wirte operation
  reg     [15:0]    rMem [0:4]; //메모리 선언 ?? 이거 내가 무슨 정신으로?
  reg     [15:0]    rRdDt;  //읽은 데이터 저장

  /*********************************************
  //For waveform
  *********************************************/
  wire    [15:0]    wOutMul1;
  wire    [15:0]    wOutMul2;
  wire    [15:0]    wOutMul3;
  wire    [15:0]    wOutMul4;

  assign oWaveform = wOutMul1 | wOutMul2 | wOutMul3 | wOutMul4;

  /*********************************************
  //Controller(FSM).v instantiation
  *********************************************/

  FSM FSM (

  // Clock & reset
  .iClk12M         (iClk12M),
  .iRsn            (iRsn),

  //Sample enable 600kHz
  .iEnSample600k   (iEnSample600k),

  //Flag
  .iCoeffUpdateFlag (iCoeffUpdateFlag),

  //Sram Control
  .iAddrRam         (iAddrRam[5:0]),
  .iWrDtRam         (iWrDtRam[15:0]),
  .iNumOfCoeff      (iNumOfCoeff[5:0]),
  .iFirIn           (iFirIn[2:0]),

  //SRAM Chip select
  .wCsnRam1         (wCsnRam1),
	.wCsnRam2         (wCsnRam2),
	.wCsnRam3         (wCsnRam3),
	.wCsnRam4         (wCsnRam4),

  // SRAM Write/Read select 
  .wWrnRam1         (wWrnRam1),
	.wWrnRam2         (wWrnRam2),
	.wWrnRam3         (wWrnRam3),
	.wWrnRam4         (wWrnRam4),

  //SRAM Address
  .wAddrRam1         (wAddrRam1),
	.wAddrRam2         (wAddrRam2),
	.wAddrRam3         (wAddrRam3),
	.wAddrRam4         (wAddrRam4),

  //SRAM WRITE Data
  .wWrDtRam1         (wWrDtRam1),
	.wWrDtRam2         (wWrDtRam2),
	.wWrDtRam3         (wWrDtRam3),
	.wWrDtRam4         (wWrDtRam4),

  //Multi Enable
  .wEnMul1         (wEnMul1),
	.wEnMul2         (wEnMul2),
	.wEnMul3         (wEnMul3),
	.wEnMul4         (wEnMul4),

  //Add Enable
  .wEnAdd1         (wEnAdd1),
	.wEnAdd2         (wEnAdd2),
	.wEnAdd3         (wEnAdd3),
	.wEnAdd4         (wEnAdd4),

  //Accum Enable
  .wEnAcc1         (wEnAcc1),
	.wEnAcc2         (wEnAcc2),
	.wEnAcc3         (wEnAcc3),
	.wEnAcc4         (wEnAcc4),

  .wEnDelay        (wEnDelay)

  );

/*************************************************************/
  // Delay chain instantiation 
/*************************************************************/
  DelayChain DelayChain (

  // Clock & reset
  .iClk12M         (iClk12M),
  .iRsn            (iRsn),

  // SP-SRAM Input & Output
  .iEnSample600k  (iEnSample600k),
  .iFirIn         (iFirIn[2:0]),
  .wEnDelay	  (wEnDelay),

  //output 연결. DelayChain (output reg)-> wDelay (wire 연결)
  .rDelay1         (wDelay1),
  .rDelay2         (wDelay2),
  .rDelay3         (wDelay3),
  .rDelay4         (wDelay4),
  .rDelay5         (wDelay5),
  .rDelay6         (wDelay6),
  .rDelay7         (wDelay7),
  .rDelay8         (wDelay8),
  .rDelay9         (wDelay9),
  .rDelay10        (wDelay10),

  .rDelay11        (wDelay11),
  .rDelay12        (wDelay12),
  .rDelay13        (wDelay13),
  .rDelay14        (wDelay14),
  .rDelay15        (wDelay15),
  .rDelay16        (wDelay16),
  .rDelay17        (wDelay17),
  .rDelay18        (wDelay18),
  .rDelay19        (wDelay19),
  .rDelay20        (wDelay20),

  .rDelay21        (wDelay21),
  .rDelay22        (wDelay22),
  .rDelay23        (wDelay23),
  .rDelay24        (wDelay24),
  .rDelay25        (wDelay25),
  .rDelay26        (wDelay26),
  .rDelay27        (wDelay27),
  .rDelay28        (wDelay28),
  .rDelay29        (wDelay29),
  .rDelay30        (wDelay30),
    
  .rDelay31        (wDelay31),
  .rDelay32        (wDelay32),
  .rDelay33        (wDelay33),
  .rDelay34        (wDelay34),
  .rDelay35        (wDelay35),
  .rDelay36        (wDelay36),
  .rDelay37        (wDelay37),
  .rDelay38        (wDelay38),
  .rDelay39        (wDelay39),
  .rDelay40        (wDelay40)


//Delay Chain으로 들어가는 wEnDelay 신호는 머지 .. 마치 merge sort..
  );



/*************************************************************/
  // MAC instantiation
/*************************************************************/
  Mac Mac1 ( 

  // Clock & reset
  .iClk12M         (iClk12M),
  .iRsn            (iRsn),

  //enable input
  .wEnMul         (wEnMul1),
  .wEnAdd         (wEnAdd1),
  .wEnAcc         (wEnAcc1),

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
  
  .wCoeff        (wRdDtRam1),
  .oMac          (wMac1[15:0]),
  .oOutMul	 (wOutMul1)
  );

/*************************************************************/
  // MAC instantiation
/*************************************************************/
  Mac Mac2 ( 

  // Clock & reset
  .iClk12M         (iClk12M),
  .iRsn            (iRsn),

  //enable input
  .wEnMul         (wEnMul2),
  .wEnAdd         (wEnAdd2),
  .wEnAcc         (wEnAcc2),

  // Delay chain to Mul inst
  .wDelay1       (wDelay11),
  .wDelay2       (wDelay12),
  .wDelay3       (wDelay13),
  .wDelay4       (wDelay14),
  .wDelay5       (wDelay15),
  .wDelay6       (wDelay16),
  .wDelay7       (wDelay17),
  .wDelay8       (wDelay18),
  .wDelay9       (wDelay19),
  .wDelay10      (wDelay20),
  
  .wCoeff        (wRdDtRam2),
  .oMac          (wMac2[15:0]),

  .oOutMul	 (wOutMul2)
  );

  /*************************************************************/
  // MAC instantiation
/*************************************************************/
  Mac Mac3 ( 

  // Clock & reset
  .iClk12M         (iClk12M),
  .iRsn            (iRsn),

  //enable input
  .wEnMul         (wEnMul3),
  .wEnAdd         (wEnAdd3),
  .wEnAcc         (wEnAcc3),

  // Delay chain to Mul inst
  .wDelay1       (wDelay21),
  .wDelay2       (wDelay22),
  .wDelay3       (wDelay23),
  .wDelay4       (wDelay24),
  .wDelay5       (wDelay25),
  .wDelay6       (wDelay26),
  .wDelay7       (wDelay27),
  .wDelay8       (wDelay28),
  .wDelay9       (wDelay29),
  .wDelay10      (wDelay30),
  
  .wCoeff        (wRdDtRam3),
  .oMac          (wMac3[15:0]),

  .oOutMul	 (wOutMul3)
  );

  /*************************************************************/
  // MAC instantiation
/*************************************************************/
  Mac Mac4 ( 

  // Clock & reset
  .iClk12M         (iClk12M),
  .iRsn            (iRsn),

  //enable input
  .wEnMul         (wEnMul4),
  .wEnAdd         (wEnAdd4),
  .wEnAcc         (wEnAcc4),

  // Delay chain to Mul inst
  .wDelay1       (wDelay31),
  .wDelay2       (wDelay32),
  .wDelay3       (wDelay33),
  .wDelay4       (wDelay34),
  .wDelay5       (wDelay35),
  .wDelay6       (wDelay36),
  .wDelay7       (wDelay37),
  .wDelay8       (wDelay38),
  .wDelay9       (wDelay39),
  .wDelay10      (wDelay40),
  
  .wCoeff        (wRdDtRam4),
  .oMac          (wMac4[15:0]),

  .oOutMul	 (wOutMul4)
  );





/*************************************************************/
  // SUM instantiation
/*************************************************************/
  Sum Sum (

  // Clock & reset
  .iClk12M           (iClk12M),
  .iRsn           (iRsn),

  .iEnSample600k  (iEnSample600k),
  .wEnDelay       (wEnDelay),

  //MAC->SUM 연결
  .wMac1          (wMac1),
  .wMac2          (wMac2),
  .wMac3          (wMac3),
  .wMac4          (wMac4),

  //최종 결과 출력.
  .oFirOut      (oFirOut)  //그냥 outport로 바로 연결해도 괜찮나?

  );



/*************************************************************/
  // SpSram instantiation
/*************************************************************/
  SpSram SRAM1 (

  // Clock & reset
  .iClk            (iClk12M),
  .iRsn            (iRsn),

  // SP-SRAM Input & Output
  .iCsn            (wCsnRam1),
  .iWrn            (wWrnRam1),
  .iAddr           (wAddrRam1[3:0]),

  .iWrDt           (wWrDtRam1[15:0]),
  .oRdDt           (wRdDtRam1[15:0])

  );


  SpSram SRAM2 (

  // Clock & reset
  .iClk            (iClk12M),
  .iRsn            (iRsn),

  // SP-SRAM Input & Output
  .iCsn            (wCsnRam2),
  .iWrn            (wWrnRam2),
  .iAddr           (wAddrRam2[3:0]),

  .iWrDt           (wWrDtRam2[15:0]),
  .oRdDt           (wRdDtRam2[15:0])

  );

  SpSram SRAM3 (

  // Clock & reset
  .iClk            (iClk12M),
  .iRsn            (iRsn),

  // SP-SRAM Input & Output
  .iCsn            (wCsnRam3),
  .iWrn            (wWrnRam3),
  .iAddr           (wAddrRam3[3:0]),

  .iWrDt           (wWrDtRam3[15:0]),
  .oRdDt           (wRdDtRam3[15:0])

  );

  SpSram SRAM4 (

  // Clock & reset
  .iClk            (iClk12M),
  .iRsn            (iRsn),

  // SP-SRAM Input & Output
  .iCsn            (wCsnRam4),
  .iWrn            (wWrnRam4),
  .iAddr           (wAddrRam4[3:0]),

  .iWrDt           (wWrDtRam4[15:0]),
  .oRdDt           (wRdDtRam4[15:0])

  );


endmodule
