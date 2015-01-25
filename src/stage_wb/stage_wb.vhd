LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity stage_wb is
	port (
		clk			: in	std_logic;
		boot		: in	std_logic;
		stall		: in	std_logic;
		
		-- flipflop inputs
		ff_load_data: in	std_logic_vector(15 downto 0);
		
		load_data	: out	std_logic_vector(15 downto 0)
	);
end stage_wb;


architecture Structure of stage_wb is

	constant zero		: std_logic_vector(15 downto 0) := "0000000000000000";

begin

	process (clk)
	begin
		if (rising_edge(clk)) then
			if boot = '1' then
				load_data	<= zero;
			else 
				if not (stall = '1') then
					load_data 	<= ff_load_data;
				end if;
			end if;
		end if;
	end process;
	
end Structure;
