library ieee;
Use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ControlUnit is 
	port (CLK : in std_logic;
		ForceJMP: in std_logic;
		FetchStage: in std_logic_vector(31 downto 0); --Output of FetchStage buffer
		FlushBuffers: out std_logic;	-- FLush Decode,Execute and Memory Buffers
		FetchUpperMuxSelector: out std_logic;
		FetchBufferFlush: out std_logic;
		FetchBufferStall: out std_logic;
		DecodeImmMuxSelector: out std_logic;
		FetchPCMuxSelector: out std_logic_vector(1 downto 0);
		
		--First stage output, should be buffered at integration for each next stage
		JMPIndicator: out std_logic_vector(1 downto 0);
		WritebackControlWB: out std_logic_vector(1 downto 0);
		MemoryControlM: out std_logic_vector(3 downto 0);
		ExecuteControlEX: out std_logic_vector (11 downto 0);
		);
end entity ControlUnit;


Architecture ControlUnit_Implementation of ControlUnit is  

Begin 
 
	
	
end Architecture;
