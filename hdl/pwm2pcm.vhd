-----------------------------------------------------------------------
-- Title: GBA Audio PWM to PCM converter
-- Author: zwenergy
-----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all;
use IEEE.math_real.ALL;

entity pwm2pcm is
  generic (
    clkFreq0 : real; -- clk freq. in kHz
    clkFreq1 : real; -- clk freq. in kHz
    clkFreqMax : real; -- clk freq. in kHz
    sampleFreq : real;
    damp : integer
  );
  port (
    pwmInL : in std_logic;
    pwmInR : in std_logic;
    clk : in std_logic;
    rst : in std_logic;
    
    -- Corresponding to the generics.
    clkFreq : in std_logic;
    
    sampleClkOut : out std_logic;
    datOutL : out std_logic_vector( 15 downto 0 );
    datOutR : out std_logic_vector( 15 downto 0 );
    validOut : out std_logic 
  );
end pwm2pcm;

architecture rtl of pwm2pcm is
constant maxCntClk : integer := integer( ceil( clkFreqMax / sampleFreq ) ) - 1;
constant maxHighCnt : integer := integer( ceil( clkFreqMax / 65.5360 ) ) - 1;
constant highCntBits : integer := integer( ceil( log2( real( maxHighCnt ) ) ) ) + 1;
signal cnt : integer range 0 to maxCntClk;
signal highCntL : unsigned( highCntBits - 1 downto 0 );
signal highCntR : unsigned( highCntBits - 1 downto 0 );
signal curSampleL, curSampleR : std_logic_vector( 15 downto 0 );
signal pwmInL_prev, pwmInR_prev: std_logic;

constant maxCntSampleClk0 : integer := integer( floor( clkFreq0 / ( sampleFreq ) ) ) - 1;
constant maxCntSampleClkHalf0 : integer := maxCntSampleClk0 / 2;
constant maxCntSampleClk1 : integer := integer( floor( clkFreq1 / ( sampleFreq ) ) ) - 1;
constant maxCntSampleClkHalf1 : integer := maxCntSampleClk1 / 2;
constant maxCntSampleClk_total : integer := integer( floor( clkFreqMax / ( sampleFreq ) ) ) - 1;
signal sampleClkCnt : integer range 0 to maxCntSampleClk_total;

constant minCycles : integer := 5;
signal pwmL_int_buf, pwmR_int_buf : std_logic_vector( 0 to minCycles - 1 );
signal pwmL_int, pwmR_int : std_logic;

begin

  datOutL <= curSampleL;
  datOutR <= curSampleR;
  
  -- Filter
  process( clk ) is
  begin
    if ( rising_edge( clk ))  then
      if ( rst = '1' ) then
        pwmL_int <= '0';
        pwmR_int <= '0';
        pwmL_int_buf <= ( others => '0' );
        pwmR_int_buf <= ( others => '0' );
      else
        pwmL_int_buf( 0 ) <= pwmInL;
        pwmL_int_buf( 1 to minCycles - 1 ) <= pwmL_int_buf( 0 to minCycles - 2 );
        
        pwmR_int_buf( 0 ) <= pwmInR;
        pwmR_int_buf( 1 to minCycles - 1 ) <= pwmR_int_buf( 0 to minCycles - 2 );
        
        if ( pwmL_int = '0' ) then
          if ( and_reduce( pwmL_int_buf ) = '1' ) then
            pwmL_int <= '1';
          end if;
        else
          if ( or_reduce( pwmL_int_buf ) = '0' ) then
            pwmL_int <= '0';
          end if;
        end if;
        
        if ( pwmR_int = '0' ) then
          if ( and_reduce( pwmR_int_buf ) = '1' ) then
            pwmR_int <= '1';
          end if;
        else
          if ( or_reduce( pwmR_int_buf ) = '0' ) then
            pwmR_int <= '0';
          end if;
        end if;
        
      end if;
    end if;
  end process;
  
  process( clk ) is
  variable tmpCurSampleL, tmpCurSampleR : unsigned( 15 downto 0 );
  begin
    if ( rising_edge( clk ) ) then
      if ( rst = '1' ) then
        highCntL <= ( others => '0' );
        pwmInL_prev <= '0';
        curSampleL <= ( others => '0' );
        
        highCntR <= ( others => '0' );
        pwmInR_prev <= '0';
        curSampleR <= ( others => '0' );
      else
        pwmInL_prev <= pwmL_int;
        
        if ( pwmInL_prev = '0'  and pwmL_int = '1' ) then
          highCntL <= ( others => '0' );
          
          tmpCurSampleL := ( others => '0' );
          tmpCurSampleL( 15 downto ( 16 - highCntBits ) ) := highCntL;
          tmpCurSampleL := shift_right( tmpCurSampleL, damp );
          
          curSampleL <= std_logic_vector( tmpCurSampleL );
          
        elsif ( pwmL_int = '1' ) then
          highCntL <= highCntL + 1;
        end if;
        
        
        pwmInR_prev <= pwmR_int;
        
        if ( pwmInR_prev = '0'  and pwmR_int = '1' ) then
          highCntR <= ( others => '0' );
          
          tmpCurSampleR := ( others => '0' );
          tmpCurSampleR( 15 downto ( 16 - highCntBits ) ) := highCntR;
          tmpCurSampleR := shift_right( tmpCurSampleR, damp );
          
          curSampleR <= std_logic_vector( tmpCurSampleR );
          
        elsif ( pwmR_int = '1' ) then
          highCntR <= highCntR + 1;
        end if;
        
      end if;
    end if;
  end process;

  process( clk ) is
  begin
    if ( rising_edge( clk ) ) then
      if ( rst = '1' ) then
        cnt <= 0;
        validOut <= '0';
      else
        if ( cnt < maxCntClk ) then
          cnt <= cnt + 1;
          validOut <= '0';
        else
          cnt <= 0;
          validOut <= '1';
        end if;
      end if;
    end if;
  end process;
  
  process( clk ) is
  begin
    if ( rising_edge( clk ) ) then
      if ( rst = '1' ) then
        sampleClkCnt <= 0;
      else
      
        if ( ( clkFreq = '0' and sampleClkCnt >= maxCntSampleClkHalf0 ) or 
             ( clkFreq = '1' and sampleClkCnt >= maxCntSampleClkHalf1 ) ) then
          sampleClkOut <= '0';
        else
          sampleClkOut <= '1';
        end if;
      
        if ( ( clkFreq = '0' and sampleClkCnt = maxCntSampleClk0 ) or
             ( clkFreq = '1' and sampleClkCnt = maxCntSampleClk1 ) ) then
          sampleClkCnt <= 0;
        else 
          sampleClkCnt <= sampleClkCnt + 1;
        end if;
      end if;      
    end if;
  end process;

end rtl;