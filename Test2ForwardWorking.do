mem load -filltype value -filldata 0 -fillradix symbolic /processor/Decode/RegisterFile/registers(0)
mem load -filltype value -filldata 1 -fillradix symbolic /processor/Decode/RegisterFile/registers(1)
mem load -filltype value -filldata 10 -fillradix symbolic /processor/Decode/RegisterFile/registers(2)
mem load -filltype value -filldata 11 -fillradix symbolic /processor/Decode/RegisterFile/registers(3)
mem load -filltype value -filldata 100 -fillradix symbolic /processor/Decode/RegisterFile/registers(4)
mem load -filltype value -filldata 101 -fillradix symbolic /processor/Decode/RegisterFile/registers(5)
mem load -filltype value -filldata 111 -fillradix symbolic /processor/Decode/RegisterFile/registers(6)
mem load -filltype value -filldata 1000 -fillradix symbolic /processor/Decode/RegisterFile/registers(7)
add wave -position insertpoint  \
sim:/processor/CLK \
sim:/processor/INT \
sim:/processor/RST
force -freeze sim:/processor/CLK U 0
force -freeze sim:/processor/INT 0 0
force -freeze sim:/processor/RST 0 0
add wave -position insertpoint  \
sim:/processor/DecodeOutput \
sim:/processor/ExecuteOutput \
sim:/processor/FetchOutput
add wave -position insertpoint  \
sim:/processor/ExecuteControlEX_CU_D \
sim:/processor/ExecuteControlEX_D_Ex
add wave -position insertpoint  \
sim:/processor/MemoryControlM_CU_D
add wave -position insertpoint  \
sim:/processor/WritebackControlWB_CU_D
add wave -position insertpoint  \
sim:/processor/Fetch/PCRegOut
force -freeze sim:/processor/CLK 1 0, 0 {50 ps} -r 100
mem load -filltype value -filldata 1010010000000110 -fillradix symbolic /processor/Fetch/Instruction_MEM/ram(0)
mem load -filltype value -filldata 1010100000001000 -fillradix symbolic /processor/Fetch/Instruction_MEM/ram(1)
mem load -filltype value -filldata 0010100010000001 -fillradix symbolic /processor/Fetch/Instruction_MEM/ram(2)
mem load -filltype value -filldata 1010010000001001 -fillradix symbolic /processor/Fetch/Instruction_MEM/ram(3)
mem load -filltype value -filldata 0100100100000010 -fillradix symbolic /processor/Fetch/Instruction_MEM/ram(4)
mem load -filltype value -filldata 0000000000000101 -fillradix symbolic /processor/Memory/Data_MEM/ram(0)
mem load -filltype value -filldata 0000000001100100 -fillradix symbolic /processor/Memory/Data_MEM/ram(1)
mem load -filltype value -filldata 0000000000001010 -fillradix symbolic /processor/Memory/Data_MEM/ram(2)
mem load -filltype value -filldata 0000000000010100 -fillradix symbolic /processor/Memory/Data_MEM/ram(3)
mem load -filltype value -filldata 0000000000011110 -fillradix symbolic /processor/Memory/Data_MEM/ram(4)
mem load -filltype value -filldata 0000000000101000 -fillradix symbolic /processor/Memory/Data_MEM/ram(5)
mem load -filltype value -filldata 0000000000110010 -fillradix symbolic /processor/Memory/Data_MEM/ram(6)
mem load -filltype value -filldata 0000000000111100 -fillradix symbolic /processor/Memory/Data_MEM/ram(7)
mem load -filltype value -filldata 0000000001000110 -fillradix symbolic /processor/Memory/Data_MEM/ram(8)
mem load -filltype value -filldata 0100010010000010 -fillradix symbolic /processor/Fetch/Instruction_MEM/ram(5)
mem load -filltype value -filldata 1010010000000000 -fillradix symbolic /processor/Fetch/Instruction_MEM/ram(6)
mem load -filltype value -filldata 1010100000000010 -fillradix symbolic /processor/Fetch/Instruction_MEM/ram(7)
mem load -filltype value -filldata 0010100010000001 -fillradix symbolic /processor/Fetch/Instruction_MEM/ram(8)
mem load -filltype value -filldata 0100010010000011 -fillradix symbolic /processor/Fetch/Instruction_MEM/ram(9)
mem load -filltype value -filldata 0100100100000011 -fillradix symbolic /processor/Fetch/Instruction_MEM/ram(10)
mem load -filltype value -filldata 1010010000000110 -fillradix symbolic /processor/Fetch/Instruction_MEM/ram(11)
mem load -filltype value -filldata 0000000000000001 -fillradix symbolic /processor/Fetch/Instruction_MEM/ram(11)
mem load -filltype value -filldata 1000010010000000 -fillradix symbolic /processor/Fetch/Instruction_MEM/ram(12)
mem load -filltype value -filldata 0000000000000101 -fillradix symbolic /processor/Fetch/Instruction_MEM/ram(13)
mem load -filltype value -filldata 1000100100000000 -fillradix symbolic /processor/Fetch/Instruction_MEM/ram(14)
mem load -filltype value -filldata 0000000000000101 -fillradix symbolic /processor/Fetch/Instruction_MEM/ram(15)
mem load -filltype value -filldata 0010010100000010 -fillradix symbolic /processor/Fetch/Instruction_MEM/ram(16)