-----------------------------------------------------------------------
-- Title: Border Generator
-- Author: zwenergy
-----------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity borderGen is 
  generic(
    xMin : integer;
    xMax : integer;
    yMin : integer;
    yMax : integer
  );
  port (
    x : in integer range xMin to xMax;
    y : in integer range yMin to yMax; 
    r : out std_logic_vector( 7 downto 0 );
    g : out std_logic_vector( 7 downto 0 );
    b : out std_logic_vector( 7 downto 0 )
  );
end borderGen;
architecture rtl of borderGen is
begin

  r <= ( others => '0' );
  g <= ( others => '0' );
  b <= ( others => '0' );
  
end rtl;
