LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity datapath is 

end datapath;


architecture Structure OF datapath is

	component stage_decode is
		
	end component;

	component ff_decode_alu is
		
	end component;

begin

	-- Stages and interconnection between stages
	d	:	stage_decode;
	ffd_a	:	ff_decode_alu;

end Structure;