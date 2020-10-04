-----------------------------------------------------------------------
-- Title: ECC
-- Author: zwenergy
-----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ecc is 
  port (
    datIn : in std_logic;
    newPacket : in std_logic;
    enable : in std_logic;
    clk : in std_logic;
    rst : in std_logic;
    
    datOut : out std_logic_vector( 7 downto 0 )
  );
end ecc;

architecture rtl of ecc is
signal lfsr : std_logic_vector( 7 downto 0 );
begin

  process( clk ) is
  begin
    if rising_edge( clk ) then
      if ( rst = '1' ) then
        lfsr <= ( others => '0' );
      else
        if ( enable = '1' ) then
          if ( newPacket = '1' ) then
            lfsr( 7 ) <= datIn;
            lfsr( 6 downto 2 ) <= "00000";
            lfsr( 1 ) <= datIn;
            lfsr( 0 ) <= datIn;
          else 
            lfsr( 7 ) <= datIn xor lfsr( 0 );
            lfsr( 6 downto 2 ) <= lfsr( 7 downto 3 );
            lfsr( 1 ) <= lfsr( 2 ) xor ( datIn xor lfsr( 0 ) );
            lfsr( 0 ) <= lfsr( 1 ) xor ( datIn xor lfsr( 0 ) );
          end if;
        end if;
      end if;    
    end if;
  end process;
  
  datOut <= lfsr;

end rtl;
