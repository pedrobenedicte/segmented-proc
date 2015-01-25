library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity cache_i is
	port (
		clk				: in std_logic;		-- clock
		boot			: in std_logic;		-- boot
		cache_mem		: in std_logic;		-- access cache or memory
		add_physical	: in std_logic_vector(15 downto 0);
		
		memory_address	: out std_logic_vector(12 downto 0);
		memory_in		: in std_logic_vector(63 downto 0);
		
		data_out		: out std_logic_vector(15 downto 0)
	);
end entity;

architecture Structure of cache_i is
	signal page		: std_logic_vector(9 downto 0);
	signal index	: std_logic_vector(2 downto 0);
	signal offset	: std_logic_vector(2 downto 0);
	
	signal i_index	: integer;
	signal i_offset	: integer;
	
	-- 8 lines, 64b each line
	-- 512b cache size
	type cache_line is array (7 downto 0) of std_logic_vector (7 downto 0);
	type cache_table is array (7 downto 0) of cache_line;
	signal cache : cache_table;

	-- Initialize Cache_i from file cache_d.txt
	procedure Load_Cache_Inst (signal data : inout cache_table) is
		-- Open File in Read Mode
		file cache_file	:text open read_mode is "cache_i.txt";
		variable lbuf	:line;
		variable i		:integer := 0;
		variable fdata	:std_logic_vector (63 downto 0);
	begin
		while i < 8 loop
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
	
	i_index		<= to_integer(unsigned(index));

	process (clk)
	begin
		if (clk'event and clk = '0') then
			if (boot = '1') then
				Load_Cache_Inst(cache);
			else
				if (cache_mem = '1') then			-- load from cache
					data_out(7 downto 0) 	<= cache(i_index)(to_integer(unsigned(offset)));
					data_out(15 downto 8) 	<= cache(i_index)(to_integer(unsigned(offset+"001")));
				else								-- load from memory
					memory_address	<= page & offset;
					cache(i_index)(to_integer(unsigned(offset)))		<= memory_in(63 downto 56);
					cache(i_index)(to_integer(unsigned(offset+"001")))	<= memory_in(55 downto 48);
					cache(i_index)(to_integer(unsigned(offset+"010")))	<= memory_in(47 downto 40);
					cache(i_index)(to_integer(unsigned(offset+"011")))	<= memory_in(39 downto 32);
					cache(i_index)(to_integer(unsigned(offset+"100")))	<= memory_in(31 downto 24);
					cache(i_index)(to_integer(unsigned(offset+"101")))	<= memory_in(23 downto 16);
					cache(i_index)(to_integer(unsigned(offset+"110")))	<= memory_in(15 downto 8);
					cache(i_index)(to_integer(unsigned(offset+"111")))	<= memory_in(7 downto 0);
				end if;
			end if;
		end if;
	end process;
			
end Structure;
