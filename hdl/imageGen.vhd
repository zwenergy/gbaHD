-----------------------------------------------------------------------
-- Title: Image Generator
-- Author: zwenergy
-- Notes:
-- This module generates the actual data for the video output. Currently
-- the implementation bends any video specification by A LOT. It does not
-- assume a "valid" pixel clock frequency, the number of horizontal
-- pixels are not according to specs and probably the worst: the number
-- of vertical lines is not event consistent. Right now, this is the 
-- "price" of not replacing the GBA's oscillator by a clock signal 
-- created by the FPGA and not saving whole frames, but going
-- line-by-line.
-- For future implementations, creating the GBA clock by the FPGA
-- itself should be considered to create more standard-confrom signal.
-- Right now, the back-porch area of the signal is not always consistent,
-- as this seemed to be the most accepted (..by my TV)
-----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity imageGen is 
  port(
    pxlClk : in std_logic;
    rst : in std_logic;
    redPxlIn : in std_logic_vector( 7 downto 0 );
    greenPxlIn : in std_logic_vector( 7 downto 0 );
    bluePxlIn : in std_logic_vector( 7 downto 0 );
    sameLine : in std_logic;
    newFrameIn : in std_logic;
    
    nextLine : out std_logic;
    curPxl : out std_logic_vector( 7 downto 0 );
    
    redEnc : out std_logic_vector( 9 downto 0 );
    greenEnc : out std_logic_vector( 9 downto 0 );
    blueEnc : out std_logic_vector( 9 downto 0 )    
  );
end imageGen;

architecture rtl of imageGen is
signal countX : integer range 0 to 1665;
signal countY : integer range -25 to 1000;
signal countXDel : integer range 0 to 1665;
signal countYDel : integer range -25 to 1000;
signal hSync : std_logic;
signal vSync : std_logic;
signal ctrl : std_logic_vector( 1 downto 0 );
signal draw : std_logic;

signal pxlCnt : integer range 0 to 239;

signal pxlCnt4 : integer range 0 to 3;
signal lineCnt4 : integer range 0 to 3;

signal redPxl : std_logic_vector( 7 downto 0 );
signal greenPxl : std_logic_vector( 7 downto 0 );
signal bluePxl : std_logic_vector( 7 downto 0 );

-- Signals to be encoded
signal redDat : std_logic_vector( 7 downto 0 );
signal greenDat : std_logic_vector( 7 downto 0 );
signal blueDat : std_logic_vector( 7 downto 0 );

signal drawGBA : std_logic;

signal newFrameProcessed : std_logic;
signal newFrameInDel : std_logic;

constant vfrontporch : integer := 3;
constant vsyncpxl : integer := 5;
constant vbackporch : integer := 20;
-- TODO: These values are depending on the actual pixel clock. Make
-- them depending on a given generic.
constant maxHor : integer := 1410;
constant maxVer : integer := 900;

begin
  
  counterUpdate:process( pxlClk, rst ) is
  begin
    if ( rst = '1' ) then
        countX <= 0;
        countY <= -25;
        countXDel <= 0;
        countYDel <= -25;
        pxlCnt <= 0;
        pxlCnt4 <= 0;
        newFrameInDel <= '0';
        newFrameProcessed <= '0';
    elsif ( rising_edge( pxlClk ) ) then
      countXDel <= countX;
      countYDel <= countY;
      newFrameInDel <= newFrameIn;
      
      if ( newFrameIn = '1' and newFrameInDel = '0' ) then
        newFrameProcessed <= '0';
      end if;
      -- countX and countY
      if ( countX = maxHor ) then
        countX <= 0;
        if ( countY = maxVer ) then
          -- FIX!!
          countY <= -25;
        elsif ( newFrameIn = '1' and newFrameProcessed = '0' ) then
          newFrameProcessed <= '1';
          countY <= -25;
        else
          countY <= countY + 1;
        
        end if;
      else
        countX <= countX + 1;
      end if;
      
      -- PxlCnt
      if ( drawGBA = '0'  ) then
        pxlCnt4 <= 0;
        pxlCnt <= 0;
      else
        if ( pxlCnt4 = 3 ) then
          pxlCnt4 <= 0;
          pxlCnt <= pxlCnt + 1;
        else
          pxlCnt4 <= pxlCnt4 + 1;
        end if;
      end if;
      
      if ( countX = maxHor - 1 ) then
        if ( countY = maxVer or countY < 0 or ( newFrameIn = '1' and newFrameProcessed = '0' ) ) then
          lineCnt4 <= 0;
        elsif ( lineCnt4 = 3 ) then
          lineCnt4 <= 0;
        else
          lineCnt4 <= lineCnt4 + 1;
        end if;
      end if;
    end if;
  end process;
  
  curPxl <= std_logic_vector( to_unsigned( pxlCnt, curPxl'length ) );
  nextLine <= '0' when ( countXDel /= maxHor - 2 ) else
              '0' when ( sameLine = '1' ) else
              '0' when ( newFrameIn = '1' and newFrameProcessed = '0' ) else
              '0' when ( countY < 0 ) else
              '1' when ( lineCnt4 = 3 ) else
              '0';
  drawGBA <= '1' when ( countXDel < 959 and ( countYDel >= 0 and countYDel < 639 ) ) else '0';
  
  --hSync <= '1' when ( countXDel >= 1344 ) and ( countXDel < 1472 ) else '0';
  hSync <= '1' when ( countXDel >= 1344 ) and ( countXDel < 1380 ) else '0';
  vSync <= '1' when ( countYDel < -vbackporch) else '0';
  draw <= '1' when ( countXDel < 1280 ) and ( countYDel >= 0 and countYDel < 720 ) else '0';
  ctrl( 1 ) <= vSync;
  ctrl( 0 ) <= hSync;
  
  redDat <= redPxl when ( drawGBA ='1' ) else ( others => '0' );
  greenDat <= greenPxl when ( drawGBA ='1' ) else ( others => '0' );
  blueDat <= bluePxl when ( drawGBA ='1' ) else ( others => '0' );  
  
  --Capture the next pixel.
  getPixel:process( pxlClk, rst ) is
  begin
    if ( rst = '1' ) then
      redPxl <= ( others => '0' );
      greenPxl <= ( others => '0' );
      bluePxl <= ( others => '0' );
    elsif ( rising_edge( pxlClk ) ) then
      redPxl <= redPxlIn;
      greenPxl <= greenPxlIn;
      bluePxl <= bluePxlIn;
    end if;
  end process;
    
    -- Encode.
  redTMDS : entity work.tmdsEncoder( rtl )
    port map( 
      dispEN => draw,
      ctrl => "00",
      datIn => redDat,
      clk => pxlClk,
      rst => rst,
      datOut => redEnc 
    );
    
    greenTMDS : entity work.tmdsEncoder( rtl )
    port map( 
      dispEN => draw,
      ctrl => "00",
      datIn => greenDat,
      clk => pxlClk,
      rst => rst,
      datOut => greenEnc 
    );
    
    blueTMDS : entity work.tmdsEncoder( rtl )
    port map( 
      dispEN => draw,
      ctrl => ctrl,
      datIn => blueDat,
      clk => pxlClk,
      rst => rst,
      datOut => blueEnc 
    );
    

end rtl;