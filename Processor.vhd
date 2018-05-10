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
		UpperMuxSelect: in std_logic_vector (1 downto 0); -- 1 bit upper MUX selector
		FetchBufferFlush_CU: in std_logic; -- 1 bit to clear lower FROM CU
		FetchBufferFlush_HU: in std_logic; -- 1 bit to clear lower FROM HU
		FetchBufferStall: in std_logic; -- 1 bit to stall upper Fetch
		FetchedInstruction: out std_logic_vector(15 downto 0); --Fetched Instruction before buffer to HU.
		Jmp16R : in std_logic_vector (15 downto 0); -- 16 bits - Address stored in register but for Jumps that need a condition
		PC16Addr : in std_logic_vector(15 downto 0);	--16 bits - Address stored in register 
		PCMuxSelector: in std_logic_vector(1 downto 0); --2 bits - MUX next instruction address, Fetch Buffer Control
		PCMemAddr: in std_logic_vector(15 downto 0); -- 16 bits - Address stored in memory
		StageOutput: out std_logic_vector(31 downto 0) --32 Bits
		);
end component;
component DecodeStage is 
	port (CLK : in std_logic;
	  WriteBackMuxSelector: in std_logic;
		InMuxSelector: in std_logic; -- IN mux selector
		R1MuxSelector: in std_logic; --From FU, R1 Mux Mux selector
		R2MuxSelector: in std_logic; --From FU, R2 Mux selector
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
		ExecuteControlEX: in std_logic_vector (13 downto 0); --14 bits , Control unit execute 
		MemoryFlags: in std_logic_vector(3 downto 0); --Flags from memory
		DecodeStage: in std_logic_vector(50 downto 0); --51 bits Out of Decode Stage Buffer (Previous stage)
		ExecuteMemAddress: out std_logic_vector(15 downto 0); -- Mem Write Value to FU
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
	  RST: in std_logic;
		INT: in std_logic;
		ForceJMP: in std_logic;
		FetchStage: in std_logic_vector(31 downto 0); --Output of FetchStage buffer
		FlushBuffers: out std_logic;	-- FLush Decode,Execute and Memory Buffers
		FetchUpperMuxSelector: out std_logic_vector (1 downto 0);
		FetchBufferFlush: out std_logic;
		FetchBufferStall: out std_logic;
		DecodeInMuxSelector: out std_logic;
		DecodeImmMuxSelector: out std_logic_vector (1 downto 0);
		FetchPCMuxSelector: out std_logic_vector(1 downto 0);
		
		--First stage output, should be buffered at integration for each next stage
		JMPIndicator: out std_logic_vector(1 downto 0);
		WritebackControlWB: out std_logic_vector(1 downto 0);
		MemoryControlM: out std_logic_vector(2 downto 0);
		ExecuteControlEX: out std_logic_vector (13 downto 0);
		WriteBackAddrMuxSelector: out std_logic
		);
end component;

component ForwardingUnit is 
	port (CLK : in std_logic;	  
	  MemWB: in std_logic_vector (1 downto 0);
	  MemWBAddress: in std_logic_vector (2 downto 0);
	  WBStageValue: in std_logic_vector (15 downto 0);
		FetchR1R2: in std_logic_vector(5 downto 0);
		DecodeBufferlast3: in std_logic_vector(2 downto 0);
		DecodeWB: in std_logic_vector(1 downto 0);
		ExecuteWB: in std_logic_vector(1 downto 0);
		ExecuteMemAddress: in std_logic_vector(15 downto 0);
		ExecuteWBAddress: in std_logic_vector(2 downto 0);
		ExecuteMemAddressBuffered: in std_logic_vector(8 downto 0);
		MemoryValueRead: in std_logic_vector(15 downto 0);
		FR1,FR2: out std_logic_vector(15 downto 0);
		FS1,FS2: out std_logic
		);
end component;

