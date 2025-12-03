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
  reg signed [2:0] iFirIn; // signed로 선언하여 음수 표현 명확화

  // --- Outputs ---
  wire signed [15:0] oFirOut;
  wire [15:0] oWaveform;

  // --- Loop Variables ---
  integer k;
  integer sample_idx;

  // --- Clock Generation (12MHz) ---
  initial iClk12M = 0;
  always #41.666 iClk12M = ~iClk12M; // Period approx 83.33ns

  // --- Instantiation ---
  DUT_top u_DUT (
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

  // --- Task: 계수 쓰기 (Coefficient Write) ---
  task write_coeff(input [5:0] addr, input [15:0] data);
    begin
      @(posedge iClk12M);
      iAddrRam = addr;
      iWrDtRam = data;
      @(posedge iClk12M);
    end
  endtask

  // --- Main Test Sequence ---
  initial begin
    // Waveform Dump (필요시 사용)
    $dumpfile("waveform_impulse.vcd");
    $dumpvars(0, TB_DUT);

    // 1. 초기화
    iRsn = 0;
    iEnSample600k = 0;
    iCoeffUpdateFlag = 0;
    iAddrRam = 0;
    iWrDtRam = 0;
    iNumOfCoeff = 40; // 탭 개수 40개 설정
    iFirIn = 3'd0;

    #200;
    iRsn = 1; // Reset 해제
    #100;

    // ---------------------------------------------------------
    // 2. 계수 업데이트 (Coefficient Update)
    // ---------------------------------------------------------
    $display("--- [Step 1] Writing Coefficients ---");
    iCoeffUpdateFlag = 1;
    
    // Impulse Response를 눈으로 확인하기 좋게
    // 계수를 1, 2, 3 ... 40 처럼 증가하는 값으로 설정합니다.
    // 이렇게 하면 출력 파형이 계단 모양(1,2,3...)으로 보여야 정상입니다.
    for (k=0; k<40; k=k+1) begin
        write_coeff(k[5:0], k + 1); // Coeff[0]=1, Coeff[1]=2 ...
    end

    @(posedge iClk12M);
    iCoeffUpdateFlag = 0;
    $display("--- Coefficient Write Done ---");
    #200;

    // ---------------------------------------------------------
    // 3. Impulse Response Test (Positive Impulse: 3'b001)
    // ---------------------------------------------------------
    $display("--- [Step 2] Testing Positive Impulse (3'b001) ---");
    
    // 교수님 요청: 64번의 샘플링 주기 동안 패턴 입력
    // 주기: 600kHz (12MHz / 20 = 20 clocks)
    for (sample_idx = 0; sample_idx < 64; sample_idx = sample_idx + 1) begin
        
        // (1) 입력 데이터 설정
        if (sample_idx == 0) begin
            iFirIn = 3'b001; // 첫 번째만 Impulse (1)
            $display("Injecting Impulse: 1");
        end else begin
            iFirIn = 3'b000; // 나머지는 0
        end

        // (2) Sampling Enable Pulse (1 cycle duration)
        @(posedge iClk12M);
        iEnSample600k = 1; 
        @(posedge iClk12M);
        iEnSample600k = 0;

        // (3) Wait for next sample (19 clocks to make it 20 clocks total)
        repeat(19) @(posedge iClk12M);
    end

    #500; // 구분 딜레이

    // ---------------------------------------------------------
    // 4. Impulse Response Test (Negative Impulse: 3'b111)
    // ---------------------------------------------------------
    $display("--- [Step 3] Testing Negative Impulse (3'b111 -> -1) ---");

    for (sample_idx = 0; sample_idx < 64; sample_idx = sample_idx + 1) begin
        
        // (1) 입력 데이터 설정
        if (sample_idx == 0) begin
            iFirIn = 3'b111; // -1 (2's complement 3bit)
            $display("Injecting Impulse: -1");
        end else begin
            iFirIn = 3'b000; 
        end

        // (2) Sampling Enable Pulse
        @(posedge iClk12M);
        iEnSample600k = 1; 
        @(posedge iClk12M);
        iEnSample600k = 0;

        // (3) Wait 19 clocks
        repeat(19) @(posedge iClk12M);
    end

    #1000;
    $display("Test Finished");
    $finish;
  end

endmodule


