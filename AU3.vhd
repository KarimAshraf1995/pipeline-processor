library ieee;
use ieee.std_logic_1164.all;


entity AU3 is 
	generic (width : integer := 16 );  
	port (S : in std_logic_vector(1 downto 0);
		A : in std_logic_vector (width-1 downto 0);
		B : in std_logic_vector (width-1 downto 0);
		F : out std_logic_vector(width-1 downto 0);
		Cin: in std_logic_vector (0 downto 0);
		Zout,Vout,Nout,Cout: out std_logic_vector (0 downto 0));
end entity AU3;


Architecture AU3_Implementation of AU3 is  
signal Aa,Bb,Z: std_logic_vector(width-1 downto 0);
signal C: std_logic_vector(0 downto 0);
signal R: std_logic_vector(width-1 downto 0);


Component FullNAdder is 
Generic (n : integer := 16);
PORT    (a, b : in std_logic_vector(n-1 downto 0) ;
		cin : in std_logic_vector(0 downto 0);
		s : out std_logic_vector(n-1 downto 0);
		cout : out std_logic_vector(0 downto 0));

end Component;



Begin 

Aa <= A;

Bb <= 
(others => '0')	when S="00" else
B	when S="01" else
not B	when S="10" else
(others => '1') when S="11" and Cin="0" else
not A;


OP: FullNAdder generic map(width) port map(Aa,Bb,Cin,R,C);

F<=R;

Cout <= not C  when S="10" OR S="11"
else C;
Z(0) <= R(0);
ZeroGenerate: for i in 1 to width-1 generate Z(i) <= Z(i-1) OR R(i); end generate;
Zout(0) <= not Z(width-1);
Nout <= "1"	 when R(width-1)='1' else "0";
-- Change This Later
Vout <= "0";
end Architecture;
