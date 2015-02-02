library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.proc_resources.all;

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

	component decode_control_logic is
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
	end component;
	
	component bypass_control_logic is
		port (
			rstages				: in	reg_stages;
			
			-- Bypasses control
			bypasses_ctrl_a		: out	std_logic_vector(3 downto 0); -- A, F1
			bypasses_ctrl_b		: out	std_logic_vector(3 downto 0); -- A, F1
			bypasses_ctrl_mem	: out	std_logic_vector(5 downto 0)  -- A, WB/L, C
		);
	end component;


	signal rstages				: reg_stages;
	signal rstage_decode		: reg_stages_entry;
	
	signal regPC_fetch			: std_logic_vector(15 downto 0);
	signal regPC_decode			: std_logic_vector(15 downto 0);
	signal newPC				: std_logic_vector(15 downto 0);
	signal stalls				: std_logic_vector(11 downto 0) := "000000000000";
	
	constant EXC_VECTOR	: std_logic_vector(15 downto 0) := "0001000000000000";
	
	signal opclass	: std_logic_vector(2 downto 0);
	signal opcode	: std_logic_vector(1 downto 0);
	signal immed	: std_logic_vector(15 downto 0); -- 8 for bnz, 5 for mem
	signal addr_d	: std_logic_vector(2 downto 0);
	signal addr_a	: std_logic_vector(2 downto 0);
	signal addr_b	: std_logic_vector(2 downto 0);
	
	signal exc		: std_logic := '0';
	
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
	
	procedure move_decode_info(	signal rstages		: inout	reg_stages;
								signal rstage_decode: inout	reg_stages_entry;
								variable dest 		: in	integer) is
	begin
		rstages(dest).int 		<= rstage_decode.int;
		rstages(dest).exc 		<= rstage_decode.exc;
		rstages(dest).pc 		<= rstage_decode.pc;
		rstages(dest).addr_d 	<= rstage_decode.addr_d;
		rstages(dest).addr_a 	<= rstage_decode.addr_a;
		rstages(dest).addr_b 	<= rstage_decode.addr_b;
		rstages(dest).opclass 	<= rstage_decode.opclass;
		rstages(dest).opcode 	<= rstage_decode.opcode;
	end procedure;
	
	procedure do_pipeline_step (signal rstages			: inout	reg_stages;
								signal rstage_decode	: inout	reg_stages_entry) is
		variable i	: integer := ALU;
		variable j	: integer := LOOKUP;
	begin
		move_decode_info(rstages, rstage_decode, i);
		while i < MEMWB loop
			move_stages_info(rstages, i, j);
			i := i+1;
			j := j+1;
		end loop;
		
		i := FOP1;
		j := FOP2;
		move_decode_info(rstages, rstage_decode, i);
		while i < FOPWB loop
			move_stages_info(rstages, i, j);
			i := i+1;
			j := j+1;
		end loop;
	end procedure;
	
begin

	dcl : decode_control_logic
	port map (
		ir		=> decode_ir,
		
		opclass	=> opclass,
		opcode	=> opcode,
		
		-- 8 for bnz, 5 for mem. SXT
		immed	=> immed,
		addr_d	=> addr_d,
		addr_a	=> addr_a,
		addr_b	=> addr_b
	);
	
	bcl : bypass_control_logic
	port map (
		rstages				=> rstages,
		bypasses_ctrl_a		=> bypasses_ctrl_a,
		bypasses_ctrl_b		=> bypasses_ctrl_b,
		bypasses_ctrl_mem	=> bypasses_ctrl_mem
	);
	
	-- FEED STAGES
	stall_vector		<= stalls;
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
	
	-- Fetch signals assignation
	fetch_pc	<=	regPC_fetch;

	newPC	<=	rstages(ALU).pc+alu_w	when (to_integer(unsigned(rstages(ALU).opclass)) = BNZ) and alu_z = '1' else
				EXC_VECTOR				when exc = '1' else
				regPC_fetch+2;	
	
	fetch_cache_mem <= '1';
	
	rstage_decode.int		<= '0';
	rstage_decode.exc		<= '0';
	rstage_decode.pc 		<= regPC_decode;
	rstage_decode.addr_d	<= addr_d;
	rstage_decode.addr_a	<= addr_a;
	rstage_decode.addr_b	<= addr_b;
	rstage_decode.opclass	<= opclass;
	rstage_decode.opcode	<= opcode;
	
	process(clk)
	begin
		if (rising_edge(clk)) then
			if boot = '1' then
				regPC_fetch		<= zero;
				regPC_decode 	<= zero;
				clear_pipeline(rstages);
			else
				regPC_fetch		<= newPC;
				regPC_decode	<= regPC_fetch;
				do_pipeline_step(rstages, rstage_decode);
			end if;
		end if;
	end process;



end Structure;
