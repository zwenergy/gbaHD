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
  input hdmiHPD,
  
  output enable3V3
);


// Pull 3V3_EN line low to enable them.
assign enable3V3 = 0;

// Reconf.
wire framerate, drdy, locked, busy, dwe, den, dclkDRP, rstMMCM, busyDRP;
wire [15:0] doSig, diSig;
wire [6:0] daddr;
logic doSwitch;
logic [2:0] stateSel;

// Generate clocks.
wire pxlClk, pxlClkInt, pxlClkx5, pxlClkx5Int, gbaClkx2, gbaClkx2Int, 
  clkFB, clkLock;
wire [2:0] tmds;
wire tmdsClk;

assign locked = clkLock;

MMCME2_ADV
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
    .RST                 (rstMMCM),
    .CLKIN1( clk ),
    .DADDR( daddr ),
    .DI( diSig ),
    .DO( doSig ),
    .DWE( dwe ),
    .DEN( den ),
    .DCLK( dclkDRP ),
    .DRDY( drdy ) );

BUFG clkBuf0
  (.O (pxlClkx5),
   .I (pxlClkx5Int));
   
BUFG clkBuf1
  (.O (pxlClk),
   .I (pxlClkInt));

// Reset generate.
logic [9:0] rstCnt = 10'(0);
logic rst;

assign rst = ( rstCnt < 1000 ? 1 : 0 );

always_ff @( posedge pxlClk )
begin
  if ( rstCnt < 1000 ) begin
    rstCnt = rstCnt + 1;    
  end
end

drp drp_inst
  (
    .doSwitch( doSwitch ),
    .drdy( drdy ),
    .locked( locked ),
    .stateSel( stateSel ),
    .dwe( dwe ),
    .den( den ),
    .dclk( dclkDRP ),
    .rstMMCM( rstMMCM ),
    .doSig( doSig ),
    .diSig( diSig ),
    .daddr( daddr ),
    .clk( clk ),
    .rst( 1'b0 ),
    .busy( busyDRP )
  );

// Logic to start MMCM reconf.
logic framerate_sync;
always_ff @( posedge pxlClk )
begin
  framerate_sync <= framerate;
end


logic framerateCDC1, framerateCDC2;
logic prevFramerate;
always_ff @( posedge clk )
begin
  if ( rst ) begin
    prevFramerate <= 0;
    framerateCDC1 <= 0;
    framerateCDC2 <= 0;
  end else begin
    framerateCDC1 <= framerate_sync;
    framerateCDC2 <= framerateCDC1;
  
    prevFramerate <= framerateCDC2;
    
    if ( prevFramerate != framerateCDC2 ) begin
      doSwitch <= 1;
      if ( framerateCDC2 == 0 ) begin
      `ifdef RES0_720P
        stateSel <= 3'b000;
      `elsif RES_1080P
        stateSel <= 3'b010;
      `else
        stateSel <= 3'b100;
      `endif
      end else begin
      `ifdef RES0_720P
        stateSel <= 3'b001;
      `elsif RES_1080P
        stateSel <= 3'b011;
      `else
        stateSel <= 3'b101;
      `endif
      end
    end else begin
      doSwitch <= 0;
    end
  end
end


// GBA Clock.
fracDiv #( .mul( GBACLKMUL ), .div( GBACLKDIV ), .maxInt( 10000 ) )
fracDiv ( .clk( pxlClk ), .rst( rst ), .clkOut( gbaClk ) );

// GBA capture.
logic [7:0] redPxlCap, greenPxlCap, bluePxlCap;
logic validCap;
logic [7:0] pxlCntCap;
logic validLineCap, newFrameCap;
logic colorMode;
captureGBA #( .clkPeriodNS( pxlClkPeriod_60hz ) ) 
captureGBA( .clk( pxlClk ), 
            .rst( rst ), 
            .redPxl( redPxl ), 
            .bluePxl( bluePxl ), 
            .greenPxl( greenPxl ),
            .vsync( vsync ), 
            .dclk( dclk ),
            .colorMode( colorMode ),
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
            .colorMode( colorMode ),
            .framerate( framerate ),
            .osdEnable( osdEnable ),
            
            .nextLine( pullLineBuff ),
            .cacheUpdate( cacheUpdate ),
            .curPxl( pxlCntReadToCache ),
            .tmds( tmds ),
            .tmdsClk( tmdsClk ) );
            

// Controller communication.
commTransceiver #( .packetBits( 8 ),
                   .clkFreq0( pxlClkFrq_60hz ),
                   .clkFreq1( pxlClkFrq_59hz ),
                   .clkFreqMax( pxlClkFrq_60hz ),
                   .usBit( 10.0 ) )
commTransceiver ( .serDatIn( controllerMCUIn ),
                  .clk( pxlClk ),
                  .rst( rst ),
                  //.clkFreq( framerate ),
                  .clkFreq( 0 ),
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
