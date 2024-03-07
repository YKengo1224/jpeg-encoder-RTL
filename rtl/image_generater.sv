`default_nettype none
module image_generater#(
    parameter int WIDTH  = -1,
    parameter int HEIGHT = -1,
    parameter int PIXEL_BITWIDTH = -1,
    parameter int RGB_BITWIDTH = 8
)
(
    input wire clk,
    input wire n_rst,
    input wire i_start,
    output logic [PIXEL_BITWIDTH-1:0] o_axis_tdata,
    output logic                      o_axis_tlast,
    output logic                      o_axis_tuser,
    output logic                      o_axis_tvalid,
    input wire                       i_axis_ready    
);
    localparam int WIDTH_HALF =  WIDTH  / 2;
    localparam int HEIGHT_HALF = HEIGHT / 2;

    logic    busy;

    localparam int MAX_WIDTH_COUNT = WIDTH-1;
    localparam int WIDTH_COUNT_BITWIDTH = $clog2(MAX_WIDTH_COUNT);
    logic [WIDTH_COUNT_BITWIDTH:0]     width_count;

    localparam int MAX_HEIGHT_COUNT = HEIGHT-1;
    localparam int HEIGHT_COUNT_BITWIDTH = $clog2(MAX_HEIGHT_COUNT);
    logic [HEIGHT_COUNT_BITWIDTH:0]    height_count;

    localparam int FIFO_DATA_BITWIDTH = PIXEL_BITWIDTH+2;
    logic [FIFO_DATA_BITWIDTH-1:0] fifo_data;
    logic         fifo_tuser;
    logic         fifo_tlast;
    logic         fifo_re;
    logic         fifo_we;
    wire          fifo_empty;
    wire          fifo_full;
    wire [FIFO_DATA_BITWIDTH-1:0] fifo_o_data;


    always_ff @(posedge clk) begin
        if(!n_rst) begin
            busy <= 1'b0;
        end
        else if(i_start) begin
            busy <= 1'b1;
        end
        else if((width_count==MAX_WIDTH_COUNT) & (height_count==MAX_HEIGHT_COUNT))begin
            busy <= 1'b0;
        end
        else begin
            busy <= busy;
        end
    end

    always_ff @(posedge clk) begin
        if(!n_rst)begin
            width_count <= WIDTH_COUNT_BITWIDTH'('d0);
        end
        else if(busy) begin
            if(width_count == MAX_WIDTH_COUNT[WIDTH_COUNT_BITWIDTH:0]) begin
                width_count <= WIDTH_COUNT_BITWIDTH'('d0);
            end
            else begin
                width_count <= width_count + WIDTH_COUNT_BITWIDTH'('d1);
            end
        end
        else begin
            width_count <= WIDTH_COUNT_BITWIDTH'('d0);
        end
    end

    always_ff @(posedge clk) begin
        if(!n_rst) begin
            height_count <= HEIGHT_COUNT_BITWIDTH'('d0);
        end
        else if(width_count == MAX_WIDTH_COUNT[WIDTH_COUNT_BITWIDTH:0]) begin
            if(height_count == MAX_HEIGHT_COUNT[HEIGHT_COUNT_BITWIDTH:0]) begin
                height_count <= HEIGHT_COUNT_BITWIDTH'('d0);
            end
            else begin
                height_count <= height_count + HEIGHT_COUNT_BITWIDTH'('d1);
            end
        end
        else begin
            height_count <= height_count;
        end

    end


    always_comb begin
        fifo_tuser <= busy & (width_count == WIDTH_COUNT_BITWIDTH'('d0)) & (height_count == HEIGHT_COUNT_BITWIDTH'('d0));
        fifo_tlast <= busy & (width_count == MAX_WIDTH_COUNT[WIDTH_COUNT_BITWIDTH:0]);
    end



    // always_ff @(posedge clk) begin
    //     if(!n_rst)begin
    //         fifo_data <= FIFO_DATA_BITWIDTH'('d0);
    //     end
    //     else if(busy) begin
    //         if(width_count <= WIDTH_HALF) begin
    //             if(height_count <= HEIGHT_HALF) begin
    //                 fifo_data <= {24'hFF0000,fifo_tlast,fifo_tuser};
    //             end
    //             else begin
    //                 fifo_data <= {24'h00FF00,fifo_tlast,fifo_tuser};
    //             end
    //         end
    //         else begin
    //             if(height_count <= HEIGHT_HALF) begin
    //                 fifo_data <= {24'h0000FF,fifo_tlast,fifo_tuser};
    //             end
    //             else begin
    //                 fifo_data <= {24'hFFFFFF,fifo_tlast,fifo_tuser};
    //             end
    //         end
    //     end
    //     else begin
    //         fifo_data <= FIFO_DATA_BITWIDTH'('d0);
    //     end
    // end
    always_comb begin
        if(busy) begin
            if(width_count < WIDTH_HALF) begin
                if(height_count < HEIGHT_HALF) begin
                    fifo_data <= {24'hFF0000,fifo_tlast,fifo_tuser};
                end
                else begin
                    fifo_data <= {24'h00FF00,fifo_tlast,fifo_tuser};
                end
            end
            else begin
                if(height_count < HEIGHT_HALF) begin
                    fifo_data <= {24'h0000FF,fifo_tlast,fifo_tuser};
                end
                else begin
                    fifo_data <= {24'hFFFFFF,fifo_tlast,fifo_tuser};
                end
            end
        end
        else begin
            fifo_data <= FIFO_DATA_BITWIDTH'('d0);
        end
    end



    // always_ff @(posedge clk) begin
    //     if(!n_rst) begin
    //         fifo_re <= 1'b0;
    //     end
    //     else begin
    //         fifo_re <= i_axis_ready & !fifo_empty;
    //     end
    // end
    always_comb begin
        fifo_re <= i_axis_ready & !fifo_empty;
    end

    // always_ff @(posedge clk) begin
    //     if(!n_rst)begin
    //         fifo_we <= 1'b0;
    //     end
    //     else begin
    //         fifo_we <= busy;
    //     end
    // end
    always_comb begin
        fifo_we <= busy;
    end



    fifo#(
        .FIFO_SIZE(WIDTH*HEIGHT),
        .BIT_WIDTH(FIFO_DATA_BITWIDTH)
    )
    fifo_inst
    (
        .clk(clk),
        .n_rst(n_rst),
        .we(fifo_we),
        .re(fifo_re),
        .din(fifo_data),
        .empty(fifo_empty),
        .full(fifo_full),
        .dout(fifo_o_data)
    );


    always_comb begin
        o_axis_tdata = fifo_o_data[FIFO_DATA_BITWIDTH-1:2];
        o_axis_tlast = fifo_o_data[1] & o_axis_tvalid;
        o_axis_tuser = fifo_o_data[0]& o_axis_tvalid;
    end

    always_ff @(posedge clk) begin
        if(!n_rst) begin
            o_axis_tvalid <= 1'b0;
        end
        else begin
            o_axis_tvalid <= fifo_re;
        end
    end


endmodule

`default_nettype wire