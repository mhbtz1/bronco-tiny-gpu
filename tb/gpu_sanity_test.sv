class gpu_sanity_test extends gpu_base_test;
    
    `uvm_component_utils(gpu_sanity_test)
    
    function new(string name = "gpu_sanity_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        simple_matmul_vseq vseq;
        bit [DATA_WIDTH-1:0] w_data[W_DEPTH];
        bit [DATA_WIDTH-1:0] x_data[X_DEPTH];
        
        phase.raise_objection(this);
        
        `uvm_info(get_type_name(), "========================================", UVM_NONE)
        `uvm_info(get_type_name(), "      STARTING SANITY TEST", UVM_NONE)
        `uvm_info(get_type_name(), "========================================", UVM_NONE)
        
        // Simple identity-like test
        // W = Identity matrix (simplified for 4x4):
        // [1 0 0 0]
        // [0 1 0 0]
        // [0 0 1 0]
        // [0 0 0 1]
        w_data[0] = 1; w_data[1] = 0; w_data[2] = 0; w_data[3] = 0;
        w_data[4] = 0; w_data[5] = 1; w_data[6] = 0; w_data[7] = 0;
        w_data[8] = 0; w_data[9] = 0; w_data[10] = 1; w_data[11] = 0;
        w_data[12] = 0; w_data[13] = 0; w_data[14] = 0; w_data[15] = 1;
        
        // X = [5, 10, 15, 20]
        x_data[0] = 5;
        x_data[1] = 10;
        x_data[2] = 15;
        x_data[3] = 20;
        
        // Expected result: [5, 10, 15, 20] (identity * X = X)
        
        load_test_data(w_data, x_data, 8'h00, 8'h10);
        
        // Run the test
        vseq = simple_matmul_vseq::type_id::create("vseq");
        vseq.w_base = 8'h00;
        vseq.x_base = 8'h10;
        vseq.start(null);
        
        #5000;  // Wait for completion
        
        `uvm_info(get_type_name(), "========================================", UVM_NONE)
        `uvm_info(get_type_name(), "      SANITY TEST COMPLETE", UVM_NONE)
        `uvm_info(get_type_name(), "========================================", UVM_NONE)
        
        phase.drop_objection(this);
    endtask
    
endclass