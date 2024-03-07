`default_nettype none

/*
・BUFFSIZEビットデータがたまったら出力，
・BUFF_SIZEは8ビットを想定

・書き込みは１〜３クロックで動作
・読み出しは，シフトレジスタが満杯になると順次読み出し
・i_r_enが１になると，強制で読み出し(１拡張される)

・O_busyが１のときは入力信号変化禁止
*/
module bit_buffer
(
    input  wire                        clk,
    input  wire                        n_rst,
    input  wire                        i_w_en,
    input  wire  [15:0]                i_data,
    input  wire  [7:0]                 i_datalength,
    input  wire                        i_r_en,         //残りのデータを送信 ODATA_BITWIDTHビットそろってない場合は，０埋めする
    input  wire                        i_wait,
    output logic [7:0]                 o_data,
    output logic                       o_valid,
    output logic                       o_busy
);

    localparam [3:0]                   STATE_READY = 4'b001;
    localparam [3:0]                   STATE_I_DATA = 4'b010;
    localparam [3:0]                   STATE_TEMP_DATA = 4'b100;

    logic [2:0]                        state;
    logic                               w_en;                             
    logic                              r_en;
    logic [7:0]                        datalength;
    logic [15:0]                        data;

    logic [7:0]                        shift_reg;
    logic [7:0]                        avail;           //シフトレジスタの空き領域

    logic [15:0]                       lalign_wdata;      //i_dataの左詰めデータ
    logic [7:0]                        wlength;
    logic                              all_wdata_written; //すべてのデータを書き込めるかのフラグ

    logic [15:0]                       temp_reg;               //退避用レジスタ
    logic [7:0]                        temp_length;            //退避用レジスタの有効データ長
    logic                              temp_length_2clock_flag;//1回で書き込めるか




    /*
    書き込み動作
        2ステートで動作する    
        Step 1. write i_data    : i_dataをシフトレジスタに書き込み すべて書き込めない場合は，退避用レジスタに残りを格納にStep 2へ
                                  全ビット書き込めた場合は書き込み動作終了
        Step 2. write_tmp_reg   : 退避用レジスタのデータを書き込み(すべて書き込めない場合は２クロックで書き込み)
    */
    always_ff @(posedge clk) begin
        if(!n_rst) begin
            state <= STATE_READY;
        end
        else if(i_wait) begin
            state <= state;
        end
        else begin
            case(state)
            STATE_READY  :
                if(i_w_en) begin
                    state <= STATE_I_DATA;    
                end
                else begin
                    state <= state;    
                end
            STATE_I_DATA :
                if(w_en) begin
                    state <= STATE_TEMP_DATA;
                end
                else begin
                    state <= state;
                end
            STATE_TEMP_DATA :
                if(temp_length == 0) begin
                    state <= STATE_READY;
                end
                else begin
                    state <= state;
                end
            default:
                state <= STATE_READY;
            endcase
        end
    end

    always_comb begin
        o_busy =  state[1] | state[2];
    end

//クリティカルパスを短くるすつためにレジスタを挟む
    always_ff@(posedge clk) begin
        if(!n_rst) begin
            w_en <= 1'b0;
        end
        else if(i_wait) begin
            w_en <= w_en;
        end
        else begin
            w_en <= i_w_en &! o_busy;
        end
    end
    always_ff @( posedge clk ) begin
        if(!n_rst) begin
            datalength <= 8'd0;
        end
        else if(i_wait) begin
            datalength <= datalength;
        end
        else begin
            datalength <= i_datalength;
        end
    end
    always_ff @( posedge clk ) begin
        if(!n_rst) begin
            data <= 16'd0;
        end
        else if(i_wait) begin
            data <= data;
        end
        else begin
            data <= i_data;
        end
    end


//Step 1
    //w_en 
    //assign w_en = i_w_en & !o_busy;

    //all_wdata_written
    always_comb begin
        if(w_en) begin
            all_wdata_written  = (avail >= datalength) ;
        end
        else begin
            all_wdata_written = 1'b0;
        end
    end

    //lalign_wdata (左詰め)
    always_comb begin
        lalign_wdata   <= data << (16 - datalength);
    end

    //wlength
    always_comb begin
        if(all_wdata_written) begin
            wlength = datalength;
        end
        else if(w_en) begin
            wlength = avail;
        end
        else begin
            wlength = 8'd0;
        end
    end
//

//Step 2

    
    always_comb begin
            temp_length_2clock_flag = temp_length >5'd8; 
    end

    always_ff @(posedge clk) begin
        if(!n_rst) begin
            temp_length <= 8'd0;
        end
        else if(i_wait) begin
            temp_length <= temp_length;
        end
        //すべてのデータを書き込めなかったら
        else if(w_en & !all_wdata_written)begin
            temp_length <= datalength -avail;
        end
        //1クロックですべて書き込めなかったら
        else if(state[2] & temp_length_2clock_flag) begin
            temp_length <= temp_length - 8'd8;
        end
        else begin
            temp_length <= 8'd0;
        end
    end

    always_ff @(posedge clk) begin
        if(!n_rst) begin
            temp_reg <= 16'd0;
        end
        else if(i_wait) begin
            temp_reg <= temp_reg;
        end
        else if(w_en)  begin
            case(avail)
            8'd1    :  temp_reg <= {lalign_wdata[14:0],1'd0};
            8'd2    :  temp_reg <= {lalign_wdata[13:0],2'd0};
            8'd3    :  temp_reg <= {lalign_wdata[12:0],3'd0};
            8'd4    :  temp_reg <= {lalign_wdata[11:0],4'd0};
            8'd5    :  temp_reg <= {lalign_wdata[10:0],5'd0};
            8'd6    :  temp_reg <= {lalign_wdata[9:0] ,6'd0};
            8'd7    :  temp_reg <= {lalign_wdata[8:0] ,7'd0};
            8'd8    :  temp_reg <= {lalign_wdata[7:0] ,8'd0};
            8'd9    :  temp_reg <= {lalign_wdata[6:0] ,9'd0};
            8'd10   :  temp_reg <= {lalign_wdata[5:0] ,10'd0};
            8'd11   :  temp_reg <= {lalign_wdata[4:0] ,11'd0};
            8'd12   :  temp_reg <= {lalign_wdata[3:0] ,12'd0};
            8'd13   :  temp_reg <= {lalign_wdata[2:0] ,13'd0};
            8'd14   :  temp_reg <= {lalign_wdata[1:0] ,14'd0};
            8'd15   :  temp_reg <= {lalign_wdata[0]   ,15'd0};
            default                :  temp_reg <= 16'd0;
            endcase
        end
        else if(state[2] & temp_length_2clock_flag)  begin
            //シフト
            temp_reg <= {temp_reg << 16'd8};   
        end
        else begin
            temp_reg <= temp_reg;
        end
    end


//シフトレジスタ
    //shift reg
    always_ff @(posedge clk) begin
        if(!n_rst) begin
            shift_reg<= 16'd0;
        end//データ書き込み
        else if(i_wait) begin
            shift_reg <= shift_reg;
        end
        else if(w_en) begin
            shift_reg <= sec_shift(shift_reg,lalign_wdata,wlength);
        end
        //退避用レジスタのデータを書き込み(１回目)
        else if(state[2] & temp_length_2clock_flag) begin
            shift_reg <= sec_shift(shift_reg,temp_reg,8'd8);
        end
        else if(state[2]) begin
            shift_reg <= sec_shift(shift_reg,temp_reg,temp_length);
        end
        else begin
            shift_reg <= shift_reg;
        end
    end

//読み出し
    //シフトレジスタが満杯になったら読み出し
    always_comb begin
        r_en = (avail == 8'd0);
    end

    always_ff @(posedge clk) begin
        if(!n_rst) begin
            o_data <= 8'd0;
        end
        else if(i_wait) begin
            o_data <= o_data;
        end
        //強制読み出し
        else if(i_r_en) begin
            case(avail)
            8'('d0)  : o_data <= shift_reg;
            8'('d1)  : o_data <= {shift_reg[6:0],1'b1};
            8'('d2)  : o_data <= {shift_reg[5:0],2'b11};
            8'('d3)  : o_data <= {shift_reg[4:0],3'b111};
            8'('d4)  : o_data <= {shift_reg[3:0],4'b1111};
            8'('d5)  : o_data <= {shift_reg[2:0],5'b11111};
            8'('d6)  : o_data <= {shift_reg[1:0],6'b111111};
            8'('d7)  : o_data <= {shift_reg[0]  ,7'b1111111};
            default              : o_data <= 8'd0;
            endcase                            
        end 
        else if(r_en) begin
            o_data <= shift_reg;
        end
        else begin
            o_data <= 8'd0;
        end
    end
    always_ff @(posedge clk) begin
        if(!n_rst) begin
            o_valid <= 1'b0;
        end
        else if(i_wait) begin
            o_valid <= o_valid;
        end
        else if(i_r_en & (avail != 8'd8)) begin
            o_valid <= 1'b1;
        end
        else if(r_en) begin
            o_valid <= 1'b1;
        end
        else begin
            o_valid <= 1'b0;
        end
    end

    //空き領域
    always_ff @(posedge clk) begin
        if(!n_rst) begin
            avail <= 8'd8;
        end
        else if(i_wait) begin
            avail <= avail;
        end
        else if(i_r_en) begin
            avail <= 8'd8;
        end
        //入力データをすべてかきこめなかったら
        else if(w_en & !all_wdata_written) begin
            avail <= 8'd0;
        end
        //入力データ書き込み
        else if(w_en) begin
            avail <= avail - 8'(wlength);
        end

        else if(state[2] & (temp_length != 8'd0) & temp_length_2clock_flag) begin
            if(r_en) begin
                avail <= 8'd0;
            end
        end
        else if(state[2] & (temp_length != 8'd0)) begin
            if(r_en) begin
                avail <= 8'd8 - temp_length;
            end
        end
        else if(r_en) begin
            avail <= 8'd8;
        end
        else begin
            avail <= avail;
        end
        
    end





    function [7:0]sec_shift(
        input [7:0]      shift_reg,
        input [15:0] data,
        input [7:0]    wlength
    );  
        case(wlength)
            8'd1    : sec_shift = {shift_reg[6:0],data[15]};
        8'd2    : sec_shift = {shift_reg[5:0],data[15:14]};
        8'd3    : sec_shift = {shift_reg[4:0],data[15:13]};
        8'd4    : sec_shift = {shift_reg[3:0],data[15:12]};
        8'd5    : sec_shift = {shift_reg[2:0],data[15:11]};
        8'd6    : sec_shift = {shift_reg[1:0],data[15:10]};
        8'd7    : sec_shift = {shift_reg[ 0 ],data[15:9]};
        8'd8    : sec_shift = data[15:8];
        default : sec_shift = shift_reg;
        endcase                
    endfunction



endmodule


`default_nettype wire