class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard) // Macro para registrar la clase como un componente UVM.

  // Constructor de la clase.
  function new(string name="scoreboard", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  // Puerto de análisis para recibir transacciones de otros componentes.
  uvm_analysis_imp #(Item, scoreboard) m_analysis_imp;

  // Fase de construcción donde se inicializa el puerto de análisis.
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase); // Llama a la implementación base.
    m_analysis_imp = new("m_analysis_imp", this); // Crea el puerto de análisis.
  endfunction

  // Función que procesa cada transacción recibida.
  virtual function write(Item item);
    bit [31:0] expected_fp_Z; // Valor esperado del resultado de la operación.
    bit expected_ovrf, expected_udrf; // Flags esperados para overflow y underflow.
    bit sign_X, sign_Y, sign_Z; // Bits de signo para los operandos y el resultado.
    bit [7:0] exp_X, exp_Y, exp_Z; // Exponentes de los operandos y resultado.
    bit [23:0] sig_X, sig_Y; // Parte significativa de los operandos.
    bit [47:0] sig_Z; // Parte significativa del resultado.
    bit [47:0] product; // Producto intermedio.
    int i; // Contador para el cálculo.

    // Extrae los bits de signo, exponente y significando de los operandos.
    sign_X = item.fp_X[31];
    sign_Y = item.fp_Y[31];
    exp_X = item.fp_X[30:23];
    exp_Y = item.fp_Y[30:23];
    sig_X = {1'b1, item.fp_X[22:0]}; // Añade el bit implícito de 1 en IEEE 754.
    sig_Y = {1'b1, item.fp_Y[22:0]};

    // Manejo de casos especiales (NaN, infinito, cero).
    if ((exp_X == 8'hFF && item.fp_X[22:0] != 0) || (exp_Y == 8'hFF && item.fp_Y[22:0] != 0)) begin
      // Caso NaN.
      expected_fp_Z = {sign_X ^ sign_Y, 8'hFF, 23'h400000}; 
    end else if ((exp_X == 8'hFF && item.fp_X[22:0] == 0) || (exp_Y == 8'hFF && item.fp_Y[22:0] == 0)) begin
      // Caso infinito.
      if ((exp_X == 8'hFF && item.fp_X[22:0] == 0 && item.fp_Y == 0) || 
          (exp_Y == 8'hFF && item.fp_Y[22:0] == 0 && item.fp_X == 0)) begin
        // Caso 0 * infinito.
        expected_fp_Z = {sign_X ^ sign_Y, 8'hFF, 23'h400000}; 
      end else begin
        expected_fp_Z = {sign_X ^ sign_Y, 8'hFF, 23'h000000}; 
      end
    end else if (item.fp_X == 0 || item.fp_Y == 0) begin
      // Caso cero.
      expected_fp_Z = {sign_X ^ sign_Y, 8'h00, 23'h000000}; 
    end else begin
      // Cálculo de la multiplicación en punto flotante.
      product = 0;
      for (i = 0; i < 24; i++) begin
        if (sig_Y[i]) begin
          product = product + (sig_X << i);
        end
      end
      sig_Z = product;

      // Ajusta el exponente sumando los exponentes de los operandos y restando el sesgo.
      exp_Z = exp_X + exp_Y - 8'd127;
      sign_Z = sign_X ^ sign_Y; // Calcula el signo del resultado.

      // Normaliza el resultado si es necesario.
      if (sig_Z[47]) begin
        sig_Z = sig_Z >> 1;
        exp_Z = exp_Z + 1;
      end else begin
        while (sig_Z[46] == 0 && exp_Z > 0) begin
          sig_Z = sig_Z << 1;
          exp_Z = exp_Z - 1;
        end
      end

      // Aplica el modo de redondeo especificado.
      case (item.r_mode)
        3'b000: begin
          // Redondeo al número par más cercano.
          if (sig_Z[23:0] > 24'h800000 || (sig_Z[23:0] == 24'h800000 && sig_Z[24])) begin
            sig_Z = sig_Z + 1;
          end
        end
        3'b001: begin
          // Truncamiento (redondeo hacia 0).
        end
        3'b010: begin
          // Redondeo hacia abajo (hacia -∞).
          if (sign_Z && sig_Z[23:0] != 0) begin
            sig_Z = sig_Z + 1;
          end
        end
        3'b011: begin
          // Redondeo hacia arriba (hacia +∞).
          if (!sign_Z && sig_Z[23:0] != 0) begin
            sig_Z = sig_Z + 1;
          end
        end
        3'b100: begin
          // Redondeo hacia la magnitud máxima.
          if (sig_Z[23:0] > 24'h800000 || (sig_Z[23:0] == 24'h800000 && !sign_Z)) begin
            sig_Z = sig_Z + 1;
          end
        end
      endcase

      // Maneja los casos de overflow y underflow.
      if (exp_Z >= 8'hFF) begin
        expected_fp_Z = {sign_Z, 8'hFF, 23'h000000}; // Overflow a infinito.
        expected_ovrf = 1;
        expected_udrf = 0;
      end else if (exp_Z <= 0) begin
        expected_fp_Z = {sign_Z, 8'h00, 23'h000000}; // Underflow a cero.
        expected_ovrf = 0;
        expected_udrf = 1;
      end else begin
        expected_fp_Z = {sign_Z, exp_Z[7:0], sig_Z[46:24]};
        expected_ovrf = 0;
        expected_udrf = 0;
      end
    end

    // Imprime información sobre la transacción procesada.
    `uvm_info("SCBD", $sformatf("r_mode=%0h fp_X=%0h fp_Y=%0h fp_Z=%0h ovrf=%0h udrf=%0h", 
      item.r_mode, item.fp_X, item.fp_Y, item.fp_Z, item.ovrf, item.udrf), UVM_LOW)
    
    // Comprueba si el resultado coincide con el esperado.
    if (item.fp_Z == expected_fp_Z && item.ovrf == expected_ovrf && item.udrf == expected_udrf) begin
      `uvm_info("SCBD", $sformatf("PASS! fp_Z=%0h ovrf=%0h udrf=%0h", item.fp_Z, item.ovrf, item.udrf), UVM_HIGH)
    end else begin
      `uvm_error("SCBD", $sformatf("ERROR! fp_Z=%0h (expected %0h) ovrf=%0h (expected %0h) udrf=%0h (expected %0h)", 
        item.fp_Z, expected_fp_Z, item.ovrf, expected_ovrf, item.udrf, expected_udrf))
    end
  endfunction

endclass
