LIBRARY ieee;
USE ieee.std_logic_1164.all;

entity proc is
	port (
		clk				: in std_logic;
		boot			: in std_logic;
		
		-- Instructions memory
		imem_we			: out	std_logic; 						-- not used
		imem_addr		: out	std_logic_vector(15 downto 0);
		imem_wr_data	: out	std_logic_vector(63 downto 0);	-- not used
		imem_rd_data	: in	std_logic_vector(63 downto 0);
		
		-- Data memory
		dmem_we			: out	std_logic;
		dmem_addr		: out	std_logic_vector(15 downto 0);
		dmem_wr_data	: out	std_logic_vector(63 downto 0);
		dmem_rd_data	: in	std_logic_vector(63 downto 0)
	);
end proc;


architecture Structure of proc is

	component datapath is
		port (
			clk					: in	std_logic;
			boot				: in	std_logic;
			base_stall_vector	: in	std_logic_vector(5 downto 0);
			base_nop_vector		: in	std_logic_vector(5 downto 1);
			fop_stall_vector	: in	std_logic_vector(7 downto 2);
			fop_nop_vector		: in	std_logic_vector(7 downto 2);
			
			-- Fetch
			fetch_pc			: in	std_logic_vector(15 downto 0);
			
			-- Decode
			decode_awb_addr_d	: in	std_logic_vector(2 downto 0);
			decode_mwb_addr_d	: in	std_logic_vector(2 downto 0);
			decode_fwb_addr_d	: in	std_logic_vector(2 downto 0);
			
			decode_addr_a		: in	std_logic_vector(2 downto 0);
			decode_addr_b		: in	std_logic_vector(2 downto 0);
			
			decode_wrd			: in	std_logic;
			decode_ctrl_d		: in	std_logic_vector(1 downto 0);
			decode_ctrl_immed	: in	std_logic;
			decode_immed		: in	std_logic_vector(15 downto 0);
			
			decode_ir			: out	std_logic_vector(15 downto 0);
			
			-- Alu
			alu_opclass			: in	std_logic_vector(2 downto 0);
			alu_opcode			: in	std_logic_vector(1 downto 0);
			alu_w				: out	std_logic_vector(15 downto 0);
			alu_z				: out	std_logic;
			
			-- Cache
			cache_opclass		: in	std_logic_vector(2 downto 0);
			cache_opcode		: in	std_logic_vector(1 downto 0);
		
			-- Memories
			-- Instructions memory
			imem_addr			: out	std_logic_vector(15 downto 0);
			imem_rd_data		: in	std_logic_vector(63 downto 0);
			
			-- Data memory
			dmem_we				: out	std_logic;
			dmem_addr			: out	std_logic_vector(15 downto 0);
			dmem_wr_data		: out	std_logic_vector(63 downto 0);
			dmem_rd_data		: in	std_logic_vector(63 downto 0);
			
			-- Bypasses control
			bypasses_ctrl_a		: in	std_logic_vector(3 downto 0); -- A, F1
			bypasses_ctrl_b		: in	std_logic_vector(3 downto 0); -- A, F1
			bypasses_ctrl_mem	: in	std_logic_vector(5 downto 0)  -- A, WB/L, C
		);
	end component;

	component control_unit is
		port (
			clk					: in	std_logic;
			boot				: in	std_logic;
			base_stall_vector	: out	std_logic_vector(5 downto 0);
			base_nop_vector		: out	std_logic_vector(5 downto 1);
			fop_stall_vector	: out	std_logic_vector(7 downto 2);
			fop_nop_vector		: out	std_logic_vector(7 downto 2);
			
			-- Fetch
			fetch_pc			: out	std_logic_vector(15 downto 0);
			
			-- Decode
			decode_awb_addr_d	: out	std_logic_vector(2 downto 0);
			decode_mwb_addr_d	: out	std_logic_vector(2 downto 0);
			decode_fwb_addr_d	: out	std_logic_vector(2 downto 0);
			
			decode_addr_a		: out	std_logic_vector(2 downto 0);
			decode_addr_b		: out	std_logic_vector(2 downto 0);
			
			decode_wrd			: out	std_logic;
			decode_ctrl_d		: out	std_logic_vector(1 downto 0);
			decode_ctrl_immed	: out	std_logic;
			decode_immed		: out	std_logic_vector(15 downto 0);
			
			decode_ir			: in	std_logic_vector(15 downto 0);
			
			-- Alu
			alu_opclass			: out	std_logic_vector(2 downto 0);
			alu_opcode			: out	std_logic_vector(1 downto 0);
			alu_w				: in	std_logic_vector(15 downto 0);
			alu_z				: in	std_logic;
			
			-- Cache
			cache_opclass		: out	std_logic_vector(2 downto 0);
			cache_opcode		: out	std_logic_vector(1 downto 0);
			
			-- Bypasses control
			bypasses_ctrl_a		: out	std_logic_vector(3 downto 0); -- A, F1
			bypasses_ctrl_b		: out	std_logic_vector(3 downto 0); -- A, F1
			bypasses_ctrl_mem	: out	std_logic_vector(5 downto 0)  -- A, WB/L, C
		);
	end component;
	
	signal base_stall_vector	: std_logic_vector(5 downto 0);
	signal base_nop_vector		: std_logic_vector(5 downto 1);
	signal fop_stall_vector		: std_logic_vector(7 downto 2);
	signal fop_nop_vector		: std_logic_vector(7 downto 2);
	
	
	-- Fetch
	signal fetch_pc				: std_logic_vector(15 downto 0);
	
	-- Decode	
	signal decode_awb_addr_d	: std_logic_vector(2 downto 0);
	signal decode_mwb_addr_d	: std_logic_vector(2 downto 0);
	signal decode_fwb_addr_d	: std_logic_vector(2 downto 0);
	
	signal decode_addr_a		: std_logic_vector(2 downto 0);
	signal decode_addr_b		: std_logic_vector(2 downto 0);
	
	signal decode_wrd			: std_logic;
	signal decode_ctrl_d		: std_logic_vector(1 downto 0);
	signal decode_ctrl_immed	: std_logic;
	signal decode_immed			: std_logic_vector(15 downto 0);
	
	signal decode_ir			: std_logic_vector(15 downto 0);
	
	-- Alu
	signal alu_opclass			: std_logic_vector(2 downto 0);
	signal alu_opcode			: std_logic_vector(1 downto 0);
	signal alu_w				: std_logic_vector(15 downto 0);
	signal alu_z				: std_logic;
	
	-- Cache
	signal cache_opclass		: std_logic_vector(2 downto 0);
	signal cache_opcode			: std_logic_vector(1 downto 0);

	-- Bypasses control
	signal bypasses_ctrl_a		: std_logic_vector(3 downto 0); -- A
	signal bypasses_ctrl_b		: std_logic_vector(3 downto 0); -- A
	signal bypasses_ctrl_mem	: std_logic_vector(5 downto 0); -- A, WB/L, C
	
