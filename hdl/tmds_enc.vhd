-----------------------------------------------------------------------
-- Title: TMDS Encoder
-- Author: zwenergy
-----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tmdsEncoder is 
  port (
    dispEN : in std_logic;
    ctrl : in std_logic_vector( 1 downto 0 );
    datIn : in std_logic_vector( 7 downto 0 );
    clk : in std_logic;
    rst : in std_logic;
    
    datOut : out std_logic_vector( 9 downto 0 )
  );
end tmdsEncoder;

architecture rtl of tmdsEncoder is
signal sumDatIn : integer range 0 to 8;
signal sumTmp : integer range 0 to 8;
signal diffTmp : integer range -8 to 8;
signal disparity : integer range -16 to 15;
signal disparity_prev : integer range -16 to 15;
signal datIn_int : std_logic_vector( 7 downto 0 );
signal datOut_tmp : std_logic_vector( 9 downto 0 );
signal ctrl_int : std_logic_vector( 1 downto 0 );
signal dispEN_int : std_logic;
begin

  -- This one has a sync. reset.
  syncProc:process( clk ) is
  begin
    if rising_edge( clk ) then
      if ( rst = '1' ) then
        datIn_int <= ( others => '0' );
        disparity_prev <= 0;
        ctrl_int <= "00";
        dispEN_int <= '0';
      else
        datIn_int <= datIn;
        disparity_prev <= disparity;
        ctrl_int <= ctrl;
        dispEN_int <= dispEN;
      end if;
    end if;
  end process;

  sumDatInProc:process( datIn_int ) is
  variable tmpSum : integer range 0 to 8;
  begin
    tmpSum := 0;
    for i in 0 to 7 loop
      if ( datIn_int( i ) = '1' ) then
        tmpSum := tmpSum + 1;
      end if;
    end loop;
  
    sumDatIn <= tmpSum;
  end process;
  
  tmpProc:process( datIn_int, sumDatIn, datOut_tmp ) is
  begin
    if ( ( sumDatIn > 4 ) or ( sumDatIn = 4 and datIn_int( 0 ) = '0' ) ) then
      datOut_tmp( 0 ) <= datIn_int( 0 );
      datOut_tmp( 8 ) <= '0';
      for i in 1 to 7 loop
        datOut_tmp( i ) <= not( datOut_tmp( i - 1 ) xor datIn_int( i ) );
      end loop;
    else
      datOut_tmp( 0 ) <= datIn_int( 0 );
      datOut_tmp( 8 ) <= '1';
      for i in 1 to 7 loop
        datOut_tmp( i ) <= datOut_tmp( i - 1 ) xor datIn_int( i );
      end loop;
    end if;
  end process;
  
  cntTmpProc:process( datOut_tmp ) is
  variable tmpSum : integer range 0 to 8;
  begin
    tmpSum:= 0;
    for i in 0 to 7 loop
      if ( datOut_tmp( i ) = '1' ) then
        tmpSum := tmpSum + 1;
      end if;
    end loop;
    
    sumTmp <= tmpSum;
    diffTmp <= tmpSum + tmpSum - 8;
  end process;
  
  outProc:process( datOut_tmp, sumTmp, diffTmp, disparity_prev,
                   dispEN_int, ctrl_int ) is
  begin
    if ( dispEN_int = '0' ) then
      disparity <= 0;
      case ctrl_int is
        when "00" =>
          datOut <= "1101010100";
        when "01" =>
          datOut <= "0010101011";
        when "10" =>
          datOut <= "0101010100";
        when others =>
          datOut <= "1010101011";
      end case;
    else
      if ( disparity_prev = 0 or sumTmp = 4 ) then
        if ( datOut_tmp( 8 ) = '0' ) then
          datOut( 9 ) <= '1';
          datOut( 8 ) <= '0';
          disparity <= disparity_prev - diffTmp;
          datOut( 7 downto 0 ) <= not( datOut_tmp( 7 downto 0 ) );
        else
          datOut( 9 ) <= '0';
          datOut( 8 ) <= '1';
          disparity <= disparity_prev + diffTmp;
          datOut( 7 downto 0 ) <= datOut_tmp( 7 downto 0 );
        end if;
      else
        if ( ( disparity_prev > 0 and sumTmp > 4 ) or
             ( disparity_prev < 0 and sumTmp < 4 ) ) then
          if ( datOut_tmp( 8 ) = '0' ) then
            datOut( 9 ) <= '1';
            datOut( 8 ) <= '0';
            disparity <= disparity_prev - diffTmp;
            datOut( 7 downto 0 ) <= not( datOut_tmp( 7 downto 0 ) );
          else
            datOut( 9 ) <= '1';
            datOut( 8 ) <= '1';
            disparity <= disparity_prev - diffTmp + 2;
            datOut( 7 downto 0 ) <= not( datOut_tmp( 7 downto 0 ) );
          end if;
        else
          if ( datOut_tmp( 8 ) = '0' ) then
            datOut( 9 ) <= '0';
            datOut( 8 ) <= '0';
            disparity <= disparity_prev + diffTmp -2;
            datOut( 7 downto 0 ) <= datOut_tmp( 7 downto 0 );
          else
            datOut( 9 ) <= '0';
            datOut( 8 ) <= '1';
            disparity <= disparity_prev + diffTmp;
            datOut( 7 downto 0 ) <= datOut_tmp( 7 downto 0 );
          end if;
        end if;
      end if;
    end if;
  
  end process;

end rtl;
