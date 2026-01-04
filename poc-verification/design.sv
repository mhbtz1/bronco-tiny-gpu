interface test_design_if(input clk)
    logic rst_n;
    logic wr;
    logic en;
    logic [7:0] wdata;
    logic [7:0] addr;
    logic [7:0] src_data;
endinterface


module test_design(
    input clk,
    input rst_n,
    input wr,
    input en, 
    input wdata,
    input addr,
    output src_data
);


    always @(posedge clk or negedge rst_n)
    begin
    end

endmodule

module test_design_wrapper(test_design_if tif)
    test_design dsn0(
        .clk(tif.clk),
        .rst_n(tif.rst_n),
        .wr(tif.wr),
        .en(tif.en),
        .wdata(tif.wdata),
        .addr(tif.addr),
        .src_data(tif.src_data)
    )
endmodule

// Instantiate DUT wrapper with test_design_wrapper dsw0 (.tif (custom_tif))