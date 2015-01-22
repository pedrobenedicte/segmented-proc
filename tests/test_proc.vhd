LIBRARY ieee;
USE ieee.std_logic_1164.all;

entity test_proc is


end test_proc;


architecture Structure of test_proc is

	component memory is
		port (
			clk          : in std_logic;
			addr         : in std_logic_vector(15 downto 0);
			wr_data      : in std_logic_vector(15 downto 0);
			rd_data      : out std_logic_vector(15 downto 0);
			we           : in std_logic;
			byte_m       : in std_logic;
			boot         : in std_logic
		);
	end component;
	
	component proc is
		port (
			clk          : in std_logic;
			boot         : in std_logic
		);
	end component;

	signal clk			: std_logic := '0';
	signal reset_mem	: std_logic := '0';
	signal reset_proc	: std_logic := '0';
	
	signal addr         : std_logic_vector(15 downto 0);
	signal wr_data      : std_logic_vector(15 downto 0);
	signal rd_data      : std_logic_vector(15 downto 0);
	signal we           : std_logic;
	signal byte_m       : std_logic;

begin

	mem0 : memory
	port map (
		clk 	=> clk,
		boot 	=> reset_mem,
		addr	=> addr,
		wr_data	=> wr_data,
		rd_data	=> rd_data,
		we		=> we,
		byte_m	=> byte_m
	);

	soc : proc
	port map (
		clk 	=> clk,
		boot 	=> reset_proc
		-- more to do
	);



	clk <= not clk after 10 ns;
	reset_mem <= '1' after 15 ns, '0' after 50 ns;
	reset_proc <= '1' after 25 ns, '0' after 320 ns;

end Structure;