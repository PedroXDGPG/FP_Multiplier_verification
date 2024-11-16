class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard)
  
  function new(string name="scoreboard", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  uvm_analysis_imp #(Item, scoreboard) m_analysis_imp;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_analysis_imp = new("m_analysis_imp", this);
  endfunction

  virtual function write(Item item);
    bit [31:0] expected_fp_Z;
    bit expected_ovrf, expected_udrf;
    bit sign_X, sign_Y, sign_Z;
    bit [7:0] exp_X, exp_Y, exp_Z;
    bit [23:0] sig_X, sig_Y;
    bit [47:0] sig_Z;
    bit [47:0] product;
    int i;

    // Extract sign, exponent, and significand
    sign_X = item.fp_X[31];
    sign_Y = item.fp_Y[31];
    exp_X = item.fp_X[30:23];
    exp_Y = item.fp_Y[30:23];
    sig_X = {1'b1, item.fp_X[22:0]};
    sig_Y = {1'b1, item.fp_Y[22:0]};

    // Check for special cases
    if ((exp_X == 8'hFF && item.fp_X[22:0] != 0) || (exp_Y == 8'hFF && item.fp_Y[22:0] != 0)) begin
      // NaN case
      expected_fp_Z = {sign_X ^ sign_Y, 8'hFF, 23'h400000}; // NaN
    end else if ((exp_X == 8'hFF && item.fp_X[22:0] == 0) || (exp_Y == 8'hFF && item.fp_Y[22:0] == 0)) begin
      // Infinity case
      if ((exp_X == 8'hFF && item.fp_X[22:0] == 0 && item.fp_Y == 0) || (exp_Y == 8'hFF && item.fp_Y[22:0] == 0 && item.fp_X == 0)) begin
        // Zero * Infinity case
        expected_fp_Z = {sign_X ^ sign_Y, 8'hFF, 23'h400000}; // NaN
      end else begin
        expected_fp_Z = {sign_X ^ sign_Y, 8'hFF, 23'h000000}; // Infinity
      end
    end else if (item.fp_X == 0 || item.fp_Y == 0) begin
      // Zero case
      expected_fp_Z = {sign_X ^ sign_Y, 8'h00, 23'h000000}; // Zero
    end else begin
      // Perform the floating-point multiplication bit by bit
      product = 0;
      for (i = 0; i < 24; i++) begin
        if (sig_Y[i]) begin
          product = product + (sig_X << i);
        end
      end
      sig_Z = product;

      // Adjust exponent
      exp_Z = exp_X + exp_Y - 8'd127;
      sign_Z = sign_X ^ sign_Y;

      // Normalize the result
      if (sig_Z[47]) begin
        sig_Z = sig_Z >> 1;
        exp_Z = exp_Z + 1;
      end else begin
        while (sig_Z[46] == 0 && exp_Z > 0) begin
          sig_Z = sig_Z << 1;
          exp_Z = exp_Z - 1;
        end
      end

      // Apply rounding mode
      case (item.r_mode)
        3'b000: begin
          // Round to nearest, ties to even
          if (sig_Z[23:0] > 24'h800000 || (sig_Z[23:0] == 24'h800000 && sig_Z[24])) begin
            sig_Z = sig_Z + 1;
          end
        end
        3'b001: begin
          // Round to zero (truncate)
          // No additional action needed
        end
        3'b010: begin
          // Round down (towards -infinity)
          if (sign_Z && sig_Z[23:0] != 0) begin
            sig_Z = sig_Z + 1;
          end
        end
        3'b011: begin
          // Round up (towards +infinity)
          if (!sign_Z && sig_Z[23:0] != 0) begin
            sig_Z = sig_Z + 1;
          end
        end
        3'b100: begin
          // Round to nearest, ties to max magnitude
          if (sig_Z[23:0] > 24'h800000 || (sig_Z[23:0] == 24'h800000 && !sign_Z)) begin
            sig_Z = sig_Z + 1;
          end
        end
        default: begin
          // Default case if needed
        end
      endcase

      // Handle overflow and underflow
      if (exp_Z >= 8'hFF) begin
        expected_fp_Z = {sign_Z, 8'hFF, 23'h000000}; // Infinity
        expected_ovrf = 1;
        expected_udrf = 0;
      end else if (exp_Z <= 0) begin
        expected_fp_Z = {sign_Z, 8'h00, 23'h000000}; // Zero
        expected_ovrf = 0;
        expected_udrf = 1;
      end else begin
        expected_fp_Z = {sign_Z, exp_Z[7:0], sig_Z[46:24]};
        expected_ovrf = 0;
        expected_udrf = 0;
      end
    end

    `uvm_info("SCBD", $sformatf("r_mode=%0h fp_X=%0h fp_Y=%0h fp_Z=%0h ovrf=%0h udrf=%0h", item.r_mode, item.fp_X, item.fp_Y, item.fp_Z, item.ovrf, item.udrf), UVM_LOW)
    
    if (item.fp_Z == expected_fp_Z && item.ovrf == expected_ovrf && item.udrf == expected_udrf) begin
      `uvm_info("SCBD", $sformatf("PASS! fp_Z=%0h ovrf=%0h udrf=%0h", item.fp_Z, item.ovrf, item.udrf), UVM_HIGH)
    end else begin
      `uvm_error("SCBD", $sformatf("ERROR! fp_Z=%0h (expected %0h) ovrf=%0h (expected %0h) udrf=%0h (expected %0h)", item.fp_Z, expected_fp_Z, item.ovrf, expected_ovrf, item.udrf, expected_udrf))
    end
  endfunction

endclass