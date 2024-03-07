`default_nettype none

//ジグザグスキャンされたMCU配列の最後の非ゼロ成分を探索し，その配列番号を出力
//$clog2(MCU_SIZE*MCU_SIZE) クロックで探索完了
module ac_non_zero_scanner#(

    parameter int MCU_SIZE = -1,
    parameter int IDATA_BITWIDTH = 100,
    parameter int IDATA_REGSIZE = MCU_SIZE * MCU_SIZE,
    //parameter int ODATA_BITWIDTH  = $clog2(IDATA_REGSIZE) +1
    parameter int ODATA_BITWIDTH = 4
)
(
    input wire                                                      clk,
    input wire                                                      n_rst,
    input wire [IDATA_REGSIZE-1:0][IDATA_BITWIDTH-1:0]              i_data,
    input wire                                                      i_start,
    output wire [ODATA_BITWIDTH-1:0]                                o_data,
    output wire                                                     o_valid
);

    //REGSIZE以上の，最小の2のべき乗
    localparam int                                                  STAGE_0_REGSIZE = (1<<(ODATA_BITWIDTH+1));           
    //パイプライン1段目のレジスタ数
    localparam int                                                  STAGE_1_REGSIZE = STAGE_0_REGSIZE >> 1;       
    //パイプラインのレジスタ数を減らすため，1段めより小さいサイズに
    localparam int                                                  STAGE_I_REGSIZE = STAGE_1_REGSIZE >> 1;          
    localparam int                                                  PIPE_DEPTH = ODATA_BITWIDTH;
    
    logic [STAGE_0_REGSIZE-1:0] [IDATA_BITWIDTH-1:0]                 pipe_stage_0;//IDATA_REGSIZEが２のべき乗ではないとき，０を補完
    logic [STAGE_1_REGSIZE-1:0][ODATA_BITWIDTH-1:0]                  pipe_stage_1;//パイプライン1段目のレジスタ
    logic [PIPE_DEPTH-2:0][STAGE_I_REGSIZE-1:0][ODATA_BITWIDTH-1:0]  pipe_stage_i;//パイプライン2段目以降のレジスタ    
    logic [PIPE_DEPTH-1:0]                                           proc_shift_reg;  //スタートフラグのシフトレジスタ


    //出力データ
    assign o_data = pipe_stage_i[PIPE_DEPTH-2][0];
    //処理完了フラグ
    assign o_valid = proc_shift_reg[PIPE_DEPTH-1];

    int k;
    //パイプライン0段目(ゼロを補完)
    always_comb begin
        for(k = 0;k < STAGE_0_REGSIZE;k++) begin
            if(k < IDATA_REGSIZE) begin
                pipe_stage_0[k] <= i_data[k];
            end
            else begin
                pipe_stage_0[k] <= IDATA_BITWIDTH'('d0);
            end
        end
    end

    always_ff @(posedge clk) begin
        if(!n_rst) begin
            proc_shift_reg <= PIPE_DEPTH'('d0);
        end
        else begin
            proc_shift_reg <= {proc_shift_reg[PIPE_DEPTH-2:0],i_start};
        end
    end

    genvar i,j;
    generate
        for(i = 0; i < PIPE_DEPTH;i ++ )begin        
            localparam int STAGE_I_VARID_REGSIZE = STAGE_1_REGSIZE >> i;

            //1段目
            if(i == 0) begin
                for(j = 0;j < STAGE_1_REGSIZE;j++) begin
                    localparam int STAGE_PREV_UPPER = j * 2 + 1;
                    localparam int STAGE_PREV_LOWER = j * 2 ;

                    always_ff @(posedge clk) begin
                        if(!n_rst) begin
                            pipe_stage_1[j] <= ODATA_BITWIDTH'('d0);
                        end
                        else if(pipe_stage_0[STAGE_PREV_UPPER] != IDATA_BITWIDTH'('d0)) begin
                            pipe_stage_1[j] <= STAGE_PREV_UPPER;
                        end
                        else if(pipe_stage_0[STAGE_PREV_LOWER] != IDATA_BITWIDTH'('d0)) begin
                            pipe_stage_1[j] <= STAGE_PREV_LOWER;
                        end
                        else begin
                            pipe_stage_1[j] <= ODATA_BITWIDTH'('d0);
                        end
                    end
                end
            end 


            else begin
                for(j = 0;j < STAGE_I_REGSIZE;j++) begin
                    localparam int STAGE_PREV_UPPER = j * 2 + 1;
                    localparam int STAGE_PREV_LOWER = j * 2 ;

                    //2段目
                    if(i == 1) begin
                        if(j < STAGE_I_VARID_REGSIZE) begin
                            always_ff @(posedge clk) begin
                                if(!n_rst) begin
                                    pipe_stage_i[i-1][j] <= ODATA_BITWIDTH'('d0);
                                end
                                else if(pipe_stage_1[STAGE_PREV_UPPER] > pipe_stage_1[STAGE_PREV_LOWER])begin
                                    pipe_stage_i[i-1][j] <= pipe_stage_1[STAGE_PREV_UPPER];
                                end
                                else begin
                                    pipe_stage_i[i-1][j] <= pipe_stage_1[STAGE_PREV_LOWER];
                                end
                            end
                        end
                        else begin
                            always_ff @(posedge clk) begin
                                pipe_stage_i[i-1][j] <= ODATA_BITWIDTH'('d0);
                            end
                        end

                    end

                    //それ以降
                    else begin
                        if(j < STAGE_I_VARID_REGSIZE) begin
                            always_ff @(posedge clk) begin
                                if(!n_rst) begin
                                    pipe_stage_i[i-1][j] <= ODATA_BITWIDTH'('d0);
                                end
                                else if(pipe_stage_i[i-2][STAGE_PREV_UPPER] > pipe_stage_i[i-2][STAGE_PREV_LOWER])begin
                                    pipe_stage_i[i-1][j] <= pipe_stage_i[i-2][STAGE_PREV_UPPER];
                                end
                                else begin
                                    pipe_stage_i[i-1][j] <= pipe_stage_i[i-2][STAGE_PREV_LOWER];
                                end
                            end                    
                        end
                        else begin
                            always_ff @(posedge clk) begin
                                pipe_stage_i[i-1][j] <= ODATA_BITWIDTH'('d0);
                            end
                        end
                    end
                end
            end
        end
    endgenerate

endmodule




`default_nettype wire

