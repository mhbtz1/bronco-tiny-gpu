typedef { 
    int a;
    real b;
} test_struct;


module testbench;
    reg clk;
    reg rst_n;
    wire en;
    wire wr;
    wire data;

    logic [3:0] test_data;
    logic [3:0] test_en;

    bit [7:0] random;
    byte same_random;

    initial begin
        clk = 0;
    end

    initial begin
        test_data = 4'b0101;
        $display("test_data = %0d", test_data);
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