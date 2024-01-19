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
    
    colorMode : in std_logic;
    
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
signal cntX : integer range -1 to 245;
signal cntY : integer range 0 to 165;
signal prevCntX : integer range -1 to 245;
signal prevCntY : integer range 0 to 165;
signal validLine_int : std_logic;
signal curRedPxl : std_logic_vector( 4 downto 0 );
signal curGreenPxl : std_logic_vector( 4 downto 0 );
signal curBluePxl : std_logic_vector( 4 downto 0 );
signal dclk_int : std_logic;
signal dclk_prev : std_logic;
signal dclkRise : std_logic;
signal newPxl : std_logic;
signal vsyncFall : std_logic;
signal vsyncRise : std_logic;
signal vsync_int : std_logic;
signal vsync_del : std_logic;
signal syncCnt : integer range 0 to integer(ceil(325000.0/clkPeriodNS));
constant minSyncCnt : integer := integer(ceil(136500.0/clkPeriodNS));

-- GBA Color Correction
signal redGBACol, greenGBACol, blueGBACol, redExt, greenExt, blueExt : std_logic_vector( 7 downto 0 );
begin

  -- Thanks to ManCloud for improving my stupid color extension :)
  
  redExtProc : process( curRedPxl ) is
  variable pxl_tmp, curPxl : unsigned( 7 downto 0 );
  begin
    curPxl := unsigned( curRedPxl ) & "000";
    pxl_tmp := "00000" & unsigned( curRedPxl( 4 downto 2 ) );
    pxl_tmp := pxl_tmp + curPxl;
    
    redExt <= std_logic_vector( pxl_tmp ) ;
    
    -- Keep limited range.
--    if ( unsigned( pxl_tmp ) < 16 ) then
--      pxl_tmp := std_logic_vector( to_unsigned( 16, pxl_tmp'length ) );
--    elsif ( unsigned( pxl_tmp ) > 235 ) then
--      pxl_tmp := std_logic_vector( to_unsigned( 235, pxl_tmp'length ) );
--    end if;
  end process;
  
  blueExtProc : process( curBluePxl ) is
  variable pxl_tmp, curPxl : unsigned( 7 downto 0 );
  begin
    curPxl := unsigned( curBluePxl ) & "000";
    pxl_tmp := "00000" & unsigned( curBluePxl( 4 downto 2 ) );
    pxl_tmp := pxl_tmp + curPxl;
    
    blueExt <= std_logic_vector( pxl_tmp ) ;
  end process;
  
  greenExtProc : process( curGreenPxl ) is
  variable pxl_tmp, curPxl : unsigned( 7 downto 0 );
  begin
    curPxl := unsigned( curGreenPxl ) & "000";
    pxl_tmp := "00000" & unsigned( curGreenPxl( 4 downto 2 ) );
    pxl_tmp := pxl_tmp + curPxl;
    
    greenExt <= std_logic_vector( pxl_tmp ) ;
  end process;
  
  -- GBA color correction.
  colorCorrection : entity work.gbaColorCorrNew( rtl )
    port map(
      gbaRed => curRedPxl,
      gbaGreen => curGreenPxl,
      gbaBlue => curBluePxl,
      rGBACol => redGBACol,
      gGBACol => greenGBACol,
      bGBACol => blueGBACol
    );
    
  -- Choose color mode.
  process( clk ) is
  begin
    if rising_edge( clk ) then
      if ( colorMode = '1' ) then
        redPxlOut <= redGBACol;
        greenPxlOut <= greenGBACol;
        bluePxlOut <= blueGBACol;
        
      else
        redPxlOut <= redExt;
        greenPxlOut <= greenExt;
        bluePxlOut <= blueExt;
        
      end if;
      
      pxlCnt <= std_logic_vector( to_unsigned( prevCntX, pxlCnt'length ) );
      
      -- Since the very first bit is a start bit, we have to count until 239
      if ( ( newPxl = '1' ) and ( prevCntX = 239 ) ) then
        validLine <= '1';
      else
        validLine <= '0';
      end if;
      
      if ( prevCntY = 0 ) then
        newFrame <= '1';
      else
        newFrame <= '0';
      end if;

      validPxlOut <= newPxl;
      
    end if;
  end process;
  
  
  dclkRise <= '1' when ( dclk_int = '1' and dclk_prev = '0' ) else '0';
  
  
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
        cntX <= -1;
        dclk_prev <= '1';
        curRedPxl <= ( others => '0' );
        curGreenPxl <= ( others => '0' );
        curBluePxl <= ( others => '0' );
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
        if ( cntX = -1 ) then
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
        
        if ( vsyncFall = '1' ) then
          syncCnt <= 0;
        elsif ( vsync_int = '0' ) then
          syncCnt <= syncCnt + 1;
        end if;
        
        if ( vsyncRise = '1' and syncCnt >= minSyncCnt ) then
          cntY <= 0;
          cntX <= -1;
        elsif ( dclkRise = '1' ) then
          if ( cntX = 239 ) then
            cntX <= -1;
            cntY <= cntY + 1;
          else
            cntX <= cntX + 1;
          end if;
        end if;
      end if;
    end if;
  end process;
  
 

end rtl;