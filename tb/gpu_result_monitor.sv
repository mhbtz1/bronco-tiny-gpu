class gpu_result_monitor extends uvm_monitor;
    
    `uvm_component_utils(gpu_result_monitor);
    
    virtual gpu_result_if vif;
    uvm_analysis_port #(gpu_result_transaction) ap;

    function new (string name="gpu_result_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new ("ap", this);
    endfunction

    virtual function build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual gpu_result_if)::get(this, "", "result_vif", vif))
            `uvm_fatal(get_type_name(), "Virtual interface not found in config DB")
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            gpu_result_transaction trans;
            @(vif.monitor_cb);
            
            if (vif.monitor_cb.result_vld && vif.monitor_cb.result_rdy) begin
                trans = gpu_result_transaction::type_id::create("result_trans");
                trans.data = vif.monitor_cb.result_data;
                trans.timestamp = $time;
                
                `uvm_info(get_type_name(), $sformatf("Monitored Result: %s", trans.convert2string()), UVM_MEDIUM)
                ap.write(trans);
            end
        end
    endtask

endclass