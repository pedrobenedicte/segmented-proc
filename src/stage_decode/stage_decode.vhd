LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity stage_decode is
	port (
		clk			: in	std_logic;
		wrd			: in	std_logic;
		alu_d		: in	std_logic_vector(15 downto 0);
		mem_d		: in	std_logic_vector(15 downto 0);
		fop_d		: in	std_logic_vector(15 downto 0);
		addr_a		: in	std_logic_vector(2 downto 0);
		addr_b		: in	std_logic_vector(2 downto 0);
		alu_addr_d	: in	std_logic_vector(2 downto 0);
		mem_addr_d	: in	std_logic_vector(2 downto 0);
		fop_addr_d	: in	std_logic_vector(2 downto 0);
		a			: out	std_logic_vector(15 downto 0);
		b			: out	std_logic_vector(15 downto 0);
		ctrl_d		: in 	std_logic_vector(1 downto 0);
		mem_data	: out	std_logic_vector(15 downto 0);
		rdest		: out	std_logic_vector(2 downto 0)	-- rdest of Alu/Mem instructions
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
		a		=> a,
		b 		=> b
	);

	with ctrl_d select
		selected_d		<=	alu_d	when "00",
							mem_d	when "01",
							fop_d	when "10",
							debug	when others;
	with ctrl_d select	
		selected_addr_d	<=	alu_addr_d	when "00",
							mem_addr_d	when "01",
							fop_addr_d	when "10",
							debug		when others;

	-- fed mem_data with op decode

end Structure;