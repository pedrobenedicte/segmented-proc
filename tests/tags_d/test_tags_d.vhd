library ieee;
use ieee.std_logic_1164.all;

entity test_tags_d is
end test_tags_d;

architecture behavior of test_tags_d is
	component tags_d is 
		port (	clk				: in std_logic;
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
	
	-- Signals
	signal clock		: std_logic := '0';
	signal reset		: std_logic := '1';
	signal we			: std_logic := '1';
	signal rw			: std_logic := '0';
	signal hit 			: std_logic;
	signal addr_in		: std_logic_vector(15 downto 0) := "1111111111001000";
	signal phys_in		: std_logic_vector(15 downto 0) := "1010101010000000";
	signal tag_out		: std_logic_vector(9 downto 0);
	signal wb			: std_logic;

begin
	tag : tags_d
		port map (	clk				=> clock,
					boot			=> reset,
					we				=> we,
					read_write		=> rw,
					add_logical		=> addr_in,
					add_physical	=> phys_in,
					hit_miss		=> hit,
					wb				=> wb,
					wb_tag			=> tag_out

		);

	clock <= not clock after 10 ns;
	reset <= '0' after 100 ns;

end behavior;
