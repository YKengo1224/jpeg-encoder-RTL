`default_nettype none

module send_ctrl#(
    parameter int MARKER_BYTE_NUM = -1
)
(
    input  wire clk,
    input  wire n_rst,
    input  wire                       i_start,
    input  wire                       i_wait,
    input  wire                       i_data_end,
    input  wire [0:MARKER_BYTE_NUM-1][7:0] i_marker_array,
    input  wire [7:0]                 i_data,
    input  wire                       i_data_valid,
    output logic                      o_data_send_ready,
    output logic[7:0]                 o_data,
    output logic                      o_valid,
    output logic                      o_data_end
);

    logic      [2:0]                state;
    localparam [2:0]           STATE_READY  = 3'b001;
    localparam [2:0]           STATE_MARKER = 3'b010;
    localparam [2:0]           STATE_DATA    = 3'b100;
    localparam [2:0]           STATE_SOL    = 3'b101;

    localparam int             MAX_COUNT    = MARKER_BYTE_NUM - 1;
    localparam int             COUNT_BITWIDTH = $clog2(MAX_COUNT);
    logic [COUNT_BITWIDTH-1:0] count;

    logic      [7:0]               idata_ff;
    logic                          idata_ff_avail;
    logic                          i_data_end_reg;

    logic      [1:0]               sol_count;

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
                if(i_start) begin
                    state <= STATE_MARKER;
                end
                else begin
                    state <= STATE_READY;
                end
            STATE_MARKER :
                if(count == MAX_COUNT) begin
                    state <= STATE_DATA;
                end
                else begin
                    state <= STATE_MARKER;
                end
            STATE_DATA  :
                if(i_data_end_reg & !o_valid) begin
                    state <= STATE_SOL;
                end
                else begin
                    state <= STATE_DATA;
                end
            STATE_SOL    :
                if(sol_count[1]) begin
                    state <= STATE_READY;
                end
                else begin
                    state <= STATE_SOL;
                end
            default     :
                state <= 3'bxx;
            endcase
        end
    end


    always_ff @(posedge clk) begin
        if(!n_rst) begin
            count <= COUNT_BITWIDTH'('d0);
        end
        else if(i_wait) begin
            count <= count;
        end
        else if(count == MAX_COUNT) begin
            count <= COUNT_BITWIDTH'('d0);
        end
        else if(state == STATE_MARKER) begin
            count <= count + COUNT_BITWIDTH'('d1);
        end
        else begin
            count <= COUNT_BITWIDTH'('d0);
        end 
    end


    always_ff @(posedge clk) begin
        if(!n_rst) begin
            o_data_send_ready <= 1'b0;
        end
        else if(i_wait) begin
            o_data_send_ready <= i_wait;
        end
        else if(i_start) begin
            o_data_send_ready <= 1'b0;
        end
        else if(count == MAX_COUNT) begin
            o_data_send_ready <= 1'b1;
        end
        else begin
            o_data_send_ready <= o_data_send_ready;
        end
    end




    always_ff @(posedge clk) begin
        if(!n_rst) begin
            idata_ff <= 8'd0;
        end
        else if(i_wait) begin
            idata_ff <= idata_ff;
        end
        else begin
            idata_ff <= i_data;
        end
    end

    always_ff @(posedge clk) begin
        if(!n_rst) begin
            idata_ff_avail <= 1'b0;
        end
        else if(i_wait) begin
            idata_ff_avail <= idata_ff_avail;
        end
        else if(state == STATE_DATA) begin
            if(idata_ff_avail & i_data_valid) begin
                idata_ff_avail <= 1'b1;
            end
            else if(o_data == 8'hFF)begin
                idata_ff_avail <= 1'b1;
            end
            else begin
                idata_ff_avail <= 1'b0;
            end
        end
        else begin
            idata_ff_avail <= 1'b0;
        end

    end


    always_ff @(posedge clk) begin
        if(!n_rst) begin
            i_data_end_reg <= 1'b0;
        end
        else if(i_wait) begin
            i_data_end_reg <= i_data_end_reg;
        end
        else if(i_data_end_reg) begin
            if(o_valid) begin
                i_data_end_reg <= 1'b1;
            end
            else begin
                i_data_end_reg <= 1'b0;
            end
        end
        else begin
            i_data_end_reg <= i_data_end ;
        end
    end



    always_ff @(posedge clk) begin
        if(!n_rst)begin
            sol_count <= 2'b0;
        end
        else if(i_wait) begin
            sol_count <= sol_count;
        end
        else begin
            sol_count <= { sol_count[0],(i_data_end_reg & !o_valid)};
        end
    end



    always_ff @(posedge clk) begin
        if(!n_rst) begin
            o_data <= 8'h00;
        end
        else if(i_wait) begin
            o_data <= o_data;
        end
        else begin
            case(state)
            STATE_MARKER : 
                o_data <= i_marker_array[count];
            STATE_DATA   : begin
                if(o_data == 8'hFF) begin
                    o_data <= 00;
                end
                else if(idata_ff_avail) begin
                    o_data <= idata_ff;
                end
                else begin
                o_data  <= i_data;
                end
            end
            STATE_SOL :
                if(sol_count[0]) begin
                    o_data<= 8'hFF;
                end
                else begin
                    o_data<= 8'hD9;
                end
            default     :
                o_data <= 8'h00;
            endcase
        end
    end    


    always_ff @(posedge clk) begin
        if(!n_rst) begin
            o_valid <= 1'b0;
        end
        else if(i_wait) begin
            o_valid <= o_valid;
        end
        else begin
            case(state)
            STATE_MARKER : 
                o_valid <= 1'b1;
            STATE_DATA   : begin
                if(o_data == 8'hFF & o_valid) begin
                    o_valid <= 1'b1;
                end
                else if(idata_ff_avail) begin
                    o_valid <= 1'b1;
                end
                else begin
                    o_valid  <= i_data_valid;
                end
            end
            STATE_SOL   :
                o_valid <= 1'b1;
            default     :
                o_valid <= 1'b0;
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if(!n_rst)begin
            o_data_end <= 1'b0;
        end
        else if(i_wait) begin
            o_data_end <= o_data_end;
        end
        else begin
            o_data_end <= (state==STATE_SOL) & (sol_count[1]);
        end
    end


endmodule

`default_nettype wire