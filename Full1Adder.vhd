Library ieee;
Use ieee.std_logic_1164.all;
Entity Full1Adder is
	port( a,b,cin : in std_logic;
		s,cout : out std_logic); 
		end Full1Adder;
Architecture Full1Adder_Implementation of Full1Adder is
begin

	s <= a xor b xor cin;
	cout <= (a and b) or (cin and (a xor b));

end Full1Adder_Implementation;

