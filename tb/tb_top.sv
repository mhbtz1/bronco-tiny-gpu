module tb_top;
    
    import uvm_pkg::*;
    import gpu_pkg::*;
    
    // Clock and reset
    logic clk;
    logic rst_n;
    
    // Instantiate interfaces
    gpu_control_if control_if(clk, rst_n);
    gpu_memory_if memory_if(clk, rst_n);
    gpu_result_if result_if(clk, rst_n);
    
    // Instantiate DUT
    gpu_top dut(
        .clk(clk),
        .rst_n(rst_n),
        .start(control_if.start),
        .op_code(control_if.op_code),
        .cfg_data(control_if.cfg_data),
        .m_req_vld(memory_if.m_req_vld),
        .m_req_rdy(memory_if.m_req_rdy),
        .m_req_addr(memory_if.m_req_addr),
        .m_rsp_vld(memory_if.m_rsp_vld),
        .m_rsp_rdy(memory_if.m_rsp_rdy),
        .m_rsp_data(memory_if.m_rsp_data),
        .result_vld(result_if.result_vld),
        .result_rdy(result_if.result_rdy),
        .result_data(result_if.result_data),
        .busy(control_if.busy)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100MHz clock
    end
    
    // Reset generation
    initial begin
        rst_n = 0;
        repeat(5) @(posedge clk);
        rst_n = 1;
    end
    
    // UVM configuration
    initial begin
        // Set interfaces in config DB
        uvm_config_db#(virtual gpu_control_if)::set(null, "uvm_test_top.env.control_agent*", "control_vif", control_if);
        uvm_config_db#(virtual gpu_memory_if)::set(null, "uvm_test_top.env.memory_agent*", "memory_vif", memory_if);
        uvm_config_db#(virtual gpu_result_if)::set(null, "uvm_test_top.env.result_agent*", "result_vif", result_if);
        
        // Run test
        run_test();
    end
    
    // Waveform dumping
    initial begin
        $dumpfile("gpu_tb.vcd");
        $dumpvars(0, tb_top);
    end
    
    // Timeout watchdog
    initial begin
        #1000000;  // 1ms timeout
        $display("ERROR: Simulation timeout!");
        $finish;
    end
    
endmodule