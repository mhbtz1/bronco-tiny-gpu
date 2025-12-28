class axis_beat extends uvm_sequence_item;
    bit [31:0] data;
    `uvm_object_utils_begin(axis_beat)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_object_utils_end

    function new (string name="axis_beat"); 
        super.new(name); 
    endfunction
endclass

class stream_monitor extends uvm_component;
    `uvm_component_utils(stream_monitor)
    virtual smol_axis_if vif;
    uvm_analysis_port #(axis_beat) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual smol_axis_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "stream_monitor: no vif")
    endfunction

    task run_phase(uvm_phase phase);
        axis_beat beat;
        
        // Wait for reset deassertion
        do @(posedge vif.clk); while (!vif.rst_n);
        
        forever begin
            @(posedge vif.clk);
            if (vif.vld && vif.rdy) begin
                beat = axis_beat::type_id::create("beat");
                beat.data = vif.data;
                `uvm_info("MONITOR", $sformatf("Captured: data=0x%08h", beat.data), UVM_HIGH)
                ap.write(beat);
            end
        end
    endtask
endclass
