`default_nettype none

module stencil_patch
#(
    parameter int WIDTH           = -1,
    parameter int PIXEL_BITWIDTH  = -1,
    parameter int KERNEL_SIZE     = -1
)
(
    input wire                                                          clk,
    input wire                                                          n_rst,
    input wire                                                          i_wait,
    input wire [PIXEL_BITWIDTH-1:0]                                     i_data,
    output logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][PIXEL_BITWIDTH-1:0] o_data,
    output logic                                                        o_valid
);

    localparam int LINE_BUFFER_SIZE = WIDTH - KERNEL_SIZE;
    localparam int LINE_BUFFER_NUM  = KERNEL_SIZE - 1;

    logic [LINE_BUFFER_NUM-1:0][PIXEL_BITWIDTH-1:0]    line_buf_in;
    logic [LINE_BUFFER_NUM-1:0][PIXEL_BITWIDTH-1:0]    line_buf_out;
    logic [LINE_BUFFER_NUM-1:0]                        line_buf_valid;  

    int j;
    always_comb begin
        for(j=0;j<LINE_BUFFER_NUM;j++) begin
            line_buf_in[j] = o_data[j][KERNEL_SIZE-1];
        end
    end

    genvar i;
    generate
        //line buffer generate
        for(i=0;i<LINE_BUFFER_NUM;i++) begin
            line_buffer#(
                .LINE_BUFFER_SIZE(LINE_BUFFER_SIZE),
                .BIT_WIDTH(PIXEL_BITWIDTH)
            )
            line_buff_inst(
                .clk(clk),
                .n_rst(n_rst),
                .i_wait(i_wait),
                .i_data(line_buf_in[i]),
                .o_data(line_buf_out[i]),
                .o_valid(line_buf_valid[i])
            );
        end

    endgenerate


        int k,l;
        //shift o_data
        always_ff @(posedge clk) begin
            if(!n_rst) begin
                // for(k=0;k<KERNEL_SIZE;k++) begin
                //     for(l=0;l<KERNEL_SIZE;l++) begin
                o_data <= '{default : PIXEL_BITWIDTH'('d0)};
            end
            else if(!i_wait)begin
                //
                o_data[0][0] <= i_data;

                //connet o_data to line buffer
                for(k=1;k<KERNEL_SIZE;k++) begin
                    o_data[k][0] <= line_buf_out[k-1];
                end

                //shift
                for(k=0;k<KERNEL_SIZE;k++) begin
                    for(l=1;l<KERNEL_SIZE;l++) begin
                        o_data[k][l] <= o_data[k][l-1];
                    end
                end
            end
            //wait
            else begin
                for(k=0;k<KERNEL_SIZE;k++) begin
                    for(l=0;l<KERNEL_SIZE;l++) begin
                        o_data[k][l] <= o_data[k][l];
                    end
                end
            end
         
        end


        always_ff @(posedge clk) begin
            if(!n_rst) begin
                o_valid <= 1'b0;
            end
            else begin
                //o_valid <= !i_wait;
                o_valid <= (line_buf_valid == {LINE_BUFFER_NUM{1'b1}});
            end
        end

endmodule
`default_nettype wire