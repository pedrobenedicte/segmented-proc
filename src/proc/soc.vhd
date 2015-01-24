LIBRARY ieee;
USE ieee.std_logic_1164.all;

entity soc is

end soc;


architecture Structure of soc is

	component proc is
		port (
			clk				: in std_logic;
			boot			: in std_logic;
			
			-- Instructions memory
			imem_we			: out	std_logic;
			imem_addr		: out	std_logic_vector(15 downto 0);
			imem_wr_data	: out	std_logic_vector(63 downto 0);
			imem_rd_data	: in	std_logic_vector(63 downto 0);
			
			-- Data memory
			dmem_we			: out	std_logic;
			dmem_addr		: out	std_logic_vector(15 downto 0);
			dmem_wr_data	: out	std_logic_vector(63 downto 0);
			dmem_rd_data	: in	std_logic_vector(63 downto 0)
		);
	end component;

	component memory is
		port (
			clk		: in	std_logic;
			boot	: in	std_logic;
			addr	: in	std_logic_vector(15 downto 0);
			wr_data	: in	std_logic_vector(63 downto 0);
			rd_data	: out	std_logic_vector(63 downto 0);
			we		: in	std_logic;
			imem	: in	std_logic
		);
	end component;
	
	signal clk			: std_logic;
	signal reset_proc	: std_logic;
	signal reset_ram	: std_logic;
	
	signal imem_we		: std_logic;
	signal imem_addr	: std_logic_vector(15 downto 0);
	signal imem_wr_data	: std_logic_vector(63 downto 0);
	signal imem_rd_data	: std_logic_vector(63 downto 0);
	
	signal dmem_we		: std_logic;
	signal dmem_addr	: std_logic_vector(15 downto 0);
	signal dmem_wr_data	: std_logic_vector(63 downto 0);
	signal dmem_rd_data	: std_logic_vector(63 downto 0);
	
begin

	p : proc
	port map (
		clk				=> clk,
		boot			=> reset_proc,
		
		-- Instructions memory
		imem_we			=> imem_we,
		imem_addr		=> imem_addr,
		imem_wr_data	=> imem_wr_data,
		imem_rd_data	=> imem_rd_data,
		
		-- Data memory
		dmem_we			=> dmem_we,
		dmem_addr		=> dmem_addr,
		dmem_wr_data	=> dmem_wr_data,
		dmem_rd_data	=> dmem_rd_data
	);
	
	imem : memory
	port map (
		clk				=> clk,
		boot			=> reset_ram,
		addr			=> imem_addr,
		wr_data			=> imem_wr_data,
		rd_data			=> imem_rd_data,
		we				=> imem_we,
		imem			=> '1'
	);
	
	dmem : memory
	port map (
		clk				=> clk,
		boot			=> reset_ram,
		addr			=> dmem_addr,
		wr_data			=> dmem_wr_data,
		rd_data			=> dmem_rd_data,
		we				=> dmem_we,
		imem			=> '0'
	);

	clk <= not clk after 10 ns;
	reset_ram <= '1' after 15 ns, '0' after 50 ns;
	reset_proc <= '1' after 25 ns, '0' after 320 ns;

	
end Structure;