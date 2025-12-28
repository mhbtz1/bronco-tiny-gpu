all:
	iverilog -g2012 -o gpu_top.vvp designs/constants.sv designs/producer.sv designs/consumer.sv designs/skid_buffer.sv designs/gpu_top.sv tb/tb.sv

clean:
	rm -f *.vvp *.vcd

run: all
	vvp gpu_top.vvp

.PHONY: all clean run