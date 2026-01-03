class gpu_env extends uvm_env;
    
    `uvm_component_utils(gpu_env)
    
    gpu_control_agent control_agent;
    gpu_memory_agent memory_agent;
    gpu_result_agent result_agent;
    
    gpu_scoreboard scoreboard;
    gpu_coverage coverage;
    
    gpu_config cfg;
    
    function new(string name = "gpu_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Get configuration
        if (!uvm_config_db#(gpu_config)::get(this, "", "config", cfg)) begin
            `uvm_info(get_type_name(), "Using default config", UVM_MEDIUM)
            cfg = gpu_config::type_id::create("cfg");
            cfg.randomize();
        end
        
        // Set config for all sub-components
        uvm_config_db#(gpu_config)::set(this, "*", "config", cfg);
        
        // Create agents
        control_agent = gpu_control_agent::type_id::create("control_agent", this);
        memory_agent = gpu_memory_agent::type_id::create("memory_agent", this);
        result_agent = gpu_result_agent::type_id::create("result_agent", this);
        
        // Create scoreboard
        if (cfg.enable_scoreboard) begin
            scoreboard = gpu_scoreboard::type_id::create("scoreboard", this);
        end
        
        // Create coverage
        if (cfg.enable_coverage) begin
            coverage = gpu_coverage::type_id::create("coverage", this);
        end
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        if (cfg.enable_scoreboard) begin
            // Connect monitors to scoreboard
            control_agent.monitor.ap.connect(scoreboard.control_export);
            memory_agent.monitor.req_ap.connect(scoreboard.mem_req_export);
            memory_agent.monitor.rsp_ap.connect(scoreboard.mem_rsp_export);
            result_agent.monitor.ap.connect(scoreboard.result_export);
        end
        
        if (cfg.enable_coverage) begin
            // Connect control monitor to coverage
            control_agent.monitor.ap.connect(coverage.analysis_export);
        end
    endfunction
    
endclass