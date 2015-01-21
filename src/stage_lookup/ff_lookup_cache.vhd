LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity ff_lookup_cache is 
	port (
		clk			: in	std_logic;
		stall		: in	std_logic;
		nop			: in	std_logic;
		mem_data_in	: in	std_logic_vector(15 downto 0);
		mem_data_out: out	std_logic_vector(15 downto 0);
		rdest_in	: in	std_logic_vector(2 downto 0);
		rdest_out	: out	std_logic_vector(2 downto 0)
	);
end ff_lookup_cache;


architecture Structure of ff_lookup_cache is

begin


end Structure;