library ieee;
Use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- Flags : ZNCV (3 downto 0) ;


entity ExecuteStage is 
	port (CLK : in std_logic;
		ExecuteBufferFlush: in std_logic;
		ForceJMP: out std_logic;
		JMPIndicator: in std_logic_vector (1 downto 0); --Jump Indicator
		ExecuteControlEX: in std_logic_vector (12 downto 0); --12 bits , Control unit execute 
		MemoryFlags: in std_logic_vector(3 downto 0); --Flags from memory
		DecodeStage: in std_logic_vector(50 downto 0); --51 bits Out of Decode Stage Buffer (Previous stage)
		ExecuteMemAddress: out std_logic_vector(15 downto 0); -- Mem Write Value to FU
		StageOutput: out std_logic_vector(34 downto 0) -- StageOutput 35 Bit
		);
end entity ExecuteStage;


Architecture ExecuteStage_Implementation of ExecuteStage is  
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
component ALU is 
	generic (width : integer := 16 );
	port (OP : in std_logic_vector(3 downto 0);
		A : in std_logic_vector (width-1 downto 0);
		B : in std_logic_vector (width-1 downto 0);
		F : out std_logic_vector(width-1 downto 0);
		Cin : in std_logic_vector (0 downto 0);
		Zout,Vout,Nout,Cout: out std_logic_vector (0 downto 0)
		);
end Component;

signal ALUOutput: std_logic_vector(15 downto 0);
signal SPValue: std_logic_vector(15 downto 0);
signal OP1MuxOut,OP2MuxOutL1,OP2MuxOut: std_logic_vector(15 downto 0);
signal ALU_cin,ALU_cout,ALU_vout,ALU_nout,ALU_zout: std_logic_vector(0 downto 0);
signal ALU_flags_Rin,ALU_flags_Rout: std_logic_vector(3 downto 0);
signal EXout1,PaddedFlags: std_logic_vector(15 downto 0);
signal StageBufferIn:  std_logic_vector(34 downto 0); -- StageOutput 35 Bit
Begin 
 
	SP: nRegister generic map(n=>16) port map(CLK,'0', ExecuteControlEX(9) , ALUOutput, SPValue);
	
	OP1Mux: Mux4 generic map(width=>16) port map(ExecuteControlEX(1 downto 0),DecodeStage(15 downto 0),DecodeStage(47 downto 32),SPValue,SPValue,OP1MuxOut);
	OP2Mux: Mux2 generic map(width=>16) port map(ExecuteControlEX(2),DecodeStage(31 downto 16),DecodeStage(47 downto 32),OP2MuxOutL1);
	
	PaddedFlags <= x"000"&ALU_flags_Rout;
	FlagOROP2Mux: Mux2 generic map(width=>16) port map(ExecuteControlEX(12),OP2MuxOutL1,PaddedFlags,OP2MuxOut);
	
	
	ALU_cin <= ALU_flags_Rout(1 downto 1) when ExecuteControlEX(8)='0' else "0";
	ALUOP: ALU generic map (width=>16) port map(ExecuteControlEX(6 downto 3),OP1MuxOut,OP2MuxOut,ALUOutput,ALU_cin,ALU_zout,ALU_vout,ALU_nout,ALU_cout);
	ALU_flags_Rin<=ALU_zout&ALU_nout&ALU_cout&ALU_vout when ExecuteControlEX(11)='0' else MemoryFlags; --ZNCV
	FlagsRegister: nRegister generic map(n=>4) port map(CLK,'0', ExecuteControlEX(7), ALU_flags_Rin, ALU_flags_Rout);
	
	ExOutMux: Mux2 generic map(width=>16) port map(ExecuteControlEX(10),ALUOutput,OP1MuxOut,EXout1);
	ExecuteMemAddress <= EXout1;
	
	-- Branch Decision Unit
	ForceJMP<=	'1' when JMPIndicator="01" and ALU_flags_Rout(3)='0' else
				'1' when JMPIndicator="10" and ALU_flags_Rout(2)='1' else
				'1' when JMPIndicator="11" and ALU_flags_Rout(1)='1' else '0';
	-- END Branch Decision Unit
	
	
	StageBufferIn <= DecodeStage(50 downto 48) & OP2MuxOut & EXout1 ;
	ExecuteBuffer: nRegister generic map(n=>35) port map(CLK,ExecuteBufferFlush, '1', StageBufferIn, StageOutput);
	
	
	
end Architecture;