begin

	imem_we	<= '0';

	dp : datapath
	port map (
		clk					=> clk,
		boot				=> boot,
		base_stall_vector	=> base_stall_vector,
		base_nop_vector		=> base_nop_vector,
		fop_stall_vector	=> fop_stall_vector,
		fop_nop_vector		=> fop_nop_vector,
		
		-- Fetch
		fetch_pc			=> fetch_pc,
		
		-- Decode
		decode_awb_addr_d	=> decode_awb_addr_d,
		decode_mwb_addr_d	=> decode_mwb_addr_d,
		decode_fwb_addr_d	=> decode_fwb_addr_d,
		
		decode_addr_a		=> decode_addr_a,
		decode_addr_b		=> decode_addr_b,
		
		decode_wrd			=> decode_wrd,
		decode_ctrl_d		=> decode_ctrl_d,
		decode_ctrl_immed	=> decode_ctrl_immed,
		decode_immed		=> decode_immed,
		
		decode_ir			=> decode_ir,
		
		-- Alu
		alu_opclass			=> alu_opclass,
		alu_opcode			=> alu_opcode,
		alu_w				=> alu_w,
		alu_z				=> alu_z,
		
		-- Cache
		cache_opclass		=> cache_opclass,
		cache_opcode		=> cache_opcode,
		
		-- Memories
		-- Instructions memory
		imem_addr			=> imem_addr,
		imem_rd_data		=> imem_rd_data,
		
		-- Data memory
		dmem_we				=> dmem_we,
		dmem_addr			=> dmem_addr,
		dmem_wr_data		=> dmem_wr_data,
		dmem_rd_data		=> dmem_rd_data,
		
		-- Bypasses control
		bypasses_ctrl_a		=> bypasses_ctrl_a,
		bypasses_ctrl_b		=> bypasses_ctrl_b,
		bypasses_ctrl_mem	=> bypasses_ctrl_mem
	);
	
	ctrl : control_unit
	port map (
		clk					=> clk,
		boot				=> boot,
		base_stall_vector	=> base_stall_vector,
		base_nop_vector		=> base_nop_vector,
		fop_stall_vector	=> fop_stall_vector,
		fop_nop_vector		=> fop_nop_vector,
		
		-- Fetch
		fetch_pc			=> fetch_pc,
		
		-- Decode		
		decode_awb_addr_d	=> decode_awb_addr_d,
		decode_mwb_addr_d	=> decode_mwb_addr_d,
		decode_fwb_addr_d	=> decode_fwb_addr_d,
		
		decode_addr_a		=> decode_addr_a,
		decode_addr_b		=> decode_addr_b,
		
		decode_wrd			=> decode_wrd,
		decode_ctrl_d		=> decode_ctrl_d,
		decode_ctrl_immed	=> decode_ctrl_immed,
		decode_immed		=> decode_immed,
		
		decode_ir			=> decode_ir,
		
		-- Alu
		alu_opclass			=> alu_opclass,
		alu_opcode			=> alu_opcode,
		alu_w				=> alu_w,
		alu_z				=> alu_z,
		
		-- Cache
		cache_opclass		=> cache_opclass,
		cache_opcode		=> cache_opcode,
		
		-- Bypasses control
		bypasses_ctrl_a		=> bypasses_ctrl_a,
		bypasses_ctrl_b		=> bypasses_ctrl_b,
		bypasses_ctrl_mem	=> bypasses_ctrl_mem
	);

end Structure;