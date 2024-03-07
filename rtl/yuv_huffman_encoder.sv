
`default_nettype none

module yuv_huffman_encoder#(
    parameter int MCU_SIZE = -1,
    parameter int DATA_BITWIDTH = -1,
    //parameter int ODATA_BITWIDTH = -1,
    parameter int DC_VVEC_SIZE = -1
)
(
    input wire                                            clk,
    input wire                                            n_rst,
    dht_if.slave                                          dhtif,
    input wire [MCU_SIZE*MCU_SIZE-1:0][DATA_BITWIDTH-1:0] i_mcu_y,
    input wire [MCU_SIZE*MCU_SIZE-1:0][DATA_BITWIDTH-1:0] i_mcu_u,
    input wire [MCU_SIZE*MCU_SIZE-1:0][DATA_BITWIDTH-1:0] i_mcu_v,
    input wire                                            i_send_ready, 
    input wire                                            i_start,
    input wire                                            i_wait,
    input wire                                            i_data_end,
    output logic                                           o_ready,
    output wire                                           o_done,
    output wire [7:0]                                     o_data,
    output logic                                           o_last,
    output wire                                           o_valid
);

    localparam [3:0]  STATE_READY = 4'b0001;
    localparam [3:0]  STATE_Y     = 4'b0010;
    localparam [3:0]  STATE_U     = 4'b0100;
    localparam [3:0]  STATE_V     = 4'b1000;

    localparam [2:0]  COMP_Y      = 3'b001;
    localparam [2:0]  COMP_U      = 3'b010;
    localparam [2:0]  COMP_V      = 3'b100;

    logic                                              data_end_reg;
    logic  [3:0]                                       state;
    logic [15:0]                                       dc_huffcode_table[DC_VVEC_SIZE-1:0];
    logic [7:0]                                        dc_hufflength_table[DC_VVEC_SIZE-1:0];
    logic [15:0]                                       ac_huffcode_table[15:0][9:0];
    logic [7:0]                                        ac_hufflength_table[15:0][9:0];
    logic [15:0]                                       eob;
    logic [7:0]                                        eob_len;
    logic [15:0]                                       zrl;
    logic [7:0]                                        zrl_len;
    logic                                              encode_start;
    logic [2:0]                                        comp;
    logic [MCU_SIZE*MCU_SIZE-1:0][DATA_BITWIDTH-1:0]   encode_data;
    logic                                              r_en;
    wire                                               encode_done;

    logic busy;

    always_ff @(posedge clk) begin
        if(!n_rst) begin
            busy <= 1'b0;
        end
        else if(i_wait) begin
            busy <= busy;
        end
        else if(!busy &  i_start) begin
            busy <= 1'b1;
        end
        else if(busy & o_done) begin
            busy <= 1'b0;
        end
        else begin
            busy <= busy;
        end
    end

    assign o_done = (state == STATE_V) & encode_done;

    always_comb begin
        if(i_start) begin
            o_ready <= 1'b0;
        end
        else begin
            o_ready <= i_send_ready & !busy; 
        end
    end



    always_comb begin
        r_en = (state==STATE_V) & o_done & data_end_reg;
    end

    always_ff @(posedge clk) begin
        if(!n_rst) begin
            o_last <= 1'b0;
        end
        else if(i_wait) begin
            o_last <= o_last;
        end
        else begin
            o_last <= r_en;
        end
    end


    always_ff @(posedge clk) begin
        if(!n_rst) begin
            data_end_reg <= 1'b0;
        end
        else if(i_wait) begin
            data_end_reg <= data_end_reg;
        end
        else if(i_data_end) begin
            data_end_reg <= 1'b1;
        end
        else if(o_done) begin
            data_end_reg <= 1'b0;
        end
        else begin
            data_end_reg <= data_end_reg;
        end
    end

    always_ff @(posedge clk) begin
        if(!n_rst) begin
            state <= STATE_READY;
        end
        else if(i_wait) begin
            state <= state;
        end
        else begin
            case(state)
            STATE_READY :
                if(i_start) begin 
                    state <= STATE_Y;
                end
                else begin
                    state <= STATE_READY;
                end
            STATE_Y : 
                if(encode_done) begin
                    state <= STATE_U;
                end
                else begin
                    state <= STATE_Y;
                end
            STATE_U :
                if(encode_done) begin
                    state <= STATE_V;
                end
                else begin
                    state <= STATE_U;
                end
            STATE_V : 
                if(encode_done) begin
                    state <= STATE_READY;
                end
                else begin
                    state <= STATE_V;
                end
            default : 
                state <= STATE_READY;
            endcase
        end
    end


    always_comb begin
        case(state)
        STATE_Y : 
            encode_data =  i_mcu_y;
        STATE_U :
            encode_data =  i_mcu_u;
        STATE_V :
            encode_data =  i_mcu_v;
        default :
            encode_data = i_mcu_y;
        endcase
    end

    always_ff @(posedge clk) begin
        if(!n_rst) begin
            encode_start <= 1'b0;
        end
        else if(i_wait) begin
            encode_start <= encode_start;
        end
        else if(i_start | encode_done) begin
            if(state != STATE_V) begin
                encode_start <= 1'b1;  
            end
            else begin
                encode_start <= 1'b0;  
            end
        end
        else begin
            encode_start <= 1'b0;
        end
    end

    always_comb begin
        case(state)
        STATE_Y : comp = COMP_Y;
        STATE_U : comp = COMP_U;
        STATE_V : comp = COMP_V;
        default : comp = 3'd0;
        endcase
    end


    always_comb begin
        case(state)
        STATE_Y : begin
            dc_huffcode_table   = dhtif.y_dc_huffcode;
            dc_hufflength_table = dhtif.y_dc_hufflength;
            ac_huffcode_table  = dhtif.y_ac_huffcode;
            ac_hufflength_table = dhtif.y_ac_hufflength;
            eob                 = dhtif.y_eob;
            eob_len             = dhtif.y_eob_len;
            zrl                 = dhtif.y_zrl;
            zrl_len             = dhtif.y_zrl_len;
        end
        default : begin
            dc_huffcode_table   = dhtif.uv_dc_huffcode;
            dc_hufflength_table = dhtif.uv_dc_hufflength;
            ac_huffcode_table  = dhtif.uv_ac_huffcode;
            ac_hufflength_table = dhtif.uv_ac_hufflength;
            eob                 = dhtif.uv_eob;
            eob_len             = dhtif.uv_eob_len;
            zrl                 = dhtif.uv_zrl;
            zrl_len             = dhtif.uv_zrl_len;
        end
        endcase
    end

    huffman_encoder
    #(
        .MCU_SIZE(MCU_SIZE),
        .DATA_BITWIDTH(DATA_BITWIDTH),
        .DC_VVEC_SIZE(DC_VVEC_SIZE),
        .COMP_Y(COMP_Y),
        .COMP_U(COMP_U),
        .COMP_V(COMP_V)
    )
    huffman_encoder_inst
    (
        .clk(clk),
        .n_rst(n_rst),
        .i_dc_huffcode_table(dc_huffcode_table),
        .i_dc_hufflength_table(dc_hufflength_table),
        .i_ac_huffcode_table(ac_huffcode_table),
        .i_ac_hufflength_table(ac_hufflength_table),
        .i_eob(eob),
        .i_eob_len(eob_len),
        .i_zrl(zrl),
        .i_zrl_len(zrl_len),
        .i_start(encode_start),
        .i_wait(i_wait),
        .i_comp(comp),
        .i_data(encode_data),
        .i_r_en(r_en),
        .o_done(encode_done),
        .o_valid(o_valid),
        .o_data(o_data)
    );


endmodule
`default_nettype wire 