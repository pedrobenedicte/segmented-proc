LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity ff_cache_wb is 
	port (
		clk			: in	std_logic;
		stall		: in	std_logic;
		nop			: in	std_logic;
		rdest_in	: in	std_logic_vector(2 downto 0);
		rdest_out	: out	std_logic_vector(2 downto 0)
	);
end ff_cache_wb;


architecture Structure of ff_cache_wb is

begin


end Structure;