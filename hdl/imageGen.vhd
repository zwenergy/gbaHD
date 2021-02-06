-----------------------------------------------------------------------
-- Title: Image Generator
-- Author: zwenergy
-----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use IEEE.std_logic_misc.all;

entity imageGen is 
  port(
    pxlClk : in std_logic;
    rst : in std_logic;
    redPxlIn : in std_logic_vector( 7 downto 0 );
    greenPxlIn : in std_logic_vector( 7 downto 0 );
    bluePxlIn : in std_logic_vector( 7 downto 0 );
    sameLine : in std_logic;
    newFrameIn : in std_logic;
    audioLIn : in std_logic;
    audioRIn : in std_logic;
    
    nextLine : out std_logic;
    curPxl : out std_logic_vector( 7 downto 0 );
    
    redEnc : out std_logic_vector( 9 downto 0 );
    greenEnc : out std_logic_vector( 9 downto 0 );
    blueEnc : out std_logic_vector( 9 downto 0 )
  );
end imageGen;

architecture rtl of imageGen is
constant xMin : integer := 0;
constant xMax : integer := 1665;
constant yMin : integer := -25;
constant yMax : integer := 1000;
signal countX : integer range xMin to xMax;
signal countY : integer range yMin to yMax;
signal countXDel : integer range xMin to xMax;
signal countYDel : integer range yMin to yMax;
signal hSync : std_logic;
signal vSync : std_logic;
signal ctrl : std_logic_vector( 1 downto 0 );
signal draw : std_logic;

signal pxlCnt : integer range 0 to 239;

signal pxlCnt4 : integer range 0 to 3;
signal lineCnt4 : integer range 0 to 3;

signal redPxl : std_logic_vector( 7 downto 0 );
signal greenPxl : std_logic_vector( 7 downto 0 );
signal bluePxl : std_logic_vector( 7 downto 0 );

constant gbaVideoXStart : integer := 160;
constant gbaVideoYStart : integer := 40;

-- Signals to be encoded
signal redDat : std_logic_vector( 7 downto 0 );
signal greenDat : std_logic_vector( 7 downto 0 );
signal blueDat : std_logic_vector( 7 downto 0 );
signal borderRed, borderGreen, borderBlue : std_logic_vector( 7 downto 0 );

signal redDat4b, greenDat4b, blueDat4b : std_logic_vector( 7 downto 0 );

-- Output signals.
signal redTMDSEnc, greenTMDSEnc, blueTMDSEnc, redTERCEnc, greenTERCEnc, blueTERCEnc, 
       redNoEnc, greenNoEnc, blueNoEnc, redNoEnc_del, greenNoEnc_del,
       blueNoEnc_del : std_logic_vector( 9 downto 0 );

signal drawGBA : std_logic;

signal newFrameProcessed : std_logic;
signal newFrameInDel : std_logic;

-- ECC control.
signal eccNewPacket, eccEnable, eccHeaderEnable : std_logic;

-- Data related signals
type tSubpacket is array( 0 to 6 ) of std_logic_vector( 7 downto 0);
type tPacketheader is array( 0 to 2 ) of std_logic_vector( 7 downto 0);
signal ctl0, ctl1, ctl2, ctl3 : std_logic;
signal guard0, guard1, guard2 : std_logic_vector( 9 downto 0 );
signal dat0, dat1, dat2 : std_logic_vector( 3 downto 0 );
signal subpacket0, subpacket1, subpacket2, subpacket3 : tSubpacket;
signal packetheader : tPacketheader;
signal subpacket0Del, subpacket1Del, subpacket2Del, subpacket3Del, packetheaderDel : std_logic_vector( 7 downto 0 );
signal packetClkCnt : integer range 0 to 50;
signal newPacketByte : std_logic;
signal ecc0, ecc1, ecc2, ecc3, ecc4,
       ecc0_int, ecc1_int, ecc2_int, ecc3_int,
       ecc4_int : std_logic_vector( 7 downto 0 ); 

constant vfrontporch : integer := 3;
constant vsyncpxl : integer := 5;
constant vbackporch : integer := 20;
constant hfrontporch : integer := 64;
constant hsyncpxl : integer := 36;
constant ystart : integer := -( vsyncpxl + vbackporch );

constant maxHor : integer := 1539;
constant maxVer : integer := 911 + ystart; 

constant aviFrameHeader : tPacketHeader := ( 0 => "10000010", 1 => "00000010", 2 => "00001101" );
constant aviPacket0 : tSubpacket := ( 0 => "00010001", 1 => "00010000", 2 => "00101010", 3 => "00000100",
  4 => "00000000", 5 => "00000000", 6 => "00000000" );
constant aviLine : integer := 42;

-- Encoding-Type
type tStatus is ( TMDSENC, TERCENC, NOENC );
signal curEncType, curEncType_del : tStatus;

-- Data-related constants.
constant dataPreambleXPosStart : integer := 1280 + hfrontporch + hsyncpxl + 10;
constant dataXPosStart : integer := dataPreAmbleXPosStart + 8;
constant videoPreambleXPosStart : integer := maxHor - 9;--1530
constant videoGuardXPosStart : integer := videoPreambleXPosStart + 8;--1538

