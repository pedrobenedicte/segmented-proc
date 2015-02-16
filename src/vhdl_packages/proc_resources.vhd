library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package proc_resources is

	type reg_stages_entry is record
		int			: std_logic;
		exc			: std_logic;
		pc			: std_logic_vector(15 downto 0);
		addr_d		: std_logic_vector(2 downto 0);
		addr_a		: std_logic_vector(2 downto 0);
		addr_b		: std_logic_vector(2 downto 0);
		opclass		: std_logic_vector(2 downto 0);
		opcode		: std_logic_vector(1 downto 0);
	end record;

	type reg_stages is array (11 downto 2) of reg_stages_entry;

	-- Defines
	constant FETCH		: integer := 0;
	constant DECODE		: integer := 1;
	constant ALU		: integer := 2;
	constant LOOKUP		: integer := 3;
	constant CACHE		: integer := 4;
	constant MEMWB		: integer := 5;
	
	constant FOP1		: integer := 6;
	constant FOP2		: integer := 7;
	constant FOP3		: integer := 8;
	constant FOP4		: integer := 9;
	constant FOP5		: integer := 10;
	constant FOPWB		: integer := 11;
	
	constant zero		: std_logic_vector(15 downto 0) := "0000000000000000";
	constant debug 		: std_logic_vector(15 downto 0) := "1101110010111010"; -- 0xDCBA

	-- Instruction OPCLASS signals
	constant NOP		: integer := 0;
	constant MEM		: integer := 1;
	constant ART		: integer := 2;
	constant BNZ		: integer := 3;
	constant FOP		: integer := 4;

	-- Functions headers
	procedure clear_stage 	  ( signal rstage			: out	reg_stages_entry);
	procedure clear_pipeline  (	signal rstages			: out	reg_stages);
	procedure move_stages_info(	signal rstage_dest		: out	reg_stages_entry;
								signal rstage_src		: in	reg_stages_entry;
								signal stall			: in 	std_logic;
								signal clear			: in 	std_logic);
	procedure do_pipeline_step(	signal rstages			: inout	reg_stages;
								signal rstage_decode	: in	reg_stages_entry;
								signal stalls			: in 	std_logic_vector(11 downto 0);
								signal clears			: in 	std_logic_vector(11 downto 0));

end proc_resources;

package body proc_resources is

	-- Functions behaviour
	
	procedure clear_stage ( signal rstage	: out	reg_stages_entry) is
	begin
		rstage.int 		<= '0';
		rstage.exc 		<= '0';
		rstage.pc 		<= zero;
		rstage.addr_d 	<= "000";
		rstage.addr_a 	<= "000";
		rstage.addr_b 	<= "000";
		rstage.opclass	<= "000";
		rstage.opcode 	<= "00";
	end procedure;
	
	procedure clear_pipeline ( signal rstages	: out	reg_stages) is
		variable i	: integer := ALU;
	begin
		while i <= FOPWB loop
			rstages(i).int 		<= '0';
			rstages(i).exc 		<= '0';
			rstages(i).pc 		<= zero;
			rstages(i).addr_d 	<= "000";
			rstages(i).addr_a 	<= "000";
			rstages(i).addr_b 	<= "000";
			rstages(i).opclass	<= "000";
			rstages(i).opcode	<= "00";
			i := i+1;
		end loop;
	end procedure;
	
	procedure move_stages_info(	signal rstage_dest	: out	reg_stages_entry;
								signal rstage_src	: in	reg_stages_entry;
								signal stall		: in 	std_logic;
								signal clear		: in 	std_logic) is
	begin
		if stall = '0' then
			if clear = '0' then
				rstage_dest.int 	<= rstage_src.int;
				rstage_dest.exc 	<= rstage_src.exc;
				rstage_dest.pc 		<= rstage_src.pc;
				rstage_dest.addr_d 	<= rstage_src.addr_d;
				rstage_dest.addr_a 	<= rstage_src.addr_a;
				rstage_dest.addr_b 	<= rstage_src.addr_b;
				rstage_dest.opclass <= rstage_src.opclass;
				rstage_dest.opcode 	<= rstage_src.opcode;
			else
				clear_stage(rstage_dest);
			end if;
		end if;
	end procedure;
	
	procedure do_pipeline_step (signal rstages			: inout	reg_stages;
								signal rstage_decode	: in	reg_stages_entry;
								signal stalls			: in 	std_logic_vector(11 downto 0);
								signal clears			: in 	std_logic_vector(11 downto 0)) is
	begin
		-- 	INFO:		 dest				src				stall_dest		clear_dest
		-- alu/mem pipeline
		move_stages_info(rstages(ALU), 		rstage_decode, 	stalls(ALU), 	clears(ALU));
		move_stages_info(rstages(LOOKUP),	rstages(ALU), 	stalls(LOOKUP), clears(LOOKUP));
		move_stages_info(rstages(CACHE),	rstages(LOOKUP),stalls(CACHE), 	clears(CACHE));
		move_stages_info(rstages(MEMWB),	rstages(CACHE),	stalls(MEMWB),	clears(MEMWB));
		
		-- fop pipeline
		move_stages_info(rstages(FOP1),		rstage_decode, 	stalls(FOP1), 	clears(FOP1));
		move_stages_info(rstages(FOP2), 	rstages(FOP1), 	stalls(FOP2), 	clears(FOP2));
		move_stages_info(rstages(FOP3), 	rstages(FOP2), 	stalls(FOP3), 	clears(FOP3));
		move_stages_info(rstages(FOP4), 	rstages(FOP3), 	stalls(FOP4), 	clears(FOP4));
		move_stages_info(rstages(FOP5), 	rstages(FOP4), 	stalls(FOP5), 	clears(FOP5));
		move_stages_info(rstages(FOPWB), 	rstages(FOP5), 	stalls(FOPWB),	clears(FOPWB));
	end procedure;

end proc_resources;
