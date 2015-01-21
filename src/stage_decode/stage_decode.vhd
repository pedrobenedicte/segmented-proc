LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity stage_decode is
	port (
		clk			: in	std_logic;
		
		-- Value and addr of d to be written in Regfile.
		-- Also used as bypasses for a and b
		alu_d		: in	std_logic_vector(15 downto 0);
		mem_d		: in	std_logic_vector(15 downto 0);
		fop_d		: in	std_logic_vector(15 downto 0);
		alu_addr_d	: in	std_logic_vector(2 downto 0);
		mem_addr_d	: in	std_logic_vector(2 downto 0);
		fop_addr_d	: in	std_logic_vector(2 downto 0);
		
		addr_a		: in	std_logic_vector(2 downto 0);
		addr_b		: in	std_logic_vector(2 downto 0);
		a			: out	std_logic_vector(15 downto 0);
		b			: out	std_logic_vector(15 downto 0);
		
		wrd			: in	std_logic;						-- Regfile enable write
		ctrl_d		: in 	std_logic_vector(1 downto 0);	-- Select source for d write
		ctrl_immed	: in 	std_logic;						-- Select immed over a to use it
		immed		: in	std_logic_vector(15 downto 0);
		
		-- Bypasses control
		bypass_a	: in	std_logic_vector(1 downto 0);
		bypass_b	: in	std_logic_vector(1 downto 0);
		bypass_mem	: in	std_logic_vector(1 downto 0);
		
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
	signal a_regsource		:	std_logic_vector(15 downto 0);
	signal selected_b		:	std_logic_vector(15 downto 0);
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
		selected_d		<=	alu_d	when "00",
							mem_d	when "01",
							fop_d	when "10",
							debug	when others;
	with ctrl_d select	
		selected_addr_d	<=	alu_addr_d	when "00",
							mem_addr_d	when "01",
							fop_addr_d	when "10",
							"000"		when others;

	--Bypasses and immed routing
	with bypass_a select
		a_regsource	<=	rf_a	when "00",
						alu_d	when "01",
						mem_d	when "10",
						fop_d	when "11";
	
	with ctrl_immed select
		a	<=	a_regsource	when '0',
				immed		when '1';
	
	
	with bypass_b select
		b	<=	rf_b	when "00",
				alu_d	when "01",
				mem_d	when "10",
				fop_d	when "11";

	with bypass_mem select
		mem_data	<=	rf_a		when "00",
						alu_d	when "01",
						mem_d	when "10",
						fop_d	when "11";

end Structure;