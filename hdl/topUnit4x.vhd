-----------------------------------------------------------------------
-- Title: Top Unit 4x
-- Author: zwenergy
-- TODO: Replace clock-related constants with generics.
-----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
Library UNISIM;
use UNISIM.vcomponents.all;

entity topUnit4x is
  port(
    clk : in std_logic; -- 100 MHz
    rst : in std_logic;
    hdmiTxHPD : in std_logic;
    
    redPxl : in std_logic_vector( 4 downto 0 );
    greenPxl : in std_logic_vector( 4 downto 0 );
    bluePxl : in std_logic_vector( 4 downto 0 );
    vsync : in std_logic;
    dclk : in std_logic;
    
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

signal rstH : std_logic;

signal redPxlCap, greenPxlCap, bluePxlCap : std_logic_vector( 7 downto 0 );
signal validPxlCap : std_logic;
signal pxlCntCap : std_logic_vector( 7 downto 0 );
signal lineValidCap : std_logic;
signal newFrameGBA :std_logic;

signal redBuf, greenBuf, blueBuf : std_logic_vector( 7 downto 0 );
signal pxlCntRead : std_logic_vector( 7 downto 0 );
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

-- Out.
signal redSer, greenSer, blueSer : std_logic;
begin

  rstH <= not rst;
  
  hdmiTxCEC <= 'Z';
  hdmiTxRSCL <= 'Z';
  hdmiTxRSDA <= 'Z';

  -- Generate a pixelclock of 75 MHz.
  PLL_inst:PLLE2_BASE
    generic map(
      CLKFBOUT_MULT => 11,
      CLKOUT0_DIVIDE => 15, -- pxlClk
      CLKOUT1_DIVIDE => 3 -- pxlClk5x
    )
    port map(
      CLKIN1 => clk,
      CLKFBIN => clkFB,
      RST => rstH,
      CLKOUT0 => pxlClk,
      CLKOUT1 => pxlClk5x,
      CLKFBOUT => clkFB,
      LOCKED => clkLock,
      PWRDWN => '0'
    );
    
  -- The capture interface.
  cap_inst : entity work.captureGBA( rtl )
    generic map(
      clkPeriodNS => 13.0
    )
    port map(
      clk => pxlClk,
      rst => rstH,
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
      rst => rstH,
      redIn => redPxlCap,
      greenIn => greenPxlCap,
      blueIn => bluePxlCap,
      wEn => validPxlCap,
      pxlCntWrite => pxlCntCap,
      pushLine => lineValidCap,
      newFrameIn => newFrameGBA,
      redOut => redBuf,
      greenOut => greenBuf,
      blueOut => blueBuf,
      pxlCntRead => pxlCntRead,
      pullLine => nextLineRead,
      sameLine => writeReadSameLine,
      newFrameOut => newFrameBuff
    );
      

  -- Image gen.
  imgGen_inst : entity work.imageGen( rtl )
    port map(
      pxlClk => pxlClk,
      rst => rstH,
      redPxlIn => redBuf,
      greenPxlIn => greenBuf,
      bluePxlIn => blueBuf,
      sameLine => writeReadSameLine,
      newFrameIn => newFrameBuff,
      nextLine => nextLineRead,
      curPxl => pxlCntRead,
      redEnc => redEnc,
      greenEnc => greenEnc,
      blueEnc => blueEnc
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
        RST => rstH,
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
      RST => rstH,
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
        RST => rstH,
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
      RST => rstH,
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
        RST => rstH,
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
      RST => rstH,
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
