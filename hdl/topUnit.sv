//-----------------------------------------------------------------------
//-- Title: Top Unit
//-- Author: zwenergy
//-----------------------------------------------------------------------

import definePackage::*;

module topUnit
(
  input clk,
  
  input [4:0] redPxl,
  input [4:0] greenPxl,
  input [4:0] bluePxl,
  input dclk,
  input vsync,
  input audioLIn,
  input audioRIn,
  input controllerMCUIn,
  
  output gbaClk,
  
  output [2:0] hdmiTX,
  output [2:0] hdmiTXN,
  output hdmiClk,
  output hdmiClkN,
  input hdmiCEC,
  inout hdmiSDA,
  inout hdmiSCL,
  input hdmiHPD
);


// Generate clocks.
wire pxlClk, pxlClkInt, pxlClkx5, pxlClkx5Int, gbaClkx2, gbaClkx2Int, 
  clkFB, clkLock;
wire [2:0] tmds;
wire tmdsClk;

MMCME2_BASE
  #( .DIVCLK_DIVIDE        (CLKDIV),
     .CLKFBOUT_MULT_F      (CLKMULT),
     .CLKOUT0_DIVIDE_F     (CLK0DIV),
     .CLKOUT1_DIVIDE       (CLK1DIV),
     .CLKIN1_PERIOD        (10.000))
