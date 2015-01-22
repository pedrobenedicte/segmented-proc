LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;

entity control_unit is
	port (
		clk			: in	std_logic;
		ir			: in	std_logic_vector(15 downto 0);
		bp_alu_a	: out	std_logic_vector(1 downto 0);
		bp_alu_b	: out	std_logic_vector(1 downto 0);
		bp_dec_a	: out	std_logic_vector(1 downto 0);
		bp_dec_b	: out	std_logic_vector(1 downto 0);
		
		-- Signals to/from fetch
		fetch_pc			: out	std_logic_vector(15 downto 0);
		
		-- Signals to/from decode
		decode_ir			: out	std_logic_vector(15 downto 0);
		
		decode_artm_addr_d	: out	std_logic_vector(2 downto 0);
		decode_mem_addr_d	: out	std_logic_vector(2 downto 0);
		decode_fop_addr_d	: out	std_logic_vector(2 downto 0);
		
		decode_addr_a		: out	std_logic_vector(2 downto 0);
		decode_addr_b		: out	std_logic_vector(2 downto 0);
		decode_wrd			: out	std_logic;
		decode_ctrl_d		: out 	std_logic_vector(1 downto 0);
		decode_ctrl_immed	: out 	std_logic;
		decode_immed		: out	std_logic_vector(15 downto 0);
		
		-- Bypasses control
		decode_bypass_a		: out	std_logic_vector(1 downto 0);
		decode_bypass_b		: out	std_logic_vector(1 downto 0);
		decode_bypass_mem	: out	std_logic_vector(1 downto 0);
		
		
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
	type reg_stages is array (0 to 7) of reg_stages_entry;
	
	signal rstages	: reg_stages;
	
	signal newPC	: std_logic_vector(15 downto 0);
	
	-- Defines
		constant FETCH	: std_logic	:= '0';
		constant DECODE	: std_logic	:= '1';
		constant ALU	: std_logic	:= '2';
		constant LOOKUP	: std_logic	:= '3';
		constant CACHE	: std_logic	:= '4';
		constant MEMWB	: std_logic	:= '5';
		constant F5		: std_logic	:= '6';
		constant FOPWB	: std_logic	:= '7';
		constant EXCVECTOR	: std_logic_vector(15 downto 0) := "0001000000000000";
	
	-- Instruction decode signlas
		constant NOP	: std_logic_vector(2 downto 0) := "000";
		constant MEM	: std_logic_vector(2 downto 0) := "001";
		constant ART	: std_logic_vector(2 downto 0) := "010";
		constant BNZ	: std_logic_vector(2 downto 0) := "011";
		constant FOP	: std_logic_vector(2 downto 0) := "100";
		
		signal opclass	: std_logic_vector(2 downto 0);
		signal opcode	: std_logic_vector(1 downto 0);
		signal immed	: std_logic_vector(15 downto 0); -- 8 for bnz, 5 for mem
		signal addr_d	: std_logic_vector(2 downto 0);
		signal addr_a	: std_logic_vector(2 downto 0);
		signal addr_b	: std_logic_vector(2 downto 0);
	
	signal ctrl_pc	: std_logic_vector(1 downto 0) := "00";
	
begin

	-- Instruction decode
		opclass	<= ir(15 downto 13);
		opcode	<= ir(12 downto 11);
		addr_a 	<= ir(5 downto 3);
		addr_b 	<= ir(2 downto 0);
		
		addr_d	<=	ir(5 downto 3)	when ir(15 downto 13) = MEM and	ir(12 downto 12) = "0" else 
					ir(8 downto 6)	when ir(15 downto 13) = ART or 	ir(15 downto 13) = FOP;
		
		with ir(15 downto 13) select
			immed	<=	SXT(ir(10 DOWNTO 6),immed'length) when MEM, -- TODO change to extend sign
						SXT(ir(10 DOWNTO 3),immed'length) when BNZ;
	
	
	with ctrl_pc select
		newPC	<=	rstages(FETCH).pc+4		when "00",
					rstages(FETCH).pc+jump	when "01",
					EXCVECTOR				when "10",
					rstages(FETCH).pc+4		when others;

	-- Fetch signals assignation
	fetch_pc	<=	rstages(FETCH).pc;
	
	
	process(clk)
	begin
		if (rising_edge(clk)) then
			if boot = '1' then
				rstages(FETCH).pc	<= "1100000000000000";
				-- inizialitation
			else
				-- if exception/interruption
				-- elsif branch
				-- else +4
				rstages(FETCH).pc	<= newPC;
			end if;
		end if;
	end process;



end Structure;