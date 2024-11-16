class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard) // Macro para registrar la clase como componente de UVM
  
  // Constructor de la clase
  function new(string name="scoreboard", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  // Puerta de análisis para recibir transacciones
  uvm_analysis_imp #(Item, scoreboard) m_analysis_imp;

  // Fase de construcción: se inicializa la puerta de análisis
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_analysis_imp = new("m_analysis_imp", this);
  endfunction

  // Método para procesar los datos escritos en el scoreboard
  virtual function write(Item item);
    // Declaración de variables locales para cálculos
    bit [31:0] expected_fp_Z;           // Resultado esperado en formato de punto flotante
    bit expected_ovrf, expected_udrf;   // Indicadores esperados de desbordamiento y subdesbordamiento
    bit sign_X, sign_Y, sign_Z;         // Signos de los operandos y el resultado
    bit [7:0] exp_X, exp_Y, exp_Z;      // Exponentes de los operandos y el resultado
    bit [23:0] sig_X, sig_Y;            // Significandos de los operandos
    bit [47:0] sig_Z;                   // Significando extendido del resultado
    bit [47:0] product;                 // Producto acumulado para la multiplicación
    int i;                              // Índice para el bucle

    // Comprobación de casos especiales
    if ((exp_X == 8'hFF && item.fp_X[22:0] != 0) || 
        (exp_Y == 8'hFF && item.fp_Y[22:0] != 0)) begin
        // Caso NaN (Not a Number)
        expected_fp_Z = {sign_X ^ sign_Y, 8'hFF, 23'h400000}; // NaN
    end 

    else if ((exp_X == 8'hFF && item.fp_X[22:0] == 0) || 
             (exp_Y == 8'hFF && item.fp_Y[22:0] == 0)) begin
        // Casos de infinito
        if ((exp_X == 8'hFF && item.fp_X[22:0] == 0 && item.fp_Y == 0) || 
            (exp_Y == 8'hFF && item.fp_Y[22:0] == 0 && item.fp_X == 0)) begin
            // Caso 0 * infinito
            expected_fp_Z = {sign_X ^ sign_Y, 8'hFF, 23'h400000}; // NaN
        end 

        else begin
            expected_fp_Z = {sign_X ^ sign_Y, 8'hFF, 23'h000000}; // Infinito
        end
    end 

    else if (item.fp_X == 0 || item.fp_Y == 0) begin
        // Caso 0
        expected_fp_Z = {sign_X ^ sign_Y, 8'h00, 23'h000000}; // Cero
    end 

    else begin
        // Multiplicación de punto flotante bit a bit
        product = 0;
        for (i = 0; i < 24; i++) begin
            if (sig_Y[i]) begin
                product = product + (sig_X << i);
            end
        end
        sig_Z = product;

        // Ajuste del exponente
        exp_Z = exp_X + exp_Y - 8'd127;
        sign_Z = sign_X ^ sign_Y;

        // Normalización del resultado
        if (sig_Z[47]) begin
            sig_Z = sig_Z >> 1;
            exp_Z = exp_Z + 1;
        end 

        else begin
            while (sig_Z[46] == 0 && exp_Z > 0) begin
                sig_Z = sig_Z << 1;
                exp_Z = exp_Z - 1;
            end
        end

        // Aplicar el modo de redondeo
        case (item.r_mode)
            3'b000: begin
                // Redondeo al más cercano, con empate al par
                if (sig_Z[23:0] > 24'h800000 || 
                   (sig_Z[23:0] == 24'h800000 && sig_Z[24])) begin
                    sig_Z = sig_Z + 1;
                end
            end
            3'b001: begin
                // Redondeo hacia cero (truncar)
                // No se requiere acción adicional
            end
            3'b010: begin
                // Redondeo hacia abajo (hacia -infinito)
                if (sign_Z && sig_Z[23:0] != 0) begin
                    sig_Z = sig_Z + 1;
                end
            end
            3'b011: begin
                // Redondeo hacia arriba (hacia +infinito)
                if (!sign_Z && sig_Z[23:0] != 0) begin
                    sig_Z = sig_Z + 1;
                end
            end
            3'b100: begin
                // Redondeo al más cercano, con empate a la magnitud máxima
                if (sig_Z[23:0] > 24'h800000 || 
                   (sig_Z[23:0] == 24'h800000 && !sign_Z)) begin
                    sig_Z = sig_Z + 1;
                end
            end
            default: begin
                // Caso por defecto (si es necesario)
            end
        endcase

        // Manejo de desbordamiento y subdesbordamiento
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
            expected_fp_Z = {sign_Z, exp_Z[7:0], sig_Z[46:24]};
            expected_ovrf = 0;
            expected_udrf = 0;
        end
    end

    // Mensaje informativo de los resultados esperados y obtenidos
    `uvm_info("SCBD", $sformatf("r_mode=%0h fp_X=%0h fp_Y=%0h fp_Z=%0h ovrf=%0h udrf=%0h", 
                                 item.r_mode, item.fp_X, item.fp_Y, item.fp_Z, item.ovrf, item.udrf), UVM_LOW)
    
    // Validación de los resultados
    if (item.fp_Z == expected_fp_Z && item.ovrf == expected_ovrf && item.udrf == expected_udrf) begin
        `uvm_info("SCBD", $sformatf("PASS! fp_Z=%0h ovrf=%0h udrf=%0h", 
                                     item.fp_Z, item.ovrf, item.udrf), UVM_HIGH)
    end else begin
        `uvm_error("SCBD", $sformatf("ERROR! fp_Z=%0h (expected %0h) ovrf=%0h (expected %0h) udrf=%0h (expected %0h)", 
                                      item.fp_Z, expected_fp_Z, item.ovrf, expected_ovrf, item.udrf, expected_udrf))
    end
  endfunction

endclass
