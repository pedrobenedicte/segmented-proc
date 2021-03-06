library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.std_logic_textio.all;
   use std.textio.all;


entity memory is
	port (
		clk		: in	std_logic;
		boot	: in	std_logic;
		addr	: in	std_logic_vector(15 downto 0);
		wr_data	: in	std_logic_vector(63 downto 0);
		rd_data	: out	std_logic_vector(63 downto 0);
		we		: in	std_logic;
		imem	: in	std_logic
	);
end entity;

architecture comportament of memory is
	
	-- RAM memory 8x2^16
	type RAM_MEMORY is array (2 ** 16 - 1 downto 0) of std_logic_vector(7 downto 0);
	signal mem			: RAM_MEMORY;

	signal addr1		: std_logic_vector(15 downto 0);
	signal addr2		: std_logic_vector(15 downto 0);
	signal addr3		: std_logic_vector(15 downto 0);
	signal addr4		: std_logic_vector(15 downto 0);
	signal addr5		: std_logic_vector(15 downto 0);
	signal addr6		: std_logic_vector(15 downto 0);
	signal addr7		: std_logic_vector(15 downto 0);
	
	procedure Load_FitxerDadesMemoria(	signal data_word	:inout RAM_MEMORY;
										signal imem			:in std_logic) is
		
		file romfilep   :text open read_mode is "prog.rom";
		file romfiled   :text open read_mode is "data.rom";
		variable lbuf  :line;
		variable i     :integer := 0;  -- X"C000" ==> 49152 adreca inicial S.O.
		variable fdata :std_logic_vector (7 downto 0);
	begin
		if (imem = '1') then
			while not endfile(romfilep) loop
				-- read data from input file
				readline(romfilep, lbuf);
				hread(lbuf, fdata);
				data_word(i) <= fdata;
				i := i+1;
			end loop;
		else 
			while not endfile(romfiled) loop
				-- read data from input file
				readline(romfiled, lbuf);
				hread(lbuf, fdata);
				data_word(i) <= fdata;
				i := i+1;
			end loop;
		end if;
		fdata	:= "00000000";
		while i < (2 ** 16)-1 loop
			data_word(i) <= fdata;
			i := i+1;
		end loop;
	end procedure;
	
begin
   
	addr1	<= addr(15 downto 3)&"001";
	addr2	<= addr(15 downto 3)&"010";
	addr3	<= addr(15 downto 3)&"011";
	addr4	<= addr(15 downto 3)&"100";
	addr5	<= addr(15 downto 3)&"101";
	addr6	<= addr(15 downto 3)&"110";
	addr7	<= addr(15 downto 3)&"111";
	
	rd_data	<= 	mem(conv_integer(addr7)) & mem(conv_integer(addr6)) & mem(conv_integer(addr5)) & mem(conv_integer(addr4)) &
				mem(conv_integer(addr3)) & mem(conv_integer(addr2)) & mem(conv_integer(addr1)) & mem(conv_integer(addr));

    process (clk)
    begin
		if (clk'event and clk = '1') then
			if boot = '1' then
				Load_FitxerDadesMemoria(mem, imem);
			else
				if (we = '1') then
					mem(conv_integer(addr))		<= wr_data(7 downto 0);
					mem(conv_integer(addr1))	<= wr_data(15 downto 8);
					mem(conv_integer(addr2))	<= wr_data(23 downto 16);
					mem(conv_integer(addr3))	<= wr_data(31 downto 24);
					mem(conv_integer(addr4))	<= wr_data(39 downto 32);
					mem(conv_integer(addr5))	<= wr_data(47 downto 40);
					mem(conv_integer(addr6))	<= wr_data(55 downto 48);
					mem(conv_integer(addr7))	<= wr_data(63 downto 56);
				end if;
			end if;
		end if;
    end process;
   
end comportament;

