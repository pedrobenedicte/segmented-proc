LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity stage_f1 is
	port (
		clk			: in	std_logic;
		stall		: in	std_logic;
		
		-- flipflop inputs
		ff_a		: in	std_logic_vector(15 downto 0);
		ff_b		: in	std_logic_vector(15 downto 0);
		
		-- Bypasses control and sources
		bp_ctrl_a	: in	std_logic_vector(1 downto 0);
		bp_ctrl_b	: in	std_logic_vector(1 downto 0);
		bp_data_awb	: in	std_logic_vector(15 downto 0);
		bp_data_mwb	: in	std_logic_vector(15 downto 0);
		bp_data_fwb	: in	std_logic_vector(15 downto 0);
		
		fop_data	: out	std_logic_vector(15 downto 0)
	);
end stage_f1;


architecture Structure of stage_f1 is

	signal a			: std_logic_vector(15 downto 0);
	signal b			: std_logic_vector(15 downto 0);
	
	signal selected_a	: std_logic_vector(15 downto 0);
	signal selected_b	: std_logic_vector(15 downto 0);

begin

	with bp_ctrl_a select
		selected_a	<=	a			when "00",
						bp_data_awb	when "01",
						bp_data_mwb	when "10",
						bp_data_fwb	when "11";

	with bp_ctrl_b select
		selected_b	<=	b			when "00",
						bp_data_awb	when "01",
						bp_data_mwb	when "10",
						bp_data_fwb	when "11";
	
	fop_data	<= selected_a+selected_b;

	process (clk)
	begin
		if (rising_edge(clk)) then
			if not (stall = '1') then
				a	<=	ff_a;
				b	<=	ff_b;
			end if;
		end if;
	end process;

end Structure;
