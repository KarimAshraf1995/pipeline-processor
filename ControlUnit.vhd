library ieee;
Use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ControlUnit is 
	port (CLK : in std_logic;
	  RST: in std_logic;
		INT: in std_logic;	--Interrupt 
		ForceJMP: in std_logic; --Force Jump from Branch Decision unit
		FetchStage: in std_logic_vector(31 downto 0); --Output of FetchStage buffer
		FlushBuffers: out std_logic;	-- FLush Decode,Execute and Memory Buffers
		FetchUpperMuxSelector: out std_logic_vector (1 downto 0);
		FetchBufferFlush: out std_logic;
		FetchBufferStall: out std_logic;
		DecodeInMuxSelector: out std_logic;
		DecodeImmMuxSelector: out std_logic_vector (1 downto 0);
		FetchPCMuxSelector: out std_logic_vector(1 downto 0);
		
		--First stage output, should be buffered at integration for each next stage
		JMPIndicator: out std_logic_vector(1 downto 0);
		WritebackControlWB: out std_logic_vector(1 downto 0);
		MemoryControlM: out std_logic_vector(2 downto 0);
		ExecuteControlEX: out std_logic_vector (13 downto 0);
		WriteBackAddrMuxSelector: out std_logic
		);
end entity ControlUnit;


Architecture ControlUnit_Implementation of ControlUnit is  

signal iJMPIndicator : std_logic_vector(1 downto 0) := "00"; --for intial value

signal counter: std_logic_vector(2 downto 0) := "000";
signal is_counting: std_logic := '0';
signal InnerRegister: std_logic_vector (1 downto 0) := "00";

--Interrupt Unit.
signal gotIReg,doIReg : std_logic := '0';
signal IntRegister : std_logic_vector(15 downto 0) := "0000000000000000";
signal RSTdoIreg : std_logic := '0';
--End Interrupt Unit.

