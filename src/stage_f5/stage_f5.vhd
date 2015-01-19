LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity stage_f5 is
	port (
		clk			: in	std_logic;
		rdest_in	: in	std_logic_vector(2 downto 0);
		rdest_out	: out	std_logic_vector(2 downto 0)
	);
end stage_f5;


architecture Structure of stage_f5 is

begin
	rdest_out <= rdest_in;

end Structure;
