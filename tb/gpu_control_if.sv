interface gpu_control_if(input logic clk, input logic rst_n);
    
    logic start;
    logic [1:0] op_code;
    logic [constants_pkg::ADDR_WIDTH-1:0] cfg_data;
    logic busy;
    
    // Clocking block for driver
    clocking driver_cb @(posedge clk);
        default input #1step output #1ns;
        output start;
        output op_code;
        output cfg_data;
        input busy;
    endclocking
    
    // Clocking block for monitor
    clocking monitor_cb @(posedge clk);
        default input #1step;
        input start;
        input op_code;
        input cfg_data;
        input busy;
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