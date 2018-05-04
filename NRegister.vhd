Library ieee;
Use ieee.std_logic_1164.all;

Entity nRegister is
	Generic ( n : integer := 8);
	port( Clk,Rst : in std_logic;
	enable: in std_logic;
	d : in std_logic_vector(n-1 downto 0);
	q : out std_logic_vector(n-1 downto 0));
end nRegister;

Architecture b_nRegister of nRegister is
Component OneRegister is
	port( d,clk,rst, enable: in std_logic;
	q : out std_logic);
end component;
begin
	loop1: for i in 0 to n-1 generate
		fx: OneRegister port map(d(i),Clk,Rst,enable,q(i));
	end generate;
end b_nRegister;

