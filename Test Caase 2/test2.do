vsim -gui work.processor
add wave  \
sim:/processor/CLK \
sim:/processor/INT \
sim:/processor/InPort \
sim:/processor/RST \
sim:/processor/OutPort \
sim:/processor/DecodeOutput \
sim:/processor/ExecuteOutput \
sim:/processor/FetchOutput \
sim:/processor/MemoryOutput
force -freeze sim:/processor/CLK 1 0, 0 {50 ps} -r 100
force -freeze sim:/processor/INT 0 0
force -freeze sim:/processor/InPort 0000000000000101 0
force -freeze sim:/processor/RST 1 0
add wave -position insertpoint  \
sim:/processor/Execute/ALU_flags_Rout
mem load -i {D:/Google Drive/Subjects/Computer Architecture/AssemblerVS/AssemblerVS/instructions.mem} /processor/Fetch/Instruction_MEM/ram
mem load -i {D:/Google Drive/Subjects/Computer Architecture/AssemblerVS/AssemblerVS/data.mem} /processor/Memory/Data_MEM/ram
add wave -position insertpoint  \
sim:/processor/Execute/ALUOP/OP \
sim:/processor/Execute/ALUOP/ALUOP
run
force -freeze sim:/processor/RST 0 0
run
run
run
run
run
run
run
run
run
run
run
run
run
run
run
run
run
force -freeze sim:/processor/InPort 0000000000000100 0
run
force -freeze sim:/processor/InPort 0000000000000111 0
run
run
run
run
run
run
run
run
run
run
run
run