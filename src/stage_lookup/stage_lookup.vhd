LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity stage_lookup is
	port (
		clk			: in	std_logic;
		mem_data_in	: in	std_logic_vector(15 downto 0);
		mem_data_out: out	std_logic_vector(15 downto 0);
		rdest_in	: in	std_logic_vector(2 downto 0);
		rdest_out	: out	std_logic_vector(2 downto 0)
	);
end stage_lookup;


architecture Structure of stage_lookup is

begin
	mem_data_out <= mem_data_in;
	rdest_out <= rdest_in;

end Structure;