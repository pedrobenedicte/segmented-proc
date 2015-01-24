LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity stage_f2 is
	port (
		clk			: in	std_logic;
		stall		: in	std_logic;
		
		-- flipflop inputs
		ff_fop_data	: in	std_logic_vector(15 downto 0);
		
		fop_data	: out	std_logic_vector(15 downto 0)
	);
end stage_f2;


architecture Structure of stage_f2 is

begin

	process (clk)
	begin
		if (rising_edge(clk)) then
			if not (stall = '1') then
				fop_data 	<= ff_fop_data;
			end if;
		end if;
	end process;

end Structure;
