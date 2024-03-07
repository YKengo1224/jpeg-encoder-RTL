`default_nettype none

module sequare_matrix_multiplier 
#(
    parameter int MATRIX_SIZE = -1,
    parameter int MAT1_BITWIDTH = -1, 
    parameter int MAT2_BITWIDTH = -1 ,
    parameter int OUT_BITWIDTH = (MAT1_BITWIDTH+MAT2_BITWIDTH)+1
)   
(
    input  wire                                                             clk,
    input  wire                                                             n_rst,
    input  wire                                                             i_start,
    input  wire signed [MATRIX_SIZE-1:0][MATRIX_SIZE-1:0][MAT1_BITWIDTH-1:0]i_matrix1,
    input  wire signed [MATRIX_SIZE-1:0][MATRIX_SIZE-1:0][MAT2_BITWIDTH-1:0]i_matrix2,
    input  wire                                                             i_wait,
    output logic signed [MATRIX_SIZE-1:0][MATRIX_SIZE-1:0][OUT_BITWIDTH-1:0]o_matrix,
    output logic                                                            o_valid
);

    wire [MATRIX_SIZE-1:0]  valid;

    assign o_valid = valid == {MATRIX_SIZE{1'b1}};

    genvar i;
    generate
        for(i=0;i<MATRIX_SIZE;i=i+1) begin
            
            line_matrix_multiplier
            #(
                .MATRIX_SIZE(MATRIX_SIZE),
                .LINE_BITWIDTH(MAT1_BITWIDTH),
                .MAT_BITWIDTH(MAT2_BITWIDTH),
                .OUT_BITWIDTH(OUT_BITWIDTH)
            )
            line_matrix_multiplier_inst
            (
                .clk(clk),
                .n_rst(n_rst),
                .i_start(i_start),
                .i_line(i_matrix1[i]),
                .i_matrix(i_matrix2),
                .i_wait(i_wait),
                .o_line(o_matrix[i]),
                .o_valid(valid[i])
            );
            
        end
    endgenerate

endmodule

`default_nettype wire