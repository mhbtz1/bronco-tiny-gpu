# AXI-Stream UVM Testbench

This directory contains a UVM-based testbench for validating AXI-Stream protocol implementations.

## Architecture

```
smol_tb_top
├── smolproducer (DUT - Producer)
├── smolconsumer (DUT - Consumer)
└── UVM Environment
    ├── ready_driver     (Drives random backpressure)
    ├── stream_monitor   (Captures transactions)
    └── stream_scoreboard (Checks data integrity)
```

## Files

- **RTL:**
  - `smol-producer.v` - Producer module (generates incrementing data)
  - `smol-consumer.v` - Consumer module (receives and displays data)

- **UVM Components:**
  - `smol_axis_if.sv` - SystemVerilog interface for AXI-Stream
  - `smol-driver.sv` - UVM driver (random ready generation)
  - `smol-monitor.sv` - UVM monitor (transaction capture)
  - `smol-scoreboard.sv` - UVM scoreboard (data checking)
  - `smol_axis_pkg.sv` - UVM package (environment + test)
  - `smol_tb_top.sv` - Top-level testbench

- **Legacy:**
  - `smol-tb.v` - Simple Verilog testbench (no UVM)

## Running the Testbench

### Option 1: With Commercial Simulators (Full UVM)

#### Questa/ModelSim
```bash
make run SIM=questa UVM_HOME=/path/to/uvm-1.2
# Or with GUI:
make gui SIM=questa UVM_HOME=/path/to/uvm-1.2
```

#### Synopsys VCS
```bash
make run SIM=vcs UVM_HOME=/path/to/uvm-1.2
```

#### Cadence Xcelium
```bash
make run SIM=xcelium UVM_HOME=/path/to/uvm-1.2
```

### Option 2: With Open-Source Tools (Simple test, no UVM)

```bash
make run SIM=iverilog
```

This uses the simple `smol-tb.v` testbench without UVM features.

## What the Test Does

1. **Producer** generates incrementing 32-bit data (0x00, 0x01, 0x02, ...)
2. **Driver** applies random backpressure via `rdy` signal (70% ready by default)
3. **Monitor** captures all completed transactions (when `vld && rdy`)
4. **Scoreboard** verifies data integrity (checks for sequential values)
5. **Report** prints pass/fail results

## Expected Output

```
UVM_INFO MONITOR: Captured: data=0x00000000
UVM_INFO SCOREBOARD: ✓ PASS: Received 0x00000000 (expected 0x00000000)
UVM_INFO MONITOR: Captured: data=0x00000001
UVM_INFO SCOREBOARD: ✓ PASS: Received 0x00000001 (expected 0x00000001)
...
UVM_INFO SCOREBOARD: === Final Report ===
UVM_INFO SCOREBOARD: Transactions: 50
UVM_INFO SCOREBOARD: Errors: 0
UVM_INFO SCOREBOARD: *** TEST PASSED ***
```

## Customization

### Adjust Backpressure
Modify `ready_pct` in driver:
```systemverilog
rand int unsigned ready_pct = 70;  // 70% ready
```

### Change Test Duration
Modify run_phase in test:
```systemverilog
task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    #5000ns;  // Change duration here
    phase.drop_objection(this);
endtask
```

### Add More Tests
Create new test classes in `smol_axis_pkg.sv`:
```systemverilog
class my_custom_test extends smol_test;
    `uvm_component_utils(my_custom_test)
    // Custom test behavior
endclass
```

## Waveforms

VCD waveforms are generated in `wave.vcd`. View with:
```bash
gtkwave wave.vcd
```

## Troubleshooting

**UVM not found:**
- Set `UVM_HOME` to point to your UVM installation
- Example: `export UVM_HOME=/usr/local/share/uvm-1.2`

**Compilation errors:**
- Ensure you're using a UVM-compatible simulator
- Check SystemVerilog support in your simulator

**No transactions:**
- Check reset sequence timing
- Verify interface connections in `smol_tb_top.sv`

