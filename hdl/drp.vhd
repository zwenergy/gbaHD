-----------------------------------------------------------------------
-- Title: DRP
-- Author: zwenergy
-----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity drp is
  port (
    -- 000: 60 Hz, 720p
    -- 001: 59.x Hz, 720p
    -- 010: 60 Hz, 1080p
    -- 011: 59.x Hz, 1080p
    -- 100: 60 Hz, 480p
    -- 101: 59.x Hz, 480p
    stateSel : in std_logic_vector( 2 downto 0 );
    doSwitch : in std_logic;
    
    doSig : in std_logic_vector( 15 downto 0 );
    drdy : in std_logic;
    locked : in std_logic;
        
    clk : in std_logic;
    rst : in std_logic;
    
    busy : out std_logic;
    
    dwe : out std_logic;
    den : out std_logic;
    daddr : out std_logic_vector( 6 downto 0 );
    diSig : out std_logic_vector( 15 downto 0 );
    dclk : out std_logic;
    rstMMCM : out std_logic
  );
end drp;

architecture rtl of drp is
type reconfEntry_t is record
  addr : std_logic_vector( 6 downto 0 );
  data : std_logic_vector( 15 downto 0 );
  mask :  std_logic_vector( 15 downto 0 );
end record reconfEntry_t;
type reconfSetting_t is array( 0 to 13 ) of reconfEntry_t;
type reconfROM_t is array( 0 to 5 ) of reconfSetting_t;

