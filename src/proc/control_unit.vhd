LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity control_unit is
	port (
		clk			: in	std_logic;
		ir			: in	std_logic_vector(15 downto 0);
		bp_alu_a	: out	std_logic_vector(1 downto 0);
		bp_alu_b	: out	std_logic_vector(1 downto 0);
		bp_dec_a	: out	std_logic_vector(1 downto 0);
		bp_dec_b	: out	std_logic_vector(1 downto 0)
	);
end control_unit;


architecture Structure of control_unit is
	type reg_stages_entry is record
		int		: std_logic;
		exc		: std_logic;
		pc		: std_logic_vector(15 downto 0);
		addr_d	: std_logic_vector(2 downto 0);
		addr_a	: std_logic_vector(2 downto 0);
		addr_b	: std_logic_vector(2 downto 0);
		opclass	: std_logic_vector(2 downto 0);
		opcode	: std_logic_vector(1 downto 0);
	end record;
	type reg_stages is array (7 downto 0) of reg_stages_entry;
	
	signal rstages : reg_stages;
	
	-- Instruction decode signas
		constant NOP	: std_logic_vector(2 downto 0) := "000";
		constant MEM	: std_logic_vector(2 downto 0) := "001";
		constant ART	: std_logic_vector(2 downto 0) := "010";
		constant BNZ	: std_logic_vector(2 downto 0) := "011";
		constant FOP	: std_logic_vector(2 downto 0) := "100";
		
		signal opclass	: std_logic_vector(2 downto 0);
		signal opcode	: std_logic_vector(1 downto 0);
		signal immed	: std_logic_vector(7 downto 0); -- 8 for bnz, 5 for mem
		signal addr_d	: std_logic_vector(2 downto 0);
		signal addr_a	: std_logic_vector(2 downto 0);
		signal addr_b	: std_logic_vector(2 downto 0);
	
	-- Bypasses signals
		signal bp_alu_a	: std_logic_vector(1 downto 0);
		signal bp_alu_b	: std_logic_vector(1 downto 0);

		signal bp_dec_a	: std_logic_vector(1 downto 0);
		signal bp_dec_b	: std_logic_vector(1 downto 0);
begin

	-- Instruction decode
		opclass	<= ir(15 downto 13);
		opcode	<= ir(12 downto 11);
		addr_a 	<= ir(5 downto 3);
		addr_b 	<= ir(2 downto 0);
		
		addr_d	<=	ir(5 downto 3)	when ir(15 downto 13) = MEM and	ir(12 downto 12) = "0" else 
					ir(8 downto 6)	when ir(15 downto 13) = ART or 	ir(15 downto 13) = FOP;
		
		with ir(15 downto 13) select
			immed	<=	"000"+ir(10 downto 6)	when MEM,
						ir(10 downto 3)			when BNZ;
	
	-- Bypasses
		
	
	
	
	process(clk)
	begin
		if (rising_edge(clk)) then
		
			-- move_stages (stall, nop)
			-- insert_new_pc (stall, nop)
		
		end if;
	end process;



end Structure;