LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE IEEE.numeric_std.all;
USE ieee.std_logic_unsigned.all;

ENTITY alu IS
	PORT (	
		x 			: IN	STD_LOGIC_VECTOR(15 DOWNTO 0);
		y			: IN	STD_LOGIC_VECTOR(15 DOWNTO 0);
		opclass		: IN	STD_LOGIC_VECTOR(2 DOWNTO 0);
		opcode		: IN	STD_LOGIC_VECTOR(1 DOWNTO 0);
		w			: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0);
		z			: OUT	STD_LOGIC
	);
END alu;


ARCHITECTURE Structure OF alu IS
	
	constant NOP	: std_logic_vector(2 downto 0) := "000";
	constant MEM	: std_logic_vector(2 downto 0) := "001";
	constant ART	: std_logic_vector(2 downto 0) := "010";
	constant BNZ	: std_logic_vector(2 downto 0) := "011";
	constant FOP	: std_logic_vector(2 downto 0) := "100";
	constant debug	: STD_LOGIC_VECTOR(15 DOWNTO 0) := "1010101010101010";
	 
	SIGNAL wLogAritm : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL wMem 	: STD_LOGIC_VECTOR(15 DOWNTO 0);
	
BEGIN
	
	z <= BOOLEAN_TO_STD_LOGIC(SIGNED(y)=0);
	
	WITH opclass SELECT
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
  
END Structure;