constant audioRegenHeader : tPacketheader := ( 0 => "00000001", 1 => "00000000", 2 => "00000000" );
constant audioRegenN : std_logic_vector( 19 downto 0 ) := std_logic_vector( to_unsigned( 6144, 20 ) );
signal audioRegenCTS : std_logic_vector( 19 downto 0 ) := std_logic_vector( to_unsigned( 79872, 20 ) );
signal ctsPacketSendCnt : unsigned( audioRegenN'length - 1 downto 0 );
signal sendCTS, sendCTSdone : std_logic;

signal dataPacketSending : std_logic;

-- Audio signals.
signal audioLOut : std_logic_vector( 15 downto 0 );
signal audioROut : std_logic_vector( 15 downto 0 );
signal audioValidOut : std_logic;
signal lastAudioLSample0, lastAudioRSample0 : std_logic_vector( 23 downto 0 );
signal lastAudioLSample1, lastAudioRSample1 : std_logic_vector( 23 downto 0 );
signal lastAudioLSample2, lastAudioRSample2 : std_logic_vector( 23 downto 0 );
signal lastAudioLSample3, lastAudioRSample3 : std_logic_vector( 23 downto 0 );
signal audioSamplesPresent : std_logic_vector( 3 downto 0 );
signal newAudio : std_logic;
signal sendingAudio : std_logic;
signal lastAudioProcessed : std_logic;
signal audioSampleCnt, audioSampleCnt1, audioSampleCnt2, audioSampleCnt3, audioSampleCnt4 : integer range 0 to 191;
signal prevADClk : std_logic;
signal sample128Clk : std_logic;

constant audioSampleFreq : real := 48.0;
constant clkFreq : real := 83745.07997655;
signal statusBits : std_logic_vector( 191 downto 0 );

begin

  statusBits( 39 downto 0 ) <= x"D202004004";
  statusBits( 191 downto 40 ) <= ( others => '0' );
  
  counterUpdate:process( pxlClk ) is
  begin
    if ( rising_edge( pxlClk ) ) then
      if ( rst = '1' ) then
          countX <= 0;
          countY <= -25;
          countXDel <= 0;
          countYDel <= -25;
          pxlCnt <= 0;
          pxlCnt4 <= 0;
          newFrameInDel <= '0';
          newFrameProcessed <= '0';
      else
        countXDel <= countX;
        countYDel <= countY;
        newFrameInDel <= newFrameIn;
        
        if ( newFrameIn = '1' and newFrameInDel = '0' ) then
          newFrameProcessed <= '0';
        end if;
        -- countX and countY
        if ( countX = maxHor ) then
          countX <= 0;
          if ( countY = maxVer ) then
            countY <= ystart;
          elsif ( newFrameIn = '1' and newFrameProcessed = '0' ) then
            -- We set it to a line close to the GBA video center, otherwise
            -- we would need a larger frame buffer.
            countY <= gbaVideoYStart;
            newFrameProcessed <= '1';
          else
            countY <= countY + 1;
          
          end if;
        else
          countX <= countX + 1;
        end if;
        
        -- PxlCnt
        if ( drawGBA = '0'  ) then
          pxlCnt4 <= 0;
          pxlCnt <= 0;
        else
          if ( pxlCnt4 = 3 ) then
            pxlCnt4 <= 0;
            pxlCnt <= pxlCnt + 1;
          else
            pxlCnt4 <= pxlCnt4 + 1;
          end if;
        end if;
        
        if ( countX = maxHor - 1 ) then
          if ( countY = maxVer or countY < 0 or ( newFrameIn = '1' and newFrameProcessed = '0' ) ) then
            lineCnt4 <= 0;
          elsif ( lineCnt4 = 3 ) then
            lineCnt4 <= 0;
          else
            lineCnt4 <= lineCnt4 + 1;
          end if;
        end if;
      end if;
    end if;
  end process;
  
  -- Data process.
  dataProc : process( pxlClk ) is
  begin
    if ( rising_edge( pxlClk ) ) then
      if ( rst = '1' ) then
        ctl0 <= '0';
        ctl1 <= '0';
        ctl2 <= '0';
        ctl3 <= '0';
        guard0 <= ( others => '0' );
        guard1 <= ( others => '0' );
        guard2 <= ( others => '0' );
        subpacket0 <= ( others => ( others => '0' ) );
        subpacket1 <= ( others => ( others => '0' ) );
        subpacket2 <= ( others => ( others => '0' ) );
        subpacket3 <= ( others => ( others => '0' ) );
        packetheader <= ( others => ( others => '0' ) );
        packetClkCnt <= 0;
        newPacketByte <= '0';
        curEncType <= TMDSENC;
        ecc0 <= ( others => '0' );
        ecc1 <= ( others => '0' );
        ecc2 <= ( others => '0' );
        ecc3 <= ( others => '0' );
        ecc4 <= ( others => '0' );
        dataPacketSending <= '0';
        lastAudioProcessed <= '0';
        eccHeaderEnable <= '0';
        eccEnable <= '0';
        audioSampleCnt <= 0;
        sendCTSdone <= '0';
      else
        -- Send the audio reconstruction paket.
        if ( sendCTS = '1' and countX = dataPreambleXPosStart - 1 ) then
          -- Set the packets and header.
          subpacket0( 0 ) <= "00000000";
          subpacket0( 1 ) <= "0000" & audioRegenCTS( 19 downto 16 );
          subpacket0( 2 ) <= audioRegenCTS( 15 downto 8 );
          subpacket0( 3 ) <= audioRegenCTS( 7 downto 0 );
          subpacket0( 4 ) <= "0000" & audioRegenN( 19 downto 16 );
          subpacket0( 5 ) <= audioRegenN( 15 downto 8 );
          subpacket0( 6 ) <= audioRegenN( 7 downto 0 );
          
          subpacket1( 0 ) <= "00000000";
          subpacket1( 1 ) <= "0000" & audioRegenCTS( 19 downto 16 );
          subpacket1( 2 ) <= audioRegenCTS( 15 downto 8 );
          subpacket1( 3 ) <= audioRegenCTS( 7 downto 0 );
          subpacket1( 4 ) <= "0000" & audioRegenN( 19 downto 16 );
          subpacket1( 5 ) <= audioRegenN( 15 downto 8 );
          subpacket1( 6 ) <= audioRegenN( 7 downto 0 );
          
          subpacket2( 0 ) <= "00000000";
          subpacket2( 1 ) <= "0000" & audioRegenCTS( 19 downto 16 );
          subpacket2( 2 ) <= audioRegenCTS( 15 downto 8 );
          subpacket2( 3 ) <= audioRegenCTS( 7 downto 0 );
          subpacket2( 4 ) <= "0000" & audioRegenN( 19 downto 16 );
          subpacket2( 5 ) <= audioRegenN( 15 downto 8 );
          subpacket2( 6 ) <= audioRegenN( 7 downto 0 );
          
          subpacket3( 0 ) <= "00000000";
          subpacket3( 1 ) <= "0000" & audioRegenCTS( 19 downto 16 );
          subpacket3( 2 ) <= audioRegenCTS( 15 downto 8 );
          subpacket3( 3 ) <= audioRegenCTS( 7 downto 0 );
          subpacket3( 4 ) <= "0000" & audioRegenN( 19 downto 16 );
          subpacket3( 5 ) <= audioRegenN( 15 downto 8 );
          subpacket3( 6 ) <= audioRegenN( 7 downto 0 );

          packetheader <= audioRegenHeader;
          
          curEncType <= TMDSENC;
          dataPacketSending <= '1';
          lastAudioProcessed <= '0';
          sendCTSdone <= '1';
          
        -- Send an AVI frame.
--        elsif ( countX = dataPreambleXPosStart - 1 and countY = aviLine ) then
--          subpacket0 <= aviPacket0;
--          subpacket1 <= ( others => ( others => '0' ) );
--          subpacket2 <= ( others => ( others => '0' ) );
--          subpacket3 <= ( others => ( others => '0' ) );
--          packetHeader <= aviFrameHeader;
          
--          curEncType <= TMDSENC;
--          dataPacketSending <= '1';
--          lastAudioProcessed <= '0';
--          sendCTSdone <= '0';
          
        -- Send an audio packet.
        elsif ( countX = dataPreambleXPosStart - 1 and newAudio = '1' ) then
          -- Set the packets and header.
          subpacket0( 0 ) <= lastAudioLSample0( 7 downto 0 );
          subpacket0( 1 ) <= lastAudioLSample0( 15 downto 8 );
          subpacket0( 2 ) <= lastAudioLSample0( 23 downto 16 );
          subpacket0( 3 ) <= lastAudioRSample0( 7 downto 0 );
          subpacket0( 4 ) <= lastAudioRSample0( 15 downto 8 );
          subpacket0( 5 ) <= lastAudioRSample0( 23 downto 16 );
          subpacket0( 6 )( 7 ) <= xor_reduce( lastAudioRSample0 ) xor '1' xor statusBits( audioSampleCnt );
          subpacket0( 6 )( 6 downto 4 ) <= statusBits( audioSampleCnt ) & "01";
          subpacket0( 6 )( 3 ) <= xor_reduce( lastAudioLSample0 ) xor '1' xor statusBits( audioSampleCnt );
          subpacket0( 6 )( 2 downto 0 ) <= statusBits( audioSampleCnt ) & "01";
          
          if ( audioSamplesPresent( 1 ) = '1' ) then
            subpacket1( 0 ) <= lastAudioLSample1( 7 downto 0 );
            subpacket1( 1 ) <= lastAudioLSample1( 15 downto 8 );
            subpacket1( 2 ) <= lastAudioLSample1( 23 downto 16 );
            subpacket1( 3 ) <= lastAudioRSample1( 7 downto 0 );
            subpacket1( 4 ) <= lastAudioRSample1( 15 downto 8 );
            subpacket1( 5 ) <= lastAudioRSample1( 23 downto 16 );
            subpacket1( 6 )( 7 ) <= xor_reduce( lastAudioRSample1 ) xor '1' xor statusBits( audioSampleCnt1 );
            subpacket1( 6 )( 6 downto 4 ) <= statusBits( audioSampleCnt1 ) & "01";
            subpacket1( 6 )( 3 ) <= xor_reduce( lastAudioLSample1 ) xor '1' xor statusBits( audioSampleCnt1 );
            subpacket1( 6 )( 2 downto 0 ) <= statusBits( audioSampleCnt1 ) & "01";
          else
            subpacket1 <= ( others => ( others => '0' ) );
          end if;
          
          if ( audioSamplesPresent( 2 ) = '1' ) then
            subpacket2( 0 ) <= lastAudioLSample2( 7 downto 0 );
            subpacket2( 1 ) <= lastAudioLSample2( 15 downto 8 );
            subpacket2( 2 ) <= lastAudioLSample2( 23 downto 16 );
            subpacket2( 3 ) <= lastAudioRSample2( 7 downto 0 );
            subpacket2( 4 ) <= lastAudioRSample2( 15 downto 8 );
            subpacket2( 5 ) <= lastAudioRSample2( 23 downto 16 );
            subpacket2( 6 )( 7 ) <= xor_reduce( lastAudioRSample2 ) xor '1' xor statusBits( audioSampleCnt2 );
            subpacket2( 6 )( 6 downto 4 ) <= statusBits( audioSampleCnt2 ) & "01";
            subpacket2( 6 )( 3 ) <= xor_reduce( lastAudioLSample2 ) xor '1' xor statusBits( audioSampleCnt2 );
            subpacket2( 6 )( 2 downto 0 ) <= statusBits( audioSampleCnt2 ) & "01";
          else
            subpacket2 <= ( others => ( others => '0' ) );
          end if;
          
          if ( audioSamplesPresent( 3 ) = '1' ) then
            subpacket3( 0 ) <= lastAudioLSample3( 7 downto 0 );
            subpacket3( 1 ) <= lastAudioLSample3( 15 downto 8 );
            subpacket3( 2 ) <= lastAudioLSample3( 23 downto 16 );
            subpacket3( 3 ) <= lastAudioRSample3( 7 downto 0 );
            subpacket3( 4 ) <= lastAudioRSample3( 15 downto 8 );
            subpacket3( 5 ) <= lastAudioRSample3( 23 downto 16 );
            subpacket3( 6 )( 7 ) <= xor_reduce( lastAudioRSample3 ) xor '1' xor statusBits( audioSampleCnt3 );
            subpacket3( 6 )( 6 downto 4 ) <= statusBits( audioSampleCnt3 ) & "01";
            subpacket3( 6 )( 3 ) <= xor_reduce( lastAudioLSample3 ) xor '1' xor statusBits( audioSampleCnt3 );
            subpacket3( 6 )( 2 downto 0 ) <= statusBits( audioSampleCnt3 ) & "01";
          else
            subpacket3 <= ( others => ( others => '0' ) );
          end if;
          

          packetheader( 0 ) <= "00000010";
          packetheader( 1 ) <= "0000" & audioSamplesPresent;
          
          if ( audioSampleCnt = 0 ) then
            packetheader( 2 )( 4 ) <= '1';
          else
            packetheader( 2 )( 4 ) <= '0';
          end if;
          
          if ( audioSampleCnt1 = 0 ) then
            packetheader( 2 )( 5 ) <= '1';
          else
            packetheader( 2 )( 5 ) <= '0';
          end if;
          
          if ( audioSampleCnt2 = 0 ) then
            packetheader( 2 )( 6 ) <= '1';
          else
            packetheader( 2 )( 6 ) <= '0';
          end if;
          
          if ( audioSampleCnt3 = 0 ) then
            packetheader( 2 )( 7 ) <= '1';
          else
            packetheader( 2 )( 7 ) <= '0';
          end if;
          
          packetheader( 2 )( 3 downto 0 ) <= "0000";

          curEncType <= TMDSENC;
          dataPacketSending <= '1';
          lastAudioProcessed <= '1';
          sendCTSdone <= '0';
          
          case audioSamplesPresent is 
            when "0001" => audioSampleCnt <= audioSampleCnt1;
            when "0011" => audioSampleCnt <= audioSampleCnt2;
            when "0111" => audioSampleCnt <= audioSampleCnt3;
            when "1111" => audioSampleCnt <= audioSampleCnt4;
            -- This should never happen
            when others => audioSampleCnt <= audioSampleCnt1;
          end case;
          
        elsif ( dataPacketSending = '1' and countX >= dataPreambleXPosStart and countX < dataXPosStart ) then
          -- Send data island preamble.
          ctl0 <= '1';
          ctl1 <= '0';
          ctl2 <= '1';
          ctl3 <= '0';
          guard0 <= ( others => '0' );
          guard1 <= ( others => '0' );
          guard2 <= ( others => '0' );
          dat0 <= "11" & vsync & hsync;
          
          curEncType <= TMDSENC;
          lastAudioProcessed <= '0';
          sendCTSdone <= '0';

        elsif( dataPacketSending = '1' and ( countX = dataXPosStart or countX = dataXPosStart + 1 or
                                packetClkCnt = 32 or packetClkCnt = 33 )  ) then
          -- Send the guard band.
          ctl0 <= '0';
          ctl1 <= '0';
          ctl2 <= '0';
          ctl3 <= '0';
          
          if ( vsync = '0' and hsync = '0') then
            guard0 <= "1010001110";
          elsif ( vsync = '1' and hsync = '0') then
            guard0 <= "0101100011";
          elsif ( vsync = '0' and hsync = '1') then
            guard0 <= "1001110001";
          else
            guard0 <= "1011000011";
          end if;

          guard1 <= "0100110011";
          guard2 <= "0100110011";
          
          curEncType <= NOENC;
          
          if ( countX = dataXPosStart or countX = dataXPosStart + 1 ) then
            packetClkCnt <= 0;   
          else
            packetClkCnt <= packetClkCnt + 1;
          end if;   

        elsif( dataPacketSending = '1' and countX >= dataXPosStart + 2 and packetClkCnt < 28 ) then
          -- Send the packets.
          packetClkCnt <= packetClkCnt + 1;
          ctl0 <= '0';
          ctl1 <= '0';
          ctl2 <= '0';
          ctl3 <= '0';
          dat1 <= subpacket3( 0 )( 0 ) & subpacket2( 0 )( 0 ) & subpacket1( 0 )( 0 ) & subpacket0( 0 )( 0 ) ;
          dat2 <= subpacket3( 0 )( 1 ) & subpacket2( 0 )( 1 ) & subpacket1( 0 )( 1 ) & subpacket0( 0 )( 1 ) ;
          
          curEncType <= TERCENC;
          lastAudioProcessed <= '0';
          sendCTSdone <= '0';
          
          -- Shift.
          for I in 0 to 6 loop
            subpacket0( I )( 5 downto 0 ) <= subpacket0( I )( 7 downto 2 );
            subpacket1( I )( 5 downto 0 ) <= subpacket1( I )( 7 downto 2 );
            subpacket2( I )( 5 downto 0 ) <= subpacket2( I )( 7 downto 2 );
            subpacket3( I )( 5 downto 0 ) <= subpacket3( I )( 7 downto 2 );
            
            if( I = 6 ) then
              subpacket0( I )( 7 downto 6 ) <= "00";
              subpacket1( I )( 7 downto 6 ) <= "00";
              subpacket2( I )( 7 downto 6 ) <= "00";
              subpacket3( I )( 7 downto 6 ) <= "00";
            else
              subpacket0( I )( 7 downto 6 ) <= subpacket0( I + 1 )( 1 downto 0 );
              subpacket1( I )( 7 downto 6 ) <= subpacket1( I + 1 )( 1 downto 0 );
              subpacket2( I )( 7 downto 6 ) <= subpacket2( I + 1 )( 1 downto 0 );
              subpacket3( I )( 7 downto 6 ) <= subpacket3( I + 1 )( 1 downto 0 );
            end if;
          end loop;
          
          -- ECC.
          if ( packetClkCnt = 0 or packetClkCnt = 4 or packetClkCnt = 8 or
               packetClkCnt = 12 or packetClkCnt = 16 or packetClkCnt = 20 or
               packetClkCnt = 24 ) then
            eccEnable <= '1';
          else
            eccEnable <= '0';
          end if;
          
          if ( packetClkCnt = 0 or packetClkCnt = 8 or packetClkCnt = 16 ) then
            eccHeaderEnable <= '1';
          else
            eccHeaderEnable <= '0';
          end if;
          
          -- Data ECC
          if ( packetClkCnt = 26 ) then
            ecc0 <= ecc0_int;
            ecc1 <= ecc1_int;
            ecc2 <= ecc2_int;
            ecc3 <= ecc3_int;
          end if;
          
          -- Header ECC.
          if ( packetClkCnt = 18 ) then
            ecc4 <= ecc4_int;
          end if;
          
          if ( packetClkCnt = 0 ) then
            eccNewPacket <= '1';
          else
            eccNewPacket <= '0';
          end if;
          
          if ( packetClkCnt < 24 ) then
            dat0( 0 ) <= hsync;
            dat0( 1 ) <= vsync;
            dat0( 2 ) <= packetheader( 0 )( 0 );
            
            --  First bit of the packet.
            if ( packetClkCnt = 0 ) then
              dat0( 3 ) <= '0';
            else
              dat0( 3 ) <= '1';
            end if;
            
            -- Shift.
            packetheader( 0 )( 6 downto 0 ) <= packetheader( 0 )( 7 downto 1 );
            packetheader( 1 )( 6 downto 0 ) <= packetheader( 1 )( 7 downto 1 );
            packetheader( 2 )( 6 downto 0 ) <= packetheader( 2 )( 7 downto 1 );
            
            packetheader( 0 )( 7 ) <= packetheader( 1 )( 0 );
            packetheader( 1 )( 7 ) <= packetheader( 2 )( 0 );
            packetheader( 2 )( 7 ) <= '0';
          elsif ( packetClkCnt >= 24 and packetClkCnt < 32 ) then
            dat0( 0 ) <= hsync;
            dat0( 1 ) <= vsync;
            dat0( 2 ) <= ecc4( 0 );
            dat0( 3 ) <= '1';
            
            ecc4( 6 downto 0 ) <= ecc4( 7 downto 1 );
            ecc4( 7 ) <= '0';
          else
            dat0 <= ( others => '0' );
          end if;
                    
        elsif( dataPacketSending = '1' and packetClkCnt >= 28 and packetClkCnt < 32 ) then
          packetClkCnt <= packetClkCnt + 1;
          
          dat1 <= ecc3( 0 ) & ecc2( 0 ) & ecc1( 0 ) & ecc0( 0 ) ;
          dat2 <= ecc3( 1 ) & ecc2( 1 ) & ecc1( 1 ) & ecc0( 1 ) ;
          
          dat0( 0 ) <= hsync;
          dat0( 1 ) <= vsync;
          dat0( 2 ) <= ecc4( 0 );
          dat0( 3 ) <= '1';
          
          ecc4( 6 downto 0 ) <= ecc4( 7 downto 1 );
          ecc4( 7 ) <= '0';
          
          ecc3( 5 downto 0 ) <= ecc3( 7 downto 2 );
          ecc3( 7 downto 6 ) <= "00";
          
          ecc2( 5 downto 0 ) <= ecc2( 7 downto 2 );
          ecc2( 7 downto 6 ) <= "00";
          
          ecc1( 5 downto 0 ) <= ecc1( 7 downto 2 );
          ecc1( 7 downto 6 ) <= "00";
          
          ecc0( 5 downto 0 ) <= ecc0( 7 downto 2 );
          ecc0( 7 downto 6 ) <= "00";
          
          curEncType <= TERCENC;
          lastAudioProcessed <= '0';
          sendCTSdone <= '0';
          
        elsif ( ( countY >= -1 and countY <= 718 ) and countX >= videoPreambleXPosStart and countX < videoGuardXPosStart ) then
          -- Send video preamble.
          ctl0 <= '1';
          ctl1 <= '0';
          ctl2 <= '0';
          ctl3 <= '0';
          guard0 <= ( others => '0' );
          guard1 <= ( others => '0' );
          guard2 <= ( others => '0' );
          dat0 <= "11" & vsync & hsync;
          
          curEncType <= TMDSENC;
          dataPacketSending <= '0';
          lastAudioProcessed <= '0';
          
        elsif( ( countY >= -1 and countY <= 718 ) and countX >= videoGuardXPosStart  ) then
          -- Send the video guard band.
          ctl0 <= '0';
          ctl1 <= '0';
          ctl2 <= '0';
          ctl3 <= '0';
          guard0 <= "1011001100";
          guard1 <= "0100110011";
          guard2 <= "1011001100";
          
          curEncType <= NOENC;
          dataPacketSending <= '0';
          lastAudioProcessed <= '0';
          sendCTSdone <= '0';
 
        else
          ctl0 <= '0';
          ctl1 <= '0';
          ctl2 <= '0';
          ctl3 <= '0';
          guard0 <= ( others => '0' );
          guard1 <= ( others => '0' );
          guard2 <= ( others => '0' );
          curEncType <= TMDSENC;
          dataPacketSending <= '0';
          lastAudioProcessed <= '0';
          sendCTSdone <= '0';
        end if;
      end if;
    end if;  
  end process;
  
  -- Small helper counters.
  process( audioSampleCnt ) is
  variable tmpCnt : integer range 0 to 191;
  begin
    tmpCnt := audioSampleCnt;
    if ( tmpCnt < 191 ) then
      tmpCnt := tmpCnt + 1;
    else
      tmpCnt := 0;
    end if;
    
    audioSampleCnt1 <= tmpCnt;
    
    if ( tmpCnt < 191 ) then
      tmpCnt := tmpCnt + 1;
    else
      tmpCnt := 0;
    end if;
    
    audioSampleCnt2 <= tmpCnt;
    
    if ( tmpCnt < 191 ) then
      tmpCnt := tmpCnt + 1;
    else
      tmpCnt := 0;
    end if;
    
    audioSampleCnt3 <= tmpCnt;
    
    if ( tmpCnt < 191 ) then
      tmpCnt := tmpCnt + 1;
    else
      tmpCnt := 0;
    end if;
    
    audioSampleCnt4 <= tmpCnt;
    
  end process;
  
  -- Counter when to send a CTS packet.
  process( pxlClk ) is
  begin
    if ( rising_edge( pxlClk ) ) then
      if ( rst = '1' ) then
        ctsPacketSendCnt <= (others => '0' );
        sendCTS <= '1';
        prevADClk <= '0';
      else
        prevADClk <= sample128Clk;
        
        if ( sendCTSdone = '1' ) then
            sendCTS <= '0';
        end if;
        
        if ( prevADClk = '0' and sample128Clk = '1' ) then    
          ctsPacketSendCnt <= ctsPacketSendCnt + 1;
          
          if ( ctsPacketSendCnt = unsigned( audioRegenN ) ) then 
            ctsPacketSendCnt <= (others => '0' );
            sendCTS <= '1';
          end if;
          
        end if;
      end if;
    end if;
  end process;
  
  -- Just a simple delaying process.
  delayProc : process( pxlClk ) is
  begin
    if rising_edge( pxlClk ) then
      if ( rst = '1' ) then
        curEncType_del <= TMDSENC;
        redNoEnc_del <= ( others => '0' );
        blueNoEnc_del <= ( others => '0' );
        greenNoEnc_del <= ( others => '0' );
        subpacket0Del <= ( others => '0' );
        subpacket1Del <= ( others => '0' );
        subpacket2Del <= ( others => '0' );
        subpacket3Del <= ( others => '0' );
        packetheaderDel <= ( others => '0' );
      else
        curEncType_del <= curEncType;
        redNoEnc_del <= redNoEnc;
        blueNoEnc_del <= blueNoEnc;
        greenNoEnc_del <= greenNoEnc;
        subpacket0Del <= subpacket0( 0 );
        subpacket1Del <= subpacket1( 0 );
        subpacket2Del <= subpacket2( 0 );
        subpacket3Del <= subpacket3( 0 );
        packetheaderDel <= packetheader( 0 );
      end if;
    end if;
  end process;
  
  redNoEnc <= guard2;
  blueNoEnc <= guard0;
  greenNoEnc <= guard1;
  
  curPxl <= std_logic_vector( to_unsigned( pxlCnt, curPxl'length ) );
  nextLine <= '0' when ( countXDel /= maxHor - 2 ) else
              '0' when ( sameLine = '1' ) else
              '0' when ( newFrameIn = '1' and newFrameProcessed = '0' ) else
              '0' when ( countY < 0 ) else
              '1' when ( lineCnt4 = 3 ) else
              '0';
  drawGBA <= '1' when ( countX >= gbaVideoXStart and countX < ( gbaVideoXStart + 960 ) and 
                      ( countY >= gbaVideoYStart and countY < ( gbaVideoYStart + 640 ) ) ) else '0';
  
  hSync <= '1' when ( countXDel >= 1280 + hfrontporch ) and ( countXDel < 1280 + hfrontporch + hsyncpxl ) else '0';
  vSync <= '1' when ( countYDel < -vbackporch) else '0';
  draw <= '1' when ( countXDel < 1280 ) and ( countYDel >= 0 and countYDel < 720 ) else '0';
  
  ctrl( 1 ) <= vSync;
  ctrl( 0 ) <= hSync;
  
  redDat <= redPxl when ( drawGBA ='1' ) else borderRed;
  greenDat <= greenPxl when ( drawGBA ='1' ) else borderGreen;
  blueDat <= bluePxl when ( drawGBA ='1' ) else borderBlue;
  
  --Capture the next pixel.
  getPixel:process( pxlClk ) is
  begin
    if ( rising_edge( pxlClk ) ) then
      if ( rst = '1' ) then
        redPxl <= ( others => '0' );
        greenPxl <= ( others => '0' );
        bluePxl <= ( others => '0' );
      else
        redPxl <= redPxlIn;
        greenPxl <= greenPxlIn;
        bluePxl <= bluePxlIn;
      end if;
    end if;
  end process;
    
    -- Encode.
  redTMDS : entity work.tmdsEncoder( rtl )
    port map( 
      dispEN => draw,
      ctrl(1) => ctl3,
      ctrl(0) => ctl2,
      datIn => redDat,
      clk => pxlClk,
      rst => rst,
      datOut => redTMDSEnc 
    );
    
    greenTMDS : entity work.tmdsEncoder( rtl )
    port map( 
      dispEN => draw,
      ctrl(1) => ctl1,
      ctrl(0) => ctl0,
      datIn => greenDat,
      clk => pxlClk,
      rst => rst,
      datOut => greenTMDSEnc 
    );
    
    blueTMDS : entity work.tmdsEncoder( rtl )
    port map( 
      dispEN => draw,
      ctrl => ctrl,
      datIn => blueDat,
      clk => pxlClk,
      rst => rst,
      datOut => blueTMDSEnc 
    );
    
    blueTERC : entity work.terc4Encoder( rtl )
    port map(
      datIn => dat0,
      clk => pxlClk,
      rst => rst,
      datOut => blueTERCEnc
    );
    
    greenTERC : entity work.terc4Encoder( rtl )
    port map(
      datIn => dat1,
      clk => pxlClk,
      rst => rst,
      datOut => greenTERCEnc
    );
    
    redTERC : entity work.terc4Encoder( rtl )
    port map(
      datIn => dat2,
      clk => pxlClk,
      rst => rst,
      datOut => redTERCEnc
    );
    
    -- Select the outgoing signals.
    redEnc <= redTMDSEnc when curEncType_del = TMDSENC else
              redTERCEnc when curEncType_del = TERCENC else
              redNoEnc_del;
              
    blueEnc <= blueTMDSEnc when curEncType_del = TMDSENC else
               blueTERCEnc when curEncType_del = TERCENC else
               blueNoEnc_del;
               
    greenEnc <= greenTMDSEnc when curEncType_del = TMDSENC else
                greenTERCEnc when curEncType_del = TERCENC else
                greenNoEnc_del;
    
    -- ECC
    ecc0Gen : entity work.ecc( rtl )
    port map(
      datIn => subpacket0Del,
      newPacket => eccNewPacket,
      enable => eccEnable,
      clk => pxlClk,
      rst => rst,
      datOut => ecc0_int
    );
    
    ecc1Gen : entity work.ecc( rtl )
    port map(
      datIn => subpacket1Del,
      newPacket => eccNewPacket,
      enable => eccEnable,
      clk => pxlClk,
      rst => rst,
      datOut => ecc1_int
    );
    
    ecc2Gen : entity work.ecc( rtl )
    port map(
      datIn => subpacket2Del,
      newPacket => eccNewPacket,
      enable => eccEnable,
      clk => pxlClk,
      rst => rst,
      datOut => ecc2_int
    );
    
    ecc3Gen : entity work.ecc( rtl )
    port map(
      datIn => subpacket3Del,
      newPacket => eccNewPacket,
      enable => eccEnable,
      clk => pxlClk,
      rst => rst,
      datOut => ecc3_int
    );
    
    ecc4Gen : entity work.ecc( rtl )
    port map(
      datIn => packetheaderDel,
      newPacket => eccNewPacket,
      enable => eccHeaderEnable,
      clk => pxlClk,
      rst => rst,
      datOut => ecc4_int
    );
    
    -- Audio.
    pwm2pcmInst: entity work.pwm2pcm( rtl )
    generic map(
      clkFreq => clkFreq,
      sampleFreq => audioSampleFreq
    )
    port map(
      pwmInL => audioLIn,
      pwmInR => audioRIn,
      clk => pxlClk,
      rst => rst,
      sample128ClkOut => sample128Clk,
      datOutL => audioLOut,
      datOutR => audioROut,
      validOut => audioValidOut
    );
 
    -- Check for new audio packets.
    process( pxlClk ) is 
    begin
      if ( rising_edge( pxlClk ) ) then
        if ( rst = '1' ) then
          lastAudioLSample0 <= ( others => '0' );
          lastAudioLSample1 <= ( others => '0' );
          lastAudioLSample2 <= ( others => '0' );
          lastAudioLSample3 <= ( others => '0' );
          
          lastAudioRSample0 <= ( others => '0' );
          lastAudioRSample1 <= ( others => '0' );
          lastAudioRSample2 <= ( others => '0' );
          lastAudioRSample3 <= ( others => '0' );
          
          audioSamplesPresent <= ( others => '0' );
          newAudio <= '0';
        else 
          if ( lastAudioProcessed = '1' ) then
            newAudio <= '0';
            lastAudioLSample0 <= ( others => '0' );
            lastAudioLSample1 <= ( others => '0' );
            lastAudioLSample2 <= ( others => '0' );
            lastAudioLSample3 <= ( others => '0' );
            
            lastAudioRSample0 <= ( others => '0' );
            lastAudioRSample1 <= ( others => '0' );
            lastAudioRSample2 <= ( others => '0' );
            lastAudioRSample3 <= ( others => '0' );
            
            audioSamplesPresent <= ( others => '0' );
          end if;
          
          if ( audioValidOut = '1' ) then
            newAudio <= '1';
            lastAudioLSample0( 23 downto 0 ) <= audioLOut & "00000000";
            lastAudioLSample1 <= lastAudioLSample0;
            lastAudioLSample2 <= lastAudioLSample1;
            lastAudioLSample3 <= lastAudioLSample2;
            
            lastAudioRSample0( 23 downto 0 ) <= audioROut & "00000000";
            lastAudioRSample1 <= lastAudioRSample0;
            lastAudioRSample2 <= lastAudioRSample1;
            lastAudioRSample3 <= lastAudioRSample2;
            
            audioSamplesPresent( 0 ) <= '1';
            audioSamplesPresent( 3 downto 1 ) <= audioSamplesPresent( 2 downto 0 );
          end if;
        end if;
      end if;
    end process;
    
  -- Border generation.
  border : entity work.borderGen( rtl )
  generic map(
    xMin => xMin,
    xMax => xMax,
    yMin => yMin,
    yMax => yMax
  )
  port map(
    x => countX,
    y => countY,
    r => borderRed,
    g => borderGreen,
    b => borderBlue
  );

end rtl;