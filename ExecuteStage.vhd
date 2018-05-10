library ieee;
Use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- Flags : ZNCV (3 downto 0) ;


entity ExecuteStage is 
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

signal ALUOutput: std_logic_vector(15 downto 0) := "0000000111111111";
signal SPValue: std_logic_vector(15 downto 0);
signal OP1MuxOut,OP2MuxOutL1,OP2MuxOut: std_logic_vector(15 downto 0);
signal ALU_cin,ALU_cout,ALU_vout,ALU_nout,ALU_zout: std_logic_vector(0 downto 0);
signal ALU_flags_Mux,ALU_flags_Rin,ALU_flags_Rout: std_logic_vector(3 downto 0);
signal EXout1,PaddedFlags: std_logic_vector(15 downto 0);
signal StageBufferIn:  std_logic_vector(34 downto 0); -- StageOutput 35 Bit
signal R2Value: std_logic_vector(15 downto 0);
signal DupEXCUbits: std_logic_vector(13 downto 0) := "00000000000010";
signal ForceJMPInternal,FlagsWen: std_logic; --Flags write enable.
Begin 
  
	DupEXCUbits <= ExecuteControlEX;

	SP: nRegister generic map(n=>16) port map(CLK,'0', DupEXCUbits(9) , ALUOutput, SPValue);

	OP1Mux: Mux4 generic map(width=>16) port map(DupEXCUbits(1 downto 0),DecodeStage(15 downto 0),DecodeStage(47 downto 32),SPValue,SPValue,OP1MuxOut);
	OP2Mux: Mux2 generic map(width=>16) port map(DupEXCUbits(2),R2Value,DecodeStage(47 downto 32),OP2MuxOutL1);
	R2MUX:  Mux2 generic map(width=>16) port map(DupEXCUbits(13),DecodeStage(31 downto 16),DecodeStage(15 downto 0),R2Value);

	PaddedFlags <= x"000"&ALU_flags_Rout;
	FlagOROP2Mux: Mux2 generic map(width=>16) port map(DupEXCUbits(12),OP2MuxOutL1,PaddedFlags,OP2MuxOut);


	ALU_cin <= ALU_flags_Rout(1 downto 1) when DupEXCUbits(8)='1' else "0";
	ALUOP: ALU generic map (width=>16) port map(DupEXCUbits(6 downto 3),OP1MuxOut,OP2MuxOut,ALUOutput,ALU_cin,ALU_zout,ALU_vout,ALU_nout,ALU_cout);
	ALU_flags_Mux<=ALU_zout&ALU_nout&ALU_cout&ALU_vout when DupEXCUbits(11)='0' else MemoryFlags; --ZNCV
	
	ALU_flags_Rin <= '0'&ALU_flags_Rout(2 downto 0) when ForceJMPInternal='1' and JMPIndicator="01" else -- JZ condition true, consume Z flag
					  ALU_flags_Rout(3)&'0'&ALU_flags_Rout(1 downto 0) when ForceJMPInternal='1' and JMPIndicator="10" else  -- JN condition true, consume N flag
					  ALU_flags_Rout(3 downto 2)&'0'&ALU_flags_Rout(0) when ForceJMPInternal='1' and JMPIndicator="11" else  -- JC condition true, consume C flag
					  ALU_flags_Rout(3 downto 2)&'0'&ALU_flags_Rout(0) when DupEXCUbits(6 downto 3)="1001" else --CLRC
					  ALU_flags_Rout(3 downto 2)&'1'&ALU_flags_Rout(0) when DupEXCUbits(6 downto 3)="1000" else --SETC
					  ALU_flags_Mux; -- Default, use flags from mux.
	
	
	FlagsWen <= ForceJMPInternal or DupEXCUbits(7);
	FlagsRegister: nRegister generic map(n=>4) port map(CLK,'0', FlagsWen, ALU_flags_Rin, ALU_flags_Rout);

	ExOutMux: Mux2 generic map(width=>16) port map(DupEXCUbits(10),ALUOutput,OP1MuxOut,EXout1);
	ExecuteMemAddress <= EXout1;

	-- Branch Decision Unit
	ForceJMPInternal<=	'1' when JMPIndicator="01" and ALU_flags_Rout(3)='1' else
						'1' when JMPIndicator="10" and ALU_flags_Rout(2)='1' else
						'1' when JMPIndicator="11" and ALU_flags_Rout(1)='1' else '0';
						
	ForceJMP <= ForceJMPInternal;
	-- END Branch Decision Unit


	StageBufferIn <= DecodeStage(50 downto 48) & OP2MuxOut & EXout1 ;
	ExecuteBuffer: nRegister generic map(n=>35) port map(CLK,ExecuteBufferFlush, '1', StageBufferIn, StageOutput);

	
	
end Architecture;
