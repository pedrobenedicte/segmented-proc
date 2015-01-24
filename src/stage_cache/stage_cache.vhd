LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity stage_cache is
	port (
		clk			: in	std_logic;
		stall		: in	std_logic;
		nop			: in	std_logic;
		
		-- flipflop inputs
		ff_addr_mem	: in	std_logic_vector(15 downto 0);
		ff_mem_data	: in	std_logic_vector(15 downto 0);
		
		-- Bypasses control and sources
		bp_ctrl_mem	: in	std_logic_vector(1 downto 0);
		bp_data_mwb	: in	std_logic_vector(15 downto 0);
		bp_data_fwb	: in	std_logic_vector(15 downto 0);
		
		-- Data memory
		dmem_we		: out	std_logic;
		dmem_addr	: out	std_logic_vector(15 downto 0);
		dmem_wr_data: out	std_logic_vector(63 downto 0);
		dmem_rd_data: in	std_logic_vector(63 downto 0);
		
		load_data	: out	std_logic_vector(15 downto 0)
	);
end stage_cache;


architecture Structure of stage_cache is

	constant debug		: std_logic_vector(15 downto 0) := "1010101010101010";
	signal addr_mem		: std_logic_vector(15 downto 0);
	signal mem_data_lk	: std_logic_vector(15 downto 0);
	signal mem_data		: std_logic_vector(15 downto 0);

begin

	with bp_ctrl_mem select
		mem_data	<=	mem_data_lk	when "00",
						bp_data_mwb	when "10",
						bp_data_fwb	when "11",
						debug		when others;


	process (clk)
	begin
		if (rising_edge(clk)) then
			if stall = '1' then
			elsif nop = '1' then
			else
				addr_mem 	<= ff_addr_mem;
				mem_data_lk	<= ff_mem_data;
			end if;
		end if;
	end process;
	
end Structure;