module gridGen #(
    // out = in * (1 (+/-) 2^-ALPHA)
    int ALPHA,
    // out = in (+/-) DELTA
    int DELTA
) (
    input logic [7:0] pxlInRed,
    input logic [7:0] pxlInGreen,
    input logic [7:0] pxlInBlue,
    input logic gridAct,
    input logic brightGrid,
    input logic gridMult,
    output logic [7:0] pxlOutRed,
    output logic [7:0] pxlOutGreen,
    output logic [7:0] pxlOutBlue
);

function logic [7:0] apply(logic [7:0] value, logic bright, logic mult);
    logic [7:0] delta = mult ? value >> ALPHA : DELTA;
    logic [8:0] sum;

    // Saturating addition/subtraction
    if (bright) begin
        sum = value + delta;
        return sum[8] ? 255 : sum[7:0];
    end else begin
        sum = value - delta;
        return sum[8] ? 0 : sum[7:0];
    end
endfunction

assign pxlOutRed = gridAct ? apply(pxlInRed, brightGrid, gridMult) : pxlInRed;
assign pxlOutGreen = gridAct ? apply(pxlInGreen, brightGrid, gridMult) : pxlInGreen;
assign pxlOutBlue = gridAct ? apply(pxlInBlue, brightGrid, gridMult) : pxlInBlue;

endmodule
