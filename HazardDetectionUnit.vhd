library ieee;
Use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity HazardDetectionUnit is 
	port (CLK : in std_logic;
		FetchBufferLower16: in std_logic_vector(15 downto 0);
		InstructionMemory: in std_logic_vector(15 downto 0);
		CU_WB: in std_logic_vector(1 downto 0);
		FlushFetchBufer:out std_logic;
		PCEnable: out std_logic
		);
end entity HazardDetectionUnit;


Architecture HazardDetectionUnit_Implementation of HazardDetectionUnit is  
Begin 
	PCEnable <= '0' when CU_WB="10" and InstructionMemory(5 downto 3)=FetchBufferLower16(8 downto 6)
					and  InstructionMemory(8 downto 6)=FetchBufferLower16(8 downto 6) and FetchBufferLower16(2 downto 0)/="100" 
					else '1';
					
					
	FlushFetchBufer <= '1' when CU_WB="10" and InstructionMemory(5 downto 3)=FetchBufferLower16(8 downto 6)
							and  InstructionMemory(8 downto 6)=FetchBufferLower16(8 downto 6) and FetchBufferLower16(2 downto 0)/="100" 
							else '0';
	
end Architecture;
