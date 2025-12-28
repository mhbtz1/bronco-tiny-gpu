class stream_scoreboard extends uvm_component;
    `uvm_component_utils(stream_scoreboard)
    
    uvm_analysis_imp #(axis_beat, stream_scoreboard) ap;
    
    int expected_data = 0;
    int received_count = 0;
    int error_count = 0;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
    endfunction
    
    function void write(axis_beat beat);
        received_count++;
        
        if (beat.data == expected_data) begin
            `uvm_info("SCOREBOARD", $sformatf("✓ PASS: Received 0x%08h (expected 0x%08h)", 
                      beat.data, expected_data), UVM_MEDIUM)
        end else begin
            `uvm_error("SCOREBOARD", $sformatf("✗ FAIL: Received 0x%08h (expected 0x%08h)", 
                       beat.data, expected_data))
            error_count++;
        end
        
        expected_data++;
    endfunction
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCOREBOARD", $sformatf("=== Final Report ==="), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Transactions: %0d", received_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Errors: %0d", error_count), UVM_LOW)
        
        if (error_count == 0 && received_count > 0) begin
            `uvm_info("SCOREBOARD", "*** TEST PASSED ***", UVM_LOW)
        end else if (received_count == 0) begin
            `uvm_error("SCOREBOARD", "*** TEST FAILED: No transactions received ***")
        end else begin
            `uvm_error("SCOREBOARD", "*** TEST FAILED: Data mismatches detected ***")
        end
    endfunction
    
endclass
