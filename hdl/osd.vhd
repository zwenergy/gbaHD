-----------------------------------------------------------------------
-- Title: OSD
-- Author: zwenergy
-----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity osd is
  port(
    pxlX : in integer range 0 to 1665;
    pxlY : in integer range -25 to 1000;
    controller : in std_logic_vector( 5 downto 0 );
    osdEnableIn : in std_logic;
    rxValid : in std_logic;
    clk : in std_logic;
    rst : in std_logic;
    
    osdEnableOut : out std_logic;
    osdRed : out std_logic_vector( 7 downto 0 );
    osdGreen : out std_logic_vector( 7 downto 0 );
    osdBlue : out std_logic_vector( 7 downto 0 );
    
    smooth2x : out std_logic;
    smooth4x : out std_logic;
    pixelGrid : out std_logic;
    bgrid : out std_logic
  );
end entity;

architecture rtl of osd is
-- Assuming the resolution is 1280x720
constant SCALE : integer := 4;
constant MENU_WIDTHFIELDS : integer := 27;
constant MENU_HEIGHTFIELDS : integer := 6;
constant CHARWIDTH : integer := 5;
constant CHARHEIGHT : integer := 7;
constant CHARSPACE : integer := 1;
constant FIELDHEIGHT : integer := CHARHEIGHT + CHARSPACE;
constant FIELDWIDTH : integer := CHARWIDTH + CHARSPACE;
constant MENUSTARTX : integer := 640 - ( ( ( FIELDWIDTH * MENU_WIDTHFIELDS ) / 2 ) * SCALE );
constant MENUSTARTY : integer := 360  - ( ( ( FIELDHEIGHT * MENU_HEIGHTFIELDS ) / 2) * SCALE );
constant MENUENDX : integer := MENUSTARTX + ( FIELDWIDTH * MENU_WIDTHFIELDS * SCALE );
constant MENUENDY : integer := MENUSTARTY + ( FIELDHEIGHT * MENU_HEIGHTFIELDS * SCALE );
constant PXLGRIDFIELDX : integer := 15;
constant PXLGRIDFIELDY : integer := 3;
constant SMOOTHFIELDX : integer := 15;
constant SMOOTHFIELDY : integer := 4;

type tLine  is array( 0 to MENU_WIDTHFIELDS - 1 ) of integer range 0 to 37;
type tMenuFrame is array( 0 to MENU_HEIGHTFIELDS - 1 ) of tLine;

signal mainMenu : tMenuFrame := (
-- One empty line
( 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00 ),
-- GBAHD v1.2
( 00, 00, 00, 00, 00, 00, 00, 00, 00, 07, 02, 01, 08, 04, 00, 22, 27, 36, 28, 00, 00, 00, 00, 00, 00, 00, 00 ),
-- One empty line
( 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00 ),
-- PXL GRID
( 00, 16, 24, 12, 00, 07, 18, 09, 04, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00 ),
-- Smoothing
( 00, 19, 13, 15, 15, 20, 08, 09, 14, 07, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00 ),
-- One empty line
( 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00 )
);


signal osdEnable_int : std_logic;
signal fieldYCnt : integer range 0 to MENU_HEIGHTFIELDS - 1;
signal fieldXCnt : integer range 0 to MENU_WIDTHFIELDS - 1;
signal pxlXCnt : integer range 0 to FIELDWIDTH - 1;
signal pxlYCnt : integer range 0 to FIELDHEIGHT - 1;

signal menuArea : std_logic;
signal curSpace : std_logic;
signal nextOSDShow : std_logic;

signal char : integer range 0 to 37;
signal charX : integer range 0 to 4;
signal charY: integer range 0 to 6;
signal charPxl : std_logic;

signal scaleCntX, scaleCntY : integer range 0 to SCALE - 1;

signal smooth2x_int, smooth4x_int, pixelGrid_int, bgrid_int : std_logic;
signal controller_int, controller_prev : std_logic_vector( 5 downto 0 );
signal lineSelected : integer range 0 to MENU_HEIGHTFIELDS - 1;
signal lineActive : std_logic;

