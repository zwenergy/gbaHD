-----------------------------------------------------------------------
-- Title: Line Cache
-- Author: zwenergy
-----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use IEEE.std_logic_misc.all;

entity lineCache is 
  port(
    clk : in std_logic;
    rst : in std_logic;
    curPxlCnt : in std_logic_vector( 7 downto 0 );
    lineChange : in std_logic;
    
    curLineCurPxlRedIn : in std_logic_vector( 7 downto 0 );
    curLineCurPxlGreenIn : in std_logic_vector( 7 downto 0 );
    curLineCurPxlBlueIn : in std_logic_vector( 7 downto 0 );
    
    prevLineCurPxlRedIn : in std_logic_vector( 7 downto 0 );
    prevLineCurPxlGreenIn : in std_logic_vector( 7 downto 0 );
    prevLineCurPxlBlueIn : in std_logic_vector( 7 downto 0 );
    
    nextLineCurPxlRedIn : in std_logic_vector( 7 downto 0 );
    nextLineCurPxlGreenIn : in std_logic_vector( 7 downto 0 );
    nextLineCurPxlBlueIn : in std_logic_vector( 7 downto 0 );
    
    prevLinePrevPxlRedOut : out std_logic_vector( 7 downto 0 );
    prevLinePrevPxlGreenOut : out std_logic_vector( 7 downto 0 );
    prevLinePrevPxlBlueOut : out std_logic_vector( 7 downto 0 );
    
    prevLineCurPxlRedOut : out std_logic_vector( 7 downto 0 );
    prevLineCurPxlGreenOut : out std_logic_vector( 7 downto 0 );
    prevLineCurPxlBlueOut : out std_logic_vector( 7 downto 0 );
    
    prevLineNextPxlRedOut : out std_logic_vector( 7 downto 0 );
    prevLineNextPxlGreenOut : out std_logic_vector( 7 downto 0 );
    prevLineNextPxlBlueOut : out std_logic_vector( 7 downto 0 );
    
    curLinePrevPxlRedOut : out std_logic_vector( 7 downto 0 );
    curLinePrevPxlGreenOut : out std_logic_vector( 7 downto 0 );
    curLinePrevPxlBlueOut : out std_logic_vector( 7 downto 0 );
    
    curLineCurPxlRedOut : out std_logic_vector( 7 downto 0 );
    curLineCurPxlGreenOut : out std_logic_vector( 7 downto 0 );
    curLineCurPxlBlueOut : out std_logic_vector( 7 downto 0 );
    
    curLineNextPxlRedOut : out std_logic_vector( 7 downto 0 );
    curLineNextPxlGreenOut : out std_logic_vector( 7 downto 0 );
    curLineNextPxlBlueOut : out std_logic_vector( 7 downto 0 );
    
    nextLinePrevPxlRedOut : out std_logic_vector( 7 downto 0 );
    nextLinePrevPxlGreenOut : out std_logic_vector( 7 downto 0 );
    nextLinePrevPxlBlueOut : out std_logic_vector( 7 downto 0 );
    
    nextLineCurPxlRedOut : out std_logic_vector( 7 downto 0 );
    nextLineCurPxlGreenOut : out std_logic_vector( 7 downto 0 );
    nextLineCurPxlBlueOut : out std_logic_vector( 7 downto 0 );
    
    nextLineNextPxlRedOut : out std_logic_vector( 7 downto 0 );
    nextLineNextPxlGreenOut : out std_logic_vector( 7 downto 0 );
    nextLineNextPxlBlueOut : out std_logic_vector( 7 downto 0 );
    
    pxlCntRead : out std_logic_vector( 7 downto 0 )
  );
end lineCache;

architecture rtl of lineCache is
type pixel is array( 0 to 2 ) of std_logic_vector( 7 downto 0 );
signal curLinePrevPxl, curLineCurPxl, curLineNextPxl, 
  prevLinePrevPxl, prevLineCurPxl, prevLineNextPxl,
  nextLinePrevPxl, nextLineCurPxl, nextLineNextPxl : pixel;
  
