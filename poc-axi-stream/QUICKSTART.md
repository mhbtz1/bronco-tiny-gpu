# Quick Start Guide

## Files Created

### UVM Infrastructure (for commercial simulators)
- ✅ `smol_axis_if.sv` - AXI-Stream interface with modports
- ✅ `smol-driver.sv` - Random backpressure driver (ready_driver)
- ✅ `smol-monitor.sv` - Transaction monitor (stream_monitor)
- ✅ `smol-scoreboard.sv` - Data integrity checker (stream_scoreboard)
- ✅ `smol_axis_pkg.sv` - UVM package (env + test)
- ✅ `smol_tb_top.sv` - Top-level UVM testbench

### Simple Test (for open-source tools)
- ✅ `smol-tb.v` - Basic Verilog testbench
- ✅ `smol-producer.v` - Producer DUT (already existed, now fixed)
- ✅ `smol-consumer.v` - Consumer DUT (already existed)

### Build System
- ✅ `Makefile` - Multi-simulator support
- ✅ `README.md` - Detailed documentation
- ✅ `QUICKSTART.md` - This file

## Run Tests

### Simple Test (Iverilog - No UVM)
```bash
make run SIM=iverilog
```
**Output:** Displays incrementing data values with handshake confirmations

### UVM Test (Commercial Simulators)

#### Questa/ModelSim
```bash
make run SIM=questa UVM_HOME=/path/to/uvm
```

#### VCS
```bash
make run SIM=vcs UVM_HOME=/path/to/uvm
```

#### Xcelium
```bash
make run SIM=xcelium UVM_HOME=/path/to/uvm
```

## What You Get

### Simple Test (iverilog)
- Basic producer/consumer communication
- Sequential data transfer validation
- Console output showing each transaction

### UVM Test (commercial sims)
- **Random backpressure** testing (70% ready by default)
- **Automated scoreboarding** (checks data integrity)
- **Transaction monitoring** (captures all transfers)
- **Detailed reporting** (pass/fail with statistics)
- **Waveform generation** (wave.vcd)

## Typical Output

### Simple Test:
```
data processed = [00000000]
HANDSHAKE DONE
data processed = [00000001]
HANDSHAKE DONE
...
```

### UVM Test:
```
UVM_INFO MONITOR: Captured: data=0x00000000
UVM_INFO SCOREBOARD: ✓ PASS: Received 0x00000000 (expected 0x00000000)
...
UVM_INFO SCOREBOARD: === Final Report ===
UVM_INFO SCOREBOARD: Transactions: 50
UVM_INFO SCOREBOARD: Errors: 0
UVM_INFO SCOREBOARD: *** TEST PASSED ***
```

## Next Steps

1. **View waveforms:**
   ```bash
   gtkwave wave.vcd
   ```

2. **Modify backpressure:**
   Edit `ready_pct` in `smol-driver.sv` (line 5)

3. **Change test duration:**
   Edit delay in `smol_axis_pkg.sv` test run_phase

4. **Add custom tests:**
   Extend `smol_test` class in `smol_axis_pkg.sv`

## Troubleshooting

**"UVM not found"**
- Install UVM library or download from Accellera
- Set UVM_HOME environment variable

**"No transactions"**
- Check reset timing in testbench
- Verify interface connections

**"Compilation errors"**
- Ensure SystemVerilog support in simulator
- Check UVM version compatibility (1.2 recommended)

## Architecture Diagram

```
┌─────────────────────────────────────────┐
│         smol_tb_top (SV)                │
│                                         │
│  ┌──────────────┐   ┌──────────────┐  │
│  │ smolproducer │   │ smolconsumer │  │
│  │   (Verilog)  │   │   (Verilog)  │  │
│  └──────┬───────┘   └───────┬──────┘  │
│         │                   │          │
│         └────── vld/rdy/data┘          │
│                     ▲                   │
│  ┌──────────────────┴────────────────┐ │
│  │   UVM Environment (SV)            │ │
│  │  ┌──────────┐  ┌──────────────┐  │ │
│  │  │  Driver  │  │   Monitor    │  │ │
│  │  └─────┬────┘  └──────┬───────┘  │ │
│  │        │              │           │ │
│  │        │    ┌─────────▼────────┐ │ │
│  │        │    │   Scoreboard    │ │ │
│  │        │    └──────────────────┘ │ │
│  └────────┴───────────────────────┘  │
└─────────────────────────────────────────┘
```

