-----------------------------------------------------------------------
-- Title: Top Unit 4x
-- Author: zwenergy
-----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
Library UNISIM;
use UNISIM.vcomponents.all;

entity topUnit4x is
  port(
    clk : in std_logic; -- 100 MHz
    hdmiTxHPD : in std_logic;
    
    redPxl : in std_logic_vector( 4 downto 0 );
    greenPxl : in std_logic_vector( 4 downto 0 );
    bluePxl : in std_logic_vector( 4 downto 0 );
    vsync : in std_logic;
    dclk : in std_logic;
    
    controllerMCUIn : in std_logic;
    
    audioLIn : in std_logic;
    audioRIn : in std_logic;
    
    gbaclk : out std_logic;
    
    hdmiTxCEC : inout std_logic;
    hdmiTxRSCL : inout std_logic;
    hdmiTxRSDA : inout std_logic;
    
    hdmiTxRedP : out std_logic;
    hdmiTxRedN : out std_logic;
    hdmiTxBlueP : out std_logic;
    hdmiTxBlueN : out std_logic;
    hdmiTxGreenP : out std_logic;
    hdmiTxGreenN : out std_logic;
    hdmiTxClkP : out std_logic;
    hdmiTxClkN : out std_logic  
  );
end topUnit4x;

architecture rtl of topUnit4x is
-- Pixelclk
signal pxlClk : std_logic;
signal pxlClk5x : std_logic;
signal clkLock : std_logic;
signal clkFB : std_logic;

signal redPxlCap, greenPxlCap, bluePxlCap : std_logic_vector( 7 downto 0 );
signal validPxlCap : std_logic;
signal pxlCntCap : std_logic_vector( 7 downto 0 );
signal lineValidCap : std_logic;
signal newFrameGBA :std_logic;

signal prevLineCurPxlRedBuf, prevLineCurPxlGreenBuf, prevLineCurPxlBlueBuf,
  curLineCurPxlRedBuf, curLineCurPxlGreenBuf, curLineCurPxlBlueBuf,
  nextLineCurPxlRedBuf, nextLineCurPxlGreenBuf, nextLineCurPxlBlueBuf: std_logic_vector( 7 downto 0 );
signal pxlCntReadToCache, pxlCntReadToBuffer : std_logic_vector( 7 downto 0 );
signal nextLineRead : std_logic;
signal writeReadSameLine : std_logic;
signal newFrameBuff : std_logic;

signal redEnc, greenEnc, blueEnc : std_logic_vector( 9 downto 0 );

-- Serializer.
signal redSHIFT1 : std_logic;
signal redSHIFT2 : std_logic;
signal greenSHIFT1 : std_logic;
signal greenSHIFT2 : std_logic;
signal blueSHIFT1 : std_logic;
signal blueSHIFT2 : std_logic;

signal gbaclk_int : std_logic;
signal gbaclk2x : std_logic;

signal controller : std_logic_vector( 5 downto 0 );
signal controllerRXValid : std_logic;
signal osdEnable : std_logic;

-- Line cache.
signal curLineCurPxlRed, curLineCurPxlBlue, curLineCurPxlGreen,
  curLinePrevPxlRed, curLinePrevPxlBlue, curLinePrevPxlGreen,
  curLineNextPxlRed, curLineNextPxlBlue, curLineNextPxlGreen,
  prevLineCurPxlRed, prevLineCurPxlBlue, prevLineCurPxlGreen,
  prevLinePrevPxlRed, prevLinePrevPxlBlue, prevLinePrevPxlGreen,
  prevLineNextPxlRed, prevLineNextPxlBlue, prevLineNextPxlGreen,
  nextLineCurPxlRed, nextLineCurPxlBlue, nextLineCurPxlGreen,
  nextLinePrevPxlRed, nextLinePrevPxlBlue, nextLinePrevPxlGreen,
  nextLineNextPxlRed, nextLineNextPxlBlue, nextLineNextPxlGreen : std_logic_vector( 7 downto 0 );

-- Main reset.
signal rst : std_logic := '1';

