library ieee;
Use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WriteBackStage is 
	port (CLK : in std_logic;
		MemoryStage: in std_logic_vector(34 downto 0); --35 bits Out of Memory Stage Buffer (Previous stage)
		WritebackControlWB: in std_logic_vector(1 downto 0); --2 bits , Control unit WB
		WriteBackValue: out std_logic_vector(15 downto 0) -- stage output is just WriteBackValue and not buffered.
		);
end entity WriteBackStage;


Architecture WriteBackStage_Implementation of WriteBackStage is  

Begin 
 
	WriteBackValue <= MemoryStage(15 downto 0) when WritebackControlWB(1)='0' else MemoryStage(31 downto 16);
	
end Architecture;
