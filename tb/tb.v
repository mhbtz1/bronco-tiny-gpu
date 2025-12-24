module tb;
  input clk, src_vld, src_rdy, src_data;
  wire snk_vld, snk_rdy, snk_data;
  output busy, result_vld, result_rdy, result_data;

  gpu_top gpu_top_inst(.clk(clk), 
    .src_vld(src_vld), 
    .src_rdy(src_rdy), 
    .src_data(src_data), 
    .snk_vld(snk_vld), 
    .snk_rdy(snk_rdy), 
    .snk_data(snk_data), 
    .busy(busy), 
    .result_vld(result_vld), 
    .result_rdy(result_rdy), 
    .result_data(result_data)
  );

  initial begin
  end
endmodule

