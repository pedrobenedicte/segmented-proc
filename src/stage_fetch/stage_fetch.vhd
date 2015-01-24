LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity stage_fetch is
	port (
		clk				: in	std_logic;
		boot			: in	std_logic;
		stall			: in	std_logic;
		
		imem_addr		: out	std_logic_vector(15 downto 0);
		imem_rd_data	: in	std_logic_vector(63 downto 0);
	
		-- TLB exception
		fetch_exception	: out	std_logic;
		
		-- Access cache or memory
		cache_mem		: in	std_logic;
		
		-- Hit or miss
		hit_miss		: out	std_logic;
		
		-- Physical addres obtained in previous miss
		memory_pc		: in	std_logic_vector(15 downto 0);
		
		-- no flipflop, pc comes from a flipflop
		pc				: in	std_logic_vector(15 downto 0);
		ir				: out	std_logic_vector(15 downto 0)
	);
end stage_fetch;


architecture Structure of stage_fetch is
	component tags_i is
		port (
			clk				: in std_logic;
			boot			: in std_logic;
			we				: in std_logic;
			add_logical		: in std_logic_vector(15 downto 0);
			add_physical	: in std_logic_vector(15 downto 0);
			hit_miss		: out std_logic
		);
	end component;
	
	component tlb_i is
		port (
			clk				: in std_logic;
			boot			: in std_logic;
			we				: in std_logic;
			add_logical		: in std_logic_vector(15 downto 0);
			hit_miss		: out std_logic;
			add_physical	: out std_logic_vector(15 downto 0)
		);
	end component;
	
	component cache_i is
		port (
			clk				: in std_logic;		-- clock
			boot			: in std_logic;		-- boot
			cache_mem		: in std_logic;		-- access cache or memory
			add_physical	: in std_logic_vector(15 downto 0);
			memory_address	: out std_logic_vector(12 downto 0);
			memory_in		: in std_logic_vector(63 downto 0);
			data_out		: out std_logic_vector(15 downto 0)
		);
	end component;
	
	signal cache_add		: std_logic_vector(15 downto 0);
	signal addess_tlb		: std_logic_vector(15 downto 0);
	signal addess_tag		: std_logic_vector(15 downto 0);
	signal tlb_hit			: std_logic;
	signal tag_hit			: std_logic;
	signal u_a_tlb			: integer;
	signal u_a_tag			: integer;

begin
	tags : tags_i
		port map (
			clk				=> clk,
			boot			=> boot,
			we				=> cache_mem,
			add_logical		=> pc,
			add_physical	=> addess_tag,
			hit_miss		=> tag_hit
		);
		
	tlb : tlb_i
		port map (
			clk				=> clk,
			boot			=> boot,
			we				=> cache_mem,
			add_logical		=> pc,
			hit_miss		=> tlb_hit,
			add_physical	=> addess_tlb
		);
		
	cache : cache_i
		port map (
			clk				=> clk,
			boot			=> boot,
			cache_mem		=> cache_mem,
			add_physical	=> cache_add,
			memory_address	=> imem_addr(15 downto 3),
			memory_in		=> imem_rd_data,
			data_out		=> ir
		);
	
	fetch_exception <= not tlb_hit;
	
	imem_addr(2 downto 0) <= "000";
	
	u_a_tlb <= to_integer(unsigned(addess_tlb));
	u_a_tag <= to_integer(unsigned(addess_tag));

	hit_miss	<= '1' when ((tag_hit = '1') and (u_a_tlb = u_a_tag))
				else '0';
	cache_add	<= pc when (cache_mem = '0')
				else memory_pc;
	
end Structure;