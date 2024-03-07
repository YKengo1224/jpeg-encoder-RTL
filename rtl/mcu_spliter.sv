`default_nettype none

module mcu_spliter #(
    parameter int WIDTH = -1,
    parameter int HEIGHT = -1,
    parameter int PIXEL_BITWIDTH = -1,
    parameter int MCU_SIZE       = -1
)
(
    input wire clk,
    input wire n_rst,
    input wire  [PIXEL_BITWIDTH-1:0]           i_yuv,
    input wire                                 i_tlast,
    input wire                                 i_tuser,
    input wire                                 i_tvalid,
    input wire                                 i_wait,
    //output wire [MCU_SIZE-1:0][MCU_SIZE-1:0][PIXEL_BITWIDTH-1:0] o_mcu,
    output logic [0:MCU_SIZE-1][0:MCU_SIZE-1][PIXEL_BITWIDTH-1:0] o_mcu,
    output logic                               o_valid,
    output logic                               o_last
);

    logic [MCU_SIZE-1:0][MCU_SIZE-1:0][PIXEL_BITWIDTH-1:0] mcu;
    wire patch_valid;

    logic busy;

    localparam int COUNT_BITWIDTH      = $clog2(WIDTH);
//    logic [COUNT_BITWIDTH:0]       count;

    localparam int LINE_COUNT_BITWIDTH = $clog2(HEIGHT);
    localparam int MAX_LINE_COUNT      = HEIGHT-1;
    logic [LINE_COUNT_BITWIDTH:0]  line_count;

    localparam int DIVISION_COUNT_BITWIDTH = $clog2(MCU_SIZE);
    localparam int MAX_DIVISION_COUNT      = MCU_SIZE-1;
    logic [DIVISION_COUNT_BITWIDTH:0] division_count;
    logic [DIVISION_COUNT_BITWIDTH:0] division_line_count;

    logic                             stencil_wait;

    //o_last
    // always_comb begin
    //     o_last <= (!i_wait & i_tlast &  (line_count == MAX_LINE_COUNT) ) ;
    // end    
    always_ff @(posedge clk) begin
        if(!n_rst) begin
            o_last <= 1'b0;
        end
        else begin
            o_last <= (!i_wait & i_tlast & i_tvalid &  (line_count == MAX_LINE_COUNT) ) ;
        end
    end
    

    //width count
    // always_ff @(posedge clk) begin
    //     if(!n_rst) begin
    //         count <= COUNT_BITWIDTH'('d0);
    //     end
    //     else if(!i_wait) begin
    //         if(!busy) begin
    //             if(i_tuser) begin
    //                 count <= COUNT_BITWIDTH'('d1);
    //             end
    //             else begin
    //                 count <= COUNT_BITWIDTH'('d0);
    //             end
    //         end
    //         else if(i_tlast)begin
    //             count <= COUNT_BITWIDTH'('d0);
    //         end
    //         else begin
    //             count <= count + COUNT_BITWIDTH'('d1);
    //         end
    //     end
    //     else begin
    //         count <= count;
    //     end
    // end


    always_ff @(posedge clk) begin
        if(!n_rst) begin
            line_count <= LINE_COUNT_BITWIDTH'('d0);
        end
        else if(!i_wait & i_tlast & i_tvalid) begin
            if(line_count == MAX_LINE_COUNT) begin
                line_count <= LINE_COUNT_BITWIDTH'('d0);
            end
            else begin
                line_count <= line_count + LINE_COUNT_BITWIDTH'('d1);
            end
        end
        else begin
            line_count <= line_count;
        end
    end

    //width count
    always_ff @(posedge clk) begin
        if(!n_rst) begin
            division_count <= DIVISION_COUNT_BITWIDTH'('d0);
        end
        else if(!i_wait & i_tvalid) begin
            if(!busy) begin
                if(i_tuser) begin
                    division_count <= DIVISION_COUNT_BITWIDTH'('d1);
                end
                else begin
                    division_count <= DIVISION_COUNT_BITWIDTH'('d0);
                end
            end
            else if(division_count == MAX_DIVISION_COUNT)begin
                division_count <= DIVISION_COUNT_BITWIDTH'('d0);
            end
            else begin
                division_count <= division_count + DIVISION_COUNT_BITWIDTH'('d1);
            end
        end
        else begin
            division_count <= division_count;
        end
    end


    always_ff @(posedge clk) begin
        if(!n_rst) begin
            division_line_count <= DIVISION_COUNT_BITWIDTH'('d0);
        end
        else if(!i_wait & i_tlast & i_tvalid) begin
            if(division_line_count == MAX_DIVISION_COUNT) begin
                division_line_count <= DIVISION_COUNT_BITWIDTH'('d0);
            end
            else begin
                division_line_count <= division_line_count + DIVISION_COUNT_BITWIDTH'('d1);
            end
        end
        else begin
            division_line_count <= division_line_count;
        end
    end



    always_ff @(posedge clk) begin
        if(!n_rst) begin
            busy <= 1'b0;
        end
        else if(!busy & i_tuser & i_tvalid) begin
            busy <= 1'b1;
        end
        else if(busy & (line_count == MAX_LINE_COUNT) & i_tlast & i_tvalid) begin
            busy <= 1'b0;
        end
        else begin
            busy <= busy;
        end
    end

    assign  stencil_wait = i_wait | !i_tvalid;

    stencil_patch
    #(
        .WIDTH(WIDTH),
        .PIXEL_BITWIDTH(PIXEL_BITWIDTH),
        .KERNEL_SIZE(MCU_SIZE)
    )
    stencil_patch_inst
    (
        .clk(clk),
        .n_rst(n_rst),
        .i_wait(stencil_wait),
        .i_data(i_yuv),
        .o_data(mcu),
        .o_valid(patch_valid)
    );


    //change order
    always_comb begin
        for(int i = 0;i<MCU_SIZE;i++) begin
            for(int j = 0;j<MCU_SIZE;j++) begin
                o_mcu[i][j] = mcu[MCU_SIZE-1-i][MCU_SIZE-1-j];
            end
        end
    end

    always_ff @(posedge clk) begin
        if(!n_rst) begin
            o_valid <= 1'b0;
        end
        else if(!i_wait & i_tvalid & (division_line_count == MAX_DIVISION_COUNT) & (division_count == MAX_DIVISION_COUNT))begin
            o_valid <= 1'b1;
        end
        else begin
            o_valid <= 1'b0;
        end
    end


    
endmodule


`default_nettype wire