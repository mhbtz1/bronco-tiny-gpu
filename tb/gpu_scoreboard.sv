class gpu_scoreboard extends uvm_scoreboard;
    
    `uvm_component_utils(gpu_scoreboard)
    
    // Analysis ports from monitors
    uvm_analysis_imp_control #(gpu_control_transaction, gpu_scoreboard) control_export;
    uvm_analysis_imp_mem_req #(gpu_memory_transaction, gpu_scoreboard) mem_req_export;
    uvm_analysis_imp_mem_rsp #(gpu_memory_transaction, gpu_scoreboard) mem_rsp_export;
    uvm_analysis_imp_result #(gpu_result_transaction, gpu_scoreboard) result_export;
    
    // State tracking
    bit [ADDR_WIDTH-1:0] w_base_addr;
    bit [ADDR_WIDTH-1:0] x_base_addr;
    bit run_issued;
    
    // Data storage
    bit [DATA_WIDTH-1:0] w_matrix[W_DEPTH];
    bit [DATA_WIDTH-1:0] x_vector[X_DEPTH];
    bit [ACC_WIDTH-1:0] expected_results[MAT_DIM];
    
    // Result collection
    bit [ACC_WIDTH-1:0] actual_results[$];
    int result_count;
    
    // Statistics
    int transactions_checked;
    int transactions_passed;
    int transactions_failed;
    
    function new(string name = "gpu_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        control_export = new("control_export", this);
        mem_req_export = new("mem_req_export", this);
        mem_rsp_export = new("mem_rsp_export", this);
        result_export = new("result_export", this);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        w_base_addr = 0;
        x_base_addr = 0;
        run_issued = 0;
        result_count = 0;
        transactions_checked = 0;
        transactions_passed = 0;
        transactions_failed = 0;
    endfunction
    
    // Receive control commands
    virtual function void write_control(gpu_control_transaction trans);
        `uvm_info(get_type_name(), $sformatf("Received control: %s", trans.convert2string()), UVM_MEDIUM)
        
        case(trans.op_code)
            SET_W_BASE: begin
                w_base_addr = trans.cfg_data;
                `uvm_info(get_type_name(), $sformatf("Set W_BASE = 0x%0h", w_base_addr), UVM_LOW)
            end
            SET_X_BASE: begin
                x_base_addr = trans.cfg_data;
                `uvm_info(get_type_name(), $sformatf("Set X_BASE = 0x%0h", x_base_addr), UVM_LOW)
            end
            RUN: begin
                run_issued = 1;
                result_count = 0;
                actual_results.delete();
                `uvm_info(get_type_name(), "RUN command issued", UVM_LOW)
            end
        endcase
    endfunction
    
    // Track memory requests (not used for checking, just logging)
    virtual function void write_mem_req(gpu_memory_transaction trans);
        `uvm_info(get_type_name(), $sformatf("Memory request: addr=0x%0h", trans.addr), UVM_HIGH)
    endfunction
    
    // Collect memory responses to build W and X matrices
    int w_collect_idx = 0;
    int x_collect_idx = 0;
    
    virtual function void write_mem_rsp(gpu_memory_transaction trans);
        `uvm_info(get_type_name(), $sformatf("Memory response: data=0x%0h", trans.data), UVM_HIGH)
        
        if (run_issued) begin
            // Collect W matrix (first W_DEPTH responses)
            if (w_collect_idx < W_DEPTH) begin
                w_matrix[w_collect_idx] = trans.data;
                `uvm_info(get_type_name(), $sformatf("Collected W[%0d] = 0x%0h", w_collect_idx, trans.data), UVM_MEDIUM)
                w_collect_idx++;
                
                // When W is complete, compute expected results
                if (w_collect_idx == W_DEPTH && x_collect_idx == X_DEPTH) begin
                    compute_expected_results();
                    w_collect_idx = 0;
                    x_collect_idx = 0;
                end
            end
            // Collect X vector (next X_DEPTH responses)
            else if (x_collect_idx < X_DEPTH) begin
                x_vector[x_collect_idx] = trans.data;
                `uvm_info(get_type_name(), $sformatf("Collected X[%0d] = 0x%0h", x_collect_idx, trans.data), UVM_MEDIUM)
                x_collect_idx++;
                
                // When both W and X are complete, compute expected results
                if (w_collect_idx == W_DEPTH && x_collect_idx == X_DEPTH) begin
                    compute_expected_results();
                    w_collect_idx = 0;
                    x_collect_idx = 0;
                end
            end
        end
    endfunction
    
    // Golden reference model: matrix-vector multiplication
    virtual function void compute_expected_results();
        `uvm_info(get_type_name(), "Computing expected results", UVM_LOW)
        
        // For each row in the matrix
        for (int row = 0; row < MAT_DIM; row++) begin
            bit [ACC_WIDTH-1:0] sum = 0;
            
            // Compute dot product: sum(W[row][col] * X[col])
            for (int col = 0; col < MAT_DIM; col++) begin
                int w_idx = row * MAT_DIM + col;
                bit [ACC_WIDTH-1:0] product = w_matrix[w_idx] * x_vector[col];
                sum += product;
                
                `uvm_info(get_type_name(), 
                         $sformatf("  row=%0d, col=%0d: W[%0d]=0x%0h * X[%0d]=0x%0h = %0d",
                                  row, col, w_idx, w_matrix[w_idx], col, x_vector[col], product),
                         UVM_HIGH)
            end
            
            expected_results[row] = sum;
            `uvm_info(get_type_name(), 
                     $sformatf("Expected result[%0d] = %0d (0x%0h)", row, sum, sum),
                     UVM_LOW)
        end
    endfunction
    
    // Check results
    virtual function void write_result(gpu_result_transaction trans);
        `uvm_info(get_type_name(), $sformatf("Received result: %s", trans.convert2string()), UVM_MEDIUM)
        
        actual_results.push_back(trans.data);
        
        if (result_count < MAT_DIM) begin
            bit [ACC_WIDTH-1:0] expected = expected_results[result_count];
            bit [ACC_WIDTH-1:0] actual = trans.data;
            
            transactions_checked++;
            
            if (expected == actual) begin
                transactions_passed++;
                `uvm_info(get_type_name(), 
                         $sformatf("PASS: Result[%0d] = %0d (expected %0d)", 
                                  result_count, actual, expected),
                         UVM_LOW)
            end else begin
                transactions_failed++;
                `uvm_error(get_type_name(), 
                          $sformatf("FAIL: Result[%0d] = %0d, expected %0d (diff = %0d)", 
                                   result_count, actual, expected, actual - expected))
            end
            
            result_count++;
            
            if (result_count == MAT_DIM) begin
                run_issued = 0;
                `uvm_info(get_type_name(), "All results checked for this operation", UVM_LOW)
            end
        end
    endfunction
    
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        `uvm_info(get_type_name(), "========================================", UVM_NONE)
        `uvm_info(get_type_name(), "       SCOREBOARD FINAL REPORT", UVM_NONE)
        `uvm_info(get_type_name(), "========================================", UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("Transactions Checked: %0d", transactions_checked), UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("Transactions Passed:  %0d", transactions_passed), UVM_NONE)
        `uvm_info(get_type_name(), $sformatf("Transactions Failed:  %0d", transactions_failed), UVM_NONE)
        
        if (transactions_failed == 0 && transactions_checked > 0) begin
            `uvm_info(get_type_name(), "*** TEST PASSED ***", UVM_NONE)
        end else if (transactions_checked == 0) begin
            `uvm_warning(get_type_name(), "*** NO TRANSACTIONS CHECKED ***")
        end else begin
            `uvm_error(get_type_name(), "*** TEST FAILED ***")
        end
        `uvm_info(get_type_name(), "========================================", UVM_NONE)
    endfunction
    
endclass

// Define analysis imp macros
`uvm_analysis_imp_decl(_control)
`uvm_analysis_imp_decl(_mem_req)
`uvm_analysis_imp_decl(_mem_rsp)
`uvm_analysis_imp_decl(_result)