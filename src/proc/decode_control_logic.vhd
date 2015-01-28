LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity decode_control_logic is
	port (
		ir		: in	std_logic_vector(15 downto 0);
		
		opclass	: out	std_logic_vector(2 downto 0);
		opcode	: out	std_logic_vector(1 downto 0);
		
		-- 8 for bnz, 5 for mem. SXT
		immed	: out	std_logic_vector(15 downto 0);
		addr_d	: out	std_logic_vector(2 downto 0);
		addr_a	: out	std_logic_vector(2 downto 0);
		addr_b	: out	std_logic_vector(2 downto 0)
	);
end decode_control_logic;

architecture Structure of decode_control_logic is

	-- Instruction decode signlas
	constant NOP	: integer := 0;
	constant MEM	: integer := 1;
	constant ART	: integer := 2;
	constant BNZ	: integer := 3;
	constant FOP	: integer := 4;
	constant zero	: std_logic_vector(15 downto 0) := "0000000000000000";
	constant debug 	: std_logic_vector(15 downto 0) := "1010101010101010";
	
begin

	-- Instruction decode
	opclass	<= ir(15 downto 13);
	opcode	<= ir(12 downto 11);
	addr_a 	<= ir(5 downto 3);
	addr_b 	<= ir(2 downto 0);
	
	addr_d	<=	ir(5 downto 3)	when ir(15 downto 13) = MEM and	ir(12 downto 12) = "0"	else 
				ir(8 downto 6)	when ir(15 downto 13) = ART or 	ir(15 downto 13) = FOP	else 
				"000";
	
	with to_integer(unsigned(ir(15 downto 13))) select
		immed	<=	ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10 DOWNTO 6) 	when MEM,
					ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10 DOWNTO 3) 						when BNZ,
					debug	when others;

end Structure;
