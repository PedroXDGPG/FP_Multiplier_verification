class base_test extends uvm_test;
  `uvm_component_utils(base_test)
  
  function new(string name = "base_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction
  
  env e0;
  gen_item_seq  seq;
  virtual des_if  vif;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    e0 = env::type_id::create("e0",this);

    if(!uvm_config_db#(virtual des_if)::get(this, "", "des_vif",vif))
      `uvm_fatal("TEST","Did not get vif")
    uvm_config_db#(virtual des_if)::set(this, "e0.a0.*","des_vif",vif);
    

    seq = gen_item_seq::type_id::create("seq");
    seq.randomize();
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    seq.start(e0.a0.s0);
    #200;
    phase.drop_objection(this);
  endtask

endclass

class test_FP_Multiplier extends base_test;
  `uvm_component_utils(test_FP_Multiplier)
  
  function new(string name="test_FP_Multiplier",uvm_component parent=null);
    super.new(name,parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    seq.randomize() with {num inside {[300:500]};};
  endfunction
endclass
