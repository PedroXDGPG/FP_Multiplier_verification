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
    seq.randomize() with {num inside {10000};};
  endfunction
endclass

class test_FP_Multiplier_rmode_000 extends base_test;
  `uvm_component_utils(test_FP_Multiplier_rmode_000)
  
  function new(string name="test_FP_Multiplier_rmode_000", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TEST_NAME", "Running test_FP_Multiplier_rmode_000", UVM_LOW)
    seq.randomize() with {r_mode_rnd  == 3'b000; num inside {5000};};
  endfunction
endclass

class test_FP_Multiplier_rmode_001 extends base_test;
  `uvm_component_utils(test_FP_Multiplier_rmode_001)
  
  function new(string name="test_FP_Multiplier_rmode_001", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TEST_NAME", "Running test_FP_Multiplier_rmode_001", UVM_LOW)
    seq.randomize() with {r_mode_rnd  == 3'b001; num inside {5000};};
  endfunction
endclass

class test_FP_Multiplier_rmode_010 extends base_test;
  `uvm_component_utils(test_FP_Multiplier_rmode_010)
  
  function new(string name="test_FP_Multiplier_rmode_010", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TEST_NAME", "Running test_FP_Multiplier_rmode_010", UVM_LOW)
    seq.randomize() with {r_mode_rnd  == 3'b010; num inside {5000};};
  endfunction
endclass

class test_FP_Multiplier_rmode_011 extends base_test;
  `uvm_component_utils(test_FP_Multiplier_rmode_011)
  
  function new(string name="test_FP_Multiplier_rmode_011", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TEST_NAME", "Running test_FP_Multiplier_rmode_011", UVM_LOW)
    seq.randomize() with {r_mode_rnd  == 3'b011; num inside {5000};};
  endfunction
endclass

class test_FP_Multiplier_rmode_100 extends base_test;
  `uvm_component_utils(test_FP_Multiplier_rmode_100)
  
  function new(string name="test_FP_Multiplier_rmode_100", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("TEST_NAME", "Running test_FP_Multiplier_rmode_100", UVM_LOW)
    seq.randomize() with {r_mode_rnd  == 3'b100; num inside {5000};};
  endfunction
endclass