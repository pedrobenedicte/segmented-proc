LIBRARY ieee;
USE ieee.std_logic_1164.all;

entity proc is
	port (
		clk          : in std_logic;
		boot         : in std_logic
		-- more to add
	);
end proc;


architecture Structure of proc is

	component datapath is
		port (
			clk          : in std_logic
		);
	end component;

	component control_unit is
	end component;

begin

	dp : datapath
	port map (
		clk 	=> clk
	);

end Structure;