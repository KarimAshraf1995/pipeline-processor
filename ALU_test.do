vsim -gui work.alu(alu_implementation)
add wave -position insertpoint  \
sim:/alu/OP \
sim:/alu/A \
sim:/alu/B \
sim:/alu/F \
sim:/alu/Cin \
sim:/alu/Zout \
sim:/alu/Vout \
sim:/alu/Nout \
sim:/alu/Cout \
sim:/alu/ALUOP
force -freeze sim:/alu/OP 4'b1010 0
force -freeze sim:/alu/A FF0F 0
force -freeze sim:/alu/B 000A 0
force -freeze sim:/alu/Cin 1 0
run
force -freeze sim:/alu/OP 4'b0010 0
run
force -freeze sim:/alu/Cin 0 0
run
force -freeze sim:/alu/OP 4'b0011 0
run
force -freeze sim:/alu/Cin 1 0
run
force -freeze sim:/alu/OP 4'b1011 0
run
force -freeze sim:/alu/OP 4'b0001 0
run
force -freeze sim:/alu/B 000A 0
force -freeze sim:/alu/A 0F0F 0
force -freeze sim:/alu/OP 0 0
run
force -freeze sim:/alu/OP 4'b0111 0
run
force -freeze sim:/alu/OP 4'b0101 0
force -freeze sim:/alu/Cin 0 0
run
force -freeze sim:/alu/Cin 1 0
run
force -freeze sim:/alu/OP 4'b0110 0
run
force -freeze sim:/alu/OP 4'b0100 0
force -freeze sim:/alu/A F0F0 0
force -freeze sim:/alu/Cin 0 0
run
force -freeze sim:/alu/OP 4'b1001 0
run
force -freeze sim:/alu/OP 4'b1000 0
run