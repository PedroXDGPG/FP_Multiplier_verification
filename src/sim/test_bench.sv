//`timescale 1ns / 1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "../rtl/32b_FP_Multiplier.sv"
`include "interface.sv"
`include "sequence_item.sv"
`include "sequence.sv"
`include "monitor.sv"
`include "driver.sv"
`include "report_info.sv"
`include "scoreboard.sv"
`include "agent.sv"
`include "environment.sv"
`include "test.sv"

module tb;

  reg clk;

  always #10 clk =~ clk;
  des_if _if(clk);
  // conexion de la interface con el DUT
  top u0 (.clk(_if.clk),
                      .r_mode(_if.r_mode),  
                      .fp_X(_if.fp_X),
                      .fp_Y(_if.fp_Y),
                      .fp_Z(_if.fp_Z),
                      .ovrf(_if.ovrf),
                      .udrf(_if.udrf));
  initial begin
    clk <= 0;
    uvm_config_db#(virtual des_if)::set(null,"uvm_test_top","des_vif",_if);
//    uvm_config_db#(virtual des_if)::set(null, "uvm_test_top.e0.a0.d0","des_vif",_if);
    run_test("test_FP_Multiplier");
    // Run each test individually
    run_test("test_FP_Multiplier_rmode_000");
    run_test("test_FP_Multiplier_rmode_001");
    run_test("test_FP_Multiplier_rmode_010");
    run_test("test_FP_Multiplier_rmode_011");
    run_test("test_FP_Multiplier_rmode_100");
    run_test("test_zero_multi"); // Prueba con primer operando cero
  end
endmodule
