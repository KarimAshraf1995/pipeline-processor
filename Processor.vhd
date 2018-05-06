library ieee;
Use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


entity Processor is 
	port (CLK : in std_logic;
		RST : in std_logic;
		INT: in std_logic; 
		InPort : in std_logic_vector (15 downto 0);
		OutPort : out std_logic_vector(15 downto 0)
		);
end entity Processor;


Architecture Processor_Implementation of Processor is  
component FetchStage is 
	port (CLK : in std_logic;
		PCEnable : in std_logic; -- PC enable - HDU
		UpperMuxSelect: in std_logic; -- 1 bit upper MUX selector
		FetchBufferFlush: in std_logic; -- 1 bit to clear both upper&lower
		FetchBufferStall: in std_logic; -- 1 bit to stall upper Fetch
		Jmp16R : in std_logic_vector (15 downto 0); -- 16 bits - Address stored in register but for Jumps that need a condition
		PC16Addr : in std_logic_vector(15 downto 0);	--16 bits - Address stored in register 
		PCMuxSelector: in std_logic_vector(1 downto 0); --2 bits - MUX next instruction address, Fetch Buffer Control
		PCMemAddr: in std_logic_vector(15 downto 0); -- 16 bits - Address stored in memory
		StageOutput: out std_logic_vector(31 downto 0) --32 Bits
		);
end component;
component DecodeStage is 
	port (CLK : in std_logic;
		InMuxSelector: in std_logic; -- IN mux selector
		RMuxSelector: in std_logic; --From FU, R1 Mux and R2 Mux selectors
		WriteBackEnable: in std_logic; --Enable writeback to RegFile
		DecodeBufferFlush: in std_logic; --Flush Decode Buffer
		ImmMuxSelector: in std_logic_vector(1 downto 0); --From CU,
		FetchStage: in std_logic_vector (31 downto 0); --Output of the Fetch Stage Buffer (Previous stage)
		WriteBackAddress: in std_logic_vector (2 downto 0); --Which Reg to writeback in
		WriteBackValue: in std_logic_vector (15 downto 0); --writeback value
		InPort: in std_logic_vector (15 downto 0); -- Input port: 16 bits
		FR1,FR2: in std_logic_vector(15 downto 0); -- Forwarded R1 and R2
		R1Out: out std_logic_vector (15 downto 0); --16 bits - Address stored in register 
		StageOutput: out std_logic_vector(50 downto 0) --51 bits
		);
end component;
component ExecuteStage is 
	port (CLK : in std_logic;
		ExecuteBufferFlush: in std_logic;
		ForceJMP: out std_logic;
		JMPIndicator: in std_logic_vector (1 downto 0); --Jump Indicator
		ExecuteControlEX: in std_logic_vector (11 downto 0); --12 bits , Control unit execute 
		MemoryFlags: in std_logic_vector(3 downto 0); --Flags from memory
		DecodeStage: in std_logic_vector(50 downto 0); --51 bits Out of Decode Stage Buffer (Previous stage)
		OP2Mux2FU: out std_logic_vector(15 downto 0); -- Mem Write Value to FU
		StageOutput: out std_logic_vector(34 downto 0) -- StageOutput 35 Bit
		);
end component;
component MemoryStage is 
	port (CLK : in std_logic;
		RST: in std_logic;
		MemoryBufferFlush: in std_logic;
		MemoryControlM: in std_logic_vector (2 downto 0); --3 bits , Control unit memory
		ExecuteStage: in std_logic_vector(34 downto 0); --35 bits Out of Decode Stage Buffer (Previous stage)
		MemoryDataOut: out std_logic_vector(15 downto 0); --Read value from memory
		OutPort: out std_logic_vector(15 downto 0); -- OUT port
		StageOutput: out std_logic_vector(34 downto 0) -- StageOutput 35 Bit
		);
end component;
component WriteBackStage is 
	port (CLK : in std_logic;
		MemoryStage: in std_logic_vector(34 downto 0); --35 bits Out of Memory Stage Buffer (Previous stage)
		WritebackControlWB: in std_logic_vector(1 downto 0); --2 bits , Control unit WB
		WriteBackValue: out std_logic_vector(15 downto 0) -- stage output is just WriteBackValue and not buffered.
		);
