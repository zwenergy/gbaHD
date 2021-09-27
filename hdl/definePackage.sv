//-----------------------------------------------------------------------
//-- Title: Define Package
//-- Author: zwenergy
//-----------------------------------------------------------------------
`define RES0_720P
`define SCALE4

package definePackage;
  localparam AUDIO_BIT_WIDTH = 16;
  
  `ifdef RES0_720P
  localparam pxlClkFrq = 74250.0;
  localparam widthMax = 1650;
  localparam heightMax = 750;
  localparam CLKMULT = 37.125;
  localparam CLKDIV = 5;
  localparam CLK0DIV = 2.0;
  localparam CLK1DIV = 10;
  localparam pxlClkPeriod = 13.468013;
  `endif
  
  
`ifdef SCALE4
localparam maxScaleCnt = 3;
`endif
endpackage
