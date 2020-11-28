-----------------------------------------------------------------------
-- Title: TERC4 Encoder
-- Author: zwenergy
-----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity terc4Encoder is 
  port (
    datIn : in std_logic_vector( 3 downto 0 );
    clk : in std_logic;
    rst : in std_logic;
    
    datOut : out std_logic_vector( 9 downto 0 )
  );
end terc4Encoder;

architecture rtl of terc4Encoder is
signal datIn_int : std_logic_vector( 3 downto 0 );
begin

  process( clk ) is
  begin
    if rising_edge( clk ) then
      if ( rst = '1' ) then
        datIn_int <= ( others => '0' );
      else
        datIn_int <= datIn;
      end if;    
    end if;
  end process;
  
  process( datIn_int ) is
  begin
    case datIn_int is
      when "0000" => datOut <= "1010011100";
      when "0001" => datOut <= "1001100011";
      when "0010" => datOut <= "1011100100";
      when "0011" => datOut <= "1011100010";
      when "0100" => datOut <= "0101110001";
      when "0101" => datOut <= "0100011110";
      when "0110" => datOut <= "0110001110";
      when "0111" => datOut <= "0100111100";
      when "1000" => datOut <= "1011001100";
      when "1001" => datOut <= "0100111001";
      when "1010" => datOut <= "0110011100";
      when "1011" => datOut <= "1011000110";
      when "1100" => datOut <= "1010001110";
      when "1101" => datOut <= "1001110001";
      when "1110" => datOut <= "0101100011";
      when "1111" => datOut <= "1011000011";
      when others => datOut <= ( others => '0' );
    end case;
  end process;


end rtl;
