library ieee;
Use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity HazardDetectionUnit is 
	port (CLK : in std_logic;
		DecodeWBAddress: in std_logic_vector(2 downto 0); --The WB it is going to propagate
		InstructionMemory: in std_logic_vector(15 downto 0);
		Is_Load: in std_logic;
		FlushFetchBufer:out std_logic;
		PCEnable: out std_logic
		);
end entity HazardDetectionUnit;


Architecture HazardDetectionUnit_Implementation of HazardDetectionUnit is  
Begin 
  
  PCEnable <= '0' when Is_Load='1' --if there is going to be an LDD
          and (InstructionMemory(12 downto 10)=DecodeWBAddress or InstructionMemory(9 downto 7)=DecodeWBAddress) --and I am going to use the R that will change its value
        else '1';
  					
					
	FlushFetchBufer <= '1' when Is_Load='1' --if there is going to be an LDD
          and (InstructionMemory(12 downto 10)=DecodeWBAddress or InstructionMemory(9 downto 7)=DecodeWBAddress) --and I am going to use the R that will change its value
        else '0';
	
end Architecture;
