-----------------------------------------------------------------------
-- Title: 4x Smoother
-- Author: zwenergy
-----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity smooth4x is
  generic(
    colorDepth : integer := 8
  );
  port (
    -- Source pixels
   rTL : in std_logic_vector( colorDepth - 1 downto 0 );
   gTL : in std_logic_vector( colorDepth - 1 downto 0 );
   bTL : in std_logic_vector( colorDepth - 1 downto 0 );
   rTM : in std_logic_vector( colorDepth - 1 downto 0 );
   gTM : in std_logic_vector( colorDepth - 1 downto 0 );
   bTM : in std_logic_vector( colorDepth - 1 downto 0 );
   rTR : in std_logic_vector( colorDepth - 1 downto 0 );
   gTR : in std_logic_vector( colorDepth - 1 downto 0 );
   bTR : in std_logic_vector( colorDepth - 1 downto 0 );
   
   rCL : in std_logic_vector( colorDepth - 1 downto 0 );
   gCL : in std_logic_vector( colorDepth - 1 downto 0 );
   bCL : in std_logic_vector( colorDepth - 1 downto 0 );
   rCM : in std_logic_vector( colorDepth - 1 downto 0 );
   gCM : in std_logic_vector( colorDepth - 1 downto 0 );
   bCM : in std_logic_vector( colorDepth - 1 downto 0 );
   rCR : in std_logic_vector( colorDepth - 1 downto 0 );
   gCR : in std_logic_vector( colorDepth - 1 downto 0 );
   bCR : in std_logic_vector( colorDepth - 1 downto 0 );
   
   rBL : in std_logic_vector( colorDepth - 1 downto 0 );
   gBL : in std_logic_vector( colorDepth - 1 downto 0 );
   bBL : in std_logic_vector( colorDepth - 1 downto 0 );
   rBM : in std_logic_vector( colorDepth - 1 downto 0 );
   gBM : in std_logic_vector( colorDepth - 1 downto 0 );
   bBM : in std_logic_vector( colorDepth - 1 downto 0 );
   rBR : in std_logic_vector( colorDepth - 1 downto 0 );
   gBR : in std_logic_vector( colorDepth - 1 downto 0 );
   bBR : in std_logic_vector( colorDepth - 1 downto 0 );
   
   xSel : in std_logic_vector( 1 downto 0 );
   ySel : in std_logic_vector( 1 downto 0 );
   
   do4x : in std_logic;
   
   -- Out pixel
   rOut : out std_logic_vector( colorDepth - 1 downto 0 );
   gOut : out std_logic_vector( colorDepth - 1 downto 0 );
   bOut : out std_logic_vector( colorDepth - 1 downto 0 )   
  );
end smooth4x;

architecture rtl of smooth4x is
type pixel is array( 0 to 2 ) of std_logic_vector( colorDepth - 1 downto 0 );
type pixel4 is array( 0 to 3 ) of pixel;
type pixel16 is array( 0 to 3 ) of pixel4;  

function smooth2x( 
  signal pxTM: in pixel;
  signal pxCL: in pixel;
  signal pxCM: in pixel;
  signal pxCR: in pixel;
  signal pxBM: in pixel ) return pixel4 is 
    variable sm : pixel4;
    variable tmpTL, tmpTR, tmpBL, tmpBR : pixel;
begin
  if ( pxTM /= pxBM and pxCL /= pxCR ) then
      if ( pxCL = pxTM ) then
        tmpTL := pxCL;
      else
        tmpTL := pxCM;
      end if;
      
      if ( pxTM = pxCR ) then
        tmpTR := pxCR;
      else
        tmpTR := pxCM;
      end if;
      
      if ( pxCL = pxBM ) then
        tmpBL := pxCL;
      else
        tmpBL := pxCM;
      end if;
      
      if ( pxBM = pxCR ) then
        tmpBR := pxCR;
      else
        tmpBR := pxCM;
      end if;
      
    else
      tmpTL := pxCM;
      tmpTR := pxCM;
      tmpBL := pxCM;
      tmpBR := pxCM;
    end if;
    
    sm( 0 ) := tmpTL;
    sm( 1 ) := tmpTR;
    sm( 2 ) := tmpBL;
    sm( 3 ) := tmpBR;
    
    return sm;
