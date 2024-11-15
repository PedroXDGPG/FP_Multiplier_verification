//`timescale 1ns / 1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "32b_FP_Multiplier.sv"
`include "interface.sv"
`include "sequence_item.sv"
`include "sequence.sv"
`include "monitor.sv"
`include "driver.sv"
`include "scoreboard.sv"
`include "agent.sv"
`include "environment.sv"
`include "test.sv"

module tb;

  reg clk;

  always #10 clk =~ clk;
  des_if _if(clk);
  // conexion de la interface con el DUT
  FP_Multiplier u0 (   .clk(_if.clk),
               .in1(_if.r_mode),
               .in2(_if.fp_X),
               .in2(_if.fp_Y),
               .out(_if.fp_Z)),
               .out(_if.ovrf)),
               .out(_if.udrf));
  initial begin
    clk <= 0;
    uvm_config_db#(virtual des_if)::set(null,"uvm_test_top","des_vif",_if);
//    uvm_config_db#(virtual des_if)::set(null, "uvm_test_top.e0.a0.d0","des_vif",_if);
    run_test("test_FP_Multiplier");
  end
endmodule
