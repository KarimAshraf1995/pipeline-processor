library ieee;
Use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


entity DecodeStage is 
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
end entity DecodeStage;


Architecture DecodeStage_Implementation of DecodeStage is  
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
component regFile is
	generic (addr_width : integer := 16; width : integer := 8);  
	port ( clk : in std_logic;
		we : in std_logic;
		address1,address2 : in std_logic_vector(addr_width-1 downto 0);
		writeaddress : in std_logic_vector(addr_width-1 downto 0);
		datain : in std_logic_vector(width-1 downto 0);
		dataout1,dataout2 : out std_logic_vector(width-1 downto 0) );
end component;

signal value0extended: std_logic_vector(15 downto 0);
signal value1extended: std_logic_vector(15 downto 0);
signal ImmMuxOut: std_logic_vector(15 downto 0);
signal RegR1,RegR2: std_logic_vector(15 downto 0);
signal R1Mux0Out,R1Mux1Out,R2MuxOut: std_logic_vector(15 downto 0);
signal StageBufferIn : std_logic_vector(50 downto 0);
signal WBAddrMuxOut : std_logic_vector (2 downto 0);
Begin  
	
	value0extended <= "00000000000"&FetchStage(6 downto 2);
	value1extended <= "0000000"&FetchStage(9 downto 1);
	
	ImmMux: Mux4 generic map(width=>16) port map(ImmMuxSelector,value0extended,FetchStage(31 downto 16),value1extended,x"0001",ImmMuxOut);
	RegisterFile: regFile generic map(addr_width=>3,width=>16) port map (CLK,WriteBackEnable,FetchStage(12 downto 10),FetchStage(9 downto 7),WriteBackAddress,WriteBackValue,RegR1,RegR2);
	
	R1Mux0: Mux2 generic map(width=>16) port map(R1MuxSelector, RegR1,FR1,R1Mux0Out);
	R1Out<=R1Mux0Out;
	
	R1Mux1: Mux2 generic map(width=>16) port map(InMuxSelector, R1Mux0Out,InPort,R1Mux1Out);
	R2Mux: Mux2 generic map(width=>16) port map(R2MuxSelector, RegR2,FR2,R2MuxOut);
  WBAddrMux: Mux2 generic map(width=>3) port map(WriteBackMuxSelector, FetchStage(9 downto 7),FetchStage(12 downto 10),WBAddrMuxOut);
	
	
	StageBufferIn <= WBAddrMuxOut&ImmMuxOut&R2MuxOut&R1Mux1Out;
	DecodeBuffer: nRegister generic map(n=>51) port map(CLK,DecodeBufferFlush, '1', StageBufferIn, StageOutput);
	
	
	
end Architecture;
