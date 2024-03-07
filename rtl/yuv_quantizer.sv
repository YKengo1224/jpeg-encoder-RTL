`default_nettype none

module yuv_quantizer
#(
    parameter int MCU_SIZE = -1,
    parameter int DCT_BITWIDTH = -1,
    parameter int QUAN_BITWIDTH = -1
)
(
    input wire clk,
    input wire n_rst,
    input wire                                                         i_dct_valid,
    input wire signed [MCU_SIZE-1:0][MCU_SIZE-1:0][DCT_BITWIDTH-1:0]   i_dct_y,
    input wire signed [MCU_SIZE-1:0][MCU_SIZE-1:0][DCT_BITWIDTH-1:0]   i_dct_u,
    input wire signed [MCU_SIZE-1:0][MCU_SIZE-1:0][DCT_BITWIDTH-1:0]   i_dct_v,
    input wire                                                         i_last,
    input wire signed [MCU_SIZE-1:0][MCU_SIZE-1:0][QUAN_BITWIDTH-1:0]  i_y_quan_table,
    input wire signed [MCU_SIZE-1:0][MCU_SIZE-1:0][QUAN_BITWIDTH-1:0]  i_uv_quan_table,
    input wire                                                         i_wait,
    output logic                                                       o_quan_valid,
    output logic signed [MCU_SIZE-1:0][MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] o_quan_y,
    output logic signed [MCU_SIZE-1:0][MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] o_quan_u,
    output logic signed [MCU_SIZE-1:0][MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] o_quan_v,
    output logic                                                       o_last
);

    // valid信号を2クロック遅延(量子化の計算に２クロックかかるから)
    logic      valid_ff;
    logic      last_ff;

    always_ff @(posedge clk) begin
        if(!n_rst) begin
            valid_ff <= 1'b0;
        end
        else if(i_wait) begin
            valid_ff <= valid_ff;
        end
        else begin
            valid_ff <= i_dct_valid;
        end
    end    

    always_ff @(posedge clk) begin
        if(!n_rst) begin
            o_quan_valid <= 1'b0;
        end
        else if(i_wait) begin
            o_quan_valid <= o_quan_valid;
        end
        else begin
            o_quan_valid<= valid_ff;
        end
    end    

    always_ff @(posedge clk) begin
        if(!n_rst) begin
            last_ff <= 1'b0;
        end
        else if(i_wait) begin
            last_ff <= last_ff;
        end
        else begin
            last_ff <= i_last;
        end
    end

    always_ff @(posedge clk) begin
        if(!n_rst) begin
            o_last <= 1'b0;
        end
        else if(i_wait) begin
            o_last <= o_last;
        end
        else begin
            o_last <= last_ff;
        end
    end





    //quantization y
    quantizer
    #(
        .MCU_SIZE(MCU_SIZE),
        .DCT_BITWIDTH(DCT_BITWIDTH),
        .QUAN_BITWIDTH(QUAN_BITWIDTH)
    )
    quantizer_y
    (
        .clk(clk),
        .n_rst(n_rst),
        .dct_data(i_dct_y),
        .quan_table(i_y_quan_table),
        .i_wait(i_wait),
        .quan_data(o_quan_y)
    );

    //quantization u
    quantizer
    #(
        .MCU_SIZE(MCU_SIZE),
        .DCT_BITWIDTH(DCT_BITWIDTH),
        .QUAN_BITWIDTH(QUAN_BITWIDTH)
    )
    quantizer_u
    (
        .clk(clk),
        .n_rst(n_rst),
        .dct_data(i_dct_u),
        .quan_table(i_uv_quan_table),
        .i_wait(i_wait),
        .quan_data(o_quan_u)
    );


    //quantization u
    quantizer
    #(
        .MCU_SIZE(MCU_SIZE),
        .DCT_BITWIDTH(DCT_BITWIDTH),
        .QUAN_BITWIDTH(QUAN_BITWIDTH)
    )
    quantizer_v
    (
        .clk(clk),
        .n_rst(n_rst),
        .dct_data(i_dct_v),
        .quan_table(i_uv_quan_table),
        .i_wait(i_wait),
        .quan_data(o_quan_v)
    );

endmodule

`default_nettype wire