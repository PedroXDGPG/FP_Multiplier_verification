class report_info; 

    typedef enum logic {PASS, ERROR} status;

   
    // Definición de los miembros de la clase
    logic [31 : 0]  fp_x;
    logic [31 : 0]  fp_y;
    logic [31 : 0]  result;
    status          conclusion;
    //logic [31 : 0]  expected_fp_y;
    logic [31 : 0]  expected_result;
    
    
    function new (
        logic [31 : 0]  x = 0, 
        logic [31 : 0]  y = 0, 
        logic [31 : 0]  r = 0, 
        status          c = PASS, 
        //logic [31 : 0]  e_y = 0, 
        logic [31 : 0]  e_r = 0
    );
        this.fp_x = x;
        this.fp_y = y;
        this.result = r;
        this.conclusion = c;
        //this.expected_fp_x = e_x;
        //this.expected_fp_y = e_y;
        this.expected_result = e_r;
    endfunction

endclass