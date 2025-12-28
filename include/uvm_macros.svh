interface smol_axis_if(input bit clk);
  logic rst_n;
  logic vld;
  logic rdy;
  logic [31:0] data;
endinterface
