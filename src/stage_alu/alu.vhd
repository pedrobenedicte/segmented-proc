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
	
	function BOOLEAN_TO_STD_LOGIC(L: BOOLEAN) return std_ulogic is
	begin
		if L then
			return('1');
		else
			return('0');
		end if;
	 end function BOOLEAN_TO_STD_LOGIC; 

	constant NOP	: std_logic_vector(2 downto 0) := "000";
	constant MEM	: std_logic_vector(2 downto 0) := "001";
	constant ART	: std_logic_vector(2 downto 0) := "010";
	constant BNZ	: std_logic_vector(2 downto 0) := "011";
	constant FOP	: std_logic_vector(2 downto 0) := "100";
	
	 
	 
	CONSTANT DEBUG : STD_LOGIC_VECTOR(15 DOWNTO 0) := "1010101010101010";
	SIGNAL wLogAritm : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL wComps : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL wMov : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL wExtAritm : STD_LOGIC_VECTOR(15 DOWNTO 0);
	
	SIGNAL SHL : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL SHA : STD_LOGIC_VECTOR(15 DOWNTO 0);
	
	-- Requerit per ModelSIM
	SIGNAL SMUL : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL USMUL : STD_LOGIC_VECTOR(31 DOWNTO 0);
	
BEGIN
	
	z <= BOOLEAN_TO_STD_LOGIC(SIGNED(y)=0);
  
	WITH y(4 DOWNTO 4) SELECT
		SHL <=	STD_LOGIC_VECTOR(SHIFT_LEFT(UNSIGNED(x),TO_INTEGER(UNSIGNED(y(4 DOWNTO 0))))) 	WHEN "0",
					STD_LOGIC_VECTOR(SHIFT_RIGHT(UNSIGNED(x),TO_INTEGER(UNSIGNED(not(y(4 DOWNTO 0))+1))))	WHEN "1",
					DEBUG																										WHEN others;
	
	WITH y(4 DOWNTO 4) SELECT
		SHA <=	STD_LOGIC_VECTOR(SHIFT_LEFT(SIGNED(x),TO_INTEGER(UNSIGNED(y(4 DOWNTO 0))))) 	WHEN "0",
					STD_LOGIC_VECTOR(SHIFT_RIGHT(SIGNED(x),TO_INTEGER(UNSIGNED(not(y(4 DOWNTO 0))+1)))) 	WHEN "1",
					DEBUG																									WHEN others;
	
	with opcode select
		wLogAritm	<=	x+y		when "00",
						x-y		when "01",
						debug	when others;
						
	
	WITH op SELECT
		wLogAritm <=	x and y		WHEN "000", -- AND
							x or y		WHEN "001", -- OR
							x xor y		WHEN "010", -- XOR
							not(x)		WHEN "011", -- NOT
							x+y			WHEN "100", -- ADD
							x-y			WHEN "101", -- SUB
							SHA			WHEN "110", -- SHA
							SHL			WHEN "111", -- SHL
							DEBUG			WHEN others;
							
	WITH op SELECT
		wComps <=	"000000000000000"&BOOLEAN_TO_STD_LOGIC(SIGNED(x)<SIGNED(y))			WHEN "000", -- CMPLT
						"000000000000000"&BOOLEAN_TO_STD_LOGIC(SIGNED(x)<=SIGNED(y))		WHEN "001", -- CMPLE
						"000000000000000"&BOOLEAN_TO_STD_LOGIC(SIGNED(x)=SIGNED(y))			WHEN "011", -- CMPEQ
						"000000000000000"&BOOLEAN_TO_STD_LOGIC(UNSIGNED(x)<UNSIGNED(y))	WHEN "100", -- CMPLTU
						"000000000000000"&BOOLEAN_TO_STD_LOGIC(UNSIGNED(x)<=UNSIGNED(y))	WHEN "101", -- CMPLEU
						DEBUG																					WHEN others;
	
	WITH op(0 DOWNTO 0) SELECT
		wMov <=  y										WHEN "0", -- MOVI
					y(7 DOWNTO 0)&x(7 DOWNTO 0)	WHEN "1", -- MOVHI
					DEBUG									WHEN others;
	
	-- Requerit per ModelSIM	
	SMUL <= STD_LOGIC_VECTOR(SIGNED(x)*SIGNED(y));
	USMUL <= STD_LOGIC_VECTOR(UNSIGNED(x)*UNSIGNED(y));
					
	WITH op SELECT
		wExtAritm <=	SMUL(15 DOWNTO 0)									WHEN "000", -- MUL
							SMUL(31 DOWNTO 16)								WHEN "001", -- MULH
							USMUL(31 DOWNTO 16)								WHEN "010", -- MULHU
							STD_LOGIC_VECTOR(SIGNED(x)/SIGNED(y))		WHEN "100", -- DIV
							STD_LOGIC_VECTOR(UNSIGNED(x)/UNSIGNED(y))	WHEN "101", -- DIVU
							DEBUG													WHEN others;
	
	WITH g_op SELECT
		w <=	wLogAritm	WHEN "0000", -- Op. Log i Artim
				wComps		WHEN "0001", -- Comps s/u
				x+y			WHEN "0010", -- ADDI
				x+y			WHEN "0011", -- LD
				x+y			WHEN "0100", -- ST
				wMov			WHEN "0101", -- MOVI/MOVHI
				wExtAritm	WHEN "1000", -- Ext. Aritm
				x+y			WHEN "1101", -- LDB
				x+y			WHEN "1110", -- STB
				x				WHEN "0110", -- BZ/BNZ
				x				WHEN "1010", -- JZ/JNZ/JMP/JAL
				x				WHEN "0111", -- IN/OUT
				DEBUG			WHEN others; -- DEBUG INFO
	
END Structure;