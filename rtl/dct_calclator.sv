 `default_nettype  none

module dct_calculator
#(
    //parameter int WIDTH = -1,    
    parameter int MCU_SIZE = -1,
    parameter int YUV_BITWIDTH = -1,
    parameter int OUT_BITWIDTH = -1
)   
(
    input  wire                                                        clk,
    input  wire                                                        n_rst,
    input  wire                                                        i_start,  //calc_start_enable
    input  wire  signed [MCU_SIZE-1:0][MCU_SIZE-1:0][YUV_BITWIDTH-1:0] i_mcu,
    input  wire                                                        i_wait,
    output logic                                                       o_ready,
    output logic signed [MCU_SIZE-1:0][MCU_SIZE-1:0][OUT_BITWIDTH-1:0] o_dct,    
    output wire                                                        o_valid
);

    localparam int DCT_BITWIDTH = 14;    
    //localparam int MUL_BITWIDTH = DCT_BITWIDTH + OUT_BITWIDTH;
    localparam int MUL_BITWIDTH = DCT_BITWIDTH + DCT_BITWIDTH;

    localparam int STATE_READY = 3'b000;
    localparam int STATE_FIRST = 3'b001;
    localparam int STATE_SECOND = 3'b010;        
    logic [2:0]                        state;

    //i_startとi_waitが同時に１になったとき, i_start_evecが1になる
    //waitが解除されるまで1を保持し，waitが解除されると同時に計算をスタートさせる役割を担っている
    wire                                                 i_start_evec_flag;   
    logic                                                i_start_evec;        
    wire                                                 i_start_in;


    logic [7:0][7:0][DCT_BITWIDTH-1:0]                   dct ;
    logic [7:0][7:0][DCT_BITWIDTH-1:0]                   dct_t ;  //transpose dct




    wire                                                dct_start;
    logic [MCU_SIZE-1:0][MCU_SIZE-1:0][DCT_BITWIDTH-1:0] dct_matrix1;
    logic [MCU_SIZE-1:0][MCU_SIZE-1:0][DCT_BITWIDTH-1:0] dct_matrix2;
    wire [MCU_SIZE-1:0][MCU_SIZE-1:0][MUL_BITWIDTH-1:0] dct_out;
    wire                                                dct_o_valid;

    logic [MCU_SIZE-1:0][MCU_SIZE-1:0][DCT_BITWIDTH-1:0] mcu;
    logic [MCU_SIZE-1:0][MCU_SIZE-1:0][DCT_BITWIDTH-1:0] A_mul_mcu;
    wire                                                first_valid;

    //second_startとi_waitが同時に１になったとき, second_start_evecが1になる
    //waitが解除されるまで1を保持し，waitが解除されると同時に計算をスタートさせる役割を担っている
    logic                                                second_start;
    wire                                                second_start_evec_flag;
    logic                                                second_start_evec;
    wire                                                second_start_in;

    //##############################################
    //start evec
    //##############################################
    assign i_start_evec_flag = i_start & i_wait;

    always_ff @(posedge clk) begin
        if(!n_rst) begin
            i_start_evec <= 1'b0;
        end
        else if(i_start_evec_flag)begin
            i_start_evec <= 1'b1;
        end
        else if(!i_wait) begin
            i_start_evec <= 1'b0;
        end
        else begin
            i_start_evec <= i_start_evec;
        end 
    end


    assign i_start_in =  i_start | i_start_evec;


    //##############################################
    //second start evec
    //##############################################
    // assign second_start           = (state == STATE_FIRST) & dct_o_valid;
    assign second_start_evec_flag = second_start & i_wait;

    always_ff @( posedge clk) begin
        if(!n_rst) begin
            second_start <= 1'b0;
        end        
        else begin
            second_start <= first_valid;
        end
    end
    
    always_ff @(posedge clk) begin
        if(!n_rst) begin
            second_start_evec <= 1'b0;
        end
        else if(second_start_evec_flag)begin
            second_start_evec <= 1'b1;
        end
        else if(!i_wait) begin
            second_start_evec <= 1'b0;
        end
        else begin
            second_start_evec <= second_start_evec;
        end 
    end
    
    assign second_start_in = second_start | second_start_evec;


    //##############################################
    //state
    //##############################################
    always_ff @( posedge clk ) begin
        if(!n_rst) begin
            state <= STATE_READY;
        end
        else begin
            case(state) 
            STATE_READY:
                if(i_start_in) begin
                    state <= STATE_FIRST;
                end
                else begin
                    state <= STATE_READY;
                end
            STATE_FIRST:
                if(dct_o_valid) begin
                    state <= STATE_SECOND; 
                end
                else begin
                    state <= STATE_FIRST;
                end
            STATE_SECOND:
                if(dct_o_valid) begin
                    state <= STATE_READY;
                end
                else begin
                    state <= STATE_SECOND;
                end
            default:
                state <= STATE_READY;
            endcase        
        end
    end





    //##############################################
    //set dct and dct_t
    //##############################################

    always_comb begin
        for(int i=0;i<8;i++) begin
            for(int j=0;j<8;j++) begin
                dct[i][j] <= set_dct(i,j);
                dct_t[i][j] <= set_dct_t(i,j);
            end
        end
    end


        

    //##############################################
    //set o_ready
    //##############################################
    logic          ready;

    always_comb begin
        if(i_start) begin
            o_ready = 1'b0;
        end
        else if(i_start_evec) begin
            o_ready = 1'b0;
        end
        else begin
            o_ready = ready;
        end
    end
    always_ff @(posedge clk) begin
        if(!n_rst) begin
            ready <= 1'b1;
        end
        else if(i_wait) begin
            ready <= ready;
        end
        else if(i_start_evec) begin
            ready <= 1'b0;
        end
        else if(i_start) begin
            ready <= 1'b0;
        end
        else if(!o_ready & o_valid) begin
            ready <= 1'b1;
        end
        else begin
            ready <= o_ready;
        end 
    end
    
    

    //##############################################
    //i_mcu -> mcu(expand bitwidth)
    //##############################################
    localparam  int EXPAND_BITWIDTH = DCT_BITWIDTH - YUV_BITWIDTH;
    always_comb begin
        for(int i = 0;i<MCU_SIZE;i++) begin
            for(int j = 0;j<MCU_SIZE;j++) begin
                mcu[i][j] =  {{EXPAND_BITWIDTH{i_mcu[i][j][YUV_BITWIDTH-1]}} ,i_mcu[i][j]};
            end
        end
        
    end

    assign  dct_start   = (state==STATE_SECOND) ?  second_start_in : i_start_in;
//    assign  dct_matrix1 = (state!=STATE_SECOND) ?  dct : A_mul_mcu;
    always_comb begin 
        if(state == STATE_FIRST & dct_o_valid | state==STATE_SECOND) begin
            dct_matrix1 =  A_mul_mcu;
        end 
        else begin
            dct_matrix1 =  dct;
        end
        
    end
        //assign  dct_matrix2 = (state!=STATE_SECOND) ?  mcu : dct_t;
    always_comb begin 
        if(state == STATE_FIRST & dct_o_valid | state==STATE_SECOND) begin
            dct_matrix2 =  dct_t;
        end 
        else begin
            dct_matrix2 =  mcu;
        end
        
    end

    assign  first_valid = (state==STATE_FIRST)  ? dct_o_valid  : 1'b0;
    assign  o_valid     = (state==STATE_SECOND)? dct_o_valid  : 1'b0;
    

    sequare_matrix_multiplier
    #(
        .MATRIX_SIZE(8),
        .MAT1_BITWIDTH(DCT_BITWIDTH),
        .MAT2_BITWIDTH(DCT_BITWIDTH),
        .OUT_BITWIDTH(MUL_BITWIDTH)
    )
    mul1_init
    (
        .clk(clk),
        .n_rst(n_rst),
        .i_start(dct_start),
        .i_matrix1(dct_matrix1),
        .i_matrix2(dct_matrix2),
        .i_wait(i_wait),
        .o_matrix(dct_out),
        .o_valid(dct_o_valid)
    );


    //##############################################
    //A * mcu(rounding)
    //##############################################
    always_ff @(posedge clk) begin
        if(!n_rst) begin
            for(int i=0;i<8;i++) begin
                for(int j=0;j<8;j++) begin
                        A_mul_mcu[i][j] = DCT_BITWIDTH'('d0);
                end
            end            
        end
        else if(first_valid) begin
            for(int i=0;i<8;i++) begin
                for(int j=0;j<8;j++) begin
                    if(dct_out[i][j][DCT_BITWIDTH-1]&& !dct_out[i][j][MUL_BITWIDTH-1]) begin
                        A_mul_mcu[i][j] = dct_out[i][j][MUL_BITWIDTH-1 -: DCT_BITWIDTH] + 'd1;
                    end
                    else begin
                        A_mul_mcu[i][j] = dct_out[i][j][MUL_BITWIDTH-1 -: DCT_BITWIDTH];
                    end 
                end
            end
        end

        else begin
            for(int i=0;i<8;i++) begin
                for(int j=0;j<8;j++) begin
                        A_mul_mcu[i][j] = A_mul_mcu[i][j];
                end
            end
        end
    end
    
    //##############################################
    //A * mcu * A^-1(rounding)
    //##############################################
    localparam int DIFF_BITWIDTH = (DCT_BITWIDTH - OUT_BITWIDTH);
    
    always_comb begin    //rounding
        for(int i=0;i<8;i++) begin
            for(int j=0;j<8;j++) begin
                if(dct_out[i][j][DCT_BITWIDTH-1] && !dct_out[i][j][MUL_BITWIDTH-1]) begin
                    o_dct[i][j] = dct_out[i][j][(MUL_BITWIDTH-1)-DIFF_BITWIDTH -: OUT_BITWIDTH] + 'd1;
                end
                else begin
                    o_dct[i][j] = dct_out[i][j][(MUL_BITWIDTH-1)-DIFF_BITWIDTH -: OUT_BITWIDTH];
                end 
            end
        end
    end






    function int set_dct(int i,int j);
        localparam int DCT [7:0][7:0] = '{  
            '{ 5792,  5792,  5792,  5792,  5792,  5792,  5792,  5792},
            '{ 8034,  6811,  4551,  1598, -1598, -4551, -6811, -8034},
            '{ 7568,  3134, -3134, -7568, -7568,  -3134,  3134,  7568},
            '{ 6811, -1598, -8034, -4551,  4551,  8034,  1598, -6811},
            '{ 5792, -5792, -5792,  5792,  5792, -5792, -5792,  5792},
            '{ 4551, -8034,  1598,  6811, -6811, -1598,  8034, -4551},
            '{ 3134, -7568,  7568, -3134, -3134,  7568, -7568,  3134},
            '{ 1598, -4551,  6811, -8034,  8034, -6811,  4551, -1598}
        };
        int out;
        out = DCT[7-i][7-j];    //big endian to little endian
        return out;

    endfunction 

    function int set_dct_t(int i,int j);
        localparam int DCT_T [7:0][7:0] = '{
            '{ 5792,  8034,  7568,  6811,  5792,  4551,  3134,  1598},
            '{ 5792,  6811,  3134, -1598, -5792, -8034, -7568, -4551},
            '{ 5792,  4551, -3134, -8034, -5792,  1598,  7568,  6811},
            '{ 5792,  1598, -7568, -4551,  5792,  6811, -3134, -8034},
            '{ 5792, -1598, -7568,  4551,  5792, -6811, -3134,  8034},
            '{ 5792, -4551, -3134,  8034, -5792, -1598,  7568, -6811},
            '{ 5792, -6811,  3134,  1598, -5792,  8034, -7568,  4551},
            '{ 5792, -8034,  7568, -6811,  5792, -4551,  3134, -1598}
        };
        int out;
        out = DCT_T[7-i][7-j];
        return out;
        
    endfunction


endmodule

`default_nettype wire