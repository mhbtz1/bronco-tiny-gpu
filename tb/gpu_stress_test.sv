class gpu_stress_test extends gpu_base_test;
    
    `uvm_component_utils(gpu_stress_test)
    
    function new(string name = "gpu_stress_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Enable backpressure for stress test
        cfg.enable_mem_backpressure = 1;
        cfg.mem_backpressure_prob = 20;
        cfg.enable_result_backpressure = 1;
        cfg.result_backpressure_prob = 30;
        cfg.memory_latency_min = 1;
        cfg.memory_latency_max = 10;
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        back_to_back_vseq vseq;
        bit [DATA_WIDTH-1:0] w_data[W_DEPTH];
        bit [DATA_WIDTH-1:0] x_data[X_DEPTH];
        
        phase.raise_objection(this);
        
        `uvm_info(get_type_name(), "========================================", UVM_NONE)
        `uvm_info(get_type_name(), "      STARTING STRESS TEST", UVM_NONE)
        `uvm_info(get_type_name(), "========================================", UVM_NONE)
        
        // Load random test data
        for (int i = 0; i < W_DEPTH; i++) begin
            w_data[i] = $urandom_range(0, 15);  // Keep small for easier debugging
        end
        for (int i = 0; i < X_DEPTH; i++) begin
            x_data[i] = $urandom_range(0, 15);
        end
        
        load_test_data(w_data, x_data, 8'h00, 8'h10);
        
        // Run back-to-back operations
        vseq = back_to_back_vseq::type_id::create("vseq");
        assert(vseq.randomize() with { num_operations == 3; });
        vseq.start(null);
        
        #20000;  // Wait for completion
        
        `uvm_info(get_type_name(), "========================================", UVM_NONE)
        `uvm_info(get_type_name(), "      STRESS TEST COMPLETE", UVM_NONE)
        `uvm_info(get_type_name(), "========================================", UVM_NONE)
        
        phase.drop_objection(this);
    endtask
    
endclass