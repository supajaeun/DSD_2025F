`timescale 1ns/10ps

module FSM (
    input                 iClk12M,
    input                 iRsn,
    input                 iEnSample600k,
    input                 iCoeffUpdateFlag,
    input       [5:0]     iAddrRam,       
    input       [15:0]    iWrDtRam,
    input       [5:0]     iNumOfCoeff,
    input       [2:0]     iFirIn,

    output wire           oCsnRam1, oCsnRam2, oCsnRam3, oCsnRam4,
    output wire           oWrnRam1, oWrnRam2, oWrnRam3, oWrnRam4,
    output wire [3:0]     oAddrRam1, oAddrRam2, oAddrRam3, oAddrRam4,
    output wire [15:0]    oWrDtRam1, oWrDtRam2, oWrDtRam3, oWrDtRam4,

    output wire           oEnAdd1, oEnAdd2, oEnAdd3, oEnAdd4,
    output wire           oEnAcc1, oEnAcc2, oEnAcc3, oEnAcc4,
    output wire           oEnMul1, oEnMul2, oEnMul3, oEnMul4, 

    output wire           oEnDelay,
    output wire           oEnSum 
);

    localparam  IDLE        = 4'd0;
    localparam  COEFFWR     = 4'd1; 
    localparam  WREND       = 4'd2;
    localparam  FETCH       = 4'd3;
    localparam  LOOP        = 4'd4;
    localparam  FLUSH       = 4'd5;
    localparam  SUM         = 4'd7;
    localparam  OUTPUT      = 4'd8; 

    reg    [3:0]    state, next_state;
    reg    [5:0]    rCoeff_cnt;
    reg    [5:0]    rNumOfCoeff;
    // for read
    reg    [3:0]    rRdRam [4:1]; 

    // for write
    wire   [1:0]    wWrBank = iAddrRam[1:0];
    wire   [3:0]    wWrAddr = iAddrRam[5:2];

    // State Logic
    always @(posedge iClk12M) begin
        if (!iRsn) state <= IDLE;
        else       state <= next_state;
    end

    // Next State Logic
    always @(*) begin
        case (state)
            IDLE: 
                if (iCoeffUpdateFlag) next_state <= COEFFWR;
                else if (iEnSample600k) next_state <= FETCH;
                else next_state <= IDLE;
            COEFFWR: 
                if (!iCoeffUpdateFlag) next_state <= WREND;
                else next_state <= COEFFWR;
            WREND: 
                if (iCoeffUpdateFlag) next_state <= COEFFWR;
                else if (iEnSample600k) next_state <= FETCH;
                else next_state <= WREND;
            FETCH: next_state <= LOOP; 
            LOOP: 
                if (rCoeff_cnt >= (rNumOfCoeff - 1)) next_state <= FLUSH;
                else next_state <= LOOP;
            FLUSH: next_state <= SUM;
            SUM:   next_state <= OUTPUT;
            OUTPUT: next_state <= IDLE;
            default: next_state <= IDLE;
        endcase
    end

    // RAM Outputs
    assign oCsnRam1 = (state == LOOP || (state == COEFFWR && wWrBank == 0)) ? 1'b0 : 1'b1;
    assign oCsnRam2 = (state == LOOP || (state == COEFFWR && wWrBank == 1)) ? 1'b0 : 1'b1;
    assign oCsnRam3 = (state == LOOP || (state == COEFFWR && wWrBank == 2)) ? 1'b0 : 1'b1;
    assign oCsnRam4 = (state == LOOP || (state == COEFFWR && wWrBank == 3)) ? 1'b0 : 1'b1;

    assign oWrnRam1 = (state == COEFFWR && wWrBank == 0) ? 1'b1 : 1'b0;
    assign oWrnRam2 = (state == COEFFWR && wWrBank == 1) ? 1'b1 : 1'b0;
    assign oWrnRam3 = (state == COEFFWR && wWrBank == 2) ? 1'b1 : 1'b0;
    assign oWrnRam4 = (state == COEFFWR && wWrBank == 3) ? 1'b1 : 1'b0;

    assign oAddrRam1 = (state == COEFFWR && wWrBank == 0) ? wWrAddr : rRdRam[1];
    assign oAddrRam2 = (state == COEFFWR && wWrBank == 1) ? wWrAddr : rRdRam[2];
    assign oAddrRam3 = (state == COEFFWR && wWrBank == 2) ? wWrAddr : rRdRam[3];
    assign oAddrRam4 = (state == COEFFWR && wWrBank == 3) ? wWrAddr : rRdRam[4];

    assign oWrDtRam1 = (state == COEFFWR && wWrBank == 0) ? iWrDtRam : 16'd0;
    assign oWrDtRam2 = (state == COEFFWR && wWrBank == 1) ? iWrDtRam : 16'd0;
    assign oWrDtRam3 = (state == COEFFWR && wWrBank == 2) ? iWrDtRam : 16'd0;
    assign oWrDtRam4 = (state == COEFFWR && wWrBank == 3) ? iWrDtRam : 16'd0;

    // MAC Control Logic
    assign oEnMul1 = (state == LOOP);
    assign oEnMul2 = (state == LOOP);
    assign oEnMul3 = (state == LOOP);
    assign oEnMul4 = (state == LOOP);

    assign oEnAcc1 = (state == LOOP); 
    assign oEnAcc2 = (state == LOOP);
    assign oEnAcc3 = (state == LOOP);
    assign oEnAcc4 = (state == LOOP);

    assign oEnAdd1 = (state == LOOP && rCoeff_cnt == 0); 
    assign oEnAdd2 = oEnAdd1;
    assign oEnAdd3 = oEnAdd1; 
    assign oEnAdd4 = oEnAdd1;

    assign oEnDelay = (state == FETCH);
    // addition signal
    assign oEnSum   = (state == SUM);

    // Register Counters
    integer i;
    always @(posedge iClk12M) begin
        if (!iRsn) begin
            rCoeff_cnt  <= 6'd0;
            rNumOfCoeff <= 6'd0;
            for(i=1; i<=4; i=i+1) rRdRam[i] <= 4'd0;
        end
        else if (state == IDLE) begin
            rCoeff_cnt  <= 6'd0;
            for(i=1; i<=4; i=i+1) rRdRam[i] <= 4'd0;
            if (iCoeffUpdateFlag) begin
                rNumOfCoeff <= (iNumOfCoeff[1:0] == 0) ? (iNumOfCoeff >> 2) : (iNumOfCoeff >> 2) + 1;
            end
        end
        else if (state == FETCH) begin
            rCoeff_cnt <= 6'd0;
            for(i=1; i<=4; i=i+1) rRdRam[i] <= 4'd0;
        end
        else if (state == LOOP) begin
            if (rCoeff_cnt < rNumOfCoeff - 1) begin
                rCoeff_cnt <= rCoeff_cnt + 6'd1;
                rRdRam[1] <= rRdRam[1] + 4'd1;
                rRdRam[2] <= rRdRam[2] + 4'd1;
                rRdRam[3] <= rRdRam[3] + 4'd1;
                rRdRam[4] <= rRdRam[4] + 4'd1;
            end
        end
        else if (state == OUTPUT) begin
            rCoeff_cnt <= 6'd0;
        end
    end

endmodule