Begin 
  
  JMPIndicator <= iJMPIndicator;

	--Interrupt Unit
	process(INT, doIReg) is 
	begin
		--notice that these two registers don't act according to the clk; their clk is the interrupt pulse
		if rising_edge(INT) or rising_edge(doIReg) then  --if interrupt pulse
			gotIReg <= INT;--set gotIReg to 1
			IntRegister <= FetchStage(15 downto 0);-- set 16 bit register to lower 16 bits of the fetch buffer
		end if;
	end process;
	
	process(CLK) is 
	begin
		-- these set will actually change the value in the next clock cycle so its clk is the actual clk
		if rising_edge(CLK) then
			--if gotIReg == 1 && 16 bit register != 16 bit of lower fetch buffer && CU 2 bit register == 0 && counter == 0
			if gotIReg = '1' and InnerRegister="00" and counter="000" then
				doIReg <= '1';
			end if;
			if doIReg = '1' then
			  doIReg <= '0';
			end if;
		end if;
	end process;
	--End Interrupt Unit
  
	
	
	--Best practice and important note: counter and InnerRegister could be read anywhere 
	--but better be changed inside process only.
	process(CLK) is
	begin
		if rising_edge(CLK) then
			-- counter keep counting
			if is_counting = '1' then 
				counter <= counter - 1;
			end if;
			
			-- if regsiter == 3 & if counter == 1
			if InnerRegister = "10" and counter="001" then
				InnerRegister <= "00";				
				is_counting <= '0';
			end if;
			
			--if doInterrupt && counter == 0:
			if doIReg='1' and counter="000" then
				counter<="011";
				is_counting <= '1'; --set counter = 4 
				InnerRegister <= "10"; --set register = 3
			
			
			-- a) 2 Bit Register
			-- ii. if null type and rti.
			elsif FetchStage(15 downto 13)="000" and FetchStage(2 downto 0)="100" then
				InnerRegister <= "01";
			end if;
			
			-- b) backward counter
			-- if null type and (RET or RTI) start backward counter from 3
			if FetchStage(15 downto 13)="000" and (FetchStage(2 downto 0)="011" or FetchStage(2 downto 0)="100") then
				counter <= "010";
				is_counting <= '1';
			end if;
			
			  
			
		end if;
	end process;
	
	-- c)JMPIndicator
	-- If J-type 110: put lower two bits into the Jmp indicator buffer
	iJMPIndicator <= FetchStage(1 downto 0) when FetchStage(15 downto 13)="110" else "00";
		
	--d) Buffers control
	--If call & upper 16 bits are the same instruction bits: stall lower 16
	FetchBufferStall <= '1' when FetchStage(15 downto 13)="110" and FetchStage(2 downto 0)="100" and FetchStage(15 downto 0)=FetchStage(31 downto 16) else
						'1' when FetchStage(15 downto 13)="100" and FetchStage(15 downto 0)=FetchStage(31 downto 16)--If LDM&upper 16 bits are the same instruction bits: stall lower 16 bits
							else '0';
	
	FetchBufferFlush <= '1' when ForceJMP='1' else --If Force JMP: flush fetch & decode
						'1' when FetchStage(15 downto 13)="110" and FetchStage(2 downto 0)="000" else --If JMP: flush fetch buffer
						'1' when (counter > "000") or FetchStage(15 downto 0) = "0000000000000011" or FetchStage(15 downto 0) = "0000000000000100"   --If backward counter > 1 or rti/ret first time, flush fetch buffer
							else '0';
	
	FlushBuffers <= '1' when ForceJMP='1' else '0';--If Force JMP: flush fetch & decode
					
		
	-- e) In Mux selector
	-- Always 0 except if Atype and IN function
	DecodeInMuxSelector <= '1' when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0101" else '0';
	
	-- f) PC MUX
	FetchPCMuxSelector<= "01" when ((InnerRegister="10" and counter="001") or RST='1') else
						"11" when ForceJMP = '1' else -- If forced JMP: value 3
						"00" when FetchStage(15 downto 13)="110" and FetchStage(2 downto 0)="000"  else -- If J-type and JMP
						"00" when FetchStage(15 downto 13)="110" and FetchStage(2 downto 0)="100"  else -- If J-type and CALL
						"01" when counter/="000" --If counter != 0, value =  1
						else "10"; --Default value is 2 
	
	-- g) Imm Value Mux selector
	DecodeImmMuxSelector <= "11" when InnerRegister="10" and counter="011" else
							"01" when InnerRegister="10" and counter="010" else
							"00" when InnerRegister="10" and counter="001" else
							"00" when FetchStage(15 downto 13)="011" else --If S-type, value = 0
							"10" when FetchStage(15 downto 13)="101" else --If X-type, value = 2
							-- If call & upper 16 bits are not the same instruction bits: value = 1
							"01" when FetchStage(15 downto 13)="110" and FetchStage(2 downto 0)="100" and FetchStage(15 downto 0)/=FetchStage(31 downto 16) else
							-- If LDM&upper 16 bits are not the same instruction bits: value = 1
							"01" when FetchStage(15 downto 13)="100" and FetchStage(15 downto 0)/=FetchStage(31 downto 16)
							else "00"; --Default dont care --but should have a value to avoid latch
	
	-- h) Upper MUX Selector
	-- If J-type & call & upper 16 bits are the same instruction bits: value = 1
	FetchUpperMuxSelector <= "10" when InnerRegister="10" and counter="011" else "01" when FetchStage(15 downto 13)="110" and FetchStage(2 downto 0)="100" and FetchStage(15 downto 0)=FetchStage(31 downto 16) -- If J-type and CALL;
							else "00"; --Default dont care --but should have a value to avoid latch
	
	
	
	-- i) EX CU bits
	ExecuteControlEX <= 
	"00010000000001" when InnerRegister="10" and counter="011" else -- If register == 3 and counter == 4
	"00011001011110" when InnerRegister="10" and counter="010" else -- If register == 3 and counter == 3
	"01011001011110" when InnerRegister="10" and counter="001" else -- If register == 3 and counter == 2
	"00001001010010" when InnerRegister="01" and counter="010" else -- If register == 1 and counter == 2
	"00100010000000" when InnerRegister="01" and counter="001" else -- If register == 1 and counter == 1
	-- 2.If LDM&upper 16 bits are not the same instruction bits
	"00010000000001" when FetchStage(15 downto 13)="100" and FetchStage(15 downto 0)/=FetchStage(31 downto 16) else 
	-- 3.If NULL type
	"00000011000000" when FetchStage(15 downto 13)="000" and FetchStage(2 downto 0)="001" else -- If SETC
	"00000010111000" when FetchStage(15 downto 13)="000" and FetchStage(2 downto 0)="010" else -- If CLRC
	"00001001010010" when FetchStage(15 downto 13)="000" and FetchStage(2 downto 0)="011" else -- If RET 
	"00001001010010" when FetchStage(15 downto 13)="000" and FetchStage(2 downto 0)="100" else -- If RTI
	-- 4.If A-type
	"00011001011010" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0010" else --If push
	"00001001010010" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0011" else --If pop
	"00000000000000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0100" else --If out
	"00010000000000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0101" else --If in
	"00000110100000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0000" else --If rlc
	"00000110101000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0001" else --If rrc
	"00000011100000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0110" else --If NOT
	"00000011010000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="1000" else --If INC
	"00000011011000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="1001" else --If DEC
	"00000011110000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0111" else --If NEG
	-- 5. If R-type
	"00010000000000" when FetchStage(15 downto 13)="001" and FetchStage(2 downto 0)="000" else --If Move
	"00000010010000" when FetchStage(15 downto 13)="001" and FetchStage(2 downto 0)="001" else --If Add
	"00000010011000" when FetchStage(15 downto 13)="001" and FetchStage(2 downto 0)="010" else --If SUB
	"00000010001000" when FetchStage(15 downto 13)="001" and FetchStage(2 downto 0)="011" else --If AND
	"00000010000000" when FetchStage(15 downto 13)="001" and FetchStage(2 downto 0)="100" else --If OR
	-- 6. If S-type 
	"00000000111100" when FetchStage(15 downto 13)="011" and FetchStage(0)='0' else --If SHR 
	"00000000110100" when FetchStage(15 downto 13)="011" and FetchStage(0)='1' else --If SHL 
	-- 7. If X-type
	"00010000000001" when FetchStage(15 downto 13)="101" and FetchStage(0)='0' else --If LDD
	"10010000000001" when FetchStage(15 downto 13)="101" and FetchStage(0)='1' else --If STD
	-- 8. If J-type
	-- If call & upper 16 bits are not the same instruction bits
	"00011001011110" when FetchStage(15 downto 13)="110" and FetchStage(2 downto 0)="100" and FetchStage(15 downto 0)/=FetchStage(31 downto 16) 
	--Default ZEROS
	else "00000000000000"; 
						
	-- j) M CU bits (A B C)
	MemoryControlM <=
	"010" when InnerRegister="10" and counter="011" else -- If register == 3 and counter == 4
	"001" when InnerRegister="10" and counter="010" else -- If register == 3 and counter == 3
	"001" when InnerRegister="10" and counter="001" else -- If register == 3 and counter == 2
	"010" when InnerRegister="01" and counter="010" else -- If register == 1 and counter == 2
	"000" when InnerRegister="01" and counter="001" else -- If register == 1 and counter == 1
	-- 2. If LDM&upper 16 bits are not the same instruction bits
	"000" when FetchStage(15 downto 13)="100" and FetchStage(15 downto 0)/=FetchStage(31 downto 16) else 
	-- 3. If NULL type
	"010" when FetchStage(15 downto 13)="000" and FetchStage(2 downto 0)="011" else -- If RET 
	"010" when FetchStage(15 downto 13)="000" and FetchStage(2 downto 0)="100" else -- If RTI						
	-- 4. If J-type
	-- If call & upper 16 bits are not the same instruction bits
	"001" when FetchStage(15 downto 13)="110" and FetchStage(2 downto 0)="100" and FetchStage(15 downto 0)/=FetchStage(31 downto 16) else 
	-- 5. If A-type
	"001" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0010" else --If push
	"010" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0011" else --If pop
	"100" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0100" else --If out
	"000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0101" else --If in
	"000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0000" else --If rlc
	"000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0001" else --If rrc
	"000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0110" else --If NOT
	"000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="1000" else --If INC
	"000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="1001" else --If DEC	
  "000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0111" else --If NEG
	-- 6. If R-type OR S-type
	"000" when FetchStage(15 downto 13)="001" or FetchStage(15 downto 13)="011" else 
	-- 7. If X-type
	"010" when FetchStage(15 downto 13)="101" and FetchStage(0)='0' else -- If LDD
	"001" when FetchStage(15 downto 13)="101" and FetchStage(0)='1'  -- If STD
	--Default ZEROS
	else "000";


	-- k) WB CU bits (A B)
	WritebackControlWB <=
	-- 0. 
	"00" when InnerRegister="10" else --if register == 3 -> WB always 00
	-- 1. If A-type
	"00" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0010" else --If push
	"01" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0011" else --If pop
	"00" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0100" else --If out
	"11" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0101" else --If in
	"11" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0000" else --If rlc
	"11" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0001" else --If rrc
	"11" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0110" else --If NOT
	"11" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="1000" else --If INC
	"11" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="1001" else --If DEC	
	"11" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0111" else --If NEG
	-- 2. If R-type OR S-type
	"11" when FetchStage(15 downto 13)="001" or FetchStage(15 downto 13)="011" else 
	-- 3. If LDM&upper 16 bits are not the same instruction bits
	"11" when FetchStage(15 downto 13)="100" and FetchStage(15 downto 0)/=FetchStage(31 downto 16) else 
	-- 4. If X type
	"01" when FetchStage(15 downto 13)="101" and FetchStage(0)='0' else -- If LDD
	"00" when FetchStage(15 downto 13)="101" and FetchStage(0)='1'  -- If STD
	--Default ZEROS
	else "00";
	  
	 --Write Back Address MUX Selector is 1 only if X-type & LDD because we can't duplicate R1 into R2
	WriteBackAddrMuxSelector<=
	'1' when (FetchStage(15 downto 13)="101" and FetchStage(0)='0') or (FetchStage(15 downto 13)="101" and FetchStage(3 downto 0) = "0011")
	else '0';
	
end Architecture;
