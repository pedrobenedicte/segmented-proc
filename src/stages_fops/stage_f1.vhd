LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity stage_f1 is
	port (
		clk			: in	std_logic;
		stall		: in	std_logic;
		nop			: in	std_logic;
		
		-- flipflop inputs
		ff_a		: in	std_logic_vector(15 downto 0);
		ff_b		: in	std_logic_vector(15 downto 0);
		
		fop_data	: out	std_logic_vector(15 downto 0)
	);
end stage_f1;


architecture Structure of stage_f1 is

	signal a		: std_logic_vector(15 downto 0);
	signal b		: std_logic_vector(15 downto 0);

begin

	fop_data	<= a+b;

	process (clk)
	begin
		if (rising_edge(clk)) then
			if stall = '1' then
			elsif nop = '1' then
			else
				a	<=	ff_a;
				b	<=	ff_b;
			end if;
		end if;
	end process;

end Structure;
