module smoltb;
  reg clk, rst_n;
  wire [31:0] data;
  wire vld;
  wire rdy;
  wire [31:0] next_data;

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    rst_n = 0;
    repeat (5) @(posedge clk);
    rst_n = 1;
  end

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, smoltb);
    #500 $finish;
  end

  smolproducer prod_inst(
    .clk(clk),
    .rst_n(rst_n),
    .vld(vld),
    .rdy(rdy),
    .data(data),
    .next_data(next_data)
  );

  smolconsumer cons_inst(
    .clk(clk),
    .rst_n(rst_n),
    .vld(vld),
    .rdy(rdy),
    .data(data)
  );
endmodule
