-----------------------------------------------------------------------
-- Title: Controller Transceiver
-- Author: zwenergy
-----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.ALL;
use IEEE.std_logic_misc.ALL;

entity commTransceiver is
  generic( 
    packetBits : integer := 8;
    clkFreq : real; -- kHz
    usBit : real
  );
  port(
    serDatIn : in std_logic;
    clk : in std_logic;
    rst : in std_logic;
    
    --serDatOut : out std_logic;
    --txActive : out std_logic;
    controllerOut : out std_logic_vector( 5 downto 0 );
    osdActive : out std_logic;
    rxValid : out std_logic
    );
    
end commTransceiver;

architecture rtl of commTransceiver is
  constant cyclesBit : integer := integer( ceil( ( usBit / 1000000.0 ) /  ( 1.0 / ( clkFreq * 1000.0 ) ) ) );
  constant cyclesTimeout : integer := 2 * cyclesBit;
  constant cyclesHalfBit : integer := cyclesBit / 2;
  
  -- Timeout counter.
  signal timeoutCnt : integer range 0 to cyclesTimeout;
  -- Bit counter.
  signal bitCnt : integer range 0 to packetBits;
  -- Packet.
  signal curPacket : std_logic_vector( packetBits - 1 downto 0 );
  -- Flag for a new packet.
  signal newPacket : std_logic;

  signal serDatInPrev, serDatIn_filtered : std_logic;
  signal serDatFilter : std_logic_vector( 7 downto 0 );
  signal osdActive_int : std_logic;
  
  -- A few status bits.
  signal rxPacket : std_logic;
  
begin

  osdActive <= osdActive_int;
                       
  
  -- Synch. part.
  process( clk ) is
  begin
    if ( rising_edge( clk ) ) then
      if ( rst = '1' ) then
        timeoutCnt <= 0;
        bitCnt <= 0;
        curPacket <= ( others => '0' );
        newPacket <= '0';
        serDatInPrev <= '0';
        rxPacket <= '0';
        osdActive_int <= '0';
        controllerOut <= ( others => '0' );
        rxValid <= '0';
        serDatFilter <= ( others => '1' );
        serDatIn_filtered <= '1';
        --serDatOut <= '1';
        --txActive <= '0';
      else
      
        -- Serial Input related stuff.
        serDatFilter( 7 ) <= serDatIn;
        serDatFilter( 6 downto 0 ) <= serDatFilter( 7 downto 1 );
        
        if ( and_reduce( serDatFilter ) = '1' ) then
          serDatIn_filtered <= '1';
        elsif ( or_reduce( serDatFilter ) = '0' ) then
          serDatIn_filtered <= '0';
        end if;          
      
        serDatInPrev <= serDatIn_filtered;
        
        -- Per default, there is no new packet.
        newPacket <= '0';
        
        -- Falling edge, a new bit is arriving.
        if ( serDatInPrev = '1' and serDatIn_filtered = '0' ) then
          -- Reset counter.
          timeoutCnt <= 0;
          rxPacket <= '1';
        elsif ( rxPacket = '1' ) then
          timeoutCnt <= timeoutCnt + 1;
          
          -- Sample?
          if ( timeoutCnt = cyclesHalfBit ) then
            curPacket( packetBits - 1 ) <= serDatIn_filtered;
            curPacket( packetBits - 2 downto 0 ) <= curPacket( packetBits - 1 downto 1 );
            bitCnt <= bitCnt + 1;
            
          -- Timeout?
          elsif ( timeoutCnt = cyclesTimeout ) then
            rxPacket <= '0';
            bitCnt <= 0;
            if ( bitCnt = packetBits ) then
              newPacket <= '1';
            end if;
          end if;
        end if;
        
        
        -- Controller output related stuff.
        if ( newPacket = '1' ) then
          controllerOut <= curPacket( packetBits - 1 downto packetBits - 6 );
          
          if ( curPacket( packetBits - 7 ) = '1' ) then
            osdActive_int <= '1';
          else
            osdActive_int <= '0';
          end if;
 
          rxValid <= '1';
        else 
          rxValid <= '0';
        end if;

      end if;
    end if;
  end process;
end rtl;