begin

  smooth2x <= smooth2x_int;
  smooth4x <= smooth4x_int;
  pixelGrid <= pixelGrid_int;
  bgrid <= bgrid_int;
  
  -- Update menu.
  process( smooth2x_int, smooth4x_int, pixelGrid_int, bgrid_int ) is
  begin
    if ( smooth2x_int = '1' ) then
      -- 2X
      mainMenu( SMOOTHFIELDY )( SMOOTHFIELDX ) <= 28;
      mainMenu( SMOOTHFIELDY )( SMOOTHFIELDX + 1 ) <= 24;
      mainMenu( SMOOTHFIELDY )( SMOOTHFIELDX + 2 ) <= 0;
    elsif ( smooth4x_int = '1' ) then
      -- 4X
      mainMenu( SMOOTHFIELDY )( SMOOTHFIELDX ) <= 30;
      mainMenu( SMOOTHFIELDY )( SMOOTHFIELDX + 1 ) <= 24;
      mainMenu( SMOOTHFIELDY )( SMOOTHFIELDX + 2 ) <= 0;
    else
      -- OFF
      mainMenu( SMOOTHFIELDY )( SMOOTHFIELDX ) <= 15;
      mainMenu( SMOOTHFIELDY )( SMOOTHFIELDX + 1 ) <= 6;
      mainMenu( SMOOTHFIELDY )( SMOOTHFIELDX + 2 ) <= 6;
    end if;
    
    if ( pixelGrid_int = '1' ) then
      if ( bgrid_int = '1' ) then
        -- Bright
        mainMenu( PXLGRIDFIELDY )( PXLGRIDFIELDX ) <= 2;
        mainMenu( PXLGRIDFIELDY )( PXLGRIDFIELDX + 1 ) <= 18;
        mainMenu( PXLGRIDFIELDY )( PXLGRIDFIELDX + 2 ) <= 9;
        mainMenu( PXLGRIDFIELDY )( PXLGRIDFIELDX + 3 ) <= 7;
        mainMenu( PXLGRIDFIELDY )( PXLGRIDFIELDX + 4 ) <= 8;
        mainMenu( PXLGRIDFIELDY )( PXLGRIDFIELDX + 5 ) <= 20;
      else
        -- Dark
        mainMenu( PXLGRIDFIELDY )( PXLGRIDFIELDX ) <= 4;
        mainMenu( PXLGRIDFIELDY )( PXLGRIDFIELDX + 1 ) <= 1;
        mainMenu( PXLGRIDFIELDY )( PXLGRIDFIELDX + 2 ) <= 18;
        mainMenu( PXLGRIDFIELDY )( PXLGRIDFIELDX + 3 ) <= 11;
        mainMenu( PXLGRIDFIELDY )( PXLGRIDFIELDX + 4 ) <= 0;
        mainMenu( PXLGRIDFIELDY )( PXLGRIDFIELDX + 5 ) <= 0;
        
      end if;
    else
      -- OFF
      mainMenu( PXLGRIDFIELDY )( PXLGRIDFIELDX ) <= 15;
      mainMenu( PXLGRIDFIELDY )( SMOOTHFIELDX + 1 ) <= 6;
      mainMenu( PXLGRIDFIELDY )( PXLGRIDFIELDX + 2 ) <= 6;
      mainMenu( PXLGRIDFIELDY )( PXLGRIDFIELDX + 3 ) <= 0;
      mainMenu( PXLGRIDFIELDY )( PXLGRIDFIELDX + 4 ) <= 0;
      mainMenu( PXLGRIDFIELDY )( PXLGRIDFIELDX + 5 ) <= 0;
    end if;
  end process;
  
  menuArea <= '1' when ( pxlX >= MENUSTARTX and pxlX < MENUENDX and
                         pxlY >= MENUSTARTY and pxlY < MENUENDY ) else '0';
                         
  lineActive <= '1' when ( lineSelected = fieldYCnt ) else '0';
             
  curSpace <= '1' when ( pxlXCnt = FIELDWIDTH - 1 or pxlYCnt = FIELDHEIGHT - 1 ) else '0';
  
  char <= mainMenu( fieldYCnt )( fieldXCnt ) when ( curSpace = '0' ) else 0;
  charX <= pxlXCnt when ( menuArea = '1' and curSpace = '0' ) else 0;
  charY <= pxlYCnt when ( menuArea = '1' and curSpace = '0' ) else 0;
  
             
  font_inst : entity work.font5x7( rtl )
  port map(
    char => char,
    x => charX,
    y => charY,
    clk => clk,
    rst => rst,
    charPxl => charPxl
  );

  process( clk ) is
  begin
    if ( rising_edge( clk ) ) then
      if ( rst = '1' ) then
        osdEnable_int <= '0';
        fieldYCnt <= 0;
        fieldXCnt <= 0;
        pxlYCnt <= 0;
        pxlXCnt <= 0;
        nextOSDShow <= '0';
        scaleCntX <= 0;
        scaleCntY <= 0;
        controller_int <= ( others => '0' );
        controller_prev <= ( others => '0' );
      else
      
        nextOSDShow <= menuArea and osdEnable_int;
      
        if ( rxValid = '1' ) then
          osdEnable_int <= osdEnableIn;
          controller_int <= controller;
        end if;
        
        controller_prev <= controller_int;
        
        -- Zero everything.
        if ( pxlX = 0 and pxlY = 0 ) then
          fieldYCnt <= 0;
          fieldXCnt <= 0;
          pxlYCnt <= 0;
          pxlXCnt <= 0;
          scaleCntX <= 0;
          scaleCntY <= 0;
        end if;
        
        if ( osdEnable_int = '1' and menuArea = '1' ) then
          -- Increase counters.
          if ( scaleCntX = SCALE - 1 ) then
            scaleCntX <= 0;
          else
            scaleCntX <= scaleCntX + 1;
          end if;
          
          if ( scaleCntX = SCALE - 1 ) then
            -- Reached end of a field (X)
            if ( pxlXCnt = FIELDWIDTH - 1 ) then
              pxlXCnt <= 0;
              
              -- Reached end of the menu (X)
              if ( fieldXCnt = MENU_WIDTHFIELDS - 1 ) then
                fieldXCnt <= 0;
                
                if ( scaleCntY = SCALE - 1 ) then
                  scaleCntY <= 0;
                else
                  scaleCntY <= scaleCntY + 1;
                end if;
                
                if ( scaleCntY = SCALE - 1 ) then
                  -- Reached end of a field (Y)
                  if ( pxlYCnt = FIELDHEIGHT - 1 ) then
                    pxlYCnt <= 0;
                    if ( fieldYCnt = MENU_HEIGHTFIELDS - 1 ) then
                      fieldYCnt <= 0;
                    else
                      fieldYCnt <= fieldYCnt + 1;
                    end if;
                  else
                    pxlYCnt <= pxlYCnt + 1;
                  end if;
                end if;
                
              else
                fieldXCnt <= fieldXCnt + 1;
              end if;
            else
            
              pxlXCnt <= pxlXCnt + 1;
            end if;
          end if;
        end if;
        
        -- Pipeline outgoing signals.
        osdEnableOut <= nextOSDShow;
        
        if ( lineActive = '1' ) then
          osdRed <= ( others => ( not charPxl ) );
          osdGreen <= ( others => ( not charPxl ) );
          osdBlue <= ( others => ( not charPxl ) );
        else
          osdRed <= ( others => ( charPxl ) );
          osdGreen <= ( others => ( charPxl ) );
          osdBlue <= ( others => ( charPxl ) );
        end if;
        
      end if;
    end if;
  end process;
  
  -- Controller handling
  process( clk ) is
  begin
    if ( rising_edge( clk ) ) then
      if ( rst = '1' ) then
        smooth2x_int <= '0';
        smooth4x_int <= '0';
        pixelGrid_int <= '0';
        bgrid_int <= '0';
        lineSelected <= 3;
      else
      
        if ( osdEnable_int = '1' ) then
          -- Up
          if ( controller_int( 0 ) = '1' and controller_prev( 0 ) = '0' ) then
            if ( lineSelected > 3 ) then
              lineSelected <= lineSelected - 1;
            end if;
          end if;
          
          -- Down
          if ( controller_int( 1 ) = '1' and controller_prev( 1 ) = '0' ) then
            if ( lineSelected < 4 ) then
              lineSelected <= lineSelected + 1;
            end if;
          end if;
          
          -- A
          if ( controller_int( 4 ) = '1' and controller_prev( 4 ) = '0' ) then
            case lineSelected is
              -- Pxl grid
              when 3 => 
                smooth2x_int <= '0';
                smooth4x_int <= '0';
                if ( pixelGrid_int = '1' ) then
                  if ( bgrid_int = '1' ) then
                    pixelGrid_int <= '0';
                    bgrid_int <= '0';
                  else
                    pixelGrid_int <= '1';
                    bgrid_int <= '1';
                  end if;
                else
                  pixelGrid_int <= '1';
                  bgrid_int <= '0';
                end if;
                
              -- Smooth  
              when 4 =>
                pixelGrid_int <= '0';
                bgrid_int <= '0';
                
                if ( smooth2x_int = '1' ) then
                  smooth2x_int <= '0';
                  smooth4x_int <= '1';
                elsif ( smooth4x_int = '1' ) then
                  smooth2x_int <= '0';
                  smooth4x_int <= '0';
                else
                  smooth2x_int <= '1';
                  smooth4x_int <= '0';
                end if;
                
              when others =>
                pixelGrid_int <= '0';
                bgrid_int <= '0';
                smooth4x_int <= '0';
                smooth2x_int <= '0';
            end case;
          end if;
        end if;
      end if;
    end if;
  end process;

end rtl;
