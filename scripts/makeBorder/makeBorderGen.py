#!/usr/bin/env python3

#######################################################
## Title: Custom border generator
## Author: zwenergy
#######################################################

from PIL import Image
import sys

######## INPUT SECTION (may be changed) ###############
outputFile = "borderGen.vhd"
outputR = "r"
outputG = "g"
outputB = "b"
inputX = "x"
inputY = "y"
#######################################################

# Some constants
borderH = 180
borderW = 320
leftRight = 40
topBottom = 10
scale = 4

# Get the image file.
if ( not( len( sys.argv ) == 2 or len( sys.argv ) == 3 ) ):
  print( "Wrong usage. Correct usage: makeBorderGen.py <IMAGEFILE> (<CUTBITS>)" )
  exit( 1 )

imageFile = sys.argv[ 1 ]

cutBits = 0
if ( len( sys.argv ) == 3 ):
  cutBits = int( sys.argv[ 2 ] )

# Open output file.
f = open( outputFile, "w" )

# Write header.
print( 
"-----------------------------------------------------------------------\n"
"-- Title: Border Generator (auto generated)\n"
"-----------------------------------------------------------------------\n"
"library IEEE;\n"
"use IEEE.STD_LOGIC_1164.ALL;\n"
"use IEEE.NUMERIC_STD.ALL;\n"
"entity borderGen is \n"
"  generic(\n"
"    xMin : integer;\n"
"    xMax : integer;\n"
"    yMin : integer;\n"
"    yMax : integer\n"
"  );\n"
"  port (\n"
"    x : in integer range xMin to xMax;\n"
"    y : in integer range yMin to yMax; \n"
"    r : out std_logic_vector( 7 downto 0 );\n"
"    g : out std_logic_vector( 7 downto 0 );\n"
"    b : out std_logic_vector( 7 downto 0 )\n"
"  );\n"
"end borderGen;\n"
"architecture rtl of borderGen is\n"
"begin\n"
"border:process( x, y ) is\n"
"begin\n", file = f );


# Load the image.
im = Image.open( imageFile )
w, h = im.size

if ( w != borderW or h != borderH ):
  print( "Wrong resolution!" )
  exit( 1 )

rgbIm = im.convert( "RGB" )

print( "case " + inputY + " is", file = f )
for y in range( borderH ):    
  print( "  when ", end = "", file = f )
  for i in range( scale ):
    print( str( y * scale + i ), end = "", file = f )
    if ( i != scale - 1 ):
      print( "|" , end = "", file = f )
      
  print( " =>", file = f )
  
  print( "    case " + inputX + " is", file = f )
  for x in range( borderW ):
    if ( x >= leftRight and x < borderW - leftRight ):
      continue

    r, g, b = rgbIm.getpixel( ( x, y  )  )
    
    # Reduce color space
    if ( cutBits != 0 ):
      r = ( r >> cutBits ) << cutBits
      if ( r & ( 1 << cutBits ) ):
        r = r | ( ( 1 << cutBits ) - 1 )
        
      g = ( g >> cutBits ) << cutBits
      if ( g & ( 1 << cutBits ) ):
        g = g | ( ( 1 << cutBits ) - 1 )
        
      b = ( b >> cutBits ) << cutBits
      if ( b & ( 1 << cutBits ) ):
        b = b | ( ( 1 << cutBits ) - 1 )
    
    print( "      when ", end = "", file = f )
    for i in range( scale ):
      print( str( x * scale + i ), end = "", file = f )
      if ( i != scale - 1 ):
        print( "|" , end = "", file = f )
      
    print( " => " + outputR + " <= std_logic_vector( to_unsigned( " + str( r ) + ", " + outputR + "'length ) ); " 
      + outputG + " <= std_logic_vector( to_unsigned( "
      + str( g ) + ", " + outputR + "'length ) ); " 
      + outputB + " <= std_logic_vector( to_unsigned( "
      + str( b ) + ", " + outputR + "'length ) ); ", file = f )
      
  print( "      when others => r <= ( others => ( '-' ) ); "
         "g <= ( others => ( '-' ) ); b <= ( others => ( '-' ) );", file = f )
  print( "    end case;", file = f )

print( "  when others => r <= ( others => ( '-' ) ); "
       "g <= ( others => ( '-' ) ); b <= ( others => ( '-' ) );", file = f )
print( "end case;", file = f );

print(
"end process;\n"
"end rtl;", file = f );

print( "New " + outputFile + " created!" )
