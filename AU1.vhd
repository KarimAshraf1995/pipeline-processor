library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity AU1 is 
	generic (width : integer := 16 );  
	port (S : in std_logic_vector(1 downto 0);
		A : in std_logic_vector (width-1 downto 0);
		B : in std_logic_vector (width-1 downto 0);
		F : out std_logic_vector(width-1 downto 0);
		Cin: in std_logic_vector (0 downto 0);
		Zout,Vout,Nout,Cout: out std_logic_vector (0 downto 0));
end entity AU1;


Architecture AU1_Implementation of AU1 is  
signal R,Z: std_logic_vector(width-1 downto 0);

Begin 
	R <= to_stdlogicvector(to_bitvector(A) srl to_integer(unsigned(B))) when S="00" else 
		A(0) & A(width-1 downto 1) when S="01" else
		Cin(0) & A(width-1 downto 1) when S="10" else
		A(width-1) & A(width-1 downto 1); 

	Cout(0) <= A(0);
	
	F<=R;
	Z(0) <= R(0);
	ZeroGenerate: for i in 1 to width-1 generate Z(i) <= Z(i-1) OR R(i); end generate;
	Zout(0) <= not Z(width-1);
	Nout <= "1"	 when R(width-1)='1' else "0";
	-- Change This Later
	Vout <= "0";
  
end Architecture;

-- 0F0F 00 -> 0787
-- 0F0F 01 -> 8787 
-- 0F0F 0  10 0787 
-- 0F0F 1  10 8787
-- F0F0  11  F878 
 	 
