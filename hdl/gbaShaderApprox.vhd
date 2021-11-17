-----------------------------------------------------------------------
-- Title: GBA color correction
-- Author: zwenergy
-----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity gbaColorCorr is
  port(
    gbaRed : in std_logic_vector( 4 downto 0 );
    gbaGreen : in std_logic_vector( 4 downto 0 );
    gbaBlue : in std_logic_vector( 4 downto 0 );
    
    rGBACol : out std_logic_vector( 7 downto 0 );
    gGBACol : out std_logic_vector( 7 downto 0 );
    bGBACol : out std_logic_vector( 7 downto 0 )
  );
end gbaColorCorr;

architecture rtl of gbaColorCorr is
signal baseRed, baseGreen, baseBlue : std_logic_vector( 7 downto 0 );
begin

  process( baseRed, baseGreen, baseBlue, gbaRed, gbaGreen, gbaBlue ) is
  variable tmpRed, tmpGreen, tmpBlue : signed( 9 downto 0 );
  begin
    tmpRed :=  signed( "00" & baseRed ) + signed( "00000000" & gbaRed( 1 downto 0 ) ) + signed( "0000" & gbaGreen( 4 downto 0 ) & '0' ) - signed( "00000" & gbaBlue );
    if ( tmpRed < 0 ) then
      tmpRed := to_signed( 0, tmpRed'length );
    elsif ( tmpRed > 255 ) then
      tmpRed := to_signed( 255, tmpRed'length ); 
    end if;
    
    tmpGreen :=  signed( "00" & baseGreen ) + signed( "0000" & gbaRed( 4 downto 0 ) & '0' ) - signed( "00000" & gbaGreen( 4 downto 0 ) ) + signed( "000000" & gbaBlue( 3 downto 0 ) );
    if ( tmpGreen < 0 ) then
      tmpGreen := to_signed( 0, tmpGreen'length );
    elsif ( tmpGreen > 255 ) then
      tmpGreen := to_signed( 255, tmpGreen'length ); 
    end if;
    
    tmpBlue :=  signed( "00" & baseBlue ) + signed( "00000000" & gbaRed( 1 downto 0 ) ) + signed( "0000" & gbaGreen( 4 downto 0 ) & '0' ) - signed( "00000" & gbaBlue( 4 downto 0 ) );
    if ( tmpBlue < 0 ) then
      tmpBlue := to_signed( 0, tmpBlue'length );
    elsif ( tmpBlue > 255 ) then
      tmpBlue := to_signed( 255, tmpBlue'length ); 
    end if;
    
    rGBACol <= std_logic_vector( tmpRed( 7 downto 0 )  );
    gGBACol <= std_logic_vector( tmpGreen( 7 downto 0 )  );
    bGBACol <= std_logic_vector( tmpBlue( 7 downto 0 )  );
  end process;
  
process( gbaRed ) is begin
  case gbaRed is 
    when "00000" => baseRed <= "00000000";
    when "00001" => baseRed <= "00000001";
    when "00010" => baseRed <= "00000101";
    when "00011" => baseRed <= "00001000";
    when "00100" => baseRed <= "00001101";
    when "00101" => baseRed <= "00010010";
    when "00110" => baseRed <= "00010111";
    when "00111" => baseRed <= "00011101";
    when "01000" => baseRed <= "00100011";
    when "01001" => baseRed <= "00101001";
    when "01010" => baseRed <= "00110000";
    when "01011" => baseRed <= "00110111";
    when "01100" => baseRed <= "00111110";
    when "01101" => baseRed <= "01000101";
    when "01110" => baseRed <= "01001101";
    when "01111" => baseRed <= "01010100";
    when "10000" => baseRed <= "01011100";
    when "10001" => baseRed <= "01100101";
    when "10010" => baseRed <= "01101101";
    when "10011" => baseRed <= "01110110";
    when "10100" => baseRed <= "01111110";
    when "10101" => baseRed <= "10000111";
    when "10110" => baseRed <= "10010000";
    when "10111" => baseRed <= "10011010";
    when "11000" => baseRed <= "10100011";
    when "11001" => baseRed <= "10101101";
    when "11010" => baseRed <= "10110110";
    when "11011" => baseRed <= "11000000";
    when "11100" => baseRed <= "11001010";
    when "11101" => baseRed <= "11010100";
    when "11110" => baseRed <= "11011111";
    when "11111" => baseRed <= "11101001";
  end case;
end process;
process( gbaGreen ) is begin
  case gbaGreen is 
    when "00000" => baseGreen <= "00000000";
    when "00001" => baseGreen <= "00000001";
    when "00010" => baseGreen <= "00000100";
    when "00011" => baseGreen <= "00001000";
    when "00100" => baseGreen <= "00001011";
    when "00101" => baseGreen <= "00010000";
    when "00110" => baseGreen <= "00010101";
    when "00111" => baseGreen <= "00011010";
    when "01000" => baseGreen <= "00011111";
    when "01001" => baseGreen <= "00100101";
    when "01010" => baseGreen <= "00101011";
    when "01011" => baseGreen <= "00110001";
    when "01100" => baseGreen <= "00110111";
    when "01101" => baseGreen <= "00111110";
    when "01110" => baseGreen <= "01000100";
    when "01111" => baseGreen <= "01001011";
    when "10000" => baseGreen <= "01010010";
    when "10001" => baseGreen <= "01011010";
    when "10010" => baseGreen <= "01100001";
    when "10011" => baseGreen <= "01101001";
    when "10100" => baseGreen <= "01110001";
    when "10101" => baseGreen <= "01111001";
    when "10110" => baseGreen <= "10000001";
    when "10111" => baseGreen <= "10001001";
    when "11000" => baseGreen <= "10010010";
    when "11001" => baseGreen <= "10011010";
    when "11010" => baseGreen <= "10100011";
    when "11011" => baseGreen <= "10101100";
    when "11100" => baseGreen <= "10110101";
    when "11101" => baseGreen <= "10111110";
    when "11110" => baseGreen <= "11000111";
    when "11111" => baseGreen <= "11010000";
  end case;
end process;
process( gbaBlue ) is begin
  case gbaBlue is 
    when "00000" => baseBlue <= "00000000";
    when "00001" => baseBlue <= "00000001";
    when "00010" => baseBlue <= "00000100";
    when "00011" => baseBlue <= "00001000";
    when "00100" => baseBlue <= "00001100";
    when "00101" => baseBlue <= "00010001";
    when "00110" => baseBlue <= "00010110";
    when "00111" => baseBlue <= "00011011";
    when "01000" => baseBlue <= "00100001";
    when "01001" => baseBlue <= "00100111";
    when "01010" => baseBlue <= "00101101";
    when "01011" => baseBlue <= "00110011";
    when "01100" => baseBlue <= "00111010";
    when "01101" => baseBlue <= "01000001";
    when "01110" => baseBlue <= "01001000";
    when "01111" => baseBlue <= "01010000";
    when "10000" => baseBlue <= "01010111";
    when "10001" => baseBlue <= "01011111";
    when "10010" => baseBlue <= "01100111";
    when "10011" => baseBlue <= "01101111";
    when "10100" => baseBlue <= "01110111";
    when "10101" => baseBlue <= "10000000";
    when "10110" => baseBlue <= "10001000";
    when "10111" => baseBlue <= "10010001";
    when "11000" => baseBlue <= "10011010";
    when "11001" => baseBlue <= "10100011";
    when "11010" => baseBlue <= "10101100";
    when "11011" => baseBlue <= "10110101";
    when "11100" => baseBlue <= "10111111";
    when "11101" => baseBlue <= "11001000";
    when "11110" => baseBlue <= "11010010";
    when "11111" => baseBlue <= "11011100";
  end case;
end process;

end rtl;
