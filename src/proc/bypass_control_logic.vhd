library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.proc_resources.all;

entity bypass_control_logic is
	port (
		rstages				: in	reg_stages;
		
		-- Bypasses control
		bypasses_ctrl_a		: out	std_logic_vector(3 downto 0); -- A, F1
		bypasses_ctrl_b		: out	std_logic_vector(3 downto 0); -- A, F1
		bypasses_ctrl_mem	: out	std_logic_vector(5 downto 0)  -- A, WB/L, C
	);
end bypass_control_logic;

architecture Structure of bypass_control_logic is

	signal bypass_alu_ctrl_a	: std_logic_vector(1 downto 0);
	signal bypass_alu_ctrl_b	: std_logic_vector(1 downto 0);
	
	signal bypass_fop_ctrl_a	: std_logic_vector(1 downto 0);
	signal bypass_fop_ctrl_b	: std_logic_vector(1 downto 0);

	signal bypass_alu_ctrl_mem	: std_logic_vector(1 downto 0);
	signal bypass_lk_ctrl_mem	: std_logic_vector(1 downto 0);
	signal bypass_ch_ctrl_mem	: std_logic_vector(1 downto 0);

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
		
		if c_opclass = NOP or p_opclass = NOP then
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

	-- Bypasses assignation
	bypasses_ctrl_a(1 downto 0)		<= bypass_alu_ctrl_a;
	bypasses_ctrl_b(1 downto 0)		<= bypass_alu_ctrl_b;

	bypasses_ctrl_a(3 downto 2)		<= bypass_fop_ctrl_a;
	bypasses_ctrl_b(3 downto 2)		<= bypass_fop_ctrl_b;

	bypasses_ctrl_mem(1 downto 0)	<= bypass_alu_ctrl_mem;
	bypasses_ctrl_mem(3 downto 2)	<= bypass_lk_ctrl_mem;
	bypasses_ctrl_mem(5 downto 4)	<= bypass_ch_ctrl_mem;

	-- Bypasses control selection
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
	
end Structure;
