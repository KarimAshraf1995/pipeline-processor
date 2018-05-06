library ieee;
Use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ForwardingUnit is 
	port (CLK : in std_logic;
		DecodeWB: in std_logic_vector(1 downto 0);
		DecodeEX: in std_logic_vector(1 downto 0);
		DecodeR2: in std_logic_vector(15 downto 0);
		ExecuteOP2: in std_logic_vector(15 downto 0);
		FetchR1R2: in std_logic_vector(5 downto 0);
		ExecuteWBAddr: in std_logic_vector(3 downto 0);
		ExecuteMemAddr:in std_logic_vector(9 downto 0);
		MemoryMemoryRead: in std_logic_vector(15 downto 0);
		FR1,FR2: out std_logic_vector(15 downto 0)
		);
end entity ForwardingUnit;


Architecture ForwardingUnit_Implementation of ForwardingUnit is  
Begin 
 
	
	
end Architecture;