mmc
   (
    .CLKFBOUT            (clkFB),
    .CLKOUT0             (pxlClkx5Int),
    .CLKOUT1             (pxlClkInt),
    .CLKFBIN             (clkFB),
    .LOCKED              (clkLock),
    .PWRDWN              (1'b0),
    .RST                 (1'b0),
    .CLKIN1( clk ) );

BUFG clkBuf0
  (.O (pxlClkx5),
   .I (pxlClkx5Int));
   
BUFG clkBuf1
  (.O (pxlClk),
   .I (pxlClkInt));


logic rst;
assign rst = !clkLock;

// GBA Clock. 532/9375 slower than the HDMI clock.
fracDiv #( .mul( 532 ), .div( 9375 ), .maxInt( 10000 ) )
fracDiv ( .clk( pxlClkInt ), .rst( rst ), .clkOut( gbaClk ) );

// GBA capture.
logic [7:0] redPxlCap, greenPxlCap, bluePxlCap;
logic validCap;
logic [7:0] pxlCntCap;
logic validLineCap, newFrameCap;
captureGBA #( .clkPeriodNS( pxlClkPeriod ) ) 
captureGBA( .clk( pxlClk ), 
            .rst( rst ), 
            .redPxl( redPxl ), 
            .bluePxl( bluePxl ), 
            .greenPxl( greenPxl ),
            .vsync( vsync ), 
            .dclk( dclk ), 
            .redPxlOut( redPxlCap ),
            .greenPxlOut( greenPxlCap ), 
            .bluePxlOut( bluePxlCap ), 
            .validPxlOut( validCap ), 
            .pxlCnt( pxlCntCap ), 
            .validLine( validLineCap ), 
            .newFrame( newFrameCap ) );

// Line buffer.
logic [7:0] redBuff, greenBuff, blueBuff, redBuffPrev, greenBuffPrev, 
  blueBuffPrev, redBuffNext, greenBuffNext, blueBuffNext;
logic [7:0] pxlCntReadBuff;
logic sameLineBuff, newFrameBuffOut;
logic pullLineBuff;

logic [7:0] curLineCurPxlRed, curLineCurPxlBlue, curLineCurPxlGreen,
  curLinePrevPxlRed, curLinePrevPxlBlue, curLinePrevPxlGreen,
  curLineNextPxlRed, curLineNextPxlBlue, curLineNextPxlGreen,
  prevLineCurPxlRed, prevLineCurPxlBlue, prevLineCurPxlGreen,
  prevLinePrevPxlRed, prevLinePrevPxlBlue, prevLinePrevPxlGreen,
  prevLineNextPxlRed, prevLineNextPxlBlue, prevLineNextPxlGreen,
  nextLineCurPxlRed, nextLineCurPxlBlue, nextLineCurPxlGreen,
  nextLinePrevPxlRed, nextLinePrevPxlBlue, nextLinePrevPxlGreen,
  nextLineNextPxlRed, nextLineNextPxlBlue, nextLineNextPxlGreen;
  
logic [5:0] controller;
logic controllerRXValid;

lineBuffer #( .nrStgs(20) ) 
lineBuffer( .clkW( pxlClk ), 
            .clkR( pxlClk ), 
            .rst( rst ), 
            .redIn( redPxlCap ), 
            .greenIn( greenPxlCap ), 
            .blueIn( bluePxlCap ),
            .wEn( validCap ), 
            .pxlCntWrite( pxlCntCap ), 
            .pushLine( validLineCap ), 
            .newFrameIn( newFrameCap ), 
            .redOutPrev( redBuffPrev ),
            .greenOutPrev( greenBuffPrev ),
            .blueOutPrev( blueBuffPrev ),
            .redOutCur( redBuff ),
            .greenOutCur( greenBuff ), 
            .blueOutCur( blueBuff ), 
            .redOutNext( redBuffNext ),
            .greenOutNext( greenBuffNext ),
            .blueOutNext( blueBuffNext ),
            .pxlCntRead( pxlCntReadBuff ), 
            .pullLine( pullLineBuff ), 
            .sameLine( sameLineBuff ),
            .newFrameOut( newFrameBuffOut ) );

// Line cache.
wire [7:0] pxlCntReadToCache;
logic cacheUpdate;
lineCache( .clk( pxlClk ),
           .rst( rst ),
           .curPxlCnt( pxlCntReadToCache ),
           .lineChange( cacheUpdate ),
           .curLineCurPxlRedIn( redBuff ),
           .curLineCurPxlGreenIn( greenBuff ),
           .curLineCurPxlBlueIn( blueBuff ),
           .prevLineCurPxlRedIn( redBuffPrev ),
           .prevLineCurPxlGreenIn( greenBuffPrev ),
           .prevLineCurPxlBlueIn( blueBuffPrev ),
           .nextLineCurPxlRedIn( redBuffNext ),
           .nextLineCurPxlGreenIn( greenBuffNext ),
           .nextLineCurPxlBlueIn( blueBuffNext ),
           
           .curLineCurPxlRedOut( curLineCurPxlRed ),
           .curLineCurPxlGreenOut( curLineCurPxlGreen ),
           .curLineCurPxlBlueOut( curLineCurPxlBlue ),
           .curLinePrevPxlRedOut( curLinePrevPxlRed ),
           .curLinePrevPxlGreenOut( curLinePrevPxlGreen ),
           .curLinePrevPxlBlueOut( curLinePrevPxlBlue ),
           .curLineNextPxlRedOut( curLineNextPxlRed ),
           .curLineNextPxlGreenOut( curLineNextPxlGreen ),
           .curLineNextPxlBlueOut( curLineNextPxlBlue ),
           
           .prevLineCurPxlRedOut( prevLineCurPxlRed ),
           .prevLineCurPxlGreenOut( prevLineCurPxlGreen ),
           .prevLineCurPxlBlueOut( prevLineCurPxlBlue ),
           .prevLinePrevPxlRedOut( prevLinePrevPxlRed ),
           .prevLinePrevPxlGreenOut( prevLinePrevPxlGreen ),
           .prevLinePrevPxlBlueOut( prevLinePrevPxlBlue ),
           .prevLineNextPxlRedOut( prevLineNextPxlRed ),
           .prevLineNextPxlGreenOut( prevLineNextPxlGreen ),
           .prevLineNextPxlBlueOut( prevLineNextPxlBlue ),
           
           .nextLineCurPxlRedOut( nextLineCurPxlRed ),
           .nextLineCurPxlGreenOut( nextLineCurPxlGreen ),
           .nextLineCurPxlBlueOut( nextLineCurPxlBlue ),
           .nextLinePrevPxlRedOut( nextLinePrevPxlRed ),
           .nextLinePrevPxlGreenOut( nextLinePrevPxlGreen ),
           .nextLinePrevPxlBlueOut( nextLinePrevPxlBlue ),
           .nextLineNextPxlRedOut( nextLineNextPxlRed ),
           .nextLineNextPxlGreenOut( nextLineNextPxlGreen ),
           .nextLineNextPxlBlueOut( nextLineNextPxlBlue ),
           
           .pxlCntRead( pxlCntReadBuff ) );


// Image generation.
imageGenV ( .pxlClk( pxlClk ),
            .pxlClk5x( pxlClkx5 ),
            .rst( rst ),
             
            .curLineCurPxlRedIn( curLineCurPxlRed ),
            .curLineCurPxlGreenIn( curLineCurPxlGreen ),
            .curLineCurPxlBlueIn( curLineCurPxlBlue ),
            .curLinePrevPxlRedIn( curLinePrevPxlRed ),
            .curLinePrevPxlGreenIn( curLinePrevPxlGreen ),
            .curLinePrevPxlBlueIn( curLinePrevPxlBlue ),
            .curLineNextPxlRedIn( curLineNextPxlRed ),
            .curLineNextPxlGreenIn( curLineNextPxlGreen ),
            .curLineNextPxlBlueIn( curLineNextPxlBlue ),
             
            .prevLineCurPxlRedIn( prevLineCurPxlRed ),
            .prevLineCurPxlGreenIn( prevLineCurPxlGreen ),
            .prevLineCurPxlBlueIn( prevLineCurPxlBlue ),
            .prevLinePrevPxlRedIn( prevLinePrevPxlRed ),
            .prevLinePrevPxlGreenIn( prevLinePrevPxlGreen ),
            .prevLinePrevPxlBlueIn( prevLinePrevPxlBlue ),
            .prevLineNextPxlRedIn( prevLineNextPxlRed ),
            .prevLineNextPxlGreenIn( prevLineNextPxlGreen ),
            .prevLineNextPxlBlueIn( prevLineNextPxlBlue ),
             
            .nextLineCurPxlRedIn( nextLineCurPxlRed ),
            .nextLineCurPxlGreenIn( nextLineCurPxlGreen ),
            .nextLineCurPxlBlueIn( nextLineCurPxlBlue ),
            .nextLinePrevPxlRedIn( nextLinePrevPxlRed ),
            .nextLinePrevPxlGreenIn( nextLinePrevPxlGreen ),
            .nextLinePrevPxlBlueIn( nextLinePrevPxlBlue ),
            .nextLineNextPxlRedIn( nextLineNextPxlRed ),
            .nextLineNextPxlGreenIn( nextLineNextPxlGreen ),
            .nextLineNextPxlBlueIn( nextLineNextPxlBlue ),
            
            .sameLine( sameLineBuff ),
            .newFrameIn( newFrameBuffOut ),
            .audioLIn( audioLIn ),
            .audioRIn( audioRIn ),
            
            .controllerRXValid( controllerRXValid ),
            .controller( controller ),
            .osdEnable( osdEnable ),
            
            .nextLine( pullLineBuff ),
            .cacheUpdate( cacheUpdate ),
            .curPxl( pxlCntReadToCache ),
            .tmds( tmds ),
            .tmdsClk( tmdsClk ) );
            

// Controller communication.
commTransceiver #( .packetBits( 8 ),
                   .clkFreq( pxlClkFrq ),
                   .usBit( 10.0 ) )
commTransceiver ( .serDatIn( controllerMCUIn ),
                  .clk( pxlClk ),
                  .rst( rst ),
                  .controllerOut( controller ),
                  .osdActive( osdEnable ),
                  .rxValid( controllerRXValid ) );

// Output diff. signals.
genvar i;
generate
  for (i = 0; i < 3; i++)
  begin: obufdsGen
      OBUFDS #( .IOSTANDARD("TMDS_33")) 
      obufds ( .I(tmds[i]), .O(hdmiTX[i]), .OB(hdmiTXN[i]) );
  end
  
  OBUFDS #(.IOSTANDARD("TMDS_33")) 
  obufdsClk( .I(tmdsClk), .O(hdmiClk), .OB(hdmiClkN));
endgenerate

endmodule
