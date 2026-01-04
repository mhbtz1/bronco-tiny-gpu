`include "uvm_macros.svh"
import uvm_pkg::*;

// ============================================================================
// INTERFACES
// ============================================================================

interface gpu_control_if(input logic clk, input logic rst_n);
    
    logic start;
    logic [1:0] op_code;
    logic [constants_pkg::ADDR_WIDTH-1:0] cfg_data;
    logic busy;
    
    clocking driver_cb @(posedge clk);
        default input #1step output #1ns;
        output start;
        output op_code;
        output cfg_data;
        input busy;
    endclocking
    
    clocking monitor_cb @(posedge clk);
        default input #1step;
        input start;
        input op_code;
        input cfg_data;
        input busy;
    endclocking
    
    modport driver_mp (
        clocking driver_cb,
        input clk,
        input rst_n
    );
    
    modport monitor_mp (
        clocking monitor_cb,
        input clk,
        input rst_n
    );
    
endinterface

interface gpu_memory_if(input logic clk, input logic rst_n);
    
    logic m_req_vld;
    logic m_req_rdy;
    logic [constants_pkg::ADDR_WIDTH-1:0] m_req_addr;
    
    logic m_rsp_vld;
    logic m_rsp_rdy;
    logic [constants_pkg::DATA_WIDTH-1:0] m_rsp_data;
    
    clocking driver_cb @(posedge clk);
        default input #1step output #1ns;
        input m_req_vld;
        output m_req_rdy;
        input m_req_addr;
        output m_rsp_vld;
        input m_rsp_rdy;
        output m_rsp_data;
    endclocking
    
    clocking monitor_cb @(posedge clk);
        default input #1step;
        input m_req_vld;
        input m_req_rdy;
        input m_req_addr;
        input m_rsp_vld;
        input m_rsp_rdy;
        input m_rsp_data;
    endclocking
    
    // Allow direct access to signals for reading outputs
    modport driver_mp (
        clocking driver_cb,
        input clk,
        input rst_n,
        input m_req_vld,    // Can read this directly
        input m_req_rdy,    // Can read what we wrote
        input m_req_addr,   // Can read this directly
        input m_rsp_rdy     // Can read this directly
    );
    
    modport monitor_mp (
        clocking monitor_cb,
        input clk,
        input rst_n
    );
    
endinterface

interface gpu_result_if(input logic clk, input logic rst_n);
    
    logic result_vld;
    logic result_rdy;
    logic [constants_pkg::ACC_WIDTH-1:0] result_data;
    
    clocking driver_cb @(posedge clk);
        default input #1step output #1ns;
        input result_vld;
        output result_rdy;
        input result_data;
    endclocking
    
    clocking monitor_cb @(posedge clk);
        default input #1step;
        input result_vld;
        input result_rdy;
        input result_data;
    endclocking
    
    modport driver_mp (
        clocking driver_cb,
        input clk,
        input rst_n
    );
    
    modport monitor_mp (
        clocking monitor_cb,
        input clk,
        input rst_n
    );
    
endinterface

// ============================================================================
// UVM TESTBENCH PACKAGE
// ============================================================================

package gpu_pkg;
    import uvm_pkg::*;
    import constants_pkg::*;
    
    typedef enum {CONFIG_OP, RUN_OP} control_op_type_e;
    typedef enum {REQ_TRANS, RSP_TRANS} mem_trans_type_e;
    
    // ========================================================================
    // TRANSACTION CLASSES
    // ========================================================================
    
    class gpu_control_transaction extends uvm_sequence_item;
        
        rand bit [1:0] op_code;
        rand bit [ADDR_WIDTH-1:0] cfg_data;
        rand int delay_cycles;
        
        constraint valid_opcode_c {
            op_code inside {SET_W_BASE, SET_X_BASE, RUN, RES};
        }
        
        constraint reasonable_delay_c {
            delay_cycles inside {[0:10]};
        }
        
        `uvm_object_utils_begin(gpu_control_transaction)
            `uvm_field_int(op_code, UVM_ALL_ON)
            `uvm_field_int(cfg_data, UVM_ALL_ON)
            `uvm_field_int(delay_cycles, UVM_ALL_ON)
        `uvm_object_utils_end
        
        function new(string name = "gpu_control_transaction");
            super.new(name);
        endfunction
        
        function string op_code_string();
            case(op_code)
                SET_W_BASE: return "SET_W_BASE";
                SET_X_BASE: return "SET_X_BASE";
                RUN: return "RUN";
                RES: return "RES";
                default: return "UNKNOWN";
            endcase
        endfunction
        
        virtual function string convert2string();
            return $sformatf("Control Transaction: op=%s, cfg_data=0x%0h, delay=%0d",
                            op_code_string(), cfg_data, delay_cycles);
        endfunction
        
    endclass
    
    class gpu_memory_transaction extends uvm_sequence_item;
        
        rand mem_trans_type_e trans_type;
        rand bit [ADDR_WIDTH-1:0] addr;
        rand bit [DATA_WIDTH-1:0] data;
        rand int req_ready_delay;
        rand int rsp_delay;
        
        constraint reasonable_delays_c {
            req_ready_delay inside {[0:5]};
            rsp_delay inside {[1:10]};
        }
        
        `uvm_object_utils_begin(gpu_memory_transaction)
            `uvm_field_enum(mem_trans_type_e, trans_type, UVM_ALL_ON)
            `uvm_field_int(addr, UVM_ALL_ON | UVM_HEX)
            `uvm_field_int(data, UVM_ALL_ON | UVM_HEX)
            `uvm_field_int(req_ready_delay, UVM_ALL_ON)
            `uvm_field_int(rsp_delay, UVM_ALL_ON)
        `uvm_object_utils_end
        
        function new(string name = "gpu_memory_transaction");
            super.new(name);
        endfunction
        
    endclass
    
    class gpu_result_transaction extends uvm_sequence_item;
        
        bit [ACC_WIDTH-1:0] data;
        rand int ready_delay;
        time timestamp;
        
        constraint reasonable_delay_c {
            ready_delay inside {[0:10]};
        }
        
        `uvm_object_utils_begin(gpu_result_transaction)
            `uvm_field_int(data, UVM_ALL_ON | UVM_DEC)
            `uvm_field_int(ready_delay, UVM_ALL_ON)
        `uvm_object_utils_end
        
        function new(string name = "gpu_result_transaction");
            super.new(name);
        endfunction
        
        virtual function string convert2string();
            return $sformatf("Result: data=%0d (0x%0h), ready_delay=%0d", 
                            data, data, ready_delay);
        endfunction
        
    endclass
    
    // ========================================================================
    // CONFIGURATION OBJECT
    // ========================================================================
    
    class gpu_config extends uvm_object;
        
        rand bit control_agent_is_active;
        rand bit memory_agent_is_active;
        rand bit result_agent_is_active;
        
        rand int memory_latency_min;
        rand int memory_latency_max;
        rand bit enable_mem_backpressure;
        rand int mem_backpressure_prob;
        
        rand bit enable_result_backpressure;
        rand int result_backpressure_prob;
        
        bit enable_coverage;
        bit enable_scoreboard;
        
        constraint default_active_c {
            control_agent_is_active == 1;
            memory_agent_is_active == 1;
            result_agent_is_active == 1;
        }
        
        constraint reasonable_latency_c {
            memory_latency_min inside {[1:5]};
            memory_latency_max inside {[memory_latency_min:20]};
        }
        
        constraint reasonable_backpressure_c {
            mem_backpressure_prob inside {[0:50]};
            result_backpressure_prob inside {[0:50]};
        }
        
        `uvm_object_utils_begin(gpu_config)
            `uvm_field_int(control_agent_is_active, UVM_ALL_ON)
            `uvm_field_int(memory_agent_is_active, UVM_ALL_ON)
            `uvm_field_int(result_agent_is_active, UVM_ALL_ON)
            `uvm_field_int(memory_latency_min, UVM_ALL_ON)
            `uvm_field_int(memory_latency_max, UVM_ALL_ON)
            `uvm_field_int(enable_mem_backpressure, UVM_ALL_ON)
            `uvm_field_int(mem_backpressure_prob, UVM_ALL_ON)
            `uvm_field_int(enable_result_backpressure, UVM_ALL_ON)
            `uvm_field_int(result_backpressure_prob, UVM_ALL_ON)
            `uvm_field_int(enable_coverage, UVM_ALL_ON)
            `uvm_field_int(enable_scoreboard, UVM_ALL_ON)
        `uvm_object_utils_end
        
        function new(string name = "gpu_config");
            super.new(name);
            enable_coverage = 1;
            enable_scoreboard = 1;
        endfunction
        
    endclass
    
    // ========================================================================
    // SEQUENCERS
    // ========================================================================
    
    class gpu_control_sequencer extends uvm_sequencer #(gpu_control_transaction);
        `uvm_component_utils(gpu_control_sequencer)
        function new(string name = "gpu_control_sequencer", uvm_component parent = null);
            super.new(name, parent);
        endfunction
    endclass
    
    class gpu_memory_sequencer extends uvm_sequencer #(gpu_memory_transaction);
        `uvm_component_utils(gpu_memory_sequencer)
        function new(string name = "gpu_memory_sequencer", uvm_component parent = null);
            super.new(name, parent);
        endfunction
    endclass
    
    class gpu_result_sequencer extends uvm_sequencer #(gpu_result_transaction);
        `uvm_component_utils(gpu_result_sequencer)
        function new(string name = "gpu_result_sequencer", uvm_component parent = null);
            super.new(name, parent);
        endfunction
    endclass
    
    // ========================================================================
    // DRIVERS
    // ========================================================================
    
    class gpu_control_driver extends uvm_driver #(gpu_control_transaction);
        
        `uvm_component_utils(gpu_control_driver)
        
        virtual gpu_control_if vif;
        
        function new(string name = "gpu_control_driver", uvm_component parent = null);
            super.new(name, parent);
        endfunction
        
        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual gpu_control_if)::get(this, "", "control_vif", vif))
                `uvm_fatal(get_type_name(), "Virtual interface not found in config DB")
        endfunction
        
        virtual task run_phase(uvm_phase phase);
            gpu_control_transaction trans;
            
            vif.driver_cb.start <= 0;
            vif.driver_cb.op_code <= 0;
            vif.driver_cb.cfg_data <= 0;
            
            forever begin
                seq_item_port.get_next_item(trans);
                drive_transaction(trans);
                seq_item_port.item_done();
            end
        endtask
        
        virtual task drive_transaction(gpu_control_transaction trans);
            `uvm_info(get_type_name(), $sformatf("Driving: %s", trans.convert2string()), UVM_MEDIUM)
            
            repeat(trans.delay_cycles) @(vif.driver_cb);
            
            vif.driver_cb.start <= 1;
            vif.driver_cb.op_code <= trans.op_code;
            vif.driver_cb.cfg_data <= trans.cfg_data;
            @(vif.driver_cb);
            
            vif.driver_cb.start <= 0;
            @(vif.driver_cb);
        endtask
        
    endclass
    
    class gpu_memory_driver extends uvm_driver #(gpu_memory_transaction);
        
        `uvm_component_utils(gpu_memory_driver)
        
        virtual gpu_memory_if vif;
        gpu_config cfg;
        
        bit [DATA_WIDTH-1:0] memory [bit [ADDR_WIDTH-1:0]];
        gpu_memory_transaction req_queue[$];
        
        function new(string name = "gpu_memory_driver", uvm_component parent = null);
            super.new(name, parent);
        endfunction
        
        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual gpu_memory_if)::get(this, "", "memory_vif", vif))
                `uvm_fatal(get_type_name(), "Virtual interface not found in config DB")
            if (!uvm_config_db#(gpu_config)::get(this, "", "config", cfg))
                `uvm_warning(get_type_name(), "Config not found, using defaults")
        endfunction
        
        function void load_memory(bit [ADDR_WIDTH-1:0] base_addr, bit [DATA_WIDTH-1:0] data[], string name);
            `uvm_info(get_type_name(), $sformatf("Loading %s at base 0x%0h with %0d elements", 
                      name, base_addr, data.size()), UVM_LOW)
            foreach(data[i]) begin
                memory[base_addr + i] = data[i];
                `uvm_info(get_type_name(), $sformatf("  memory[0x%0h] = 0x%0h", 
                          base_addr + i, data[i]), UVM_HIGH)
            end
        endfunction
        
        virtual task run_phase(uvm_phase phase);
            vif.driver_cb.m_req_rdy <= 0;
            vif.driver_cb.m_rsp_vld <= 0;
            vif.driver_cb.m_rsp_data <= 0;
            
            fork
                handle_requests();
                handle_responses();
            join
        endtask
        
        virtual task handle_requests();
            forever begin
                @(vif.driver_cb);
                
                if (cfg != null && cfg.enable_mem_backpressure) begin
                    vif.driver_cb.m_req_rdy <= ($urandom_range(100) > cfg.mem_backpressure_prob);
                end else begin
                    vif.driver_cb.m_req_rdy <= 1;
                end
                
                if (vif.m_req_vld && vif.m_req_rdy) begin
                    gpu_memory_transaction trans = gpu_memory_transaction::type_id::create("mem_req");
                    trans.trans_type = REQ_TRANS;
                    trans.addr = vif.m_req_addr;
                    
                    if (cfg != null) begin
                        trans.rsp_delay = $urandom_range(cfg.memory_latency_min, cfg.memory_latency_max);
                    end else begin
                        trans.rsp_delay = 1;
                    end
                    
                    if (memory.exists(trans.addr)) begin
                        trans.data = memory[trans.addr];
                    end else begin
                        trans.data = $urandom;
                        `uvm_warning(get_type_name(), 
                                   $sformatf("Read from uninitialized address 0x%0h, returning random data 0x%0h",
                                           trans.addr, trans.data))
                    end
                    
                    req_queue.push_back(trans);
                    `uvm_info(get_type_name(), $sformatf("Captured request: addr=0x%0h, data=0x%0h, delay=%0d",
                              trans.addr, trans.data, trans.rsp_delay), UVM_HIGH)
                end
            end
        endtask
        
        virtual task handle_responses();
            forever begin
                gpu_memory_transaction trans;
                
                wait(req_queue.size() > 0);
                trans = req_queue.pop_front();
                
                repeat(trans.rsp_delay) @(vif.driver_cb);
                
                vif.driver_cb.m_rsp_vld <= 1;
                vif.driver_cb.m_rsp_data <= trans.data;
                
                `uvm_info(get_type_name(), $sformatf("Driving response: addr=0x%0h, data=0x%0h",
                          trans.addr, trans.data), UVM_HIGH)
                
                @(vif.driver_cb);
                while (!vif.m_rsp_rdy) begin
                    @(vif.driver_cb);
                end
                
                vif.driver_cb.m_rsp_vld <= 0;
            end
        endtask
        
    endclass
    
    class gpu_result_driver extends uvm_driver #(gpu_result_transaction);
        
        `uvm_component_utils(gpu_result_driver)
        
        virtual gpu_result_if vif;
        gpu_config cfg;
        
        function new(string name = "gpu_result_driver", uvm_component parent = null);
            super.new(name, parent);
        endfunction
        
        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual gpu_result_if)::get(this, "", "result_vif", vif))
                `uvm_fatal(get_type_name(), "Virtual interface not found in config DB")
            if (!uvm_config_db#(gpu_config)::get(this, "", "config", cfg))
                `uvm_warning(get_type_name(), "Config not found, using defaults")
        endfunction
        
        virtual task run_phase(uvm_phase phase);
            vif.driver_cb.result_rdy <= 1;
            
            if (cfg != null && cfg.enable_result_backpressure) begin
                apply_backpressure();
            end else begin
                forever @(vif.driver_cb);
            end
        endtask
        
        virtual task apply_backpressure();
            forever begin
                @(vif.driver_cb);
                vif.driver_cb.result_rdy <= ($urandom_range(100) > cfg.result_backpressure_prob);
            end
        endtask
        
    endclass
    
    // ========================================================================
    // MONITORS
    // ========================================================================
    
    class gpu_control_monitor extends uvm_monitor;
        
        `uvm_component_utils(gpu_control_monitor)
        
        virtual gpu_control_if vif;
        uvm_analysis_port #(gpu_control_transaction) ap;
        
        function new(string name = "gpu_control_monitor", uvm_component parent = null);
            super.new(name, parent);
            ap = new("ap", this);
        endfunction
        
        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual gpu_control_if)::get(this, "", "control_vif", vif))
                `uvm_fatal(get_type_name(), "Virtual interface not found in config DB")
        endfunction
        
        virtual task run_phase(uvm_phase phase);
            forever begin
                gpu_control_transaction trans;
                @(vif.monitor_cb);
                
                if (vif.monitor_cb.start) begin
                    trans = gpu_control_transaction::type_id::create("control_trans");
                    trans.op_code = vif.monitor_cb.op_code;
                    trans.cfg_data = vif.monitor_cb.cfg_data;
                    
                    `uvm_info(get_type_name(), $sformatf("Monitored: %s", trans.convert2string()), UVM_MEDIUM)
                    ap.write(trans);
                end
            end
        endtask
        
    endclass
    
    class gpu_memory_monitor extends uvm_monitor;
        
        `uvm_component_utils(gpu_memory_monitor)
        
        virtual gpu_memory_if vif;
        
        uvm_analysis_port #(gpu_memory_transaction) req_ap;
        uvm_analysis_port #(gpu_memory_transaction) rsp_ap;
        
        function new(string name = "gpu_memory_monitor", uvm_component parent = null);
            super.new(name, parent);
            req_ap = new("req_ap", this);
            rsp_ap = new("rsp_ap", this);
        endfunction
        
        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual gpu_memory_if)::get(this, "", "memory_vif", vif))
                `uvm_fatal(get_type_name(), "Virtual interface not found in config DB")
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
                @(vif.monitor_cb);
                
                if (vif.monitor_cb.m_req_vld && vif.monitor_cb.m_req_rdy) begin
                    trans = gpu_memory_transaction::type_id::create("mem_req_mon");
                    trans.trans_type = REQ_TRANS;
                    trans.addr = vif.monitor_cb.m_req_addr;
                    
                    `uvm_info(get_type_name(), $sformatf("Monitored REQ: addr=0x%0h", trans.addr), UVM_HIGH)
                    req_ap.write(trans);
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
    
    class gpu_result_monitor extends uvm_monitor;
        
        `uvm_component_utils(gpu_result_monitor)
        
        virtual gpu_result_if vif;
        uvm_analysis_port #(gpu_result_transaction) ap;
        
        function new(string name = "gpu_result_monitor", uvm_component parent = null);
            super.new(name, parent);
            ap = new("ap", this);
        endfunction
        
        virtual function void build_phase(uvm_phase phase);
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
    
    // ========================================================================
    // SCOREBOARD
    // ========================================================================
    
    // Define analysis imp macros
    `uvm_analysis_imp_decl(_control)
    `uvm_analysis_imp_decl(_mem_req)
    `uvm_analysis_imp_decl(_mem_rsp)
    `uvm_analysis_imp_decl(_result)
    
    class gpu_scoreboard extends uvm_scoreboard;
        
        `uvm_component_utils(gpu_scoreboard)
        
        uvm_analysis_imp_control #(gpu_control_transaction, gpu_scoreboard) control_export;
        uvm_analysis_imp_mem_req #(gpu_memory_transaction, gpu_scoreboard) mem_req_export;
        uvm_analysis_imp_mem_rsp #(gpu_memory_transaction, gpu_scoreboard) mem_rsp_export;
        uvm_analysis_imp_result #(gpu_result_transaction, gpu_scoreboard) result_export;
        
        bit [ADDR_WIDTH-1:0] w_base_addr;
        bit [ADDR_WIDTH-1:0] x_base_addr;
        bit run_issued;
        
        bit [DATA_WIDTH-1:0] w_matrix[W_DEPTH];
        bit [DATA_WIDTH-1:0] x_vector[X_DEPTH];
        bit [ACC_WIDTH-1:0] expected_results[MAT_DIM];
        
        bit [ACC_WIDTH-1:0] actual_results[$];
        int result_count;
        
        int transactions_checked;
        int transactions_passed;
        int transactions_failed;
        
        int w_collect_idx = 0;
        int x_collect_idx = 0;
        
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
        
        virtual function void write_mem_req(gpu_memory_transaction trans);
            `uvm_info(get_type_name(), $sformatf("Memory request: addr=0x%0h", trans.addr), UVM_HIGH)
        endfunction
        
        virtual function void write_mem_rsp(gpu_memory_transaction trans);
            `uvm_info(get_type_name(), $sformatf("Memory response: data=0x%0h", trans.data), UVM_HIGH)
            
            if (run_issued) begin
                if (w_collect_idx < W_DEPTH) begin
                    w_matrix[w_collect_idx] = trans.data;
                    `uvm_info(get_type_name(), $sformatf("Collected W[%0d] = 0x%0h", w_collect_idx, trans.data), UVM_MEDIUM)
                    w_collect_idx++;
                    
                    if (w_collect_idx == W_DEPTH && x_collect_idx == X_DEPTH) begin
                        compute_expected_results();
                        w_collect_idx = 0;
                        x_collect_idx = 0;
                    end
                end
                else if (x_collect_idx < X_DEPTH) begin
                    x_vector[x_collect_idx] = trans.data;
                    `uvm_info(get_type_name(), $sformatf("Collected X[%0d] = 0x%0h", x_collect_idx, trans.data), UVM_MEDIUM)
                    x_collect_idx++;
                    
                    if (w_collect_idx == W_DEPTH && x_collect_idx == X_DEPTH) begin
                        compute_expected_results();
                        w_collect_idx = 0;
                        x_collect_idx = 0;
                    end
                end
            end
        endfunction
        
        virtual function void compute_expected_results();
            `uvm_info(get_type_name(), "Computing expected results", UVM_LOW)
            
            for (int row = 0; row < MAT_DIM; row++) begin
                bit [ACC_WIDTH-1:0] sum = 0;
                
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
    
    // ========================================================================
    // AGENTS
    // ========================================================================
    
    class gpu_control_agent extends uvm_agent;
        
        `uvm_component_utils(gpu_control_agent)
        
        gpu_control_driver driver;
        gpu_control_monitor monitor;
        gpu_control_sequencer sequencer;
        
        gpu_config cfg;
        
        function new(string name = "gpu_control_agent", uvm_component parent = null);
            super.new(name, parent);
        endfunction
        
        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            
            if (!uvm_config_db#(gpu_config)::get(this, "", "config", cfg))
                `uvm_warning(get_type_name(), "Config not found, using defaults")
            
            monitor = gpu_control_monitor::type_id::create("monitor", this);
            
            if (cfg == null || cfg.control_agent_is_active == UVM_ACTIVE) begin
                driver = gpu_control_driver::type_id::create("driver", this);
                sequencer = gpu_control_sequencer::type_id::create("sequencer", this);
            end
        endfunction
        
        virtual function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            if (cfg == null || cfg.control_agent_is_active == UVM_ACTIVE) begin
                driver.seq_item_port.connect(sequencer.seq_item_export);
            end
        endfunction
        
    endclass
    
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
    
    class gpu_result_agent extends uvm_agent;
        
        `uvm_component_utils(gpu_result_agent)
        
        gpu_result_driver driver;
        gpu_result_monitor monitor;
        gpu_result_sequencer sequencer;
        
        gpu_config cfg;
        
        function new(string name = "gpu_result_agent", uvm_component parent = null);
            super.new(name, parent);
        endfunction
        
        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            
            if (!uvm_config_db#(gpu_config)::get(this, "", "config", cfg))
                `uvm_warning(get_type_name(), "Config not found, using defaults")
            
            monitor = gpu_result_monitor::type_id::create("monitor", this);
            
            if (cfg == null || cfg.result_agent_is_active == UVM_ACTIVE) begin
                driver = gpu_result_driver::type_id::create("driver", this);
                sequencer = gpu_result_sequencer::type_id::create("sequencer", this);
            end
        endfunction
        
        virtual function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            if (cfg == null || cfg.result_agent_is_active == UVM_ACTIVE) begin
                driver.seq_item_port.connect(sequencer.seq_item_export);
            end
        endfunction
        
    endclass
    
    // ========================================================================
    // ENVIRONMENT
    // ========================================================================
    
    class gpu_env extends uvm_env;
        
        `uvm_component_utils(gpu_env)
        
        gpu_control_agent control_agent;
        gpu_memory_agent memory_agent;
        gpu_result_agent result_agent;
        
        gpu_scoreboard scoreboard;
        
        gpu_config cfg;
        
        function new(string name = "gpu_env", uvm_component parent = null);
            super.new(name, parent);
        endfunction
        
        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            
            if (!uvm_config_db#(gpu_config)::get(this, "", "config", cfg)) begin
                `uvm_info(get_type_name(), "Using default config", UVM_MEDIUM)
                cfg = gpu_config::type_id::create("cfg");
                if (!cfg.randomize())
                    `uvm_warning(get_type_name(), "Config randomization failed")
            end
            
            uvm_config_db#(gpu_config)::set(this, "*", "config", cfg);
            
            control_agent = gpu_control_agent::type_id::create("control_agent", this);
            memory_agent = gpu_memory_agent::type_id::create("memory_agent", this);
            result_agent = gpu_result_agent::type_id::create("result_agent", this);
            
            if (cfg.enable_scoreboard) begin
                scoreboard = gpu_scoreboard::type_id::create("scoreboard", this);
            end
        endfunction
        
        virtual function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            
            if (cfg.enable_scoreboard) begin
                control_agent.monitor.ap.connect(scoreboard.control_export);
                memory_agent.monitor.req_ap.connect(scoreboard.mem_req_export);
                memory_agent.monitor.rsp_ap.connect(scoreboard.mem_rsp_export);
                result_agent.monitor.ap.connect(scoreboard.result_export);
            end
        endfunction
        
    endclass
    
    // ========================================================================
    // SEQUENCES
    // ========================================================================
    
    class gpu_control_base_seq extends uvm_sequence #(gpu_control_transaction);
        `uvm_object_utils(gpu_control_base_seq)
        function new(string name = "gpu_control_base_seq");
            super.new(name);
        endfunction
    endclass
    
    class set_w_base_seq extends gpu_control_base_seq;
        `uvm_object_utils(set_w_base_seq)
        rand bit [ADDR_WIDTH-1:0] w_base;
        
        function new(string name = "set_w_base_seq");
            super.new(name);
        endfunction
        
        virtual task body();
            gpu_control_transaction trans;
            trans = gpu_control_transaction::type_id::create("trans");
            start_item(trans);
            assert(trans.randomize() with {
                op_code == SET_W_BASE;
                cfg_data == w_base;
            });
            finish_item(trans);
        endtask
    endclass
    
    class set_x_base_seq extends gpu_control_base_seq;
        `uvm_object_utils(set_x_base_seq)
        rand bit [ADDR_WIDTH-1:0] x_base;
        
        function new(string name = "set_x_base_seq");
            super.new(name);
        endfunction
        
        virtual task body();
            gpu_control_transaction trans;
            trans = gpu_control_transaction::type_id::create("trans");
            start_item(trans);
            assert(trans.randomize() with {
                op_code == SET_X_BASE;
                cfg_data == x_base;
            });
            finish_item(trans);
        endtask
    endclass
    
    class run_seq extends gpu_control_base_seq;
        `uvm_object_utils(run_seq)
        
        function new(string name = "run_seq");
            super.new(name);
        endfunction
        
        virtual task body();
            gpu_control_transaction trans;
            trans = gpu_control_transaction::type_id::create("trans");
            start_item(trans);
            assert(trans.randomize() with {
                op_code == RUN;
            });
            finish_item(trans);
        endtask
    endclass
    
    class config_and_run_seq extends gpu_control_base_seq;
        `uvm_object_utils(config_and_run_seq)
        rand bit [ADDR_WIDTH-1:0] w_base;
        rand bit [ADDR_WIDTH-1:0] x_base;
        
        set_w_base_seq set_w;
        set_x_base_seq set_x;
        run_seq run;
        
        function new(string name = "config_and_run_seq");
            super.new(name);
        endfunction
        
        virtual task body();
            set_w = set_w_base_seq::type_id::create("set_w");
            set_w.w_base = w_base;
            set_w.start(m_sequencer);
            
            set_x = set_x_base_seq::type_id::create("set_x");
            set_x.x_base = x_base;
            set_x.start(m_sequencer);
            
            run = run_seq::type_id::create("run");
            run.start(m_sequencer);
        endtask
    endclass
    
    // ========================================================================
    // TESTS
    // ========================================================================
    
    class gpu_base_test extends uvm_test;
        
        `uvm_component_utils(gpu_base_test)
        
        gpu_env env;
        gpu_config cfg;
        
        function new(string name = "gpu_base_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction
        
        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            
            cfg = gpu_config::type_id::create("cfg");
            if (!cfg.randomize()) begin
                `uvm_fatal(get_type_name(), "Config randomization failed")
            end
            
            cfg.enable_coverage = 0;  // Disable for EDA Playground
            cfg.enable_scoreboard = 1;
            cfg.memory_latency_min = 1;
            cfg.memory_latency_max = 5;
            cfg.enable_mem_backpressure = 0;
            cfg.enable_result_backpressure = 0;
            
            uvm_config_db#(gpu_config)::set(this, "*", "config", cfg);
            
            env = gpu_env::type_id::create("env", this);
        endfunction
        
        virtual function void end_of_elaboration_phase(uvm_phase phase);
            super.end_of_elaboration_phase(phase);
            // Commented out for EDA Playground compatibility
            // uvm_top.print_topology();
        endfunction
        
        function void load_test_data(bit [DATA_WIDTH-1:0] w_data[], bit [DATA_WIDTH-1:0] x_data[],
                                     bit [ADDR_WIDTH-1:0] w_base, bit [ADDR_WIDTH-1:0] x_base);
            if (env.memory_agent.driver != null) begin
                env.memory_agent.driver.load_memory(w_base, w_data, "W matrix");
                env.memory_agent.driver.load_memory(x_base, x_data, "X vector");
            end else begin
                `uvm_error(get_type_name(), "Memory driver not found")
            end
        endfunction
        
    endclass
    
    class gpu_sanity_test extends gpu_base_test;
        
        `uvm_component_utils(gpu_sanity_test)
        
        function new(string name = "gpu_sanity_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction
        
        virtual task run_phase(uvm_phase phase);
            config_and_run_seq seq;
            bit [DATA_WIDTH-1:0] w_data[W_DEPTH];
            bit [DATA_WIDTH-1:0] x_data[X_DEPTH];
            
            phase.raise_objection(this);
            
            `uvm_info(get_type_name(), "========================================", UVM_NONE)
            `uvm_info(get_type_name(), "      STARTING SANITY TEST", UVM_NONE)
            `uvm_info(get_type_name(), "========================================", UVM_NONE)
            
            // Identity matrix
            w_data[0] = 1; w_data[1] = 0; w_data[2] = 0; w_data[3] = 0;
            w_data[4] = 0; w_data[5] = 1; w_data[6] = 0; w_data[7] = 0;
            w_data[8] = 0; w_data[9] = 0; w_data[10] = 1; w_data[11] = 0;
            w_data[12] = 0; w_data[13] = 0; w_data[14] = 0; w_data[15] = 1;
            
            x_data[0] = 5;
            x_data[1] = 10;
            x_data[2] = 15;
            x_data[3] = 20;
            
            load_test_data(w_data, x_data, 8'h00, 8'h10);
            
            seq = config_and_run_seq::type_id::create("seq");
            seq.w_base = 8'h00;
            seq.x_base = 8'h10;
            seq.start(env.control_agent.sequencer);
            
            #5000;
            
            `uvm_info(get_type_name(), "========================================", UVM_NONE)
            `uvm_info(get_type_name(), "      SANITY TEST COMPLETE", UVM_NONE)
            `uvm_info(get_type_name(), "========================================", UVM_NONE)
            
            phase.drop_objection(this);
        endtask
        
    endclass
    
endpackage

// ============================================================================
// TESTBENCH TOP MODULE
// ============================================================================

module tb_top;
    
    import uvm_pkg::*;
    import gpu_pkg::*;
    
    logic clk;
    logic rst_n;
    
    gpu_control_if control_if(clk, rst_n);
    gpu_memory_if memory_if(clk, rst_n);
    gpu_result_if result_if(clk, rst_n);
    
    // DUT instantiation
    gpu_top dut(
        .clk(clk),
        .rst_n(rst_n),
        .start(control_if.start),
        .op_code(control_if.op_code),
        .cfg_data(control_if.cfg_data),
        .m_req_vld(memory_if.m_req_vld),
        .m_req_rdy(memory_if.m_req_rdy),
        .m_req_addr(memory_if.m_req_addr),
        .m_rsp_vld(memory_if.m_rsp_vld),
        .m_rsp_rdy(memory_if.m_rsp_rdy),
        .m_rsp_data(memory_if.m_rsp_data),
        .result_vld(result_if.result_vld),
        .result_rdy(result_if.result_rdy),
        .result_data(result_if.result_data),
        .busy(control_if.busy)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        rst_n = 0;
        repeat(5) @(posedge clk);
        rst_n = 1;
    end
    
    initial begin
        uvm_config_db#(virtual gpu_control_if)::set(null, "uvm_test_top.env.control_agent*", "control_vif", control_if);
        uvm_config_db#(virtual gpu_memory_if)::set(null, "uvm_test_top.env.memory_agent*", "memory_vif", memory_if);
        uvm_config_db#(virtual gpu_result_if)::set(null, "uvm_test_top.env.result_agent*", "result_vif", result_if);
        
        // Run test with default name if +UVM_TESTNAME not specified
        run_test("gpu_sanity_test");
    end
    
    initial begin
        #100000;
        $display("ERROR: Simulation timeout!");
        $finish;
    end
    
endmodule