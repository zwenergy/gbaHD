-----------------------------------------------------------------------
-- Title: OSD
-- Author: zwenergy
-----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity osd is
  generic(
    scale : integer;
    frameWidth : integer;
    frameHeight : integer
  );
  port(
    pxlX : in integer range 0 to 1665;
    pxlY : in integer range -25 to 1000;
    osdEnableIn : in std_logic;
    clk : in std_logic;
    rst : in std_logic;
    
    osdRed : out std_logic_vector( 7 downto 0 );
    osdGreen : out std_logic_vector( 7 downto 0 );
    osdBlue : out std_logic_vector( 7 downto 0 );
    
    smooth2xIn : in std_logic;
    smooth4xIn : in std_logic;
    pixelGridIn : in std_logic;
    bgridIn : in std_logic;
    gridMultIn : in std_logic;
    colorModeIn : in std_logic;
    rateIn : in std_logic;
    controllerOSDActive : in std_logic;
    
    osdEnableOut : out std_logic;
    smooth2xOut : out std_logic;
    smooth4xOut : out std_logic;
    pixelGridOut : out std_logic;
    bgridOut : out std_logic;
    gridMultOut : out std_logic;
    colorModeOut : out std_logic;
    rateOut : out std_logic;
    
    osdState : in std_logic_vector( 7 downto 0 );
    
    configValid : in std_logic;
    stateValid : in std_logic;
    rxValid : in std_logic
  );
end entity;

architecture rtl of osd is
-- Assuming the resolution is 1280x720
constant MENU_WIDTHFIELDS : integer := 27;
constant MENU_HEIGHTFIELDS : integer := 12;
constant CHARWIDTH : integer := 5;
constant CHARHEIGHT : integer := 7;
constant CHARSPACE : integer := 1;
constant FIELDHEIGHT : integer := CHARHEIGHT + CHARSPACE;
constant FIELDWIDTH : integer := CHARWIDTH + CHARSPACE;
constant MENUSTARTX : integer := (frameWidth/2) - ( ( ( FIELDWIDTH * MENU_WIDTHFIELDS ) / 2 ) * scale );
constant MENUSTARTY : integer := (frameHeight/2)  - ( ( ( FIELDHEIGHT * MENU_HEIGHTFIELDS ) / 2) * scale );
constant MENUENDX : integer := MENUSTARTX + ( FIELDWIDTH * MENU_WIDTHFIELDS * scale );
constant MENUENDY : integer := MENUSTARTY + ( FIELDHEIGHT * MENU_HEIGHTFIELDS * scale );
constant PXLGRIDFIELDX : integer := 15;
constant PXLGRIDFIELDY : integer := 3;
constant GRIDMULTFIELDX : integer := 15;
constant GRIDMULTFIELDY : integer := PXLGRIDFIELDY + 1;
constant SMOOTHFIELDX : integer := 15;
constant SMOOTHFIELDY : integer := GRIDMULTFIELDY + 1;
constant COLORFIELDX : integer := 15;
constant COLORFIELDY : integer := SMOOTHFIELDY + 1;
constant FRAMEFIELDX : integer := 15;
constant FRAMEFIELDY : integer := COLORFIELDY + 1;
constant PADDISPFIELDX : integer := 15;
constant PADDISPFIELDY : integer := FRAMEFIELDY + 1;

type tLine  is array( 0 to MENU_WIDTHFIELDS - 1 ) of integer range 0 to 43;
type tMenuFrame is array( 0 to MENU_HEIGHTFIELDS - 1 ) of tLine;

attribute ram_style : string;
signal mainMenu : tMenuFrame := (
-- One empty line
( 39, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 40 ),
-- GBAHD v1.4B
( 41, 00, 00, 00, 00, 00, 00, 00, 07, 02, 01, 08, 04, 00, 27, 36, 30, 02, 00, 00, 00, 00, 00, 00, 00, 00, 41 ),
-- One empty line
( 37, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 38 ),
-- PXL GRID
( 41, 00, 16, 24, 12, 00, 07, 18, 09, 04, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 41 ),
-- Method
( 41, 00, 13, 05, 20, 08, 15, 04, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 41 ),
-- Smoothing
( 41, 00, 19, 13, 15, 15, 20, 08, 09, 14, 07, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 41 ),
-- Color
( 41, 00, 03, 15, 12, 15, 18, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 41 ),
-- Framerate
( 41, 00, 06, 18, 01, 13, 05, 18, 01, 20, 05, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 41 ),
-- Pad display
( 41, 00, 16, 01, 04, 00, 04, 09, 19, 16, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 41 ),
-- One empty line
( 41, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 41 ),
-- START: SAVE | B: REVERT
( 41, 00, 19, 20, 01, 18, 20, 42, 00, 19, 01, 22, 05, 00, 41, 00, 02, 42, 00, 01, 02, 15, 18, 20, 00, 00, 41 ),
-- Bottom Line
( 40, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 39 )
);

