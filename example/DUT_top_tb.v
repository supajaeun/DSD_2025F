/*********************************************************************
  - Project          : Team Project (Configurable FIR filter w/ Kaiser window)
  - File name        : configurable_fir_filter_tb.v
  - Description      : Testbench top file for configurable_fir_filter.v
  - Owner            : SeoALee
  - Revision history : 1) 2024.11.16 : Initial release
                       2) 2024.11.23 : Revision
                       3) 2024.12.01 : Final Revision
*********************************************************************/

`timescale 1ns / 10ps

module DUT_top_tb;

    /***********************************************
    // wire & register
    ***********************************************/
    reg iClk12M;
    reg iRsn;
    reg iEnSample600k;
    reg iCoeffUpdateFlag;
    reg [5:0] iAddrRam;
    reg [15:0] iWrDtRam;
    reg [5:0] iNumOfCoeff;
    reg [2:0] iFirIn;
    wire [15:0] oFirOut;
    wire [15:0] oWaveform;


    /***********************************************
    // FSM instantiation
    ***********************************************/
    DUT_top dut (
        .iClk12M(iClk12M),
        .iRsn(iRsn),
        .iEnSample600k(iEnSample600k),
        .iCoeffUpdateFlag(iCoeffUpdateFlag),
        .iAddrRam(iAddrRam),
        .iWrDtRam(iWrDtRam),
        .iNumOfCoeff(iNumOfCoeff),
        .iFirIn(iFirIn),
        .oFirOut(oFirOut),
        .oWaveform(oWaveform)
    );


    /***********************************************
        // Initialization
    ***********************************************/
    initial
    begin
        iEnSample600k = 1'b0;
        iCoeffUpdateFlag = 1'b0;
        iWrDtRam = 16'b0;
        iAddrRam = 6'b0;
        iNumOfCoeff = 6'd0;
        iFirIn = 3'b0;
    end
    

    /***********************************************
    // Clock define
    ***********************************************/
    initial 
    begin
        iClk12M <= 1'b0;
    end

    always
    begin
        #(83.333/2) iClk12M <= ~iClk12M;
    end


    /***********************************************
    // Sync. & active high reset define
    ***********************************************/
    initial
    begin
        iRsn = 1'b1;

        repeat(4) @(posedge iClk12M)
        iRsn = 1'b0;

        repeat(2) @(posedge iClk12M)
        $display("--------------------------------------->");
        $display("**** Active low Reset released !!!! ****");
        iRsn = 1'b1;
        $display("--------------------------------------->");
    end


    /***********************************************
    // 600kHz sample enable making
    ***********************************************/
    reg [4:0] rSampleCnt;

    always @(posedge iClk12M)
    begin
        if (!iRsn)
            rSampleCnt <= 5'd0;
        else if (rSampleCnt == 5'd19)
            rSampleCnt <= 5'd0;
        else
            rSampleCnt <= rSampleCnt + 5'd1;
    end
    
    always @(*) begin
    iEnSample600k = (rSampleCnt == 5'd19) ? 1'b1 : 1'b0;
    end


    /***********************************************
    // FSM Test Scenario
    ***********************************************/
    integer i, j, temp;
    reg [5:0] address_array [0:39]; 
    reg [15:0] coeff_array [0:10]; 
    
    initial
    begin
        iNumOfCoeff = 6'd21;
        iCoeffUpdateFlag = 1'b0;
        iFirIn = 3'b000;

        #500;

        @(posedge iClk12M);
        iCoeffUpdateFlag = 1'b1;

        iAddrRam = 6'd0; iWrDtRam = 16'b0000_0000_0000_1100; @(posedge iClk12M);
        iAddrRam = 6'd1; iWrDtRam = 16'b0000_0000_0000_0000; @(posedge iClk12M);
        iAddrRam = 6'd2; iWrDtRam = 16'b1111_1111_1110_1101; @(posedge iClk12M);
        iAddrRam = 6'd3; iWrDtRam = 16'b0000_0000_0001_0111; @(posedge iClk12M);
        iAddrRam = 6'd4; iWrDtRam = 16'b0000_0000_0000_0000; @(posedge iClk12M);
        iAddrRam = 6'd5; iWrDtRam = 16'b1111_1111_1110_1100; @(posedge iClk12M);
        iAddrRam = 6'd6; iWrDtRam = 16'b0000_0000_0011_0000; @(posedge iClk12M);
        iAddrRam = 6'd7; iWrDtRam = 16'b0000_0000_0000_0000; @(posedge iClk12M);
        iAddrRam = 6'd8; iWrDtRam = 16'b1111_1111_1001_1011; @(posedge iClk12M);
        iAddrRam = 6'd9; iWrDtRam = 16'b0000_0001_1001_1011; @(posedge iClk12M);
        iAddrRam = 6'd10; iWrDtRam = 16'b0000_0011_1111_0011; @(posedge iClk12M);
        iAddrRam = 6'd11; iWrDtRam = 16'b0000_0001_1001_1011; @(posedge iClk12M);
        iAddrRam = 6'd12; iWrDtRam = 16'b1111_1111_1001_1011; @(posedge iClk12M);
        iAddrRam = 6'd13; iWrDtRam = 16'b0000_0000_0000_0000; @(posedge iClk12M);
        iAddrRam = 6'd14; iWrDtRam = 16'b0000_0000_0011_0000; @(posedge iClk12M);
        iAddrRam = 6'd15; iWrDtRam = 16'b1111_1111_1110_1100; @(posedge iClk12M);
        iAddrRam = 6'd16; iWrDtRam = 16'b0000_0000_0000_0000; @(posedge iClk12M);
        iAddrRam = 6'd17; iWrDtRam = 16'b0000_0000_0001_0111; @(posedge iClk12M);
        iAddrRam = 6'd18; iWrDtRam = 16'b1111_1111_1110_1101; @(posedge iClk12M);
        iAddrRam = 6'd19; iWrDtRam = 16'b0000_0000_0000_0000; @(posedge iClk12M);
        iAddrRam = 6'd20; iWrDtRam = 16'b0000_0000_0000_1100;

        @(posedge iClk12M);
        iCoeffUpdateFlag = 1'b0;

        #1000;

        repeat (200) @(posedge iClk12M && iEnSample600k);
        iFirIn <= 3'b000;

	    @(posedge iClk12M);
        iFirIn <= 3'b000;

        $display("------------------------------------------------->");
        $display("OOOOO 3'b001 is received from testbench  !!! OOOOO");
        $display("------------------------------------------------->");

        repeat (1) @(posedge iClk12M && iEnSample600k);
        iFirIn <= 3'b001;
        repeat (1) @(posedge iClk12M && iEnSample600k);
        iFirIn <= 3'b000;

        repeat (200) @(posedge iClk12M && iEnSample600k);

        $display("------------------------------------------------->");
        $display("OOOOO 3'b111 is received from testbench  !!! OOOOO");
        $display("------------------------------------------------->");

        repeat (1) @(posedge iClk12M && iEnSample600k);
        iFirIn <= 3'b111;
        repeat (1) @(posedge iClk12M && iEnSample600k);
        iFirIn <= 3'b000;

        repeat (200) @(posedge iClk12M && iEnSample600k);

        $display("-------------------------------------------------->"); 
        $display("OOOOO FIR Filter Simulation has been done !!! OOOOO");
        $display("-------------------------------------------------->");

        #1000

        @(posedge iClk12M);
        iCoeffUpdateFlag = 1'b0;
        iEnSample600k = 1'b1;

        repeat (21) begin  
            @(posedge iClk12M);
            $display ("coefficient reading... : %h", iWrDtRam);
        end

        #1000

        @(posedge iEnSample600k);
        $display("MAC computationing ...");

        repeat (1) @(posedge iClk12M && iEnSample600k);
        $display("FIR filter final output : %b", oFirOut);

        #1000
        @(posedge iClk12M);
        iRsn = 1'b0;
        @(posedge iClk12M);
        iRsn = 1'b1;
        @(posedge iClk12M);
        iNumOfCoeff = 6'd9;
        iCoeffUpdateFlag = 1'b0;
        iFirIn = 3'b000;

        #500;
    
        @(posedge iClk12M);
        iCoeffUpdateFlag = 1'b1;
        
        iAddrRam = 6'd0; iWrDtRam = 16'b1111_1111_1001_1011; @(posedge iClk12M);
        iAddrRam = 6'd1; iWrDtRam = 16'b0000_0011_1111_0011; @(posedge iClk12M);
        iAddrRam = 6'd2; iWrDtRam = 16'b1111_1111_1100_1100; @(posedge iClk12M);
        iAddrRam = 6'd3; iWrDtRam = 16'b0000_0000_0000_0000; @(posedge iClk12M);
        iAddrRam = 6'd4; iWrDtRam = 16'b1111_1110_0000_1111; @(posedge iClk12M);
        iAddrRam = 6'd5; iWrDtRam = 16'b0000_0001_0110_0110; @(posedge iClk12M);
        iAddrRam = 6'd6; iWrDtRam = 16'b0000_1111_0000_1101; @(posedge iClk12M);
        iAddrRam = 6'd7; iWrDtRam = 16'b1111_1111_1000_0011; @(posedge iClk12M);
        iAddrRam = 6'd8; iWrDtRam = 16'b0000_0000_1001_1000; 

        @(posedge iClk12M);
        iCoeffUpdateFlag = 1'b0;
        #1000;

        repeat (200) @(posedge iClk12M && iEnSample600k);
        iFirIn <= 3'b000;

        $display("------------------------------------------------->");
        $display("OOOOO 3'b001 is received from testbench  !!! OOOOO");
        $display("------------------------------------------------->");

        repeat (1) @(posedge iClk12M && iEnSample600k);
        iFirIn <= 3'b001;
        repeat (1) @(posedge iClk12M && iEnSample600k);
        iFirIn <= 3'b000;

        repeat (200) @(posedge iClk12M && iEnSample600k);

        $display("------------------------------------------------->");
        $display("OOOOO 3'b111 is received from testbench  !!! OOOOO");
        $display("------------------------------------------------->");

        repeat (1) @(posedge iClk12M && iEnSample600k);
        iFirIn <= 3'b111;
        repeat (1) @(posedge iClk12M && iEnSample600k);
        iFirIn <= 3'b000;

        repeat (200) @(posedge iClk12M && iEnSample600k);

        $display("-------------------------------------------------->"); 
        $display("OOOOO FIR Filter Simulation has been done !!! OOOOO");
        $display("-------------------------------------------------->");

        #1000

        @(posedge iClk12M);
        iCoeffUpdateFlag = 1'b0;
        iEnSample600k = 1'b1;

        repeat (16) begin
            @(posedge iClk12M);
            $display ("coefficient reading... : %h", iWrDtRam);
        end

        #1000

        @(posedge iEnSample600k);
        $display("MAC computationing ...");

        repeat (1) @(posedge iClk12M && iEnSample600k);
        $display("FIR filter final output : %b", oFirOut);

        #1000
        @(posedge iClk12M);
        iRsn = 1'b0;
        @(posedge iClk12M);
        iRsn = 1'b1;
        @(posedge iClk12M);
        iNumOfCoeff = 6'd30;
        iCoeffUpdateFlag = 1'b0;
        iFirIn = 3'b000;

        #500;
    
        @(posedge iClk12M);
        iCoeffUpdateFlag = 1'b1;
        
        iAddrRam = 6'd0; iWrDtRam = 16'b1111_1111_1110_1101; @(posedge iClk12M);
        iAddrRam = 6'd1; iWrDtRam = 16'b0000_0000_0001_0111; @(posedge iClk12M);
        iAddrRam = 6'd2; iWrDtRam = 16'b0000_0000_0011_0000; @(posedge iClk12M);
        iAddrRam = 6'd3; iWrDtRam = 16'b1111_1111_1001_1011; @(posedge iClk12M);
        iAddrRam = 6'd4; iWrDtRam = 16'b0000_0011_1111_0011; @(posedge iClk12M);
        iAddrRam = 6'd5; iWrDtRam = 16'b1111_1111_1100_1100; @(posedge iClk12M);
        iAddrRam = 6'd6; iWrDtRam = 16'b0000_0000_0000_0000; @(posedge iClk12M);
        iAddrRam = 6'd7; iWrDtRam = 16'b1111_1110_0000_1111; @(posedge iClk12M);
        iAddrRam = 6'd8; iWrDtRam = 16'b0000_0001_0110_0110; @(posedge iClk12M);
        iAddrRam = 6'd9; iWrDtRam = 16'b0000_1111_0000_1101; @(posedge iClk12M);
        iAddrRam = 6'd10; iWrDtRam = 16'b1111_1111_1000_0011; @(posedge iClk12M);
        iAddrRam = 6'd11; iWrDtRam = 16'b0000_0000_1001_1000; @(posedge iClk12M);
        iAddrRam = 6'd12; iWrDtRam = 16'b0000_0000_0101_0110; @(posedge iClk12M);
        iAddrRam = 6'd13; iWrDtRam = 16'b1111_1111_1111_1111; @(posedge iClk12M);
        iAddrRam = 6'd14; iWrDtRam = 16'b0000_0000_0010_0010; @(posedge iClk12M);
        iAddrRam = 6'd15; iWrDtRam = 16'b1111_1111_1110_1010; @(posedge iClk12M);
        iAddrRam = 6'd16; iWrDtRam = 16'b0000_0000_0000_1100; @(posedge iClk12M);
        iAddrRam = 6'd17; iWrDtRam = 16'b0000_0000_0110_1101; @(posedge iClk12M);
        iAddrRam = 6'd18; iWrDtRam = 16'b0000_0000_1110_0000; @(posedge iClk12M);
        iAddrRam = 6'd19; iWrDtRam = 16'b1111_1111_0110_0101; @(posedge iClk12M);
        iAddrRam = 6'd20; iWrDtRam = 16'b0000_0000_0011_0010; @(posedge iClk12M);
        iAddrRam = 6'd21; iWrDtRam = 16'b1111_1111_1111_1100; @(posedge iClk12M);
        iAddrRam = 6'd22; iWrDtRam = 16'b0000_0000_1000_0001; @(posedge iClk12M);
        iAddrRam = 6'd23; iWrDtRam = 16'b1111_1111_0111_0010; @(posedge iClk12M);
        iAddrRam = 6'd24; iWrDtRam = 16'b0000_0000_0100_1100; @(posedge iClk12M);
        iAddrRam = 6'd25; iWrDtRam = 16'b1111_1111_1000_1011; @(posedge iClk12M);
        iAddrRam = 6'd26; iWrDtRam = 16'b0000_0000_1100_0011; @(posedge iClk12M);
        iAddrRam = 6'd27; iWrDtRam = 16'b1111_1111_1010_1111; @(posedge iClk12M);
        iAddrRam = 6'd28; iWrDtRam = 16'b0000_0001_0000_1110; @(posedge iClk12M);
        iAddrRam = 6'd29; iWrDtRam = 16'b1111_1110_1011_0110; 

        @(posedge iClk12M);
        iCoeffUpdateFlag = 1'b0;

	#1000;

        repeat (200) @(posedge iClk12M && iEnSample600k);
        iFirIn <= 3'b000;

        $display("------------------------------------------------->");
        $display("OOOOO 3'b001 is received from testbench  !!! OOOOO");
        $display("------------------------------------------------->");

        repeat (1) @(posedge iClk12M && iEnSample600k);
        iFirIn <= 3'b001;
        repeat (1) @(posedge iClk12M && iEnSample600k);
        iFirIn <= 3'b000;

        repeat (200) @(posedge iClk12M && iEnSample600k);

        $display("------------------------------------------------->");
        $display("OOOOO 3'b111 is received from testbench  !!! OOOOO");
        $display("------------------------------------------------->");

        repeat (1) @(posedge iClk12M && iEnSample600k);
        iFirIn <= 3'b111;
        repeat (1) @(posedge iClk12M && iEnSample600k);
        iFirIn <= 3'b0000;

        repeat (200) @(posedge iClk12M && iEnSample600k);

        $display("-------------------------------------------------->"); 
        $display("OOOOO FIR Filter Simulation has been done !!! OOOOO");
        $display("-------------------------------------------------->");

        #1000

        @(posedge iClk12M);
        iCoeffUpdateFlag = 1'b0;
        iEnSample600k = 1'b1;

        repeat (16) begin
            @(posedge iClk12M);
            $display ("coefficient reading... : %h", iWrDtRam);
        end

        #1000

        @(posedge iEnSample600k);
        $display("MAC computationing ...");

        repeat (1) @(posedge iClk12M && iEnSample600k);
        $display("FIR filter final output : %b", oFirOut);
        
        #1000
        @(posedge iClk12M);
        iRsn = 1'b0;
        @(posedge iClk12M);
        iRsn = 1'b1;
        @(posedge iClk12M);
        iNumOfCoeff = 6'd45;
        iCoeffUpdateFlag = 1'b0;
        iFirIn = 3'b000;

        #500;
    
        @(posedge iClk12M);
        iCoeffUpdateFlag = 1'b1;
        
        iAddrRam = 6'd0;  iWrDtRam = 16'b0000_0000_0000_1100; @(posedge iClk12M); 
        iAddrRam = 6'd1;  iWrDtRam = 16'b0000_0000_0000_0000; @(posedge iClk12M); 
        iAddrRam = 6'd2;  iWrDtRam = 16'b1111_1111_1110_1101; @(posedge iClk12M); 
        iAddrRam = 6'd3;  iWrDtRam = 16'b0000_0000_0001_0111; @(posedge iClk12M); 
        iAddrRam = 6'd4;  iWrDtRam = 16'b0000_0000_0000_0000; @(posedge iClk12M); 
        iAddrRam = 6'd5;  iWrDtRam = 16'b1111_1111_1110_1100; @(posedge iClk12M); 
        iAddrRam = 6'd6;  iWrDtRam = 16'b0000_0000_0011_0000; @(posedge iClk12M); 
        iAddrRam = 6'd7;  iWrDtRam = 16'b0000_0000_0000_0000; @(posedge iClk12M); 
        iAddrRam = 6'd8;  iWrDtRam = 16'b1111_1111_1001_1011; @(posedge iClk12M); 
        iAddrRam = 6'd9;  iWrDtRam = 16'b0000_0001_1001_1011; @(posedge iClk12M); 
        iAddrRam = 6'd10; iWrDtRam = 16'b0000_0011_1111_0011; @(posedge iClk12M); 
        iAddrRam = 6'd11; iWrDtRam = 16'b0000_0001_1001_1011; @(posedge iClk12M); 
        iAddrRam = 6'd12; iWrDtRam = 16'b1111_1111_1001_1011; @(posedge iClk12M);
        iAddrRam = 6'd13; iWrDtRam = 16'b0000_0000_0000_0000; @(posedge iClk12M); 
        iAddrRam = 6'd14; iWrDtRam = 16'b0000_0000_0011_0000; @(posedge iClk12M); 
        iAddrRam = 6'd15; iWrDtRam = 16'b1111_1111_1110_1100; @(posedge iClk12M); 
        iAddrRam = 6'd16; iWrDtRam = 16'b0000_0000_0000_0000; @(posedge iClk12M); 
        iAddrRam = 6'd17; iWrDtRam = 16'b0000_0000_0001_0111; @(posedge iClk12M); 
        iAddrRam = 6'd18; iWrDtRam = 16'b1111_1111_1110_1101; @(posedge iClk12M); 
        iAddrRam = 6'd19; iWrDtRam = 16'b0000_0000_0000_0000; @(posedge iClk12M); 
        iAddrRam = 6'd20; iWrDtRam = 16'b0000_0000_0000_1100; @(posedge iClk12M); 
        iAddrRam = 6'd21; iWrDtRam = 16'b1111_1111_1001_0110; @(posedge iClk12M); 
        iAddrRam = 6'd22; iWrDtRam = 16'b0000_0000_0001_0010; @(posedge iClk12M); 
        iAddrRam = 6'd23; iWrDtRam = 16'b1111_1111_1000_0000; @(posedge iClk12M); 
        iAddrRam = 6'd24; iWrDtRam = 16'b0000_0000_1001_0100; @(posedge iClk12M); 
        iAddrRam = 6'd25; iWrDtRam = 16'b1111_1111_1110_0001; @(posedge iClk12M); 
        iAddrRam = 6'd26; iWrDtRam = 16'b0000_0000_0001_1100; @(posedge iClk12M); 
        iAddrRam = 6'd27; iWrDtRam = 16'b0000_0000_0010_0000; @(posedge iClk12M); 
        iAddrRam = 6'd28; iWrDtRam = 16'b1111_1111_1111_0000; @(posedge iClk12M); 
        iAddrRam = 6'd29; iWrDtRam = 16'b0000_0001_0010_0101; @(posedge iClk12M); 
        iAddrRam = 6'd30; iWrDtRam = 16'b1111_1110_1011_0110; @(posedge iClk12M); 
        iAddrRam = 6'd31; iWrDtRam = 16'b0000_1110_1010_1011; @(posedge iClk12M); 
        iAddrRam = 6'd32; iWrDtRam = 16'b1111_0001_0001_1111; @(posedge iClk12M);
        iAddrRam = 6'd33; iWrDtRam = 16'b0000_1101_1011_1100; @(posedge iClk12M); 
        iAddrRam = 6'd34; iWrDtRam = 16'b1110_1000_1101_1111; @(posedge iClk12M); 
        iAddrRam = 6'd35; iWrDtRam = 16'b0000_1011_1111_1110; @(posedge iClk12M); 
        iAddrRam = 6'd36; iWrDtRam = 16'b1111_0110_1011_0011; @(posedge iClk12M); 
        iAddrRam = 6'd37; iWrDtRam = 16'b0000_0110_1001_0011; @(posedge iClk12M); 
        iAddrRam = 6'd38; iWrDtRam = 16'b1111_1100_1111_0100; @(posedge iClk12M); 
        iAddrRam = 6'd39; iWrDtRam = 16'b0000_1111_0000_1010; @(posedge iClk12M); 
        iAddrRam = 6'd40; iWrDtRam = 16'b1111_1111_1111_1011; @(posedge iClk12M); 
        iAddrRam = 6'd41; iWrDtRam = 16'b0000_0000_0000_0101; @(posedge iClk12M); 
        iAddrRam = 6'd42; iWrDtRam = 16'b1111_1111_1011_1000; @(posedge iClk12M); 
        iAddrRam = 6'd43; iWrDtRam = 16'b0000_0001_0110_1100; @(posedge iClk12M); 
        iAddrRam = 6'd44; iWrDtRam = 16'b1111_1111_1110_1011; @(posedge iClk12M); 
    

        @(posedge iClk12M);
        iCoeffUpdateFlag = 1'b0;

	    #1000;

        repeat (200) @(posedge iClk12M && iEnSample600k);
        iFirIn <= 3'b000;

        $display("------------------------------------------------->");
        $display("OOOOO 3'b001 is received from testbench  !!! OOOOO");
        $display("------------------------------------------------->");

        repeat (1) @(posedge iClk12M && iEnSample600k);
        iFirIn <= 3'b001;
        repeat (1) @(posedge iClk12M && iEnSample600k);
        iFirIn <= 3'b000;

        repeat (200) @(posedge iClk12M && iEnSample600k);

        $display("------------------------------------------------->");
        $display("OOOOO 3'b111 is received from testbench  !!! OOOOO");
        $display("------------------------------------------------->");

        repeat (1) @(posedge iClk12M && iEnSample600k);
        iFirIn <= 3'b111;
        repeat (1) @(posedge iClk12M && iEnSample600k);
        iFirIn <= 3'b0000;

        repeat (200) @(posedge iClk12M && iEnSample600k);

        $display("-------------------------------------------------->"); 
        $display("OOOOO FIR Filter Simulation has been done !!! OOOOO");
        $display("-------------------------------------------------->");

        #1000

        @(posedge iClk12M);
        iCoeffUpdateFlag = 1'b0;
        iEnSample600k = 1'b1;

        repeat (16) begin
            @(posedge iClk12M);
            $display ("coefficient reading... : %h", iWrDtRam);
        end

        #1000

        @(posedge iEnSample600k);
        $display("MAC computationing ...");

        repeat (1) @(posedge iClk12M && iEnSample600k);
        $display("FIR filter final output : %b", oFirOut);

        #1000
        @(posedge iClk12M);
        iRsn = 1'b0;
        @(posedge iClk12M);
        iRsn = 1'b1;
        @(posedge iClk12M);
        iNumOfCoeff = 6'd40;
        iCoeffUpdateFlag = 1'b0;
        iFirIn = 3'b000;

        @(posedge iClk12M);
        iCoeffUpdateFlag = 1'b1;

        @(posedge iClk12M);
        coeff_array[0] = 16'b0000_0000_0000_0011;
        coeff_array[1] = 16'b0000_0000_0000_0110;
        coeff_array[2] = 16'b0000_0000_0001_0111; 
        coeff_array[3] = 16'b0000_0000_0011_0000; 
        coeff_array[4] = 16'b0000_0001_1001_1011; 
        coeff_array[5] = 16'b1111_1111_1001_1011; 
        coeff_array[6] = 16'b0000_0000_0000_0000;
        coeff_array[7] = 16'b1111_1111_1110_1101;
        coeff_array[8] = 16'b0000_0000_0011_0110;
        coeff_array[9] = 16'b0000_0000_0110_1100;
        coeff_array[10] = 16'b1111_1111_1100_1100;
        coeff_array[11] = 16'b0000_0000_0000_0000;
        coeff_array[12] = 16'b0000_0000_0000_0000;
        coeff_array[13] = 16'b0000_0000_0000_0000;
        coeff_array[14] = 16'b0000_0000_0000_0000;
        coeff_array[15] = 16'b0000_0000_0000_0000;
        coeff_array[16] = 16'b0000_0000_0000_0000;
        coeff_array[17] = 16'b0000_0000_0000_0000;
        coeff_array[18] = 16'b0000_0000_0000_0000;
        coeff_array[19] = 16'b0000_0000_0000_0000;
        coeff_array[20] = 16'b0000_0000_0000_0000;
        coeff_array[21] = 16'b0000_0000_0000_0000;
        coeff_array[22] = 16'b0000_0000_0000_0000;
        coeff_array[23] = 16'b0000_0000_0000_0000;
        coeff_array[24] = 16'b0000_0000_0000_0000;
        coeff_array[25] = 16'b0000_0000_0000_0000;
        coeff_array[26] = 16'b0000_0000_0000_0000;
        coeff_array[27] = 16'b0000_0000_0000_0000;
        coeff_array[28] = 16'b0000_0000_0000_0000;
        coeff_array[29] = 16'b0000_0000_0000_0000;
        coeff_array[30] = 16'b0000_0000_0000_0000;
        coeff_array[31] = 16'b0000_0000_0000_0000;
        coeff_array[32] = 16'b0000_0000_0000_0000;
        coeff_array[33] = 16'b0000_0000_0000_0000;
        coeff_array[34] = 16'b0000_0000_0000_0000;
        coeff_array[35] = 16'b0000_0000_0000_0000;
        coeff_array[36] = 16'b0000_0000_0000_0000;
        coeff_array[37] = 16'b0000_0000_0000_0000;
        coeff_array[38] = 16'b0000_0000_0000_0000;
        coeff_array[39] = 16'b0000_0000_0000_0000;

        for (i = 0; i < 40; i = i + 1) begin
            address_array[i] = i;
        end

        for (i = 39; i > 28; i = i - 1) begin
            j = $urandom_range(0, i);
            temp = address_array[i];
            address_array[i] = address_array[j];
            address_array[j] = temp;
        end

        for (i = 29; i < 40; i = i + 1) begin
            iAddrRam = address_array[i];
            iWrDtRam = coeff_array[i - 29]; 
            @(posedge iClk12M);
            $display("Addr[%0d] <= Coeff[%0h]", iAddrRam, iWrDtRam);
        end

        @(posedge iClk12M);
        iCoeffUpdateFlag = 1'b0;

        @(posedge iClk12M);
        iFirIn <= 3'b001;

        @(posedge iClk12M);
        iFirIn <= 3'b000;

        repeat (200) @(posedge iClk12M && iEnSample600k);
        iFirIn <= 3'b000;

        #1000
        @(posedge iClk12M);
        iRsn = 1'b0;
        @(posedge iClk12M);
        iRsn = 1'b1;
        @(posedge iClk12M);
        iNumOfCoeff = 6'd16;
        iCoeffUpdateFlag = 1'b0;
        iFirIn = 3'b000;

        #500;

        @(posedge iClk12M);
        iCoeffUpdateFlag = 1'b1;

        iAddrRam = 6'd0; iWrDtRam = 16'b1111_1111_1110_1101; @(posedge iClk12M);
        iAddrRam = 6'd1; iWrDtRam = 16'b0000_0000_0001_0111; @(posedge iClk12M);
        iAddrRam = 6'd2; iWrDtRam = 16'b0000_0000_0011_0000; @(posedge iClk12M);
        iAddrRam = 6'd3; iWrDtRam = 16'b1111_1111_1001_1011; @(posedge iClk12M);
        iAddrRam = 6'd4; iWrDtRam = 16'b0000_0011_1111_0011; @(posedge iClk12M);
        iAddrRam = 6'd5; iWrDtRam = 16'b1111_1111_1100_1100; @(posedge iClk12M);
        iAddrRam = 6'd6; iWrDtRam = 16'b0000_0000_0000_0000; @(posedge iClk12M);
        iAddrRam = 6'd7; iWrDtRam = 16'b1111_1110_0000_1111; @(posedge iClk12M);
        iAddrRam = 6'd8; iWrDtRam = 16'b0000_0001_0110_0110; @(posedge iClk12M);

        @(posedge iClk12M);
        iCoeffUpdateFlag = 1'b0;

        iAddrRam = 6'd9; iWrDtRam = 16'b0000_1111_0000_1101; @(posedge iClk12M);
        iAddrRam = 6'd10; iWrDtRam = 16'b1111_1111_1000_0011; @(posedge iClk12M);
        iAddrRam = 6'd11; iWrDtRam = 16'b0000_0000_1001_1000; @(posedge iClk12M);
        iAddrRam = 6'd12; iWrDtRam = 16'b0000_0000_0101_0110; @(posedge iClk12M);
        iAddrRam = 6'd13; iWrDtRam = 16'b1111_1111_1111_1111; @(posedge iClk12M);
        iAddrRam = 6'd14; iWrDtRam = 16'b0000_0000_0010_0010; @(posedge iClk12M);
        iAddrRam = 6'd15; iWrDtRam = 16'b1111_1111_1110_1010;

        @(posedge iClk12M);

        iCoeffUpdateFlag = 1'b0;
        @(posedge iClk12M);
        iFirIn <= 3'b000;
	    @(posedge iClk12M);
        iFirIn <= 3'b000;

        @(posedge iClk12M);
        iFirIn <= 3'b001;

        @(posedge iClk12M);
        iFirIn <= 3'b000;

        repeat (200) @(posedge iClk12M && iEnSample600k);
        iFirIn <= 3'b000;
	
	#1000;

        $finish;
    end


    /***********************************************
    // Result check
    ***********************************************/
    initial
    begin
        $monitor($realtime, "ns, iFirIn = %b, oFirOut = %b", iFirIn, oFirOut);
    end

endmodule
