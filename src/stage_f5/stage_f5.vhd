LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity stage_f5 is
	port (
		clk			: in	std_logic;
		stall		: in	std_logic;
		nop			: in	std_logic
	);
end stage_f5;


architecture Structure of stage_f5 is

begin

	process (clk)
	begin
		if (rising_edge(clk)) then
			if stall = '1' then
			elsif nop = '1' then
			else
				
			end if;
		end if;
	end process;

end Structure;
