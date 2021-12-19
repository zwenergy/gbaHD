//-----------------------------------------------------------------------
//-- Title: Image Gen
//-- Author: zwenergy
//-----------------------------------------------------------------------

import definePackage::*;

module imageGenV
(
  input logic pxlClk,
  input logic pxlClk5x,
  input logic rst,
  
  input logic [7:0] prevLinePrevPxlRedIn,
  input logic [7:0] prevLinePrevPxlGreenIn,
  input logic [7:0] prevLinePrevPxlBlueIn,
  input logic [7:0] prevLineCurPxlRedIn,
  input logic [7:0] prevLineCurPxlGreenIn,
  input logic [7:0] prevLineCurPxlBlueIn,
  input logic [7:0] prevLineNextPxlRedIn,
  input logic [7:0] prevLineNextPxlGreenIn,
  input logic [7:0] prevLineNextPxlBlueIn,
  input logic [7:0] curLinePrevPxlRedIn,
  input logic [7:0] curLinePrevPxlGreenIn,
  input logic [7:0] curLinePrevPxlBlueIn,
  input logic [7:0] curLineCurPxlRedIn,
  input logic [7:0] curLineCurPxlGreenIn,
  input logic [7:0] curLineCurPxlBlueIn,
  input logic [7:0] curLineNextPxlRedIn,
  input logic [7:0] curLineNextPxlGreenIn,
  input logic [7:0] curLineNextPxlBlueIn,
  input logic [7:0] nextLinePrevPxlRedIn,
  input logic [7:0] nextLinePrevPxlGreenIn,
  input logic [7:0] nextLinePrevPxlBlueIn,
  input logic [7:0] nextLineCurPxlRedIn,
  input logic [7:0] nextLineCurPxlGreenIn,
  input logic [7:0] nextLineCurPxlBlueIn,
  input logic [7:0] nextLineNextPxlRedIn,
  input logic [7:0] nextLineNextPxlGreenIn,
  input logic [7:0] nextLineNextPxlBlueIn,
  
  input logic sameLine,
  input logic newFrameIn,
  input logic audioLIn,
  input logic audioRIn,
  
  input logic osdEnable,
  input logic controllerRXValid,
  input logic [5:0] controller,
  
  output logic colorMode,
  output logic framerate,
  
  output logic nextLine,
  output logic cacheUpdate,
  output logic [7:0] curPxl,
  
  output logic [2:0] tmds,
  output logic tmdsClk  
);

localparam audioDamp = 6;

wire audioClk_gba, audioValid;
logic [AUDIO_BIT_WIDTH-1:0] pcmL, pcmR, audioL, audioR;

// Store audio samples.
always_ff @( posedge pxlClk )
begin
  if ( audioValid ) begin
    audioL <= pcmL;
    audioR <= pcmR;
  end
end

// Audio module.
pwm2pcm #( .clkFreq0( pxlClkFrq_60hz ),
           .clkFreq1( pxlClkFrq_59hz ),
           .clkFreqMax( pxlClkFrq_60hz ),
           .sampleFreq( 48.0 ),
           .damp( 2 ) )
pwm2pcm( .pwmInL( audioLIn ), 
         .pwmInR( audioRIn ), 
         .clk( pxlClk ), 
         .rst( rst ), 
         .clkFreq( framerate ),
         .sampleClkOut( audioClk_gba ), 
         .datOutL( pcmL ), 
         .datOutR( pcmR ), 
         .validOut( audioValid ) );


// HDMI.
logic [23:0] rgb;
logic [10:0] cy, frameHeight;
logic [11:0] cx, frameWidth;

logic [11:0] cxDel, setStartX; 
logic [10:0] cyDel, setStartY;
logic setStart;

hdmi #( .VIDEO_ID_CODE(VIDEOID), 
        .DVI_OUTPUT(0), 
        .VIDEO_REFRESH_RATE(60.0), 
        .AUDIO_RATE(48000), 
        .AUDIO_BIT_WIDTH(AUDIO_BIT_WIDTH) ) 