-- Have to add this attribute to NOT use RAM (since all is used for the line buffer)
attribute ram_style of mainMenu : signal is "registers";


signal fieldYCnt : integer range 0 to MENU_HEIGHTFIELDS - 1;
signal fieldXCnt : integer range 0 to MENU_WIDTHFIELDS - 1;
signal pxlXCnt : integer range 0 to FIELDWIDTH - 1;
signal pxlYCnt : integer range 0 to FIELDHEIGHT - 1;

signal menuArea : std_logic;
signal curSpace : std_logic;
signal nextOSDShow : std_logic;

signal char, char_reg : integer range 0 to 37;
-- Have to add this attribute to NOT use RAM (since all is used for the line buffer)
attribute ram_style of char_reg : signal is "registers";

signal charX : integer range 0 to 4;
signal charY: integer range 0 to 6;
signal charPxl : std_logic;

signal scaleCntX, scaleCntY : integer range 0 to SCALE - 1;

-- 0: Normal, 1: GBA mode
signal colorMode_int : std_logic;

-- 0: 60hz, 1: 59....
signal framerate : std_logic;

signal smooth2x_int, smooth4x_int, pixelGrid_int, bgrid_int, gridMult_int : std_logic;

signal lineSelected : integer range 0 to MENU_HEIGHTFIELDS - 1;
signal lineActive, osdEnable_int : std_logic;