end smooth2x;

function smooth2xMod( 
  signal pxTM: in pixel;
  signal pxCL: in pixel;
  signal pxCM: in pixel;
  signal pxCR: in pixel;
  signal pxBM: in pixel;
  signal ignoreTopBottom: in std_logic;
  signal ignoreLeftRight: in std_logic ) return pixel4 is 
    variable sm : pixel4;
    variable tmpTL, tmpTR, tmpBL, tmpBR : pixel;
begin
  if ( ( ignoreTopBottom = '1' and pxCL /= pxCR ) or
       ( ignoreLeftRight = '1' and pxTM /= pxBM ) or
       ( pxTM /= pxBM and pxCL /= pxCR and 
         ignoreTopBottom = '0' and ignoreLeftRight = '0' ) ) then
      if ( pxCL = pxTM ) then
        tmpTL := pxCL;
      else
        tmpTL := pxCM;
      end if;
      
      if ( pxTM = pxCR ) then
        tmpTR := pxCR;
      else
        tmpTR := pxCM;
      end if;
      
      if ( pxCL = pxBM ) then
        tmpBL := pxCL;
      else
        tmpBL := pxCM;
      end if;
      
      if ( pxBM = pxCR ) then
        tmpBR := pxCR;
      else
        tmpBR := pxCM;
      end if;
      
    else
      tmpTL := pxCM;
      tmpTR := pxCM;
      tmpBL := pxCM;
      tmpBR := pxCM;
    end if;
    
    sm( 0 ) := tmpTL;
    sm( 1 ) := tmpTR;
    sm( 2 ) := tmpBL;
    sm( 3 ) := tmpBR;
    
    return sm;
end smooth2xMod; 

