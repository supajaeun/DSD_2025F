/*******************************************************************
  - Project          : 2025 Team Project Verification
  - File name        : TB_DUT
  - Description      : Stress Testbench for 33-Tap Symmetric FIR
  - Owner            : JunSuKo
  - Revision history : 2025.11.30
                       2025.12.06 
                       2025.12.08
*******************************************************************/
`timescale 1ns/10ps

module TB_DUT;

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

  // Task 2: 샘플 보내기 (600kHz = 20클럭 주기)
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

  // Task 3: 딜레이 체인 비우기 (Flush)
  // 33-Tap 필터이므로 여유있게 35번 0을 입력하여 초기화
  task flush_delay_chain();
    integer k;
    begin
      $display("   -> [Flush] Cleaning Delay Chain (Sending 35 Zeros)...");
      for(k=0; k<35; k=k+1) begin
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
    $dumpfile("Final_v6_Symmetric.vcd");
    $dumpvars(0, TB_DUT_Final_Stress_v6);

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
    // [Scenario 1] Standard 33-Tap Setup (Symmetric)
    // -------------------------------------------------------
    $display("\n==================================================");
    $display(" [Scenario 1] Standard Setup: 33 Coefficients (17 Unique)");
    $display("==================================================");
    
    @(posedge iClk12M);
    iCoeffUpdateFlag = 1;
    iNumOfCoeff = 17; // [중요] 0~16번까지 유니크한 계수 17개 전달

    // 0~16번지 (총 17개)에 계수 입력
    // 대칭 구조이므로 0번 계수는 (1번 Tap, 33번 Tap)에 곱해짐
    // 16번 계수는 (17번 Center Tap)에 곱해짐
    write_coeff(0, 10);   // h[0]
    write_coeff(1, 20);   // h[1]
    write_coeff(2, 30);   // h[2]
    write_coeff(3, 40); 
    write_coeff(4, 50); 
    write_coeff(5, 60); 
    write_coeff(6, 70); 
    write_coeff(7, 80); 
    write_coeff(8, 90); 
    write_coeff(9, 100); 
    write_coeff(10, 110); 
    write_coeff(11, 120); 
    write_coeff(12, 130); 
    write_coeff(13, 140); 
    write_coeff(14, 150); 
    write_coeff(15, 160); 
    write_coeff(16, 500); // h[16] (Center Tap)

    @(posedge iClk12M);
    iCoeffUpdateFlag = 0;
    #200;

    flush_delay_chain(); 

    // -------------------------------------------------------
    // [Scenario 2-A] Positive Impulse (+1)
    // -------------------------------------------------------
    $display("\n==================================================");
    $display(" [Scenario 2-A] Positive Impulse (+1)");
    $display("==================================================");
    
    // 이론상 출력 예상: 10, 20, 30 ... 500 ... 30, 20, 10 순서로 나와야 함
    send_sample(3'b001); // Input +1
    for(i=0; i<35; i=i+1) send_sample(3'b000);

    flush_delay_chain();

    // -------------------------------------------------------
    // [Scenario 2-B] Negative Impulse (-1)
    // -------------------------------------------------------
    $display("\n==================================================");
    $display(" [Scenario 2-B] Negative Impulse (-1)");
    $display("==================================================");

    send_sample(3'b111); // Input -1
    for(i=0; i<35; i=i+1) send_sample(3'b000); 

    flush_delay_chain();

    // -------------------------------------------------------
    // [Scenario 3] Mixed Pattern
    // -------------------------------------------------------
    $display("\n==================================================");
    $display(" [Scenario 3] Mixed Pattern (1, -1, 3, -3)");
    $display("==================================================");

    send_sample(3'b001); 
    send_sample(3'b111); 
    send_sample(3'b011); 
    send_sample(3'b101); 
    
    repeat(15) send_sample(3'b000); 
    flush_delay_chain();

    // -------------------------------------------------------
    // [Scenario 4] Small Tap Count Test (Variable Tap)
    // -------------------------------------------------------
    $display("\n==================================================");
    $display(" [Scenario 4] Small Tap Test: 9 Taps (5 Unique)");
    $display("==================================================");

    @(posedge iClk12M);
    iCoeffUpdateFlag = 1;
    iNumOfCoeff = 5; // = 9 Taps

    // 5개의 계수만 입력
    write_coeff(0, 100); 
    write_coeff(1, 200); 
    write_coeff(2, 300); 
    write_coeff(3, 400); 
    write_coeff(4, 500); // Center (9번째 Tap)

    @(posedge iClk12M);
    iCoeffUpdateFlag = 0;
    #200;

    // Impulse 입력
    send_sample(3'b001); 
    
    // 9 Taps이므로 15번만 기다려도 결과가 다 나오고 0이 되어야 함
    for(i=0; i<15; i=i+1) send_sample(3'b000); 

    // -------------------------------------------------------
    // [Scenario 5] Overflow Test (Max Capacity)
    // -------------------------------------------------------
    $display("\n==================================================");
    $display(" [Scenario 5] OVERFLOW TEST: Max Coefficients");
    $display("==================================================");

    @(posedge iClk12M);
    iCoeffUpdateFlag = 1;
    iNumOfCoeff = 30; // 17개를 넘어서는 잘못된 입력 테스트

    for(i=0; i<17; i=i+1) write_coeff(i[5:0], 100); 
    for(i=17; i<30; i=i+1) write_coeff(i[5:0], 9999); // Garbage values

    @(posedge iClk12M);
    iCoeffUpdateFlag = 0;
    #200;

    send_sample(3'b001); 
    for(i=0; i<40; i=i+1) send_sample(3'b000); 

    flush_delay_chain(); 

    // -------------------------------------------------------
    // [Scenario 6] Saturation Stress Test
    // -------------------------------------------------------
    $display("\n==================================================");
    $display(" [Scenario 6] Saturation Stress Test");
    $display("==================================================");

    // Max Values to provoke saturation
    @(posedge iClk12M);
    iCoeffUpdateFlag = 1;
    iNumOfCoeff = 17; 
    for(i=0; i<17; i=i+1) write_coeff(i[5:0], 16'h7FFF); 
    @(posedge iClk12M);
    iCoeffUpdateFlag = 0;
    #200;

    // Inject Max Input (+3) repeatedly
    for(i=0; i<10; i=i+1) send_sample(3'b011); 
    
    flush_delay_chain();

    // -------------------------------------------------------
    // [Scenario 7] Interrupt Test (Stability Check)
    // -------------------------------------------------------
    $display("\n==================================================");
    $display(" [Scenario 7] Stability Test: Interrupt MID-Operation");
    $display("==================================================");

    // Setup Normal Coeffs (Short Filter)
    @(posedge iClk12M); iCoeffUpdateFlag = 1; iNumOfCoeff = 5;
    for(i=0; i<5; i=i+1) write_coeff(i[5:0], 200);
    @(posedge iClk12M); iCoeffUpdateFlag = 0;
    #200;

    // Start Sample
    @(posedge iClk12M);
    iFirIn = 3'b001; iEnSample600k = 1;
    @(posedge iClk12M); iEnSample600k = 0;

    repeat(5) @(posedge iClk12M);
    
    $display(" -> Interrupting FSM with Update Flag...");
    iCoeffUpdateFlag = 1; // 강제 인터럽트

    repeat(15) @(posedge iClk12M);
    iCoeffUpdateFlag = 0;
    #200;

    // FSM Alive Check (Recovery)
    send_sample(3'b001);
    flush_delay_chain();

    $display("\n==================================================");
    $display(" ALL TESTS COMPLETED SUCCESSFULLY.");
    $display("==================================================");
    $finish;

    flush_delay_chain();

    // -------------------------------------------------------
    // [Scenario 8] Reset Attack Test (Async Reset during Write)
    // -------------------------------------------------------
    $display("\n==================================================");
    $display(" [Scenario 8] Reset Attack: Reset while Writing Coeffs");
    $display("==================================================");

    // 1. 계수 쓰기 시작
    @(posedge iClk12M);
    iCoeffUpdateFlag = 1;
    iNumOfCoeff = 17; 

    write_coeff(0, 1111);
    write_coeff(1, 2222);
    write_coeff(2, 3333);
    
    // 2. [공격!] 쓰는 도중에 리셋 때려버리기
    $display("   -> !!! SYSTEM RESET TRIGGERED !!!");
    #10; 
    iRsn = 0; // Active Low Reset
    #50;      // 리셋 유지
    iRsn = 1; // 리셋 해제 (Recovery)
    #100;

    // 3. 복구 확인 (Recovery Check)
    // 리셋이 제대로 됐다면, FSM은 IDLE 상태여야 하고
    // 다시 처음부터 계수를 쓰면 정상 동작해야 함.
    $display("   -> System Recovered. Re-writing correct coefficients...");
    
    @(posedge iClk12M);
    iCoeffUpdateFlag = 1; // 다시 플래그 올림
    iNumOfCoeff = 5;      // 테스트를 위해 짧게 5개만 다시 설정
    
    write_coeff(0, 10);
    write_coeff(1, 20);
    write_coeff(2, 30);
    write_coeff(3, 40);
    write_coeff(4, 50);
    
    @(posedge iClk12M);
    iCoeffUpdateFlag = 0; // 플래그 내림
    #200;

    // 4. 동작 확인
    send_sample(3'b001); 
    for(i=0; i<15; i=i+1) send_sample(3'b000); 

    $display("\n==================================================");
    $display(" ALL TESTS (Inc. Variable Tap & Reset) COMPLETED.");
    $display("==================================================");
    $finish;
 
    flush_delay_chain();

    // -------------------------------------------------------
    // [Scenario 9] ACC Attack Test 
    // -------------------------------------------------------
    $display("\n==================================================");
    $display(" [Scenario 9] Acc Attack Test");
    $display("==================================================");

    // ============================================================
    // Step 1: 쓰레기 값 누적하기 (Accumulate)
    // 목표: 내부에 20이라는 값을 만듦
    // ============================================================
    @(posedge iClk);
    iEnMul = 1; iEnAcc = 1; iEnAdd = 0; 
    iIsCenter = 1; // Center mode (Head * Coeff)
    iDelayHead = 3'd2; // Data = 2
    iCoeff = 16'd10;   // Coeff = 10 -> Result = 20
    
    @(posedge iClk); 
    // 1클럭 후 oMac은 20이 되어야 함
    #1; $display("[Step 1] Acc Mode: Input(2*10), Prev(0)  -> Result: %d (Exp: 20)", oMac);


    // ============================================================
    // Step 2: iEnAdd 테스트 (핵심!)
    // 목표: 이전 값(20)을 무시하고 새로운 값(100)으로 덮어쓰는지 확인
    // ============================================================
    @(posedge iClk);
    iEnMul = 1; 
    iEnAcc = 0; 
    iEnAdd = 1; // [중요] Load Signal 활성화!
    
    iDelayHead = 3'd1; // Data = 1
    iCoeff = 16'd100;  // Coeff = 100 -> MulResult = 100
    
    @(posedge iClk);
    #1; 
    if (oMac == 100) 
        $display("[Step 2] Add Mode: Input(1*100), Prev(20) -> Result: %d (Exp: 100) -> PASS!!", oMac);
    else 
        $display("[Step 2] Add Mode: Input(1*100), Prev(20) -> Result: %d (Exp: 100) -> FAIL!! (Did it accumulate?)", oMac);


    // ============================================================
    // Step 3: 다시 누적하기 (Re-Accumulate)
    // 목표: 로드된 값(100)에 새로운 값(50)이 더해지는지 확인 (150)
    // ============================================================
    @(posedge iClk);
    iEnMul = 1; 
    iEnAcc = 1; // 다시 Acc 모드
    iEnAdd = 0; 
    
    iDelayHead = 3'd5; // Data = 5
    iCoeff = 16'd10;   // Coeff = 10 -> MulResult = 50
    
    @(posedge iClk);
    #1;
    if (oMac == 150)
        $display("[Step 3] Acc Mode: Input(5*10), Prev(100) -> Result: %d (Exp: 150) -> PASS!!", oMac);
    else
        $display("[Step 3] Acc Mode: Input(5*10), Prev(100) -> Result: %d (Exp: 150) -> FAIL!!", oMac);

    // 종료
    #20;
    $finish;
end

  

endmodule