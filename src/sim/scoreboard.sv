class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard)
  
  function new(string name="scoreboard",uvm_component parent=null);
    super.new(name, parent);
  endfunction


  uvm_analysis_imp #(Item, scoreboard) m_analysis_imp;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_analysis_imp = new("m_analysis_imp",this);
  endfunction

  virtual function write(Item item);

    `uvm_info("SCBD", $sformatf("in1=%0d in2=%0d out=%0d", item.in1, item.in2, item.out), UVM_LOW)
    
    if(item.in1 + item.in2 == item.out) begin
      `uvm_info("SCBD",$sformatf("PASS ! out=%0d in1=%0d in2=%0d",item.out, item.in1, item.in2), UVM_HIGH)   
    end else begin
      `uvm_error("SCBD",$sformatf("ERROR ! out=%0d in1=%0d in2=%0d",item.out, item.in1, item.in2))
    end
  endfunction

endclass
    
