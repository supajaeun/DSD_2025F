/*******************************************************************
  - Project          : 2025 Team Project
  - File name        : Sum.v
  - Description      : Aggregates MAC outputs & Saturation
  - Owner            : JunSuKO
  - Revision history : 2025.11.25 : Input width expanded for Full Precision
*******************************************************************/

module Sum #(
    parameter IN_WIDTH  = 25,  // Mac.v의 출력 크기와 맞춰야 함 (중요!)
    parameter OUT_WIDTH = 16   // 최종 FIR 필터 출력 크기
) (
    // clock & reset
    input                                  iClk12M,                   
    input                                  iRsn, 

    // input MacUnits (From Mac.v - 25 bits)                  
    input  signed [IN_WIDTH-1:0]           iMac1,         
    input  signed [IN_WIDTH-1:0]           iMac2,         
    input  signed [IN_WIDTH-1:0]           iMac3,        
    input  signed [IN_WIDTH-1:0]           iMac4,  

    // input Sampling signal  
    input                                  iEnSample600k,    

    // Control Signal (Latching Trigger)    
    input                                  iEnSum,     

    // FIR Final output (Saturated to 16 bits)          
    output reg signed [OUT_WIDTH-1:0]      oFirOut  
);

/**********************************************************
 wire & reg declaration
*********************************************************/
    // 4개 값을 더하므로 비트 수 +2 증가 (log2(4)=2)
    // 25bit + 2bit = 27bit
    wire signed [IN_WIDTH+1:0] wSumResult;

    // Saturation Constants (16-bit Signed Max/Min)
    localparam signed [IN_WIDTH+1:0] MAX_VAL = 27'sd32767;
    localparam signed [IN_WIDTH+1:0] MIN_VAL = -27'sd32768;


/***********************************************************
 Summation & Saturation
*******************************************************/    

    // 1. Summation (Combinational Logic)
    // 25비트 입력 4개를 더해 27비트 결과 생성
    assign wSumResult = iMac1 + iMac2 + iMac3 + iMac4;


    // 2. Output Latch & Saturation (Sequential Logic)
    always @(posedge iClk12M or negedge iRsn) begin
        if (!iRsn) begin
            oFirOut <= {OUT_WIDTH{1'b0}};
        end
        else if (iEnSum) begin // FSM state == SUM 시점
            
            // Saturation Logic
            // 27비트 합계가 16비트 표현 범위를 넘어가면 최대/최소값으로 고정
            if (wSumResult > MAX_VAL)      
                oFirOut <= 16'h7FFF;       // Max Positive
            else if (wSumResult < MIN_VAL) 
                oFirOut <= 16'h8000;       // Max Negative
            else                           
                oFirOut <= wSumResult[OUT_WIDTH-1:0]; // Normal Range
        end
    end

endmodule