end component;
component ControlUnit is 
	port (CLK : in std_logic;
		ForceJMP: in std_logic;
		FetchStage: in std_logic_vector(31 downto 0); --Output of FetchStage buffer
		FlushBuffers: out std_logic;	-- FLush Decode,Execute and Memory Buffers
		FetchUpperMuxSelector: out std_logic;
		FetchBufferFlush: out std_logic;
		FetchBufferStall: out std_logic;
		DecodeInMuxSelector: out std_logic;
		DecodeImmMuxSelector: out std_logic_vector (1 downto 0);
		FetchPCMuxSelector: out std_logic_vector(1 downto 0);
		
		--First stage output, should be buffered at integration for each next stage
		JMPIndicator: out std_logic_vector(1 downto 0);
		WritebackControlWB: out std_logic_vector(1 downto 0);
		MemoryControlM: out std_logic_vector(2 downto 0);
		ExecuteControlEX: out std_logic_vector (11 downto 0)
		);
end component;
component nRegister is
	Generic ( n : integer := 8);
	port( Clk,Rst : in std_logic;
	enable: in std_logic;
	d : in std_logic_vector(n-1 downto 0);
	q : out std_logic_vector(n-1 downto 0));
end component;

-- Signals Naming Convention: name_Source_Destination


-- Between Different components
signal PCEnable_HU_F,UpperMuxSelect_CU_F, FetchBufferFlush_CU_F, FetchBufferStall_CU_F :  std_logic;
signal ForceJMP_EX_CU,FlushBuffers_CU_DExMWB, DecodeInMuxSelector_CU_D :  std_logic;
signal Jmp16R_EX_F,PC16Addr_D_F,PCMemAddr_M_F, WriteBackValue_WB_D: std_logic_vector (15 downto 0);
signal FR1_FU_D,FR2_FU_D: std_logic_vector (15 downto 0);
signal PCMuxSelector_CU_F, DecodeImmMuxSelector_CU_D: std_logic_vector(1 downto 0);
signal WriteBackAddress_M_D: std_logic_vector(2 downto 0);
signal RMuxSelector_FU_D,WriteBackEnable_M_D: std_logic;
signal MemoryDataRead_M,OP2Mux2_Ex_FU: std_logic_vector (15 downto 0);


-- Single Stages
signal FetchOutput :std_logic_vector(31 downto 0);
signal DecodeOutput:std_logic_vector(50 downto 0);
signal ExecuteOutput: std_logic_vector(34 downto 0);
signal MemoryOutput: std_logic_vector(34 downto 0);

-- Control Unit and its buffers
signal JMPIndicator_CU_D,WritebackControlWB_CU_D : std_logic_vector(1 downto 0);
signal MemoryControlM_CU_D: std_logic_vector(2 downto 0);
signal ExecuteControlEX_CU_D: std_logic_vector (11 downto 0);

signal JMPIndicator_D_Ex,WritebackControlWB_D_Ex : std_logic_vector(1 downto 0);
signal MemoryControlM_D_Ex: std_logic_vector(2 downto 0);
signal ExecuteControlEX_D_Ex: std_logic_vector (11 downto 0);


signal WritebackControlWB_Ex_M,WritebackControlWB_M_WB : std_logic_vector(1 downto 0);
signal MemoryControlM_Ex_M: std_logic_vector(2 downto 0);

