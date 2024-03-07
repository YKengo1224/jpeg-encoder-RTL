`default_nettype none

module yuv_dct_calclator
#(
    // parameter int MCU_SIZE = -1,
    // parameter int PIXEL_BITWIDTH = -1,
    // parameter int YUV_BITWIDTH = -1,
    // parameter int OUT_BITWIDTH = -1
      parameter int MCU_SIZE = 8,
      parameter int PIXEL_BITWIDTH = 24,
      parameter int YUV_BITWIDTH = 8,
      parameter int OUT_BITWIDTH = 12

)
(
    input  wire                                                         clk,
    input  wire                                                         n_rst,
    input  wire                                                         i_start,
    input  wire [0:MCU_SIZE-1][0:MCU_SIZE-1][PIXEL_BITWIDTH-1:0]        i_mcu,
    input  wire                                                         i_last,
    input  wire                                                         i_wait,
    output logic                                                        o_ready,
    output logic signed [MCU_SIZE-1:0][MCU_SIZE-1:0][OUT_BITWIDTH-1:0]  o_y,
    output logic signed [MCU_SIZE-1:0][MCU_SIZE-1:0][OUT_BITWIDTH-1:0]  o_u,
    output logic signed [MCU_SIZE-1:0][MCU_SIZE-1:0][OUT_BITWIDTH-1:0]  o_v,
    output logic                                                        o_last,
    output logic                                                        o_valid
    
);

    logic   last_en;


    always_ff @(posedge clk) begin
        if(!n_rst)begin
            last_en <= 1'b0;
        end
        else if(i_last) begin
            last_en <= 1'b1;
        end
        else if(o_valid) begin
            last_en <= 1'b0;
        end
        else begin
            last_en <= last_en;
        end
    end

    always_comb begin
        o_last <= last_en &  o_valid;
    end

    
    //split y,u,v  負の数がいるかどうか
    logic signed [MCU_SIZE-1:0][MCU_SIZE-1:0][YUV_BITWIDTH-1:0] mcu_y;
    logic signed [MCU_SIZE-1:0][MCU_SIZE-1:0][YUV_BITWIDTH-1:0] mcu_u; 
    logic signed [MCU_SIZE-1:0][MCU_SIZE-1:0][YUV_BITWIDTH-1:0] mcu_v;
    // logic signed [MCU_SIZE-1:0][MCU_SIZE-1:0][YUV_BITWIDTH:0] mcu_y; 
    // logic signed [MCU_SIZE-1:0][MCU_SIZE-1:0][YUV_BITWIDTH:0] mcu_u; 
    // logic signed [MCU_SIZE-1:0][MCU_SIZE-1:0][YUV_BITWIDTH:0] mcu_v;

    int i,j;
    always_comb begin
        for(i=0;i<MCU_SIZE;i++) begin
            for(j=0;j<MCU_SIZE;j++) begin
                // mcu_y[i][j] = {1'b0,i_mcu[i][j][PIXEL_BITWIDTH-1 -:YUV_BITWIDTH]};
                // mcu_u[i][j] = {1'b0,i_mcu[i][j][(PIXEL_BITWIDTH-YUV_BITWIDTH-1)-:YUV_BITWIDTH]};
                // mcu_v[i][j] = {1'b0,i_mcu[i][j][YUV_BITWIDTH-1:0]};
                mcu_y[i][j] = i_mcu[i][j][PIXEL_BITWIDTH-1 -:YUV_BITWIDTH];
                mcu_u[i][j] = i_mcu[i][j][(PIXEL_BITWIDTH-YUV_BITWIDTH-1)-:YUV_BITWIDTH];
                mcu_v[i][j] = i_mcu[i][j][YUV_BITWIDTH-1:0];

            end
        end
    end


    wire [2:0] ready;
    always_comb begin
        o_ready = ready[0] & ready[1] & ready[2];
    end

    wire [2:0] valid;
    always_comb begin
        o_valid = valid[0] & valid[1] & valid[2];
    end

    dct_calculator
    #(
        .MCU_SIZE(MCU_SIZE),
        .YUV_BITWIDTH(YUV_BITWIDTH),
        // .YUV_BITWIDTH(YUV_BITWIDTH+1),
        .OUT_BITWIDTH(OUT_BITWIDTH)
    )
    y_dct_calculator_inst
    (
        .clk(clk),
        .n_rst(n_rst),
        .i_start(i_start),
        .i_mcu(mcu_y),
        .i_wait(i_wait),
        .o_ready(ready[0]),
        .o_dct(o_y),
        .o_valid(valid[0])
        
    );

    dct_calculator
    #(
        .MCU_SIZE(MCU_SIZE),
        .YUV_BITWIDTH(YUV_BITWIDTH),
        // .YUV_BITWIDTH(YUV_BITWIDTH+1),
        .OUT_BITWIDTH(OUT_BITWIDTH)
    )
    u_dct_calculator_inst
    (
        .clk(clk),
        .n_rst(n_rst),
        .i_start(i_start),
        .i_mcu(mcu_u),
        .i_wait(i_wait),
        .o_ready(ready[1]),
        .o_dct(o_u),
        .o_valid(valid[1])
        
    );

    dct_calculator
    #(
        .MCU_SIZE(MCU_SIZE),
        .YUV_BITWIDTH(YUV_BITWIDTH),
        // .YUV_BITWIDTH(YUV_BITWIDTH+1),
        .OUT_BITWIDTH(OUT_BITWIDTH)
    )
    v_dct_calculator_inst
    (
        .clk(clk),
        .n_rst(n_rst),
        .i_start(i_start),
        .i_mcu(mcu_v),
        .i_wait(i_wait),
        .o_ready(ready[2]),
        .o_dct(o_v),
        .o_valid(valid[2])
        
    );
endmodule

`default_nettype wire
