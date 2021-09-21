

----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:01:41 09/07/2021 
-- Design Name: 
-- Module Name:    Frequency_counter - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_arith.all;
entity Frequency_counter is
port(
	ref_clk, test_signal : in std_logic;
	start,reset : in std_logic;
	done : out std_logic;
	Dout : out std_logic_vector(15 downto 0)
);
end Frequency_counter;

architecture Behavioral of Frequency_counter is

constant RCR_MAX : integer range 0 to 99_999_999 := 99_999_999;
signal RCR :  integer range 0 to 99_999_999;
signal TSCR : integer range 0 to 65535;
signal clr_tscr : std_logic;
type states is (idle, measure, m_done, clr);
signal state : states := idle;

begin
process(ref_clk,reset)begin
if(reset = '0')then 
	state <= idle;
	done <= '0';
	dout <= "0000000000000000";
else
	if(falling_edge(ref_clk))then
		if (state = idle) then
			if(start = '0')then
				state <= measure;
			end if;

		elsif(state = measure)then	
			clr_tscr <= '0';
			if(RCR < RCR_MAX)then
				RCR <= RCR + 1;
			else
				RCR <= 0;
				state <= m_done;
			end if;
			
		elsif(state = m_done)then
			dout <= conv_std_logic_vector(TSCR,16);
			done <= '1';
			state <= clr;
			
		elsif(state = clr)then
			if(RCR < RCR_MAX/4)then				
				RCR <= RCR + 1;
				clr_tscr <= '1';
			else 
				done <= '0';
				RCR <= 0;
				state <= measure;
			end if;
			
		end if;
		
	end if;
end if;

end process;

process(test_signal, state,reset)begin

if reset = '0' or clr_tscr = '1' then
	TSCR <= 0;
else
	if(rising_edge(test_signal))then	
		if(state = measure)then
			TSCR <= TSCR + 1;
		end if;
	end if;
end if;


end process;
end Behavioral;

