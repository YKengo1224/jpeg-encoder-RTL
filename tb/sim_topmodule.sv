`timescale 1ns/1ps

`default_nettype none
module sim_topmodule;
    parameter real CLK_PERIOD    = 10e6;
    parameter      CLK_FREQ      = 1500000;
    parameter real CLK_PERIOD_NS = CLK_PERIOD/CLK_FREQ;

    reg clk;
    reg n_rst;

    //--------user singnal and parameter--------
    // localparam int WIDTH  = 640;
    // localparam int HEIGHT = 480;
    localparam int WIDTH = 1280;
    localparam int HEIGHT = 720;
    // localparam int WIDTH  = 32;
    // localparam int HEIGHT = 16;
    localparam int PIXEL_BITWIDTH = 24;
    localparam int RGB_BITWIDTH = 8;
    localparam int MCU_SIZE = 8;
    localparam int DCT_BITWIDTH = 12;
    localparam int QUAN_BITWIDTH = 10;
    

    reg i_start;
    wire [PIXEL_BITWIDTH-1:0] axis_tdata;
    wire                      axis_tlast;
    wire                      axis_tuser;
    wire                      axis_tvalid;
    wire                      axis_ready;  

    wire         [7:0]             o_data;
    wire                            o_valid;
    wire                           o_last;
    wire                           m_axis_ready;
    wire                           m_axis_tstrb;

    //yuv
    logic [PIXEL_BITWIDTH-1:0] yuv_data;
    logic                      yuv_tlast;
    logic                      yuv_tuser;    
    logic                      yuv_tvalid;    
 
    logic fifo_we;
    logic [MCU_SIZE-1:0][MCU_SIZE-1:0][PIXEL_BITWIDTH-1:0] mcu_data;

    //mcu fifo
    logic [MCU_SIZE-1:0][MCU_SIZE-1:0][PIXEL_BITWIDTH-1:0] mcu_fifo_dout;

    //dct calc
    logic [MCU_SIZE-1:0][MCU_SIZE-1:0][DCT_BITWIDTH-1:0] dct_y;
    logic [MCU_SIZE-1:0][MCU_SIZE-1:0][DCT_BITWIDTH-1:0] dct_u;
    logic [MCU_SIZE-1:0][MCU_SIZE-1:0][DCT_BITWIDTH-1:0] dct_v;
    logic                                                dct_valid;

    logic quan_valid;
    logic  [MCU_SIZE-1:0][MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] quan_y;
    logic  [MCU_SIZE-1:0][MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] quan_u;
    logic  [MCU_SIZE-1:0][MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] quan_v;

    logic                                            zig_valid;
    logic [MCU_SIZE*MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] zig_y;
    logic [MCU_SIZE*MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] zig_u;
    logic [MCU_SIZE*MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] zig_v;

    logic [7:0] huffman_data;
    logic       huffman_valid;


    // reg i_data_end;
    // logic [7:0]i_data;
    // logic i_data_valid;
    // wire o_data_send_ready;
    // wire [7:0]o_data;
    // wire o_valid;
    // wire o_data_end;
    //------------------------------------------

    //--------target module---------
    image_generater#(
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT),
        .PIXEL_BITWIDTH(PIXEL_BITWIDTH)        
    )
    gen_inst(
        .clk(clk),
        .n_rst(n_rst),
        .i_start(i_start),
        .o_axis_tdata(axis_tdata),
        .o_axis_tlast(axis_tlast),
        .o_axis_tuser(axis_tuser),
        .o_axis_tvalid(axis_tvalid),
        .i_axis_ready(axis_ready)    
    );

    top_jpeg#(
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT),
        .MCU_SIZE(MCU_SIZE),
        .PIXEL_BITWIDTH(PIXEL_BITWIDTH),
        .RGB_BITWIDTH(RGB_BITWIDTH),
        .DCT_BITWIDTH(DCT_BITWIDTH),
        .QUAN_BITWIDTH(QUAN_BITWIDTH)
        )
    top_inst
    (
        .i_axis_aclk(clk),    
        .i_axis_aresetn(n_rst),
        .i_axis_tdata(axis_tdata),
        .i_axis_tlast(axis_tlast),
        .i_axis_tuser(axis_tuser),
        .i_axis_tvalid(axis_tvalid),
        .o_axis_ready(axis_ready),
        .m_axis_aclk(clk),
        .m_axis_aresetn(n_rst),
        .m_axis_tdata(o_data),
        .m_axis_tstrb(m_axis_tstrb),
        .m_axis_tvalid(o_valid),
        .m_axis_tlast(o_last),
        .m_axis_tready(m_axis_ready)
    );
    //     .yuv_data(yuv_data),
    //     .yuv_tlast(yuv_tlast),
    //     .yuv_tuser(yuv_tuser),
    //     .yuv_tvalid(yuv_tvalid),
    //     .fifo_we(fifo_we),
    //     .mcu_data(mcu_data),
    //     .mcu_fifo_dout(mcu_fifo_dout),
    //     .dct_y(dct_y),
    //     .dct_u(dct_u),
    //     .dct_v(dct_v),
    //     .dct_valid(dct_valid),
    //     .quan_y(quan_y),
    //     .quan_u(quan_u),
    //     .quan_v(quan_v),
    //     .quan_valid(quan_valid),
    //     .zig_valid(zig_valid),
    //     .zig_y(zig_y),
    //     .zig_u(zig_u),
    //     .zig_v(zig_v),
    //     .huffman_data(huffman_data),
    //     .huffman_valid(huffman_valid)
    // );


    wire [31:0] count;
    counter counter_inst(
        .clk(clk),
        .n_rst(n_rst),
        .en(axis_tlast),
        .count(count)
    );

    always_comb begin
        yuv_data     = top_inst.yuv_data;
       yuv_tlast     = top_inst.yuv_tlast;
       yuv_tuser     = top_inst.yuv_tuser;
       yuv_tvalid    = top_inst.yuv_tvalid;
       fifo_we       = top_inst.fifo_we;
       mcu_data      = top_inst.mcu_data;
       mcu_fifo_dout = top_inst.mcu_fifo_dout;
       dct_y         = top_inst.dct_y;
       dct_u         = top_inst.dct_u;
       dct_v         = top_inst.dct_v;
       dct_valid     = top_inst.dct_valid;
       quan_y        = top_inst.quan_y;
       quan_u        = top_inst.quan_u;
       quan_v        = top_inst.quan_v;
       quan_valid    = top_inst.quan_valid;
       zig_valid     = top_inst.zig_valid;
       zig_y         = top_inst.zig_y;
       zig_u         = top_inst.zig_u;
       zig_v         = top_inst.zig_v;
       huffman_data  = top_inst.huffman_data;
       huffman_valid = top_inst.huffman_valid;
        
    end


    //------------------------------

    //clk
    initial begin
        clk <= 1'b0;
        forever begin
            #(CLK_PERIOD_NS/2) clk <= ~clk;
        end
    end

    //n_rst
    initial begin
        n_rst <= 1'b0;
        #(CLK_PERIOD_NS) n_rst = 1'b1;
    end

    assign m_axis_ready = 1'b1;


    //user's signal
    initial begin
        i_start = 1'b0;
        #(CLK_PERIOD_NS)
        i_start = 1'b1;
        #(CLK_PERIOD_NS)
        i_start = 1'b0;
    end

    int f,f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12,f13,f14,f15;
    initial begin
        f = $fopen("sw_verify/sim_result/image.dat","w");
        f1 = $fopen("sw_verify/sim_result/yuv.dat","w");
        f2 = $fopen("sw_verify/sim_result/mcu_y.dat","w");
        f3 = $fopen("sw_verify/sim_result/mcu_u.dat","w");
        f4 = $fopen("sw_verify/sim_result/mcu_v.dat","w");
        f5 = $fopen("sw_verify/sim_result/dct_y.dat","w");
        f6 = $fopen("sw_verify/sim_result/dct_u.dat","w");
        f7 = $fopen("sw_verify/sim_result/dct_v.dat","w");
        f8 = $fopen("sw_verify/sim_result/quan_y.dat","w");
        f9 = $fopen("sw_verify/sim_result/quan_u.dat","w");
        f10= $fopen("sw_verify/sim_result/quan_v.dat","w");
        f12= $fopen("sw_verify/sim_result/zig_y.dat","w");
        f13= $fopen("sw_verify/sim_result/zig_u.dat","w");
        f14= $fopen("sw_verify/sim_result/zig_v.dat","w");
        f15= $fopen("sw_verify/sim_result/huffman.dat","w");

        f11 = $fopen("sw_verify/sim_result/out.jpg","wb");        
    end
    //image data output
    always_ff @(posedge clk) begin
        if(axis_tvalid)
            $fdisplay(f,"%d,%d,%d",axis_tdata[PIXEL_BITWIDTH-1 -:RGB_BITWIDTH],axis_tdata[(PIXEL_BITWIDTH-RGB_BITWIDTH)-1 -:RGB_BITWIDTH],axis_tdata[(PIXEL_BITWIDTH-(RGB_BITWIDTH*2))-1 -:RGB_BITWIDTH]);
        //if(yuv_tvalid)
        //     $display("%x,%x,%x",yuv_data[PIXEL_BITWIDTH-1 -:RGB_BITWIDTH],yuv_data[(PIXEL_BITWIDTH-RGB_BITWIDTH)-1 -:RGB_BITWIDTH],yuv_data[(PIXEL_BITWIDTH-(RGB_BITWIDTH*2))-1 -:RGB_BITWIDTH]);
    end

    //rgb to yuv
    logic signed [RGB_BITWIDTH-1:0] y;
    logic signed [RGB_BITWIDTH-1:0] u;
    logic signed [RGB_BITWIDTH-1:0] v;
    always_comb begin
        y <= yuv_data[PIXEL_BITWIDTH-1 -:RGB_BITWIDTH];
        u <= yuv_data[(PIXEL_BITWIDTH-RGB_BITWIDTH)-1 -:RGB_BITWIDTH];
        v <= yuv_data[(PIXEL_BITWIDTH-(RGB_BITWIDTH*2))-1 -:RGB_BITWIDTH];
    end
    
    always_ff @(posedge clk) begin
        if(yuv_tvalid & !top_inst.mcu_fifo_full) begin    
            //$display("%d,%d,%d",y,u,v);
            $fdisplay(f1,"%d,%d,%d",y,u,v);
            //$fdisplay(f1,"%d,%d,%d",yuv_data[PIXEL_BITWIDTH-1 -:RGB_BITWIDTH],yuv_data[(PIXEL_BITWIDTH-RGB_BITWIDTH)-1 -:RGB_BITWIDTH],yuv_data[(PIXEL_BITWIDTH-(RGB_BITWIDTH*2))-1 -:RGB_BITWIDTH]);
        end
    end
    //mcu spliter
    logic signed [RGB_BITWIDTH-1:0] mcuy[MCU_SIZE-1:0][MCU_SIZE-1:0];
    logic signed [RGB_BITWIDTH-1:0] mcuu[MCU_SIZE-1:0][MCU_SIZE-1:0];
    logic signed [RGB_BITWIDTH-1:0] mcuv[MCU_SIZE-1:0][MCU_SIZE-1:0];
    always_comb begin
        for(int i = 0;i<MCU_SIZE;i++) begin
            for(int j = 0;j<MCU_SIZE;j++) begin
                mcuy[i][j] <= mcu_data[i][j][PIXEL_BITWIDTH-1 -: RGB_BITWIDTH];
                mcuu[i][j] <= mcu_data[i][j][PIXEL_BITWIDTH-RGB_BITWIDTH-1 -: RGB_BITWIDTH];
                mcuv[i][j] <= mcu_data[i][j][PIXEL_BITWIDTH-(RGB_BITWIDTH*2)-1 -: RGB_BITWIDTH];
            end
        end
    end

    always_ff @(posedge clk) begin
        if(fifo_we) begin
            for(int i = 0;i<MCU_SIZE;i++) begin
                    for(int j = 0;j<MCU_SIZE;j++) begin
                        if (i==MCU_SIZE-1 && j==MCU_SIZE-1) begin
                            $fwrite(f2,"%d",mcuy[i][j]);
                            $fwrite(f3,"%d",mcuu[i][j]);
                            $fwrite(f4,"%d",mcuv[i][j]);
                        end
                        else begin
                            $fwrite(f2,"%d,",mcuy[i][j]);
                            $fwrite(f3,"%d,",mcuu[i][j]);
                            $fwrite(f4,"%d,",mcuv[i][j]);
                        end
                    end
            end
            $fwrite(f2,"\n");
            $fwrite(f3,"\n");
            $fwrite(f4,"\n");
        end
    end

    //dct 
    logic signed [DCT_BITWIDTH-1:0]tmpy[MCU_SIZE-1:0][MCU_SIZE-1:0];
    logic signed [DCT_BITWIDTH-1:0]tmpu[MCU_SIZE-1:0][MCU_SIZE-1:0];
    logic signed [DCT_BITWIDTH-1:0]tmpv[MCU_SIZE-1:0][MCU_SIZE-1:0];
    always_comb begin
        for(int i=0;i<MCU_SIZE;i++) begin
            for(int j=0;j<MCU_SIZE;j++) begin
                tmpy[i][j] <= dct_y[i][j];
                tmpu[i][j] <= dct_u[i][j];
                tmpv[i][j] <= dct_v[i][j];
            end
        end
    end

    always_ff @(posedge clk) begin
        if(dct_valid & !top_inst.zig_fifo_full) begin
            for(int i = 0;i<MCU_SIZE;i++) begin
                    for(int j = 0;j<MCU_SIZE;j++) begin
                        if (i==MCU_SIZE-1 && j==MCU_SIZE-1) begin
                            $fwrite(f5,"%d",tmpy[i][j]);
                            $fwrite(f6,"%d",tmpu[i][j]);
                            $fwrite(f7,"%d",tmpv[i][j]);
                        end
                        else begin
                            $fwrite(f5,"%d,",tmpy[i][j]);
                            $fwrite(f6,"%d,",tmpu[i][j]);
                            $fwrite(f7,"%d,",tmpv[i][j]);
                        end
                    end
            end
            $fwrite(f5,"\n");
            $fwrite(f6,"\n");
            $fwrite(f7,"\n");
        end
    end


    //quan
    logic signed [QUAN_BITWIDTH-1:0]tmpqy[MCU_SIZE-1:0][MCU_SIZE-1:0];
    logic signed [QUAN_BITWIDTH-1:0]tmpqu[MCU_SIZE-1:0][MCU_SIZE-1:0];
    logic signed [QUAN_BITWIDTH-1:0]tmpqv[MCU_SIZE-1:0][MCU_SIZE-1:0];
    always_comb begin
        for(int i=0;i<MCU_SIZE;i++) begin
            for(int j=0;j<MCU_SIZE;j++) begin
                tmpqy[i][j] <= quan_y[i][j];
                tmpqu[i][j] <= quan_u[i][j];
                tmpqv[i][j] <= quan_v[i][j];
            end
        end
    end

    always_ff @(posedge clk) begin
        if(quan_valid & !top_inst.zig_fifo_full) begin
            for(int i = 0;i<MCU_SIZE;i++) begin
                    for(int j = 0;j<MCU_SIZE;j++) begin
                        if (i==MCU_SIZE-1 && j==MCU_SIZE-1) begin
                            $fwrite(f8,"%d",tmpqy[i][j]);
                            $fwrite(f9,"%d",tmpqu[i][j]);
                            $fwrite(f10,"%d",tmpqv[i][j]);
                        end
                        else begin
                            $fwrite(f8,"%d,",tmpqy[i][j]);
                            $fwrite(f9,"%d,",tmpqu[i][j]);
                            $fwrite(f10,"%d,",tmpqv[i][j]);
                        end
                    end
            end
            $fwrite(f8,"\n");
            $fwrite(f9,"\n");
            $fwrite(f10,"\n");

        end
    end

