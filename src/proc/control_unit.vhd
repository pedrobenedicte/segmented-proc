LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;

entity control_unit is
	port (
		clk					: in	std_logic;
		boot				: in	std_logic;
		base_stall_vector	: out	std_logic_vector(5 downto 0);
		base_nop_vector		: out	std_logic_vector(5 downto 1);
		fop_stall_vector	: out	std_logic_vector(7 downto 2);
		fop_nop_vector		: out	std_logic_vector(7 downto 2);
		
		-- Fetch
		fetch_pc			: out	std_logic_vector(15 downto 0);
		
		-- Decode
		decode_opclass		: out	std_logic_vector(2 downto 0);
		decode_opcode		: out	std_logic_vector(1 downto 0);
		
		decode_awb_addr_d	: out	std_logic_vector(2 downto 0);
		decode_mwb_addr_d	: out	std_logic_vector(2 downto 0);
		decode_fwb_addr_d	: out	std_logic_vector(2 downto 0);
		
		decode_addr_a		: out	std_logic_vector(2 downto 0);
		decode_addr_b		: out	std_logic_vector(2 downto 0);
		
		decode_wrd			: out	std_logic;
		decode_ctrl_d		: out	std_logic_vector(1 downto 0);
		decode_ctrl_immed	: out	std_logic;
		decode_immed		: out	std_logic_vector(15 downto 0);
		
		decode_ir			: in	std_logic_vector(15 downto 0);
		
		-- Alu
		alu_w				: in	std_logic_vector(15 downto 0);
		alu_z				: in	std_logic;
		
		-- Lookup
		-- Data tlb
		we_dtlb				: out 	std_logic;
		hit_miss_dtlb		: in	std_logic;

		-- Data tags cache
		we_dtags			: out 	std_logic;
		read_write_dtags	: out 	std_logic;
		hit_miss_dtags		: in	std_logic;
		wb_dtags			: in	std_logic;
		
		-- Bypasses control
		bypasses_ctrl_a		: out	std_logic_vector(3 downto 0); -- D, A
		bypasses_ctrl_b		: out	std_logic_vector(3 downto 0); -- D, A
		bypasses_ctrl_mem	: out	std_logic_vector(7 downto 0)  -- D, A, WB/L, C
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
	
	type base_reg_stages is array (5 downto 0) of reg_stages_entry;
	type fop_reg_stages is array (7 downto 2) of reg_stages_entry;
	
	signal base_rstages	: base_reg_stages;
	signal fop_rstages	: fop_reg_stages;
	
	signal newPC	: std_logic_vector(15 downto 0);

	signal bypass_dec_ctrl_a	: std_logic_vector(1 downto 0);
	signal bypass_alu_ctrl_a	: std_logic_vector(1 downto 0);
	signal bypass_dec_ctrl_b	: std_logic_vector(1 downto 0);
	signal bypass_alu_ctrl_b	: std_logic_vector(1 downto 0);

	signal bypass_dec_ctrl_mem	: std_logic_vector(1 downto 0);
	signal bypass_alu_ctrl_mem	: std_logic_vector(1 downto 0);
	signal bypass_lk_ctrl_mem	: std_logic_vector(1 downto 0);
	signal bypass_ch_ctrl_mem	: std_logic_vector(1 downto 0);
	
	-- Defines
		constant FETCH	: integer	:= 0;
		constant DECODE	: integer	:= 1;
		constant ALU	: integer	:= 2;
		constant LOOKUP	: integer	:= 3;
		constant CACHE	: integer	:= 4;
		constant MEMWB	: integer	:= 5;
		
		constant FOP1	: integer	:= 2;
		constant FOP2	: integer	:= 3;
		constant FOP3	: integer	:= 4;
		constant FOP4	: integer	:= 5;
		constant FOP5	: integer	:= 6;
		constant FOPWB	: integer	:= 7;
		
		constant EXC_VECTOR	: std_logic_vector(15 downto 0) := "0001000000000000";
		constant debug 		: std_logic_vector(15 downto 0) := "1010101010101010";
	
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
	signal ir		: std_logic_vector(15 downto 0);
	
begin
	
	-- Bypasses control
	bypasses_ctrl_a(1 downto 0)	<= bypass_dec_ctrl_a;
	bypasses_ctrl_a(3 downto 2)	<= bypass_alu_ctrl_a;
	bypasses_ctrl_b(1 downto 0)	<= bypass_dec_ctrl_b;
	bypasses_ctrl_b(3 downto 2)	<= bypass_alu_ctrl_b;

	bypass_ctrl_mem(1 downto 0)	<= bypass_dec_ctrl_mem;
	bypass_ctrl_mem(3 downto 2)	<= bypass_alu_ctrl_mem;
	bypass_ctrl_mem(5 downto 4)	<= bypass_lk_ctrl_mem;
	bypass_ctrl_mem(7 downto 6)	<= bypass_ch_ctrl_mem;

	-- check_bypass
	-- reg(dec).ra = regf(fopwb).rdest
	-- regf(fopbw) <> STORE
	-- reg(dec) op uses a


	bypass_dec_ctrl_a <=	"11" when check_bypass(DECODE, FOPWB, 0) else
				"10" when check_bypass(DECODE, MEMWB, 0) else
				"01" when check_bypass(DECODE, ALU, 0) else
				"00";

	bypass_alu_ctrl_a <=	"11" when check_bypass(ALU, FOPWB, 0) else
				"10" when check_bypass(ALU, MEMWB, 0) else
				"01" when check_bypass(ALU, ALU, 0) else
				"00";

	bypass_dec_ctrl_b <=	"11" when check_bypass(DECODE, FOPWB, 1) else
				"10" when check_bypass(DECODE, MEMWB, 1) else
				"01" when check_bypass(DECODE, ALU, 1) else
				"00";

	bypass_alu_ctrl_b <=	"11" when check_bypass(ALU, FOPWB, 1) else
				"10" when check_bypass(ALU, MEMWB, 1) else
				"01" when check_bypass(ALU, ALU, 1) else
				"00";


	ir <= decode_ir;

	-- Instruction decode
		opclass	<= ir(15 downto 13);
		opcode	<= ir(12 downto 11);
		addr_a 	<= ir(5 downto 3);
		addr_b 	<= ir(2 downto 0);
		
		addr_d	<=	ir(5 downto 3)	when ir(15 downto 13) = MEM and	ir(12 downto 12) = "0" else 
					ir(8 downto 6)	when ir(15 downto 13) = ART or 	ir(15 downto 13) = FOP;
		
		with ir(15 downto 13) select
			immed	<=	SXT(ir(10 DOWNTO 6),immed'length) when MEM,
						SXT(ir(10 DOWNTO 3),immed'length) when BNZ,
						debug	when others;
	
	--with ctrl_pc select
	--	newPC	<=	base_rstages(FETCH).pc+4		when "00",
	--				base_rstages(FETCH).pc+jump	when "01",
	--				EXC_VECTOR				when "10",
	--				base_rstages(FETCH).pc+4		when others;

	-- Fetch signals assignation
	fetch_pc	<=	base_rstages(FETCH).pc;
	
	
	process(clk)
	begin
		if (rising_edge(clk)) then
			if boot = '1' then
				base_rstages(FETCH).pc	<= "1100000000000000";
				-- inizialitation
			else
				-- if exception/interruption
				-- elsif branch
				-- else +4
				base_rstages(FETCH).pc	<= newPC;
			end if;
		end if;
	end process;



end Structure;