signal pxTL, pxTM, pxTR, pxCL, pxCM, pxCR, pxBL, pxBM, pxBR : pixel;
signal smoothOut : pixel16;
signal tm2x, cl2x, cm2x, cr2x, bm2x : pixel4;
signal ignoreSig : std_logic := '1';
signal notIgnoreSig : std_logic := '0';
begin

  pxTL( 0 ) <= rTL;
  pxTL( 1 ) <= gTL;
  pxTL( 2 ) <= bTL;
  
  pxTM( 0 ) <= rTM;
  pxTM( 1 ) <= gTM;
  pxTM( 2 ) <= bTM;
  
  pxTR( 0 ) <= rTR;
  pxTR( 1 ) <= gTR;
  pxTR( 2 ) <= bTR;
  
  pxCL( 0 ) <= rCL;
  pxCL( 1 ) <= gCL;
  pxCL( 2 ) <= bCL;
  
  pxCM( 0 ) <= rCM;
  pxCM( 1 ) <= gCM;
  pxCM( 2 ) <= bCM;
  
  pxCR( 0 ) <= rCR;
  pxCR( 1 ) <= gCR;
  pxCR( 2 ) <= bCR;
  
  pxBL( 0 ) <= rBL;
  pxBL( 1 ) <= gBL;
  pxBL( 2 ) <= bBL;
  
  pxBM( 0 ) <= rBM;
  pxBM( 1 ) <= gBM;
  pxBM( 2 ) <= bBM;
  
  pxBR( 0 ) <= rBR;
  pxBR( 1 ) <= gBR;
  pxBR( 2 ) <= bBR;
  
  process( pxTL, pxTM, pxTR, pxCL, pxCM, pxCR, pxBL, pxBM, pxBR, ignoreSig, notIgnoreSig ) is
  begin
    
    -- Smooth 2x
    tm2x <= smooth2xMod( pxCM, pxTL, pxTM, pxTR, pxCM, ignoreSig, notIgnoreSig );
    cl2x <= smooth2xMod( pxTL, pxCM, pxCL, pxCM, pxBL, notIgnoreSig, ignoreSig );
    cm2x <= smooth2x( pxTM, pxCL, pxCM, pxCR, pxBM );
    cr2x <= smooth2xMod( pxTR, pxCM, pxCR, pxCM, pxBR, notIgnoreSig, ignoreSig );
    bm2x <= smooth2xMod( pxCM, pxBL, pxBM, pxBR, pxCM, ignoreSig, notIgnoreSig );
  end process;
  
  process( tm2x, cl2x, cm2x, cr2x, bm2x ) is
  begin
    -- And 4x.
    smoothOut( 0 ) <= smooth2x( tm2x( 2 ), cl2x( 1 ), cm2x( 0 ),
      cm2x( 1 ), cm2x( 2 ) );
      
    smoothOut( 1 ) <= smooth2x( tm2x( 3 ), cm2x( 0 ), cm2x( 1 ), cr2x( 0 ),
      cm2x( 3 ) );
      
    smoothOut( 2 ) <= smooth2x( cm2x( 0 ), cl2x( 3 ), cm2x( 2 ),
      cm2x( 3 ), bm2x( 0 ) );
      
    smoothOut( 3 ) <= smooth2x( cm2x( 1 ), cm2x( 2 ), cm2x( 3 ),
      cr2x( 2 ), bm2x( 1 ) );
  end process;
  
  -- Output.
  process( tm2x, cl2x, cm2x, cr2x, bm2x, xSel, ySel, smoothOut, do4x ) is
  begin
    if ( do4x = '0' ) then
      case xSel is
        when "00"|"01" =>
          case ySel is
            when "00"|"01" =>
              rOut <= cm2x( 0 )( 0 );
              gOut <= cm2x( 0 )( 1 );
              bOut <= cm2x( 0 )( 2 );
            when "10"|"11" =>
              rOut <= cm2x( 2 )( 0 );
              gOut <= cm2x( 2 )( 1 );
              bOut <= cm2x( 2 )( 2 );
            when others =>
              rOut <= cm2x( 0 )( 0 );
              gOut <= cm2x( 0 )( 1 );
              bOut <= cm2x( 0 )( 2 );
            end case;
        
        when "10"|"11" =>
          case ySel is
            when "00"|"01" =>
              rOut <= cm2x( 1 )( 0 );
              gOut <= cm2x( 1 )( 1 );
              bOut <= cm2x( 1 )( 2 );
            when "10"|"11" =>
              rOut <= cm2x( 3 )( 0 );
              gOut <= cm2x( 3 )( 1 );
              bOut <= cm2x( 3 )( 2 );
            when others =>
              rOut <= cm2x( 0 )( 0 );
              gOut <= cm2x( 0 )( 1 );
              bOut <= cm2x( 0 )( 2 );
            end case;
            
        when others =>
          rOut <= cm2x( 0 )( 0 );
          gOut <= cm2x( 0 )( 1 );
          bOut <= cm2x( 0 )( 2 );
    end case;
    
  else 
    case xSel is
      when "00" =>
        case ySel is
          when "00" =>
            rOut <= smoothOut( 0 )( 0 )( 0 );
            gOut <= smoothOut( 0 )( 0 )( 1 );
            bOut <= smoothOut( 0 )( 0 )( 2 );
            
          when "01" =>
            rOut <= smoothOut( 0 )( 2 )( 0 );
            gOut <= smoothOut( 0 )( 2 )( 1 );
            bOut <= smoothOut( 0 )( 2 )( 2 );
            
          when "10" =>
            rOut <= smoothOut( 2 )( 0 )( 0 );
            gOut <= smoothOut( 2 )( 0 )( 1 );
            bOut <= smoothOut( 2 )( 0 )( 2 );
            
          when "11" =>
            rOut <= smoothOut( 2 )( 2 )( 0 );
            gOut <= smoothOut( 2 )( 2 )( 1 );
            bOut <= smoothOut( 2 )( 2 )( 2 );
          
          when others =>
            rOut <= smoothOut( 0 )( 0 )( 0 );
            gOut <= smoothOut( 0 )( 0 )( 0 );
            bOut <= smoothOut( 0 )( 0 )( 0 );
        end case;
        
      when "01" =>
        case ySel is
          when "00" =>
            rOut <= smoothOut( 0 )( 1 )( 0 );
            gOut <= smoothOut( 0 )( 1 )( 1 );
            bOut <= smoothOut( 0 )( 1 )( 2 );
            
          when "01" =>
            rOut <= smoothOut( 0 )( 3 )( 0 );
            gOut <= smoothOut( 0 )( 3 )( 1 );
            bOut <= smoothOut( 0 )( 3 )( 2 );
            
          when "10" =>
            rOut <= smoothOut( 2 )( 1 )( 0 );
            gOut <= smoothOut( 2 )( 1 )( 1 );
            bOut <= smoothOut( 2 )( 1 )( 2 );
            
          when "11" =>
            rOut <= smoothOut( 2 )( 3 )( 0 );
            gOut <= smoothOut( 2 )( 3 )( 1 );
            bOut <= smoothOut( 2 )( 3 )( 2 );
            
          when others =>
            rOut <= smoothOut( 0 )( 0 )( 0 );
            gOut <= smoothOut( 0 )( 0 )( 0 );
            bOut <= smoothOut( 0 )( 0 )( 0 );
        end case;
        
      when "10" =>
        case ySel is
          when "00" =>
            rOut <= smoothOut( 1 )( 0 )( 0 );
            gOut <= smoothOut( 1 )( 0 )( 1 );
            bOut <= smoothOut( 1 )( 0 )( 2 );
            
          when "01" =>
            rOut <= smoothOut( 1 )( 2 )( 0 );
            gOut <= smoothOut( 1 )( 2 )( 1 );
            bOut <= smoothOut( 1 )( 2 )( 2 );
            
          when "10" =>
            rOut <= smoothOut( 3 )( 0 )( 0 );
            gOut <= smoothOut( 3 )( 0 )( 1 );
            bOut <= smoothOut( 3 )( 0 )( 2 );
            
          when "11" =>
            rOut <= smoothOut( 3 )( 2 )( 0 );
            gOut <= smoothOut( 3 )( 2 )( 1 );
            bOut <= smoothOut( 3 )( 2 )( 2 );
            
          when others =>
            rOut <= smoothOut( 0 )( 0 )( 0 );
            gOut <= smoothOut( 0 )( 0 )( 0 );
            bOut <= smoothOut( 0 )( 0 )( 0 );
        end case;
        
      when "11" =>
        case ySel is
          when "00" =>
            rOut <= smoothOut( 1 )( 1 )( 0 );
            gOut <= smoothOut( 1 )( 1 )( 1 );
            bOut <= smoothOut( 1 )( 1 )( 2 );
            
          when "01" =>
            rOut <= smoothOut( 1 )( 3 )( 0 );
            gOut <= smoothOut( 1 )( 3 )( 1 );
            bOut <= smoothOut( 1 )( 3 )( 2 );
            
          when "10" =>
            rOut <= smoothOut( 3 )( 1 )( 0 );
            gOut <= smoothOut( 3 )( 1 )( 1 );
            bOut <= smoothOut( 3 )( 1 )( 2 );
            
          when "11" =>
            rOut <= smoothOut( 3 )( 3 )( 0 );
            gOut <= smoothOut( 3 )( 3 )( 1 );
            bOut <= smoothOut( 3 )( 3 )( 2 );
            
          when others =>
            rOut <= smoothOut( 0 )( 0 )( 0 );
            gOut <= smoothOut( 0 )( 0 )( 0 );
            bOut <= smoothOut( 0 )( 0 )( 0 );
        end case;
        
      when others =>
        rOut <= smoothOut( 0 )( 0 )( 0 );
        gOut <= smoothOut( 0 )( 0 )( 0 );
        bOut <= smoothOut( 0 )( 0 )( 0 );
      end case;
    end if;
  end process;

end rtl;
