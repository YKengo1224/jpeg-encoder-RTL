`default_nettype none

module zig_fifo
#(
    parameter int FIFO_SIZE = -1,
    parameter int MCU_SIZE =  -1,
    parameter int BIT_WIDTH = -1
)
(
    input wire                                              clk,
    input wire                                              n_rst,
    input wire                                              i_we,  
    input wire                                              i_re,
    input wire [MCU_SIZE*MCU_SIZE-1:0][BIT_WIDTH-1:0]       i_y,
    input wire [MCU_SIZE*MCU_SIZE-1:0][BIT_WIDTH-1:0]       i_u,
    input wire [MCU_SIZE*MCU_SIZE-1:0][BIT_WIDTH-1:0]       i_v,
    input wire                                              i_last,
    input wire                                              i_wait,
    output logic                                            o_empty,
    output logic                                            o_full,
    output logic [MCU_SIZE*MCU_SIZE-1:0][BIT_WIDTH-1:0]      o_y,
    output logic [MCU_SIZE*MCU_SIZE-1:0][BIT_WIDTH-1:0]      o_u,
    output logic [MCU_SIZE*MCU_SIZE-1:0][BIT_WIDTH-1:0]      o_v,
    output logic                                             o_last,
    output logic                                            o_valid
);

    localparam int FIFO_BITWIDTH = MCU_SIZE*MCU_SIZE*BIT_WIDTH*3+1;   
    logic [FIFO_BITWIDTH-1:0] fifo_idata;
    logic [FIFO_BITWIDTH-1:0] fifo_odata;
    

    always_comb begin
        for(int i = 0;i<(MCU_SIZE*MCU_SIZE);i++) begin
            fifo_idata[(i*BIT_WIDTH*3) +: BIT_WIDTH] = i_v[i];
            fifo_idata[(i*BIT_WIDTH*3+BIT_WIDTH) +: BIT_WIDTH] = i_u[i];
            fifo_idata[(i*BIT_WIDTH*3+(BIT_WIDTH*2)) +: BIT_WIDTH] = i_y[i];
            fifo_idata[FIFO_BITWIDTH-1] = i_last;
        end
    end

    always_comb begin
        for(int i = 0;i<(MCU_SIZE*MCU_SIZE);i++) begin
            o_y[i] = fifo_odata[(i*BIT_WIDTH*3+(BIT_WIDTH*2)) +: BIT_WIDTH] ;
            o_u[i] = fifo_odata[(i*BIT_WIDTH*3+(BIT_WIDTH)) +: BIT_WIDTH] ;
            o_v[i] = fifo_odata[(i*BIT_WIDTH*3) +: BIT_WIDTH] ;
            o_last = fifo_odata[FIFO_BITWIDTH-1] ;
        end
    end


    fifo#(
    .FIFO_SIZE(FIFO_SIZE),
    .BIT_WIDTH(FIFO_BITWIDTH)
    )
    fifo_inst(
        .clk(clk),
        .n_rst(n_rst),
        .we(i_we),
        .re(i_re),
        .din(fifo_idata),
        .empty(o_empty),
        .full(o_full),
        .dout(fifo_odata)
    );


    always_ff @(posedge clk) begin
        if(!n_rst) begin
            o_valid <= 1'b0;
        end
        else if(i_wait) begin
            o_valid <= o_valid;
        end
        else begin
            o_valid <= i_re & !o_empty;
        end
    end


//             fifo
//             #(
//                 .FIFO_SIZE(FIFO_SIZE),
//                 .BIT_WIDTH((BIT_WIDTH*3)+1)
//             )
//             _fifo_inst
//             (
//                 .clk(clk),
//                 .n_rst(n_rst),
//                 .we(i_we),
//                 .re(i_re),
//                 .din(fifo_idata[i]),
//                 .empty(fifo_empty[i]),
//                 .full(fifo_full[i]),
//                 .dout(fifo_odata[i])    
//             );
//         end

//     logic [MCU_SIZE*MCU_SIZE-1:0][(BIT_WIDTH*3+1)-1:0]  fifo_idata;
//     logic [MCU_SIZE*MCU_SIZE-1:0][(BIT_WIDTH*3+1)-1:0]  fifo_odata;
//     logic [MCU_SIZE*MCU_SIZE-1:0] fifo_empty;   
//     logic [MCU_SIZE*MCU_SIZE-1:0] fifo_full;



//     always_comb begin
//         for(int i = 0;i<(MCU_SIZE*MCU_SIZE);i++) begin
//                 fifo_idata[i] <= {i_y[i],i_u[i],i_v[i],i_last};
//         end
//     end

//     assign o_empty = fifo_empty[0];
//     assign o_full  = fifo_full[0];

//     always_comb begin
//         for(int i = 0;i<(MCU_SIZE*MCU_SIZE);i++) begin
//             o_y[i] = fifo_odata[i][(BIT_WIDTH*3+1)-1 -:BIT_WIDTH];
//             o_u[i] = fifo_odata[i][(BIT_WIDTH*2+1)-1 -:BIT_WIDTH];
//             o_v[i] = fifo_odata[i][(BIT_WIDTH+1)-1   -:BIT_WIDTH];
//             o_last = fifo_odata[i][0];
//         end
//     end


//     always_ff @(posedge clk) begin
//         if(!n_rst) begin
//             o_valid <= 1'b0;
//         end
//         else if(i_wait) begin
//             o_valid <= o_valid;
//         end
//         else begin
//             o_valid <= i_re & !o_empty;
//         end
//     end

//    genvar i,j;
//     generate
//         for(i=0;i<(MCU_SIZE*MCU_SIZE);i++) begin
//             fifo
//             #(
//                 .FIFO_SIZE(FIFO_SIZE),
//                 .BIT_WIDTH((BIT_WIDTH*3)+1)
//             )
//             _fifo_inst
//             (
//                 .clk(clk),
//                 .n_rst(n_rst),
//                 .we(i_we),
//                 .re(i_re),
//                 .din(fifo_idata[i]),
//                 .empty(fifo_empty[i]),
//                 .full(fifo_full[i]),
//                 .dout(fifo_odata[i])    
//             );
//         end

//     endgenerate








    
    // wire [MCU_SIZE*MCU_SIZE-1:0] y_full;
    // wire [MCU_SIZE*MCU_SIZE-1:0] u_full;
    // wire [MCU_SIZE*MCU_SIZE-1:0] v_full;
    // wire [MCU_SIZE*MCU_SIZE-1:0] y_empty;
    // wire [MCU_SIZE*MCU_SIZE-1:0] u_empty;
    // wire [MCU_SIZE*MCU_SIZE-1:0] v_empty;

    // always_comb begin
    //     o_full  = y_full  == {(MCU_SIZE*MCU_SIZE){1'b1}};
    //     o_empty = y_empty == {(MCU_SIZE*MCU_SIZE){1'b1}};
    // end

    // always_ff @(posedge clk) begin
    //     if(!n_rst) begin
    //         o_valid <= 1'b0;
    //     end
    //     else if(i_wait) begin
    //         o_valid <= o_valid;
    //     end
    //     else begin
    //         o_valid <= i_re & !o_empty;
    //     end
    // end


    // fifo
    //         #(
    //             .FIFO_SIZE(FIFO_SIZE),
    //             .BIT_WIDTH(1)
    //         )
    //         y_fifo_inst
    //         (
    //             .clk(clk),
    //             .n_rst(n_rst),
    //             .we(i_we),
    //             .re(i_re),
    //             .din(i_last),
    //             .dout(o_last)
    //         );


    // genvar i,j;
    // generate
    //     for(i=0;i<(MCU_SIZE*MCU_SIZE);i++) begin
    //         fifo
    //         #(
    //             .FIFO_SIZE(FIFO_SIZE),
    //             .BIT_WIDTH(BIT_WIDTH)
    //         )
    //         y_fifo_inst
    //         (
    //             .clk(clk),
    //             .n_rst(n_rst),
    //             .we(i_we),
    //             .re(i_re),
    //             .din(i_y[i]),
    //             .empty(y_empty[i]),
    //             .full(y_full[i]),
    //             .dout(o_y[i])    
    //         );

    //     fifo
    //     #(
    //         .FIFO_SIZE(FIFO_SIZE),
    //         .BIT_WIDTH(BIT_WIDTH)
    //     )
    //     u_fifo_inst
    //     (
    //         .clk(clk),
    //         .n_rst(n_rst),
    //         .we(i_we),
    //         .re(i_re),
    //         .din(i_u[i]),
    //         .empty(u_empty[i]),
    //         .full(u_full[i]),
    //         .dout(o_u[i])    
    //     );
    //             fifo
    //     #(
    //         .FIFO_SIZE(FIFO_SIZE),
    //         .BIT_WIDTH(BIT_WIDTH)
    //     )
    //     v_fifo_inst
    //     (
    //         .clk(clk),
    //         .n_rst(n_rst),
    //         .we(i_we),
    //         .re(i_re),
    //         .din(i_v[i]),
    //         .empty(v_empty[i]),
    //         .full(v_full[i]),
    //         .dout(o_v[i])    
    //     );

    //     end

    // endgenerate


endmodule

`default_nettype wire