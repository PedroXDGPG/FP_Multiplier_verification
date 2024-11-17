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
    // Variables para almacenar resultados esperados
    bit [31:0] expected_fp_Z;
    bit expected_ovrf, expected_udrf;

    // Componentes del número flotante
    bit sign_X, sign_Y, sign_Z;
    bit [7:0] exp_X, exp_Y, exp_Z;
    bit [23:0] man_X, man_Y;       // 24 bits para evitar desbordamiento
    bit [47:0] man_Z;              // 48 bits para evitar desbordamiento
    bit [47:0] product;   
    bit guard, round, sticky;    // Definir los bits guard, round y sticky
    int i;

    // Extraer signo, exponente y significando
    sign_X = item.fp_X[31];
    sign_Y = item.fp_Y[31];
    exp_X = item.fp_X[30:23];
    exp_Y = item.fp_Y[30:23];
    man_X = {1'b1, item.fp_X[22:0]};
    man_Y = {1'b1, item.fp_Y[22:0]};

    ////////////////////////////////// Verificar casos especiales //////////////////////////////////
    if ((exp_X == 8'hFF && item.fp_X[22:0] != 0) || (exp_Y == 8'hFF && item.fp_Y[22:0] != 0)) begin
      // Caso de NaN
      expected_fp_Z = {sign_X ^ sign_Y, 8'hFF, 23'h400000}; // NaN

    end 
    
    else if ((exp_X == 8'hFF && item.fp_X[22:0] == 0) || (exp_Y == 8'hFF && item.fp_Y[22:0] == 0)) begin
      // Caso de infinito
      if ((exp_X == 8'hFF && item.fp_X[22:0] == 0 && item.fp_Y == 0) || 
          (exp_Y == 8'hFF && item.fp_Y[22:0] == 0 && item.fp_X == 0)) begin
        // Caso de cero * infinito
        expected_fp_Z = {sign_X ^ sign_Y, 8'hFF, 23'h400000}; // NaN
      end 
      
      else begin
        expected_fp_Z = {sign_X ^ sign_Y, 8'hFF, 23'h000000}; // Infinito
      end 

    end 
    
    else if (item.fp_X == 0 || item.fp_Y == 0) begin
      // Caso de cero
      expected_fp_Z = {sign_X ^ sign_Y, 8'h00, 23'h000000}; // Cero

    end 
  ///////////////////////////////////////////////////////////////////////////////////////////////////
    else begin
      // Realizar la multiplicación punto flotante bit a bit
      product = 0;
      for (i = 0; i < 24; i++) begin
        if (man_Y[i]) begin
          product = product + (man_X << i);
        end
      end
      man_Z = product;

      // Ajustar el exponente
      exp_Z = exp_X + exp_Y - 8'd127;
      sign_Z = sign_X ^ sign_Y;

      // Normalizar el resultado
      if (man_Z[47]) begin
        man_Z = man_Z >> 1;
        exp_Z = exp_Z + 1;
      end 
      
      else begin
        while (man_Z[46] == 0 && exp_Z > 0) begin
          man_Z = man_Z << 1;
          exp_Z = exp_Z - 1;
        end
      end

        ///////////////////////////////// Aplicar modo de redondeo   /////////////////////////////////////
      guard  = man_Z[23];
      round  = man_Z[22];
      sticky = man_Z[21]; // Usamos exclusivamente el bit 21 como sticky

      case (item.r_mode)
        3'b000: begin
          // Round to nearest, ties to even
          if ((round && (guard || sticky)) || (round && !guard && !sticky && man_Z[24])) begin
            man_Z = man_Z + 1;
          end
        end

        3'b001: begin
          // Round to zero (truncate)
          // No se necesita acción adicional, ya que se ignoran los bits guard, round y sticky.
        end

        3'b010: begin
          // Round towards −∞
          if (sign_Z && (guard || sticky)) begin
            man_Z = man_Z + 1;
          end
        end

        3'b011: begin
          // Round towards +∞
          if (!sign_Z && (guard || sticky)) begin
            man_Z = man_Z + 1;
          end
        end

        3'b100: begin
          // Round to nearest, ties away from zero
          if ((round && (guard || sticky)) || (round && !guard && !sticky)) begin
            man_Z = man_Z + 1;
          end
        end

        default: begin
          // Caso por defecto si se recibe un modo inválido.
        end
      endcase
      // Manejar overflow y underflow
      if (exp_Z >= 8'hFF) begin
        expected_fp_Z = {sign_Z, 8'hFF, 23'h000000}; // Infinito
        expected_ovrf = 1;
        expected_udrf = 0;
      end 
      
      else if (exp_Z <= 0) begin
        expected_fp_Z = {sign_Z, 8'h00, 23'h000000}; // Cero
        expected_ovrf = 0;
        expected_udrf = 1;
      end 
      
      else begin
        expected_fp_Z = {sign_Z, exp_Z[7:0], man_Z[46:24]};
        expected_ovrf = 0;
        expected_udrf = 0;
      end
    end

    // Mostrar información del procesamiento
    `uvm_info("SCBD", $sformatf("r_mode=%0h fp_X=%0h fp_Y=%0h fp_Z=%0h ovrf=%0h udrf=%0h", item.r_mode, item.fp_X, item.fp_Y, item.fp_Z, item.ovrf, item.udrf), UVM_LOW)
    
    // Validar resultados
    if (item.fp_Z == expected_fp_Z && item.ovrf == expected_ovrf && item.udrf == expected_udrf) begin
      `uvm_info("SCBD", $sformatf("PASS! fp_Z=%0h ovrf=%0h udrf=%0h", item.fp_Z, item.ovrf, item.udrf), UVM_HIGH)
    end 
    
    else begin
      `uvm_error("SCBD", $sformatf("ERROR! fp_Z=%0h (expected %0h) ovrf=%0h (expected %0h) udrf=%0h (expected %0h)", item.fp_Z, expected_fp_Z, item.ovrf, expected_ovrf, item.udrf, expected_udrf))
    end
  endfunction

endclass
