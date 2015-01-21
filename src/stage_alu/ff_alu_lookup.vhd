LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity ff_alu_lookup is 
	port (
		clk			: in	std_logic;
		stall		: in	std_logic;
		nop			: in	std_logic;
		mem_data_in	: in	std_logic_vector(15 downto 0);
		mem_data_out: out	std_logic_vector(15 downto 0)
	);
end ff_alu_lookup;


architecture Structure of ff_alu_lookup is

begin


end Structure;