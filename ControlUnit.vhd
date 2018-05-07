library ieee;
Use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ControlUnit is 
	port (CLK : in std_logic;
		INT: in std_logic;	--Interrupt 
		ForceJMP: in std_logic; --Force Jump from Branch Decision unit
		FetchStage: in std_logic_vector(31 downto 0); --Output of FetchStage buffer
		FlushBuffers: out std_logic;	-- FLush Decode,Execute and Memory Buffers
		FetchUpperMuxSelector: out std_logic;
		FetchBufferFlush: out std_logic;
		FetchBufferStall: out std_logic;
		DecodeInMuxSelector: out std_logic;
		DecodeImmMuxSelector: out std_logic_vector (1 downto 0);
		FetchPCMuxSelector: out std_logic_vector(1 downto 0);
		
		--First stage output, should be buffered at integration for each next stage
		JMPIndicator: out std_logic_vector(1 downto 0);
		WritebackControlWB: out std_logic_vector(1 downto 0);
		MemoryControlM: out std_logic_vector(2 downto 0);
		ExecuteControlEX: out std_logic_vector (12 downto 0)
		);
end entity ControlUnit;


Architecture ControlUnit_Implementation of ControlUnit is  
signal counter: std_logic_vector(2 downto 0);
signal is_counting: std_logic;
signal InnerRegister: std_logic_vector (1 downto 0);

--Interrupt Unit.
signal gotIReg,doIReg : std_logic;
signal IntRegister : std_logic_vector(15 downto 0);
signal RSTdoIreg : std_logic;
--End Interrupt Unit.

