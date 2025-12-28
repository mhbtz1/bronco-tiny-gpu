package smol_axis_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    `include "smol-monitor.sv"
    `include "smol-driver.sv"
    `include "smol-scoreboard.sv"
    
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
    
    // Base test
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

