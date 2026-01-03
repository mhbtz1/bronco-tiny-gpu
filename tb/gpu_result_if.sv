interface gpu_result_if(input logic clk, input logic rst_n);
    
    logic result_vld;
    logic result_rdy;
    logic [constants_pkg::ACC_WIDTH-1:0] result_data;
    
    // Clocking block for driver (can apply backpressure)
    clocking driver_cb @(posedge clk);
        default input #1step output #1ns;
        input result_vld;
        output result_rdy;
        input result_data;
    endclocking
    
    // Clocking block for monitor
    clocking monitor_cb @(posedge clk);
        default input #1step;
        input result_vld;
        input result_rdy;
        input result_data;
    endclocking
    
    // Modport for driver
    modport driver_mp (
        clocking driver_cb,
        input clk,
        input rst_n
    );
    
    // Modport for monitor
    modport monitor_mp (
        clocking monitor_cb,
        input clk,
        input rst_n
    );
    
endinterface