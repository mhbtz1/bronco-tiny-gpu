// Base virtual sequence
class gpu_base_vseq extends uvm_sequence;
    
    `uvm_object_utils(gpu_base_vseq)
    `uvm_declare_p_sequencer(uvm_sequencer_base)
    
    gpu_control_sequencer control_sqr;
    
    function new(string name = "gpu_base_vseq");
        super.new(name);
    endfunction
    
    virtual task body();
        // Get sequencer handles
        if (!uvm_config_db#(gpu_control_sequencer)::get(null, "", "control_sequencer", control_sqr))
            `uvm_fatal(get_type_name(), "Cannot get control sequencer")
    endtask
    
    // Helper task to wait for operation completion
    virtual task wait_for_completion();
        // Wait for enough time for operation to complete
        // In real testbench, would monitor busy signal
        #10000;
    endtask
    
endclass

// Simple matrix multiply test
class simple_matmul_vseq extends gpu_base_vseq;
    
    `uvm_object_utils(simple_matmul_vseq)
    
    rand bit [ADDR_WIDTH-1:0] w_base;
    rand bit [ADDR_WIDTH-1:0] x_base;
    
    function new(string name = "simple_matmul_vseq");
        super.new(name);
        w_base = 8'h00;  // Default W base
        x_base = 8'h10;  // Default X base
    endfunction
    
    virtual task body();
        config_and_run_seq cfg_run;
        
        super.body();
        
        `uvm_info(get_type_name(), "Starting simple matrix multiply test", UVM_LOW)
        
        // Configure and run
        cfg_run = config_and_run_seq::type_id::create("cfg_run");
        cfg_run.w_base = w_base;
        cfg_run.x_base = x_base;
        cfg_run.start(control_sqr);
        
        wait_for_completion();
        
        `uvm_info(get_type_name(), "Completed simple matrix multiply test", UVM_LOW)
    endtask
    
endclass

// Back-to-back operations
class back_to_back_vseq extends gpu_base_vseq;
    
    `uvm_object_utils(back_to_back_vseq)
    
    rand int num_operations;
    
    constraint reasonable_c {
        num_operations inside {[2:5]};
    }
    
    function new(string name = "back_to_back_vseq");
        super.new(name);
    endfunction
    
    virtual task body();
        super.body();
        
        `uvm_info(get_type_name(), $sformatf("Starting %0d back-to-back operations", num_operations), UVM_LOW)
        
        for (int i = 0; i < num_operations; i++) begin
            config_and_run_seq cfg_run;
            
            cfg_run = config_and_run_seq::type_id::create($sformatf("cfg_run_%0d", i));
            assert(cfg_run.randomize());
            cfg_run.start(control_sqr);
            
            wait_for_completion();
        end
        
        `uvm_info(get_type_name(), "Completed back-to-back operations", UVM_LOW)
    endtask
    
endclass

// Stress test with random operations
class stress_test_vseq extends gpu_base_vseq;
    
    `uvm_object_utils(stress_test_vseq)
    
    rand int num_operations;
    
    constraint stress_c {
        num_operations inside {[10:20]};
    }
    
    function new(string name = "stress_test_vseq");
        super.new(name);
    endfunction
    
    virtual task body();
        super.body();
        
        `uvm_info(get_type_name(), $sformatf("Starting stress test with %0d operations", num_operations), UVM_LOW)
        
        for (int i = 0; i < num_operations; i++) begin
            random_control_seq rand_seq;
            
            rand_seq = random_control_seq::type_id::create($sformatf("rand_seq_%0d", i));
            rand_seq.num_transactions = $urandom_range(1, 5);
            rand_seq.start(control_sqr);
        end
        
        wait_for_completion();
        
        `uvm_info(get_type_name(), "Completed stress test", UVM_LOW)
    endtask
    
endclass