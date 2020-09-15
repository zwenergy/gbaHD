-----------------------------------------------------------------------
-- Title: Line buffer
-- Author: zwenergy
-----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity lineBuffer is
  generic(
    nrStgs : integer range 1 to 16 := 4
  );
  port(
    clkW : in std_logic;
    clkR : in std_logic;
    rst : in std_logic;
    redIn : in std_logic_vector( 7 downto 0 );
    greenIn : in std_logic_vector( 7 downto 0 );
    blueIn :  in std_logic_vector( 7 downto 0 );
    wEn : in std_logic;
    pxlCntWrite : in std_logic_vector( 7 downto 0 );
    pushLine : in std_logic;
    newFrameIn : in std_logic;
    
    redOut : out std_logic_vector( 7 downto 0 );
    greenOut : out std_logic_vector( 7 downto 0 );
    blueOut :  out std_logic_vector( 7 downto 0 );
    pxlCntRead : in std_logic_vector( 7 downto 0 );
    pullLine : in std_logic;
    
    sameLine : out std_logic;
    newFrameOut : out std_logic
  );
end lineBuffer;

architecture rtl of lineBuffer is
signal inCnt : integer range 0 to nrStgs-1;
signal outCnt : integer range 0 to nrStgs-1;
signal newFrames : std_logic_vector( nrStgs - 1 downto 0 );
signal wEnMult : std_logic_vector( nrStgs - 1 downto 0 );

type readDataMult is array (0 to nrStgs - 1) of std_logic_vector( 7 downto 0 );
signal redOut_int : readDataMult;
signal greenOut_int : readDataMult;
signal blueOut_int : readDataMult;

begin

  process( wEn, inCnt ) is
  begin
  
    for i in 0 to nrStgs - 1 loop
      if ( inCnt = i ) then
        wEnMult( i ) <= wEn;
      else
        wEnMult( i ) <= '0';
      end if;
    end loop;
    
  end process;
  
  redOut <= redOut_int( outCnt );
  greenOut <= greenOut_int( outCnt );
  blueOut <= blueOut_int( outCnt );

  process( clkW, rst ) is
  begin
    if ( rst = '1' ) then
      inCnt <= 0;
      newFrames <= ( others => '0' );
    elsif ( rising_edge( clkW ) ) then
      if ( pushLine = '1' ) then
      newFrames( inCnt ) <= newFrameIn;
        if ( inCnt  = nrStgs - 1 ) then
          inCnt <= 0;
        else
          inCnt <= inCnt + 1;
         end if;
      end if;
    end if;
  end process;
  
  process( clkR, rst ) is
  begin
    if ( rst = '1' ) then
        outCnt <= 0;
    elsif ( rising_edge( clkR ) ) then
      if ( pullLine = '1' ) then
        if ( outCnt = nrStgs - 1 ) then
          outCnt <= 0;
        else
          outCnt <= outCnt + 1;
        end if;
      end if;
    end if;
  end process;
  
  sameLine <= '1' when ( inCnt = outCnt ) else '0';
  newFrameOut <= newFrames( outCnt );
  
  
  -- Instantiate buffers.
  gen_buffers : for i in 0 to nrStgs - 1 generate
    curBuff : entity work.singeLineBuffer( rtl )
      port map(
        clkW => clkW,
        clkR => clkR, 
        rst => rst,
        wAddr => pxlCntWrite,
        wEn => wEnMult( i ),
        rAddr => pxlCntRead,
        redDataIn => redIn,
        greenDataIn => greenIn,
        blueDataIn => blueIn,
        redDataOut => redOut_int( i ),
        greenDataOut => greenOut_int( i ),
        blueDataOut => blueOut_int( i )        
      );
  end generate gen_buffers;

end rtl;