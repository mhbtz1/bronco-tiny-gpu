module clock_gen;
  reg clk = 0;

  always #5 clk = ~clk;  // 10 time-unit period
endmodule
