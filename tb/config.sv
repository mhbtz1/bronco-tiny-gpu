class gpu_config extends uvm_object;
    rand int memory_latency_min;
    rand int memory_latency_max;
    rand bit enable_backpressure;
    rand int backpressure_prob;

    constraint reasonable_timing {
        memory_latency_min inside {[0:10]}
        memory_latency_max inside {[latency_min:20]}
        backpressure_prob inside {[0:50]}
    }
endclass