module testbench;
    reg clk;
    reg rst_n;
    wire en;
    wire wr;
    wire data;

    initial begin
        clk = 0;
    end

    test_design dut(
        .clk(clk)
        .rst_n(rst_n)
        .en(en)
        .wire(wire)
        .data(data)
    );
    
    task apply_reset() 
        #5 rst_n <= 0;
        #20 rst_n <= 1;
    endtask

    forever #5 clk = ~clk;
    always @(posedge clk)
    begin

    end
endmodule