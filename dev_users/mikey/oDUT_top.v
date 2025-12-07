/*******************************************************************
  - Project          : 2025 Team Project (Optimized & Cleaned)
  - File name        : DUT_top.v
  - Description      : 33-Tap Symmetric FIR (2 RAMs, 2 MACs)
  - Owner            : JunSuKo
  - Revision history : 2025.11.30
                       2025.12.06 
                       2025.12.08
*******************************************************************/
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
 //==========================================================================
 // Variable Declaration
 //==========================================================================

    // --- Control & SRAM Wires ---
    wire            wEnDelay, wEnSum;
    wire            wEnAdd1, wEnAcc1, wEnMul1; 
    wire            wCsnRam1, wCsnRam2;
    wire            wWrnRam1, wWrnRam2;
    wire    [3:0]   wAddrRam1, wAddrRam2;
    wire    [15:0]  wWrDtRam1, wWrDtRam2;
    wire    [15:0]  wRdDtRam1, wRdDtRam2;

    // --- Pipeline Registers ---
    reg             rEnMul_d1; 
    reg             rEnAdd_d1; 
    reg             rEnAcc_d1; 
    reg     [3:0]   rAddrRam1_d1, rAddrRam2_d1;

    // --- Delay Chain Wires (Strictly 33 Taps) ---
    wire signed [2:0] wDelay1,  wDelay2,  wDelay3,  wDelay4,  wDelay5,  wDelay6,  wDelay7,  wDelay8;
    wire signed [2:0] wDelay9,  wDelay10, wDelay11, wDelay12, wDelay13, wDelay14, wDelay15, wDelay16;
    wire signed [2:0] wDelay17, wDelay18, wDelay19, wDelay20, wDelay21, wDelay22, wDelay23, wDelay24;
    wire signed [2:0] wDelay25, wDelay26, wDelay27, wDelay28, wDelay29, wDelay30, wDelay31, wDelay32;
    wire signed [2:0] wDelay33;
    
    // --- Logic Signals ---
    reg signed [2:0] rDelayHead1, rDelayTail1;
    reg signed [2:0] rDelayHead2, rDelayTail2;
    wire             wIsCenter1;
    wire signed [24:0] wMac1, wMac2;

    // --- Pipeline Logic ---
    always @(posedge iClk12M) begin
        if (!iRsn) begin
            rEnMul_d1    <= 0; rEnAdd_d1    <= 0; rEnAcc_d1    <= 0;
            rAddrRam1_d1 <= 0; rAddrRam2_d1 <= 0; 
        end else begin
            rEnMul_d1    <= wEnMul1; 
            rEnAdd_d1    <= wEnAdd1; 
            rEnAcc_d1    <= wEnAcc1; 
            rAddrRam1_d1 <= wAddrRam1; 
            rAddrRam2_d1 <= wAddrRam2;
        end
    end

    // 1. FSM
    FSM u_FSM (
        .iClk12M(iClk12M), .iRsn(iRsn),
        .iEnSample600k(iEnSample600k), .iCoeffUpdateFlag(iCoeffUpdateFlag),
        .iAddrRam(iAddrRam), .iWrDtRam(iWrDtRam), .iNumOfCoeff(iNumOfCoeff), .iFirIn(iFirIn),
        .oCsnRam1(wCsnRam1), .oCsnRam2(wCsnRam2), 
        .oWrnRam1(wWrnRam1), .oWrnRam2(wWrnRam2), 
        .oAddrRam1(wAddrRam1), .oAddrRam2(wAddrRam2), 
        .oWrDtRam1(wWrDtRam1), .oWrDtRam2(wWrDtRam2), 
        .oEnAdd1(wEnAdd1), .oEnAcc1(wEnAcc1), .oEnMul1(wEnMul1), 
        .oEnDelay(wEnDelay), .oEnSum(wEnSum)
    );

    // 2. DelayChain (Strictly 33 Ports)
    DelayChain u_DelayChain (
        .iClk12M(iClk12M), .iRsn(iRsn), .iEnDelay(wEnDelay), .iFirIn(iFirIn),
        .oDelay1(wDelay1),   .oDelay2(wDelay2),   .oDelay3(wDelay3),   .oDelay4(wDelay4),
        .oDelay5(wDelay5),   .oDelay6(wDelay6),   .oDelay7(wDelay7),   .oDelay8(wDelay8),
        .oDelay9(wDelay9),   .oDelay10(wDelay10), .oDelay11(wDelay11), .oDelay12(wDelay12),
        .oDelay13(wDelay13), .oDelay14(wDelay14), .oDelay15(wDelay15), .oDelay16(wDelay16),
        .oDelay17(wDelay17), .oDelay18(wDelay18), .oDelay19(wDelay19), .oDelay20(wDelay20),
        .oDelay21(wDelay21), .oDelay22(wDelay22), .oDelay23(wDelay23), .oDelay24(wDelay24),
        .oDelay25(wDelay25), .oDelay26(wDelay26), .oDelay27(wDelay27), .oDelay28(wDelay28),
        .oDelay29(wDelay29), .oDelay30(wDelay30), .oDelay31(wDelay31), .oDelay32(wDelay32),
        .oDelay33(wDelay33) 
        // 34~40 Ports removed
    );

    // 3. SRAM
    SpSram #(.DATA_WIDTH(16), .SRAM_DEPTH(16)) u_SRAM1 (.iClk(iClk12M), .iRsn(iRsn), .iCsn(wCsnRam1), .iWrn(~wWrnRam1), .iAddr(wAddrRam1), .iWrDt(wWrDtRam1), .oRdDt(wRdDtRam1));
    SpSram #(.DATA_WIDTH(16), .SRAM_DEPTH(16)) u_SRAM2 (.iClk(iClk12M), .iRsn(iRsn), .iCsn(wCsnRam2), .iWrn(~wWrnRam2), .iAddr(wAddrRam2), .iWrDt(wWrDtRam2), .oRdDt(wRdDtRam2));

    // 4. MUX Logic (33 Taps, Center=17)
    always @(*) begin
        case(rAddrRam1_d1) 
            4'd0: begin rDelayHead1 = wDelay1;   rDelayTail1 = wDelay33; end
            4'd1: begin rDelayHead1 = wDelay3;   rDelayTail1 = wDelay31; end
            4'd2: begin rDelayHead1 = wDelay5;   rDelayTail1 = wDelay29; end
            4'd3: begin rDelayHead1 = wDelay7;   rDelayTail1 = wDelay27; end
            4'd4: begin rDelayHead1 = wDelay9;   rDelayTail1 = wDelay25; end
            4'd5: begin rDelayHead1 = wDelay11;  rDelayTail1 = wDelay23; end
            4'd6: begin rDelayHead1 = wDelay13;  rDelayTail1 = wDelay21; end
            4'd7: begin rDelayHead1 = wDelay15;  rDelayTail1 = wDelay19; end
            4'd8: begin rDelayHead1 = wDelay17;  rDelayTail1 = 3'd0;     end // Center
            default: begin rDelayHead1 = 3'd0;   rDelayTail1 = 3'd0;     end
        endcase
    end
    assign wIsCenter1 = (rAddrRam1_d1 == 4'd8);

    // [MAC 2] RAM2 (Odd) -> (2,32)...(16,18)
    always @(*) begin
        case(rAddrRam2_d1)
            4'd0: begin rDelayHead2 = wDelay2;   rDelayTail2 = wDelay32; end
            4'd1: begin rDelayHead2 = wDelay4;   rDelayTail2 = wDelay30; end
            4'd2: begin rDelayHead2 = wDelay6;   rDelayTail2 = wDelay28; end
            4'd3: begin rDelayHead2 = wDelay8;   rDelayTail2 = wDelay26; end
            4'd4: begin rDelayHead2 = wDelay10;  rDelayTail2 = wDelay24; end
            4'd5: begin rDelayHead2 = wDelay12;  rDelayTail2 = wDelay22; end
            4'd6: begin rDelayHead2 = wDelay14;  rDelayTail2 = wDelay20; end
            4'd7: begin rDelayHead2 = wDelay16;  rDelayTail2 = wDelay18; end
            default: begin rDelayHead2 = 3'd0;   rDelayTail2 = 3'd0;     end
        endcase
    end

    // 5. MAC Units
    Mac #(.WIDTH(16), .DATA_WIDTH(3), .OUT_WIDTH(25)) u_Mac1 (
        .iClk12M(iClk12M), .iRsn(iRsn), 
        .iEnAdd(rEnAdd_d1), .iEnAcc(rEnAcc_d1), .iEnMul(rEnMul_d1), 
        .iIsCenter(wIsCenter1), .iDelayHead(rDelayHead1), .iDelayTail(rDelayTail1), .iCoeff(wRdDtRam1), 
        .oMac(wMac1)
    );

    Mac #(.WIDTH(16), .DATA_WIDTH(3), .OUT_WIDTH(25)) u_Mac2 (
        .iClk12M(iClk12M), .iRsn(iRsn), 
        .iEnAdd(rEnAdd_d1), .iEnAcc(rEnAcc_d1), .iEnMul(rEnMul_d1), 
        .iIsCenter(1'b0), .iDelayHead(rDelayHead2), .iDelayTail(rDelayTail2), .iCoeff(wRdDtRam2), 
        .oMac(wMac2)
    );

    // 6. SUM
    Sum #(.IN_WIDTH(25), .OUT_WIDTH(16)) u_Sum (
        .iClk12M(iClk12M), .iRsn(iRsn), .iEnSum(wEnSum), 
        .iMac1(wMac1), .iMac2(wMac2), 
        .iMac3(25'd0), .iMac4(25'd0), 
        .oFirOut(oFirOut)
    );

    assign oWaveform = wMac1[15:0]; 
endmodule