/*******************************************************************
  - Project          : 2025 Team Project (Optimized)
  - File name        : FSM.v
  - Description      : FSM for 2-RAM & 2-MAC Symmetric Structure
  - Revision history : 2025.11.30
                       2025.12.06
                       2025.12.08
*******************************************************************/
`timescale 1ns/10ps

module FSM (
    input                 iClk12M,
    input                 iRsn,
    input                 iEnSample600k,
    input                 iCoeffUpdateFlag,
    input       [5:0]     iAddrRam,       
    input       [15:0]    iWrDtRam,
    input       [5:0]     iNumOfCoeff,    
    input       [2:0]     iFirIn,         // (Unused)

    // --- RAM Control Outputs ---
    output wire           oCsnRam1, oCsnRam2,
    output wire           oWrnRam1, oWrnRam2, 
    output wire [3:0]     oAddrRam1, oAddrRam2, 
    output wire [15:0]    oWrDtRam1, oWrDtRam2, 

    // --- MAC Control Outputs ---
    output wire           oEnAdd1, 
    output wire           oEnAcc1, 
    output wire           oEnMul1, 

    output wire           oEnDelay,
    output wire           oEnSum 
);

 //==========================================================================
 // Variable Declaration
 //==========================================================================
    localparam  IDLE        = 4'd0;
    localparam  COEFFWR     = 4'd1; 
    localparam  WREND       = 4'd2;
    localparam  LOOP        = 4'd3; 
    localparam  FLUSH       = 4'd4;
    localparam  SUM         = 4'd5;
    localparam  OUTPUT      = 4'd6; 

    reg    [3:0]    state, next_state;
    reg    [5:0]    rCoeff_cnt;
    reg    [5:0]    rNumOfCoeff;
    
    // Read Address Registers
    reg    [3:0]    rRdRam1, rRdRam2; 

    // --- Write Address Decoding Logic ---
    // iAddrRam[0]가 0이면 RAM1(짝수), 1이면 RAM2(홀수)
    wire            wWrBank = iAddrRam[0]; 
    wire   [3:0]    wWrAddr = iAddrRam[4:1];


 //==========================================================================
 // Stage Logic
 //==========================================================================
    always @(posedge iClk12M or negedge iRsn) begin
        if (!iRsn) state <= IDLE;
        else       state <= next_state;
    end

 //==========================================================================
 // Nest Stage Logic
 //==========================================================================
    always @(*) begin
        case (state)
            IDLE: 
                if (iCoeffUpdateFlag) next_state = COEFFWR;
                else if (iEnSample600k) next_state = LOOP; 
                else next_state = IDLE;
            COEFFWR: 
                if (!iCoeffUpdateFlag) next_state = WREND;
                else next_state = COEFFWR;
            WREND: 
                if (iCoeffUpdateFlag) next_state = COEFFWR;
                else if (iEnSample600k) next_state = LOOP; 
                else next_state = WREND;
            
            LOOP: 
                if (rCoeff_cnt >= rNumOfCoeff) next_state = FLUSH;
                else next_state = LOOP;
            FLUSH: next_state = SUM;
            SUM:   next_state = OUTPUT;
            OUTPUT: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

 //==========================================================================
 // Output Logic
 //==========================================================================

    // 1. Chip Select (Active Low)
    assign oCsnRam1 = (state == LOOP || (state == COEFFWR && wWrBank == 0)) ? 1'b0 : 1'b1;
    assign oCsnRam2 = (state == LOOP || (state == COEFFWR && wWrBank == 1)) ? 1'b0 : 1'b1;

    // 2. Write Enable (Active Low in SRAM usually, but handled by logic)
    assign oWrnRam1 = (state == COEFFWR && wWrBank == 0) ? 1'b1 : 1'b0;
    assign oWrnRam2 = (state == COEFFWR && wWrBank == 1) ? 1'b1 : 1'b0;

    // 3. Address Mux (Write Addr/Read Addr)
    assign oAddrRam1 = (state == COEFFWR && wWrBank == 0) ? wWrAddr : rRdRam1;
    assign oAddrRam2 = (state == COEFFWR && wWrBank == 1) ? wWrAddr : rRdRam2;

    // 4. Write Data
    assign oWrDtRam1 = (state == COEFFWR && wWrBank == 0) ? iWrDtRam : 16'd0;
    assign oWrDtRam2 = (state == COEFFWR && wWrBank == 1) ? iWrDtRam : 16'd0;

    // 5. MAC Control Signals
    assign oEnMul1 = (state == LOOP || state == FLUSH);
    assign oEnAcc1 = (state == LOOP || state == FLUSH); 

    // Add(Load)는 첫 번째 사이클(rCoeff_cnt==0)에만 수행
    assign oEnAdd1 = ((state == LOOP || state == FLUSH) && rCoeff_cnt == 0); 

    // 6. Global Control
    assign oEnDelay = ((state == IDLE || state == WREND) && next_state == LOOP); 
    assign oEnSum   = (state == SUM);

 //==========================================================================
 // Counter Sequential Logic
 //==========================================================================

    always @(posedge iClk12M or negedge iRsn) begin
        if (!iRsn) begin
            rCoeff_cnt  <= 6'd0;
            rNumOfCoeff <= 6'd0;
            rRdRam1     <= 4'd0; 
            rRdRam2     <= 4'd0;
        end
        else if (state == IDLE) begin
            rCoeff_cnt <= 6'd0;
            rRdRam1    <= 4'd0; 
            rRdRam2    <= 4'd0;
            
            // Loop 횟수 계산
            if (iCoeffUpdateFlag) begin
                rNumOfCoeff <= (iNumOfCoeff >> 1) + iNumOfCoeff[0];
            end
        end
        
        else if ((state == IDLE || state == WREND) && next_state == LOOP) begin
            rCoeff_cnt <= 6'd0;
            rRdRam1    <= 4'd0; 
            rRdRam2    <= 4'd0;
        end
        
        else if (state == LOOP) begin
            if (rCoeff_cnt < rNumOfCoeff) begin 
                rCoeff_cnt <= rCoeff_cnt + 6'd1;
                rRdRam1    <= rRdRam1 + 4'd1;
                rRdRam2    <= rRdRam2 + 4'd1;
            end
        end
        else if (state == OUTPUT) begin
            rCoeff_cnt <= 6'd0;
        end
    end

endmodule