//zigzag
    logic signed [QUAN_BITWIDTH-1:0]tmpzy[MCU_SIZE-1:0][MCU_SIZE-1:0];
    logic signed [QUAN_BITWIDTH-1:0]tmpzu[MCU_SIZE-1:0][MCU_SIZE-1:0];
    logic signed [QUAN_BITWIDTH-1:0]tmpzv[MCU_SIZE-1:0][MCU_SIZE-1:0];
    always_comb begin
        for(int i=0;i<MCU_SIZE;i++) begin
            for(int j=0;j<MCU_SIZE;j++) begin
                tmpzy[i][j] <= zig_y[i*MCU_SIZE+j];
                tmpzu[i][j] <= zig_u[i*MCU_SIZE+j];
                tmpzv[i][j] <= zig_v[i*MCU_SIZE+j];
            end
        end
    end

    always_ff @(posedge clk) begin
        if(zig_valid & !top_inst.zig_fifo_full) begin
            for(int i = 0;i<MCU_SIZE;i++) begin
                    for(int j = 0;j<MCU_SIZE;j++) begin
                        if (i==MCU_SIZE-1 && j==MCU_SIZE-1) begin
                            $fwrite(f12,"%d",tmpzy[i][j]);
                            $fwrite(f13,"%d",tmpzu[i][j]);
                            $fwrite(f14,"%d",tmpzv[i][j]);
                        end
                        else begin
                            $fwrite(f12,"%d,",tmpzy[i][j]);
                            $fwrite(f13,"%d,",tmpzu[i][j]);
                            $fwrite(f14,"%d,",tmpzv[i][j]);
                        end
                    end
            end
            $fwrite(f12,"\n");
            $fwrite(f13,"\n");
            $fwrite(f14,"\n");

        end
    end

//huffman
    always_ff @(posedge clk) begin
        if(huffman_valid) begin
            $fdisplay(f15,"%d",huffman_data);
        end
    end


    always_ff @(posedge clk) begin
        if(o_valid) begin
            $fwrite(f11,"%c",o_data);
        end
    end



    //output
    initial begin
         //$monitor($time,,,"CLK=%d",clk);
        $dumpfile("sim_topmodule.vcd");
        $dumpvars(0,top_inst);
        $dumpvars(0,gen_inst);
        $dumpvars(0,counter_inst);
        #(CLK_PERIOD)
        $finish;
    end

endmodule
`default_nettype wire


module counter
(
    input wire clk,
    input wire n_rst,
    input wire en,
    output logic [31:0] count
);

    always_ff @(posedge clk ) begin
        if(!n_rst) begin
            count <= 32'd0;
        end        
        else if(en) begin
            count <= count + 32'd1;
        end
        else begin
            count <= count;
        end
    end


endmodule
