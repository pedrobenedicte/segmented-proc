LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.proc_resources.all;

entity stage_lookup is
	port (
		clk				: in	std_logic;
		boot			: in	std_logic;
		stall			: in	std_logic;
		
		-- flipflop inputs
		ff_addr_mem			: in	std_logic_vector(15 downto 0);
		ff_mem_data			: in	std_logic_vector(15 downto 0);
		
		-- Bypasses control and sources
		bp_ctrl_mem			: in	std_logic_vector(1 downto 0);
		bp_data_mwb			: in	std_logic_vector(15 downto 0);
		bp_data_fwb			: in	std_logic_vector(15 downto 0);
		
		-- TLB exception
		lookup_exception	: out	std_logic;
		
		-- Lookup
		lookup				: in	std_logic;
		load_store			: in	std_logic;
		hit_miss			: out	std_logic;
		
		-- Write back
		write_back			: out	std_logic;
		wb_tag				: out	std_logic_vector(9 downto 0);
		
		aluwb				: out	std_logic_vector(15 downto 0);
		addr_mem			: out	std_logic_vector(15 downto 0);
		mem_data			: out	std_logic_vector(15 downto 0)
	);
end stage_lookup;


architecture Structure of stage_lookup is
	component tags_d is
		port (
			clk				: in std_logic;
			boot			: in std_logic;
			we				: in std_logic;
			read_write		: in std_logic;
			add_logical		: in std_logic_vector(15 downto 0);
			add_physical	: in std_logic_vector(15 downto 0);
			hit_miss		: out std_logic;
			wb				: out std_logic;
			wb_tag			: out std_logic_vector(9 downto 0)
		);
	end component;

	component tlb_d is
		port (
			clk				: in std_logic;
			boot			: in std_logic;
			we				: in std_logic;
			add_logical		: in std_logic_vector(15 downto 0);
			hit_miss		: out std_logic;
			add_physical	: out std_logic_vector(15 downto 0)
		);
	end component;
	
	signal addr_mem_logical	: std_logic_vector(15 downto 0);
	signal mem_data_inside	: std_logic_vector(15 downto 0);
	signal tlb_hit			: std_logic;
	signal address_tlb		: std_logic_vector(15 downto 0);
		
begin
	lookup_exception <= not tlb_hit;
	
	tags : tags_d 
		port map (
			clk				=> clk,
			boot			=> boot,
			we				=> lookup,
			read_write		=> load_store,
			add_logical		=> addr_mem_logical,
			add_physical	=> address_tlb,
			hit_miss		=> hit_miss,
			wb				=> write_back,
			wb_tag			=> wb_tag
		);

	tlb : tlb_d
		port map (
			clk				=> clk,
			boot			=> boot,
			we				=> lookup,
			add_logical		=> addr_mem_logical,
			hit_miss		=> tlb_hit,
			add_physical	=> address_tlb
		);
	
	with bp_ctrl_mem select
		mem_data	<=	mem_data_inside	when "00",
						bp_data_mwb		when "10",
						bp_data_fwb		when "11",
						debug			when others;

	addr_mem <= address_tlb;
	
	process (clk)
	begin
		if (rising_edge(clk)) then
			if boot = '1' then
				aluwb			<= zero;
				addr_mem_logical<= zero;
				mem_data_inside	<= zero;
			else
				if not (stall = '1') then
					aluwb			<= ff_addr_mem;
					addr_mem_logical<= ff_addr_mem;
					mem_data_inside	<= ff_mem_data;
				end if;
			end if;
		end if;
	end process;
	
end Structure;