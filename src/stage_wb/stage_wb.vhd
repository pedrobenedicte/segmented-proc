LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity stage_wb is
	port (
		clk			: in	std_logic;
		rdest_in	: in	std_logic_vector(2 downto 0);
		rdest_out	: out	std_logic_vector(2 downto 0)
	);
end stage_wb;


architecture Structure of stage_wb is

begin
	rdest_out <= rdest_in;

end Structure;
