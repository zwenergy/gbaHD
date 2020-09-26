-----------------------------------------------------------------------
-- Title: GBA Display Capture
-- Author: zwenergy
-----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity captureGBA is
  generic(
    clkPeriodNS : real := 13.0 -- Clock period in ns.
  );
  port(
    clk : in std_logic;
    rst : in std_logic;
    redPxl : in std_logic_vector( 4 downto 0 );
    greenPxl : in std_logic_vector( 4 downto 0 );
    bluePxl : in std_logic_vector( 4 downto 0 );
    vsync : in std_logic;
    dclk : in std_logic;
    
    redPxlOut : out std_logic_vector( 7 downto 0 );
    greenPxlOut : out std_logic_vector( 7 downto 0 );
    bluePxlOut : out std_logic_vector( 7 downto 0 );
    validPxlOut : out std_logic;
    pxlCnt : out std_logic_vector( 7 downto 0 );
    
    validLine : out std_logic;
    newFrame : out std_logic
  );
end captureGBA;

architecture rtl of captureGBA is
signal cntX : integer range 0 to 245;
signal cntY : integer range 0 to 165;
signal prevCntX : integer range 0 to 245;
signal prevCntY : integer range 0 to 165;
signal validLine_int : std_logic;
signal curRedPxl : std_logic_vector( 4 downto 0 );
signal curGreenPxl : std_logic_vector( 4 downto 0 );
signal curBluePxl : std_logic_vector( 4 downto 0 );
signal dclk_int : std_logic;
signal dclk_prev : std_logic;
signal redExt : std_logic_vector( 2 downto 0 );
signal greenExt : std_logic_vector( 2 downto 0 );
signal blueExt : std_logic_vector( 2 downto 0 );
signal dclkRise : std_logic;
signal newPxl : std_logic;
signal vsyncFall : std_logic;
signal vsyncRise : std_logic;
signal vsync_int : std_logic;
signal vsync_del : std_logic;
signal syncCnt : integer range 0 to integer(ceil(325000.0/clkPeriodNS));
constant minSyncCnt : integer := integer(ceil(136500.0/clkPeriodNS));
begin
  
  redExt <= "111" when  curRedPxl( 0 ) = '1' else "000";
  greenExt <= "111" when  curGreenPxl( 0 ) = '1' else "000";
  blueExt <= "111" when  curBluePxl( 0 ) = '1' else "000";
  
  dclkRise <= '1' when ( dclk_int = '1' and dclk_prev = '0' ) else '0';
  newFrame <= '1' when ( prevCntY = 0 ) else '0';
  validPxlOut <= newPxl;
  
  vsyncRise <= '1' when ( vsync_int = '1' and vsync_del = '0' ) else '0';
  vsyncFall <= '1' when ( vsync_int = '0' and vsync_del = '1' ) else '0';

  process( clk ) is
  begin
    if ( rising_edge( clk ) ) then
      if ( rst = '1' ) then
        syncCnt <= 0;
        vsync_int <= '1';
        vsync_del <= '1';
        cntY <= 0;
        cntX <= 0;
        dclk_prev <= '1';
        curRedPxl <= ( others => '0' );
        curGreenPxl <= ( others => '0' );
        curBluePxl <= ( others => '0' );
        redPxlOut <= ( others => '0' );
        greenPxlOut <= ( others => '0' );
        bluePxlOut <= ( others => '0' );
        newPxl <= '0';
        prevCntY <= 0;
        prevCntX <= 0;
        dclk_int <= '1';
      
      else
        -- Shift prev. dclk
        dclk_int <= dclk;
        dclk_prev <= dclk_int;
        
        vsync_int <= vsync;
        vsync_del <= vsync_int;
        
        -- Shift newPxl.
        -- The very first pixel seems to be not a valid one (...start bit?)
        if ( prevCntX = 0 ) then
          newPxl <= '0';
        else
          newPxl <= dclkRise;
        end if;
        
        prevCntX <= cntX;
        prevCntY <= cntY;
        
        -- Capture new pxl.
        if ( dclkRise = '1' ) then
          curRedPxl <= redPxl;
          curGreenPxl <= greenPxl;
          curBluePxl <= bluePxl;
        end if;
        
        -- Extend prev. pxl.
        redPxlOut <= curRedPxl & redExt;
        greenPxlOut <= curGreenPxl & greenExt;
        bluePxlOut <= curBluePxl & blueExt;
        
        if ( vsyncFall = '1' ) then
          syncCnt <= 0;
        elsif ( vsync_int = '0' ) then
          syncCnt <= syncCnt + 1;
        end if;
        
        if ( vsyncRise = '1' and syncCnt >= minSyncCnt ) then
          cntY <= 0;
          cntX <= 0;
        elsif ( dclkRise = '1' ) then
          if ( cntX = 240 ) then
            cntX <= 0;
            cntY <= cntY + 1;
          else
            cntX <= cntX + 1;
          end if;
        end if;
      end if;
    end if;
  end process;
  
  pxlCnt <= std_logic_vector( to_unsigned( prevCntX, pxlCnt'length ) );
  
  -- Since the very first bit is a start bit, we have to count until 240
  validLine <= '1' when ( newPxl = '1' ) and ( prevCntX = 240 ) else '0';
 

end rtl;