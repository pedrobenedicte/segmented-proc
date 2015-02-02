library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;

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


end proc_resources;

package body proc_resources is

	-- Functions behaviour

end proc_resources;
