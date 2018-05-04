library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Entity regFile is
	generic (addr_width : integer := 16; width : integer := 8);  
	port ( clk : in std_logic;
		we : in std_logic;
		address1,address2 : in std_logic_vector(addr_width-1 downto 0);
		writeaddress : in std_logic_vector(addr_width-1 downto 0);
		datain : in std_logic_vector(width-1 downto 0);
		dataout1,dataout2 : out std_logic_vector(width-1 downto 0) );
end entity regFile;

architecture regFilea of regFile is
type registers_type is array (0 to 2**addr_width-1) of std_logic_vector(width-1 downto 0);
signal registers : registers_type;
begin
	process(clk) is
	begin
		if rising_edge(clk) then
			if we = '1' then
				registers(to_integer(unsigned(writeaddress))) <= datain;
			end if;
		end if;
	end process;
	dataout1 <= registers(to_integer(unsigned(address1)));
	dataout2 <= registers(to_integer(unsigned(address2)));
end architecture regFilea;