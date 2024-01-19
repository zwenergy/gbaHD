-----------------------------------------------------------------------
-- Title: GBA color correction (updated)
-- Author: zwenergy
-----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity gbaColorCorrNew is
  port(
    gbaRed : in std_logic_vector( 4 downto 0 );
    gbaGreen : in std_logic_vector( 4 downto 0 );
    gbaBlue : in std_logic_vector( 4 downto 0 );
    
    rGBACol : out std_logic_vector( 7 downto 0 );
    gGBACol : out std_logic_vector( 7 downto 0 );
    bGBACol : out std_logic_vector( 7 downto 0 )
  );
end gbaColorCorrNew;

architecture rtl of gbaColorCorrNew is
signal redT, greenT, blueT : std_logic_vector( 7 downto 0 );
begin

  rGBACol <= redT;
  gGBACol <= greenT;
  bGBACol <= blueT;

  process( gbaRed ) is begin
    case gbaRed is
      when "00000" => redT <= "00000000";
      when "00001" => redT <= "00001000";
      when "00010" => redT <= "00001111";
      when "00011" => redT <= "00010111";
      when "00100" => redT <= "00011110";
      when "00101" => redT <= "00100110";
      when "00110" => redT <= "00101101";
      when "00111" => redT <= "00110101";
      when "01000" => redT <= "00111101";
      when "01001" => redT <= "01000100";
      when "01010" => redT <= "01001100";
      when "01011" => redT <= "01010011";
      when "01100" => redT <= "01011011";
      when "01101" => redT <= "01100011";
      when "01110" => redT <= "01101010";
      when "01111" => redT <= "01110010";
      when "10000" => redT <= "01111001";
      when "10001" => redT <= "10000001";
      when "10010" => redT <= "10001000";
      when "10011" => redT <= "10010000";
      when "10100" => redT <= "10011000";
      when "10101" => redT <= "10011111";
      when "10110" => redT <= "10100111";
      when "10111" => redT <= "10101110";
      when "11000" => redT <= "10110110";
      when "11001" => redT <= "10111110";
      when "11010" => redT <= "11000101";
      when "11011" => redT <= "11001101";
      when "11100" => redT <= "11010100";
      when "11101" => redT <= "11011100";
      when "11110" => redT <= "11100011";
      when "11111" => redT <= "11101011";
    end case;
  end process;

  process( gbaGreen ) is begin
    case gbaGreen is
      when "00000" => greenT <= "00000000";
      when "00001" => greenT <= "00000111";
      when "00010" => greenT <= "00001110";
      when "00011" => greenT <= "00010101";
      when "00100" => greenT <= "00011100";
      when "00101" => greenT <= "00100100";
      when "00110" => greenT <= "00101011";
      when "00111" => greenT <= "00110010";
      when "01000" => greenT <= "00111001";
      when "01001" => greenT <= "01000000";
      when "01010" => greenT <= "01000111";
      when "01011" => greenT <= "01001110";
      when "01100" => greenT <= "01010101";
      when "01101" => greenT <= "01011100";
      when "01110" => greenT <= "01100011";
      when "01111" => greenT <= "01101011";
      when "10000" => greenT <= "01110010";
      when "10001" => greenT <= "01111001";
      when "10010" => greenT <= "10000000";
      when "10011" => greenT <= "10000111";
      when "10100" => greenT <= "10001110";
      when "10101" => greenT <= "10010101";
      when "10110" => greenT <= "10011100";
      when "10111" => greenT <= "10100011";
      when "11000" => greenT <= "10101010";
      when "11001" => greenT <= "10110010";
      when "11010" => greenT <= "10111001";
      when "11011" => greenT <= "11000000";
      when "11100" => greenT <= "11000111";
      when "11101" => greenT <= "11001110";
      when "11110" => greenT <= "11010101";
      when "11111" => greenT <= "11011100";
    end case;
  end process;

  process( gbaBlue ) is begin
    case gbaBlue is
      when "00000" => blueT <= "00000000";
      when "00001" => blueT <= "00000111";
      when "00010" => blueT <= "00001111";
      when "00011" => blueT <= "00010110";
      when "00100" => blueT <= "00011101";
      when "00101" => blueT <= "00100101";
      when "00110" => blueT <= "00101100";
      when "00111" => blueT <= "00110011";
      when "01000" => blueT <= "00111011";
      when "01001" => blueT <= "01000010";
      when "01010" => blueT <= "01001001";
      when "01011" => blueT <= "01010000";
      when "01100" => blueT <= "01011000";
      when "01101" => blueT <= "01011111";
      when "01110" => blueT <= "01100110";
      when "01111" => blueT <= "01101110";
      when "10000" => blueT <= "01110101";
      when "10001" => blueT <= "01111100";
      when "10010" => blueT <= "10000100";
      when "10011" => blueT <= "10001011";
      when "10100" => blueT <= "10010010";
      when "10101" => blueT <= "10011010";
      when "10110" => blueT <= "10100001";
      when "10111" => blueT <= "10101000";
      when "11000" => blueT <= "10110000";
      when "11001" => blueT <= "10110111";
      when "11010" => blueT <= "10111110";
      when "11011" => blueT <= "11000101";
      when "11100" => blueT <= "11001101";
      when "11101" => blueT <= "11010100";
      when "11110" => blueT <= "11011011";
      when "11111" => blueT <= "11100011";
    end case;
  end process;

end rtl;
