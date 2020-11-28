-----------------------------------------------------------------------
-- Title: Image Generator
-- Author: zwenergy
-----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity imageGen is 
  port(
    pxlClk : in std_logic;
    rst : in std_logic;
    redPxlIn : in std_logic_vector( 7 downto 0 );
    greenPxlIn : in std_logic_vector( 7 downto 0 );
    bluePxlIn : in std_logic_vector( 7 downto 0 );
    sameLine : in std_logic;
    newFrameIn : in std_logic;
    
    nextLine : out std_logic;
    curPxl : out std_logic_vector( 7 downto 0 );
    
    redEnc : out std_logic_vector( 9 downto 0 );
    greenEnc : out std_logic_vector( 9 downto 0 );
    blueEnc : out std_logic_vector( 9 downto 0 )    
  );
end imageGen;

architecture rtl of imageGen is
signal countX : integer range 0 to 1665;
signal countY : integer range -25 to 1000;
signal countXDel : integer range 0 to 1665;
signal countYDel : integer range -25 to 1000;
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

-- Signals to be encoded
signal redDat : std_logic_vector( 7 downto 0 );
signal greenDat : std_logic_vector( 7 downto 0 );
signal blueDat : std_logic_vector( 7 downto 0 );

signal redDat4b, greenDat4b, blueDat4b : std_logic_vector( 7 downto 0 );

-- Output signals.
signal redTMDSEnc, greenTMDSEnc, blueTMDSEnc, redTERCEnc, greenTERCEnc, blueTERCEnc, 
       redNoEnc, greenNoEnc, blueNoEnc, redNoEnc_del, greenNoEnc_del,
       blueNoEnc_del : std_logic_vector( 9 downto 0 );

signal drawGBA : std_logic;

signal newFrameProcessed : std_logic;
signal newFrameInDel : std_logic;

-- ECC control.
signal eccNewPacket, eccEnable : std_logic;

-- Data related signals
type tSubpacket is array( 0 to 6 ) of std_logic_vector( 7 downto 0);
type tPacketheader is array( 0 to 2 ) of std_logic_vector( 7 downto 0);
signal ctl0, ctl1, ctl2, ctl3 : std_logic;
signal guard0, guard1, guard2 : std_logic_vector( 9 downto 0 );
signal dat0, dat1, dat2 : std_logic_vector( 3 downto 0 );
signal subpacket0, subpacket1, subpacket2, subpacket3 : tSubpacket;
signal packetheader : tPacketheader;
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

constant maxHor : integer := 1539;
constant maxVer : integer := 911;

-- Encoding-Type
type tStatus is ( TMDSENC, TERCENC, NOENC );
signal curEncType, curEncType_del : tStatus;

-- Data-related constants.
constant dataPreambleXPosStart : integer := 1280 + hfrontporch + hsyncpxl + 10;
constant dataXPosStart : integer := dataPreAmbleXPosStart + 8;
constant videoPreambleXPosStart : integer := maxHor - 9;--1530
constant videoGuardXPosStart : integer := videoPreambleXPosStart + 8;--1538

