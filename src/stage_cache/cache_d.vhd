library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity cache_d is
	port (
		clk				: in std_logic;		-- clock
		boot				: in std_logic;		-- boot
		enable			: in std_logic;		-- do something or not
		r_w				: in std_logic;		-- read or write
		cache_mem		: in std_logic;		-- access cache or memory
		b_w				: in std_logic;		-- byte access or word access
		add_physical	: in std_logic_vector(15 downto 0);
		
		memory_request	: out std_logic;
		memory_r_w		: out std_logic;
		memory_address	: out std_logic_vector(12 downto 0);
		memory_in		: in std_logic_vector(63 downto 0);
		memory_out		: out std_logic_vector(63 downto 0);
		
		data_out			: out std_logic_vector(15 downto 0)
	);
end entity;

architecture Structure of cache_d is
	signal page		: std_logical_vector(9 downto 0);
	signal index	: std_logical_vector(2 downto 0);
	signal offset	: std_logical_vector(2 downto 0);
	
	-- 8 lines, 64b each line
	-- 512b cache size
	type cache_table is array (7 downto 0) of std_logic_vector(63 downto 0);
	signal cache : cache_table;

	-- Initialize Cache_d from file cache_d.txt
	procedure Load_Cache_Data (signal data : inout cache_table) is
		-- Open File in Read Mode
		file cache_file	:text open read_mode is "cache_d.txt";
		variable lbuf	:line;
		variable i		:integer := 0;
		variable fdata	:std_logic_vector (20 downto 0);
	begin
		while not endfile(cache_file) loop
			-- read data from input file
			readline(cache_file, lbuf);
			read(lbuf, fdata);
			data(i) <= fdata;
			i := i+1;
		end loop;
	end procedure;
	
begin
	page		<= add_physical(15 downto 6);
	index		<= add_physical(5 downto 3);
	offset	<= add_physical(2 downto 0);
	
	process (clk)
	begin
		if (clk'event and clk = '0') then
			if (boot = '1') then
				Load_Cache_Data(cache);
			else
				if (enable = '1') then
					if (r_w = '1') then
						if (cache_mem = '1') then			-- load from cache
							memory_request	<= '0';
							
						else										-- load from memory
							memory_request	<= '1';
							memory_r_w		<= '1';
							memory_address	<= page & index;
							cache()()		<= memory_in;
						end if;
					else
						if (cache_mem = '1') then			-- store to cache
							memory_request <= '0';
							
							
						else										-- store to memory
							memory_request	<= '1';
							memory_r_w		<= '0';
							memory_address	<= page & index;
							memory_out		<= cache()();
						end if;
					end if;
				end if;
			end if;
		else
			memory_request <= '0';
		end if;
	end process;
			
end Structure;
