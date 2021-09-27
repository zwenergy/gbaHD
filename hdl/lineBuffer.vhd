-----------------------------------------------------------------------
-- Title: Line buffer
-- Author: zwenergy
-----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity lineBuffer is
  generic(
    nrStgs : integer range 1 to 20 := 4
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
    
    redOutPrev : out std_logic_vector( 7 downto 0 );
    greenOutPrev : out std_logic_vector( 7 downto 0 );
    blueOutPrev :  out std_logic_vector( 7 downto 0 );
    redOutCur : out std_logic_vector( 7 downto 0 );
    greenOutCur : out std_logic_vector( 7 downto 0 );
    blueOutCur :  out std_logic_vector( 7 downto 0 );
    redOutNext : out std_logic_vector( 7 downto 0 );
    greenOutNext : out std_logic_vector( 7 downto 0 );
    blueOutNext :  out std_logic_vector( 7 downto 0 );
    
    pxlCntRead : in std_logic_vector( 7 downto 0 );
    pullLine : in std_logic;
    
    sameLine : out std_logic;
    newFrameOut : out std_logic
  );
end lineBuffer;

architecture rtl of lineBuffer is
signal inCnt : integer range 0 to nrStgs-1;
signal outCntCur, outCntPrev, outCntNext : integer range 0 to nrStgs-1;
signal inCntSel, outCntCurSel, outCntPrevSel, outCntNextSel : std_logic;
signal newFrames_sel0, newFrames_sel1 : std_logic_vector( nrStgs - 1 downto 0 );
signal wEnMult : std_logic_vector( nrStgs - 1 downto 0 );

type readDataMult is array (0 to nrStgs - 1) of std_logic_vector( 7 downto 0 );
signal redOut_int : readDataMult;
signal greenOut_int : readDataMult;
signal blueOut_int : readDataMult;

signal readAddr, writeAddr : std_logic_vector( 8 downto 0 );
signal readSel : std_logic_vector( 0 to nrStgs - 1 );

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
  
  redOutPrev <= redOut_int( outCntPrev );
  greenOutPrev <= greenOut_int( outCntPrev );
  blueOutPrev <= blueOut_int( outCntPrev );
  
  redOutCur <= redOut_int( outCntCur );
  greenOutCur <= greenOut_int( outCntCur );
  blueOutCur <= blueOut_int( outCntCur );
  
  redOutNext <= redOut_int( outCntNext );
  greenOutNext <= greenOut_int( outCntNext );
  blueOutNext <= blueOut_int( outCntNext );
  
  process( outCntCurSel, outCntPrevSel, outCntNextSel,
           outCntCur, outCntPrev, outCntNext ) is
  begin
    for i in 0 to nrStgs - 1 loop
      if ( ( outCntCur = i and outCntCurSel = '1' ) or
           ( outCntPrev = i and outCntPrevSel = '1' ) or
           ( outCntNext = i and outCntNextSel = '1' ) ) then
        readSel( i ) <= '1';
      else
        readSel( i ) <= '0';
      end if;
    end loop;
  end process;

  process( clkW ) is
  begin
    if ( rising_edge( clkW ) ) then
      if ( rst = '1' ) then
        inCnt <= 0;
        inCntSel <= '0';
        newFrames_Sel0 <= ( others => '0' );
        newFrames_Sel1 <= ( others => '0' );
      else
        if ( pushLine = '1' ) then
          if ( inCntSel = '1' ) then
            newFrames_Sel1( inCnt ) <= newFrameIn;
          else
            newFrames_Sel0( inCnt ) <= newFrameIn;
          end if;
          
          if ( inCnt  = nrStgs - 1 ) then
            inCnt <= 0;
            inCntSel <= not inCntSel;
          else
            inCnt <= inCnt + 1;
           end if;
        end if;
      end if;
    end if;
  end process;
  
  process( clkR ) is
  begin
    if ( rising_edge( clkR ) ) then
      if ( rst = '1' ) then
          outCntPrev <= nrStgs - 1;
          outCntCur <= 0;
          outCntNext <= 1;
          outCntPrevSel <= '1';
          outCntCurSel <= '0';
          outCntNextSel <= '0';
      else
        if ( pullLine = '1' ) then
          if ( outCntCur = nrStgs - 1 ) then
            outCntCur <= 0;
            outCntCurSel <= not outCntCurSel;
          else
            outCntCur <= outCntCur + 1;
          end if;
          
          if ( outCntPrev = nrStgs - 1 ) then
            outCntPrev <= 0;
            outCntPrevSel <= not outCntPrevSel;
          else
            outCntPrev <= outCntPrev + 1;
          end if;
          
          if ( outCntNext = nrStgs - 1 ) then
            outCntNext <= 0;
            outCntNextSel <= not outCntNextSel;
          else
            outCntNext <= outCntNext + 1;
          end if;
        end if;
      end if;
    end if;
  end process;
  
  sameLine <= '1' when ( inCnt = outCntCur and inCntSel = outCntCurSel ) else '0';
  newFrameOut <= newFrames_Sel0( outCntCur ) when outCntCurSel = '0' else newFrames_Sel1( outCntCur );
  writeAddr <= inCntSel & pxlCntWrite;
  
  -- Instantiate buffers.
  gen_buffers : for i in 0 to nrStgs - 1 generate
    curBuff : entity work.singeLineBuffer( rtl )
      port map(
        clkW => clkW,
        clkR => clkR, 
        rst => rst,
        wAddr => writeAddr,
        wEn => wEnMult( i ),
        rAddr( 8 ) => readSel( i ),
        rAddr( 7 downto 0 ) => pxlCntRead,
        redDataIn => redIn,
        greenDataIn => greenIn,
        blueDataIn => blueIn,
        redDataOut => redOut_int( i ),
        greenDataOut => greenOut_int( i ),
        blueDataOut => blueOut_int( i )        
      );
  end generate gen_buffers;

end rtl;