begin
  
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
            countY <= -25;
          elsif ( newFrameIn = '1' and newFrameProcessed = '0' ) then
            newFrameProcessed <= '1';
            countY <= -25;
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
      else
        if ( countY = 2 and countX = dataPreambleXPosStart - 1 ) then
          -- Set the packets and header.
          subpacket0 <= ( others => ( others => '0' ) );
          subpacket1 <= ( others => ( others => '0' ) );
          subpacket2 <= ( others => ( others => '0' ) );
          subpacket3 <= ( others => ( others => '0' ) );
          packetheader <= ( others => ( others => '0' ) );
          
          curEncType <= TMDSENC;
          
        -- Send the audio reconstruction paket at the 2nd active line.
        elsif ( countY = 2 and countX >= dataPreambleXPosStart and countX < dataXPosStart ) then
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

        elsif( countY = 2 and ( countX = dataXPosStart or countX = dataXPosStart + 1 or
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
          --dat0 <= "11" & vsync & hsync;
          
          curEncType <= NOENC;
          
          if ( countX = dataXPosStart or countX = dataXPosStart + 1 ) then
            packetClkCnt <= 0;   
          else
            packetClkCnt <= packetClkCnt + 1;
          end if;   

        --elsif( countY = 2 and countXDel = dataXPosStart + 3 and packetClkCnt < 28 ) then
        elsif( countY = 2 and countX >= dataXPosStart + 2 and packetClkCnt < 28 ) then
          -- Send the packets.
          packetClkCnt <= packetClkCnt + 1;
          ctl0 <= '0';
          ctl1 <= '0';
          ctl2 <= '0';
          ctl3 <= '0';
          dat1 <= subpacket3( 0 )( 0 ) & subpacket2( 0 )( 0 ) & subpacket1( 0 )( 0 ) & subpacket0( 0 )( 0 ) ;
          dat2 <= subpacket3( 0 )( 1 ) & subpacket2( 0 )( 1 ) & subpacket1( 0 )( 1 ) & subpacket0( 0 )( 1 ) ;
          
          curEncType <= TERCENC;
          
          -- Shift.
          for I in 0 to 6 loop
            subpacket0( I )( 5 downto 0 ) <= subpacket0( I )( 7 downto 2 );
            subpacket1( I )( 5 downto 0 ) <= subpacket1( I )( 7 downto 2 );
            subpacket2( I )( 5 downto 0 ) <= subpacket2( I )( 7 downto 2 );
            
            if( I = 6 ) then
              subpacket0( I )( 7 downto 6 ) <= "00";
              subpacket1( I )( 7 downto 6 ) <= "00";
              subpacket2( I )( 7 downto 6 ) <= "00";
            else
              subpacket0( I )( 7 downto 6 ) <= subpacket0( I + 1 )( 1 downto 0 );
              subpacket1( I )( 7 downto 6 ) <= subpacket1( I + 1 )( 1 downto 0 );
              subpacket2( I )( 7 downto 6 ) <= subpacket2( I + 1 )( 1 downto 0 );
            end if;
          end loop;
          
          -- ECC.
          if ( packetClkCnt = 0 or packetClkCnt = 4 or packetClkCnt = 8 or
               packetClkCnt = 12 or packetClkCnt = 14 or packetClkCnt = 18 or
               packetClkCnt = 24 ) then
            eccEnable <= '1';
          else
            eccEnable <= '0';
          end if;
          
          if ( packetClkCnt = 25 ) then
            ecc0 <= ecc0_int;
            ecc1 <= ecc1_int;
            ecc2 <= ecc2_int;
            ecc3 <= ecc3_int;
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
            dat0( 3 ) <= '0';
            
            ecc4( 6 downto 0 ) <= ecc4( 7 downto 1 );
            ecc4( 7 ) <= '0';
          else
            dat0 <= ( others => '0' );
          end if;
                    
        elsif( countY = 2 and packetClkCnt >= 28 and packetClkCnt < 32 ) then
          packetClkCnt <= packetClkCnt + 1;
          
          dat1 <= ecc3( 0 ) & ecc2( 0 ) & ecc1( 0 ) & ecc0( 0 ) ;
          dat2 <= ecc3( 1 ) & ecc2( 1 ) & ecc1( 1 ) & ecc0( 1 ) ;
          
          dat0( 0 ) <= hsync;
          dat0( 1 ) <= vsync;
          dat0( 2 ) <= ecc4( 0 );
          dat0( 3 ) <= '0';
          
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
        elsif ( ( countY >= -1 and countY <= 718 ) and countX >= videoPreambleXPosStart and countX < videoGuardXPosStart ) then
        --if ( ( countY >= -1 and countY <= 718 ) and countX >= videoPreambleXPosStart and countX < videoGuardXPosStart ) then
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
          
        --elsif( countY = 2 and countX >= videoGuardXPosStart  ) then
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

          
        else
          ctl0 <= '0';
          ctl1 <= '0';
          ctl2 <= '0';
          ctl3 <= '0';
          guard0 <= ( others => '0' );
          guard1 <= ( others => '0' );
          guard2 <= ( others => '0' );
          curEncType <= TMDSENC;
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
      else
        curEncType_del <= curEncType;
        redNoEnc_del <= redNoEnc;
        blueNoEnc_del <= blueNoEnc;
        greenNoEnc_del <= greenNoEnc;
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
  --drawGBA <= '1' when ( countXDel < 959 and ( countYDel >= 0 and countYDel < 639 ) ) else '0';
  drawGBA <= '1' when ( countX < 959 and ( countY >= 0 and countY < 639 ) ) else '0';
  
--  hSync <= '1' when ( countXDel >= 1280 + hfrontporch ) and ( countXDel < 1280 + hfrontporch + hsyncpxl ) else '0';
--  vSync <= '1' when ( countYDel < -vbackporch) else '0';
--  draw <= '1' when ( countXDel < 1280 ) and ( countYDel >= 0 and countYDel < 720 ) else '0';
  hSync <= '1' when ( countXDel >= 1280 + hfrontporch ) and ( countXDel < 1280 + hfrontporch + hsyncpxl ) else '0';
  vSync <= '1' when ( countYDel < -vbackporch) else '0';
  draw <= '1' when ( countXDel < 1280 ) and ( countYDel >= 0 and countYDel < 720 ) else '0';
  
  ctrl( 1 ) <= vSync;
  ctrl( 0 ) <= hSync;
  
  redDat <= redPxl when ( drawGBA ='1' ) else ( others => '0' );
  greenDat <= greenPxl when ( drawGBA ='1' ) else ( others => '0' );
  blueDat <= bluePxl when ( drawGBA ='1' ) else ( others => '0' );  
  
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
      datIn => subpacket0( 0 )( 7 downto 0 ),
      newPacket => eccNewPacket,
      enable => eccEnable,
      clk => pxlClk,
      rst => rst,
      datOut => ecc0_int
    );
    
    ecc1Gen : entity work.ecc( rtl )
    port map(
      datIn => subpacket1( 0 )( 7 downto 0 ),
      newPacket => eccNewPacket,
      enable => eccEnable,
      clk => pxlClk,
      rst => rst,
      datOut => ecc1_int
    );
    
    ecc2Gen : entity work.ecc( rtl )
    port map(
      datIn => subpacket2( 0 )( 7 downto 0 ),
      newPacket => eccNewPacket,
      enable => eccEnable,
      clk => pxlClk,
      rst => rst,
      datOut => ecc2_int
    );
    
    ecc3Gen : entity work.ecc( rtl )
    port map(
      datIn => subpacket3( 0 )( 7 downto 0 ),
      newPacket => eccNewPacket,
      enable => eccEnable,
      clk => pxlClk,
      rst => rst,
      datOut => ecc3_int
    );
    
    ecc4Gen : entity work.ecc( rtl )
    port map(
      datIn => packetheader( 0 )( 7 downto 0 ),
      newPacket => eccNewPacket,
      enable => eccEnable,
      clk => pxlClk,
      rst => rst,
      datOut => ecc4_int
    );
    

end rtl;