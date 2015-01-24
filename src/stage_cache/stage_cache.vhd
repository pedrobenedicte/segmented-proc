LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity stage_cache is
	port (
		clk			: in	std_logic;
		boot		: in	std_logic;
		stall		: in	std_logic;
		
		-- flipflop inputs
		ff_addr_mem	: in	std_logic_vector(15 downto 0);
		ff_mem_data	: in	std_logic_vector(15 downto 0);
		
		-- Bypasses control and sources
		bp_ctrl_mem	: in	std_logic_vector(1 downto 0);
		bp_data_mwb	: in	std_logic_vector(15 downto 0);
		bp_data_fwb	: in	std_logic_vector(15 downto 0);
		
		-- Data memory
		dmem_we		: out	std_logic;
		dmem_addr	: out	std_logic_vector(12 downto 0);
		dmem_wr_data: out	std_logic_vector(63 downto 0);
		dmem_rd_data: in	std_logic_vector(63 downto 0);
		
		-- Cache mode
		mode_r_w	: in	std_logic;
		mode_c_m	: in	std_logic;
		
		-- Byte or word
		size_b_w	: in	std_logic;
		
		load_data	: out	std_logic_vector(15 downto 0)
	);
end stage_cache;


architecture Structure of stage_cache is
	component cache_d is
		port (
			clk				: in std_logic;		-- clock
			boot			: in std_logic;		-- boot
			r_w				: in std_logic;		-- read or write
			cache_mem		: in std_logic;		-- access cache or memory
			b_w				: in std_logic;		-- byte access or word access
			add_physical	: in std_logic_vector(15 downto 0);
			
			memory_r_w		: out std_logic;
			memory_address	: out std_logic_vector(12 downto 0);
			memory_in		: in std_logic_vector(63 downto 0);
			memory_out		: out std_logic_vector(63 downto 0);
			
			data_in			: in std_logic_vector(15 downto 0);
			data_out		: out std_logic_vector(15 downto 0)
		);
	end component;
	
	constant debug		: std_logic_vector(15 downto 0) := "1010101010101010";
	signal addr_mem		: std_logic_vector(15 downto 0);
	signal mem_data_lk	: std_logic_vector(15 downto 0);
	signal mem_data		: std_logic_vector(15 downto 0);
	signal nread		: std_logic;
	
begin
	cache : cache_d
	port map (
		clk					=> clk,
		boot				=> boot,
		r_w					=> mode_r_w,
		cache_mem			=> mode_c_m,
		b_w					=> size_b_w,
		add_physical		=> ff_addr_mem,
		memory_r_w			=> nread,
		memory_address		=> dmem_addr,
		memory_in			=> dmem_rd_data,
		memory_out			=> dmem_wr_data,
		data_in				=> mem_data,
		data_out			=> load_data
	);

	dmem_we <= not nread;
	
	with bp_ctrl_mem select
		mem_data	<=	mem_data_lk	when "00",
						bp_data_mwb	when "10",
						bp_data_fwb	when "11",
						debug		when others;


	process (clk)
	begin
		if (rising_edge(clk)) then
			if not (stall = '1') then
				addr_mem 	<= ff_addr_mem;
				mem_data_lk	<= ff_mem_data;
			end if;
		end if;
	end process;
	
end Structure;
