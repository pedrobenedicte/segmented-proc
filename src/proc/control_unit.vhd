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
		-- Hit or miss
		fetch_hit_miss		: in	std_logic;
		-- Physical addres obtained in previous miss
		fetch_real_address	: in	std_logic_vector(15 downto 0);
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
	
	type reg_stages is array (11 downto 2) of reg_stages_entry;
	
	signal rstages				: reg_stages;
	signal rstage_decode		: reg_stages_entry;
	
	signal regPC_fetch			: std_logic_vector(15 downto 0);
	signal newPC				: std_logic_vector(15 downto 0);
	signal stalls				: std_logic_vector(11 downto 0) := "000000000000";
	signal stall_struct_hrz		: std_logic_vector(11 downto 0) := "000000000000";
	signal stall_alu			: std_logic := '0';
	signal stall_mem			: std_logic	:= '0';
	
	signal jump					: std_logic	:= '0';
	
	signal clear_stage			: std_logic_vector(11 downto 0) := "000000000000";

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
		constant zero		: std_logic_vector(15 downto 0) := "0000000000000000";
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
	
	signal exc		: std_logic := '0';
	signal ir		: std_logic_vector(15 downto 0);
	
	procedure clear_pipeline ( signal rstages	: inout	reg_stages) is
		variable i	: integer := ALU;
	begin
		while i < FOPWB loop
			rstages(i).int 		<= '0';
			rstages(i).exc 		<= '0';
			rstages(i).pc 		<= zero;
			rstages(i).addr_d 	<= "000";
			rstages(i).addr_a 	<= "000";
			rstages(i).addr_b 	<= "000";
			rstages(i).opclass	<= "000";
			rstages(i).opcode 	<= "00";
			i := i+1;
		end loop;
	end procedure;
	
	procedure clear_rstage_entry(	signal rstages		: inout	reg_stages_entry) is
	begin
			rstages.int 	<= '0';
			rstages.exc 	<= '0';
			rstages.pc 		<= zero;
			rstages.addr_d 	<= "000";
			rstages.addr_a 	<= "000";
			rstages.addr_b 	<= "000";
			rstages.opclass <= "000";
			rstages.opcode 	<= "00";
	end procedure;
	
	procedure move_stages_info(	signal rstages	: inout	reg_stages;
								variable src 	: in	integer;
								variable dest 	: in	integer;
								signal stall	: in 	std_logic;
								signal clear	: in 	std_logic) is
	begin
		if stall = '0' and clear = '0' then
			rstages(dest).int 		<= rstages(src).int;
			rstages(dest).exc 		<= rstages(src).exc;
			rstages(dest).pc 		<= rstages(src).pc;
			rstages(dest).addr_d 	<= rstages(src).addr_d;
			rstages(dest).addr_a 	<= rstages(src).addr_a;
			rstages(dest).addr_b 	<= rstages(src).addr_b;
			rstages(dest).opclass 	<= rstages(src).opclass;
			rstages(dest).opcode 	<= rstages(src).opcode;
		elsif clear = '1' then
			rstages(dest).int 		<= '0';
			rstages(dest).exc 		<= '0';
			rstages(dest).pc 		<= zero;
			rstages(dest).addr_d 	<= "000";
			rstages(dest).addr_a 	<= "000";
			rstages(dest).addr_b	<= "000";
			rstages(dest).opclass	<= "000";
			rstages(dest).opcode 	<= "00";
		end if;
	end procedure;
	
	procedure move_decode_info(	signal rstages		: inout	reg_stages;
								signal rstage_decode: inout	reg_stages_entry;
								variable dest 		: in	integer;
								signal stall		: in 	std_logic;
								signal clear		: in 	std_logic) is
	begin
		if stall = '0' and clear = '0' then
			rstages(dest).int 		<= rstage_decode.int;
			rstages(dest).exc 		<= rstage_decode.exc;
			rstages(dest).pc 		<= rstage_decode.pc;
			rstages(dest).addr_d 	<= rstage_decode.addr_d;
			rstages(dest).addr_a 	<= rstage_decode.addr_a;
			rstages(dest).addr_b 	<= rstage_decode.addr_b;
			rstages(dest).opclass 	<= rstage_decode.opclass;
			rstages(dest).opcode 	<= rstage_decode.opcode;
		elsif clear = '1' then
			rstages(dest).int 		<= '0';
			rstages(dest).exc 		<= '0';
			rstages(dest).pc 		<= zero;
			rstages(dest).addr_d 	<= "000";
			rstages(dest).addr_a 	<= "000";
			rstages(dest).addr_b	<= "000";
			rstages(dest).opclass	<= "000";
			rstages(dest).opcode 	<= "00";
		end if;
	end procedure;
	
	procedure do_pipeline_step (signal rstages			: inout	reg_stages;
								signal rstage_decode	: inout	reg_stages_entry;
								signal stall			: in std_logic_vector(11 downto 0);
								signal clear			: in std_logic_vector(11 downto 0)) is
		variable i	: integer := ALU;
		variable j	: integer := LOOKUP;
	begin
		move_decode_info(rstages, rstage_decode, i, stall(i), clear(i));
		while i < MEMWB loop
			move_stages_info(rstages, i, j, stall(i), clear(i));
			i := i+1;
			j := j+1;
		end loop;
		
		i := FOP1;
		j := FOP2;
		move_decode_info(rstages, rstage_decode, i, stall(i), clear(i));
		while i < FOPWB loop
			move_stages_info(rstages, i, j, stall(i), clear(i));
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
	
	stall_struct_hrz(FETCH)	<= stall_alu or stall_mem;
	stall_struct_hrz(DECODE)<= stall_alu or stall_mem;
	
	stall_alu	<= '1'	when	(to_integer(unsigned(rstage_decode.opclass)) = ALU and
								to_integer(unsigned(rstages(LOOKUP).opclass)) = MEM) or
								(to_integer(unsigned(rstage_decode.opclass)) = ALU and
								to_integer(unsigned(rstages(FOP4).opclass)) = FOP)	else '0';
	
	stall_mem	<= '1'	when	to_integer(unsigned(rstage_decode.opclass)) = MEM and
								to_integer(unsigned(rstages(FOP3).opclass)) = FOP	else '0';
	
	
	-- FEED STAGES
	stall_vector		<= stalls;
	stalls				<= stall_struct_hrz;
	-- Decode
	decode_awb_addr_d	<= rstages(LOOKUP).addr_d;
	decode_mwb_addr_d	<= rstages(MEMWB).addr_d;
	decode_fwb_addr_d	<= rstages(FOPWB).addr_d;

	decode_addr_a		<= addr_a;
	decode_addr_b		<= addr_b;
	
	decode_wrd			<= '1'	when 	to_integer(unsigned(rstages(LOOKUP).opclass)) = ALU or				-- ADD
										(to_integer(unsigned(rstages(MEMWB).opclass)) = MEM and
										 to_integer(unsigned(rstages(MEMWB).opcode(1 downto 1))) = 0) or 	-- LOAD
										to_integer(unsigned(rstages(FOPWB).opclass)) = FOP	else '0';		-- FOP
	
	decode_ctrl_d		<= 	"00"	when to_integer(unsigned(rstages(LOOKUP).opclass)) = ALU else			-- ADD
							"01"	when to_integer(unsigned(rstages(MEMWB).opclass)) = MEM and
										 to_integer(unsigned(rstages(MEMWB).opcode(1 downto 1))) = 0 else 	-- LOAD
							"10"	when to_integer(unsigned(rstages(FOPWB).opclass)) = FOP else 			-- FOP
							"11";																			-- Nothing to write
	
	decode_ctrl_immed	<= 	'1'	when to_integer(unsigned(opclass)) = BNZ or to_integer(unsigned(opclass)) = MEM else '0';
	decode_immed		<= 	immed;
	
	-- Alu
	alu_opclass			<= rstages(ALU).opclass;
	alu_opcode			<= rstages(ALU).opcode;

	-- Instruction decode
		ir <= decode_ir;
		
		opclass	<= ir(15 downto 13);
		opcode	<= ir(12 downto 11);
		addr_a 	<= ir(5 downto 3);
		addr_b 	<= ir(2 downto 0);
		
		addr_d	<=	ir(5 downto 3)	when ir(15 downto 13) = MEM and	ir(12 downto 12) = "0" else 
					ir(8 downto 6)	when ir(15 downto 13) = ART or 	ir(15 downto 13) = FOP else "000";
		
		with to_integer(unsigned(ir(15 downto 13))) select
			immed	<=	ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10 DOWNTO 6) 	when MEM,
						ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10)&ir(10 DOWNTO 3) 						when BNZ,
						debug	when others;
		


	
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

	jump	<= '1'	when (to_integer(unsigned(rstages(ALU).opclass)) = BNZ) and alu_z = '1' else '0';
	clear_stage(FETCH)	<= jump;
	clear_stage(DECODE)	<= jump;
	
	newPC	<=	rstages(ALU).pc+alu_w	when (to_integer(unsigned(rstages(ALU).opclass)) = BNZ) and alu_z = '1' else
				EXC_VECTOR				when exc = '1' else
				regPC_fetch+2;

	-- Fetch signals assignation
	fetch_pc	<=	regPC_fetch;
	
	fetch_cache_mem <= '1';
	
	process(clk)
	begin
		if (rising_edge(clk)) then
			if boot = '1' then
				regPC_fetch	<= zero;
				rstage_decode.pc <= zero;
				clear_pipeline(rstages);
			else
				if stalls(FETCH) = '0' then
					regPC_fetch			<= newPC;
				end if;
				if stalls(DECODE) = '0' and clear_stage(DECODE) = '0' then
					rstage_decode.pc	<= regPC_fetch;
				elsif clear_stage(DECODE) = '1' then
					rstage_decode.pc 	<= zero;
				end if;
				do_pipeline_step(rstages, rstage_decode, stalls, clear_stage);
			end if;
		elsif (falling_edge(clk)) then
			if boot = '1' or clear_stage(DECODE) = '1' then
				rstage_decode.int		<= '0';
				rstage_decode.exc		<= '0';
				rstage_decode.addr_d	<= "000";
				rstage_decode.addr_a	<= "000";
				rstage_decode.addr_b	<= "000";
				rstage_decode.opclass	<= "000";
				rstage_decode.opcode	<= "00";
			else 
				rstage_decode.int		<= '0';
				rstage_decode.exc		<= '0';
				rstage_decode.addr_d	<= addr_d;
				rstage_decode.addr_a	<= addr_a;
				rstage_decode.addr_b	<= addr_b;
				rstage_decode.opclass	<= opclass;
				rstage_decode.opcode	<= opcode;
			end if;
		end if;
		
	end process;



end Structure;

