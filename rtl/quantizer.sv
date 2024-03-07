`default_nettype none

module quantizer
#(
    parameter int MCU_SIZE = -1,
    parameter int DCT_BITWIDTH = -1,
    parameter int QUAN_BITWIDTH = -1
)
(
    input wire clk,
    input wire n_rst,
    input wire signed [MCU_SIZE-1:0][MCU_SIZE-1:0][DCT_BITWIDTH-1:0]   dct_data,
    input wire signed [MCU_SIZE-1:0][MCU_SIZE-1:0][QUAN_BITWIDTH-1:0]  quan_table,
    input wire                                                         i_wait,
    output logic signed [MCU_SIZE-1:0][MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] quan_data
);              
    
    localparam int FIXED_BITWIDTH = DCT_BITWIDTH + QUAN_BITWIDTH;

    logic [MCU_SIZE-1:0][MCU_SIZE-1:0][FIXED_BITWIDTH-1:0] quan_data_fixed;


    genvar i,j;
    generate
        for(i=0;i<MCU_SIZE;i++) begin
            for(j=0;j<MCU_SIZE;j++) begin

                always_ff @(posedge clk) begin
                    if(!n_rst) begin
                        quan_data_fixed[i][j] <= {FIXED_BITWIDTH{1'b0}};
                    end
                    if(i_wait) begin
                        quan_data_fixed[i][j] <= quan_data_fixed[i][j];
                    end
                    else begin
                        //quan_data_fixed[i][j] <= (FIXED_BITWIDTH)'(signed'(dct_data[i][j])) * (FIXED_BITWIDTH)'(signed'(quan_table[i][j]));
                        quan_data_fixed[i][j] <= (FIXED_BITWIDTH)'(signed'(dct_data[i][j])) * (quan_table[i][j]);
                    end
                end



                always_ff @(posedge clk) begin
                    if(!n_rst) begin
                        quan_data[i][j] <= {QUAN_BITWIDTH{1'b0}};
                    end
                    else if(i_wait) begin
                        quan_data[i][j] <= quan_data[i][j];
                    end
                    else begin
                        //round down
                        // quan_data[i][j] <= (quan_data_fixed[i][j][FIXED_BITWIDTH-1]) ? quan_data_fixed[i][j][FIXED_BITWIDTH-1 -: QUAN_BITWIDTH]+'b1 :
                        //                  quan_data_fixed[i][j][FIXED_BITWIDTH-1 -: QUAN_BITWIDTH];
                        quan_data[i][j] <= (quan_data_fixed[i][j][FIXED_BITWIDTH-1]) ? quan_data_fixed[i][j][QUAN_BITWIDTH +: QUAN_BITWIDTH]+'b1 :
                                         quan_data_fixed[i][j][QUAN_BITWIDTH +: QUAN_BITWIDTH];
                    end
                end

            end 
        end

    endgenerate


endmodule
`default_nettype wire