component HazardDetectionUnit is 
	port (CLK : in std_logic;
		DecodeWBAddress: in std_logic_vector(2 downto 0);
		InstructionMemory: in std_logic_vector(15 downto 0);
		Is_Load: in std_logic;
		FlushFetchBufer:out std_logic;
		PCEnable: out std_logic
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
signal PCEnable_HU_F, FetchBufferFlush_HU_F, FetchBufferFlush_CU_F, FetchBufferStall_CU_F :  std_logic;
signal UpperMuxSelect_CU_F : std_logic_vector (1 downto 0);
signal ForceJMP_EX_CU,FlushBuffers_CU_DExMWB, DecodeInMuxSelector_CU_D :  std_logic;
signal PC16Addr_D_F, WriteBackValue_WB_D: std_logic_vector (15 downto 0);
signal FR1_FU_D,FR2_FU_D: std_logic_vector (15 downto 0);
signal PCMuxSelector_CU_F, DecodeImmMuxSelector_CU_D: std_logic_vector(1 downto 0);
signal WriteBackAddress_M_D: std_logic_vector(2 downto 0);
signal R1MuxSelector_FU_D,R2MuxSelector_FU_D,WriteBackEnable_M_D: std_logic;
signal MemoryDataRead_M,ExecuteMemAddress_Ex_FU: std_logic_vector (15 downto 0);
signal FetchedInstruction_F_HU: std_logic_vector(15 downto 0);

-- Single Stages
signal FetchOutput :std_logic_vector(31 downto 0);
signal DecodeOutput:std_logic_vector(50 downto 0);
signal ExecuteOutput: std_logic_vector(34 downto 0);
signal MemoryOutput: std_logic_vector(34 downto 0);

-- Control Unit and its buffers
signal JMPIndicator_CU_D,WritebackControlWB_CU_D : std_logic_vector(1 downto 0);
signal MemoryControlM_CU_D: std_logic_vector(2 downto 0);
signal ExecuteControlEX_CU_D: std_logic_vector (13 downto 0);

signal JMPIndicator_D_Ex,WritebackControlWB_D_Ex : std_logic_vector(1 downto 0);
signal MemoryControlM_D_Ex: std_logic_vector(2 downto 0);
signal ExecuteControlEX_D_Ex: std_logic_vector (13 downto 0);


signal WritebackControlWB_Ex_M,WritebackControlWB_M_WB : std_logic_vector(1 downto 0);
signal MemoryControlM_Ex_M: std_logic_vector(2 downto 0);
signal WriteBackAddrMuxSelector_CU_D: std_logic := '0';

Begin 
	
	
	Control: ControlUnit port map
			(CLK => CLK,
			RST => RST,
			INT => INT,
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
			ExecuteControlEX => ExecuteControlEX_CU_D,
			WriteBackAddrMuxSelector => WriteBackAddrMuxSelector_CU_D
			);
			
	Fetch: FetchStage port map
			(
			CLK => CLK,
			PCEnable => PCEnable_HU_F,
			UpperMuxSelect => UpperMuxSelect_CU_F,
			FetchBufferFlush_CU => FetchBufferFlush_CU_F,
			FetchBufferFlush_HU => FetchBufferFlush_HU_F,
			FetchBufferStall => FetchBufferStall_CU_F,
			FetchedInstruction => FetchedInstruction_F_HU,
			Jmp16R => DecodeOutput(15 downto 0),
			PC16Addr => PC16Addr_D_F,
			PCMuxSelector => PCMuxSelector_CU_F,
			PCMemAddr => MemoryDataRead_M, 
			StageOutput => FetchOutput
			);
	
	Decode: DecodeStage port map 
			(
			CLK => CLK,
			WriteBackMuxSelector => WriteBackAddrMuxSelector_CU_D,
			InMuxSelector => DecodeInMuxSelector_CU_D,
			R1MuxSelector => R1MuxSelector_FU_D,
			R2MuxSelector => R2MuxSelector_FU_D,
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

	DecodeBufferJmpIndicator: nRegister generic map(n=>2) port map (CLK,FlushBuffers_CU_DExMWB,'1',JMPIndicator_CU_D,JMPIndicator_D_Ex);
	DecodeBufferWB: nRegister generic map(n=>2) port map (CLK,FlushBuffers_CU_DExMWB,'1',WritebackControlWB_CU_D,WritebackControlWB_D_Ex);
	DecodeBufferM: nRegister generic map(n=>3) port map (CLK,FlushBuffers_CU_DExMWB,'1',MemoryControlM_CU_D,MemoryControlM_D_Ex);
	DecodeBufferEx: nRegister generic map(n=>14) port map (CLK,FlushBuffers_CU_DExMWB,'1',ExecuteControlEX_CU_D,ExecuteControlEX_D_Ex);


	Execute: ExecuteStage port map
			(
			CLK => CLK,
			ExecuteBufferFlush => '0',
			ForceJMP => ForceJMP_EX_CU,
			JMPIndicator => JMPIndicator_D_Ex,
			ExecuteControlEX => ExecuteControlEX_D_Ex,
			MemoryFlags => MemoryDataRead_M(3 downto 0),
			DecodeStage => DecodeOutput,
			ExecuteMemAddress => ExecuteMemAddress_Ex_FU,
			StageOutput => ExecuteOutput
			);

	ExecuteBufferM: nRegister generic map(n=>3) port map (CLK,'0','1',MemoryControlM_D_Ex,MemoryControlM_Ex_M);
	ExecuteBufferWB: nRegister generic map(n=>2) port map (CLK,'0','1',WritebackControlWB_D_Ex,WritebackControlWB_Ex_M);
	
	Memory: MemoryStage port map
		(
		CLK => CLK,
		RST => RST,
		MemoryBufferFlush => '0',
		MemoryControlM => MemoryControlM_Ex_M,
		ExecuteStage => ExecuteOutput,
		MemoryDataOut => MemoryDataRead_M,
		OutPort => OutPort,
		StageOutput => MemoryOutput
		);

	MemoryBufferWB: nRegister generic map(n=>2) port map (CLK,'0','1',WritebackControlWB_Ex_M,WritebackControlWB_M_WB);
	
	WriteBackAddress_M_D <= MemoryOutput(34 downto 32);
	WriteBackEnable_M_D <= WritebackControlWB_M_WB(0);
	
	WriteBack: WriteBackStage port map
		(
		CLK => CLK,
		MemoryStage => MemoryOutput,
		WritebackControlWB => WritebackControlWB_M_WB,
		WriteBackValue => WriteBackValue_WB_D
		);

	
	HazardDetectionUnit1: HazardDetectionUnit port map
		(
		CLK => CLK,
		DecodeWBAddress => FetchOutput(12 downto 10),
		InstructionMemory => FetchedInstruction_F_HU,
		Is_Load => WriteBackAddrMuxSelector_CU_D,
		FlushFetchBufer => FetchBufferFlush_HU_F,
		PCEnable => PCEnable_HU_F
		);
	
	
	ForwardingUnit1: ForwardingUnit port map
		(
		CLK => CLK,		
	  MemWB => WritebackControlWB_M_WB,
	  MemWBAddress => WriteBackAddress_M_D,
	  WBStageValue => WriteBackValue_WB_D,
		FetchR1R2 => FetchOutput(12 downto 7),
		DecodeBufferlast3 => DecodeOutput(50 downto 48),
		DecodeWB => WritebackControlWB_D_Ex,
		ExecuteWB => WritebackControlWB_Ex_M,
		ExecuteMemAddress => ExecuteMemAddress_Ex_FU,
		ExecuteWBAddress => ExecuteOutput(34 downto 32),
		ExecuteMemAddressBuffered => ExecuteOutput(8 downto 0),
		MemoryValueRead => MemoryDataRead_M,
		FR1 => FR1_FU_D,
		FR2 => FR2_FU_D,
		FS1 => R1MuxSelector_FU_D,
		FS2 => R2MuxSelector_FU_D
		);
	
	
end Architecture;
