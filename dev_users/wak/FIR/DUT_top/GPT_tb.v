`timescale 1ns/10ps

module TB_DUT;

  // --- Inputs ---
  reg iClk12M;
  reg iRsn;
  reg iEnSample600k;
  reg iCoeffUpdateFlag;
  reg [5:0] iAddrRam;
  reg [15:0] iWrDtRam;
  reg [5:0] iNumOfCoeff;
  reg signed [2:0] iFirIn;

  // --- Outputs ---
  wire signed [15:0] oFirOut;
  wire [15:0] oWaveform;

  // --- [추가] DUT에 들어가는 지연된 클럭 ---
  wire wClk_DUT;

  // --- Loop Variables ---
  integer sample_idx;
  integer k;

  // --- Clock Generation (12MHz) ---
  initial iClk12M = 0;
  always #41.666 iClk12M = ~iClk12M; 

  // --- [핵심] Clock Delay (Phase Shift) ---
  // DUT 클럭을 2ns 지연시킵니다.
  // TB가 posedge iClk12M에서 데이터를 바꾸면,
  // 2ns 뒤에 posedge wClk_DUT가 발생하여 DUT가 안정된 데이터를 잡습니다.
  assign #2 wClk_DUT = iClk12M; 

  // --- Instantiation ---
  DUT_top u_DUT (
    .iClk12M(wClk_DUT), // <--- 지연된 클럭 연결
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

  // --- Task: Positive Edge 기준 쓰기 (Delay 불필요) ---
  task write_coeff(input [5:0] addr, input signed [15:0] data);
    begin
      @(posedge iClk12M); // TB 기준 클럭에 맞춤
      iAddrRam = addr;
      iWrDtRam = data;
    end
  endtask

  // --- Main Test Sequence ---
  initial begin
    $dumpfile("waveform_kaiser_delayed_clk.vcd");
    $dumpvars(0, TB_DUT);

    // 1. 초기화
    iRsn = 0;
    iEnSample600k = 0;
    iCoeffUpdateFlag = 0;
    iAddrRam = 0;
    iWrDtRam = 0;
    iNumOfCoeff = 21; 
    iFirIn = 3'd0;

    #200;
    iRsn = 1; // 리셋 해제
    #100;

    // ---------------------------------------------------------
    // 2. 계수 업데이트
    // ---------------------------------------------------------
    $display("--- [Step 1] Writing 21 Coefficients ---");
    
    @(posedge iClk12M); 
    iCoeffUpdateFlag = 1;

    // 데이터 입력
    write_coeff(0,  13);    
    write_coeff(1,  0);     
    write_coeff(2,  -19);   
    write_coeff(3,  24);    
    write_coeff(4,  0);     
    write_coeff(5,  -37);   
    write_coeff(6,  48);    
    write_coeff(7,  0);     
    write_coeff(8,  -102);  
    write_coeff(9,  206);   
    write_coeff(10, 500);   
    write_coeff(11, 206);   
    write_coeff(12, -102);  
    write_coeff(13, 0);     
    write_coeff(14, 48);    
    write_coeff(15, -37);   
    write_coeff(16, 0);     
    write_coeff(17, 24);    
    write_coeff(18, -19);   
    write_coeff(19, 0);     
    write_coeff(20, 13);    

    write_coeff(21, 0);
    write_coeff(22, 0);
    write_coeff(23, 0);

    @(posedge iClk12M);
    iCoeffUpdateFlag = 0;
    $display("--- Coefficient Write Done ---");
    #200;

    // ---------------------------------------------------------
    // 3. Positive Impulse Test (1)
    // ---------------------------------------------------------
    $display("--- [Step 2] Testing Positive Impulse (1) ---");
    for (sample_idx = 0; sample_idx < 64; sample_idx = sample_idx + 1) begin
        
        @(posedge iClk12M);
        
        if (sample_idx == 0) iFirIn = 3'b001; 
        else iFirIn = 3'b000;

        iEnSample600k = 1; 

        @(posedge iClk12M);
        iEnSample600k = 0; 

        // 대기 (19사이클)
        repeat(19) @(posedge iClk12M);
    end

    #500;

    // ---------------------------------------------------------
    // 4. Negative Impulse Test (-1)
    // ---------------------------------------------------------
    $display("--- [Step 3] Testing Negative Impulse (-1) ---");
    for (sample_idx = 0; sample_idx < 64; sample_idx = sample_idx + 1) begin
        
        @(posedge iClk12M);
        
        if (sample_idx == 0) iFirIn = 3'b111; 
        else iFirIn = 3'b000;

        iEnSample600k = 1; 

        @(posedge iClk12M);
        iEnSample600k = 0; 

        repeat(19) @(posedge iClk12M);
    end

    #1000;
    $finish;
  end

endmodule