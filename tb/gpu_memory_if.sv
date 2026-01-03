interface gpu_memory_if(input logic clk, input logic rst_n);
    
    // Request signals
    logic m_req_vld;
    logic m_req_rdy;
    logic [constants_pkg::ADDR_WIDTH-1:0] m_req_addr;
    
    // Response signals
    logic m_rsp_vld;
    logic m_rsp_rdy;
    logic [constants_pkg::DATA_WIDTH-1:0] m_rsp_data;
    
    // Clocking block for driver (models memory)
    clocking driver_cb @(posedge clk);
        default input #1step output #1ns;
        input m_req_vld;
        output m_req_rdy;
        input m_req_addr;
        output m_rsp_vld;
        input m_rsp_rdy;
        output m_rsp_data;
    endclocking
    
    // Clocking block for monitor
    clocking monitor_cb @(posedge clk);
        default input #1step;
        input m_req_vld;
        input m_req_rdy;
        input m_req_addr;
        input m_rsp_vld;
        input m_rsp_rdy;
        input m_rsp_data;
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