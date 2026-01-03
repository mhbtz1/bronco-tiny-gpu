class gpu_memory_monitor extends uvm_monitor;
    `uvm_component_utils(gpu_memory_monitor)
    virtual gpu_memory_if vif;
    
    uvm_analysis_port #(gpu_memory_transaction) req_ap;
    uvm_analysis_port #(gpu_memory_transaction) rsp_ap;

    function new(string name="gpu_memory_monitor", uvm_component parent=null);
        super.new(name, parent);
        req_ap = new ("req_ap", this);
        rsp_ap = new ("rsp_ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual gpu_memory_if)::get(this, "", "memory_vif", vif)) begin
            `uvm_fatal(get_type_name(), "Virtual interface not found in config database");
        end

    endfunction

    virtual task run_phase(uvm_phase phase);
        fork
            monitor_requests();
            monitor_responses();
        join
    endtask

    virtual task monitor_requests();
        forever begin
        end
    endtask

    virtual task monitor_responses();
        forever begin 
            gpu_memory_transaction trans;
            @(vif.monitor_cb)
        end
    endtask


endclass