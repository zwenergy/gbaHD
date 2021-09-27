-----------------------------------------------------------------------
-- Title: Fractional Divier
-- Author: zwenergy
-----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity fracDiv is
  generic (
    mul : integer;
    div : integer;
    maxInt : integer
  );
  port (
    clk : in std_logic;
    rst : in std_logic;
    clkOut : out std_logic
  );
end fracDiv;

architecture rtl of fracDiv is
signal cnt : integer range 0 to maxInt;
begin

  
  process( clk ) is 
  variable tmpCnt : integer range 0 to maxInt;
  begin
    if ( rising_edge( clk ) ) then 
      if ( rst = '1' ) then
        cnt <= 0;
      else
        tmpCnt := cnt + mul;
        if ( tmpCnt >= div ) then
          tmpCnt := tmpCnt - div;
        end if;
        
        cnt <= tmpCnt;
      end if;
    end if;
  end process;
  
  clkOut <= '0' when ( cnt <= div / 2 ) else '1';
  
end rtl;
