all:
	iverilog -g2012 -o gpu_top.vvp designs/constants.v designs/producer.v designs/consumer.v designs/system_memory.v designs/skid_buffer.v designs/gpu_top.v tb/tb.v

clean:
	rm -f *.vvp *.vcd

run: all
	vvp gpu_top.vvp

.PHONY: all clean run