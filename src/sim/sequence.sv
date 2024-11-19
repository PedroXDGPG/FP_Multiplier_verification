class gen_item_seq extends uvm_sequence;
  `uvm_object_utils(gen_item_seq);
  
  function new(string name="gen_item_seq");
    super.new(name);
  endfunction


  rand int num;
  rand bit [2:0] r_mode_rnd    ;
  bit            switch     = 0;
  bit            zero_X     = 0; // Indicador de cero en el primer operando
  constraint c1{soft num inside {[10:50]};}
  
  virtual task body();
    for(int i = 0; i<num;i++)begin
      Item m_item = Item::type_id::create("m_item");
      start_item(m_item);
      m_item.randomize();
      if(switch == 1)begin
        m_item.r_mode = $urandom_range(0,4);
      end
      else begin
        m_item.r_mode = r_mode_rnd;
      end

      if(zero_X == 1)begin
        m_item.fp_X = 32'd0;
      end
      else begin
        m_item.fp_X = $random;
      end
      `uvm_info("SEQ",$sformatf("Generate new item: %s", m_item.convert2str()),UVM_HIGH);
      finish_item(m_item);
    end
    `uvm_info("SEQ",$sformatf("Done generation of %0d items", num),UVM_LOW);
  endtask

endclass
