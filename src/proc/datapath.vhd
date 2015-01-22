LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity datapath is 
	port (
		clk          : in std_logic
		
	);
end datapath;


architecture Structure OF datapath is

	component stage_fetch is
		port (
			clk			: in	std_logic;
			pc			: in	std_logic_vector(15 downto 0);
			ir			: out	std_logic_vector(15 downto 0)
		);
	end component;
	
	component stage_decode is
		port (
			clk			: in	std_logic;
			
			-- Value and addr of d to be written in Regfile.
			-- Also used as bypasses for a and b
			artm_d		: in	std_logic_vector(15 downto 0);
			mem_d		: in	std_logic_vector(15 downto 0);
			fop_d		: in	std_logic_vector(15 downto 0);
			artm_addr_d	: in	std_logic_vector(2 downto 0);
			mem_addr_d	: in	std_logic_vector(2 downto 0);
			fop_addr_d	: in	std_logic_vector(2 downto 0);
			
			addr_a		: in	std_logic_vector(2 downto 0);
			addr_b		: in	std_logic_vector(2 downto 0);
			a			: out	std_logic_vector(15 downto 0);
			b			: out	std_logic_vector(15 downto 0);
			
			wrd			: in	std_logic;						-- Regfile enable write
			ctrl_d		: in 	std_logic_vector(1 downto 0);	-- Select source for d write
			ctrl_immed	: in 	std_logic;						-- Select immed over a to use it
			immed		: in	std_logic_vector(15 downto 0);
			
			-- Bypasses control
			bypass_a	: in	std_logic_vector(1 downto 0);
			bypass_b	: in	std_logic_vector(1 downto 0);
			bypass_mem	: in	std_logic_vector(1 downto 0);
			
			mem_data	: out	std_logic_vector(15 downto 0)
		);
	end component;
	
	component stage_alu is
		
	end component;
	
	component stage_lookup is
		
	end component;
	
	component stage_cache is
		
	end component;
	
	component stage_wb is
		
	end component;
	
	component stage_f5 is
		
	end component;
	
	component stage_fwb is
		
	end component;
	
	signal d2ff_mem_data	: std_logic_vector(15 downto 0);
	
begin

	fch		: stage_fetch;
	port map (
		clk	=> clk,
		pc	=> ,
		ir	=> 
	);
	
	dec		: stage_decode;
	port map (
		clk			=> clk,
		artm_d		=> ,
		mem_d		=> ,
		fop_d		=> ,
		artm_addr_d	=> ,
		mem_addr_d	=> ,
		fop_addr_d	=> ,
		addr_a		=> ,
		addr_b		=> ,
		a			=> , 
		b			=> ,
		wrd			=> ,
		ctrl_d		=> ,
		ctrl_immed	=> ,
		immed		=> ,
		bypass_a	=> ,
		bypass_b	=> ,
		bypass_mem	=> ,
		mem_data	=> d2ff_mem_data
	);
	
	alu		: stage_alu;
	
	lk		: stage_lookup;
	
	ch		: stage_cache;
	
	wb		: stage_wb;
	
	f5		: stage_f5;
	
	fwb		: stage_fwb;

end Structure;