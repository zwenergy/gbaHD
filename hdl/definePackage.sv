//-----------------------------------------------------------------------
//-- Title: Define Package
//-- Author: zwenergy
//-----------------------------------------------------------------------
`define RES0_720P
`define SCALE4

package definePackage;
  localparam AUDIO_BIT_WIDTH = 16;
  
  `ifdef RES0_720P
  localparam pxlClkFrq = 75468.75;
  localparam widthMax = 1512;
  localparam heightMax = 836;
  localparam CLKMULT = 60.375;
  localparam CLKDIV = 8;
  localparam CLK0DIV = 2.0;
  localparam CLK1DIV = 10;
  localparam CLK2DIV = 90;
  localparam pxlClkPeriod = 13.251;
  `endif
  
  `ifdef RES1_720P
  localparam pxlClkFrq = 83750.0;
  localparam widthMax = 1672;
  localparam heightMax = 840;
  localparam CLKMULT = 8.375;
  localparam CLKDIV = 1;
  localparam CLK0DIV = 2.0;
  localparam CLK1DIV = 10;
  localparam CLK2DIV = 100;
  localparam pxlClkPeriod = 11.940299;
  `endif
  
  
`ifdef SCALE4
localparam maxScaleCnt = 3;
`endif
endpackage
