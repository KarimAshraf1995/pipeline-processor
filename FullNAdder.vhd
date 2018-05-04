Library ieee;
Use ieee.std_logic_1164.all;
 
ENTITY FullNAdder IS
Generic (n : integer := 16);
PORT    (a, b : in std_logic_vector(n-1 downto 0) ;
		cin : in std_logic_vector(0 downto 0);
		s : out std_logic_vector(n-1 downto 0);
		cout : out std_logic_vector(0 downto 0));
END FullNAdder;

Architecture FullNAdder_Implementation of FullNAdder is
	Component Full1Adder is
		port( a,b,cin : in std_logic; s,cout : out std_logic);
	end component;

	signal temp : std_logic_vector(n-1 downto 0);
	begin
		f0 : Full1Adder port map(a(0),b(0),cin(0),s(0),temp(0));
		loop1: for i in 1 to n-1 generate
			fx: Full1Adder port map(a(i),b(i),temp(i-1),s(i),temp(i));
		end generate;
		cout(0) <= temp(n-1);
end FullNAdder_Implementation;
