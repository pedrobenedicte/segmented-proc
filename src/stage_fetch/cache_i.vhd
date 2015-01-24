library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity cache_d is
	port (
		clk				: in std_logic;		-- clock
		boot			: in std_logic;		-- boot
		r_w				: in std_logic;		-- read or write
		cache_mem		: in std_logic;		-- access cache or memory
		b_w				: in std_logic;		-- byte access or word access
		add_physical	: in std_logic_vector(15 downto 0);
		
		memory_r_w		: out std_logic;
		memory_address	: out std_logic_vector(12 downto 0);
		memory_in		: in std_logic_vector(63 downto 0);
		memory_out		: out std_logic_vector(63 downto 0);
		
		data_in			: in std_logic_vector(15 downto 0);
		data_out		: out std_logic_vector(15 downto 0)
	);
end entity;

architecture Structure of cache_d is
	signal page		: std_logic_vector(9 downto 0);
	signal index	: std_logic_vector(2 downto 0);
	signal offset	: std_logic_vector(2 downto 0);
	
	-- 8 lines, 64b each line
	-- 512b cache size
	type cache_line is array (7 downto 0) of std_logic_vector (7 downto 0);
	type cache_table is array (7 downto 0) of cache_line;
	signal cache : cache_table;

	-- Initialize Cache_d from file cache_d.txt
	procedure Load_Cache_Data (signal data : inout cache_table) is
		-- Open File in Read Mode
		file cache_file	:text open read_mode is "cache_d.txt";
		variable lbuf	:line;
		variable i		:integer := 0;
		variable fdata	:std_logic_vector (63 downto 0);
	begin
		while not endfile(cache_file) loop
			-- read data from input file
			readline(cache_file, lbuf);
			read(lbuf, fdata);
			data(i)(7) <= fdata(63 downto 56);
			data(i)(6) <= fdata(55 downto 48);
			data(i)(5) <= fdata(47 downto 40);
			data(i)(4) <= fdata(39 downto 32);
			data(i)(3) <= fdata(31 downto 24);
			data(i)(2) <= fdata(23 downto 16);
			data(i)(1) <= fdata(15 downto 8);
			data(i)(0) <= fdata(7 downto 0);
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
				memory_r_w	<= '1';
			else
				if (r_w = '1') then
					if (cache_mem = '1') then			-- load from cache
						memory_r_w	<= '1';
						data_out(7 downto 0) <= cache(index)(offset);
						if (b_w = '0') then
							data_out(15 downto 8) <= cache(index)(offset+"001");
						end if;
					else										-- load from memory
						memory_r_w	<= '1';
						memory_address	<= page & offset;
						cache(index)(offset)		<= memory_in(63 downto 56);
						cache(index)(offset+"001")	<= memory_in(55 downto 48);
						cache(index)(offset+"010")	<= memory_in(47 downto 40);
						cache(index)(offset+"011")	<= memory_in(39 downto 32);
						cache(index)(offset+"100")	<= memory_in(31 downto 24);
						cache(index)(offset+"101")	<= memory_in(23 downto 16);
						cache(index)(offset+"110")	<= memory_in(15 downto 8);
						cache(index)(offset+"111")	<= memory_in(7 downto 0);
					end if;
				else
					if (cache_mem = '1') then			-- store to cache
						memory_r_w <= '1';
						cache(index)(offset) <= data_out(7 downto 0);
						if (b_w = '0') then
							cache(index)(offset+"001") <= data_out(15 downto 8);
						end if;
					else										-- store to memory
						memory_r_w	<= '0';
						memory_address	<= page & offset;
						memory_out(63 downto 56)	<= cache(index)(offset);
						memory_out(55 downto 48)	<= cache(index)(offset+"001");
						memory_out(47 downto 40)	<= cache(index)(offset+"010");
						memory_out(39 downto 32)	<= cache(index)(offset+"011");
						memory_out(31 downto 24)	<= cache(index)(offset+"100");
						memory_out(23 downto 16)	<= cache(index)(offset+"101");
						memory_out(15 downto 8)		<= cache(index)(offset+"110");
						memory_out(7 downto 0)		<= cache(index)(offset+"111");
					end if;
				end if;
			end if;
		else
			memory_r_w	<= '1';
		end if;
	end process;
			
end Structure;