class gpu_memory_agent extends uvm_agent;
    
    `uvm_component_utils(gpu_memory_agent)
    
    gpu_memory_driver driver;
    gpu_memory_monitor monitor;
    gpu_memory_sequencer sequencer;
    
    gpu_config cfg;
    
    function new(string name = "gpu_memory_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if (!uvm_config_db#(gpu_config)::get(this, "", "config", cfg))
            `uvm_warning(get_type_name(), "Config not found, using defaults")
        
        monitor = gpu_memory_monitor::type_id::create("monitor", this);
        
        if (cfg == null || cfg.memory_agent_is_active == UVM_ACTIVE) begin
            driver = gpu_memory_driver::type_id::create("driver", this);
            sequencer = gpu_memory_sequencer::type_id::create("sequencer", this);
        end
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (cfg == null || cfg.memory_agent_is_active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction
    
endclass