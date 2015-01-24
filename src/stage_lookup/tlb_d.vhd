library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity tlb_d is
	port (
		clk				: in std_logic;
		boot			: in std_logic;
		we				: in std_logic;
		add_logical		: in std_logic_vector(15 downto 0);
		hit_miss		: out std_logic;
		add_physical	: out std_logic_vector(15 downto 0)
	);
end entity;

architecture Structure of tlb_d is
	signal page_logical		: std_logic_vector(9 downto 0);
	signal page_physical	: std_logic_vector(9 downto 0);
	signal hit				: std_logic_vector(4 downto 0);
	
	-- 5 entries,       Valid | Logical page | Physical page
	--                   1b   |     10b      |     10b
	-- 105b tlb size
	type tlb_table is array (4 downto 0) of std_logic_vector(20 downto 0);
	signal tlb : tlb_table;

	-- Initialize TLB from file tlb_d.txt
	procedure Load_TLB_Data (signal data : inout tlb_table) is
		-- Open File in Read Mode
		file tlb_file	:text open read_mode is "tlb_d.txt";
		variable lbuf	:line;
		variable i		:integer := 0;
		variable fdata	:std_logic_vector (20 downto 0);
	begin
		while (i < 4) loop
			-- read data from input file
			readline(tlb_file, lbuf);
			read(lbuf, fdata);
			data(i) <= fdata;
			i := i+1;
		end loop;
	end procedure;
	
	-- Check if a TLB entry has the page we are looking for
	procedure Check_TLB_Entry (	signal valid	: in std_logic;
								signal page		: in std_logic_vector(9 downto 0);
								signal data		: in std_logic_vector(20 downto 0);
								signal hit		: out std_logic) is
	begin
		if ((page = data(19 downto 10)) and valid = '1') then
			hit <= '1';
		else
			hit <= '0';
		end if;
	end procedure;
		
begin
	page_logical <= add_logical(15 downto 6);
	add_physical <= page_physical(9 downto 0) & add_logical(5 downto 0);
	
	process (clk)
	begin
		if (clk'event and clk = '0') then
			if (boot = '1') then
				Load_TLB_Data(tlb);
			else
				if (we = '1') then
					Check_TLB_Entry(tlb(0)(20), page_logical, tlb(0), hit(0));
					Check_TLB_Entry(tlb(1)(20), page_logical, tlb(1), hit(1));
					Check_TLB_Entry(tlb(2)(20), page_logical, tlb(2), hit(2));
					Check_TLB_Entry(tlb(3)(20), page_logical, tlb(3), hit(3));
					Check_TLB_Entry(tlb(4)(20), page_logical, tlb(4), hit(4));
					hit_miss <= hit(0) or hit(1) or hit(2) or hit(3) or hit(4);
					if (hit(0) = '1') then
						page_physical <= tlb(0)(9 downto 0);
					elsif (hit(1) = '1') then
						page_physical <= tlb(1)(9 downto 0);
					elsif (hit(2) = '1') then
						page_physical <= tlb(2)(9 downto 0);
					elsif (hit(3) = '1') then
						page_physical <= tlb(3)(9 downto 0);
					elsif (hit(4) = '1') then
						page_physical <= tlb(4)(9 downto 0);
					else
						page_physical <= "0000000000";
					end if;
				end if;
			end if;
		end if;
	end process;
			
end Structure;