-- Out.
signal redSer, greenSer, blueSer : std_logic;
begin

  rst <= not clkLock;
  gbaclk <= gbaclk_int;
  
  hdmiTxCEC <= 'Z';
  hdmiTxRSCL <= 'Z';
  hdmiTxRSDA <= 'Z';
  
  -- Generate Clks.
  mmcm_inst : MMCME2_BASE
    generic map(
      CLKOUT0_DIVIDE_F => 1.0,
      CLKOUT1_DIVIDE => 10,
      CLKOUT2_DIVIDE => 2,
      CLKOUT3_DIVIDE => 100,
      CLKFBOUT_MULT_F => 8.375,
      DIVCLK_DIVIDE => 1,
      CLKIN1_PERIOD => 10.0
    )
    port map(
      CLKIN1 => clk,
      RST => '0',
      CLKFBIN => clkFB,
      CLKOUT0 => open,
      CLKOUT1 => pxlClk,
      CLKOUT2 => pxlClk5x,
      CLKOUT3 => gbaClk2x,
      CLKFBOUT => clkFB,
      LOCKED => clkLock,
      PWRDWN => '0'
    );
    
    -- Generate the actual GBA clk.
    process( gbaclk2x, rst ) is
    begin
      if ( rst = '1' ) then
        gbaclk_int <= '1';
      elsif rising_edge( gbaclk2x ) then
        gbaclk_int <= not gbaclk_int;
      end if;
    end process;
    
  -- The capture interface.
  cap_inst : entity work.captureGBA( rtl )
    generic map(
      clkPeriodNS => 12.0
    )
    port map(
      clk => pxlClk,
      rst => rst,
      redPxl => redPxl,
      bluePxl => bluePxl,
      greenPxl => greenPxl,
      vsync => vsync,
      dclk => dclk,
      redPxlOut => redPxlCap,
      greenPxlOut => greenPxlCap,
      bluePxlOut => bluePxlCap,
      validPxlOut => validPxlCap,
      pxlCnt => pxlCntCap,
      validLine => lineValidCap,
      newFrame => newFrameGBA
    );
      
  -- Line buffer.
  buf_inst : entity work.lineBuffer( rtl ) 
    generic map(
      nrStgs => 16
    )
    port map(
      clkW => pxlClk,
      clkR => pxlClk,
      rst => rst,
      redIn => redPxlCap,
      greenIn => greenPxlCap,
      blueIn => bluePxlCap,
      wEn => validPxlCap,
      pxlCntWrite => pxlCntCap,
      pushLine => lineValidCap,
      newFrameIn => newFrameGBA,
      redOutPrev => prevLineCurPxlRedBuf,
      greenOutPrev => prevLineCurPxlGreenBuf,
      blueOutPrev => prevLineCurPxlBlueBuf,
      redOutCur => curLineCurPxlRedBuf,
      greenOutCur => curLineCurPxlGreenBuf,
      blueOutCur => curLineCurPxlBlueBuf,
      redOutNext => nextLineCurPxlRedBuf,
      greenOutNext => nextLineCurPxlGreenBuf,
      blueOutNext => nextLineCurPxlBlueBuf,
      pxlCntRead => pxlCntReadToBuffer,
      pullLine => nextLineRead,
      sameLine => writeReadSameLine,
      newFrameOut => newFrameBuff
    );
    
  -- Line cache.
  lineCache_inst : entity work.lineCache( rtl )
  port map(
    clk => pxlClk,
    rst => rst,
    curPxlCnt => pxlCntReadToCache,
    lineChange => nextLineRead,
    curLineCurPxlRedIn => curLineCurPxlRedBuf,
    curLineCurPxlGreenIn => curLineCurPxlGreenBuf,
    curLineCurPxlBlueIn => curLineCurPxlBlueBuf,
    prevLineCurPxlRedIn => prevLineCurPxlRedBuf,
    prevLineCurPxlGreenIn => prevLineCurPxlGreenBuf,
    prevLineCurPxlBlueIn => prevLineCurPxlBlueBuf,
    nextLineCurPxlRedIn => nextLineCurPxlRedBuf,
    nextLineCurPxlGreenIn => nextLineCurPxlGreenBuf,
    nextLineCurPxlBlueIn => nextLineCurPxlBlueBuf,    
    
    curLineCurPxlRedOut => curLineCurPxlRed,
    curLineCurPxlGreenOut => curLineCurPxlGreen,
    curLineCurPxlBlueOut => curLineCurPxlBlue,
    prevLineCurPxlRedOut => prevLineCurPxlRed,
    prevLineCurPxlGreenOut => prevLineCurPxlGreen,
    prevLineCurPxlBlueOut => prevLineCurPxlBlue,
    nextLineCurPxlRedOut => nextLineCurPxlRed,
    nextLineCurPxlGreenOut => nextLineCurPxlGreen,
    nextLineCurPxlBlueOut => nextLineCurPxlBlue,
    
    curLineNextPxlRedOut => curLineNextPxlRed,
    curLineNextPxlGreenOut => curLineNextPxlGreen,
    curLineNextPxlBlueOut => curLineNextPxlBlue,
    prevLineNextPxlRedOut => prevLineNextPxlRed,
    prevLineNextPxlGreenOut => prevLineNextPxlGreen,
    prevLineNextPxlBlueOut => prevLineNextPxlBlue,
    nextLineNextPxlRedOut => nextLineNextPxlRed,
    nextLineNextPxlGreenOut => nextLineNextPxlGreen,
    nextLineNextPxlBlueOut => nextLineNextPxlBlue,
    
    curLinePrevPxlRedOut => curLinePrevPxlRed,
    curLinePrevPxlGreenOut => curLinePrevPxlGreen,
    curLinePrevPxlBlueOut => curLinePrevPxlBlue,
    prevLinePrevPxlRedOut => prevLinePrevPxlRed,
    prevLinePrevPxlGreenOut => prevLinePrevPxlGreen,
    prevLinePrevPxlBlueOut => prevLinePrevPxlBlue,
    nextLinePrevPxlRedOut => nextLinePrevPxlRed,
    nextLinePrevPxlGreenOut => nextLinePrevPxlGreen,
    nextLinePrevPxlBlueOut => nextLinePrevPxlBlue,
    
    pxlCntRead => pxlCntReadToBuffer
  );
      

  -- Image gen.
  imgGen_inst : entity work.imageGen( rtl )
    port map(
      pxlClk => pxlClk,
      rst => rst,
      
      curLineCurPxlRedIn => curLineCurPxlRed,
      curLineCurPxlGreenIn => curLineCurPxlGreen,
      curLineCurPxlBlueIn => curLineCurPxlBlue,
      prevLineCurPxlRedIn => prevLineCurPxlRed,
      prevLineCurPxlGreenIn => prevLineCurPxlGreen,
      prevLineCurPxlBlueIn => prevLineCurPxlBlue,
      nextLineCurPxlRedIn => nextLineCurPxlRed,
      nextLineCurPxlGreenIn => nextLineCurPxlGreen,
      nextLineCurPxlBlueIn => nextLineCurPxlBlue,
      
      curLineNextPxlRedIn => curLineNextPxlRed,
      curLineNextPxlGreenIn => curLineNextPxlGreen,
      curLineNextPxlBlueIn => curLineNextPxlBlue,
      prevLineNextPxlRedIn => prevLineNextPxlRed,
      prevLineNextPxlGreenIn => prevLineNextPxlGreen,
      prevLineNextPxlBlueIn => prevLineNextPxlBlue,
      nextLineNextPxlRedIn => nextLineNextPxlRed,
      nextLineNextPxlGreenIn => nextLineNextPxlGreen,
      nextLineNextPxlBlueIn => nextLineNextPxlBlue,
      
      curLinePrevPxlRedIn => curLinePrevPxlRed,
      curLinePrevPxlGreenIn => curLinePrevPxlGreen,
      curLinePrevPxlBlueIn => curLinePrevPxlBlue,
      prevLinePrevPxlRedIn => prevLinePrevPxlRed,
      prevLinePrevPxlGreenIn => prevLinePrevPxlGreen,
      prevLinePrevPxlBlueIn => prevLinePrevPxlBlue,
      nextLinePrevPxlRedIn => nextLinePrevPxlRed,
      nextLinePrevPxlGreenIn => nextLinePrevPxlGreen,
      nextLinePrevPxlBlueIn => nextLinePrevPxlBlue,
      
      sameLine => writeReadSameLine,
      newFrameIn => newFrameBuff,
      audioLIn => audioLIn,
      audioRIn => audioRIn,
      nextLine => nextLineRead,
      curPxl => pxlCntReadToCache,
      redEnc => redEnc,
      greenEnc => greenEnc,
      blueEnc => blueEnc,
      
      controllerRXValid => controllerRXValid,
      controller => controller,
      osdEnable => osdEnable
    );
    
    -- Controller communication.
    controllerComm_inst : entity work.commTransceiver( rtl )
      generic map( 
        packetBits => 8,
        clkFreq => 83745.07997655,
        usBit => 10.0
      )
      port map(
        serDatIn => controllerMCUIn,
        clk => pxlClk,
        rst => rst,
        controllerOut => controller,
        osdActive => osdEnable,
        rxValid => controllerRXValid
      );
      
      
    
    -- Serialize.
    redSerM : OSERDESE2
      generic map(
        DATA_RATE_OQ => "DDR",
        DATA_RATE_TQ => "SDR",
        DATA_WIDTH => 10,
        TRISTATE_WIDTH => 1,
        SERDES_MODE => "MASTER"
      )      
      port map(
        OQ => redSer,
        OFB => open,
        TQ => open,
        TFB => open,
        SHIFTOUT1 => open,
        SHIFTOUT2 => open,
        CLK => pxlClk5x,
        CLKDIV => pxlClk,
        D8 => redEnc( 7 ),
        D7 => redEnc( 6 ),
        D6 => redEnc( 5 ),
        D5 => redEnc( 4 ),
        D4 => redEnc( 3 ),
        D3 => redEnc( 2 ),
        D2 => redEnc( 1 ),
        D1 => redEnc( 0 ),
        TCE => '0',
        OCE => '1',
        TBYTEIN => '0',
        TBYTEOUT => open,
        RST => rst,
        SHIFTIN1 => redSHIFT1,
        SHIFTIN2 => redSHIFT2,
        T1 => '0',
        T2 => '0',
        T3 => '0',
        T4 => '0'
      );
      
    redSerS : OSERDESE2
    generic map(
      DATA_RATE_OQ => "DDR",
      DATA_RATE_TQ => "SDR",
      DATA_WIDTH => 10,
      TRISTATE_WIDTH => 1,
      SERDES_MODE => "SLAVE"
    )      
    port map(
      OQ => open,
      OFB => open,
      TQ => open,
      TFB => open,
      SHIFTOUT1 => redSHIFT1,
      SHIFTOUT2 => redSHIFT2,
      CLK => pxlClk5x,
      CLKDIV => pxlClk,
      D8 => '0',
      D7 => '0',
      D6 => '0',
      D5 => '0',
      D4 => redEnc( 9 ),
      D3 => redEnc( 8 ),
      D2 => '0',
      D1 => '0',
      TCE => '0',
      OCE => '1',
      TBYTEIN => '0',
      TBYTEOUT => open,
      RST => rst,
      SHIFTIN1 => '0',
      SHIFTIN2 => '0',
      T1 => '0',
      T2 => '0',
      T3 => '0',
      T4 => '0'
    );
    
    greenSerM : OSERDESE2
      generic map(
        DATA_RATE_OQ => "DDR",
        DATA_RATE_TQ => "SDR",
        DATA_WIDTH => 10,
        TRISTATE_WIDTH => 1,
        SERDES_MODE => "MASTER"
      )      
      port map(
        OQ => greenSer,
        OFB => open,
        TQ => open,
        TFB => open,
        SHIFTOUT1 => open,
        SHIFTOUT2 => open,
        CLK => pxlClk5x,
        CLKDIV => pxlClk,
        D8 => greenEnc( 7 ),
        D7 => greenEnc( 6 ),
        D6 => greenEnc( 5 ),
        D5 => greenEnc( 4 ),
        D4 => greenEnc( 3 ),
        D3 => greenEnc( 2 ),
        D2 => greenEnc( 1 ),
        D1 => greenEnc( 0 ),
        TCE => '0',
        OCE => '1',
        TBYTEIN => '0',
        TBYTEOUT => open,
        RST => rst,
        SHIFTIN1 => greenSHIFT1,
        SHIFTIN2 => greenSHIFT2,
        T1 => '0',
        T2 => '0',
        T3 => '0',
        T4 => '0'
      );
      
    greenSerS : OSERDESE2
    generic map(
      DATA_RATE_OQ => "DDR",
      DATA_RATE_TQ => "SDR",
      DATA_WIDTH => 10,
      TRISTATE_WIDTH => 1,
      SERDES_MODE => "SLAVE"
    )      
    port map(
      OQ => open,
      OFB => open,
      TQ => open,
      TFB => open,
      SHIFTOUT1 => greenSHIFT1,
      SHIFTOUT2 => greenSHIFT2,
      CLK => pxlClk5x,
      CLKDIV => pxlClk,
      D8 => '0',
      D7 => '0',
      D6 => '0',
      D5 => '0',
      D4 => greenEnc( 9 ),
      D3 => greenEnc( 8 ),
      D2 => '0',
      D1 => '0',
      TCE => '0',
      OCE => '1',
      TBYTEIN => '0',
      TBYTEOUT => open,
      RST => rst,
      SHIFTIN1 => '0',
      SHIFTIN2 => '0',
      T1 => '0',
      T2 => '0',
      T3 => '0',
      T4 => '0'
    );
    
    
  blueSerM : OSERDESE2
      generic map(
        DATA_RATE_OQ => "DDR",
        DATA_RATE_TQ => "SDR",
        DATA_WIDTH => 10,
        TRISTATE_WIDTH => 1,
        SERDES_MODE => "MASTER"
      )      
      port map(
        OQ => blueSer,
        OFB => open,
        TQ => open,
        TFB => open,
        SHIFTOUT1 => open,
        SHIFTOUT2 => open,
        CLK => pxlClk5x,
        CLKDIV => pxlClk,
        D8 => blueEnc( 7 ),
        D7 => blueEnc( 6 ),
        D6 => blueEnc( 5 ),
        D5 => blueEnc( 4 ),
        D4 => blueEnc( 3 ),
        D3 => blueEnc( 2 ),
        D2 => blueEnc( 1 ),
        D1 => blueEnc( 0 ),
        TCE => '0',
        OCE => '1',
        TBYTEIN => '0',
        TBYTEOUT => open,
        RST => rst,
        SHIFTIN1 => blueSHIFT1,
        SHIFTIN2 => blueSHIFT2,
        T1 => '0',
        T2 => '0',
        T3 => '0',
        T4 => '0'
      );
      
    blueSerS : OSERDESE2
    generic map(
      DATA_RATE_OQ => "DDR",
      DATA_RATE_TQ => "SDR",
      DATA_WIDTH => 10,
      TRISTATE_WIDTH => 1,
      SERDES_MODE => "SLAVE"
    )      
    port map(
      OQ => open,
      OFB => open,
      TQ => open,
      TFB => open,
      SHIFTOUT1 => blueSHIFT1,
      SHIFTOUT2 => blueSHIFT2,
      CLK => pxlClk5x,
      CLKDIV => pxlClk,
      D8 => '0',
      D7 => '0',
      D6 => '0',
      D5 => '0',
      D4 => blueEnc( 9 ),
      D3 => blueEnc( 8 ),
      D2 => '0',
      D1 => '0',
      TCE => '0',
      OCE => '1',
      TBYTEIN => '0',
      TBYTEOUT => open,
      RST => rst,
      SHIFTIN1 => '0',
      SHIFTIN2 => '0',
      T1 => '0',
      T2 => '0',
      T3 => '0',
      T4 => '0'
    );
    
  -- Out.
  rDiff:OBUFDS
    port map(
      I => redSer,
      O => hdmiTxRedP,
      OB => hdmiTxRedN
    );
    
  gDiff:OBUFDS
    port map(
      I => greenSer,
      O => hdmiTxGreenP,
      OB => hdmiTxGreenN
    );
    
  bDiff:OBUFDS
    port map(
      I => blueSer,
      O => hdmiTxblueP,
      OB => hdmiTxBlueN
    );

    clkDiff:OBUFDS
    port map(
      I => pxlClk,
      O => hdmiTxClkP,
      OB => hdmiTxClkN
    );
  
    
  end rtl;
