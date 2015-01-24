LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity stage_fetch is
	port (
		clk				: in	std_logic;
		boot			: in	std_logic;
		stall			: in	std_logic;
		
		imem_addr		: out	std_logic_vector(15 downto 0);
		imem_rd_data	: in	std_logic_vector(63 downto 0);
		
		-- no flipflop, pc comes from a flipflop
		pc				: in	std_logic_vector(15 downto 0);
		ir				: out	std_logic_vector(15 downto 0)
	);
end stage_fetch;


architecture Structure of stage_fetch is

	
begin


end Structure;