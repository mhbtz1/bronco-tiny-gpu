class ready_driver extends uvm_component;
  `uvm_component_utils(ready_driver)

  virtual smol_axis_if vif;
  rand int unsigned ready_pct = 70;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    if (!uvm_config_db#(virtual smol_axis_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "ready_driver: no vif")
  endfunction

  task run_phase(uvm_phase phase);
    vif.rdy <= 0;
    // wait reset deassert
    do @(posedge vif.clk); while (!vif.rst_n);

    forever begin
      @(posedge vif.clk);
      vif.rdy <= ($urandom_range(0,99) < ready_pct);
    end
  endtask
endclass