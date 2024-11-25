class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard)

  //base de datos para almacenar los resultados obtenidos y esperados junto con los operandos
  report_info results_data [$]; 
  integer csv_file;

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

    //para almacenar lo que ira a la base de datos
    report_info current_data;

    // Componentes del número flotante
    bit sign_X, sign_Y, sign_Z;
    bit [7:0] exp_X, exp_Y, exp_Z;
    bit [8:0] exp_Z_num, exp_Z_no_sum;
    bit [23:0] man_X, man_Y;
    bit [47:0] man_Z;
    bit        round_bit, guard_bit, sticky_bit;
    int i;

    current_data = new();  

    // Extraer signo, exponente y significando
    sign_X = item.fp_X[31];
    sign_Y = item.fp_Y[31];
    exp_X = item.fp_X[30:23];
    exp_Y = item.fp_Y[30:23];
    man_X = {1'b1, item.fp_X[22:0]};
    man_Y = {1'b1, item.fp_Y[22:0]};

    /////////////////////////////////// Verificar casos especiales /////////////////////////////////
    if ((exp_X == 8'hFF && item.fp_X[22:0] != 0) || (exp_Y == 8'hFF && item.fp_Y[22:0] != 0)) begin
      // Caso de NaN
      expected_fp_Z = {sign_X ^ sign_Y, 8'hFF, 23'h400000}; // NaN
      current_data.expected_result = expected_fp_Z;

    end 
    
    else if ((exp_X == 8'hFF && item.fp_X[22:0] == 0) || (exp_Y == 8'hFF && item.fp_Y[22:0] == 0)) begin
      // Caso de infinito
      if ((exp_X == 8'hFF && item.fp_X[22:0] == 0 && item.fp_Y == 0) || 
          (exp_Y == 8'hFF && item.fp_Y[22:0] == 0 && item.fp_X == 0)) begin
        // Caso de cero * infinito
        expected_fp_Z = {sign_X ^ sign_Y, 8'hFF, 23'h400000}; // NaN
        current_data.expected_result = expected_fp_Z;
      end 
      
      else begin
        expected_fp_Z = {sign_X ^ sign_Y, 8'hFF, 23'h000000}; // Infinito
        current_data.expected_result = expected_fp_Z;
        `uvm_info("SCBD", $sformatf("ESSSSSSS IONFIFIFIFexpected_fp_Z: expected_fp_Z=%0b ", expected_fp_Z), UVM_LOW)

      end 

    end 
    
    else if (item.fp_X == 0 || item.fp_Y == 0) begin
      // Caso de cero
      
      expected_fp_Z = {sign_X ^ sign_Y, 8'h00, 23'h000000}; // Cero
      current_data.expected_result = expected_fp_Z;

    end 
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    else begin
      /////////////////////////////////// Realizar la multiplicación punto flotante bit a bit /////////////////////////////////
      man_Z = 0;
      for (i = 0; i < 24; i++) begin
        if (man_Y[i]) begin
          man_Z = man_Z + (man_X << i);
        end
      end

      // Ajustar el exponente
      exp_Z = exp_X + exp_Y - 127;
      exp_Z_num = exp_X + exp_Y - 127;    // Exponente con 9 bits
      exp_Z_no_sum = exp_X + exp_Y;      // Exponente para considerar underflow sin complemento a 2
      // Mostrar exponentes de X y Y
      `uvm_info("SCBD", $sformatf("EXPONENTE RESULTADO: exp_Z=%0h ", exp_Z), UVM_LOW)
      `uvm_info("SCBD", $sformatf("LOLOLOLOLEXPONENTE RESULTADO: exp_Z_num=%0h ", exp_Z_num), UVM_LOW)
      `uvm_info("SCBD", $sformatf("LOLOLOLOLEXPONENTE RESULTADO: exp_Z_no_sum=%0d ", exp_Z_no_sum), UVM_LOW)
      `uvm_info("SCBD", $sformatf("HEXA RESULTADO: exp_Z_no_sum=%0h ", exp_Z_no_sum), UVM_LOW)
      `uvm_info("SCBD", $sformatf("LOLOLOLOL: exp_X=%0h ", exp_X), UVM_LOW)
      `uvm_info("SCBD", $sformatf("LOLOLOLOL: exp_Y=%0h ", exp_Y), UVM_LOW)
 

      sign_Z = sign_X ^ sign_Y;
      `uvm_info("SCBD", $sformatf("SIGNO RESULTADO: sign_Z=%0h ", sign_Z), UVM_HIGH)
      // Asignar los 3 bits de redondeo: Guard, Round, Sticky
      guard_bit   = man_Z[22];     
      round_bit   = man_Z[21];     
      sticky_bit  = |man_Z[20:0];  

      // Normalizar el resultado
      if (man_Z[47]) begin
        man_Z = man_Z >> 1;
        exp_Z = exp_Z + 1;
      // Mostrar exponentes de X y Y
      `uvm_info("SCBD", $sformatf("NORMALIZADO EXPONENTE RESULTADO: exp_Z=%0h ", exp_Z), UVM_LOW)
      `uvm_info("SCBD", $sformatf("NORMALIZADO MANTISA RESULTADO: man_Z=%0h ", man_Z), UVM_LOW)

      end 
      
      // else begin
      //   while (man_Z[46] == 0 && exp_Z > 0) begin
      //     man_Z = man_Z << 1;
      //     exp_Z = exp_Z - 1;
      //   end
      // end
      `uvm_info("SCBD", $sformatf("round_bit RESULTADO: round_bit=%0h ", round_bit), UVM_LOW)
      `uvm_info("SCBD", $sformatf("guard_bit RESULTADO: guard_bit=%0h ", guard_bit), UVM_LOW)
      `uvm_info("SCBD", $sformatf("sticky_bit RESULTADO: sticky_bit=%0h ", sticky_bit), UVM_LOW)

      /////////////////////////////////// Redondeo de acuerdo al r_mode ////////////////////////////////////
      case (item.r_mode)
        3'b000: begin // Round to nearest, ties to even (Redondeo al más cercano, empates hacia par)
          if (round_bit == 1 && (guard_bit || sticky_bit)) begin
            man_Z = man_Z + 1;
          end
        end

        3'b001: begin // Round to zero (Redondeo hacia cero)
          // No se necesita acción adicional, simplemente truncar
        end

        3'b010: begin // Round towards −∞ (Redondeo hacia -infinito)
          if (sign_Z == 1) begin
            man_Z[45:23] = man_Z[45:23] + 1;
            `uvm_info("SCBD", $sformatf("MANTISA RESULTADO ROUND: man_Z=%0h ", man_Z), UVM_LOW)
          end
        end

        3'b011: begin // Round towards +∞ (Redondeo hacia +infinito)
          if (sign_Z == 0) begin
             man_Z[45:23] =  man_Z[45:23] + 1;
          end
        end

        3'b100: begin // Round to nearest, ties away from zero (Redondeo al más cercano, empates hacia la magnitud máxima)
          if (round_bit == 1) begin
             man_Z =  man_Z + 1;
          end
        end

        default: begin
          // Caso por defecto si es necesario
        end
      endcase
      `uvm_info("SCBD", $sformatf("EN IFS RESULTADO: exp_Z_no_sum=%0d ", exp_Z_no_sum), UVM_LOW)
      `uvm_info("SCBD", $sformatf("2EN IFS RESULTADO: exp_Z_num=%0d ", exp_Z_num), UVM_LOW)
      ///////////////////////////////// Manejar overflow y underflow /////////////////////////////////
      if (exp_Z_no_sum >= 255+127) begin
        expected_fp_Z = {sign_Z, 8'hFF, 23'h000000}; // Infinito
        expected_ovrf = 1;
        expected_udrf = 0;
        `uvm_info("SCBD", $sformatf("ASDFKNASDFIKNIKAFJUDSexpected_fp_Z: expected_fp_Z=%0b ", expected_fp_Z), UVM_LOW)

      end 
      
      else if (exp_Z_no_sum <= 127) begin
        expected_fp_Z = {sign_Z, 8'h00, 23'h000000}; // Cero
        expected_ovrf = 0;
        expected_udrf = 1;
      end 
      
      else begin
              // Mostrar exponentes de X y Y
        expected_fp_Z = {sign_Z, exp_Z, man_Z[45:23]};
        expected_ovrf = 0;
        expected_udrf = 0;
        `uvm_info("SCBD", $sformatf("sign: exp_Z=%0h ", sign_Z), UVM_LOW)
        `uvm_info("SCBD", $sformatf("exp_Z: exp_Z=%0h ", exp_Z), UVM_LOW)
        `uvm_info("SCBD", $sformatf("man_Z: exp_Z=%0h ", man_Z[45:23]), UVM_LOW)
        `uvm_info("SCBD", $sformatf("expected_fp_Z: expected_fp_Z=%0b ", expected_fp_Z), UVM_LOW)
      end
    end
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    // Mostrar información del procesamiento
    `uvm_info("SCBD", $sformatf("r_mode=%0h fp_X=%0h fp_Y=%0h fp_Z=%0h ovrf=%0h udrf=%0h", item.r_mode, item.fp_X, item.fp_Y, item.fp_Z, item.ovrf, item.udrf), UVM_LOW)
    
    // Validar resultados
    if (item.fp_Z == expected_fp_Z && item.ovrf == expected_ovrf && item.udrf == expected_udrf) begin
      `uvm_info("SCBD", $sformatf("PASS! fp_Z=%0h ovrf=%0h udrf=%0h", item.fp_Z, item.ovrf, item.udrf), UVM_HIGH)
    end 
    
    else begin
      `uvm_error("SCBD", $sformatf("ERROR! fp_Z=%0h (expected %0h) ovrf=%0h (expected %0h) udrf=%0h (expected %0h)", item.fp_Z, expected_fp_Z, item.ovrf, expected_ovrf, item.udrf, expected_udrf))
    end
    // Mostrar signos, exponentes y mantisas del golden reference y del DUT
 
    `uvm_info("SCBD", $sformatf("DUT: sign=%0b exp=%0b man=%0b", item.fp_Z[31], item.fp_Z[30:23], item.fp_Z[22:0]), UVM_HIGH)
    `uvm_info("SCBD", $sformatf("Golden: sign=%0b exp=%0b man=%0b", expected_fp_Z[31], expected_fp_Z[30:23], expected_fp_Z[22:0]), UVM_HIGH)
    // Mostrar exponentes de X y Y
    `uvm_info("SCBD", $sformatf("Exponentes: exp_X=%0h exp_Y=%0h", item.fp_X[30:23], item.fp_Y[30:23]), UVM_LOW)
    
    current_data.fp_x = item.fp_X;
    current_data.fp_y = item.fp_Y;
    current_data.result = item.fp_Z;
    current_data.expected_result = expected_fp_Z;
    current_data.conclusion = report_info::PASS;

    assert (current_data.result == current_data.expected_result) 
    else  begin
      `uvm_error("SCBD", "Error, los resultados no coinciden")
       current_data.conclusion = report_info::ERROR;
    end;

    results_data.push_front(current_data);

 endfunction

  //fase para generar el CSV
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    csv_file = $fopen("../results_report.csv", "a");

    if (csv_file) begin

      // header
      $fdisplay(csv_file, "Num,  Multiplicador, Multiplicando, Resultado obtenido (DUT), Resultado esperado (Reference), Estado\n");

      foreach (results_data[i]) begin
        $fdisplay(csv_file, "%0d, %0h, %0h, %0h, %0h, %s",
                  i, results_data[i].fp_x, results_data[i].fp_y, results_data[i].result, results_data[i].expected_result, results_data[i].conclusion);
      end

      $fclose(csv_file);
      `uvm_info("SCBD", "CSV file saved and closed in report_phase.", UVM_LOW);
    end else begin
      `uvm_error("SCBD", "Failed to open CSV file for writing in report_phase.");
    end
  endfunction
endclass
