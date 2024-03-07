`default_nettype none

module huffman_encoder#(
    parameter int MCU_SIZE = -1,
    parameter int DATA_BITWIDTH = -1,
    //parameter int ODATA_BITWIDTH = 8,
    parameter int DC_VVEC_SIZE = -1,
    parameter int AC_VVEC_SIZE = -1,
    parameter [2:0] COMP_Y = 001,
    parameter [2:0] COMP_U = 010,
    parameter [2:0] COMP_V = 100
)

(
    input  wire                                              clk,
    input  wire                                              n_rst,
    input  wire [15:0]                                       i_dc_huffcode_table[DC_VVEC_SIZE-1:0],
    input  wire [7:0]                                        i_dc_hufflength_table[DC_VVEC_SIZE-1:0],
    input  wire [15:0]                                       i_ac_huffcode_table[15:0][9:0],
    input  wire [7:0]                                        i_ac_hufflength_table[15:0][9:0],
    input  wire [15:0]                                       i_eob,
    input  wire [7:0]                                        i_eob_len,
    input  wire [15:0]                                       i_zrl,
    input  wire [7:0]                                        i_zrl_len,
    input  wire                                              i_start,
    input  wire                                              i_wait,
    input  wire [2:0]                                        i_comp,
    input  wire [MCU_SIZE*MCU_SIZE-1:0][DATA_BITWIDTH-1:0]   i_data,
    input  wire                                              i_r_en,
    output wire                                              o_done,
    output logic                                             o_valid,
    output logic [7:0]                                       o_data
);


//--------------------------------------------------------------------------------------------
// Signal Declarations : start
//--------------------------------------------------------------------------------------------

    //---------------------------bit buffer Signal Declarations-------------------------------
    logic         [15:0]                                     bit_buff_idata;
    logic         [7:0]                                      bit_buff_wlength;
    logic                                                    bit_buff_w_en;
    logic                                                    bit_buff_busy;
    logic                                                    bit_buff_busy_prev;
    logic                                                    bit_buff_done;
    //----------------------------------------------------------------------------------------

    //------------------------------state Signal Declarations---------------------------------
    logic         [3:0]                                      state;
    localparam    [3:0]                                      STATE_READY    = 4'b0000;
    localparam    [3:0]                                      STATE_DC       = 4'b0001;
    localparam    [3:0]                                      STATE_AC_READY = 4'b0010;
    localparam    [3:0]                                      STATE_AC       = 4'b0100;
    //----------------------------------------------------------------------------------------

    //--------------------------------DC Signal Declarations----------------------------------
    localparam    [1:0]                                      DC_STATE_CODE  = 2'b01;
    localparam    [1:0]                                      DC_STATE_VALUE = 2'b10;
    logic         [1:0]                                      dc_state;
    logic                                                    dc_finish;
    logic         [15:0]                                     dc_wdata;
    logic         [7:0]                                      dc_wlength;
    logic                                                    dc_w_en;
    logic signed  [DATA_BITWIDTH-1:0]                        dc_y_prev;
    logic signed  [DATA_BITWIDTH-1:0]                        dc_u_prev;
    logic signed  [DATA_BITWIDTH-1:0]                        dc_v_prev;
    logic signed  [DATA_BITWIDTH-1:0]                        dc_data_prev;
    logic signed  [DATA_BITWIDTH-1:0]                        dc_diff;        //1個前のy_dcuと現在のy_dcuy_dc成分の差
    logic         [DATA_BITWIDTH-1:0]                        dc_diff_abs;    //差の絶対値
    logic         [4:0]                                      dc_category;    
    logic         [15:0]                                     dc_huffcode;
    logic         [7:0]                                      dc_hufflength;
    logic         [DATA_BITWIDTH-1:0]                        dc_value;
    logic         [4:0]                                      dc_valuelength;
    //---------------------------------------------------------------------------------------

    //----------------------------------AC Signal Declarations-------------------------------
    localparam    int                                        NON_ZERO_BITWIDTH = $clog2(MCU_SIZE * MCU_SIZE)+1;
    wire          [NON_ZERO_BITWIDTH-1:0]                    ac_non_zero;
    wire                                                     non_zero_valid;
    logic [NON_ZERO_BITWIDTH-1:0]                            ac_non_zero_reg;
    logic                                                    ac_ready;

    localparam    int                                        AC_SIZE = MCU_SIZE * MCU_SIZE - 1;
    localparam    int                                        AC_COUNT_SIZE = $clog2(AC_SIZE);
    localparam    int                                        AC_STATE_READY =  3'b001;
    localparam    int                                        AC_STATE_CODE =  3'b010;
    localparam    int                                        AC_STATE_VALUE =  3'b100;
    logic         [2:0]                                      ac_state;
    logic         [2:0]                                      ac_state_prev;

    logic                                                    ac_ready_prev;
    logic                                                    dc_finish_reg;
    logic                                                    ac_start;

    logic         [AC_COUNT_SIZE:0]                          ac_count;
    logic                                                    max_ac_count;
    logic         [4:0]                                      ac_zerocount;         
    logic                                                    max_ac_zerocount;
    logic                                                    ac_next_flag;

    logic                                                    ac_w_en;
    logic                                                    ac_w_en_prev;
    logic         [15:0]                                     ac_wdata;
    logic         [7:0]                                      ac_wlength;

    logic         [15:0]                                     ac_huffcode;
    logic         [7:0]                                      ac_hufflength;
    logic         [4:0]                                      ac_category;
    logic         [15:0]                                     ac_target;    
    logic         [DATA_BITWIDTH-1:0]                        ac_next_target;    
    logic         [15:0]                                     ac_value;
    logic         [DATA_BITWIDTH-1:0]                        ac_target_abs;
    logic         [7:0]                                      ac_value_length;

    logic                                                    ac_finish;
    //----------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------
// AC Signal Declarations : end
//--------------------------------------------------------------------------------------------




//--------------------------------------------------------------------------------------------
// bit buffer : start
//--------------------------------------------------------------------------------------------
    bit_buffer
    buff_inst(
        .clk(clk),
        .n_rst(n_rst),
        .i_w_en(bit_buff_w_en),
        .i_data(bit_buff_idata),
        .i_datalength(bit_buff_wlength),
        .i_r_en(i_r_en),
        .i_wait(i_wait),
        .o_data(o_data),
        .o_valid(o_valid),
        .o_busy(bit_buff_busy)
    );

    always_ff @(posedge clk) begin
        if(!n_rst) begin
            bit_buff_busy_prev <= 1'b0;
        end
        else if(i_wait) begin
            bit_buff_busy_prev <= bit_buff_busy_prev;
        end
        else begin
            bit_buff_busy_prev <= bit_buff_busy;
        end
    end

    //negedge detection
    always_comb begin
        bit_buff_done = bit_buff_busy_prev &  !bit_buff_busy;
    end
//--------------------------------------------------------------------------------------------
// bit buffer : end
//--------------------------------------------------------------------------------------------



//--------------------------------------------------------------------------------------------
// state : start
//--------------------------------------------------------------------------------------------

    always_ff@(posedge clk) begin
        if(!n_rst) begin
            state <= 3'b0;
        end
        else if(i_wait) begin
            state <= state;
        end
        else begin
              case(state)
                STATE_READY : 
                    if(i_start) begin
                        state <= STATE_DC;
                    end
                    else begin
                        state <= STATE_READY;
                    end
      
                STATE_DC : 
                    if(dc_finish) begin
                        state <= STATE_AC;
                    end
                    else begin
                        state <= STATE_DC;
                    end
                STATE_AC       :
                    if(ac_finish) begin
                        state <= STATE_READY;
                    end
                    else begin
                        state <= STATE_AC;
                    end
                default        :
                    state <= state;
            endcase
        end
    end

    assign o_done = ac_finish;


    always_comb begin
        case(state)
        STATE_READY : begin
            bit_buff_idata   = 16'd0;
            bit_buff_wlength = 8'd0;
            bit_buff_w_en    = 1'b0;
        end
        STATE_DC    : begin
            bit_buff_idata   = dc_wdata;
            bit_buff_wlength = dc_wlength;
            bit_buff_w_en    = dc_w_en;
        end
        STATE_AC    : begin
            bit_buff_idata   = ac_wdata;
            bit_buff_wlength = ac_wlength;
            bit_buff_w_en    = ac_w_en;
        end
        default     : begin
            bit_buff_idata   = 16'dx;
            bit_buff_wlength = 8'dx;
            bit_buff_w_en    = 1'bx;
        end
        endcase
    end
//--------------------------------------------------------------------------------------------
// state : end
//--------------------------------------------------------------------------------------------





//--------------------------------------------------------------------------------------------
//DC encode : start
//--------------------------------------------------------------------------------------------
    //DC成分符号化時の状態ステート
    always_ff @(posedge clk) begin
        if(!n_rst) begin
            dc_state <= DC_STATE_CODE;
        end
        else if(i_wait) begin
            dc_state <= dc_state;
        end
        else begin
            case(dc_state)
                DC_STATE_CODE  :
                    if((state == STATE_DC) & bit_buff_done) begin
                        dc_state <= DC_STATE_VALUE;
                    end
                    else begin
                        dc_state <= DC_STATE_CODE;
                    end
                DC_STATE_VALUE :
                    if(bit_buff_done) begin
                        dc_state <= DC_STATE_CODE;
                    end
                    else begin
                        dc_state <= DC_STATE_VALUE;
                    end
                default        :
                    dc_state <= DC_STATE_CODE;
            endcase
        end
    end

    always_comb begin
    dc_finish = dc_state[1] & bit_buff_done;
    end

    //dc成分符号化時のバッファへの書き込みイネーブル
    always_ff @(posedge clk) begin
        if(!n_rst) begin
            dc_w_en <= 1'b0;
        end
        else if(i_wait) begin
            dc_w_en <= dc_w_en;
        end
        //スタート信号が立つ
        else if((dc_state == DC_STATE_CODE) & i_start)begin
            dc_w_en <= 1'b1;
        end
        else if((dc_state == DC_STATE_CODE) & bit_buff_done)begin
            dc_w_en <= 1'b1;
        end
        else begin
            dc_w_en <= 1'b0;
        end
    end
    //dc成分符号化時のバッファへの書き込みデータ
    always_comb begin
        if(dc_state == DC_STATE_CODE) begin
            dc_wdata <= dc_huffcode;
        end
        else if(dc_state == DC_STATE_VALUE) begin
            dc_wdata <= dc_value;
        end
        else begin
            dc_wdata <= 16'd0;
        end
    end
    //dc成分符号化時のバッファへの書き込みデータ長
    always_comb begin
        if(dc_state == DC_STATE_CODE) begin
            dc_wlength <= dc_hufflength;
        end
        else if(dc_state == DC_STATE_VALUE) begin
            dc_wlength <= dc_valuelength;
        end
        else begin
            dc_wlength <= 8'd0;
        end
    end

    //dc_y_prev
    always_ff @(posedge clk) begin
        if(!n_rst) begin
            dc_y_prev <= DATA_BITWIDTH'('b0);
        end
        else if(i_wait) begin
            dc_y_prev <= dc_y_prev;
        end
        else if(dc_finish & (i_comp == COMP_Y)) begin
            dc_y_prev <= i_data[0];
        end
        else begin
            dc_y_prev <= dc_y_prev;
        end
    end

    //dc_u_prev
    always_ff @(posedge clk) begin
        if(!n_rst) begin
            dc_u_prev <= DATA_BITWIDTH'('b0);
        end
        else if(i_wait) begin
            dc_u_prev <= dc_u_prev;
        end
        else if(dc_finish & (i_comp == COMP_U)) begin
            dc_u_prev <= i_data[0];
        end
        else begin
            dc_u_prev <= dc_u_prev;
        end
    end

    //dc_v_prev
    always_ff @(posedge clk) begin
        if(!n_rst) begin
            dc_v_prev <= DATA_BITWIDTH'('b0);
        end
        else if(i_wait) begin
            dc_v_prev <= dc_v_prev;
        end

        else if(dc_finish & (i_comp == COMP_V)) begin
            dc_v_prev <= i_data[0];
        end
        else begin
            dc_v_prev <= dc_v_prev;
        end
    end

    

    //dc_data_prev
    always_comb begin
        case(i_comp) 
        COMP_Y : dc_data_prev <= dc_y_prev;
        COMP_U : dc_data_prev <= dc_u_prev;
        COMP_V : dc_data_prev <= dc_v_prev;
        default: dc_data_prev <= DATA_BITWIDTH'('b0);
        endcase
    end
    // always_ff @(posedge clk) begin
    //     if(!n_rst) begin
    //         dc_data_prev <= DATA_BITWIDTH'('b0);
    //     end
    //     else if(dc_finish)begin
    //         dc_data_prev <= i_data[0];
    //     end
    //     else begin
    //         dc_data_prev <= dc_data_prev;
    //     end
    // end

    //dc_diff 1個前のmcuとのDC成分の差
    always_comb begin
        dc_diff = i_data[0]  - dc_data_prev;
    end
    //差の絶対値
    always_comb begin
        if(dc_diff[DATA_BITWIDTH-1]) begin
            dc_diff_abs = ~(dc_diff - (DATA_BITWIDTH-1)'('b1));
        end
        else begin
            dc_diff_abs = dc_diff;
        end
    end

    //dc_category 
    always_comb begin
        dc_category = sec_category(dc_diff_abs);
    end

    //y_dc_huffcode
    always_ff @(posedge clk) begin
        if(!n_rst) begin
            dc_huffcode <= 16'd0;
        end
        else if(i_wait) begin
            dc_huffcode <= dc_huffcode;
        end
        else if(i_start)begin
            dc_huffcode <= i_dc_huffcode_table[dc_category];
        end
        else begin
            dc_huffcode <= dc_huffcode;
        end
    end

    //dc_hufflength
    always_ff @(posedge clk) begin
        if(!n_rst) begin
            dc_hufflength <= 8'd0;
        end
        else if(i_wait) begin
            dc_hufflength <= dc_hufflength;
        end
        else if(i_start)begin
            dc_hufflength <= i_dc_hufflength_table[dc_category];
        end
        else begin
            dc_hufflength <= dc_hufflength;
        end
    end    

    //dc_value
    always_ff @(posedge clk) begin
        if(!n_rst) begin
            dc_value <= DATA_BITWIDTH'('d0);
        end
        else if(i_wait) begin
            dc_value <= dc_value;
        end
        else if(i_start)begin  //1の補数
            if(dc_diff[DATA_BITWIDTH-1]) begin
                dc_value <= dc_diff-DATA_BITWIDTH'('b1);
            end
            else begin
                dc_value <= dc_diff;
            end
        end
        else begin
            dc_value <= dc_value;
        end
    end

    //dc_valuelength
    always_ff @(posedge clk) begin
        if(!n_rst) begin
            dc_valuelength <= 5'd0;
        end
        else if(i_wait) begin
            dc_valuelength <= dc_valuelength;
        end
        else begin
            dc_valuelength <= dc_category;
        end
    end

//--------------------------------------------------------------------------------------------
//DC encode block : end
//--------------------------------------------------------------------------------------------







//--------------------------------------------------------------------------------------------
//AC encode : start
//--------------------------------------------------------------------------------------------

    ac_non_zero_scanner#(
        .MCU_SIZE(MCU_SIZE),
        .IDATA_BITWIDTH(DATA_BITWIDTH),
        .ODATA_BITWIDTH(NON_ZERO_BITWIDTH)
    )
    non_zero_scanner_inst(
        .clk(clk),
        .n_rst(n_rst),
        .i_data(i_data),
        .i_start(i_start),
        .o_data(ac_non_zero),
        .o_valid(non_zero_valid)
    );

    //ジグザグ配列の最後の非ゼロ成分の要素番号
    always_ff @(posedge clk) begin
        if(!n_rst)begin
            ac_non_zero_reg <= NON_ZERO_BITWIDTH'('d0);
        end
        else if(i_wait) begin
            ac_non_zero_reg <= ac_non_zero_reg;
        end
        else if(non_zero_valid) begin
            ac_non_zero_reg <= ac_non_zero;
        end
        else begin
            ac_non_zero_reg <= ac_non_zero_reg;
        end
    end
    //ac成分計算準備完了
    always_ff @(posedge clk) begin
        if(!n_rst) begin
            ac_ready <= 1'b0;
        end
        else if(i_wait) begin
            ac_ready <= ac_ready;
        end
        else if(non_zero_valid) begin
            ac_ready <= 1'b1;
        end
        else if(ac_finish) begin
            ac_ready <= 1'b0;
        end
        else begin
            ac_ready <= ac_ready;
        end
    end


    always_ff @(posedge clk) begin
        if(!n_rst) begin
            dc_finish_reg <= 1'b0;
        end
        else if(i_wait) begin
            dc_finish_reg <= dc_finish_reg;
        end
        else if(dc_finish) begin
            dc_finish_reg <= 1'b1;
        end
        else if(ac_start) begin
            dc_finish_reg <= 1'b0;
        end
        else begin
            dc_finish_reg <= dc_finish_reg;
        end
    end

    always_comb begin
        ac_start <= ac_ready & dc_finish_reg;
    end


    always_ff @(posedge clk) begin
        if(!n_rst)begin
            ac_ready_prev <= 1'b0;
        end
        else if(i_wait) begin
            ac_ready_prev <= ac_ready_prev;
        end
        else begin
            ac_ready_prev <= ac_ready;
        end
    end


    always_ff @(posedge clk)begin
        if(!n_rst) begin
            ac_state_prev <= AC_STATE_READY;
        end
        else if(i_wait) begin
            ac_state_prev <= ac_state_prev;
        end
        else begin
            ac_state_prev <= ac_state;
        end
    end


    always_comb begin
        ac_finish = (ac_state_prev != AC_STATE_READY) && (ac_state == AC_STATE_READY);
    end


    //ac state machine
    always_ff @(posedge clk) begin
        if(!n_rst) begin
            ac_state <= AC_STATE_READY;
        end
        else if(i_wait) begin
            ac_state <= ac_state;
        end
        else begin
            case(ac_state) 
            AC_STATE_READY :
                if(ac_start) begin
                    ac_state <= AC_STATE_CODE;
                end
                else begin
                    ac_state <= AC_STATE_READY;
                end
            AC_STATE_CODE  :
                if(bit_buff_done) begin
                    if(max_ac_count | max_ac_zerocount) begin
                        ac_state <= AC_STATE_READY;
                    end
                    else begin
                        ac_state <= AC_STATE_VALUE;
                    end
                end
                else begin
                    ac_state <= AC_STATE_CODE;
                end
            AC_STATE_VALUE :
                if(bit_buff_done) begin
                    if(ac_count == AC_SIZE) begin
                        ac_state <= AC_STATE_READY;
                    end
                    else begin
                        ac_state <= AC_STATE_CODE;
                    end
                end
                else begin
                    ac_state <= AC_STATE_VALUE;
                end
            default        :
                ac_state <= 3'dx;
            endcase
        end
    end


    always_ff @(posedge clk) begin
        if(!n_rst) begin
            ac_w_en_prev <= 1'b0;
        end
        else if(i_wait) begin
            ac_w_en_prev <= ac_w_en_prev;
        end
        else begin
            ac_w_en_prev <= ac_w_en;
        end
    end

    //ac_w_en
    always_comb begin
        if(bit_buff_busy) begin
            ac_w_en = 1'b0;
        end
        else if(ac_w_en_prev | bit_buff_busy | bit_buff_done)begin
            ac_w_en = 1'b0;
        end
        else begin
            case(ac_state)
            AC_STATE_CODE  :
                ac_w_en = max_ac_count || max_ac_zerocount || (ac_target != DATA_BITWIDTH'('d0));
                // if(max_ac_count) begin
                //     ac_w_en = 1'b1;
                // end
                // else if(max_ac_zerocount) begin
                //     ac_w_en = 1'b1;
                // end
                // else if(ac_target != DATA_BITWIDTH'('d0))begin
                //     ac_w_en = 1'b1;
                // end
                // else begin
                //     ac_w_en = 1'b0;
                // end
            AC_STATE_VALUE :
                ac_w_en = 1'b1;
            default :
                ac_w_en = 1'b0;
            endcase
        end
    end



    //ac_wdata
    always_comb begin
        case(ac_state)
        AC_STATE_CODE : ac_wdata = ac_huffcode;
        AC_STATE_VALUE: ac_wdata = ac_value;
        default       : ac_wdata = 16'd0; 
        endcase
    end
    //ac_wlength
    always_comb begin
        case(ac_state)
        AC_STATE_CODE : ac_wlength = ac_hufflength;
        AC_STATE_VALUE: ac_wlength = ac_value_length;
        default       : ac_wlength = 8'd0; 
        endcase
    end



    always_comb begin
        //ac_next_flag = !ac_w_en & !bit_buff_busy;
        case(ac_state)
        AC_STATE_CODE  :
            if(!ac_w_en & !bit_buff_busy) begin
                if(max_ac_zerocount | max_ac_count | (ac_target != DATA_BITWIDTH'('d0))) begin
                    ac_next_flag = 1'b0;
                end
                else begin
                    ac_next_flag = 1'b1;
                end
            end
            else begin
                ac_next_flag = 1'b0;
            end
        AC_STATE_VALUE :
            ac_next_flag = !ac_w_en & !bit_buff_busy;
        default:
            ac_next_flag = 1'b0;
        endcase
    end


    always_comb begin
        max_ac_count = (ac_count == (ac_non_zero_reg + 1)); 
    end
    always_ff @(posedge clk) begin
        if(!n_rst) begin
            ac_count <= AC_COUNT_SIZE'('d0);
        end
        else if(i_wait) begin
            ac_count <= ac_count;
        end
        else if(ac_count == AC_COUNT_SIZE'('d0))begin
            if(ac_start) begin
                ac_count <= AC_COUNT_SIZE'('d1);
            end
            else begin
                ac_count <= AC_COUNT_SIZE'('d0);
            end
        end
        else if(ac_finish) begin
            ac_count <= AC_COUNT_SIZE'('d0);
        end
        else if(ac_next_flag) begin
            if(max_ac_count)begin
                ac_count <= AC_COUNT_SIZE'('d0);
            end
            else begin
                ac_count <= ac_count + AC_COUNT_SIZE'('d1);
            end
        end
        else begin
            ac_count <= ac_count;
        end
    end


    always_comb begin
        max_ac_zerocount = (ac_zerocount == 5'd15);
    end

    //ゼロカウント
    always_ff @(posedge clk) begin
        if(!n_rst) begin
            ac_zerocount <= 5'd0;
        end
        else if(i_wait) begin
            ac_zerocount <= ac_zerocount;
        end
        else if( (ac_start | ac_next_flag) & !ac_finish) begin
            if((ac_target == DATA_BITWIDTH'('d0)) & !max_ac_zerocount) begin
                ac_zerocount <= ac_zerocount + 5'd1;
            end
            else begin
                ac_zerocount <= 5'd0;
            end
        end
        else begin
            ac_zerocount <= 5'd0;
        end
    end



    always_comb begin
        //ac_target = i_data[ac_count + AC_COUNT_SIZE'('d1)];
        ac_target = i_data[ac_count];
    end

    //ac_target ac_next_target
    always_comb begin
        if(ac_count == AC_COUNT_SIZE) begin
            ac_next_target = 16'd0;
        end
        else begin
            ac_next_target = i_data[ac_count+1];
        end
    end

    //ac_target_abs
    always_comb begin
        if(ac_target[DATA_BITWIDTH-1]) begin
            ac_target_abs = ~(ac_target - (DATA_BITWIDTH-1)'('b1));
        end
        else begin
            ac_target_abs = ac_target;
        end
    end 

    //ac_category
    always_comb begin
        ac_category = sec_category(ac_target_abs);
    end


   always_comb begin
        //if(ac_count== (ac_non_zero_reg+1)) begin
        if(max_ac_count) begin
            ac_huffcode = i_eob;
        end
        else if(max_ac_zerocount) begin
            ac_huffcode = i_zrl;
        end
        else begin
            case(ac_zerocount)
                5'd0    : ac_huffcode = sec_ac_huffcode(i_ac_huffcode_table[0],ac_category);
                5'd1    : ac_huffcode = sec_ac_huffcode(i_ac_huffcode_table[1],ac_category);
                5'd2    : ac_huffcode = sec_ac_huffcode(i_ac_huffcode_table[2],ac_category);
                5'd3    : ac_huffcode = sec_ac_huffcode(i_ac_huffcode_table[3],ac_category);
                5'd4    : ac_huffcode = sec_ac_huffcode(i_ac_huffcode_table[4],ac_category);
                5'd5    : ac_huffcode = sec_ac_huffcode(i_ac_huffcode_table[5],ac_category);
                5'd6    : ac_huffcode = sec_ac_huffcode(i_ac_huffcode_table[6],ac_category);
                5'd7    : ac_huffcode = sec_ac_huffcode(i_ac_huffcode_table[7],ac_category);
                5'd8    : ac_huffcode = sec_ac_huffcode(i_ac_huffcode_table[8],ac_category);
                5'd9    : ac_huffcode = sec_ac_huffcode(i_ac_huffcode_table[9],ac_category);
                5'd10   : ac_huffcode = sec_ac_huffcode(i_ac_huffcode_table[10],ac_category);
                5'd11   : ac_huffcode = sec_ac_huffcode(i_ac_huffcode_table[11],ac_category);
                5'd12   : ac_huffcode = sec_ac_huffcode(i_ac_huffcode_table[12],ac_category);
                5'd13   : ac_huffcode = sec_ac_huffcode(i_ac_huffcode_table[13],ac_category);
                5'd14   : ac_huffcode = sec_ac_huffcode(i_ac_huffcode_table[14],ac_category);
                5'd15   : ac_huffcode = sec_ac_huffcode(i_ac_huffcode_table[15],ac_category);
                default : ac_huffcode = sec_ac_huffcode(i_ac_huffcode_table[15],ac_category);
            endcase
        end
    end

    always_comb begin
        if(ac_count== (ac_non_zero_reg+1)) begin
            ac_hufflength = i_eob_len;
        end
        else if(max_ac_zerocount) begin
            ac_hufflength = i_zrl_len;
        end
        else begin
            case(ac_zerocount)
                5'd0    : ac_hufflength = sec_ac_hufflength(i_ac_hufflength_table[0],ac_category);
                5'd1    : ac_hufflength = sec_ac_hufflength(i_ac_hufflength_table[1],ac_category);
                5'd2    : ac_hufflength = sec_ac_hufflength(i_ac_hufflength_table[2],ac_category);
                5'd3    : ac_hufflength = sec_ac_hufflength(i_ac_hufflength_table[3],ac_category);
                5'd4    : ac_hufflength = sec_ac_hufflength(i_ac_hufflength_table[4],ac_category);
                5'd5    : ac_hufflength = sec_ac_hufflength(i_ac_hufflength_table[5],ac_category);
                5'd6    : ac_hufflength = sec_ac_hufflength(i_ac_hufflength_table[6],ac_category);
                5'd7    : ac_hufflength = sec_ac_hufflength(i_ac_hufflength_table[7],ac_category);
                5'd8    : ac_hufflength = sec_ac_hufflength(i_ac_hufflength_table[8],ac_category);
                5'd9    : ac_hufflength = sec_ac_hufflength(i_ac_hufflength_table[9],ac_category);
                5'd10   : ac_hufflength = sec_ac_hufflength(i_ac_hufflength_table[10],ac_category);
                5'd11   : ac_hufflength = sec_ac_hufflength(i_ac_hufflength_table[11],ac_category);
                5'd12   : ac_hufflength = sec_ac_hufflength(i_ac_hufflength_table[12],ac_category);
                5'd13   : ac_hufflength = sec_ac_hufflength(i_ac_hufflength_table[13],ac_category);
                5'd14   : ac_hufflength = sec_ac_hufflength(i_ac_hufflength_table[14],ac_category);
                5'd15   : ac_hufflength = sec_ac_hufflength(i_ac_hufflength_table[15],ac_category);
                default : ac_hufflength = sec_ac_hufflength(i_ac_hufflength_table[15],ac_category);
            endcase
        end
    end

    always_comb begin
         //1の補数
        if(ac_target[DATA_BITWIDTH-1]) begin
            ac_value = ac_target-DATA_BITWIDTH'('b1);
        end
        else begin
            ac_value = ac_target;
        end
    end

    always_comb begin
        ac_value_length = sec_category(ac_value);
    end


//--------------------------------------------------------------------------------------------
//AC encode : end
//--------------------------------------------------------------------------------------------





//--------------------------------------------------------------------------------------------
//function : start
//--------------------------------------------------------------------------------------------

    function [15:0] sec_ac_huffcode(
        input [15:0] huffcode_table[9:0],
        input [4:0] ac_category
    );
        case(ac_category)
            5'd1:  sec_ac_huffcode = huffcode_table[0];
            5'd2:  sec_ac_huffcode = huffcode_table[1];
            5'd3:  sec_ac_huffcode = huffcode_table[2];
            5'd4:  sec_ac_huffcode = huffcode_table[3];
            5'd5:  sec_ac_huffcode = huffcode_table[4];
            5'd6:  sec_ac_huffcode = huffcode_table[5];
            5'd7:  sec_ac_huffcode = huffcode_table[6];
            5'd8:  sec_ac_huffcode = huffcode_table[7];
            5'd9:  sec_ac_huffcode = huffcode_table[8];
            5'd10: sec_ac_huffcode = huffcode_table[9];
            default: sec_ac_huffcode = huffcode_table[9];
        endcase
    endfunction

    function [7:0] sec_ac_hufflength(
        input [7:0] hufflength_table[9:0],
        input [4:0] ac_category
    );
        case(ac_category)
            5'd1   : sec_ac_hufflength = hufflength_table[0];
            5'd2   : sec_ac_hufflength = hufflength_table[1];
            5'd3   : sec_ac_hufflength = hufflength_table[2];
            5'd4   : sec_ac_hufflength = hufflength_table[3];
            5'd5   : sec_ac_hufflength = hufflength_table[4];
            5'd6   : sec_ac_hufflength = hufflength_table[5];
            5'd7   : sec_ac_hufflength = hufflength_table[6];
            5'd8   : sec_ac_hufflength = hufflength_table[7];
            5'd9   : sec_ac_hufflength = hufflength_table[8];
            5'd10  : sec_ac_hufflength = hufflength_table[9];
            default: sec_ac_hufflength = hufflength_table[9];
        endcase
    endfunction


    function [4:0] sec_category(
         input [DATA_BITWIDTH-1:0]value
     );
         // 0
         if(value == DATA_BITWIDTH'('d0)) begin
             sec_category = 5'd0;
         end
         //1
         else if(value == DATA_BITWIDTH'('d1)) begin
             sec_category = 5'd1;
         end
         // 2~3
         else if( (DATA_BITWIDTH'('d2) <= value)  && (value <= DATA_BITWIDTH'('d3) )  ) begin
             sec_category = 5'd2;
         end
         //3~7
         else if( (DATA_BITWIDTH'('d4) <= value)  && (value <= DATA_BITWIDTH'('d7))  ) begin
             sec_category = 5'd3;
         end
         //8~15
         else if( (DATA_BITWIDTH'('d8) <= value)  && (value <= DATA_BITWIDTH'('d15))  ) begin
             sec_category = 5'd4;
         end
         //16~31
         else if( (DATA_BITWIDTH'('d16) <= value)  && (value <= DATA_BITWIDTH'('d31))  ) begin
             sec_category = 5'd5;
         end
         //32~63
         else if( (DATA_BITWIDTH'('d32) <= value)  && (value <= DATA_BITWIDTH'('d63))  ) begin
             sec_category = 5'd6;
         end
        //64~127
         else if( (DATA_BITWIDTH'('d64) <= value)  && (value <= DATA_BITWIDTH'('d127))  ) begin
             sec_category = 5'd7;
         end
         //128~255
         else if( (DATA_BITWIDTH'('d128) <= value)  && (value <= DATA_BITWIDTH'('d255))  ) begin
             sec_category = 5'd8;
         end
          //256~511
         else if( (DATA_BITWIDTH'('d256) <= value)  && (value <= DATA_BITWIDTH'('d511))  ) begin
             sec_category = 5'd9;
         end
         //512~1023
         else if( (DATA_BITWIDTH'('d512) <= value)  && (value <= DATA_BITWIDTH'('d1023))  ) begin
             sec_category = 5'd10;
         end
         //1024~2047
         else if( (DATA_BITWIDTH'('d1024) <= value)  && (value <= DATA_BITWIDTH'('d2047))  ) begin
             sec_category = 5'd11;
         end        
         else begin
             sec_category = 5'd11;
         end
     endfunction
//--------------------------------------------------------------------------------------------
//function : end
//--------------------------------------------------------------------------------------------




endmodule


`default_nettype wire
