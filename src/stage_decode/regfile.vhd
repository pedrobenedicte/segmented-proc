LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

ENTITY regfile IS
	PORT (clk		: IN	STD_LOGIC;
			wrd		: IN	STD_LOGIC;
			d 			: IN 	STD_LOGIC_VECTOR(31 DOWNTO 0);
			addr_a	: IN	STD_LOGIC_VECTOR(3 DOWNTO 0);
			addr_b	: IN	STD_LOGIC_VECTOR(3 DOWNTO 0);
			addr_d	: IN	STD_LOGIC_VECTOR(3 DOWNTO 0);
			a			: OUT	STD_LOGIC_VECTOR(31 DOWNTO 0);
			b			: OUT	STD_LOGIC_VECTOR(31 DOWNTO 0));
END regfile;


ARCHITECTURE Structure OF regfile IS
	TYPE REGS IS ARRAY (15 DOWNTO 0) OF STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL br : REGS;
BEGIN
	a <= br(to_integer(unsigned(addr_a)));
	b <= br(to_integer(unsigned(addr_b)));
	
	PROCESS (clk)
	BEGIN
		IF (rising_edge(clk)) THEN
			IF wrd = '1' THEN
				br(to_integer(unsigned(addr_d))) <= d;
			END IF;
		END IF;
	END PROCESS;
	
END Structure;