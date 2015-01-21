LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE IEEE.numeric_std.all;
USE ieee.std_logic_unsigned.all;

entity alu is
	port (
		x 			: in	std_logic_vector(15 downto 0);
		y			: in	std_logic_vector(15 downto 0);
		opclass		: in	std_logic_vector(2 downto 0);
		opcode		: in	std_logic_vector(1 downto 0);
		w			: out	std_logic_vector(15 downto 0);
		z			: out	std_logic
	);
end alu;


architecture Structure of alu is
	
	constant NOP	: std_logic_vector(2 downto 0) := "000";
	constant MEM	: std_logic_vector(2 downto 0) := "001";
	constant ART	: std_logic_vector(2 downto 0) := "010";
	constant BNZ	: std_logic_vector(2 downto 0) := "011";
	constant FOP	: std_logic_vector(2 downto 0) := "100";
	
	constant debug	: std_logic_vector(15 downto 0) := "1010101010101010";
	signal wLogAritm: std_logic_vector(15 downto 0);
	signal wMem		: std_logic_vector(15 downto 0);
	
begin
	
	z <= BOOLEAN_TO_STD_LOGIC(SIGNED(y)=0);
	
	with opclass select
		w <=	0			when NOP,
				wMem		when MEM,
				wLogAritm	when ART,
				0			when BNZ,
				0			when FOP,
				debug		when others;
	
	with opcode select
		wLogAritm	<=	x+y		when "00",
						x-y		when "01",
						"000000000000000"&BOOLEAN_TO_STD_LOGIC(SIGNED(x)=SIGNED(y))			when "10",
						debug	when others;
	wMem <= x+y;
  
end Structure;