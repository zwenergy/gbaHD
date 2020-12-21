-----------------------------------------------------------------------
-- Title: ECC
-- Author: zwenergy
-----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ecc is 
  port (
    datIn : in std_logic_vector( 7 downto 0 );
    newPacket : in std_logic;
    enable : in std_logic;
    clk : in std_logic;
    rst : in std_logic;
    
    datOut : out std_logic_vector( 7 downto 0 )
  );
end ecc;

architecture rtl of ecc is
signal lfsr : std_logic_vector( 7 downto 0 );
signal datIn_rev : std_logic_vector( 7 downto 0 );
begin

  datIn_rev <= ( 0 => datIn( 7 ), 1 => datIn( 6 ), 2 => datIn( 5 ), 3 => datIn( 4 ),
                 4 => datIn( 3 ), 5 => datIn( 2 ), 6 => datIn( 1 ), 7 => datIn( 0 ) );

  process( clk ) is
  variable shiftreg : std_logic_vector( 7 downto 0 );
  variable tmpBit : std_logic;
  begin
    if rising_edge( clk ) then
      if ( rst = '1' ) then
        lfsr <= ( others => '0' );
      else
        if ( enable = '1' ) then
          if ( newPacket = '1' ) then
            shiftreg := ( others => '0' );
          else 
            shiftreg := lfsr;
          end if;
          
          for I in 7 downto 0 loop
            tmpBit := shiftreg( 0 ) xor datIn_rev( I );
            shiftreg := tmpBit & shiftreg( 7 downto 1 );
            if ( tmpBit = '1' ) then
              shiftreg := shiftreg xor "00000011";
            end if;
          end loop;
          
          lfsr <= shiftreg;
        end if;
      end if;    
    end if;
  end process;
  
  datOut <= lfsr;

end rtl;
