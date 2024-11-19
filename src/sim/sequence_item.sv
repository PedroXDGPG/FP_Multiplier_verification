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


endclass