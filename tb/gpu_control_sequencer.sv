// Control Sequencer
class gpu_control_sequencer extends uvm_sequencer #(gpu_control_transaction);
    `uvm_component_utils(gpu_control_sequencer)
    
    function new(string name = "gpu_control_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass

// Memory Sequencer
class gpu_memory_sequencer extends uvm_sequencer #(gpu_memory_transaction);
    `uvm_component_utils(gpu_memory_sequencer)
    
    function new(string name = "gpu_memory_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass

// Result Sequencer
class gpu_result_sequencer extends uvm_sequencer #(gpu_result_transaction);
    `uvm_component_utils(gpu_result_sequencer)
    
    function new(string name = "gpu_result_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass