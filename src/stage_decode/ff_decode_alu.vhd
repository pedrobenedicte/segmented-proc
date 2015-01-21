LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity ff_decode_alu is 
	port (
		clk			: in	std_logic;
		stall		: in	std_logic;
		nop			: in	std_logic;
		a_in		: in	std_logic_vector(15 downto 0);
		a_out		: out	std_logic_vector(15 downto 0);
		b_in		: in	std_logic_vector(15 downto 0);
		b_out		: out	std_logic_vector(15 downto 0);
		mem_data_in	: in	std_logic_vector(15 downto 0);
		mem_data_out: out	std_logic_vector(15 downto 0)
	);
end ff_decode_alu;


architecture Structure of ff_decode_alu is

begin

	process (clk)
	begin
		if (rising_edge(clk)) then
			if stall = '1' then
			elsif nop = '1' then 
			else
				a_out <= a_in;
				b_out <= b_in;
				mem_data_out <= mem_data_in;
			end if;
		end if;
	end process;




end Structure;