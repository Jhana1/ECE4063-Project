module HistogramDisplayer(
	input iClk,
	input iValid,
	input [15:0] X_Cont,
	input [15:0] Y_Cont,
	input [19:0] iHistoValue,
  input [19:0] iMaxValue,
  input [7:0] iThreshPoint,
  output [7:0] oHistoAddr,
  output reg [7:0] oPixel,
  output reg oRed,
  output reg oValid);
parameter MidPoint = 383;
/* Pull in the histogram value based on Y_Cont from the RAM */

assign oHistoAddr = (MidPoint - Y_Cont);

reg rValid;
reg [3:0] Normalize;
reg [19:0] rMaxValue;

always @(posedge iClk) begin
	if ((800 - X_Cont) < (iHistoValue >> Normalize) && (383 - Y_Cont) < 255) begin
		oPixel   <= 255;
    oRed <= (oHistoAddr == iThreshPoint);
  end else begin
    oPixel <= 0;
  end
end

always @(posedge iClk) begin
	rValid <= iValid;
	oValid <= rValid;
end

always @ (posedge iClk) begin
  rMaxValue <= iMaxValue;
  casex (rMaxValue)
    20'b1xxxxxxxxxxxxxxxxxxx: Normalize <= 10; // 2^20
    20'b01xxxxxxxxxxxxxxxxxx: Normalize <= 9; // 2^19
    20'b001xxxxxxxxxxxxxxxxx: Normalize <= 9; // 2^18
    20'b0001xxxxxxxxxxxxxxxx: Normalize <= 8; // 17
    20'b00001xxxxxxxxxxxxxxx: Normalize <= 7;
    20'b000001xxxxxxxxxxxxxx: Normalize <= 6;
    20'b0000001xxxxxxxxxxxxx: Normalize <= 5;
    20'b00000001xxxxxxxxxxxx: Normalize <= 4;
    20'b000000001xxxxxxxxxxx: Normalize <= 3;
    20'b0000000001xxxxxxxxxx: Normalize <= 2;
    default:                  Normalize <= 1; // Shouldn't get this low as minimum possible max vaule is 1500 (All pixels evenly distributed)
  endcase
end
endmodule
