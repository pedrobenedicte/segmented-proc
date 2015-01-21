library ieee;
use ieee.std_logic_1164.all;

entity test_tlb_d is
end test_tlb_d;

architecture behavior of test_tlb_d is
	component tlb_d is 
		port (	clk				: in std_logic;
				boot			: in std_logic;	
				we				: in std_logic;
				add_logical		: in std_logic_vector(15 downto 0);
				hit_miss		: out std_logic;
				add_physical	: out std_logic_vector(15 downto 0)
		);
	end component;
	
	-- Signals
	signal clock		: std_logic := '0';
	signal reset		: std_logic := '1';
	signal we			: std_logic := '1';
	signal n_exception 	: std_logic;
	signal addr_in		: std_logic_vector(15 downto 0) := "1111111111001001";
	signal add_out		: std_logic_vector(15 downto 0);

begin
	tlb : tlb_d
		port map (	clk				=> clock,
					boot			=> reset,
					we				=> we,
					add_logical		=> addr_in,
					hit_miss		=> n_exception,
					add_physical	=> add_out
		);

	clock <= not clock after 10 ns;
	reset <= '0' after 100 ns;

end behavior;
