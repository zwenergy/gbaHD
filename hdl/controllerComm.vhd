-----------------------------------------------------------------------
-- Title: Controller Communication
-- Author: zwenergy
-----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity controllerComm is
  port(
    clk : in std_logic;
    rst : in std_logic;
    datIn : in std_logic;
    
    pxlGridToggle : out std_logic
  );
end controllerComm;

architecture rtl of controllerComm is
signal datIn_prev: std_logic;
begin
  
  process( clk ) is
  begin
    if rising_edge( clk ) then
      if ( rst = '1' ) then
        pxlGridToggle <= '0';
        datIn_prev <= '0';
      else
        datIn_prev <= datIn;
        if ( datIn = '1' and datIn_prev = '0' ) then
          pxlGridToggle <= '1';
        else
          pxlGridToggle <= '0';
        end if;
      end if;
    end if;
  end process;

end rtl;