Begin 

	--Interrupt Unit
	process(INT) is 
	begin
		--notice that these two registers don't act according to the clk; their clk is the interrupt pulse
		if rising_edge(INT) then  --if interrupt pulse
			gotIReg <= '1';--set gotIReg to 1
			IntRegister <= FetchStage(15 downto 0);-- set 16 bit register to lower 16 bits of the fetch buffer
		end if;
	end process;
	
	process(CLK) is 
	begin
		-- these set will actually change the value in the next clock cycle so its clk is the actual clk
		if rising_edge(CLK) then
			--if gotIReg == 1 && 16 bit register != 16 bit of lower fetch buffer && CU 2 bit register == 0 && counter == 0
			if gotIReg = '1' and IntRegister/=FetchStage(15 downto 0) and InnerRegister="00" and counter="000" then
				doIReg <= '1';
			end if;
			if RSTdoIreg = '1' then -- --if doIReg == 1: --reset doIreg in the next clk cycle
				doIReg <= '0';
				RSTdoIreg <= '0';
			end if;
		end if;
	end process;
	
	process (doIReg) is 
	begin 
		if rising_edge(doIReg) then --if doIReg == 1:
		--reset (async) both gotIreg and 16 bit register
			gotIReg<='0';
			IntRegister<=(others=>'0');
			RSTdoIreg <= '1';  --reset doIreg in the next clk cycle
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
			if InnerRegister = "11" and counter="001" then
				InnerRegister <= "00";
			end if;
			
			--if doInterrupt && counter == 0:
			if doIReg='1' and counter="000" then
				counter<="100";
				is_counting <= '1'; --set counter = 4 
				InnerRegister <= "11"; --set register = 3
			
			-- a) 2 Bit Register
			-- i. 
			elsif counter = "000" and is_counting = '1' then 
				InnerRegister <= "00";
				is_counting <= '0';
			
			
			-- a) 2 Bit Register
			-- ii. if null type and rti.
			elsif FetchStage(15 downto 13)="000" and FetchStage(2 downto 0)="100" then
				InnerRegister <= "01";
			else 
				InnerRegister <= "00";
			end if;
			
			-- b) backward counter
			-- if null type and (RET or RTI) start backward counter from 3
			if FetchStage(15 downto 13)="000" and (FetchStage(2 downto 0)="011" or FetchStage(2 downto 0)="100") then
				counter <= "011";
				is_counting <= '1';
			end if;
			
			-- c)JMPIndicator
			-- If J-type 110: put lower two bits into the Jmp indicator buffer  
			-- ON RISING EDGE OF CLOCK.
			if FetchStage(15 downto 13)="110" then 
				JMPIndicator <= FetchStage(1 downto 0);
			else
				JMPIndicator <= "00";
			end if;
		end if;
	end process;
 
		
	--d) Buffers control
	--If call & upper 16 bits are the same instruction bits: stall lower 16
	FetchBufferStall <= '1' when FetchStage(15 downto 13)="110" and FetchStage(2 downto 0)="100" and FetchStage(15 downto 0)=FetchStage(31 downto 16) else
						'1' when FetchStage(15 downto 13)="100" and FetchStage(15 downto 0)=FetchStage(31 downto 16)--If LDM&upper 16 bits are the same instruction bits: stall lower 16 bits
							else '0';
	
	FetchBufferFlush <= '1' when ForceJMP='1' else --If Force JMP: flush fetch & decode
						'1' when FetchStage(15 downto 13)="110" and FetchStage(2 downto 0)="000" else --If JMP: flush fetch buffer
						'1' when counter > "001"  --If backward counter > 1, flush fetch buffer
							else '0';
	
	FlushBuffers <= '1' when ForceJMP='1' else '0';--If Force JMP: flush fetch & decode
					
		
	-- e) In Mux selector
	-- Always 0 except if Atype and IN function
	DecodeInMuxSelector <= '1' when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0101" else '0';
	
	-- f) PC MUX
	FetchPCMuxSelector<="01" when InnerRegister="11" and counter="010" else
						"10" when ForceJMP = '1' else -- If forced JMP: value 3
						"00" when FetchStage(15 downto 13)="110" and FetchStage(2 downto 0)="000"  else -- If J-type and JMP
						"00" when FetchStage(15 downto 13)="110" and FetchStage(2 downto 0)="100"  else -- If J-type and CALL
						"01" when counter/="000" --If counter != 0, value =  1
						else "10"; --Default value is 2 
	
	-- g) Imm Value Mux selector
	DecodeImmMuxSelector <= "11" when InnerRegister="11" and counter="100" else
							"01" when InnerRegister="11" and counter="010" else
							"00" when InnerRegister="11" and counter="001" else
							"00" when FetchStage(15 downto 13)="011" else --If S-type, value = 0
							"10" when FetchStage(15 downto 13)="101" else --If X-type, value = 2
							-- If call & upper 16 bits are not the same instruction bits: value = 1
							"01" when FetchStage(15 downto 13)="110" and FetchStage(2 downto 0)="100" and FetchStage(15 downto 0)/=FetchStage(31 downto 16) else
							-- If LDM&upper 16 bits are not the same instruction bits: value = 1
							"01" when FetchStage(15 downto 13)="100" and FetchStage(15 downto 0)/=FetchStage(31 downto 16)
							else "ZZ"; --Default dont care --but should have a value to avoid latch
	
	-- h) Upper MUX Selector
	-- If J-type & call & upper 16 bits are the same instruction bits: value = 1
	FetchUpperMuxSelector <= '1' when InnerRegister="11" and counter="100" else '1' when FetchStage(15 downto 13)="110" and FetchStage(2 downto 0)="100" and FetchStage(15 downto 0)=FetchStage(31 downto 16) -- If J-type and CALL;
							else '0'; --Default dont care --but should have a value to avoid latch
	
	
	
	-- TODO change bit order here
	-- TODO replace X with missing bit(s)
	-- i) EX CU bits
	ExecuteControlEX <= 
	"0100000000100" when InnerRegister="11" and counter="100" else -- If register == 3 and counter == 4
	"1001011001000" when InnerRegister="11" and counter="011" else -- If register == 3 and counter == 3
	"1011011001000" when InnerRegister="11" and counter="010" else -- If register == 3 and counter == 2
	"0000000000000" when InnerRegister="11" and counter="001" else -- If register == 3 and counter == 1
	"1001010001000" when InnerRegister="01" and counter="010" else -- If register == 1 and counter == 2
	"0000000100010" when InnerRegister="01" and counter="001" else -- If register == 1 and counter == 1
	-- 2.If LDM&upper 16 bits are not the same instruction bits
	"0100000000100" when FetchStage(15 downto 13)="100" and FetchStage(15 downto 0)/=FetchStage(31 downto 16) else 
	-- 3.If NULL type
	"0000110100000" when FetchStage(15 downto 13)="000" and FetchStage(2 downto 0)="001" else -- If SETC
	"0000111100000" when FetchStage(15 downto 13)="000" and FetchStage(2 downto 0)="010" else -- If CLRC
	"1001010001000" when FetchStage(15 downto 13)="000" and FetchStage(2 downto 0)="011" else -- If RET 
	"1001010001000" when FetchStage(15 downto 13)="000" and FetchStage(2 downto 0)="100" else -- If RTI
	-- 4.If A-type
	"1001011001100" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0010" else --If push
	"1001010001000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0011" else --If pop
	"0000000000000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0100" else --If out
	"0000000000100" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0101" else --If in
	"0000100110000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0000" else --If rlc
	"0000101110000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0001" else --If rrc
	"0001100100000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0110" else --If NOT
	"0001010100000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="1000" else --If INC
	"0001011100000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="1001" else --If DEC
	-- 5. If R-type
	"0000000000100" when FetchStage(15 downto 13)="001" and FetchStage(2 downto 0)="000" else --If Move
	"0000010100000" when FetchStage(15 downto 13)="001" and FetchStage(2 downto 0)="001" else --If Add
	"0000011100000" when FetchStage(15 downto 13)="001" and FetchStage(2 downto 0)="010" else --If SUB
	"0000001100000" when FetchStage(15 downto 13)="001" and FetchStage(2 downto 0)="011" else --If AND
	"0000000100000" when FetchStage(15 downto 13)="001" and FetchStage(2 downto 0)="100" else --If OR
	-- 6. If S-type 
	"0010111000000" when FetchStage(15 downto 13)="011" and FetchStage(0)='0' else --If SHR 
	"0010110000000" when FetchStage(15 downto 13)="011" and FetchStage(0)='1' else --If SHL 
	-- 7. If X-type
	"1000000000100" when FetchStage(15 downto 13)="101" else
	-- 8. If J-type
	-- If call & upper 16 bits are not the same instruction bits
	"1011011001100" when FetchStage(15 downto 13)="110" and FetchStage(2 downto 0)="100" and FetchStage(15 downto 0)/=FetchStage(31 downto 16) 
	--Default ZEROS
	else "0000000000000"; 
						
	-- TODO change bit order here
	-- j) M CU bits (A B C)
	MemoryControlM <=
	"010" when InnerRegister="11" and counter="100" else -- If register == 3 and counter == 4
	"100" when InnerRegister="11" and counter="011" else -- If register == 3 and counter == 3
	"100" when InnerRegister="11" and counter="010" else -- If register == 3 and counter == 2
	"000" when InnerRegister="11" and counter="001" else -- If register == 3 and counter == 1
	"010" when InnerRegister="01" and counter="010" else -- If register == 1 and counter == 2
	"000" when InnerRegister="01" and counter="001" else -- If register == 1 and counter == 1
	-- 2. If LDM&upper 16 bits are not the same instruction bits
	"000" when FetchStage(15 downto 13)="100" and FetchStage(15 downto 0)/=FetchStage(31 downto 16) else 
	-- 3. If NULL type
	"010" when FetchStage(15 downto 13)="000" and FetchStage(2 downto 0)="011" else -- If RET 
	"010" when FetchStage(15 downto 13)="000" and FetchStage(2 downto 0)="100" else -- If RTI						
	-- 4. If J-type
	-- If call & upper 16 bits are not the same instruction bits
	"100" when FetchStage(15 downto 13)="110" and FetchStage(2 downto 0)="100" and FetchStage(15 downto 0)=FetchStage(31 downto 16) else 
	-- 5. If A-type
	"100" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0010" else --If push
	"010" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0011" else --If pop
	"001" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0100" else --If out
	"000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0101" else --If in
	"000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0000" else --If rlc
	"000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0001" else --If rrc
	"000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0110" else --If NOT
	"000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="1000" else --If INC
	"000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="1001" else --If DEC	
	-- 6. If R-type OR S-type
	"000" when FetchStage(15 downto 13)="001" or FetchStage(15 downto 13)="011" else 
	-- 7. If X-type
	"010" when FetchStage(15 downto 13)="101" and FetchStage(0)='0' else -- If LDD
	"100" when FetchStage(15 downto 13)="101" and FetchStage(0)='1'  -- If STD
	--Default ZEROS
	else "000";


	-- TODO change bit order here
	-- k) WB CU bits (A B)
	WritebackControlWB <=
	-- 0. 
	"00" when InnerRegister="11" else --if register == 3 -> WB always 00
	-- 1. If A-type
	"00" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0010" else --If push
	"10" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0011" else --If pop
	"00" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0100" else --If out
	"11" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0101" else --If in
	"11" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0000" else --If rlc
	"11" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0001" else --If rrc
	"11" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0110" else --If NOT
	"11" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="1000" else --If INC
	"11" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="1001" else --If DEC	
	-- 2. If R-type OR S-type
	"10" when FetchStage(15 downto 13)="001" or FetchStage(15 downto 13)="011" else 
	-- 3. If LDM&upper 16 bits are not the same instruction bits
	"11" when FetchStage(15 downto 13)="100" and FetchStage(15 downto 0)/=FetchStage(31 downto 16) else 
	-- 4. If X type
	"10" when FetchStage(15 downto 13)="101" and FetchStage(0)='0' else -- If LDD
	"00" when FetchStage(15 downto 13)="101" and FetchStage(0)='1'  -- If STD
	--Default ZEROS
	else "00";
	
end Architecture;
