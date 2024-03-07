`default_nettype none

module zigzag_scan
#(
    parameter int MCU_SIZE = -1,
    parameter int QUAN_BITWIDTH = -1
)
(
    input wire                                                 clk,
    input wire                                                 n_rst,
    input wire                                                 idata_en,
    input wire [MCU_SIZE-1:0][MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] i_quan_y,
    input wire [MCU_SIZE-1:0][MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] i_quan_u,
    input wire [MCU_SIZE-1:0][MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] i_quan_v,
    input wire                                                 i_last,
    input wire                                                 i_wait,
    output logic [MCU_SIZE*MCU_SIZE-1:0][QUAN_BITWIDTH-1:0]    o_zig_y,
    output logic [MCU_SIZE*MCU_SIZE-1:0][QUAN_BITWIDTH-1:0]    o_zig_u,
    output logic [MCU_SIZE*MCU_SIZE-1:0][QUAN_BITWIDTH-1:0]    o_zig_v,
    output logic                                               o_last,
    output logic                                               o_data_valid
    
);

    localparam int ZIGZAG_INDEX[0:7][0:7] = '{
        '{0, 1, 5, 6, 14, 15, 27, 28},
        '{2, 4, 7, 13, 16, 26, 29, 42},
        '{3, 8, 12, 17, 25, 30, 41, 43},
        '{9, 11, 18, 24, 31, 40, 44, 53},
        '{10, 19, 23, 32, 39, 45, 52, 54},
        '{20, 22, 33, 38, 46, 51, 55, 60},
        '{21, 34, 37, 47, 50, 56, 59, 61},
        '{35, 36, 48, 49, 57, 58, 62, 63}
    };

    logic[MCU_SIZE*MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] quan_y_1d;
    logic[MCU_SIZE*MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] quan_u_1d;
    logic[MCU_SIZE*MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] quan_v_1d;


    genvar i,j;
    generate
        for(i=0;i<MCU_SIZE;i++) begin
            for(j=0;j<MCU_SIZE;j++) begin

                assign quan_y_1d[i*MCU_SIZE+j] = i_quan_y[i][j]; 
                assign quan_u_1d[i*MCU_SIZE+j] = i_quan_u[i][j]; 
                assign quan_v_1d[i*MCU_SIZE+j] = i_quan_v[i][j]; 


                always_ff @(posedge clk) begin
                    if(!n_rst) begin
                        o_zig_y[ZIGZAG_INDEX[i][j]] <= {QUAN_BITWIDTH{1'b1}};
                        o_zig_u[ZIGZAG_INDEX[i][j]] <= {QUAN_BITWIDTH{1'b1}};
                        o_zig_v[ZIGZAG_INDEX[i][j]] <= {QUAN_BITWIDTH{1'b1}};
                    end
                    else if(i_wait) begin
                        o_zig_y[ZIGZAG_INDEX[i][j]] <= o_zig_y[ZIGZAG_INDEX[i][j]];
                        o_zig_u[ZIGZAG_INDEX[i][j]] <= o_zig_u[ZIGZAG_INDEX[i][j]];
                        o_zig_v[ZIGZAG_INDEX[i][j]] <= o_zig_v[ZIGZAG_INDEX[i][j]];
                    end
                    else begin
                        // zig_y[i*MCU_SIZE+j] <= quan_y_1d[ZIGZAG_INDEX[i][j]];
                        // zig_u[i*MCU_SIZE+j] <= quan_u_1d[ZIGZAG_INDEX[i][j]];
                        // zig_v[i*MCU_SIZE+j] <= quan_v_1d[ZIGZAG_INDEX[i][j]];
                        o_zig_y[ZIGZAG_INDEX[i][j]] <= quan_y_1d[i*MCU_SIZE+j];
                        o_zig_u[ZIGZAG_INDEX[i][j]] <= quan_u_1d[i*MCU_SIZE+j];
                        o_zig_v[ZIGZAG_INDEX[i][j]] <= quan_v_1d[i*MCU_SIZE+j];

                    end
                end


            end 
        end
        
    endgenerate


    always_ff @(posedge clk) begin
        if(!n_rst) begin
            o_data_valid <= 1'b0;
        end
        else if(i_wait) begin
            o_data_valid <= o_data_valid;
        end
        else begin
            o_data_valid <= idata_en;
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
            o_last <= i_last;
        end
    end


endmodule

`default_nettype wire