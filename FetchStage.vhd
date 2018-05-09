library ieee;
Use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


entity FetchStage is 
	port (CLK : in std_logic;
		PCEnable : in std_logic; -- PC enable - HDU
		UpperMuxSelect: in std_logic; -- 1 bit upper MUX selector
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
end entity FetchStage;


Architecture FetchStage_Implementation of FetchStage is  
component Mux2 is 
	generic (width : integer := 16 );  
	port (S : in std_logic;
		A : in std_logic_vector (width-1 downto 0);
		B : in std_logic_vector (width-1 downto 0);
		F : out std_logic_vector(width-1 downto 0)
		);
end component;
component Mux4 is 
	generic (width : integer := 16 );  
	port (S : in std_logic_vector(1 downto 0);
		A : in std_logic_vector (width-1 downto 0);
		B : in std_logic_vector (width-1 downto 0);
		C : in std_logic_vector (width-1 downto 0);
		D : in std_logic_vector (width-1 downto 0);
		F : out std_logic_vector(width-1 downto 0)
		);
end Component;
component nRegister is
	Generic ( n : integer := 8);
	port( Clk,Rst : in std_logic;
	enable: in std_logic;
	d : in std_logic_vector(n-1 downto 0);
	q : out std_logic_vector(n-1 downto 0));
end component;
component syncram is
	generic (addr_width : integer := 16; width : integer := 8);  
	port ( clk : in std_logic;
		we : in std_logic;
		address : in std_logic_vector(addr_width-1 downto 0);
		datain : in std_logic_vector(width-1 downto 0);
		dataout : out std_logic_vector(width-1 downto 0) );
end component;

signal PCAdderFeedback: std_logic_vector (15 downto 0);
signal PCMuxOut: std_logic_vector (15 downto 0);
signal PCRegOut: std_logic_vector (15 downto 0);
signal FetchedInstructionInternal: std_logic_vector (15 downto 0) := "0000000000000000";
signal UpperMuxOut: std_logic_vector (15 downto 0);

signal StageBufferUpperOut: std_logic_vector (15 downto 0);
signal StageBufferLowerOut: std_logic_vector (15 downto 0);
signal StallLower: std_logic;
signal FlushLower: std_logic;
signal FetchBufferFlush: std_logic;
Begin 
	
	PC_MUX: Mux4 generic map(width=>16) port map(PCMuxSelector,PC16Addr,PCMemAddr,PCAdderFeedback,Jmp16R,PCMuxOut);
	PCAdderFeedback <= PCRegOut + 1;
	PC: nRegister generic map(n=>16) port map(CLK,'0',PCEnable,PCMuxOut,PCRegOut);
	Instruction_MEM: syncram generic map(addr_width=>9, width=>16) port map(CLK,'0',PCRegOut(8 downto 0),(others=>'0'),FetchedInstructionInternal);
	UPPER_MUX: Mux2 generic map(width=>16) port map(UpperMuxSelect,FetchedInstructionInternal,PC16Addr,UpperMuxOut);
	FetchedInstruction <= FetchedInstructionInternal;
	
	
	StallLower <= not FetchBufferStall;
	FetchBufferFlush <= FetchBufferFlush_CU or FetchBufferFlush_HU;
	FlushLower <= FetchBufferFlush and not FetchBufferStall;
	LowerFetchBuffer: nRegister generic map(n=>16) port map(CLK,FlushLower, StallLower, FetchedInstructionInternal, StageOutput(15 downto 0));
	UpperFetchBuffer: nRegister generic map(n=>16) port map(CLK,'0', '1',UpperMuxOut, StageOutput(31 downto 16));
	
	
end Architecture;
