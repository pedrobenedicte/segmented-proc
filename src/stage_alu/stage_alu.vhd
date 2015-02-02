LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.proc_resources.all;

entity stage_alu is
	port (
		clk			: in	std_logic;
		boot		: in	std_logic;
		stall		: in	std_logic;
		
		-- flipflop inputs
		ff_a		: in	std_logic_vector(15 downto 0);
		ff_b		: in	std_logic_vector(15 downto 0);
		ff_mem_data	: in	std_logic_vector(15 downto 0);
		
		opclass		: in 	std_logic_vector(2 downto 0);
		opcode		: in	std_logic_vector(1 downto 0);
		
		-- Bypasses control and sources
		bp_ctrl_a	: in	std_logic_vector(1 downto 0);
		bp_ctrl_b	: in	std_logic_vector(1 downto 0);
		bp_ctrl_mem	: in	std_logic_vector(1 downto 0);
		bp_data_awb	: in	std_logic_vector(15 downto 0);
		bp_data_mwb	: in	std_logic_vector(15 downto 0);
		bp_data_fwb	: in	std_logic_vector(15 downto 0);
		
		w			: out	std_logic_vector(15 downto 0);
		z			: out	std_logic;
		mem_data	: out	std_logic_vector(15 downto 0)
	);
end stage_alu;


architecture Structure of stage_alu is

	component alu is
		port (
		x 			: in	std_logic_vector(15 downto 0);
		y			: in	std_logic_vector(15 downto 0);
		opclass		: in	std_logic_vector(2 downto 0);
		opcode		: in	std_logic_vector(1 downto 0);
		w			: out	std_logic_vector(15 downto 0);
		z			: out	std_logic
	);
	end component;

	signal selected_a		: std_logic_vector(15 downto 0);
	signal selected_b		: std_logic_vector(15 downto 0);
	
	signal a				: std_logic_vector(15 downto 0);
	signal b				: std_logic_vector(15 downto 0);
	signal mem_data_inside	: std_logic_vector(15 downto 0);
	
begin

	alu0 :	alu
	Port Map( 	
		x			=> selected_a,
		y			=> selected_b,
		opclass		=> opclass,
		opcode		=> opcode,
		w			=> w,
		z			=> z
	);

	-- Bypasses
	with bp_ctrl_a select
		selected_a	<=	a			when "00",
						bp_data_awb	when "01",
						bp_data_mwb	when "10",
						bp_data_fwb	when "11",
						a			when others;
	
	with bp_ctrl_b select
		selected_b	<=	b			when "00",
						bp_data_awb	when "01",
						bp_data_mwb	when "10",
						bp_data_fwb	when "11",
						b			when others;
	
	with bp_ctrl_mem select
		mem_data	<=	mem_data_inside	when "00",
						bp_data_awb		when "01",
						bp_data_mwb		when "10",
						bp_data_fwb		when "11",
						mem_data_inside	when others;
	
	process (clk)
	begin
		if (rising_edge(clk)) then
			if boot = '1' then
				a 				<= zero;
				b				<= zero;
				mem_data_inside	<= zero;
			else
				if not (stall = '1') then
					a 				<= ff_a;
					b				<= ff_b;
					mem_data_inside	<= ff_mem_data;
				end if;
			end if;
		end if;
	end process;

end Structure;