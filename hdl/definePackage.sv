//-----------------------------------------------------------------------
//-- Title: Define Package
//-- Author: zwenergy
//-----------------------------------------------------------------------
`define RES0_1080P
`define SCALE6

package definePackage;
  localparam AUDIO_BIT_WIDTH = 16;
  
  `ifdef RES0_720P
  localparam pxlClkFrq = 74250.0;
  localparam widthMax = 1650;
  localparam heightMax = 750;
  localparam FRAMEWIDTH = 1280;
  localparam FRAMEHEIGHT = 720;
  localparam CLKMULT = 37.125;
  localparam CLKDIV = 5;
  localparam CLK0DIV = 2.0;
  localparam CLK1DIV = 10;
  localparam pxlClkPeriod = 13.468013;
  localparam SMOOTHENABLE = 1;
  localparam GBACLKMUL = 532;
  localparam GBACLKDIV = 9375;
  localparam VIDEOID = 4;
  `endif
  
  `ifdef RES0_1080P
  localparam pxlClkFrq = 148500.0;
  localparam widthMax = 2200;
  localparam heightMax = 1125;
  localparam FRAMEWIDTH = 1920;
  localparam FRAMEHEIGHT = 1080;
  localparam CLKMULT = 37.125;
  localparam CLKDIV = 5;
  localparam CLK0DIV = 1.0;
  localparam CLK1DIV = 5;
  localparam pxlClkPeriod = 6.734007;
  localparam SMOOTHENABLE = 0;
  localparam GBACLKMUL = 266;
  localparam GBACLKDIV = 9375;
  localparam VIDEOID = 16;
  `endif
  
  
`ifdef SCALE4
localparam maxScaleCnt = 3;
`endif

`ifdef SCALE6
localparam maxScaleCnt = 5;
`endif
endpackage
