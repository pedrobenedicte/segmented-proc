LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity stage_lookup is
	port (
		clk			: in	std_logic;
		stall		: in	std_logic;
		nop			: in	std_logic;
		
		-- flipflop inputs
		ff_addr_mem	: in	std_logic_vector(15 downto 0);
		ff_mem_data	: in	std_logic_vector(15 downto 0);
		
		-- Bypasses control and sources
		bypass_mem	: in	std_logic_vector(1 downto 0);
		bp_mwb		: in	std_logic_vector(15 downto 0);
		bp_fwb		: in	std_logic_vector(15 downto 0);
		
		mem_data_out: out	std_logic_vector(15 downto 0)
	);
end stage_lookup;


architecture Structure of stage_lookup is

	constant debug	: std_logic_vector(15 downto 0) := "1010101010101010";
	
	signal addr_mem	: std_logic_vector(15 downto 0);
	signal mem_data	: std_logic_vector(15 downto 0);
	

begin

	with bypass_mem select
		mem_data_out	<=	mem_data	when "00",
							bp_mwb		when "10",
							bp_fwb		when "11",
							debug		when others;

	process (clk)
	begin
		if (rising_edge(clk)) then
			if stall = '1' then
			elsif nop = '1' then 
			else
				addr_mem 	<= ff_addr_mem;
				mem_data	<= ff_mem_data;
			end if;
		end if;
	end process;
							
end Structure;