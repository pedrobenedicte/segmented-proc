LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity stage_decode is
	port (
		clk			: in	std_logic;
		stall		: in	std_logic;
		
		-- flipflop inputs
		ff_ir		: in	std_logic_vector(15 downto 0);
		
		-- Value and addr of d to be written in Regfile.
		-- Also used as bypasses for a and b
		artm_d		: in	std_logic_vector(15 downto 0);
		mem_d		: in	std_logic_vector(15 downto 0);
		fop_d		: in	std_logic_vector(15 downto 0);
		awb_addr_d	: in	std_logic_vector(2 downto 0);
		mwb_addr_d	: in	std_logic_vector(2 downto 0);
		fwb_addr_d	: in	std_logic_vector(2 downto 0);
		
		addr_a		: in	std_logic_vector(2 downto 0);
		addr_b		: in	std_logic_vector(2 downto 0);
		a			: out	std_logic_vector(15 downto 0);
		b			: out	std_logic_vector(15 downto 0);
		
		wrd			: in	std_logic;						-- Regfile enable write
		ctrl_d		: in 	std_logic_vector(1 downto 0);	-- Select source for d write
		ctrl_immed	: in	std_logic;						-- Select immed over a to use it
		immed		: in	std_logic_vector(15 downto 0);
		
		ir			: out	std_logic_vector(15 downto 0);
		mem_data	: out	std_logic_vector(15 downto 0)
	);
end stage_decode;


architecture Structure of stage_decode is

	component regfile is
		port (
			clk		: in	std_logic;
			wrd		: in	std_logic;
			d 		: in 	std_logic_vector(15 downto 0);
			addr_a	: in	std_logic_vector(2 downto 0);
			addr_b	: in	std_logic_vector(2 downto 0);
			addr_d	: in	std_logic_vector(2 downto 0);
			a		: out	std_logic_vector(15 downto 0);
			b		: out	std_logic_vector(15 downto 0)
		);
	end component;
	
	constant debug : std_logic_vector(15 downto 0) := "1010101010101010";

	signal rf_a				:	std_logic_vector(15 downto 0);
	signal rf_b				:	std_logic_vector(15 downto 0);
	signal selected_d		:	std_logic_vector(15 downto 0);
	signal selected_addr_d	:	std_logic_vector(2 downto 0);
	
begin

	br : regfile
	port map (
		clk 	=> clk,
		wrd 	=> wrd,
		d 		=> selected_d,
		addr_a 	=> addr_a,
		addr_b 	=> addr_b,
		addr_d 	=> selected_addr_d,
		a		=> rf_a,
		b 		=> rf_b
	);

	-- D writting data and addr routing
	with ctrl_d select
		selected_d		<=	artm_d	when "00",
							mem_d	when "01",
							fop_d	when "10",
							debug	when others;
	with ctrl_d select	
		selected_addr_d	<=	awb_addr_d	when "00",
							mwb_addr_d	when "01",
							fwb_addr_d	when "10",
							"000"		when others;

	
	with ctrl_immed select
		a	<=	rf_a	when '0',
				immed	when '1';
	
	b			<=	rf_b;
	mem_data	<=	rf_a;

	process (clk)
	begin
		if (rising_edge(clk)) then
			if not (stall = '1') then
				ir 	<= ff_ir;
			end if;
		end if;
	end process;

end Structure;