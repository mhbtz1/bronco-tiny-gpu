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
            gpu_memory_transaction trans;
            @(vif.monitor_cb)
            if (vif.monitor_cb.m_req_vld && vif.monitor_cb.m_req_rdy) begin
                trans = gpu_memory_transaction::type_id::create("mem_req_mon");
                trans.trans_type = REQ_TRANS;
                trans.addr = vif.monitor_cb.m_req_addr;
                `uvm_info(get_type_name(), $sformatf("Monitored REQ: addr=0x%0h", trans.addr), UVM_HIGH);
                req_ap.write(trans)
            end
        end
    endtask

    virtual task monitor_responses();
        forever begin 
            gpu_memory_transaction trans;
            @(vif.monitor_cb);
            
            if (vif.monitor_cb.m_rsp_vld && vif.monitor_cb.m_rsp_rdy) begin
                trans = gpu_memory_transaction::type_id::create("mem_rsp_mon");
                trans.trans_type = RSP_TRANS;
                trans.data = vif.monitor_cb.m_rsp_data;
                
                `uvm_info(get_type_name(), $sformatf("Monitored RSP: data=0x%0h", trans.data), UVM_HIGH)
                rsp_ap.write(trans);
            end
        end
    endtask


endclass