library ieee;
use ieee.std_logic_1164.all;



entity MyLU is 
	generic (width : integer := 16 );  
	port (S : in std_logic_vector(1 downto 0);
		A : in std_logic_vector (width-1 downto 0);
		B : in std_logic_vector (width-1 downto 0);
		F : out std_logic_vector(width-1 downto 0);
		Zout,Nout: out std_logic_vector (0 downto 0));
end entity MyLU;


Architecture LU_Implementation of MyLU is  
signal R,Z: std_logic_vector(width-1 downto 0);

Begin 
	R <= 	A and B when S="00" else
		A  or B when S="01" else
		A xor B when S="10" else
		  not A; 	 

F<=R;		  
Z(0) <= R(0);
ZeroGenerate: for i in 1 to width-1 generate Z(i) <= Z(i-1) OR R(i); end generate;
Zout(0) <= not Z(width-1);
Nout <= "1"	 when R(width-1)='1' else "0";		  
		  
end Architecture;

-- 0F0F  000A  and 000A
-- 0F0F 000A or 0F0F
-- 0F0F 000A xor 0F05
-- 0F0F NOT F0F0