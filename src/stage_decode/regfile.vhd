LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

ENTITY regfile IS
	PORT (	
		clk		: IN	STD_LOGIC;
		boot	: in	std_logic;
		wrd		: IN	STD_LOGIC;
		d 		: IN 	STD_LOGIC_VECTOR(15 DOWNTO 0);
		addr_a	: IN	STD_LOGIC_VECTOR(2 DOWNTO 0);
		addr_b	: IN	STD_LOGIC_VECTOR(2 DOWNTO 0);
		addr_d	: IN	STD_LOGIC_VECTOR(2 DOWNTO 0);
		a		: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0);
		b		: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END regfile;


architecture Structure OF regfile IS
	TYPE REGS IS ARRAY (7 DOWNTO 0) OF STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL br : REGS;
BEGIN
	a <= br(to_integer(unsigned(addr_a)));
	b <= br(to_integer(unsigned(addr_b)));
	
	PROCESS (clk)
	BEGIN
		IF (falling_edge(clk)) THEN
			IF boot = '1' THEN
				br(0) <= "0000000000000001";
				br(1) <= "0000000000000010";
				br(2) <= "0000000000000100";
				br(3) <= "0000000000001000";
				br(4) <= "0000000000010000";
				br(5) <= "0000000000100000";
				br(6) <= "0000000001000000";
				br(7) <= "0000000000000000";
			ELSE 
				IF wrd = '1' THEN
					br(to_integer(unsigned(addr_d))) <= d;
				END IF;
			END IF;
		END IF;
	END PROCESS;
	
END Structure;
