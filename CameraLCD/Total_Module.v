`default_nettype none

module Total_Module
  (
    // General
    input wire CCD_PIXCLK,
    input wire iRst_n,

    // Frame Related
    input wire [15:0] iX_Cont,
    input wire [15:0] iY_Cont,
    input wire iFval,

    // RGB
    input wire [11:0] iCCD_R,
    input wire [11:0] iCCD_G,
    input wire [11:0] iCCD_B,
    input wire [7:0] iDelayedGray,
    input wire iCCD_DVAL,

    // Display
    input wire [17:0] iDisplaySelect,

    // Output
    output wire [15:0] wr1_data,
    output wire [15:0] wr2_data,
    output wire WR_DATA_VAL
  );

  // Registers and Wires				
  wire GRAY_VAL;
  wire [7:0] GRAY_DATA;
  wire [15:0] gX_Cont, gY_Cont;
  wire [19:0] maxDisplayVal;
  reg Rst_nR;

  /* Histogram Ram and displayer */
  wire [19:0] display_hist_q;
  wire [7:0] display_hist_rda;
  wire [7:0] histo_pixel;
  wire histo_disp_red;

  /* Cumulative Histogram Ram and displayer */
  wire [7:0] display_cumh_rda;
  wire [19:0] display_cumh_q;
  wire [7:0] cumh_pixel;
  wire [7:0] thresh_pixel, thresh_delayed_pixel, MultiThreshPixel;
  wire [7:0] cumulative_histo_threshold, THRESH_25, THRESH_75;
  wire hist_val;
  wire thresh_val, thresh_delayed_val;
  wire cumh_disp_red;
  wire MultiThreshValid;
  
  wire iClk = CCD_PIXCLK;
  reg rCCD_DVAL, dCCD_DVAL;
  reg [7:0] d_delayed_gray, r_delayed_gray;

  
  // Module Instantiations
  RGB2GRAY r2g (
    .iCLK(iClk),
    .iReset_n(iRst_n),
    .iRed(iCCD_R),
    .iGreen(iCCD_G),
    .iBlue(iCCD_B),
    .iDval(iCCD_DVAL),
    .iX_Cont(iX_Cont),
    .iY_Cont(iY_Cont),
    .oX_Cont(gX_Cont),
    .oY_Cont(gY_Cont),
    .oGray(GRAY_DATA),
    .oDval(GRAY_VAL)				
  );

  Total_Histogram T1
  (
    .iClk(iClk),
    .iRst_n(iRst_n),
    .iGray(GRAY_DATA),
    .iGrayValid(GRAY_VAL),
    .iFvalid(iFval),
    .iX_Cont(gX_Cont),
    .iY_Cont(gY_Cont),
    .iReadGray(display_hist_rda),
    .oGray(),
    .oGrayHisto(display_hist_q),
    .oMaxValue(maxDisplayVal),
    .oGrayCumHisto(display_cumh_q),
    
    .oThresh(cumulative_histo_threshold),
	 .oThresh25(THRESH_25),
	 .oThresh75(THRESH_75),
    .oDone()
  );					

  HistogramDisplayer histo_display
  (
    .iClk(iClk),
    .iValid(iCCD_DVAL),
    .X_Cont(iX_Cont),
    .Y_Cont(iY_Cont),
    .iHistoValue(display_hist_q),
    .iMaxValue(maxDisplayVal),
	 .iThreshPoint25(THRESH_25),
    .iThreshPoint50(cumulative_histo_threshold),
	 .iThreshPoint75(THRESH_75),
    .oHistoAddr(display_hist_rda),
    .oPixel(histo_pixel),
    .oRed(histo_disp_red),
    .oValid(hist_val)
  );

  HistogramDisplayer cumh_display
  (
    .iClk(iClk),
    .X_Cont(iX_Cont),
    .Y_Cont(iY_Cont),
    .iHistoValue(display_cumh_q),
    .iMaxValue(20'd384000),
    .iThreshPoint25(cumulative_histo_threshold),
    .iThreshPoint50(cumulative_histo_threshold),
	 .iThreshPoint75(cumulative_histo_threshold),
    .oRed(cumh_disp_red),
    .oPixel(cumh_pixel)
  );

  Thresholder thresher 
  (
    .iClk(iClk), 
    .iGray(GRAY_DATA),
    .iValid(GRAY_VAL), 
    .iThreshold(cumulative_histo_threshold), 
    .oValid(thresh_val),
    .oPixel(thresh_pixel)
  );
  
  Thresholder thresher_delayed(
      .iClk(iClk),
      .iGray(d_delayed_gray), 
      .iValid(GRAY_VAL),
      .iThreshold(cumulative_histo_threshold),
      .oValid(thresh_delayed_val),
      .oPixel(thresh_delayed_pixel)
      );
  
  MultiThresh m_thresher(
	.iClk(iClk), 
	.iGray(GRAY_DATA),
	.iValid(GRAY_VAL),
	.iThresh1(THRESH_25),
	.iThresh2(THRESH_75),
	.iX_Cont(gX_Cont),
	.iY_Cont(gY_Cont),
	.iSmooth(iDisplaySelect[8]),
	.oPixel(MultiThreshPixel),
	.oValid(MultiThreshValid)
	);

  Arbitrator arbiter
  (
    .iClk(iClk),
    .iRst_n(iRst_n),
    // Select Input
    .iSelect(iDisplaySelect),
    .iFval(iFval), // ?????????

    // Coordinates
    .iX_Cont(iX_Cont),
    .iY_Cont(iY_Cont),

    // RGB Inputs
    .iRGB_R(iCCD_R),
    .iRGB_G(iCCD_G),
    .iRGB_B(iCCD_B),
    .iRGB_Valid(iCCD_DVAL),

    // GRAY Inputs
    .iGray(GRAY_DATA),
    .iGray_Valid(GRAY_VAL),

    // Histogram Inputs
    .iHist(histo_pixel),
    .iThresholdLevel(cumulative_histo_threshold),
    .iHist_Valid(hist_val),
    .iHist_Red(histo_disp_red),

    // CUmulative inputs
    .iCumHist(cumh_pixel),
    .iCumHistRed(cumh_disp_red),

    // Threshold Input
    .iThresh(thresh_pixel),
    .iThresh_Valid(thresh_val),
    
    .iThreshDelayed(thresh_delayed_pixel),
    .iThreshDelayed_Valid(thresh_delayed_val),
	 
	 // Multithreshold Input
	 .iMultiThresh(MultiThreshPixel),
	 .iMultiThreshValid(MultiThreshValid),

    // Outputs
    .oWr1_data(wr1_data),
    .oWr2_data(wr2_data),
    .oWr_data_valid(WR_DATA_VAL)
  );

endmodule
