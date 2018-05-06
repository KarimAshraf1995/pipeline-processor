library ieee;
Use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ControlUnit is 
	port (CLK : in std_logic;
		ForceJMP: in std_logic;
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
		MemoryControlM: out std_logic_vector(3 downto 0);
		ExecuteControlEX: out std_logic_vector (11 downto 0)
		);
end entity ControlUnit;


Architecture ControlUnit_Implementation of ControlUnit is  
signal counter: std_logic_vector(1 downto 0);
signal is_counting: std_logic;
signal InnerRegister: std_logic_vector (1 downto 0);
Begin 

	--Best practice and important note: counter and InnerRegister could be read anywhere 
	--but better be changed inside process only.
	process(CLK) is
	begin
		if rising_edge(CLK) then
			-- counter keep counting
			if is_counting = '1' then 
				counter <= counter - 1;
			end if;
			
			-- a) 2 Bit Register
			-- i. 
			if counter = "0" and is_counting = '1' then 
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
				counter <= "11";
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
						'1' when counter > "01"  --If backward counter > 1, flush fetch buffer
							else '0';
	
	FlushBuffers <= '1' when ForceJMP='1' else '0';--If Force JMP: flush fetch & decode
					
		
	-- e) In Mux selector
	-- Always 0 except if Atype and IN function
	DecodeInMuxSelector <= '1' when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0101" else '0';
	
	-- f) PC MUX
	FetchPCMuxSelector<="10" when ForceJMP = '1' else -- If forced JMP: value 3
						"00" when FetchStage(15 downto 13)="110" and FetchStage(2 downto 0)="000"  else -- If J-type and JMP
						"00" when FetchStage(15 downto 13)="110" and FetchStage(2 downto 0)="100"  else -- If J-type and CALL
						"01" when counter/="00" --If counter != 0, value =  1
						else "10"; --Default value is 2 
	
	-- g) Imm Value Mux selector
	DecodeImmMuxSelector <= "00" when FetchStage(15 downto 13)="011" else --If S-type, value = 0
							"10" when FetchStage(15 downto 13)="101" else --If X-type, value = 2
							-- If call & upper 16 bits are not the same instruction bits: value = 1
							"01" when FetchStage(15 downto 13)="110" and FetchStage(2 downto 0)="100" and FetchStage(15 downto 0)/=FetchStage(31 downto 16) else
							-- If LDM&upper 16 bits are not the same instruction bits: value = 1
							"01" when FetchStage(15 downto 13)="100" and FetchStage(15 downto 0)/=FetchStage(31 downto 16)
							else "ZZ"; --Default dont care --but should have a value to avoid latch
	
	-- h) Upper MUX Selector
	-- If J-type & call & upper 16 bits are the same instruction bits: value = 1
	FetchUpperMuxSelector <= '1' when FetchStage(15 downto 13)="110" and FetchStage(2 downto 0)="100" and FetchStage(15 downto 0)=FetchStage(31 downto 16) -- If J-type and CALL;
							else '0'; --Default dont care --but should have a value to avoid latch
	
	
	
	-- TODO change bit order here
	-- TODO replace X with missing bit(s)
	-- i) EX CU bits
	ExecuteControlEX <= "100101000100" when InnerRegister="01" and counter="10" else -- If register == 1 and counter == 2
						"000000010001" when InnerRegister="01" and counter="01" else -- If register == 1 and counter == 1
						-- 2.If LDM&upper 16 bits are not the same instruction bits
						-- Missing 1 bit
						"01000000010X" when FetchStage(15 downto 13)="100" and FetchStage(15 downto 0)/=FetchStage(31 downto 16) else 
						-- 3.If NULL type
						"000011010000" when FetchStage(15 downto 13)="000" and FetchStage(2 downto 0)="001" else -- If SETC
						"000011110000" when FetchStage(15 downto 13)="000" and FetchStage(2 downto 0)="010" else -- If CLRC
						"100101000100" when FetchStage(15 downto 13)="000" and FetchStage(2 downto 0)="011" else -- If RET 
						"100101000100" when FetchStage(15 downto 13)="000" and FetchStage(2 downto 0)="100" else -- If RTI
						-- 4.If A-type
						"100101100110" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0010" else --If push
						"100101000100" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0011" else --If pop
						"000000000000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0100" else --If out
						"000000000010" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0101" else --If in
						"000010011000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0000" else --If rlc
						"000010111000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0001" else --If rrc
						"000110010000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="0110" else --If NOT
						"000101010000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="1000" else --If INC
						"000101110000" when FetchStage(15 downto 13)="010" and FetchStage(3 downto 0)="1001" else --If DEC
						-- 5. If R-type
						"000000000010" when FetchStage(15 downto 13)="001" and FetchStage(2 downto 0)="000" else --If Move
						"000001010000" when FetchStage(15 downto 13)="001" and FetchStage(2 downto 0)="001" else --If Add
						"000001110000" when FetchStage(15 downto 13)="001" and FetchStage(2 downto 0)="010" else --If SUB
						"000000110000" when FetchStage(15 downto 13)="001" and FetchStage(2 downto 0)="011" else --If AND
						"000000010000" when FetchStage(15 downto 13)="001" and FetchStage(2 downto 0)="100" else --If OR
						-- 6. If S-type 
						"001011100000" when FetchStage(15 downto 13)="011" and FetchStage(0)='0' else --If SHR 
						"001011000000" when FetchStage(15 downto 13)="011" and FetchStage(0)='1' else --If SHL 
						-- 7. If X-type
						"100000000010" when FetchStage(15 downto 13)="101" else
						-- 8. If J-type
						-- If call & upper 16 bits are not the same instruction bits
						"101101100110" when FetchStage(15 downto 13)="110" and FetchStage(2 downto 0)="100" and FetchStage(15 downto 0)/=FetchStage(31 downto 16) 
						--Default ZEROS
						else "000000000000"; 
						
						
						
end Architecture;
