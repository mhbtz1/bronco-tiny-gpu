// Memory sequences - mostly handled by driver
class gpu_memory_base_seq extends uvm_sequence #(gpu_memory_transaction);
    `uvm_object_utils(gpu_memory_base_seq)
    
    function new(string name = "gpu_memory_base_seq");
        super.new(name);
    endfunction
endclass

// Result sequences - for backpressure control
class gpu_result_base_seq extends uvm_sequence #(gpu_result_transaction);
    `uvm_object_utils(gpu_result_base_seq)
    
    function new(string name = "gpu_result_base_seq");
        super.new(name);
    endfunction
endclass