library ieee;
Use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ForwardingUnit is 
	port (CLK : in std_logic;
		FetchR1R2: in std_logic_vector(5 downto 0);
		DecodeBufferlast3: in std_logic_vector(2 downto 0);
		DecodeWB: in std_logic_vector(1 downto 0);
		ExecuteWB: in std_logic_vector(1 downto 0);
		ExecuteMemAddress: in std_logic_vector(15 downto 0);
		ExecuteWBAddress: in std_logic_vector(2 downto 0);
		ExecuteMemAddressBuffered: in std_logic_vector(8 downto 0);
		MemoryValueRead: in std_logic_vector(15 downto 0);
		FR1,FR2: out std_logic_vector(15 downto 0);
		FS1,FS2: out std_logic
		);
end entity ForwardingUnit;


Architecture ForwardingUnit_Implementation of ForwardingUnit is  
Begin 

	FS1 <= 
	'1' when DecodeWB="11" and FetchR1R2(2 downto 0) = DecodeBufferlast3 else 
	'1' when ExecuteWB(1)='1' and FetchR1R2(2 downto 0) = ExecuteWBAddress else 
	'0';
	
	FR1 <= 
	ExecuteMemAddress when DecodeWB="11" and FetchR1R2(2 downto 0) = DecodeBufferlast3 else 
	"0000000"&ExecuteMemAddressBuffered when ExecuteWB="11" and FetchR1R2(2 downto 0) = ExecuteWBAddress else 
	MemoryValueRead when ExecuteWB="10" and FetchR1R2(2 downto 0) = ExecuteWBAddress else 
	(others => 'Z');

	
	FS2 <= 
	'1' when DecodeWB="11" and FetchR1R2(5 downto 3) = DecodeBufferlast3 else 
	'1' when ExecuteWB(1)='1' and FetchR1R2(5 downto 3) = ExecuteWBAddress else 
	'0';
	
	FR2 <= 
	ExecuteMemAddress when DecodeWB="11" and FetchR1R2(5 downto 3) = DecodeBufferlast3 else 
	"0000000"&ExecuteMemAddressBuffered when ExecuteWB="11" and FetchR1R2(5 downto 3) = ExecuteWBAddress else 
	MemoryValueRead when ExecuteWB="10" and FetchR1R2(5 downto 3) = ExecuteWBAddress else 
	(others => 'Z');	
	
end Architecture;
