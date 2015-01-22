library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use ieee.numeric_std.all;

entity tags_d is
	port (
		clk				: in std_logic;
		boot			: in std_logic;
		we				: in std_logic;
		read_write		: in std_logic;
		add_logical		: in std_logic_vector(15 downto 0);
		add_physical	: in std_logic_vector(15 downto 0);
		hit_miss		: out std_logic;
		wb				: out std_logic;
		wb_tag			: out std_logic_vector(9 downto 0)
	);
end entity;

architecture Structure of tags_d is
	signal index		: std_logic_vector(3 downto 0);
	signal stored_tag	: std_logic_vector(9 downto 0);
	signal valid		: std_logic;
	signal dirty		: std_logic;
	signal hit			: std_logic;
	-- signal int_index	: integer;
	
	signal int_index : integer range 0 to 7;
	
	-- 16 lines,       Valid | Dirty | Tag
	--                  1b   |  1b   | 10b
	-- 192b tags size
	type tags_table is array (15 downto 0) of std_logic_vector(11 downto 0);
	signal tags : tags_table;
	
	-- Initialize Tags from file tags_d.txt
	procedure Load_Tags_Data (signal data : inout tags_table) is
		-- Open File in Read Mode
		file tag_file	:text open read_mode is "tags_d.txt";
		variable lbuf	:line;
		variable i		:integer := 0;
		variable fdata	:std_logic_vector (11 downto 0);
	begin
		while not endfile(tag_file) loop
			-- read data from input file
			readline(tag_file, lbuf);
			read(lbuf, fdata);
			data(i) <= fdata;
			i := i+1;
		end loop;
	end procedure;
	
	
begin
	--index <= add_logical(5 downto 2);
	--int_index <= to_integer(unsigned(index));
	int_index <= to_integer(unsigned(index));
	hit_miss <= hit;
	
	process (clk)
	begin
		if (clk'event) then
			if (clk = '1') then
				if (boot = '1') then
					Load_Tags_Data(tags);
				else
					if (we = '1') then
						valid <= tags_table(int_index)(11);
						dirty <= tags_table(int_index)(10);
						stored_tag <= tags_table(int_index)(9 downto 0);
						if ((stored_tag = add_physical(15 downto 6)) and (valid = '1')) then
							hit <= '1';
						else
							hit <= '0';
						end if;
					end if;
				end if;
			else
				if (we = '1') then
					if (hit = '0') then
						tags_table(int_index)(11) <= '1';
						tags_table(int_index)(10) <= not read_write;
						tags_table(int_index)(9 downto 0) <= add_physical(15 downto 6);
					else
						tags_table(int_index)(10) <= (not read_write) or (tags_table(int_index)(10));
					end if;
				end if;
			end if;
		end if;
	end process;
			
end Structure;