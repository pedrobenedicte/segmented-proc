LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity datapath is 
	port (
		clk          : in std_logic
		-- more to add
	);
end datapath;


architecture Structure OF datapath is

	component stage_fetch is
		
	end component;

	component ff_fetch_decode is
		
	end component;

	
	component stage_decode is
	end component;

	component ff_decode_alu is
		
	end component;
	
	
	component stage_alu is
		
	end component;

	component ff_alu_lookup is
		
	end component;
	
	
	component stage_lookup is
		
	end component;

	component ff_lookup_cache is
		
	end component;

	
	component stage_cache is
		
	end component;

	component ff_cache_wb is
		
	end component;

	
	component stage_wb is
		
	end component;

	component ff_wb_f5 is
		
	end component;

	
	component stage_f5 is
		
	end component;

	component ff_f5_fwb is
		
	end component;
	
	
	component stage_fwb is
		
	end component;
	
begin

	fch		:	stage_fetch;
	fff_d	:	ff_fetch_decode;
	
	dec		:	stage_decode;
	ffd_a	:	ff_decode_alu;
	
	alu		:	stage_alu;
	ffa_lk	:	ff_alu_lookup;
	
	lk		:	stage_lookup;
	fflk_ch	:	ff_lookup_cache;
	
	ch		:	stage_cache;
	ffch_wb	:	ff_cache_wb;
	
	wb		:	stage_wb;
	ffwb_f5	:	ff_wb_f5;
	
	f5		:	stage_f5;
	fff5_fwb :	ff_f5_fwb;
	
	fwb		:	stage_fwb;

end Structure;