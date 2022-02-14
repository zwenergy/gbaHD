//-----------------------------------------------------------------------
//-- Title: Define Package
//-- Author: zwenergy
//-----------------------------------------------------------------------
`define RES0_1080P
`define SCALE6

package definePackage;
  localparam AUDIO_BIT_WIDTH = 16;
  
  `ifdef RES0_480P
  localparam pxlClkFrq_60hz = 27000.0;
  localparam pxlClkFrq_59hz = 26888.888889;
  localparam widthMax = 858;
  localparam heightMax = 525;
  localparam FRAMEWIDTH = 720;
  localparam FRAMEHEIGHT = 480;
  localparam CLKMULT = 47.25;
  localparam CLKDIV = 5;
  localparam CLK0DIV = 7.0;
  localparam CLK1DIV = 35;
  localparam pxlClkPeriod_60hz = (1/pxlClkFrq_60hz)*1000000;
  localparam pxlClkPeriod_59hz = (1/pxlClkFrq_59hz)*1000000;
  localparam SMOOTHENABLE = 0;
  localparam GBACLKMUL = 152;
  localparam GBACLKDIV = 975;
  localparam VIDEOID = 2;
  localparam VIDEO_REFRESH = 59.94;
  `endif
  
  `ifdef RES0_720P
  localparam pxlClkFrq_60hz = 74250.0;
  localparam pxlClkFrq_59hz = 73878.750;
  localparam widthMax = 1650;
  localparam heightMax = 750;
  localparam FRAMEWIDTH = 1280;
  localparam FRAMEHEIGHT = 720;
  localparam CLKMULT = 37.125;
  localparam CLKDIV = 5;
  localparam CLK0DIV = 2.0;
  localparam CLK1DIV = 10;
  localparam pxlClkPeriod_60hz = (1/pxlClkFrq_60hz)*1000000;
  localparam pxlClkPeriod_59hz = (1/pxlClkFrq_59hz)*1000000;
  localparam SMOOTHENABLE = 1;
  localparam GBACLKMUL = 532;
  localparam GBACLKDIV = 9375;
  localparam VIDEOID = 4;
  localparam VIDEO_REFRESH = 60.0;
  `endif
  
  `ifdef RES0_1080P
  localparam pxlClkFrq_60hz = 148500.0;
  localparam pxlClkFrq_59hz = 147812.5;
  localparam widthMax = 2200;
  localparam heightMax = 1125;
  localparam FRAMEWIDTH = 1920;
  localparam FRAMEHEIGHT = 1080;
  localparam CLKMULT = 37.125;
  localparam CLKDIV = 5;
  localparam CLK0DIV = 1.0;
  localparam CLK1DIV = 5;
  localparam pxlClkPeriod_60hz = (1/pxlClkFrq_60hz)*1000000;
  localparam pxlClkPeriod_59hz = (1/pxlClkFrq_59hz)*1000000;
  localparam SMOOTHENABLE = 0;
  localparam GBACLKMUL = 266;
  localparam GBACLKDIV = 9375;
  localparam VIDEOID = 16;
  localparam VIDEO_REFRESH = 60.0;
  `endif
  
  
`ifdef SCALE4
localparam maxScaleCnt = 3;
`endif

`ifdef SCALE6
localparam maxScaleCnt = 5;
`endif

`ifdef SCALE3
localparam maxScaleCnt = 2;
`endif
endpackage