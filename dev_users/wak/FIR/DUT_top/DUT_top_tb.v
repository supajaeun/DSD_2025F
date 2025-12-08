`timescale 1ns/10ps

module TB_DUT_Final_Stress_v5_Flush;

  // =========================================================
  // 1. Signal Declarations
  // =========================================================
  reg iClk12M;
  reg iRsn;
  reg iEnSample600k;
  reg iCoeffUpdateFlag;
  reg [5:0] iAddrRam;
  reg [15:0] iWrDtRam;
  reg [5:0] iNumOfCoeff;
  reg signed [2:0] iFirIn;

  // Outputs
  wire signed [15:0] oFirOut;
  wire signed [15:0] oWaveform;

  // DUT Clock (Delayed)
  wire wClk_DUT;

  // Debugging Variables
  integer i;

  // =========================================================
  // 2. Clock Generation & Delay Trick
  // =========================================================
  initial iClk12M = 0;
  always #41.666 iClk12M = ~iClk12M; 

  // [핵심] 2ns 딜레이로 DUT에 클럭 공급
  assign #2 wClk_DUT = iClk12M;

  // =========================================================
  // 3. DUT Instantiation
  // =========================================================
  DUT_top u_DUT (
    .iClk12M(wClk_DUT), 
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

  // =========================================================
  // 4. Verification Tasks
  // =========================================================

  // Task 1: 계수 쓰기
  task write_coeff(input [5:0] addr, input signed [15:0] data);
    begin
      @(posedge iClk12M); 
      iAddrRam = addr;
      iWrDtRam = data;
    end
  endtask

  // Task 2: 샘플 보내기 (600kHz = 20클럭 주기 준수)
  task send_sample(input signed [2:0] in_data);
    begin
      @(posedge iClk12M);
      iFirIn        = in_data;
      iEnSample600k = 1'b1;

      @(posedge iClk12M);
      iEnSample600k = 1'b0;

      // 12MHz / 600kHz = 20 cycles (2 used + 18 wait)
      repeat(18) @(posedge iClk12M);
      
      if (in_data != 0)
        $display("[Input] Data: %d @ %t", in_data, $time);
    end
  endtask

  // [NEW] Task 3: 딜레이 체인 비우기 (Flush)
  // 0을 45번 입력하여 내부 40개 딜레이 레지스터를 싹 비웁니다.
  task flush_delay_chain();
    integer k;
    begin
      $display("   -> [Flush] Cleaning Delay Chain (Sending 45 Zeros)...");
      for(k=0; k<45; k=k+1) begin
        // send_sample 함수를 재사용하여 0 입력
        // (로그 출력을 줄이기 위해 직접 구현하지 않고 호출함)
        @(posedge iClk12M); iFirIn = 0; iEnSample600k = 1;
        @(posedge iClk12M); iEnSample600k = 0;
        repeat(18) @(posedge iClk12M);
      end
      $display("   -> [Flush] Complete. System Clean.");
    end
  endtask

  // =========================================================
  // 5. Main Test Scenario
  // =========================================================
  initial begin
    $dumpfile("Final_v5_Flush.vcd");
    $dumpvars(0, TB_DUT_Final_Stress_v5_Flush);

    // -------------------------------------------------------
    // Initialization
    // -------------------------------------------------------
    $display("\n==================================================");
    $display(" System Reset & Init");
    $display("==================================================");
    iRsn = 0; iEnSample600k = 0; iCoeffUpdateFlag = 0;
    iAddrRam = 0; iWrDtRam = 0; iNumOfCoeff = 0; iFirIn = 0;
    
    #200; iRsn = 1; #100;

    // -------------------------------------------------------
    // Standard Coefficient Setup (21 Taps)
    // -------------------------------------------------------
    $display("\n==================================================");
    $display(" Standard Setup: 21 Coefficients");
    $display("==================================================");
    
    @(posedge iClk12M);
    iCoeffUpdateFlag = 1;
    iNumOfCoeff = 21; 

    // Symmetric Coefficients
    write_coeff(0, 10);   write_coeff(20, 15);
    write_coeff(1, 20);   write_coeff(19, 25);
    write_coeff(2, 30);   write_coeff(18, 35);
    write_coeff(3, 40);   write_coeff(17, 45);
    write_coeff(4, 50);   write_coeff(16, 55);
    write_coeff(5, 60);   write_coeff(15, 65);
    write_coeff(6, 70);   write_coeff(14, 75);
    write_coeff(7, 80);   write_coeff(13, 85);
    write_coeff(8, 90);   write_coeff(12, 95);
    write_coeff(9, 100);  write_coeff(11, 250);
    write_coeff(10, 500); // Center

    @(posedge iClk12M);
    iCoeffUpdateFlag = 0;
    #200;

    // 초기화 확실하게 한 번 하고 시작
    flush_delay_chain(); 

    // -------------------------------------------------------
    // [Scenario 1-A] Positive Impulse (+1)
    // -------------------------------------------------------
    $display("\n==================================================");
    $display(" [Scenario 2-A] Positive Impulse (+1)");
    $display("==================================================");
    
    send_sample(3'b001); // Input +1
    
    // 결과 관측을 위해 25번 0 입력 (잔향 확인)
    for(i=0; i<25; i=i+1) send_sample(3'b000);

    // 다음 테스트를 위해 싹 비우기
    flush_delay_chain();

    // -------------------------------------------------------
    // [Scenario 1-B] Negative Impulse (-1)
    // -------------------------------------------------------
    $display("\n==================================================");
    $display(" [Scenario 2-B] Negative Impulse (-1)");
    $display("==================================================");

    send_sample(3'b111); // Input -1
    for(i=0; i<25; i=i+1) send_sample(3'b000); 

    flush_delay_chain();

    // -------------------------------------------------------
    // [Scenario 2-A] Mixed Pattern
    // -------------------------------------------------------
    $display("\n==================================================");
    $display(" [Scenario 3] Mixed Pattern (1, -1, 3, -3)");
    $display("==================================================");

    send_sample(3'b001); 
    send_sample(3'b111); 
    send_sample(3'b011); 
    send_sample(3'b101); 
    
    // 결과 관측 후 비우기
    repeat(10) send_sample(3'b000); 
    flush_delay_chain();

    // -------------------------------------------------------
    // [Scenario 4] Overflow Test (45 Taps)
    // -------------------------------------------------------
    $display("\n==================================================");
    $display(" [Scenario 4] OVERFLOW TEST: 45 Coefficients");
    $display("==================================================");

    @(posedge iClk12M);
    iCoeffUpdateFlag = 1;
    iNumOfCoeff = 45; // Limit Break

    for(i=0; i<40; i=i+1) write_coeff(i[5:0], 100); 
    for(i=40; i<45; i=i+1) write_coeff(i[5:0], 10000); // Bad Values

    @(posedge iClk12M);
    iCoeffUpdateFlag = 0;
    #200;

    send_sample(3'b001); // Impulse
    for(i=0; i<50; i=i+1) send_sample(3'b000); // Check Tail

    // ★중요★ Overflow 테스트에서 남은 찌꺼기를 완벽 제거해야 
    // 다음 Saturation 테스트가 정확해짐
    flush_delay_chain(); 

    // -------------------------------------------------------
    // [Scenario 5] Saturation Test
    // -------------------------------------------------------
    $display("\n==================================================");
    $display(" [Scenario 5] Saturation Stress Test");
    $display("==================================================");

    // Setup Max Coeffs
    @(posedge iClk12M);
    iCoeffUpdateFlag = 1;
    iNumOfCoeff = 20; 
    for(i=0; i<20; i=i+1) write_coeff(i[5:0], 16'h7FFF); 
    @(posedge iClk12M);
    iCoeffUpdateFlag = 0;
    #200;

    // Inject Max Input
    for(i=0; i<15; i=i+1) send_sample(3'b011); 
    
    flush_delay_chain();

    // -------------------------------------------------------
    // [Scenario 6] Interrupt Test
    // -------------------------------------------------------
    $display("\n==================================================");
    $display(" [Scenario 6] Stability Test: Interrupt MID-OP");
    $display("==================================================");

    // Setup Normal Coeffs
    @(posedge iClk12M); iCoeffUpdateFlag = 1; iNumOfCoeff = 5;
    for(i=0; i<5; i=i+1) write_coeff(i[5:0], 100);
    @(posedge iClk12M); iCoeffUpdateFlag = 0;
    #200;

    // Start Sample
    @(posedge iClk12M);
    iFirIn = 3'b001; iEnSample600k = 1;
    @(posedge iClk12M); iEnSample600k = 0;

    repeat(5) @(posedge iClk12M);
    
    $display(" -> Interrupting FSM...");
    iCoeffUpdateFlag = 1; 

    repeat(15) @(posedge iClk12M);
    iCoeffUpdateFlag = 0;
    #200;

    // FSM Alive Check
    send_sample(3'b001);
    flush_delay_chain();

    $display("\n==================================================");
    $display(" ALL TESTS COMPLETED.");
    $display("==================================================");
    $finish;
  end

endmodule