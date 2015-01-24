LIBRARY ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity datapath is 
	port (
		clk					: in	std_logic;
		boot				: in	std_logic;
		base_stall_vector	: in	std_logic_vector(5 downto 0);
		fop_stall_vector	: in	std_logic_vector(7 downto 2);
		
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
end datapath;


architecture Structure OF datapath is

	-- Defines
		constant FETCH	: integer	:= 0;
		constant DECODE	: integer	:= 1;
		constant ALU	: integer	:= 2;
		constant LOOKUP	: integer	:= 3;
		constant CACHE	: integer	:= 4;
		constant MEMWB	: integer	:= 5;
		
		constant FOP1	: integer	:= 2;
		constant FOP2	: integer	:= 3;
		constant FOP3	: integer	:= 4;
		constant FOP4	: integer	:= 5;
		constant FOP5	: integer	:= 6;
		constant FOPWB	: integer	:= 7;

	component stage_fetch is
		port (
			clk				: in	std_logic;
			boot			: in	std_logic;
			stall			: in	std_logic;
			
			imem_addr		: out	std_logic_vector(15 downto 0);
			imem_rd_data	: in	std_logic_vector(63 downto 0);
			
			pc				: in	std_logic_vector(15 downto 0);
			ir				: out	std_logic_vector(15 downto 0)
		);
	end component;
	
	component stage_decode is
		port (
			clk			: in	std_logic;
			stall		: in	std_logic;
			
			-- flipflop inputs
			ff_ir		: in	std_logic_vector(15 downto 0);
			
			-- Value and addr of d to be written in Regfile.
			-- Also used as bypasses for a and b
			artm_d		: in	std_logic_vector(15 downto 0);
			mem_d		: in	std_logic_vector(15 downto 0);
			fop_d		: in	std_logic_vector(15 downto 0);
			awb_addr_d	: in	std_logic_vector(2 downto 0);
			mwb_addr_d	: in	std_logic_vector(2 downto 0);
			fwb_addr_d	: in	std_logic_vector(2 downto 0);
			
			addr_a		: in	std_logic_vector(2 downto 0);
			addr_b		: in	std_logic_vector(2 downto 0);
			a			: out	std_logic_vector(15 downto 0);
			b			: out	std_logic_vector(15 downto 0);
			
			wrd			: in	std_logic;						-- Regfile enable write
			ctrl_d		: in 	std_logic_vector(1 downto 0);	-- Select source for d write
			ctrl_immed	: in 	std_logic;						-- Select immed over a to use it
			immed		: in	std_logic_vector(15 downto 0);
			
			ir			: out	std_logic_vector(15 downto 0);
			mem_data	: out	std_logic_vector(15 downto 0)
		);
	end component;
	
	component stage_alu is
		port (
			clk			: in	std_logic;
			stall		: in	std_logic;
			
			-- flipflop inputs
			ff_a		: in	std_logic_vector(15 downto 0);
			ff_b		: in	std_logic_vector(15 downto 0);
			ff_mem_data	: in	std_logic_vector(15 downto 0);
			ff_opclass	: in 	std_logic_vector(2 downto 0);
			ff_opcode	: in	std_logic_vector(1 downto 0);
			
			-- Bypasses control and sources
			bp_ctrl_a	: in	std_logic_vector(1 downto 0);
			bp_ctrl_b	: in	std_logic_vector(1 downto 0);
			bp_ctrl_mem	: in	std_logic_vector(1 downto 0);
			bp_data_awb	: in	std_logic_vector(15 downto 0);
			bp_data_mwb	: in	std_logic_vector(15 downto 0);
			bp_data_fwb	: in	std_logic_vector(15 downto 0);
			
			w			: out	std_logic_vector(15 downto 0);
			z			: out	std_logic;
			mem_data	: out	std_logic_vector(15 downto 0)
		);
	end component;
	
	component stage_lookup is
		port (
			clk				: in	std_logic;
			boot			: in 	std_logic;
			stall			: in	std_logic;
			
			-- flipflop inputs
			ff_addr_mem		: in	std_logic_vector(15 downto 0);
			ff_mem_data		: in	std_logic_vector(15 downto 0);
			
			-- Bypasses control and sources
			bp_ctrl_mem		: in	std_logic_vector(1 downto 0);
			bp_data_mwb		: in	std_logic_vector(15 downto 0);
			bp_data_fwb		: in	std_logic_vector(15 downto 0);
			
			aluwb			: out	std_logic_vector(15 downto 0);
			addr_mem		: out	std_logic_vector(15 downto 0);
			mem_data		: out	std_logic_vector(15 downto 0)
		);
	end component;
	
	component stage_cache is
		port (
			clk			: in	std_logic;
			stall		: in	std_logic;
			nop			: in	std_logic;
			
			-- flipflop inputs
			ff_addr_mem	: in	std_logic_vector(15 downto 0);
			ff_mem_data	: in	std_logic_vector(15 downto 0);
			
			-- Bypasses control and sources
			bp_ctrl_mem	: in	std_logic_vector(1 downto 0);
			bp_data_mwb	: in	std_logic_vector(15 downto 0);
			bp_data_fwb	: in	std_logic_vector(15 downto 0);
			
			-- Data memory
			dmem_we		: out	std_logic;
			dmem_addr	: out	std_logic_vector(15 downto 0);
			dmem_wr_data: out	std_logic_vector(63 downto 0);
			dmem_rd_data: in	std_logic_vector(63 downto 0);
			
			load_data	: out	std_logic_vector(15 downto 0)
		);
	end component;
	
	component stage_wb is
		port (
			clk			: in	std_logic;
			stall		: in	std_logic;
			
			-- flipflop inputs
			ff_load_data: in	std_logic_vector(15 downto 0);
			
			load_data	: out	std_logic_vector(15 downto 0)
		);
	end component;
	
	component stage_f1 is
		port (
			clk			: in	std_logic;
			stall		: in	std_logic;
			
			-- flipflop inputs
			ff_a		: in	std_logic_vector(15 downto 0);
			ff_b		: in	std_logic_vector(15 downto 0);
			
			-- Bypasses control and sources
			bp_ctrl_a	: in	std_logic_vector(1 downto 0);
			bp_ctrl_b	: in	std_logic_vector(1 downto 0);
			bp_data_awb	: in	std_logic_vector(15 downto 0);
			bp_data_mwb	: in	std_logic_vector(15 downto 0);
			bp_data_fwb	: in	std_logic_vector(15 downto 0);
			
			fop_data	: out	std_logic_vector(15 downto 0)
		);
	end component;
	
	component stage_f2 is
		port (
			clk			: in	std_logic;
			stall		: in	std_logic;
			
			-- flipflop inputs
			ff_fop_data	: in	std_logic_vector(15 downto 0);
			
			fop_data	: out	std_logic_vector(15 downto 0)
		);
	end component;
	
	component stage_f3 is
		port (
			clk			: in	std_logic;
			stall		: in	std_logic;
			
			-- flipflop inputs
			ff_fop_data	: in	std_logic_vector(15 downto 0);
			
			fop_data	: out	std_logic_vector(15 downto 0)
		);
	end component;
	
	component stage_f4 is
		port (
			clk			: in	std_logic;
			stall		: in	std_logic;
			
			-- flipflop inputs
			ff_fop_data	: in	std_logic_vector(15 downto 0);
			
			fop_data	: out	std_logic_vector(15 downto 0)
		);
	end component;
	
	component stage_f5 is
		port (
			clk			: in	std_logic;
			stall		: in	std_logic;
			
			-- flipflop inputs
			ff_fop_data	: in	std_logic_vector(15 downto 0);
			
			fop_data	: out	std_logic_vector(15 downto 0)
		);
	end component;
	
	component stage_fwb is
		port (
			clk			: in	std_logic;
			stall		: in	std_logic;
			
			-- flipflop inputs
			ff_fop_data	: in	std_logic_vector(15 downto 0);
			
			fop_data	: out	std_logic_vector(15 downto 0)
		);
	end component;
	
	-- Pipeline flow signals
	signal f2d_ir			: std_logic_vector(15 downto 0);
	signal d2a_a			: std_logic_vector(15 downto 0);
	signal d2a_b			: std_logic_vector(15 downto 0);
	signal d2a_mem_data		: std_logic_vector(15 downto 0);
	signal a2l_mem_data		: std_logic_vector(15 downto 0);
	signal l2c_mem_data		: std_logic_vector(15 downto 0);
	signal l2c_addr_mem		: std_logic_vector(15 downto 0);
	signal c2mwb_load_data	: std_logic_vector(15 downto 0);
	
	signal alu_out			: std_logic_vector(15 downto 0);
	
	signal f1_f2_fop_data	: std_logic_vector(15 downto 0);
	signal f2_f3_fop_data	: std_logic_vector(15 downto 0);
	signal f3_f4_fop_data	: std_logic_vector(15 downto 0);
	signal f4_f5_fop_data	: std_logic_vector(15 downto 0);
	signal f5_fwb_fop_data	: std_logic_vector(15 downto 0);
		
	-- Return values & bypass data
	signal aluwb_data		: std_logic_vector(15 downto 0);
	signal memwb_data		: std_logic_vector(15 downto 0);
	signal fopwb_data		: std_logic_vector(15 downto 0);
	
begin

	fch	: stage_fetch
	port map (
		clk			=> clk,
		boot		=> boot,
		stall		=> base_stall_vector(FETCH),
		imem_addr	=> imem_addr,
		imem_rd_data=> imem_rd_data,
		pc			=> fetch_pc,
		ir			=> f2d_ir
	);
	
	dec	: stage_decode
	port map (
		clk			=> clk,
		stall		=> base_stall_vector(DECODE),
		
		-- flipflop inputs
		ff_ir		=> f2d_ir,
		
		-- Write to d
		artm_d		=> aluwb_data,
		mem_d		=> memwb_data,
		fop_d		=> fopwb_data,
		awb_addr_d	=> decode_awb_addr_d,
		mwb_addr_d	=> decode_mwb_addr_d,
		fwb_addr_d	=> decode_fwb_addr_d,
		
		addr_a		=> decode_addr_a,
		addr_b		=> decode_addr_b,
		a			=> d2a_a, 
		b			=> d2a_b,
		
		wrd			=> decode_wrd,
		ctrl_d		=> decode_ctrl_d,
		ctrl_immed	=> decode_ctrl_immed,
		immed		=> decode_immed,
		
		ir			=> decode_ir,
		mem_data	=> d2a_mem_data
	);
	
	alu0 : stage_alu
	port map (
		clk			=> clk,
		stall		=> base_stall_vector(ALU),
		
		-- flipflop inputs
		ff_a		=> d2a_a,
		ff_b		=> d2a_b,
		ff_mem_data	=> d2a_mem_data,
		ff_opclass	=> alu_opclass,
		ff_opcode	=> alu_opcode,
		
		-- Bypasses control and sources
		bp_ctrl_a	=> bypasses_ctrl_a(1 downto 0),
		bp_ctrl_b	=> bypasses_ctrl_b(1 downto 0),
		bp_ctrl_mem	=> bypasses_ctrl_mem(1 downto 0),
		bp_data_awb	=> aluwb_data,
		bp_data_mwb	=> memwb_data,
		bp_data_fwb	=> fopwb_data,
		
		w			=> alu_out,
		z			=> alu_z,
		mem_data	=> a2l_mem_data
	);
	
	alu_w <= alu_out;
	
	lk	: stage_lookup
	port map (
		clk			=> clk,
		boot		=> boot,
		stall		=> base_stall_vector(LOOKUP),
		
		-- flipflop inputs
		ff_addr_mem	=> alu_out,
		ff_mem_data	=> a2l_mem_data,
		
		-- Bypasses control and sources
		bp_ctrl_mem	=> bypasses_ctrl_mem(3 downto 2),
		bp_data_mwb	=> memwb_data,
		bp_data_fwb	=> fopwb_data,
		
		aluwb		=> aluwb_data,
		addr_mem	=> l2c_addr_mem,
		mem_data	=> l2c_mem_data
	);
	
	ch	: stage_cache
	port map (
		clk			=> clk,
		stall		=> base_stall_vector(CACHE),
		nop			=> '0',
		
		-- flipflop inputs
		ff_addr_mem	=> l2c_addr_mem,
		ff_mem_data	=> l2c_mem_data,
		
		-- Bypasses control and sources
		bp_ctrl_mem	=> bypasses_ctrl_mem(5 downto 4),
		bp_data_mwb	=> memwb_data,
		bp_data_fwb	=> fopwb_data,
		
		-- Data memory
		dmem_we		=> dmem_we,
		dmem_addr	=> dmem_addr,
		dmem_wr_data=> dmem_wr_data,
		dmem_rd_data=> dmem_rd_data,
		
		load_data	=> c2mwb_load_data
	);
	
	wb	: stage_wb
	port map (
		clk			=> clk,
		stall		=> base_stall_vector(MEMWB),
		
		-- flipflop inputs
		ff_load_data=> c2mwb_load_data,
		
		load_data	=> memwb_data
	);
	
	
	f1	: stage_f1
	port map (
		clk			=> clk,
		stall		=> fop_stall_vector(FOP1),
		
		-- flipflop inputs
		ff_a		=> d2a_a,
		ff_b		=> d2a_b,
		
		-- Bypasses control and sources
		bp_ctrl_a	=> bypasses_ctrl_a(3 downto 2),
		bp_ctrl_b	=> bypasses_ctrl_b(3 downto 2),
		bp_data_awb	=> aluwb_data,
		bp_data_mwb	=> memwb_data,
		bp_data_fwb	=> fopwb_data,
		
		fop_data	=> f1_f2_fop_data
	);
	
	f2	: stage_f2
	port map (
		clk			=> clk,
		stall		=> fop_stall_vector(FOP2),
		
		-- flipflop inputs
		ff_fop_data	=> f1_f2_fop_data,
		
		fop_data	=> f2_f3_fop_data
	);
	
	f3	: stage_f3
	port map (
		clk			=> clk,
		stall		=> fop_stall_vector(FOP3),
		
		-- flipflop inputs
		ff_fop_data	=> f2_f3_fop_data,
		
		fop_data	=> f3_f4_fop_data
	);
	
	f4	: stage_f4
	port map (
		clk			=> clk,
		stall		=> fop_stall_vector(FOP4),
		
		-- flipflop inputs
		ff_fop_data	=> f3_f4_fop_data,
		
		fop_data	=> f4_f5_fop_data
	);
	
	f5	: stage_f5
	port map (
		clk			=> clk,
		stall		=> fop_stall_vector(FOP5),
		
		-- flipflop inputs
		ff_fop_data	=> f4_f5_fop_data,
		
		fop_data	=> f5_fwb_fop_data
	);
	
	fwb	: stage_fwb
	port map (
		clk			=> clk,
		stall		=> fop_stall_vector(FOPWB),
		
		-- flipflop inputs
		ff_fop_data=> f5_fwb_fop_data,
		
		fop_data	=> fopwb_data
	);

end Structure;