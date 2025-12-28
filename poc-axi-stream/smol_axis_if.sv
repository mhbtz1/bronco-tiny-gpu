// AXI-Stream interface
interface smol_axis_if(input logic clk);
    logic rst_n;
    logic [31:0] data;
    logic vld;
    logic rdy;
    
    // Clocking blocks for synchronous driving
    clocking cb @(posedge clk);
        default input #1step output #1step;
        output rst_n;
        inout data;
        inout vld;
        inout rdy;
    endclocking
    
    // Modports for different perspectives
    modport producer (
        input clk, rst_n, rdy,
        output data, vld
    );
    
    modport consumer (
        input clk, rst_n, vld, data,
        output rdy
    );
    
    modport monitor (
        input clk, rst_n, data, vld, rdy
    );
    
endinterface