hdmi( .clk_pixel_x5(pxlClk5x), 
      .clk_pixel(pxlClk), 
      .clk_audio(audioClk_gba), 
      .rgb(rgb), 
      .reset( rst ), 
      .audio_sample_word('{audioL, audioR}), 
      .setStart( setStart ), 
      .setStartX( setStartX ), 
      .setStartY( setStartY ), 
      .tmds(tmds), 
      .tmds_clock(tmdsClk), 
      .cx(cx), 
      .cy(cy),
      .frame_width( frameWidth ),
      .frame_height( frameHeight ) );


// Create the image.
logic newFrameInDel, newFrameProcessed;
logic [2:0] lineCntScale, pxlCntScale, pxlCntScaleDel, pxlCntScaleDel2;
logic drawGBA;
logic [7:0] redPxlGBA, greenPxlGBA, bluePxlGBA;
logic [7:0] pxlCntRead;
logic [7:0] redPxl, greenPxl, bluePxl, gridRed, gridGreen, gridBlue,
            smoothRed, smoothGreen, smoothBlue, osdRed, osdGreen, osdBlue,
            borderRed, borderGreen, borderBlue;
            
logic drawOSD;
logic pxlGrid;
logic smooth2x, smooth4x;
logic gridAct;
logic brightGrid;

localparam int gbaVideoXStart = ( FRAMEWIDTH - ( maxScaleCnt + 1 ) * 240 ) / 2;
localparam int gbaVideoYStart = ( FRAMEHEIGHT - ( maxScaleCnt + 1 ) * 160 ) / 2;

always_comb
begin
  if ( cx >= gbaVideoXStart && cx < ( gbaVideoXStart + ( maxScaleCnt + 1 ) * 240 ) &&
       cy >= gbaVideoYStart && cy < ( gbaVideoYStart + ( maxScaleCnt + 1 ) * 160 ) )
  begin
    drawGBA <= 1;
  end
  else
  begin
    drawGBA <= 0;
  end
  
  if ( cxDel == ( frameWidth - 8 ) && sameLine == 0 && 
       !( newFrameIn == 1 && newFrameProcessed == 0 ) &&
       cy >= gbaVideoYStart && lineCntScale == maxScaleCnt ) begin
    nextLine <= 1;
  end else begin
    nextLine <= 0;
  end
  
  if ( cxDel == frameWidth - 8 ) begin
    cacheUpdate <= 1;
  end else begin
    cacheUpdate <= 0;
  end

  rgb <= { redPxl, greenPxl, bluePxl };
end

assign curPxl = pxlCntRead;

always_ff @( posedge pxlClk )
begin
  if ( rst )
  begin
    cxDel <= 11'(0);
    cyDel <= 10'(0);
    newFrameInDel <= 0;
    newFrameProcessed <= 0;
    setStartX <= 11'(0);
    setStartY <= 10'(0);
    setStart <= 0;
    pxlCntRead <= 8'(0);
    pxlCntScale <= 3'(0);
    lineCntScale <= 3'(0);
    redPxlGBA <= 8'(0);
    greenPxlGBA <= 8'(0);
    bluePxlGBA <= 8'(0);
  end
  else
  begin
    cxDel <= cx;
    cyDel <= cy;
    newFrameInDel <= newFrameIn;
    
    redPxlGBA <= curLineCurPxlRedIn;
    greenPxlGBA <= curLineCurPxlGreenIn;
    bluePxlGBA <= curLineCurPxlBlueIn;
    
    if ( newFrameIn == 1 && newFrameInDel == 0 )
    begin
      newFrameProcessed <= 0;
    end
    
    if ( newFrameIn == 1 && newFrameProcessed == 0 )
    begin
      setStart <= 1;
      setStartX <= 12'(0);
      setStartY <= 11'(gbaVideoYStart-2);
    end
    
    if ( newFrameIn == 1 && newFrameProcessed == 0 && cyDel != cy )
    begin
      setStart <= 0;
      newFrameProcessed <= 1;
    end
    
    if ( drawGBA == 0 )
    begin
      pxlCntScale <= 2'(0);
      pxlCntRead <= 8'(0);
    end else begin
      if ( pxlCntScale == maxScaleCnt ) begin
        pxlCntScale <= 0;
        pxlCntRead <= pxlCntRead + 1'b1;
      end else begin
        pxlCntScale <= pxlCntScale + 1'b1;
      end
    end
    
    if ( cx == (frameWidth - 1) )
    begin
      if ( ( cy == ( frameHeight - 1 ) ) || ( newFrameIn == 1 && newFrameProcessed == 0 ) )
      begin
        lineCntScale <= 3'(0);
      end else if ( lineCntScale == maxScaleCnt )
      begin
        lineCntScale <= 3'(0);
      end else if ( cy >= gbaVideoYStart ) 
      begin
          lineCntScale <= lineCntScale + 1'b1;
      end
    end
    
  end
end

// Choose which signal outlet.
always_comb
begin
  if( drawOSD ) begin
    redPxl <= osdRed;
    greenPxl <= osdGreen;
    bluePxl <= osdBlue;
    
  end else if ( drawGBA ) begin
    if ( pxlGrid ) begin
      redPxl <= gridRed;
      greenPxl <= gridGreen;
      bluePxl <= gridBlue;
      
    end else if ( smooth2x || smooth4x ) begin
      redPxl <= smoothRed;
      greenPxl <= smoothGreen;
      bluePxl <= smoothBlue;
      
    end else begin
      redPxl <= redPxlGBA;
      greenPxl <= greenPxlGBA;
      bluePxl <= bluePxlGBA;
    end
    
  end else begin
    redPxl <= borderRed;
    greenPxl <= borderGreen;
    bluePxl <= borderBlue;
  end
end


always_ff @( posedge pxlClk )
begin
  // Delay the pxlCntScale twice.
  pxlCntScaleDel <= pxlCntScale;
  pxlCntScaleDel2 <= pxlCntScaleDel;
end

// Pixel grid.
assign gridAct = ( pxlCntScaleDel2 == 0 || lineCntScale == 0 ? 1 : 0 );

gridGen #( .gridLineChange( 8'b00011101 ) )
gridGen ( .pxlInRed( redPxlGBA ),
          .pxlInGreen( greenPxlGBA ),
          .pxlInBlue( bluePxlGBA ),
          .gridAct( gridAct ),
          .brightGrid( brightGrid ),
          .pxlOutRed( gridRed ),
          .pxlOutGreen( gridGreen ),
          .pxlOutBlue( gridBlue ) );
          

// Smoothing.
smooth4x ( .rTL( prevLinePrevPxlRedIn ),
           .gTL( prevLinePrevPxlGreenIn ),
           .bTL( prevLinePrevPxlBlueIn ),
           .rTM( prevLineCurPxlRedIn ),
           .gTM( prevLineCurPxlGreenIn ),
           .bTM( prevLineCurPxlBlueIn ),
           .rTR( prevLineNextPxlRedIn ),
           .gTR( prevLineNextPxlGreenIn ),
           .bTR( prevLineNextPxlBlueIn ),
           
           .rCL( curLinePrevPxlRedIn ),
           .gCL( curLinePrevPxlGreenIn ),
           .bCL( curLinePrevPxlBlueIn ),
           .rCM( curLineCurPxlRedIn ),
           .gCM( curLineCurPxlGreenIn ),
           .bCM( curLineCurPxlBlueIn ),
           .rCR( curLineNextPxlRedIn ),
           .gCR( curLineNextPxlGreenIn ),
           .bCR( curLineNextPxlBlueIn ),
           
           .rBL( nextLinePrevPxlRedIn ),
           .gBL( nextLinePrevPxlGreenIn ),
           .bBL( nextLinePrevPxlBlueIn ),
           .rBM( nextLineCurPxlRedIn ),
           .gBM( nextLineCurPxlGreenIn ),
           .bBM( nextLineCurPxlBlueIn ),
           .rBR( nextLineNextPxlRedIn ),
           .gBR( nextLineNextPxlGreenIn ),
           .bBR( nextLineNextPxlBlueIn ),
           
           .xsel( pxlCntScaleDel2 ),
           .ysel( lineCntScale ),
           .do4x( smooth4x ),
           
           .rOut( smoothRed ),
           .gOut( smoothGreen ),
           .bOut( smoothBlue ) );
           
           
// OSD.
osd #( .smoothEnable( SMOOTHENABLE ),
       .scale( maxScaleCnt + 1 ),
       .frameWidth( FRAMEWIDTH ),
       .frameHeight( FRAMEHEIGHT ) ) 
osd ( .pxlX( cx ),
      .pxlY( cy ),
      .controller( controller ),
      .osdEnableIn( osdEnable ),
      .rxValid( controllerRXValid ),
      .clk( pxlClk ),
      .rst( rst ),
      .osdEnableOut( drawOSD ),
      .osdRed( osdRed ),
      .osdGreen( osdGreen ),
      .osdBlue( osdBlue ),
      .smooth2x( smooth2x ),
      .smooth4x( smooth4x ),
      .pixelGrid( pxlGrid ),
      .bgrid( brightGrid ),
      .colorMode( colorMode ),
      .rate( framerate ) );

      
// Border gen.
borderGen #( .xMin( 0 ),
             .xMax( widthMax - 1 ),
             .yMin( 0 ),
             .yMax( heightMax - 1 ) )
borderGen ( .x( cx ),
            .y( cy ),
            .r( borderRed ),
            .g( borderGreen ) );


endmodule