Begin 
	
	
	Control: ControlUnit port map
			(CLK => CLK,
			ForceJMP => ForceJMP_EX_CU,
			FetchStage => FetchOutput,
			FlushBuffers => FlushBuffers_CU_DExMWB,
			FetchUpperMuxSelector => UpperMuxSelect_CU_F,
			FetchBufferFlush => FetchBufferFlush_CU_F,
			FetchBufferStall => FetchBufferStall_CU_F,
			DecodeInMuxSelector => DecodeInMuxSelector_CU_D,
			DecodeImmMuxSelector => DecodeImmMuxSelector_CU_D,
			FetchPCMuxSelector => PCMuxSelector_CU_F,

			--First stage output, should be buffered at integration for each next stage
			JMPIndicator => JMPIndicator_CU_D,
			WritebackControlWB => WritebackControlWB_CU_D,
			MemoryControlM => MemoryControlM_CU_D,
			ExecuteControlEX => ExecuteControlEX_CU_D
			);

	Fetch: FetchStage port map
			(
			CLK => CLK,
			PCEnable => PCEnable_HU_F,
			UpperMuxSelect => UpperMuxSelect_CU_F,
			FetchBufferFlush => FetchBufferFlush_CU_F,
			FetchBufferStall => FetchBufferStall_CU_F,
			Jmp16R => Jmp16R_EX_F,
			PC16Addr => PC16Addr_D_F,
			PCMuxSelector => PCMuxSelector_CU_F,
			PCMemAddr => PCMemAddr_M_F, 
			StageOutput => FetchOutput
			);
	
	Decode: DecodeStage port map 
			(
			CLK => CLK,
			InMuxSelector => DecodeInMuxSelector_CU_D,
			RMuxSelector => RMuxSelector_FU_D,
			WriteBackEnable => WriteBackEnable_M_D,
			DecodeBufferFlush => FlushBuffers_CU_DExMWB,
			ImmMuxSelector => DecodeImmMuxSelector_CU_D,
			FetchStage => FetchOutput,
			WriteBackAddress => WriteBackAddress_M_D,
			WriteBackValue => WriteBackValue_WB_D,
			InPort => InPort,
			FR1 => FR1_FU_D,
			FR2 => FR2_FU_D,
			R1Out => PC16Addr_D_F,
			StageOutput => DecodeOutput
			);

	DecodeBufferJmpIndicator: nRegister port map (CLK,FlushBuffers_CU_DExMWB,'1',JMPIndicator_CU_D,JMPIndicator_D_Ex);
	DecodeBufferWB: nRegister port map (CLK,FlushBuffers_CU_DExMWB,'1',WritebackControlWB_CU_D,WritebackControlWB_D_Ex);
	DecodeBufferM: nRegister port map (CLK,FlushBuffers_CU_DExMWB,'1',MemoryControlM_CU_D,MemoryControlM_D_Ex);
	DecodeBufferEx: nRegister port map (CLK,FlushBuffers_CU_DExMWB,'1',ExecuteControlEX_CU_D,ExecuteControlEX_D_Ex);
	
	
	Execute: ExecuteStage port map
			(
			CLK => CLK,
			ExecuteBufferFlush => FlushBuffers_CU_DExMWB,
			ForceJMP => ForceJMP_EX_CU,
			JMPIndicator => JMPIndicator_D_Ex,
			ExecuteControlEX => ExecuteControlEX_D_Ex,
			MemoryFlags => MemoryDataRead_M(3 downto 0),
			DecodeStage => DecodeOutput,
			OP2Mux2FU => OP2Mux2_Ex_FU,
			StageOutput => ExecuteOutput
			);

	ExecuteBufferM: nRegister port map (CLK,FlushBuffers_CU_DExMWB,'1',MemoryControlM_D_Ex,MemoryControlM_Ex_M);
	ExecuteBufferWB: nRegister port map (CLK,FlushBuffers_CU_DExMWB,'1',WritebackControlWB_D_Ex,WritebackControlWB_Ex_M);
	
	Memory: MemoryStage port map
		(
		CLK => CLK,
		RST => RST,
		MemoryBufferFlush => FlushBuffers_CU_DExMWB,
		MemoryControlM => MemoryControlM_Ex_M,
		ExecuteStage => ExecuteOutput,
		MemoryDataOut => MemoryDataRead_M,
		OutPort => OutPort,
		StageOutput => MemoryOutput
		);

	MemoryBufferWB: nRegister port map (CLK,FlushBuffers_CU_DExMWB,'1',WritebackControlWB_Ex_M,WritebackControlWB_M_WB);
	
	WriteBackEnable_M_D <= WritebackControlWB_M_WB(0);
	
	WriteBack: WriteBackStage port map
		(
		CLK => CLK,
		MemoryStage => MemoryOutput,
		WritebackControlWB => WritebackControlWB_M_WB,
		WriteBackValue => WriteBackValue_WB_D
		);

	
	
end Architecture;
