library ieee;
use ieee.std_logic_1164.all;


entity ALU is 
	generic (width : integer := 16 );
	port (OP : in std_logic_vector(3 downto 0);
		A : in std_logic_vector (width-1 downto 0);
		B : in std_logic_vector (width-1 downto 0);
		F : out std_logic_vector(width-1 downto 0);
		Cin : in std_logic_vector (0 downto 0);
		Zout,Vout,Nout,Cout: out std_logic_vector (0 downto 0)
		);
end entity ALU;


Architecture ALU_Implementation of ALU is  
signal F1,F2,F3,F4 : std_logic_vector (width-1 downto 0);
signal Aa,Bb : std_logic_vector (width-1 downto 0);
signal Acin : std_logic_vector (0 downto 0);
signal Z1,Z2,Z3,Z4,ZMux : std_logic_vector (0 downto 0);
signal N1,N2,N3,N4 : std_logic_vector (0 downto 0);
signal C1,C3,C4,CMux : std_logic_vector (0 downto 0);
signal V1,V3,V4 : std_logic_vector (0 downto 0);
signal ALUOP: std_logic_vector (3 downto 0);

Component AU1 is 
	generic (width : integer := 16 );
	port (S : in std_logic_vector(1 downto 0);
		A : in std_logic_vector (width-1 downto 0);
		B : in std_logic_vector (width-1 downto 0);
		F : out std_logic_vector(width-1 downto 0);
		Cin: in std_logic_vector (0 downto 0);
		Zout,Vout,Nout,Cout: out std_logic_vector (0 downto 0) );
End Component;

Component AU2 is 
	generic (width : integer := 16 );  
	port (S : in std_logic_vector(1 downto 0);
		A : in std_logic_vector (width-1 downto 0);
		B : in std_logic_vector (width-1 downto 0);
		F : out std_logic_vector(width-1 downto 0);
		Cin: in std_logic_vector (0 downto 0);
		Zout,Vout,Nout,Cout: out std_logic_vector (0 downto 0));
End Component;

Component AU3 is 
	generic (width : integer := 16 );  
	port (S : in std_logic_vector(1 downto 0);
		A : in std_logic_vector (width-1 downto 0);
		B : in std_logic_vector (width-1 downto 0);
		F : out std_logic_vector(width-1 downto 0);
		Cin: in std_logic_vector (0 downto 0);
		Zout,Vout,Nout,Cout: out std_logic_vector (0 downto 0));
End Component;


Component MyLU is 
	generic (width : integer := 16 );  
	port (S : in std_logic_vector(1 downto 0);
		A : in std_logic_vector (width-1 downto 0);
		B : in std_logic_vector (width-1 downto 0);
		F : out std_logic_vector(width-1 downto 0);
		Zout,Nout: out std_logic_vector (0 downto 0));
End Component;

Component Mux4 is 
	generic (width : integer := 16 );  
	port (S : in std_logic_vector(1 downto 0);
		A : in std_logic_vector (width-1 downto 0);
		B : in std_logic_vector (width-1 downto 0);
		C : in std_logic_vector (width-1 downto 0);
		D : in std_logic_vector (width-1 downto 0);
		F : out std_logic_vector(width-1 downto 0)
		);
end Component;

Begin 

-- MAP to alu opcodes
-- OR	<0000>
-- AND	0001
-- ADD	0010
-- SUB	0011
-- RLC 0100
-- RRC 0101
-- SHL 0110
-- SHR 0111
-- SETC 1000
-- CLRC 1001
-- INCOperand1 1010
-- DECOperand1 1011
-- NOT 	1100
-- NEG<1110>  1110

ALUOP <= "0101" when OP="0000" else  -- OR
		"0100" when OP="0001" else   -- AND
		"0001" when OP="0010" else	 -- ADD
		"0010" when OP="0011" else	 -- SUB
		"1110" when OP="0100" else   -- RLC
		"1010" when OP="0101" else	 -- RRC
		"1100" when OP="0110" else	 -- SHL 
		"1000" when OP="0111" else	 -- SHR
		"1111" when OP="1000" else 	 -- SETC
		"1111" when OP="1001" else	 -- CLRC
		"0000" when OP="1010" else	 -- INCOperand1
		"0011" when OP="1011" else	 -- DECOperand1
		"0111" when OP="1100" else	 -- NOT
		"0010" when OP="1110" else   -- NEG
		"1111";


Aa <= (others=>'0') when OP="1110" else A;
Bb <= A when OP="1110" else B;
Acin <= "0"	when OP="1011" OR OP="0010" else "1" when OP="1010" OR OP="1110" OR OP="0011" else Cin;

Cout <= "1" when OP="1000" else "0" when OP="1001" else CMux;
Zout <= "0" when OP="1000" OR OP="1001" else Zmux;

-- Orignal ALU

		
-- Changed This in Lab 3 
AU1_Internal1: AU3 generic map(width) port map(ALUOP(1 downto 0), Aa, Bb, F1, Acin, Z1, V1, N1, C1); 
-- 

LU_Internal : MyLU generic map(width)  port map(ALUOP(1 downto 0), Aa, Bb, F2,Z2,N2);
AU1_Internal: AU1 generic map(width)  port map(ALUOP(1 downto 0), Aa, Bb, F3, Acin, Z3, V3, N3, C3);  
AU2_Internal: AU2 generic map(width)  port map(ALUOP(1 downto 0), Aa, Bb, F4, Acin, Z4, V4, N4, C4);  


Mux4_F : Mux4 generic map(width) port map(ALUOP(3 downto 2), F1,F2,F3,F4,F);
Mux4_C : Mux4 generic map(width => 1 ) port map(ALUOP(3 downto 2), C1,C3,C3,C4,CMux);
Mux4_V : Mux4 generic map(width => 1 ) port map(ALUOP(3 downto 2), V1,V3,V3,V4,Vout);
Mux4_Z : Mux4 generic map(width => 1 ) port map(ALUOP(3 downto 2), Z1,Z2,Z3,Z4,ZMux);
Mux4_N : Mux4 generic map(width => 1 ) port map(ALUOP(3 downto 2), N1,N2,N3,Z4,Nout);
  
end Architecture;


