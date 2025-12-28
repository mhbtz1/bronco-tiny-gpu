#include "Vtb_top.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

static vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);

  Vtb_top* top = new Vtb_top;

  VerilatedVcdC* tfp = nullptr;
#if VM_TRACE
  Verilated::traceEverOn(true);
  tfp = new VerilatedVcdC;
  top->trace(tfp, 99);
  tfp->open("wave.vcd");
#endif

  // Run for N cycles (adjust as needed)
  const int cycles = 500;

  for (int i = 0; i < cycles * 2 && !Verilated::gotFinish(); i++) {
    // Toggle clock every half-cycle if your tb_top has a 'clk' reg/bit driven from C++
    // If your tb_top generates its own clock internally, you can omit this.
    top->clk = (i & 1);

    top->eval();

#if VM_TRACE
    if (tfp) tfp->dump(main_time);
#endif
    main_time++;
  }

#if VM_TRACE
  if (tfp) { tfp->close(); delete tfp; }
#endif
  delete top;
  return 0;
}
