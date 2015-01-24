LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity control_unit is
	port (
		clk					: in	std_logic;
		boot				: in	std_logic;
		stall_vector		: out	std_logic_vector(11 downto 0);
		
		-- Fetch
		fetch_pc			: out	std_logic_vector(15 downto 0);
		-- TLB exception
		fetch_exception		: in	std_logic;
		-- Access cache or memory
		fetch_cache_mem		: out	std_logic;
		-- Physical addres obtained in previous miss
		fetch_memory_pc		: out	std_logic_vector(15 downto 0);
		
		-- Decode
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
		alu_opclass			: out	std_logic_vector(2 downto 0);
		alu_opcode			: out	std_logic_vector(1 downto 0);
		alu_w				: in	std_logic_vector(15 downto 0);
		alu_z				: in	std_logic;
		
		-- Data Lookup & TLB
		-- TLB exception
		dlookup_exception	: in	std_logic;
		-- Lookup
		dlookup				: out	std_logic;
		dlookup_load_store	: out	std_logic;
		dlookup_hit_miss	: in	std_logic;
		-- Write back
		dlookup_write_back	: in	std_logic;
		dlookup_wb_tag		: in	std_logic_vector(9 downto 0);
		
		-- Data Cache
		-- Cache mode
		dcache_mode_r_w		: out	std_logic;
		dcache_mode_c_m		: out	std_logic;
		-- Byte or word
		dcache_size_b_w		: out	std_logic;
		
		-- Bypasses control
		bypasses_ctrl_a		: out	std_logic_vector(3 downto 0); -- A, F1
		bypasses_ctrl_b		: out	std_logic_vector(3 downto 0); -- A, F1
		bypasses_ctrl_mem	: out	std_logic_vector(5 downto 0)  -- A, WB/L, C
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
	
	type reg_stages is array (11 downto 0) of reg_stages_entry;
	
	signal rstages				: reg_stages;
	signal decode_tmp_rstage	: reg_stages_entry;
	
	signal newPC	: std_logic_vector(15 downto 0);

	signal bypass_alu_ctrl_a	: std_logic_vector(1 downto 0);
	signal bypass_alu_ctrl_b	: std_logic_vector(1 downto 0);
	
	signal bypass_fop_ctrl_a	: std_logic_vector(1 downto 0);
	signal bypass_fop_ctrl_b	: std_logic_vector(1 downto 0);

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
		
		constant FOP1	: integer	:= 6;
		constant FOP2	: integer	:= 7;
		constant FOP3	: integer	:= 8;
		constant FOP4	: integer	:= 9;
		constant FOP5	: integer	:= 10;
		constant FOPWB	: integer	:= 11;
		
		constant EXC_VECTOR	: std_logic_vector(15 downto 0) := "0001000000000000";
		constant debug 		: std_logic_vector(15 downto 0) := "1010101010101010";
	
	-- Instruction decode signlas
		constant NOP	: integer := 0;
		constant MEM	: integer := 1;
		constant ART	: integer := 2;
		constant BNZ	: integer := 3;
		constant FOP	: integer := 4;
		
		signal opclass	: std_logic_vector(2 downto 0);
		signal opcode	: std_logic_vector(1 downto 0);
		signal immed	: std_logic_vector(15 downto 0); -- 8 for bnz, 5 for mem
		signal addr_d	: std_logic_vector(2 downto 0);
		signal addr_a	: std_logic_vector(2 downto 0);
		signal addr_b	: std_logic_vector(2 downto 0);
	
	signal ctrl_pc	: std_logic_vector(1 downto 0) := "00";
	signal ir		: std_logic_vector(15 downto 0);
	
	
	procedure feed_decode_stage(	signal rstages	: inout	reg_stages;
									signal tmp		: in reg_stages_entry) is
	begin
		rstages(DECODE).int 	<= tmp.int;
		rstages(DECODE).exc 	<= tmp.exc;
		rstages(DECODE).pc 		<= tmp.pc;
		rstages(DECODE).addr_d 	<= tmp.addr_d;
		rstages(DECODE).addr_a 	<= tmp.addr_a;
		rstages(DECODE).addr_b 	<= tmp.addr_b;
		rstages(DECODE).opclass <= tmp.opclass;
		rstages(DECODE).opcode 	<= tmp.opcode;
	end procedure;
	
	
	procedure move_stages_info(	signal rstages	: inout	reg_stages;
								variable src 	: in	integer;
								variable dest 	: in	integer) is
	begin
		rstages(dest).int 		<= rstages(src).int;
		rstages(dest).exc 		<= rstages(src).exc;
		rstages(dest).pc 		<= rstages(src).pc;
		rstages(dest).addr_d 	<= rstages(src).addr_d;
		rstages(dest).addr_a 	<= rstages(src).addr_a;
		rstages(dest).addr_b 	<= rstages(src).addr_b;
		rstages(dest).opclass 	<= rstages(src).opclass;
		rstages(dest).opcode 	<= rstages(src).opcode;
	end procedure;
	
	procedure do_pipeline_step ( signal rstages	: inout	reg_stages) is
		variable i	: integer := DECODE;
		variable j	: integer := ALU;
	begin
		while i < MEMWB loop
			move_stages_info(rstages, i, j);
			i := i+1;
			j := j+1;
		end loop;
		i := DECODE;
		j := FOP1;
		move_stages_info(rstages, i, j);
		i := FOP1;
		j := FOP2;
		while i < FOPWB loop
			move_stages_info(rstages, i, j);
			i := i+1;
			j := j+1;
		end loop;
	end procedure;
	
	function check_bypass(	rstages	: reg_stages;
							stage_c : integer;
							stage_p : integer;
							dest	: integer -- a=0, b=1, mem=2
							) return boolean is
		
		variable valid_op			: boolean := FALSE;
		variable reg_src_eq_dest	: boolean := FALSE;
		variable producer_produces	: boolean := FALSE;
		variable consumer_consumes	: boolean := FALSE;
		
		variable c_opclass			: integer;
		variable p_opclass			: integer;
		
		variable c_addr_a			: integer;
		variable c_addr_b			: integer;
		variable p_addr_d			: integer;
		variable c_store			: integer;
		variable p_store			: integer;
		
	begin
		c_opclass	:= to_integer(unsigned(rstages(stage_c).opclass));
		p_opclass	:= to_integer(unsigned(rstages(stage_p).opclass));
		
		c_addr_a	:= to_integer(unsigned(rstages(stage_c).addr_a));
		c_addr_b	:= to_integer(unsigned(rstages(stage_c).addr_b));
		p_addr_d	:= to_integer(unsigned(rstages(stage_p).addr_d));
		c_store		:= to_integer(unsigned(rstages(stage_c).opcode(1 downto 1)));
		p_store		:= to_integer(unsigned(rstages(stage_p).opcode(1 downto 1)));
		
		if c_opclass = 0 or p_opclass = 0 then
			valid_op := FALSE;
		else
			valid_op := TRUE;
		end if;
		

		if (dest = 0) then
			if c_addr_a = p_addr_d then reg_src_eq_dest := TRUE; else reg_src_eq_dest := FALSE; end if;
		elsif (dest = 1) then
			if c_addr_b = p_addr_d then reg_src_eq_dest := TRUE; else reg_src_eq_dest := FALSE; end if;
		elsif (dest = 2) then
			if c_addr_a = p_addr_d then reg_src_eq_dest := TRUE; else reg_src_eq_dest := FALSE; end if;
		end if;
		
		if (dest = 0) then
			if c_opclass = ART or c_opclass = FOP or (c_opclass = MEM and c_store = 1) then
				consumer_consumes :=  TRUE;
			else
				consumer_consumes :=  FALSE;
			end if;
		elsif (dest = 1) then
			if c_opclass = ART or c_opclass = FOP or c_opclass = BNZ or c_opclass = MEM then
				consumer_consumes :=  TRUE;
			else
				consumer_consumes :=  FALSE;
			end if;
		elsif (dest = 2) then
			if c_opclass = MEM and c_store = 1 then
				consumer_consumes :=  TRUE;
			else
				consumer_consumes :=  FALSE;
			end if;
		end if;
		
		if p_opclass = ART or p_opclass = FOP or (p_opclass = MEM and p_store = 0) then
			producer_produces :=  TRUE;
		else
			producer_produces :=  FALSE;
		end if;
		
		return(valid_op and reg_src_eq_dest and producer_produces and consumer_consumes);
		
	end function check_bypass; 
	
begin

	-- Instruction decode
		ir <= decode_ir;
		
		opclass	<= ir(15 downto 13);
		opcode	<= ir(12 downto 11);
		addr_a 	<= ir(5 downto 3);
		addr_b 	<= ir(2 downto 0);
		
		addr_d	<=	ir(5 downto 3)	when ir(15 downto 13) = MEM and	ir(12 downto 12) = "0" else 
					ir(8 downto 6)	when ir(15 downto 13) = ART or 	ir(15 downto 13) = FOP;
		
		with to_integer(unsigned(ir(15 downto 13))) select
			immed	<=	ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10 DOWNTO 6) 	when MEM,
						ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10 DOWNTO 3) 						when BNZ,
						debug	when others;
		
		decode_tmp_rstage.int		<= '0';
		decode_tmp_rstage.exc		<= '0';
		decode_tmp_rstage.pc		<= rstages(FETCH).pc; -- TODO revisit
		decode_tmp_rstage.addr_d	<= addr_d;
		decode_tmp_rstage.addr_a	<= addr_a;
		decode_tmp_rstage.addr_b	<= addr_b;
		decode_tmp_rstage.opclass	<= opclass;
		decode_tmp_rstage.opcode	<= opcode;

	
	-- Bypasses control 
		bypasses_ctrl_a(1 downto 0)		<= bypass_alu_ctrl_a;
		bypasses_ctrl_b(1 downto 0)		<= bypass_alu_ctrl_b;
		
		bypasses_ctrl_a(3 downto 2)		<= bypass_fop_ctrl_a;
		bypasses_ctrl_b(3 downto 2)		<= bypass_fop_ctrl_b;

		bypasses_ctrl_mem(1 downto 0)	<= bypass_alu_ctrl_mem;
		bypasses_ctrl_mem(3 downto 2)	<= bypass_lk_ctrl_mem;
		bypasses_ctrl_mem(5 downto 4)	<= bypass_ch_ctrl_mem;

		bypass_alu_ctrl_a <=	
					"11" when check_bypass(rstages, ALU, FOPWB, 0) else
					"10" when check_bypass(rstages, ALU, MEMWB, 0) else
					"01" when check_bypass(rstages, ALU, LOOKUP, 0) else
					"00"; -- no bypass

		bypass_alu_ctrl_b <=	
					"11" when check_bypass(rstages, ALU, FOPWB, 1) else
					"10" when check_bypass(rstages, ALU, MEMWB, 1) else
					"01" when check_bypass(rstages, ALU, LOOKUP, 1) else
					"00"; -- no bypass

		bypass_fop_ctrl_a <=	
					"11" when check_bypass(rstages, FOP1, FOPWB, 0) else
					"10" when check_bypass(rstages, FOP1, MEMWB, 0) else
					"01" when check_bypass(rstages, FOP1, LOOKUP, 0) else
					"00"; -- no bypass

		bypass_fop_ctrl_b <=	
					"11" when check_bypass(rstages, FOP1, FOPWB, 1) else
					"10" when check_bypass(rstages, FOP1, MEMWB, 1) else
					"01" when check_bypass(rstages, FOP1, LOOKUP, 1) else
					"00"; -- no bypass

		bypass_alu_ctrl_mem <=	
					"11" when check_bypass(rstages, ALU, FOPWB, 2) else
					"10" when check_bypass(rstages, ALU, MEMWB, 2) else
					"01" when check_bypass(rstages, ALU, LOOKUP, 2) else
					"00"; -- no bypass

		bypass_lk_ctrl_mem <=	
					"11" when check_bypass(rstages, LOOKUP, FOPWB, 2) else
					"10" when check_bypass(rstages, LOOKUP, MEMWB, 2) else
					"00"; -- no bypass
					

		bypass_ch_ctrl_mem <=	
					"11" when check_bypass(rstages, CACHE, FOPWB, 2) else
					"10" when check_bypass(rstages, CACHE, MEMWB, 2) else
					"00"; -- no bypass


	with ctrl_pc select
		newPC	<=	EXC_VECTOR									when "10",
					rstages(FETCH).pc+alu_w(15 downto 2)&"00"	when "01",
					rstages(FETCH).pc+4							when others;

	-- Fetch signals assignation
	fetch_pc	<=	rstages(FETCH).pc;
	
	process(clk)
	begin
		if (rising_edge(clk)) then
			if boot = '1' then
				rstages(FETCH).pc	<= "1100000000000000";
				-- inizialitation
			else
				rstages(FETCH).pc	<= newPC;
				feed_decode_stage(rstages, decode_tmp_rstage);
				do_pipeline_step(rstages);
			end if;
		end if;
	end process;



end Structure;

