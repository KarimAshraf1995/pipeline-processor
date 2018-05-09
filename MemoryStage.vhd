library ieee;
Use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;




entity MemoryStage is 
	port (CLK : in std_logic;
		RST: in std_logic;
		MemoryBufferFlush: in std_logic;
		MemoryControlM: in std_logic_vector (2 downto 0); --3 bits , Control unit memory
		ExecuteStage: in std_logic_vector(34 downto 0); --35 bits Out of Execute Stage Buffer (Previous stage)
		MemoryDataOut: out std_logic_vector(15 downto 0); --Read value from memory
		OutPort: out std_logic_vector(15 downto 0); -- OUT port
		StageOutput: out std_logic_vector(34 downto 0) -- StageOutput 35 Bit
		);
end entity MemoryStage;


Architecture MemoryStage_Implementation of MemoryStage is  

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

signal StageBufferIn: std_logic_vector(34 downto 0); -- StageOutput 35 Bit
signal MemoryAddress: std_logic_vector(8 downto 0);
signal SyncRamOut,MemoryOut: std_logic_vector(15 downto 0);

Begin 
 
	-- Intentialy latched
	OutPort<=ExecuteStage(15 downto 0) when MemoryControlM(2)='1';
	
	MemoryAddress <= ExecuteStage(8 downto 0) when RST='0' else (others=>'0');
	
	Data_MEM: syncram generic map(addr_width=>9, width=>16) port map(CLK,MemoryControlM(0),MemoryAddress,ExecuteStage(31 downto 16),SyncRamOut);
	MemoryOut <= SyncRamOut when MemoryControlM(1)='1' else (others=>'Z');
 
	MemoryDataOut<=MemoryOut;
	
	StageBufferIn <= ExecuteStage(34 downto 32) & ExecuteStage(15 downto 0) & MemoryOut;
	ExecuteBuffer: nRegister generic map(n=>35) port map(CLK,MemoryBufferFlush, '1', StageBufferIn, StageOutput);
	
end Architecture;
