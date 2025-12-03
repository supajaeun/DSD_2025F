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

  // --- Loop Variables ---
  integer sample_idx;
  integer k;

  // --- Clock Generation (12MHz) ---
  initial iClk12M = 0;
  always #41.666 iClk12M = ~iClk12M;

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

  // --- Task: 계수 쓰기 ---
  task write_coeff(input [5:0] addr, input signed [15:0] data);
    begin
      @(posedge iClk12M);
      iAddrRam = addr;
      iWrDtRam = data;
      @(posedge iClk12M);
    end
  endtask

  // --- Main Test Sequence ---
  initial begin
    $dumpfile("waveform_kaiser_21taps.vcd");
    $dumpvars(0, TB_DUT);

    // 1. 초기화
    iRsn = 0;
    iEnSample600k = 0;
    iCoeffUpdateFlag = 0;
    iAddrRam = 0;
    iWrDtRam = 0;
    
    // [중요] 21개만 사용하도록 설정
    iNumOfCoeff = 21; 
    iFirIn = 3'd0;

    #200;
    iRsn = 1;
    #100;

    // ---------------------------------------------------------
    // 2. 계수 업데이트 (Kaiser Window Center 21 Taps)
    // ---------------------------------------------------------
    $display("--- [Step 1] Writing 21 Coefficients (Center Taps) ---");
    iCoeffUpdateFlag = 1;

    // 카이저 윈도우의 가운데 부분 (n-10 ~ n+10) 21개를 입력합니다.
    write_coeff(0,  13);    // n-10
    write_coeff(1,  0);     // n-9
    write_coeff(2,  -19);   // n-8
    write_coeff(3,  24);    // n-7
    write_coeff(4,  0);     // n-6
    write_coeff(5,  -37);   // n-5
    write_coeff(6,  48);    // n-4
    write_coeff(7,  0);     // n-3
    write_coeff(8,  -102);  // n-2
    write_coeff(9,  206);   // n-1
    write_coeff(10, 500);   // n (Center Tap)
    write_coeff(11, 206);   // n+1
    write_coeff(12, -102);  // n+2
    write_coeff(13, 0);     // n+3
    write_coeff(14, 48);    // n+4
    write_coeff(15, -37);   // n+5
    write_coeff(16, 0);     // n+6
    write_coeff(17, 24);    // n+7
    write_coeff(18, -19);   // n+8
    write_coeff(19, 0);     // n+9
    write_coeff(20, 13);    // n+10 (여기까지 21개)

    // [중요] Zero Padding
    // 21개를 처리하려면 4개씩 6번 루프(총 24개)를 돕니다.
    // 따라서 21, 22, 23번지는 반드시 0으로 채워야 결과가 오염되지 않습니다.
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
        if (sample_idx == 0) iFirIn = 3'b001; 
        else iFirIn = 3'b000;

        @(posedge iClk12M);
        iEnSample600k = 1; 
        @(posedge iClk12M);
        iEnSample600k = 0;

        // 21개 연산은 훨씬 빠르므로 대기 시간은 충분합니다.
        repeat(19) @(posedge iClk12M);
    end

    #500;

    // ---------------------------------------------------------
    // 4. Negative Impulse Test (-1)
    // ---------------------------------------------------------
    $display("--- [Step 3] Testing Negative Impulse (-1) ---");
    for (sample_idx = 0; sample_idx < 64; sample_idx = sample_idx + 1) begin
        if (sample_idx == 0) iFirIn = 3'b111; 
        else iFirIn = 3'b000;

        @(posedge iClk12M);
        iEnSample600k = 1; 
        @(posedge iClk12M);
        iEnSample600k = 0;

        repeat(19) @(posedge iClk12M);
    end

    #1000;
    $finish;
  end

endmodule