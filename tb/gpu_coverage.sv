class gpu_coverage extends uvm_subscriber #(gpu_control_transaction);
    
    `uvm_component_utils(gpu_coverage)
    
    // Coverage variables
    bit [1:0] op_code;
    bit [ADDR_WIDTH-1:0] cfg_data;
    
    // State for cross coverage
    bit [1:0] last_op;
    
    // Covergroups
    covergroup control_cg;
        opcode_cp: coverpoint op_code {
            bins set_w_base = {SET_W_BASE};
            bins set_x_base = {SET_X_BASE};
            bins run = {RUN};
            bins res = {RES};
        }
        
        cfg_data_cp: coverpoint cfg_data {
            bins low = {[0:63]};
            bins mid = {[64:191]};
            bins high = {[192:255]};
        }
        
        // Sequential opcodes
        opcode_sequence: coverpoint op_code {
            bins config_sequence = (SET_W_BASE => SET_X_BASE => RUN);
            bins run_run = (RUN => RUN);  // Back-to-back operations
        }
        
        // Cross coverage
        opcode_x_cfg: cross opcode_cp, cfg_data_cp;
    endgroup
    
    function new(string name = "gpu_coverage", uvm_component parent = null);
        super.new(name, parent);
        control_cg = new();
        last_op = 0;
    endfunction
    
    virtual function void write(gpu_control_transaction t);
        op_code = t.op_code;
        cfg_data = t.cfg_data;
        control_cg.sample();
        last_op = op_code;
    endfunction
    
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(), $sformatf("Coverage = %.2f%%", control_cg.get_coverage()), UVM_NONE)
    endfunction
    
endclass