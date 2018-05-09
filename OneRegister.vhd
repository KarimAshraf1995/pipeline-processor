Library ieee;
use ieee.std_logic_1164.all;
Entity OneRegister is
port( d,clk,rst, enable: in std_logic;
q : out std_logic);
end OneRegister;

Architecture OneRegister_Implementation of OneRegister is

signal qi : std_logic := '1';

begin
  q <= qi;
  
process(clk,rst)
begin

if clk'event and clk = '1' then   
	if(rst = '1') then
        qi <= '0';
	elsif (enable = '1') then          
 	    qi <= d;
	end if;
end if;
end process;
end OneRegister_Implementation;

