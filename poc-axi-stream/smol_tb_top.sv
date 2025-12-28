module smol_tb_top;
    import uvm_pkg::*;
    import smol_axis_pkg::*;
    
    logic clk = 0;
    always #5ns clk = ~clk; 
    
    smol_axis_if axis_if(clk);
    
    smolproducer prod_inst(
        .clk(axis_if.clk),
        .rst_n(axis_if.rst_n),
        .vld(axis_if.vld),
        .rdy(axis_if.rdy),
        .data(axis_if.data),
        .next_data()  // Leave unconnected
    );
    
    smolconsumer cons_inst(
        .clk(axis_if.clk),
        .rst_n(axis_if.rst_n),
        .vld(axis_if.vld),
        .rdy(axis_if.rdy),
        .data(axis_if.data)
    );
    
    initial begin
        uvm_config_db#(virtual smol_axis_if)::set(null, "*", "vif", axis_if);
        
        axis_if.rst_n = 0;
        repeat(5) @(posedge clk);
        axis_if.rst_n = 1;
        
        run_test("smol_test");
    end
    
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, smol_tb_top);
    end
    
    initial begin
        #10us;
        $display("TIMEOUT: Test ran too long");
        $finish;
    end
    
endmodule

