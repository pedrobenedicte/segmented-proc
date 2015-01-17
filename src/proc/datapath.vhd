LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
USE ieee.std_logic_unsigned.all;

ENTITY datapath IS 

END datapath;


ARCHITECTURE Structure OF datapath IS

	COMPONENT stage_decode IS
		
	END COMPONENT;

	COMPONENT ff_decode_alu IS
		
	END COMPONENT;

BEGIN

	-- Stages and interconnection between stages
	d	:	stage_decode;
	ffd_a	:	ff_decode_alu;

END Structure;