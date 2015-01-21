LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity stage_alu is
	port (
		clk			: in	std_logic;
		a			: in	std_logic_vector(15 downto 0);
		b			: in	std_logic_vector(15 downto 0);
		opclass		: in 	std_logic_vector(2 downto 0);
		opcode		: in	std_logic_vector(1 downto 0);
		w			: out	std_logic_vector(15 downto 0);
		
		-- Bypasses control and sources
		bypass_a	: in	std_logic_vector(1 downto 0);
		bypass_b	: in	std_logic_vector(1 downto 0);
		bypass_mem	: in	std_logic_vector(1 downto 0);
		bp_awb		: in	std_logic_vector(15 downto 0);
		bp_mwb		: in	std_logic_vector(15 downto 0);
		bp_fwb		: in	std_logic_vector(15 downto 0);
		
		mem_data_in	: in	std_logic_vector(15 downto 0);
		mem_data_out: out	std_logic_vector(15 downto 0)
	);
end stage_alu;


architecture Structure of stage_alu is

	component alu is
		PORT (	
		x 			: IN	STD_LOGIC_VECTOR(15 DOWNTO 0);
		y			: IN	STD_LOGIC_VECTOR(15 DOWNTO 0);
		opclass		: IN	STD_LOGIC_VECTOR(2 DOWNTO 0);
		opcode		: IN	STD_LOGIC_VECTOR(1 DOWNTO 0);
		w			: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0);
		z			: OUT	STD_LOGIC
	);
	end component;

	signal selected_a		: std_logic_vector(15 downto 0);
	signal selected_b		: std_logic_vector(15 downto 0);
	signal z				: std_logic;
	
	
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
	with bypass_a select
		selected_a	<=	a		when "00",
						bp_awb	when "01",
						bp_mwb	when "10",
						bp_fwb	when "11";
	
	with bypass_b select
		selected_b	<=	b		when "00",
						bp_awb	when "01",
						bp_mwb	when "10",
						bp_fwb	when "11";

	with bypass_mem select
		mem_data_out	<=	mem_data_in	when "00",
							bp_awb		when "01",
							bp_mwb		when "10",
							bp_fwb		when "11";

end Structure;