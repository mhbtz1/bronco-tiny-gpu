// AXI-Stream interface - SIMPLIFIED (removed clocking blocks)
interface smol_axis_if(input logic clk);
    logic rst_n;
    logic [31:0] data;
    logic vld;
    logic rdy;
    
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

// Package with ALL UVM components inside
package smol_axis_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    // Sequence item
    class axis_beat extends uvm_sequence_item;
        rand bit [31:0] data;
        
        `uvm_object_utils_begin(axis_beat)
            `uvm_field_int(data, UVM_ALL_ON)
        `uvm_object_utils_end

        function new(string name="axis_beat"); 
            super.new(name); 
        endfunction
    endclass

    // Monitor
    class stream_monitor extends uvm_monitor;
        `uvm_component_utils(stream_monitor)
        
        virtual smol_axis_if vif;
        uvm_analysis_port #(axis_beat) ap;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            ap = new("ap", this);
            if (!uvm_config_db#(virtual smol_axis_if)::get(this, "", "vif", vif))
                `uvm_fatal("NOVIF", "stream_monitor: no vif")
        endfunction

        task run_phase(uvm_phase phase);
            axis_beat beat;
            
            // Wait for reset deassertion
            @(posedge vif.clk);
            wait(vif.rst_n);
            
            forever begin
                @(posedge vif.clk);
                if (vif.vld && vif.rdy) begin
                    beat = axis_beat::type_id::create("beat");
                    beat.data = vif.data;
                    `uvm_info("MONITOR", $sformatf("Captured: data=0x%08h", beat.data), UVM_HIGH)
                    ap.write(beat);
                end
            end
        endtask
    endclass

    // Scoreboard
    class stream_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(stream_scoreboard)
        
        uvm_analysis_imp #(axis_beat, stream_scoreboard) ap;
        
        int expected_data = 0;
        int received_count = 0;
        int error_count = 0;
        
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            ap = new("ap", this);
        endfunction
        
        function void write(axis_beat beat);
            received_count++;
            
            if (beat.data == expected_data) begin
                `uvm_info("SCOREBOARD", $sformatf("PASS: Received 0x%08h (expected 0x%08h)", 
                          beat.data, expected_data), UVM_MEDIUM)
            end else begin
                `uvm_error("SCOREBOARD", $sformatf("FAIL: Received 0x%08h (expected 0x%08h)", 
                           beat.data, expected_data))
                error_count++;
            end
            
            expected_data++;
        endfunction
        
        function void report_phase(uvm_phase phase);
            super.report_phase(phase);
            `uvm_info("SCOREBOARD", "=== Final Report ===", UVM_LOW)
            `uvm_info("SCOREBOARD", $sformatf("Transactions: %0d", received_count), UVM_LOW)
            `uvm_info("SCOREBOARD", $sformatf("Errors: %0d", error_count), UVM_LOW)
            
            if (error_count == 0 && received_count > 0) begin
                `uvm_info("SCOREBOARD", "*** TEST PASSED ***", UVM_LOW)
            end else if (received_count == 0) begin
                `uvm_error("SCOREBOARD", "*** TEST FAILED: No transactions received ***")
            end else begin
                `uvm_error("SCOREBOARD", "*** TEST FAILED: Data mismatches detected ***")
            end
        endfunction
    endclass

    // Driver
    class ready_driver extends uvm_driver;
        `uvm_component_utils(ready_driver)

        virtual smol_axis_if vif;
        rand int unsigned ready_pct = 70;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual smol_axis_if)::get(this, "", "vif", vif))
                `uvm_fatal("NOVIF", "ready_driver: no vif")
        endfunction

        task run_phase(uvm_phase phase);
            vif.rdy <= 0;
            // wait reset deassert
            @(posedge vif.clk);
            wait(vif.rst_n);

            forever begin
                @(posedge vif.clk);
                vif.rdy <= ($urandom_range(0,99) < ready_pct);
            end
        endtask
    endclass

    // Environment
    class smol_env extends uvm_env;
        `uvm_component_utils(smol_env)
        
        ready_driver drv;
        stream_monitor mon;
        stream_scoreboard sb;
        
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            drv = ready_driver::type_id::create("drv", this);
            mon = stream_monitor::type_id::create("mon", this);
            sb = stream_scoreboard::type_id::create("sb", this);
        endfunction
        
        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            mon.ap.connect(sb.ap);
        endfunction
    endclass
    
    // Test
    class smol_test extends uvm_test;
        `uvm_component_utils(smol_test)
        
        smol_env env;
        
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            env = smol_env::type_id::create("env", this);
        endfunction
        
        task run_phase(uvm_phase phase);
            phase.raise_objection(this);
            `uvm_info("TEST", "Starting AXI-Stream test", UVM_LOW)
            
            #5000ns;
            
            `uvm_info("TEST", "Test completed", UVM_LOW)
            phase.drop_objection(this);
        endtask
    endclass
    
endpackage

// Top module - FIXED timing to comply with UVM requirements
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
    
    // CRITICAL: run_test must be called at time 0
    initial begin
        // Set config DB BEFORE run_test
        uvm_config_db#(virtual smol_axis_if)::set(null, "*", "vif", axis_if);
        
        // Start with reset asserted
        axis_if.rst_n = 0;
        
        // Call run_test at time 0 - NO delays before this
        run_test("smol_test");
    end
    
    // Handle reset in a separate process
    initial begin
        #0;  // Start at time 0
        axis_if.rst_n = 0;
        repeat(5) @(posedge clk);
        axis_if.rst_n = 1;
        `uvm_info("TB_TOP", "Reset deasserted", UVM_LOW)
    end
    
    // Waveform dumping
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, smol_tb_top);
    end
    
    // Timeout watchdog
    initial begin
        #10us;
        $display("TIMEOUT: Test ran too long");
        $finish;
    end
    
endmodule