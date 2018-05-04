library ieee;
use ieee.std_logic_1164.all;


entity Mux2 is 
	generic (width : integer := 16 );  
	port (S : in std_logic;
		A : in std_logic_vector (width-1 downto 0);
		B : in std_logic_vector (width-1 downto 0);
		F : out std_logic_vector(width-1 downto 0)
		);
end entity Mux2;


Architecture Mux2_Implementation of Mux2 is  
Begin 
	F <=  A when S='0' else B;
end Architecture;