-- The actual ROM.
constant reconfROM : reconfROM_t :=
-- 60 Hz, 720p
( 0 =>
  -- General settings
  ( 0 =>
    (
      addr => std_logic_vector( to_unsigned( 16#14#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#1491#, 16 ) ),
      mask => "0001000000000000"
    ),
    
    1 =>
    (
      addr => std_logic_vector( to_unsigned( 16#15#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#1800#, 16 ) ),
      mask => "1000000000000000"
    ),
    2 =>
    (
      addr => std_logic_vector( to_unsigned( 16#13#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#2400#, 16 ) ),
      mask => "1100001100000000"
    ),
    3 =>
    (
      addr => std_logic_vector( to_unsigned( 16#16#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#0083#, 16 ) ),
      mask => "1100000000000000"
    ),
    4 =>
    (
      addr => std_logic_vector( to_unsigned( 16#4F#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#1000#, 16 ) ),
      mask => "0110011001101111"
    ),
    5 =>
    (
      addr => std_logic_vector( to_unsigned( 16#4E#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#0900#, 16 ) ),
      mask => "0110011011111111"
    ),
    6 =>
    (
      addr => std_logic_vector( to_unsigned( 16#28#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#FFFF#, 16 ) ),
      mask => "0000000000000000"
    ),
    7 =>
    (
      addr => std_logic_vector( to_unsigned( 16#18#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#00fa#, 16 ) ),
      mask => "1111110000000000"
    ),
    8 =>
    (
      addr => std_logic_vector( to_unsigned( 16#19#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#7c01#, 16 ) ),
      mask => "1000000000000000"
    ),
    9 =>
    (
      addr => std_logic_vector( to_unsigned( 16#1A#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#7de9#, 16 ) ),
      mask => "1000000000000000"
    ),
    -- Clkout0
    10 =>
    (
      addr => std_logic_vector( to_unsigned( 16#08#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#1041#, 16 ) ),
      mask => "0001000000000000"
    ),
    11 =>
    (
      addr => std_logic_vector( to_unsigned( 16#09#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#0000#, 16 ) ),
      mask => "1000000000000000"
    ),
    -- Clkout1
    12 =>
    (
      addr => std_logic_vector( to_unsigned( 16#0A#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#1145#, 16 ) ),
      mask => "1000000000000000"
    ),
    13 =>
    (
      addr => std_logic_vector( to_unsigned( 16#0B#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#0000#, 16 ) ),
      mask => "1111110000000000"
    )
  ),
  
  -- 59.7 Hz, 720 p
  1 =>
  -- General settings
  ( 0 =>
    (
      addr => std_logic_vector( to_unsigned( 16#14#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#1410#, 16 ) ),
      mask => "0001000000000000"
    ),
    
    1 =>
    (
      addr => std_logic_vector( to_unsigned( 16#15#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#2800#, 16 ) ),
      mask => "1000000000000000"
    ),
    2 =>
    (
      addr => std_logic_vector( to_unsigned( 16#13#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#2800#, 16 ) ),
      mask => "1100001100000000"
    ),
    3 =>
    (
      addr => std_logic_vector( to_unsigned( 16#16#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#0042#, 16 ) ),
      mask => "1100000000000000"
    ),
    4 =>
    (
      addr => std_logic_vector( to_unsigned( 16#4F#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#1000#, 16 ) ),
      mask => "0110011001101111"
    ),
    5 =>
    (
      addr => std_logic_vector( to_unsigned( 16#4E#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#0900#, 16 ) ),
      mask => "0110011011111111"
    ),
    6 =>
    (
      addr => std_logic_vector( to_unsigned( 16#28#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#FFFF#, 16 ) ),
      mask => "0000000000000000"
    ),
    7 =>
    (
      addr => std_logic_vector( to_unsigned( 16#18#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#002c#, 16 ) ),
      mask => "1111110000000000"
    ),
    8 =>
    (
      addr => std_logic_vector( to_unsigned( 16#19#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#7c01#, 16 ) ),
      mask => "1000000000000000"
    ),
    9 =>
    (
      addr => std_logic_vector( to_unsigned( 16#1A#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#7de9#, 16 ) ),
      mask => "1000000000000000"
    ),
    -- Clkout0
    10 =>
    (
      addr => std_logic_vector( to_unsigned( 16#08#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#1042#, 16 ) ),
      mask => "0001000000000000"
    ),
    11 =>
    (
      addr => std_logic_vector( to_unsigned( 16#09#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#0080#, 16 ) ),
      mask => "1000000000000000"
    ),
    -- Clkout1
    12 =>
    (
      addr => std_logic_vector( to_unsigned( 16#0A#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#11c8#, 16 ) ),
      mask => "1000000000000000"
    ),
    13 =>
    (
      addr => std_logic_vector( to_unsigned( 16#0B#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#0080#, 16 ) ),
      mask => "1111110000000000"
    )
  ),
  
  -- 60 Hz, 1080p
  2 =>
  -- General settings
  ( 0 =>
    (
      addr => std_logic_vector( to_unsigned( 16#14#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#1491#, 16 ) ),
      mask => "0001000000000000"
    ),
    
    1 =>
    (
      addr => std_logic_vector( to_unsigned( 16#15#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#1800#, 16 ) ),
      mask => "1000000000000000"
    ),
    2 =>
    (
      addr => std_logic_vector( to_unsigned( 16#13#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#2400#, 16 ) ),
      mask => "1100001100000000"
    ),
    3 =>
    (
      addr => std_logic_vector( to_unsigned( 16#16#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#0083#, 16 ) ),
      mask => "1100000000000000"
    ),
    4 =>
    (
      addr => std_logic_vector( to_unsigned( 16#4F#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#1000#, 16 ) ),
      mask => "0110011001101111"
    ),
    5 =>
    (
      addr => std_logic_vector( to_unsigned( 16#4E#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#0900#, 16 ) ),
      mask => "0110011011111111"
    ),
    6 =>
    (
      addr => std_logic_vector( to_unsigned( 16#28#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#FFFF#, 16 ) ),
      mask => "0000000000000000"
    ),
    7 =>
    (
      addr => std_logic_vector( to_unsigned( 16#18#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#00fa#, 16 ) ),
      mask => "1111110000000000"
    ),
    8 =>
    (
      addr => std_logic_vector( to_unsigned( 16#19#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#7c01#, 16 ) ),
      mask => "1000000000000000"
    ),
    9 =>
    (
      addr => std_logic_vector( to_unsigned( 16#1A#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#7de9#, 16 ) ),
      mask => "1000000000000000"
    ),
    -- Clkout0
    10 =>
    (
      addr => std_logic_vector( to_unsigned( 16#08#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#1041#, 16 ) ),
      mask => "0001000000000000"
    ),
    11 =>
    (
      addr => std_logic_vector( to_unsigned( 16#09#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#00c0#, 16 ) ),
      mask => "1000000000000000"
    ),
    -- Clkout1
    12 =>
    (
      addr => std_logic_vector( to_unsigned( 16#0A#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#1083#, 16 ) ),
      mask => "1000000000000000"
    ),
    13 =>
    (
      addr => std_logic_vector( to_unsigned( 16#0B#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#0080#, 16 ) ),
      mask => "1111110000000000"
    )
  ),
  
  -- 59.x Hz, 1080p
  3 =>
  -- General settings
  ( 0 =>
    (
      addr => std_logic_vector( to_unsigned( 16#14#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#175c#, 16 ) ),
      mask => "0001000000000000"
    ),
    
    1 =>
    (
      addr => std_logic_vector( to_unsigned( 16#15#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#1800#, 16 ) ),
      mask => "1000000000000000"
    ),
    2 =>
    (
      addr => std_logic_vector( to_unsigned( 16#13#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#2400#, 16 ) ),
      mask => "1100001100000000"
    ),
    3 =>
    (
      addr => std_logic_vector( to_unsigned( 16#16#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#0104#, 16 ) ),
      mask => "1100000000000000"
    ),
    4 =>
    (
      addr => std_logic_vector( to_unsigned( 16#4F#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#1000#, 16 ) ),
      mask => "0110011001101111"
    ),
    5 =>
    (
      addr => std_logic_vector( to_unsigned( 16#4E#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#0800#, 16 ) ),
      mask => "0110011011111111"
    ),
    6 =>
    (
      addr => std_logic_vector( to_unsigned( 16#28#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#FFFF#, 16 ) ),
      mask => "0000000000000000"
    ),
    7 =>
    (
      addr => std_logic_vector( to_unsigned( 16#18#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#00fa#, 16 ) ),
      mask => "1111110000000000"
    ),
    8 =>
    (
      addr => std_logic_vector( to_unsigned( 16#19#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#7c01#, 16 ) ),
      mask => "1000000000000000"
    ),
    9 =>
    (
      addr => std_logic_vector( to_unsigned( 16#1A#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#7de9#, 16 ) ),
      mask => "1000000000000000"
    ),
    -- Clkout0
    10 =>
    (
      addr => std_logic_vector( to_unsigned( 16#08#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#1041#, 16 ) ),
      mask => "0001000000000000"
    ),
    11 =>
    (
      addr => std_logic_vector( to_unsigned( 16#09#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#00c0#, 16 ) ),
      mask => "1000000000000000"
    ),
    -- Clkout1
    12 =>
    (
      addr => std_logic_vector( to_unsigned( 16#0A#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#1083#, 16 ) ),
      mask => "1000000000000000"
    ),
    13 =>
    (
      addr => std_logic_vector( to_unsigned( 16#0B#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#0080#, 16 ) ),
      mask => "1111110000000000"
    )
  ),
  
  -- 60 Hz, 480p
  4 =>
  -- General settings
  ( 0 =>
    (
      addr => std_logic_vector( to_unsigned( 16#14#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#15d7#, 16 ) ),
      mask => "0001000000000000"
    ),
    
    1 =>
    (
      addr => std_logic_vector( to_unsigned( 16#15#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#2800#, 16 ) ),
      mask => "1000000000000000"
    ),
    2 =>
    (
      addr => std_logic_vector( to_unsigned( 16#13#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#2800#, 16 ) ),
      mask => "1100001100000000"
    ),
    3 =>
    (
      addr => std_logic_vector( to_unsigned( 16#16#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#0083#, 16 ) ),
      mask => "1100000000000000"
    ),
    4 =>
    (
      addr => std_logic_vector( to_unsigned( 16#4F#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#0100#, 16 ) ),
      mask => "0110011001101111"
    ),
    5 =>
    (
      addr => std_logic_vector( to_unsigned( 16#4E#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#1900#, 16 ) ),
      mask => "0110011011111111"
    ),
    6 =>
    (
      addr => std_logic_vector( to_unsigned( 16#28#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#FFFF#, 16 ) ),
      mask => "0000000000000000"
    ),
    7 =>
    (
      addr => std_logic_vector( to_unsigned( 16#18#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#00fa#, 16 ) ),
      mask => "1111110000000000"
    ),
    8 =>
    (
      addr => std_logic_vector( to_unsigned( 16#19#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#7c01#, 16 ) ),
      mask => "1000000000000000"
    ),
    9 =>
    (
      addr => std_logic_vector( to_unsigned( 16#1A#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#7de9#, 16 ) ),
      mask => "1000000000000000"
    ),
    -- Clkout0
    10 =>
    (
      addr => std_logic_vector( to_unsigned( 16#08#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#10c4#, 16 ) ),
      mask => "0001000000000000"
    ),
    11 =>
    (
      addr => std_logic_vector( to_unsigned( 16#09#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#0080#, 16 ) ),
      mask => "1000000000000000"
    ),
    -- Clkout1
    12 =>
    (
      addr => std_logic_vector( to_unsigned( 16#0A#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#1452#, 16 ) ),
      mask => "1000000000000000"
    ),
    13 =>
    (
      addr => std_logic_vector( to_unsigned( 16#0B#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#0080#, 16 ) ),
      mask => "1111110000000000"
    )
  ),
  
--  -- 59.x Hz, 480p
  5 =>
  -- General settings
  ( 0 =>
    (
      addr => std_logic_vector( to_unsigned( 16#14#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#175d#, 16 ) ),
      mask => "0001000000000000"
    ),
    
    1 =>
    (
      addr => std_logic_vector( to_unsigned( 16#15#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#4c00#, 16 ) ),
      mask => "1000000000000000"
    ),
    2 =>
    (
      addr => std_logic_vector( to_unsigned( 16#13#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#1400#, 16 ) ),
      mask => "1100001100000000"
    ),
    3 =>
    (
      addr => std_logic_vector( to_unsigned( 16#16#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#0105#, 16 ) ),
      mask => "1100000000000000"
    ),
    4 =>
    (
      addr => std_logic_vector( to_unsigned( 16#4F#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#1000#, 16 ) ),
      mask => "0110011001101111"
    ),
    5 =>
    (
      addr => std_logic_vector( to_unsigned( 16#4E#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#0800#, 16 ) ),
      mask => "0110011011111111"
    ),
    6 =>
    (
      addr => std_logic_vector( to_unsigned( 16#28#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#FFFF#, 16 ) ),
      mask => "0000000000000000"
    ),
    7 =>
    (
      addr => std_logic_vector( to_unsigned( 16#18#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#00fa#, 16 ) ),
      mask => "1111110000000000"
    ),
    8 =>
    (
      addr => std_logic_vector( to_unsigned( 16#19#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#7c01#, 16 ) ),
      mask => "1000000000000000"
    ),
    9 =>
    (
      addr => std_logic_vector( to_unsigned( 16#1A#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#7de9#, 16 ) ),
      mask => "1000000000000000"
    ),
    -- Clkout0
    10 =>
    (
      addr => std_logic_vector( to_unsigned( 16#08#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#1083#, 16 ) ),
      mask => "0001000000000000"
    ),
    11 =>
    (
      addr => std_logic_vector( to_unsigned( 16#09#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#0080#, 16 ) ),
      mask => "1000000000000000"
    ),
    -- Clkout1
    12 =>
    (
      addr => std_logic_vector( to_unsigned( 16#0A#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#130d#, 16 ) ),
      mask => "1000000000000000"
    ),
    13 =>
    (
      addr => std_logic_vector( to_unsigned( 16#0B#, 7 ) ),
      data => std_logic_vector( to_unsigned( 16#0080#, 16 ) ),
      mask => "1111110000000000"
    )
  )
);

type fsmSingleValStates is ( idle, setDADDR, waitDRDY0, 
                             applyMask, doWrite, waitDRDY1 );
type fsmTopStates is ( idle, setVal, waitVal, incInd, waitLock );
signal fsmTopCur, fsmTopNext : fsmTopStates := idle;
signal fsmSingleValCur, fsmSingleValNext : fsmSingleValStates := idle;
signal nextAddr : std_logic_vector( 6 downto 0 );
signal nextVal : std_logic_vector( 15 downto 0 );
signal nextMask : std_logic_vector( 15 downto 0 );
signal setNewVal : std_logic;

signal itemInd : integer range 0 to 13;

signal maskedVal : std_logic_vector( 15 downto 0 );

signal stateSel_int : std_logic_vector( 2 downto 0 );
begin

  dclk <= clk;
  
  -- Do masking.
  process( clk ) is
  begin
    if ( rising_edge( clk ) ) then
      if ( fsmSingleValCur = applyMask ) then
        maskedVal <= ( nextMask and doSig ) or ( nextVal and not( nextMask ) ) ;
      end if;
    end if;
  end process;
  
  -- Simple seq.
  process( clk ) is
  begin
    if ( rising_edge( clk ) ) then
      if ( fsmTopCur = idle ) then
        stateSel_int <= stateSel;
      end if;
    end if;
  end process;
  
  -- Do index increasing.
  process( clk ) is
  begin
    if ( rising_edge( clk ) ) then
      if ( rst = '1' ) then
        itemInd <= 0; 
      else
        if ( fsmTopCur = idle ) then
          itemInd <= 0;
        elsif ( fsmTopCur = incInd ) then
          itemInd <= itemInd + 1;
        end if;      
      end if;
    end if;
  end process;
  
  -- Top FSM.
  process( clk ) is
  begin
    if ( rising_edge( clk ) ) then
      if ( rst = '1' ) then
        fsmTopCur <= idle;
      else
        fsmTopCur <= fsmTopNext;
      end if;
    end if;
  end process;
  
  process( fsmTopCur, doSwitch, fsmSingleValCur, locked, itemInd ) is
  begin
    case fsmTopCur is
      when idle =>
        if ( doSwitch = '1' ) then
          fsmTopNext <= setVal;
        else
          fsmTopNext <= idle;
        end if;
        
      when setVal =>
        fsmTopNext <= waitVal;
        
      when waitVal =>
        if ( fsmSingleValCur = idle ) then
          if ( itemInd = 13 ) then
            fsmTopNext <= waitLock;
          else
            fsmTopNext <= incInd;
          end if;
        else
          fsmTopNext <= waitVal;
        end if;
        
      when incInd =>
        fsmTopNext <= setVal;
      
      when waitLock =>
        if ( locked = '1' ) then
          fsmTopNext <= idle;
        else
          fsmTopNext <= waitLock;
        end if;

    end case;
  end process; 
  
  process( fsmTopCur, stateSel_int, itemInd ) is
  begin
    case fsmTopCur is
      when idle =>
        nextMask <= ( others => '-' );
        nextVal <= ( others => '-' );
        nextAddr <= ( others => '-' );
        setNewVal <= '0';
        rstMMCM <= '0'; 
      
      when setVal =>
        nextMask <= reconfROM( to_integer( unsigned( stateSel_int ) ) )( itemInd ).mask;
        nextVal <= reconfROM( to_integer( unsigned( stateSel_int ) ) )( itemInd ).data;
        nextAddr <= reconfROM( to_integer( unsigned( stateSel_int ) ) )( itemInd ).addr;
        rstMMCM <= '1';
        setNewVal <= '1';
        
      when waitVal =>
        nextMask <= reconfROM( to_integer( unsigned( stateSel_int ) ) )( itemInd ).mask;
        nextVal <= reconfROM( to_integer( unsigned( stateSel_int ) ) )( itemInd ).data;
        nextAddr <= reconfROM( to_integer( unsigned( stateSel_int ) ) )( itemInd ).addr;
        rstMMCM <= '1';
        setNewVal <= '0';
        
      when incInd =>
        nextMask <= reconfROM( to_integer( unsigned( stateSel_int ) ) )( itemInd ).mask;
        nextVal <= reconfROM( to_integer( unsigned( stateSel_int ) ) )( itemInd ).data;
        nextAddr <= reconfROM( to_integer( unsigned( stateSel_int ) ) )( itemInd ).addr;
        rstMMCM <= '1';
        setNewVal <= '0';
        
      when waitLock =>
        nextMask <= reconfROM( to_integer( unsigned( stateSel_int ) ) )( itemInd ).mask;
        nextVal <= reconfROM( to_integer( unsigned( stateSel_int ) ) )( itemInd ).data;
        nextAddr <= reconfROM( to_integer( unsigned( stateSel_int ) ) )( itemInd ).addr;
        rstMMCM <= '0';
        setNewVal <= '0';
        
    end case;
  end process;

  -- FSM for changing a single value.
  process( clk ) is
  begin
  
    if ( rising_edge( clk ) ) then
      if ( rst = '1' ) then
        fsmSingleValCur <= idle;
      else
        fsmSingleValCur <= fsmSingleValNext;
      end if;
    end if;
  end process;
  
  process( fsmSingleValCur, setNewVal, drdy ) is
  begin
    case fsmSingleValCur is
      when idle =>
        if ( setNewVal = '1' ) then
          fsmSingleValNext <= setDADDR;
        else
          fsmSingleValNext <= idle;
        end if;
      
      when setDADDR =>
        fsmSingleValNext <= waitDRDY0;
        
      when waitDRDY0 =>
        if ( drdy = '1' ) then
          fsmSingleValNext <= applyMask;
        else
          fsmSingleValNext <= waitDRDY0;
        end if;
        
      when applyMask =>
        fsmSingleValNext <= doWrite;
        
      when doWrite =>
        fsmSingleValNext <= waitDRDY1;
        
      when waitDRDY1 =>
        if ( drdy = '1' ) then
          fsmSingleValNext <= idle;
        else
          fsmSingleValNext <= waitDRDY1;
        end if;
        
      when others =>
        fsmSingleValNext <= idle;
    end case;
  end process;
  
  process( fsmSingleValCur, nextAddr, maskedVal ) is
  begin
    case fsmSingleValCur is
      when idle =>
        diSig <= ( others => '-' );
        dwe <= '0';
        den <= '0';
        daddr <= ( others => '-' );       
        
      when setDADDR =>
        diSig <= ( others => '-' );
        dwe <= '0';
        den <= '1';
        daddr <= nextAddr;
                
      when waitDRDY0 =>
        diSig <= ( others => '-' );
        dwe <= '0';
        den <= '0';
        daddr <= nextAddr;
        
      when applyMask =>
        diSig <= ( others => '-' );
        dwe <= '0';
        den <= '0';
        daddr <= nextAddr;
        
      when doWrite =>
        diSig <= maskedVal;
        dwe <= '1';
        den <= '1';
        daddr <= nextAddr;
        
      when waitDRDY1 =>
        diSig <= ( others => '-' );
        dwe <= '0';
        den <= '0';
        daddr <= nextAddr;        
    end case;
  
  end process;

end rtl;