signal pxlCntRead_int, pxlCntRead_del, pxlCntRead_del2 : std_logic_vector( 7 downto 0 );
signal incAddr, firstPxlHandled, shiftRegs, lineChange_del : std_logic;
begin
  
  process( clk ) is
  begin
    if rising_edge( clk ) then
      if ( rst = '1' ) then
        pxlCntRead_del <= ( others => '0' );
        pxlCntRead_del2 <= ( others => '0' );
        firstPxlHandled <= '0';
        lineChange_del <= '0';
      else
        pxlCntRead_del <= pxlCntRead_int;
        pxlCntRead_del2 <= pxlCntRead_del;
        lineChange_del <= lineChange;
        
        if ( curPxlCnt = "00000000" ) then
          firstPxlHandled <= '1';
        else
          firstPxlHandled <= '0';
        end if;
        
        if ( lineChange_del = '1' ) then
          firstPxlHandled <= '0';
        end if;
        
        curLineNextPxl( 0 ) <= curLineCurPxlRedIn;
        curLineNextPxl( 1 ) <= curLineCurPxlGreenIn;
        curLineNextPxl( 2 ) <= curLineCurPxlBlueIn;
        
        prevLineNextPxl( 0 ) <= prevLineCurPxlRedIn;
        prevLineNextPxl( 1 ) <= prevLineCurPxlGreenIn;
        prevLineNextPxl( 2 ) <= prevLineCurPxlBlueIn;
        
        nextLineNextPxl( 0 ) <= nextLineCurPxlRedIn;
        nextLineNextPxl( 1 ) <= nextLineCurPxlGreenIn;
        nextLineNextPxl( 2 ) <= nextLineCurPxlBlueIn;
        
        
        if ( shiftRegs = '1' ) then
          curLineCurPxl <= curLineNextPxl;
          curLinePrevPxl <= curLineCurPxl;
          
          prevLineCurPxl <= prevLineNextPxl;
          prevLinePrevPxl <= prevLineCurPxl;
          
          nextLineCurPxl <= nextLineNextPxl;
          nextLinePrevPxl <= nextLineCurPxl;
        end if;
        
      end if;
    end if;
  end process;
  
  incAddr <= '0' when curPxlCnt = "00000000" and firstPxlHandled = '0' else '1';
  pxlCntRead_int <= std_logic_vector( unsigned( curPxlCnt ) + 1 ) when incAddr = '1' else
                    curPxlCnt;

  pxlCntRead <= pxlCntRead_int;
                
  shiftRegs <= '1' when pxlCntRead_del /= pxlCntRead_del2 else '0';
  
  prevLinePrevPxlRedOut <= prevLinePrevPxl( 0 );
  prevLinePrevPxlGreenOut <= prevLinePrevPxl( 1 );
  prevLinePrevPxlBlueOut <= prevLinePrevPxl( 2 );
  
  prevLineCurPxlRedOut <= prevLineCurPxl( 0 );
  prevLineCurPxlGreenOut <= prevLineCurPxl( 1 );
  prevLineCurPxlBlueOut <= prevLineCurPxl( 2 );
  
  prevLineNextPxlRedOut <= prevLineNextPxl( 0 );
  prevLineNextPxlGreenOut <= prevLineNextPxl( 1 );
  prevLineNextPxlBlueOut <= prevLineNextPxl( 2 );
  
  curLinePrevPxlRedOut <= curLinePrevPxl( 0 );
  curLinePrevPxlGreenOut <= curLinePrevPxl( 1 );
  curLinePrevPxlBlueOut <= curLinePrevPxl( 2 );
  
  curLineCurPxlRedOut <= curLineCurPxl( 0 );
  curLineCurPxlGreenOut <= curLineCurPxl( 1 );
  curLineCurPxlBlueOut <= curLineCurPxl( 2 );
  
  curLineNextPxlRedOut <= curLineNextPxl( 0 );
  curLineNextPxlGreenOut <= curLineNextPxl( 1 );
  curLineNextPxlBlueOut <= curLineNextPxl( 2 );
  
  nextLinePrevPxlRedOut <= nextLinePrevPxl( 0 );
  nextLinePrevPxlGreenOut <= nextLinePrevPxl( 1 );
  nextLinePrevPxlBlueOut <= nextLinePrevPxl( 2 );
  
  nextLineCurPxlRedOut <= nextLineCurPxl( 0 );
  nextLineCurPxlGreenOut <= nextLineCurPxl( 1 );
  nextLineCurPxlBlueOut <= nextLineCurPxl( 2 );
  
  nextLineNextPxlRedOut <= nextLineNextPxl( 0 );
  nextLineNextPxlGreenOut <= nextLineNextPxl( 1 );
  nextLineNextPxlBlueOut <= nextLineNextPxl( 2 );
  
end rtl;
