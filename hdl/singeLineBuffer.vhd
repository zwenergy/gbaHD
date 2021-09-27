-----------------------------------------------------------------------
-- Title: Single Line buffer
-- Author: zwenergy
-----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
library UNIMACRO;
use unimacro.Vcomponents.all;

entity singeLineBuffer is
  port(
    clkW : in std_logic;
    clkR : in std_logic;
    rst : in std_logic;
    wAddr : in std_logic_vector( 8 downto 0 );
    wEn : in std_logic;
    rAddr : in std_logic_vector( 8 downto 0 );
    redDataIn : in std_logic_vector( 7 downto 0 );
    blueDataIn : in std_logic_vector( 7 downto 0 );
    greenDataIn : in std_logic_vector( 7 downto 0 );
    
    redDataOut : out std_logic_vector( 7 downto 0 );
    blueDataOut : out std_logic_vector( 7 downto 0 );
    greenDataOut : out std_logic_vector( 7 downto 0 )
  );
end singeLineBuffer;

architecture rtl of singeLineBuffer is
signal readData : std_logic_vector( 31 downto 0 );
signal wea_int : std_logic_vector( 3 downto 0 );
signal addra_int : std_logic_vector( 8 downto 0 );
signal dina_int : std_logic_vector( 31 downto 0 );
signal addrb_int : std_logic_vector( 8 downto 0 );

begin

  wea_int <= ( others => wEn );
  addra_int <=  wAddr;
  dina_int <= "00000000" & redDataIn & greenDataIn & blueDataIn;
  addrb_int <= rAddr;
  
  bram_inst : BRAM_SDP_MACRO
    generic map(
      BRAM_SIZE => "18Kb",
      DEVICE => "7SERIES",
      WRITE_WIDTH => 32,
      READ_WIDTH => 32,
      DO_REG => 0,
      INIT_FILE => "NONE",
      SIM_COLLISION_CHECK => "WARNING_ONLY",
      SRVAL => X"000000000000000000",
      WRITE_MODE => "WRITE_FIRST"
     )
     port map(
      DO => readData,
      DI => dina_int,
      RDADDR => addrb_int,
      RDCLK => clkR,
      RDEN => '1',
      REGCE => '1',
      RST => rst,
      WE => wea_int,
      WRADDR => addra_int,
      WRCLK => clkW,
      WREN => wEn
     );
    
    redDataOut <= readData( 23 downto 16 );
    greenDataOut <= readData( 15 downto 8 );
    blueDataOut <= readData( 7 downto 0 );

end rtl;