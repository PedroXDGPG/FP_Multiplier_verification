class Item extends uvm_sequence_item;
  `uvm_object_utils(Item)
  rand bit [2:0]  r_mode;
  rand bit [31:0] fp_X;
  rand bit [31:0] fp_Y;
  bit      [31:0] fp_Z;
  bit             ovrf;
  bit             udrf;

  virtual function string convert2str();
    return $sformatf("r_mode=%0d fp_X=%0d fp_Y=%0d fp_Z=%0d ovrf=%0d udrf=%0d", r_mode, fp_X, fp_Y, fp_Z, ovrf, udrf);
  endfunction

  function new(string name = "Item");
    super.new(name);
  endfunction

  constraint c_r_mode { r_mode inside {3'b000, 3'b001, 3'b010, 3'b011, 3'b100}; }

endclass