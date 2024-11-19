class gen_item_seq extends uvm_sequence;
  `uvm_object_utils(gen_item_seq);
  
  function new(string name="gen_item_seq");
    super.new(name);
  endfunction


  rand int num;
 // rand bit [2:0] r_mode_rnd;

  constraint c1{soft num inside {[10:50]};}

  constraint c_r_mode_000 { r_mode == 3'b000; }
  constraint c_r_mode_001 { r_mode == 3'b001; }
  constraint c_r_mode_010 { r_mode == 3'b010; }
  constraint c_r_mode_011 { r_mode == 3'b011; }
  constraint c_r_mode_100 { r_mode == 3'b100; }

  constraint c_r_mode { r_mode inside {3'b000, 3'b001, 3'b010, 3'b011, 3'b100}; }

  virtual task body();
    for(int i = 0; i<num;i++)begin
      Item m_item = Item::type_id::create("m_item");
      start_item(m_item);
      m_item.randomize();
      //m_item.r_mode = r_mode_rnd;
      `uvm_info("SEQ",$sformatf("Generate new item: %s", m_item.convert2str()),UVM_HIGH);
      finish_item(m_item);
    end
    `uvm_info("SEQ",$sformatf("Done generation of %0d items", num),UVM_LOW);
  endtask

endclass
