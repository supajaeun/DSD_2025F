`timescale 1ns/10ps

module DUT_top(
    input                 iClk12M,
    input                 iRsn,
    input                 iEnSample600k,
    input                 iCoeffUpdateFlag,
    input       [5:0]     iAddrRam,
    input       [15:0]    iWrDtRam,
    input       [5:0]     iNumOfCoeff,
    input       [2:0]     iFirIn,
    output      [15:0]    oFirOut,
    output      [15:0]    oWaveform
);

    // --- Wires ---
    wire            wEnDelay, wEnSum;
    wire            wEnAdd1, wEnAcc1, wEnMul1; 
    wire            wCsnRam1, wCsnRam2, wCsnRam3, wCsnRam4;
    wire            wWrnRam1, wWrnRam2, wWrnRam3, wWrnRam4;
    wire    [3:0]   wAddrRam1, wAddrRam2, wAddrRam3, wAddrRam4;
    wire    [15:0]  wWrDtRam1, wWrDtRam2, wWrDtRam3, wWrDtRam4;
    wire    [15:0]  wRdDtRam1, wRdDtRam2, wRdDtRam3, wRdDtRam4;

    // --- Pipeline Control Registers ---
    
    // [요청 2] EnDelay 레지스터 제거 (Wire 직접 사용) -> wEnDelay 사용
    
    // [요청 3] EnSum 레지스터 제거 (Wire 직접 사용) -> wEnSum 사용
    // reg rEnSum_d1... 삭제됨
    
    // [요청 1] Mul, Add, Acc는 1사이클 단축 (d2 -> d1)
    reg             rEnMul_d1; 
    reg             rEnAdd_d1; 
    reg             rEnAcc_d1; 
    
    // Address Pipeline (SRAM Read Latency 대응용)
    reg     [3:0]   rAddrRam1_d1, rAddrRam2_d1, rAddrRam3_d1, rAddrRam4_d1;

    // Delay & Mac Wires
    wire signed [2:0] wDelay1,  wDelay2,  wDelay3,  wDelay4,  wDelay5,  wDelay6,  wDelay7,  wDelay8;
    wire signed [2:0] wDelay9,  wDelay10, wDelay11, wDelay12, wDelay13, wDelay14, wDelay15, wDelay16;
    wire signed [2:0] wDelay17, wDelay18, wDelay19, wDelay20, wDelay21, wDelay22, wDelay23, wDelay24;
    wire signed [2:0] wDelay25, wDelay26, wDelay27, wDelay28, wDelay29, wDelay30, wDelay31, wDelay32;
    wire signed [2:0] wDelay33, wDelay34, wDelay35, wDelay36, wDelay37, wDelay38, wDelay39, wDelay40;
    
    reg  signed [2:0] rTargetDelay1, rTargetDelay2, rTargetDelay3, rTargetDelay4;
    wire signed [24:0] wMac1, wMac2, wMac3, wMac4;

    // --- Pipeline Logic ---
    always @(posedge iClk12M) begin
        if (!iRsn) begin
            // Pipeline Reset (d1만 사용)
            // rEnSum_d1 <= 0; // 삭제됨 (Wire 사용)
            rEnMul_d1 <= 0;
            rEnAdd_d1 <= 0;
            rEnAcc_d1 <= 0;
            
            rAddrRam1_d1 <= 0; rAddrRam2_d1 <= 0; rAddrRam3_d1 <= 0; rAddrRam4_d1 <= 0;

        end else begin
            // --------------------------------------------------------
            // Stage 1 (d1): SRAM 데이터 출력 시점 & 연산 수행
            // --------------------------------------------------------
            
            // [MAC 제어] d1 타이밍에 수행 (1사이클 단축)
            rEnMul_d1    <= wEnMul1; 
            rEnAdd_d1    <= wEnAdd1; 
            rEnAcc_d1    <= wEnAcc1; 
            
            // [SUM 제어] Wire(wEnSum) 사용하므로 레지스터 할당 불필요
            
            // [Address Latch] (MUX 선택용)
            rAddrRam1_d1 <= wAddrRam1; rAddrRam2_d1 <= wAddrRam2;
            rAddrRam3_d1 <= wAddrRam3; rAddrRam4_d1 <= wAddrRam4;
        end
    end

    // 1. FSM Instance
    FSM u_FSM (
        .iClk12M(iClk12M), .iRsn(iRsn),
        .iEnSample600k(iEnSample600k), .iCoeffUpdateFlag(iCoeffUpdateFlag),
        .iAddrRam(iAddrRam), .iWrDtRam(iWrDtRam), .iNumOfCoeff(iNumOfCoeff), .iFirIn(iFirIn),
        .oCsnRam1(wCsnRam1), .oCsnRam2(wCsnRam2), .oCsnRam3(wCsnRam3), .oCsnRam4(wCsnRam4),
        .oWrnRam1(wWrnRam1), .oWrnRam2(wWrnRam2), .oWrnRam3(wWrnRam3), .oWrnRam4(wWrnRam4),
        .oAddrRam1(wAddrRam1), .oAddrRam2(wAddrRam2), .oAddrRam3(wAddrRam3), .oAddrRam4(wAddrRam4),
        .oWrDtRam1(wWrDtRam1), .oWrDtRam2(wWrDtRam2), .oWrDtRam3(wWrDtRam3), .oWrDtRam4(wWrDtRam4),
        .oEnAdd1(wEnAdd1), .oEnAdd2(), .oEnAdd3(), .oEnAdd4(),
        .oEnAcc1(wEnAcc1), .oEnAcc2(), .oEnAcc3(), .oEnAcc4(),
        .oEnMul1(wEnMul1), .oEnMul2(), .oEnMul3(), .oEnMul4(),
        .oEnDelay(wEnDelay), .oEnSum(wEnSum)
    );

    // 2. DelayChain Instance
    // [요청 2 완료] wEnDelay(Wire) 바로 연결 (지연 없음)
    DelayChain u_DelayChain (
        .iClk12M(iClk12M), .iRsn(iRsn), .iEnDelay(wEnDelay), .iFirIn(iFirIn),
        .oDelay1(wDelay1), .oDelay2(wDelay2), .oDelay3(wDelay3), .oDelay4(wDelay4),
        .oDelay5(wDelay5), .oDelay6(wDelay6), .oDelay7(wDelay7), .oDelay8(wDelay8),
        .oDelay9(wDelay9), .oDelay10(wDelay10), .oDelay11(wDelay11), .oDelay12(wDelay12),
        .oDelay13(wDelay13), .oDelay14(wDelay14), .oDelay15(wDelay15), .oDelay16(wDelay16),
        .oDelay17(wDelay17), .oDelay18(wDelay18), .oDelay19(wDelay19), .oDelay20(wDelay20),
        .oDelay21(wDelay21), .oDelay22(wDelay22), .oDelay23(wDelay23), .oDelay24(wDelay24),
        .oDelay25(wDelay25), .oDelay26(wDelay26), .oDelay27(wDelay27), .oDelay28(wDelay28),
        .oDelay29(wDelay29), .oDelay30(wDelay30), .oDelay31(wDelay31), .oDelay32(wDelay32),
        .oDelay33(wDelay33), .oDelay34(wDelay34), .oDelay35(wDelay35), .oDelay36(wDelay36),
        .oDelay37(wDelay37), .oDelay38(wDelay38), .oDelay39(wDelay39), .oDelay40(wDelay40)
    );

    // 3. SRAM Instances
    SpSram #(.DATA_WIDTH(16), .SRAM_DEPTH(16)) u_SRAM1 (.iClk(iClk12M), .iRsn(iRsn), .iCsn(wCsnRam1), .iWrn(~wWrnRam1), .iAddr(wAddrRam1), .iWrDt(wWrDtRam1), .oRdDt(wRdDtRam1));
    SpSram #(.DATA_WIDTH(16), .SRAM_DEPTH(16)) u_SRAM2 (.iClk(iClk12M), .iRsn(iRsn), .iCsn(wCsnRam2), .iWrn(~wWrnRam2), .iAddr(wAddrRam2), .iWrDt(wWrDtRam2), .oRdDt(wRdDtRam2));
    SpSram #(.DATA_WIDTH(16), .SRAM_DEPTH(16)) u_SRAM3 (.iClk(iClk12M), .iRsn(iRsn), .iCsn(wCsnRam3), .iWrn(~wWrnRam3), .iAddr(wAddrRam3), .iWrDt(wWrDtRam3), .oRdDt(wRdDtRam3));
    SpSram #(.DATA_WIDTH(16), .SRAM_DEPTH(16)) u_SRAM4 (.iClk(iClk12M), .iRsn(iRsn), .iCsn(wCsnRam4), .iWrn(~wWrnRam4), .iAddr(wAddrRam4), .iWrDt(wWrDtRam4), .oRdDt(wRdDtRam4));

    // 4. MUX Logic (rAddrRam_d1 사용)
    always @(*) case(rAddrRam1_d1)
        4'd0: rTargetDelay1 = wDelay1;  4'd1: rTargetDelay1 = wDelay5;
        4'd2: rTargetDelay1 = wDelay9;  4'd3: rTargetDelay1 = wDelay13; 
        4'd4: rTargetDelay1 = wDelay17; 4'd5: rTargetDelay1 = wDelay21;
        4'd6: rTargetDelay1 = wDelay25; 4'd7: rTargetDelay1 = wDelay29; 
        4'd8: rTargetDelay1 = wDelay33; 4'd9: rTargetDelay1 = wDelay37; 
        default: rTargetDelay1 = 3'd0;
    endcase
    always @(*) case(rAddrRam2_d1)
        4'd0: rTargetDelay2 = wDelay2;  4'd1: rTargetDelay2 = wDelay6;
        4'd2: rTargetDelay2 = wDelay10; 4'd3: rTargetDelay2 = wDelay14; 
        4'd4: rTargetDelay2 = wDelay18; 4'd5: rTargetDelay2 = wDelay22; 
        4'd6: rTargetDelay2 = wDelay26; 4'd7: rTargetDelay2 = wDelay30; 
        4'd8: rTargetDelay2 = wDelay34; 4'd9: rTargetDelay2 = wDelay38; 
        default: rTargetDelay2 = 3'd0;
    endcase
    always @(*) case(rAddrRam3_d1)
        4'd0: rTargetDelay3 = wDelay3;  4'd1: rTargetDelay3 = wDelay7;
        4'd2: rTargetDelay3 = wDelay11; 4'd3: rTargetDelay3 = wDelay15; 
        4'd4: rTargetDelay3 = wDelay19; 4'd5: rTargetDelay3 = wDelay23; 
        4'd6: rTargetDelay3 = wDelay27; 4'd7: rTargetDelay3 = wDelay31; 
        4'd8: rTargetDelay3 = wDelay35; 4'd9: rTargetDelay3 = wDelay39; 
        default: rTargetDelay3 = 3'd0;
    endcase
    always @(*) case(rAddrRam4_d1)
        4'd0: rTargetDelay4 = wDelay4;  4'd1: rTargetDelay4 = wDelay8;
        4'd2: rTargetDelay4 = wDelay12; 4'd3: rTargetDelay4 = wDelay16; 
        4'd4: rTargetDelay4 = wDelay20; 4'd5: rTargetDelay4 = wDelay24; 
        4'd6: rTargetDelay4 = wDelay28; 4'd7: rTargetDelay4 = wDelay32; 
        4'd8: rTargetDelay4 = wDelay36; 4'd9: rTargetDelay4 = wDelay40; 
        default: rTargetDelay4 = 3'd0;
    endcase

    // 5. MAC Units
    // [요청 1 & 3 완료] d1 신호 사용 + 데이터 바로 사용(wRdDtRam, rTargetDelay)
    Mac #(.WIDTH(16), .OUT_WIDTH(25)) u_Mac1 (
        .iClk12M(iClk12M), .iRsn(iRsn), 
        .iEnAdd(rEnAdd_d1), .iEnAcc(rEnAcc_d1), // d1
        .iEnMul(rEnMul_d1),                     // d1
        .iDelay(rTargetDelay1), .iCoeff(wRdDtRam1), // 바로 연결
        .oMac(wMac1)
    );

    Mac #(.WIDTH(16), .OUT_WIDTH(25)) u_Mac2 (
        .iClk12M(iClk12M), .iRsn(iRsn), 
        .iEnAdd(rEnAdd_d1), .iEnAcc(rEnAcc_d1), 
        .iEnMul(rEnMul_d1), 
        .iDelay(rTargetDelay2), .iCoeff(wRdDtRam2), 
        .oMac(wMac2)
    );

    Mac #(.WIDTH(16), .OUT_WIDTH(25)) u_Mac3 (
        .iClk12M(iClk12M), .iRsn(iRsn), 
        .iEnAdd(rEnAdd_d1), .iEnAcc(rEnAcc_d1), 
        .iEnMul(rEnMul_d1), 
        .iDelay(rTargetDelay3), .iCoeff(wRdDtRam3), 
        .oMac(wMac3)
    );

    Mac #(.WIDTH(16), .OUT_WIDTH(25)) u_Mac4 (
        .iClk12M(iClk12M), .iRsn(iRsn), 
        .iEnAdd(rEnAdd_d1), .iEnAcc(rEnAcc_d1), 
        .iEnMul(rEnMul_d1), 
        .iDelay(rTargetDelay4), .iCoeff(wRdDtRam4), 
        .oMac(wMac4)
    );

    // 6. SUM
    // [요청 3 완료] wEnSum(Wire) 바로 연결 (지연 없음)
    Sum #(.IN_WIDTH(25), .OUT_WIDTH(16)) u_Sum (
        .iClk12M(iClk12M), .iRsn(iRsn),
        .iEnSum(wEnSum), // <--- 여기! Wire를 바로 연결
        .iMac1(wMac1), .iMac2(wMac2), .iMac3(wMac3), .iMac4(wMac4), .oFirOut(oFirOut)
    );

    assign oWaveform = wMac1[15:0]; 
endmodule