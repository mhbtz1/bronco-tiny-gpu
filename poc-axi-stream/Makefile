# ========================================
# Makefile for AXI-Stream UVM Testbench
# ========================================

# Simulator selection
# Options: questa, vcs, xcelium, iverilog
SIM ?= questa

# UVM library path (for commercial simulators)
UVM_HOME ?= /usr/local/share/uvm-1.2

# Source files
RTL_SRCS = smol-producer.v smol-consumer.v
TB_SRCS = smol_axis_if.sv smol_axis_pkg.sv smol_tb_top.sv

# Output
TOP = smol_tb_top
OUT = sim.out

# ========================================
# Questa/ModelSim
# ========================================
ifeq ($(SIM),questa)
VLOG = vlog
VSIM = vsim

compile:
	$(VLOG) -sv +acc \
		+incdir+$(UVM_HOME)/src \
		$(UVM_HOME)/src/uvm_pkg.sv \
		$(RTL_SRCS) $(TB_SRCS)

run: compile
	$(VSIM) -c $(TOP) \
		+UVM_TESTNAME=smol_test \
		+UVM_VERBOSITY=UVM_MEDIUM \
		-do "run -all; quit -f"

gui: compile
	$(VSIM) $(TOP) \
		+UVM_TESTNAME=smol_test \
		+UVM_VERBOSITY=UVM_MEDIUM \
		-do "add wave -r /*; run -all"

# ========================================
# Synopsys VCS
# ========================================
else ifeq ($(SIM),vcs)
VCS = vcs

compile:
	$(VCS) -sverilog +acc+1 \
		+incdir+$(UVM_HOME)/src \
		$(UVM_HOME)/src/uvm_pkg.sv \
		$(RTL_SRCS) $(TB_SRCS) \
		-o $(OUT)

run: compile
	./$(OUT) +UVM_TESTNAME=smol_test +UVM_VERBOSITY=UVM_MEDIUM

# ========================================
# Cadence Xcelium
# ========================================
else ifeq ($(SIM),xcelium)
XRUN = xrun

run:
	$(XRUN) -sv -uvm \
		+incdir+$(UVM_HOME)/src \
		+UVM_TESTNAME=smol_test \
		+UVM_VERBOSITY=UVM_MEDIUM \
		$(RTL_SRCS) $(TB_SRCS)

# ========================================
# Icarus Verilog (Simple test, no UVM)
# ========================================
else ifeq ($(SIM),iverilog)
IVERILOG = iverilog
VVP = vvp

compile:
	@echo "NOTE: Using simple testbench (UVM not supported in iverilog)"
	$(IVERILOG) -g2012 -o axi_stream.vvp \
		smol-tb.v smol-producer.v smol-consumer.v

run: compile
	$(VVP) axi_stream.vvp

else
$(error Unknown simulator: $(SIM). Use: questa, vcs, xcelium, or iverilog)
endif

# ========================================
# Common targets
# ========================================
all: run

clean:
	rm -rf work *.vvp *.vcd *.log *.wlf transcript *.out
	rm -rf csrc simv* *.daidir *.key
	rm -rf xcelium.d INCA_libs

help:
	@echo "Available targets:"
	@echo "  make run SIM=questa   - Run with Questa/ModelSim (default)"
	@echo "  make run SIM=vcs      - Run with Synopsys VCS"
	@echo "  make run SIM=xcelium  - Run with Cadence Xcelium"
	@echo "  make run SIM=iverilog - Run with Icarus Verilog (no UVM)"
	@echo "  make gui SIM=questa   - Run Questa with GUI"
	@echo "  make clean            - Remove generated files"
	@echo ""
	@echo "Example: make run SIM=questa UVM_HOME=/path/to/uvm"

.PHONY: all run compile gui clean help
