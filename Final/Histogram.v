module Histogram
(
    input iClk,
    input iRst_n,
    input iClearRam,
    input [7:0] iGray,
    input iValid,
    
    /* RAM I/O */
    output [7:0] oReadAddr, 
    output reg [7:0] oWriteAddr,
    output reg oWriteEnable,
    output reg [19:0] oDataOut,
    input [19:0] iDataIn
);

reg ValidD1;
reg [7:0] oWriteAddrD1;

wire s = oWriteAddr == oReadAddr;

assign oReadAddr = iGray;

always @(posedge iClk) begin
    if (!iRst_n) begin
        oWriteAddr <= 8'b0;
        oWriteAddrD1 <= 8'b0;
        oWriteEnable <= 1'b0;
        oDataOut <= 20'b0;
        ValidD1 <= 1'b0;
    end else begin
        if (iClearRam) begin
            oWriteAddr <= oWriteAddr + 1'b1;
            oWriteEnable <= 1'b1;
            oDataOut <= 20'b0;
        end else begin
            /* Cycle 1. - Ask the RAM for data*/
            ValidD1 <= iValid;
            oWriteAddrD1 <= oReadAddr;
            /* Cycle 2. - Place the incremented data on the bus, with correct address */
            oWriteAddr <= oWriteAddrD1;
            /*if (oWriteAddr == oReadAddr) begin
                oDataOut <= oDataOut + 1'b1;
            end else begin*/
                oDataOut <= iDataIn + 1'b1;
            //end
            oWriteEnable <= ValidD1;
       end 
    end
end

endmodule
