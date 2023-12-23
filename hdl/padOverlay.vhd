-----------------------------------------------------------------------
-- Title: Pad overlay generator
-- Author: zwenergy
-----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity padOverlay is
  generic(
    -- PosX is multiplied with scale.
    posX : integer;
    -- PosY is multiplied with scale.
    posY : integer;
    scale : integer;
    frameWidth : integer;
    frameHeight : integer
  );
  
  port(
    pxlX : in integer range 0 to 2300;
    pxlY : in integer range -25 to 1300;
    buttons : in std_logic_vector( 9 downto 0 );
    
    clk : in std_logic;
    rst : in std_logic;

    overlayInact : out std_logic;
    overlayAct : out std_logic
  );
end entity;

architecture behaviour of padOverlay is
type tROMline is array( 0 to 21 ) of integer range 0 to 10;
-- 0: UP
-- 1: DOWN
-- 2: LEFT
-- 3: RIGHT
-- 4: A
-- 5: B
-- 6: L
-- 7: R
-- 8: START
-- 9: SELECT
-- 10: NONE
type tPadOverlayROM is array( 0 to 11 ) of tROMline;
-- Changing this overlay also needs a change in the logic.
constant overlayROM : tPadOverlayROM := (
( 10, 10, 06, 06, 06, 06, 06, 06, 10, 10, 10, 10, 10, 10, 07, 07, 07, 07, 07, 07, 10, 10 ),
( 06, 06, 06, 06, 06, 06, 06, 06, 10, 10, 10, 10, 10, 10, 07, 07, 07, 07, 07, 07, 07, 07 ),
( 06, 06, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 07, 07 ),
( 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10 ),
( 10, 10, 10, 10, 00, 00, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10 ),
( 10, 10, 10, 10, 00, 00, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10 ),
( 10, 10, 02, 02, 10, 10, 03, 03, 10, 10, 10, 10, 10, 10, 05, 05, 10, 10, 04, 04, 10, 10 ),
( 10, 10, 02, 02, 10, 10, 03, 03, 10, 10, 10, 10, 10, 10, 05, 05, 10, 10, 04, 04, 10, 10 ),
( 10, 10, 10, 10, 01, 01, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10 ),
( 10, 10, 10, 10, 01, 01, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10 ),
( 10, 10, 10, 10, 10, 10, 10, 10, 09, 09, 10, 10, 08, 08, 10, 10, 10, 10, 10, 10, 10, 10 ),
( 10, 10, 10, 10, 10, 10, 10, 10, 09, 09, 10, 10, 08, 08, 10, 10, 10, 10, 10, 10, 10, 10 )
);
  
signal scaleCntX, scaleCntY : integer range 0 to scale - 1;

signal pxlXCnt : integer range 0 to frameWidth - 1;
signal pxlYCnt : integer range 0 to frameHeight - 1;

signal pxlXCnt_sub : integer range -frameWidth to frameWidth - 1;
signal pxlYCnt_sub : integer range -frameHeight to frameHeight - 1;

signal butUp, butDown, butLeft, butRight, butA, butB, butL, butR,
  butStart, butSelect : std_logic;


begin

  process( clk ) is
  begin
    if rising_edge( clk ) then
        if ( rst = '1' ) then
          pxlXCnt <= 0;
          pxlYCnt <= 0;
          pxlXCnt_sub <= 0;
          pxlYCnt_sub <= 0;
          scaleCntX <= 0;
          scaleCntY <= 0;
          
          butUp <= '0';
          butDown <= '0';
          butLeft <= '0';
          butRight <= '0';
          butA <= '0';
          butB <= '0';
          butL <= '0';
          butR <= '0';
          butStart <= '0';
          butSelect <= '0';
          
          overlayInact <= '0';
          overlayAct <= '0';
          
        else
          -- Zero everything.
          if ( pxlX = 0  ) then
            pxlXCnt <= 0;
            scaleCntX <= 0;
            
            if ( pxlY = 0 ) then
                scaleCntY <= 0;
                pxlYCnt <= 0;
            end if;
          end if;
          
          
          if ( scaleCntX = scale - 1 ) then
            scaleCntX <= 0;
            pxlXCnt <= pxlXCnt + 1;
          else
            scaleCntX <= scaleCntX + 1;
          end if;
          
          if ( pxlX = frameWidth -1 ) then
            scaleCntX <= 0;
            pxlXCnt <= 0;
            
            if ( scaleCntY = scale - 1 ) then
              scaleCntY <= 0;
              pxlYCnt <= pxlYCnt + 1;
            else
              scaleCntY <= scaleCntY + 1;
            end if;
          end if;
          
          butUp <= buttons( 0 );
          butDown <= buttons( 1 );
          butLeft <= buttons( 2 );
          butRight <= buttons( 3 );
          butA <= buttons( 4 );
          butB <= buttons( 5 );
          butL <= buttons( 6 );
          butR <= buttons( 7 );
          butStart <= buttons( 8 );
          butSelect <= buttons( 9 );
          
          -- Shift pxlCnt
          pxlXCnt_sub <= pxlXCnt - posX;
          pxlYCnt_sub <= pxlYCnt - posY;
          --pxlXCnt_sub <= pxlX;
          --pxlYCnt_sub <= pxlY;
          
          -- Output logic.
          if ( pxlXCnt_sub >= 0 and pxlXCnt_sub <= 21 and
               pxlYCnt_sub >= 0 and pxlYCnt_sub <= 11 ) then
            -- Overlay window.
            case overlayROM( pxlYCnt_sub )( pxlXCnt_sub ) is
              when 00 =>
                overlayInact <= '1';
                overlayAct <= butUp;
                
              when 01 =>
                overlayInact <= '1';
                overlayAct <= butDown;
                
              when 02 =>
                overlayInact <= '1';
                overlayAct <= butLeft;
                
              when 03 =>
                overlayInact <= '1';
                overlayAct <= butRight;
                
              when 04 =>
                overlayInact <= '1';
                overlayAct <= butA;
                
              when 05 =>
                overlayInact <= '1';
                overlayAct <= butB;
                
              when 06=>
                overlayInact <= '1';
                overlayAct <= butL;
                
              when 07 =>
                overlayInact <= '1';
                overlayAct <= butR;
                
              when 08 =>
                overlayInact <= '1';
                overlayAct <= butStart;
                
              when 09 =>
                overlayInact <= '1';
                overlayAct <= butSelect;
                
              when others =>
                overlayInact <= '0';
                overlayAct <= '0';
            end case;
            
          else
            overlayInact <= '0';
            overlayAct <= '0';
          end if;
          
               
        end if;
    
    end if;
  end process;

end behaviour;