begin

  smooth2xOut <= smooth2x_int;
  smooth4xOut <= smooth4x_int;
  pixelGridOut <= pixelGrid_int;
  bgridOut <= bgrid_int;
  gridMultOut <= gridMult_int;
  colorModeOut <= colorMode_int;
  rateOut <= framerate;
  
  -- Update menu.
  process( smooth2x_int, smooth4x_int, pixelGrid_int, bgrid_int, gridMult_int, colorMode_int, framerate, controllerOSDActive ) is
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

    if ( gridMult_int = '1' ) then
      -- MULT
      mainMenu( GRIDMULTFIELDY )( GRIDMULTFIELDX ) <= 13;
      mainMenu( GRIDMULTFIELDY )( GRIDMULTFIELDX + 1 ) <= 21;
      mainMenu( GRIDMULTFIELDY )( GRIDMULTFIELDX + 2 ) <= 12;
      mainMenu( GRIDMULTFIELDY )( GRIDMULTFIELDX + 3 ) <= 20;
      mainMenu( GRIDMULTFIELDY )( GRIDMULTFIELDX + 4 ) <= 0;
      mainMenu( GRIDMULTFIELDY )( GRIDMULTFIELDX + 5 ) <= 0;
    else
      -- ADD
      mainMenu( GRIDMULTFIELDY )( GRIDMULTFIELDX ) <= 1;
      mainMenu( GRIDMULTFIELDY )( GRIDMULTFIELDX + 1 ) <= 4;
      mainMenu( GRIDMULTFIELDY )( GRIDMULTFIELDX + 2 ) <= 4;
      mainMenu( GRIDMULTFIELDY )( GRIDMULTFIELDX + 3 ) <= 0;
      mainMenu( GRIDMULTFIELDY )( GRIDMULTFIELDX + 4 ) <= 0;
      mainMenu( GRIDMULTFIELDY )( GRIDMULTFIELDX + 5 ) <= 0;
    end if;
    
    if ( colorMode_int = '0' ) then
      -- Normal
      mainMenu( COLORFIELDY )( COLORFIELDX ) <= 14;
      mainMenu( COLORFIELDY )( COLORFIELDX + 1 ) <= 15;
      mainMenu( COLORFIELDY )( COLORFIELDX + 2 ) <= 18;
      mainMenu( COLORFIELDY )( COLORFIELDX + 3 ) <= 13;
      mainMenu( COLORFIELDY )( COLORFIELDX + 4 ) <= 1;
      mainMenu( COLORFIELDY )( COLORFIELDX + 5 ) <= 12;
    else
    --GBA
      mainMenu( COLORFIELDY )( COLORFIELDX ) <= 7;
      mainMenu( COLORFIELDY )( COLORFIELDX + 1 ) <= 2;
      mainMenu( COLORFIELDY )( COLORFIELDX + 2 ) <= 1;
      mainMenu( COLORFIELDY )( COLORFIELDX + 3 ) <= 0;
      mainMenu( COLORFIELDY )( COLORFIELDX + 4 ) <= 0;
      mainMenu( COLORFIELDY )( COLORFIELDX + 5 ) <= 0;
    end if;
    
    --60hz
    if ( framerate = '0' ) then
      mainMenu( FRAMEFIELDY )( FRAMEFIELDX ) <= 32;
      mainMenu( FRAMEFIELDY )( FRAMEFIELDX + 1 ) <= 15;
      mainMenu( FRAMEFIELDY )( FRAMEFIELDX + 2 ) <= 8;
      mainMenu( FRAMEFIELDY )( FRAMEFIELDX + 3 ) <= 26;
      mainMenu( FRAMEFIELDY )( FRAMEFIELDX + 4 ) <= 0;
      mainMenu( FRAMEFIELDY )( FRAMEFIELDX + 5 ) <= 0;
    else
      --59.7Hz
      mainMenu( FRAMEFIELDY )( FRAMEFIELDX ) <= 31;
      mainMenu( FRAMEFIELDY )( FRAMEFIELDX + 1 ) <= 35;
      mainMenu( FRAMEFIELDY )( FRAMEFIELDX + 2 ) <= 36;
      mainMenu( FRAMEFIELDY )( FRAMEFIELDX + 3 ) <= 33;
      mainMenu( FRAMEFIELDY )( FRAMEFIELDX + 4 ) <= 8;
      mainMenu( FRAMEFIELDY )( FRAMEFIELDX + 5 ) <= 26;
    end if;
    
    -- Input display
    if ( controllerOSDActive = '0' ) then
      mainMenu( PADDISPFIELDY )( PADDISPFIELDX ) <= 15;
      mainMenu( PADDISPFIELDY )( PADDISPFIELDX + 1 ) <= 6;
      mainMenu( PADDISPFIELDY )( PADDISPFIELDX + 2 ) <= 6;
      mainMenu( PADDISPFIELDY )( PADDISPFIELDX + 3 ) <= 0;
      mainMenu( PADDISPFIELDY )( PADDISPFIELDX + 4 ) <= 0;
      mainMenu( PADDISPFIELDY )( PADDISPFIELDX + 5 ) <= 0;
    else
      mainMenu( PADDISPFIELDY )( PADDISPFIELDX ) <= 15;
      mainMenu( PADDISPFIELDY )( PADDISPFIELDX + 1 ) <= 14;
      mainMenu( PADDISPFIELDY )( PADDISPFIELDX + 2 ) <= 0;
      mainMenu( PADDISPFIELDY )( PADDISPFIELDX + 3 ) <= 0;
      mainMenu( PADDISPFIELDY )( PADDISPFIELDX + 4 ) <= 0;
      mainMenu( PADDISPFIELDY )( PADDISPFIELDX + 5 ) <= 0;
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
        
        smooth2x_int <= '0';
        smooth4x_int <= '0';
        pixelGrid_int <= '0';
        gridMult_int <= '0';
        bgrid_int <= '0';
        colorMode_int <= '0';
        framerate <= '0';
        lineSelected <= 3;
        
        char_reg <= 0;

      else
      
        nextOSDShow <= menuArea and osdEnable_int;
        char_reg <= char;
      
        if ( rxValid = '1' ) then
          if ( stateValid = '1' ) then
            osdEnable_int <= osdEnableIn;
            lineSelected <= to_integer( unsigned( osdState ) );
            
          elsif ( configValid = '1' ) then
            smooth2x_int <= smooth2xIn;
            smooth4x_int <= smooth4xIn;
            pixelGrid_int <= pixelGridIn;
            bgrid_int <= bgridIn;
            gridMult_int <= gridMultIn;
            colorMode_int <= colorModeIn;
            framerate <= rateIn;
          
          end if;
          
        end if;
        
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

end rtl;
