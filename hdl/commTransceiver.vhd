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
    packetBits : integer := 16;
    clkFreq0 : real; -- kHz
    clkFreq1 : real; -- kHz
    clkFreqMax : real; -- kHz
    usBit : real
  );
  port(
    serDatIn : in std_logic;
    clk : in std_logic;
    rst : in std_logic;
    
    -- Corresponding to the generics.
    clkFreq : in std_logic;
    
    --serDatOut : out std_logic;
    --txActive : out std_logic;
    controllerOut : out std_logic_vector( 9 downto 0 );
    controllerOSDActive : out std_logic;
    
    osdActive : out std_logic;
    osdState : out std_logic_vector( 7 downto 0 );
    osdStateValid : out std_logic;
    
    -- Settings
    osdSmooth2x : out std_logic;
    osdSmooth4x : out std_logic;
    osdGridActive : out std_logic;
    osdGridBright : out std_logic;
    osdGridMult : out std_logic;
    osdColorCorrection : out std_logic;
    osdRate : out std_logic;
    osdSettingsValid : out std_logic;
    
    rxValid : out std_logic
    );
    
end commTransceiver;

architecture rtl of commTransceiver is
  constant cyclesBitMax : integer := integer( ceil( ( usBit / 1000000.0 ) /  ( 1.0 / ( clkFreqMax * 1000.0 ) ) ) );
  constant cyclesTimeout : integer := 2 * cyclesBitMax;
  
  constant cyclesBit0 : integer := integer( ceil( ( usBit / 1000000.0 ) /  ( 1.0 / ( clkFreq0 * 1000.0 ) ) ) );
  constant cyclesBit1 : integer := integer( ceil( ( usBit / 1000000.0 ) /  ( 1.0 / ( clkFreq1 * 1000.0 ) ) ) );
  constant cyclesHalfBit0 : integer := cyclesBit0 / 2;
  constant cyclesHalfBit1 : integer := cyclesBit1 / 2;
  
  constant prefixLen : integer := 4;
  constant controllerOSD_prefix : std_logic_vector( prefixLen - 1 downto 0 ) := "1000";
  constant config_prefix : std_logic_vector( prefixLen - 1 downto 0 ) := "0100";
  constant osdState_prefix : std_logic_vector( prefixLen - 1 downto 0 ) := "0010";
  
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
    
  -- A few status bits.
  signal rxPacket : std_logic;
  
begin
                       
  
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
        controllerOut <= ( others => '0' );
        rxValid <= '0';
        serDatFilter <= ( others => '1' );
        
        controllerOut <= ( others => '0' );
        controllerOSDActive <= '0';
        osdActive <= '0';
        osdState <= ( others => '0' );
        osdStateValid <= '0';
        osdSmooth2x <= '0';
        osdSmooth4x <= '0';
        osdGridActive <= '0';
        osdGridBright <= '0';
        osdGridMult <= '0';
        osdColorCorrection <= '0';
        osdRate <= '0';
        osdSettingsValid <= '0';
        
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
          if ( ( clkFreq = '0' and timeoutCnt = cyclesHalfBit0 ) or
               ( clkFreq = '1' and timeoutCnt = cyclesHalfBit1 ) ) then
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
        
          -- On screen buttons?
          if ( curPacket( packetBits - 1 downto packetBits - prefixLen ) = controllerOSD_prefix ) then
            controllerOut <= curPacket( 9 downto 0 );
            
          -- Settings packet?
          elsif ( curPacket( packetBits - 1 downto packetBits - prefixLen ) = config_prefix ) then
            osdSmooth2x <= curPacket( 0 );
            osdSmooth4x <= curPacket( 1 );
            osdGridActive <= curPacket( 2 );
            osdGridBright <= curPacket( 3 );
            osdGridMult <= curPacket( 4 );
            osdColorCorrection <= curPacket( 5 );
            osdRate <= curPacket( 6 );
            controllerOSDActive <= curPacket( 7 );
            osdSettingsValid <= '1';
            
          -- OSD state?
          elsif ( curPacket( packetBits - 1 downto packetBits - prefixLen ) = osdState_prefix ) then
            osdActive <= curPacket( 0 );
            osdState( 6 downto 0 ) <= curPacket( 7 downto 1 );
            osdState( 7 ) <= '0';
            osdStateValid <= '1';
    
          end if;
 
          rxValid <= '1';
        else 
          rxValid <= '0';
          osdSettingsValid <= '0';
          osdStateValid <= '0';
          
        end if;

      end if;
    end if;
  end process;
end rtl;
