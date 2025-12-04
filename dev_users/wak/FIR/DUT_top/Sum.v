module Sum #(
    parameter IN_WIDTH  = 25,
    parameter OUT_WIDTH = 16
) (
    input                          iClk12M,
    input                          iRsn,

    input signed [IN_WIDTH-1:0]    iMac1,
    input signed [IN_WIDTH-1:0]    iMac2,
    input signed [IN_WIDTH-1:0]    iMac3,
    input signed [IN_WIDTH-1:0]    iMac4,

    input                          iEnSum,

    output reg signed [OUT_WIDTH-1:0] oFirOut
);

    wire signed [IN_WIDTH+1:0] wSumResult;

    localparam signed [IN_WIDTH+1:0] MAX_VAL =  27'sd32767;
    localparam signed [IN_WIDTH+1:0] MIN_VAL = -27'sd32768;

    // 반드시 signed로 합산
    assign wSumResult =
        $signed(iMac1) +
        $signed(iMac2) +
        $signed(iMac3) +
        $signed(iMac4);

    always @(posedge iClk12M or negedge iRsn) begin
        if (!iRsn)
            oFirOut <= {OUT_WIDTH{1'b0}};
        else if (iEnSum) begin
            if (wSumResult > MAX_VAL)
                oFirOut <= 16'h7FFF;
            else if (wSumResult < MIN_VAL)
                oFirOut <= 16'h8000;
            else
                oFirOut <= wSumResult[OUT_WIDTH-1:0];
        end
    end

endmodule
