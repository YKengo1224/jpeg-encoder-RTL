`default_nettype none

module top_jpeg#(
    parameter int WIDTH  = 1280,
    parameter int HEIGHT = 720,
    parameter int MCU_SIZE = 8,
    parameter int MCU_FIFO_SIZE = 50,
    parameter int ZIG_FIFO_SIZE = 50,
    parameter int PIXEL_BITWIDTH = 24,
    parameter int RGB_BITWIDTH = 8,
    parameter int DCT_BITWIDTH = 12,   //DCT_BITWIDTH <=14
    parameter int QUAN_BITWIDTH = 10
)
(
//   output wire                     mcu_fifo_f,
//   output wire                     mcu_fifo_e, 
//   output wire                     zig_fifo_f,
//   output wire                     yuv_va,
//   output wire                     yuv_llast,
//   output wire                     mcu_llast,
//   output wire                     mcu_fifo_w,
//   output wire                     mcu_fifo_r,
//   output wire                     mcu_fifo_llast,
//   output wire                     dct_va,
//   output wire                     dct_rready,
//   output wire                     quan_va,
//   output wire                     zig_fifo_r,
//   output wire                     dct_llast,
//   output wire                     quan_llast,
//   output wire                     huffman_llast,

    // input  wire                      clk,
    // input  wire                      n_rst,
    // input  wire [PIXEL_BITWIDTH-1:0] i_pixel,
    // input  wire                      i_data_start,
    // input  wire                      i_data_end,
    // output wire [7:0]                o_data,
    // output wire [7:0]                o_valid
  input wire                      i_axis_aclk,
  input wire                      i_axis_aresetn,
  input wire [PIXEL_BITWIDTH-1:0] i_axis_tdata,
  input wire                      i_axis_tlast,
  input wire                      i_axis_tuser,
  input wire                      i_axis_tvalid,
  output wire                     o_axis_ready,

  input wire                      m_axis_aclk,
  input wire                      m_axis_aresetn,
  output logic                    m_axis_tvalid,
  output wire [7:0]               m_axis_tdata,
  output wire                     m_axis_tstrb,
  output wire                     m_axis_tlast,
  input wire                      m_axis_tready


    // output wire   [7:0]                  o_data,
    // output wire                     o_valid,
    // output wire                     o_last

    //yuv
    // output wire [PIXEL_BITWIDTH-1:0] yuv_data,
    // output wire                      yuv_tlast,
    // output wire                      yuv_tuser,    
    // output wire                      yuv_tvalid,    

    // //mcu spliter
    // output wire fifo_we,
    // output wire [0:MCU_SIZE-1][0:MCU_SIZE-1][PIXEL_BITWIDTH-1:0] mcu_data,

    // //mcu fifo
    // output wire [0:MCU_SIZE-1][0:MCU_SIZE-1][PIXEL_BITWIDTH-1:0] mcu_fifo_dout,

    // // //dct calc
    // output wire [MCU_SIZE-1:0][MCU_SIZE-1:0][DCT_BITWIDTH-1:0] dct_y,
    // output wire [MCU_SIZE-1:0][MCU_SIZE-1:0][DCT_BITWIDTH-1:0] dct_u,
    // output wire [MCU_SIZE-1:0][MCU_SIZE-1:0][DCT_BITWIDTH-1:0] dct_v,
    // output wire                                                dct_valid,

    // //quan
    // output wire quan_valid,
    // output logic signed [MCU_SIZE-1:0][MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] quan_y,
    // output logic signed [MCU_SIZE-1:0][MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] quan_u,
    // output logic signed [MCU_SIZE-1:0][MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] quan_v,

    // //zigzag
    // output wire                                            zig_valid,
    // output wire [MCU_SIZE*MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] zig_y,
    // output wire [MCU_SIZE*MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] zig_u,
    // output wire [MCU_SIZE*MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] zig_v,


    // //zig_fifo
    // output wire [MCU_SIZE*MCU_SIZE-1:0][QUAN_BITWIDTH-1:0]  zig_fifo_y,
    // output wire [MCU_SIZE*MCU_SIZE-1:0][QUAN_BITWIDTH-1:0]  zig_fifo_u,
    // output wire [MCU_SIZE*MCU_SIZE-1:0][QUAN_BITWIDTH-1:0]  zig_fifo_v,
    // output logic                                            zig_fifo_valid,

    // output wire [7:0] huffman_data,
    // output wire       huffman_valid



);

        wire Master_wait;

    //yuv
    wire [PIXEL_BITWIDTH-1:0] yuv_data;
    wire                      yuv_tlast;
    wire                      yuv_tuser;    
    wire                      yuv_tvalid;    

    //mcu spliter
    wire fifo_we;
    wire [0:MCU_SIZE-1][0:MCU_SIZE-1][PIXEL_BITWIDTH-1:0] mcu_data;

    //mcu fifo
    wire [0:MCU_SIZE-1][0:MCU_SIZE-1][PIXEL_BITWIDTH-1:0] mcu_fifo_dout;

    //dct calc
    wire [MCU_SIZE-1:0][MCU_SIZE-1:0][DCT_BITWIDTH-1:0] dct_y;
    wire [MCU_SIZE-1:0][MCU_SIZE-1:0][DCT_BITWIDTH-1:0] dct_u;
    wire [MCU_SIZE-1:0][MCU_SIZE-1:0][DCT_BITWIDTH-1:0] dct_v;
    wire                                                dct_valid;

    //quan
    wire quan_valid;
    logic signed [MCU_SIZE-1:0][MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] quan_y;
    logic signed [MCU_SIZE-1:0][MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] quan_u;
    logic signed [MCU_SIZE-1:0][MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] quan_v;

    //zigzag
    wire                                            zig_valid;
    wire [MCU_SIZE*MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] zig_y;
    wire [MCU_SIZE*MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] zig_u;
    wire [MCU_SIZE*MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] zig_v;


    //zig_fifo
    wire [MCU_SIZE*MCU_SIZE-1:0][QUAN_BITWIDTH-1:0]  zig_fifo_y;
    wire [MCU_SIZE*MCU_SIZE-1:0][QUAN_BITWIDTH-1:0]  zig_fifo_u;
    wire [MCU_SIZE*MCU_SIZE-1:0][QUAN_BITWIDTH-1:0]  zig_fifo_v;
    logic                                            zig_fifo_valid;

    wire [7:0] huffman_data;
    wire       huffman_valid;




    wire zig_fifo_full;


    wire huffman_done;
    wire huffman_ready;
    // wire [7:0]huffman_data;
     wire      huffman_last;
    //wire  huffman_valid;

//------------------------------------------------------------------------------------
//marker maneger : start
//------------------------------------------------------------------------------------

    //-------------------SOI marker----------------------------
    localparam[15:0]       SOI = 16'hFFD8;

    //-------------------SOF marker----------------------------
    localparam int         SOF_BYTE_NUM = 19;
    localparam [15:0]      SOF_HEADER   = 16'hFFC0;
    localparam [15:0]      SOF_LF       = 16'h0011;
    localparam [7:0]       SOF_P        = 8'h08;
    localparam [15:0]      SOF_Y        = HEIGHT; 
    localparam [15:0]      SOF_X        = WIDTH;
    localparam [7:0]       SOF_NF       = 8'h03;
    // {成分ID，{水平，垂直サンプリング比},対応量:子化テーブル番号}
    localparam [(8*3)-1:0] SOF_C1       = {8'h01,8'h11,8'h00};   
    localparam [(8*3)-1:0] SOF_C2       = {8'h02,8'h11,8'h01};
    localparam [(8*3)-1:0] SOF_C3       = {8'h03,8'h11,8'h01};

    localparam [SOF_BYTE_NUM-1:0] [7:0]
    SOF_MARKER = {SOF_HEADER,SOF_LF,
                  SOF_P,SOF_Y,SOF_X,SOF_NF,SOF_C1,SOF_C2,SOF_C3};


    //-------------------SOS marker----------------------------
    localparam int    SOS_BYTE_NUM = 14;
    localparam [15:0] SOS_HEADER =  16'hFFDA;
    localparam [15:0] SOS_LS     =  16'h000C;
    localparam [7:0]  SOS_NS     =  8'h03;
    localparam [7:0]  SOS_CS1    =  8'h01;
    localparam [7:0]  SOS_TD_TA1 =  8'h00;
    localparam [7:0]  SOS_CS2    =  8'h02;
    localparam [7:0]  SOS_TD_TA2 =  8'h11;
    localparam [7:0]  SOS_CS3    =  8'h03;
    localparam [7:0]  SOS_TD_TA3 =  8'h11;
    localparam [7:0]  SOS_SS     =  8'h00;
    localparam [7:0]  SOS_SE     =  8'h3F;
    localparam [7:0]  SOS_AH_AI  =  8'h00;

    localparam [SOS_BYTE_NUM-1:0][7:0] 
    SOS_MARKER = {SOS_HEADER,SOS_LS,SOS_NS,SOS_CS1,
                  SOS_TD_TA1,SOS_CS2,SOS_TD_TA2,SOS_CS3,
                  SOS_TD_TA3,SOS_SS,SOS_SE,SOS_AH_AI};

    //-------------------DOT marker----------------------------
    localparam [15:0] DQT_LQ       = 16'h0084;
    localparam int    DQT_BYTE_NUM = 2 + DQT_LQ;

    wire [DQT_BYTE_NUM-1:0][7:0]           dqt_marker;
    wire [MCU_SIZE-1:0][MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] y_quan_table;
    wire [MCU_SIZE-1:0][MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] uv_quan_table;
    dqt_marker#(
        .MCU_SIZE(8),
        .QUAN_BITWIDTH(QUAN_BITWIDTH),
        .LQ(DQT_LQ),
        .BYTE_NUM(DQT_BYTE_NUM)
    )
    dqt_marker_inst(
        .marker_array(dqt_marker),
        .y_quan_table(y_quan_table),
        .uv_quan_table(uv_quan_table)
    );


    //-------------------DHT marker----------------------------
    localparam int DC_VVEC_SIZE = 12;
    localparam int AC_VVEC_SIZE = 162;
    // localparam int DHT_LH_BITWIDTH = 16*4;
    // localparam int DHT_THN_BITWIDTH = 8*4;
    // localparam int DHT_LVEC_BITWIDTH = (16*8)*4;
    // localparam int DHT_VVEC_BITWIDTH = ((12*8)*2) + ((AC_VVEC_SIZE*8)*2);
    // localparam int DHT_BYTE_NUM = (16 + DHT_LH_BITWIDTH + DHT_THN_BITWIDTH + 
    //                         DHT_LVEC_BITWIDTH + DHT_VVEC_BITWIDTH) / 8;
    localparam int DHT_LH_BYTE_NUM = 2*4;
    localparam int DHT_THN_BYTE_NUM = 4;
    localparam int DHT_LVEC_BYTE_NUM = 16*4;
    localparam int DHT_VVEC_BYTE_NUM = 2*(DC_VVEC_SIZE  + AC_VVEC_SIZE );
    localparam int DHT_BYTE_NUM = 2*4 + DHT_LH_BYTE_NUM + DHT_THN_BYTE_NUM + 
                                DHT_LVEC_BYTE_NUM + DHT_VVEC_BYTE_NUM ;


    dht_if                       dhtif();
    wire [DHT_BYTE_NUM-1:0][7:0] dht_marker;
    
    dht_marker#(
        .DC_VVEC_SIZE(DC_VVEC_SIZE),
        .AC_VVEC_SIZE(AC_VVEC_SIZE),
        .BYTE_NUM(DHT_BYTE_NUM)
    )
    dht_marker_inst(
        .clk(i_axis_aclk),
        .n_rst(i_axis_aresetn),
        .dhtif(dhtif),
        .marker(dht_marker)
    );


    //---------------------marker combine------------------------
    localparam int MARKER_BYTE_NUM = 2 + SOF_BYTE_NUM + SOS_BYTE_NUM + DQT_BYTE_NUM + DHT_BYTE_NUM; //( first :SOI)
    //wire [MARKER_BYTE_NUM-1:0][7:0]  i_marker_array;
    wire [0:MARKER_BYTE_NUM-1][7:0]  i_marker_array;
    //wire [DHT_BYTE_NUM-1:0][7:0]  i_marker_array;


    //assign i_marker_array = {SOI,dqt_marker,dht_marker,SOF_MARKER,SOS_MARKER};
    assign i_marker_array = {SOI,dqt_marker,dht_marker,SOF_MARKER,SOS_MARKER};


//------------------------------------------------------------------------------------
//send_ctrl
//------------------------------------------------------------------------------------
    logic send_data_ready;
    logic [7:0]send_data;
    logic send_valid;
    logic send_last;

    send_ctrl
    #(.MARKER_BYTE_NUM(MARKER_BYTE_NUM)
    )
    send_inst(
    .clk(i_axis_aclk),
    .n_rst(i_axis_aresetn),
    .i_start(i_axis_tuser),
    .i_wait(Master_wait),
    .i_data_end(huffman_last),
    .i_marker_array(i_marker_array),
    .i_data_valid(huffman_valid),
    .i_data(huffman_data),
    .o_data_send_ready(send_data_ready),
    .o_data(send_data),
    .o_valid(send_valid),
    .o_data_end(send_last)
    );

//------------------------------------------------------------------------------------
//AXI_Master  
//------------------------------------------------------------------------------------


    AXIS_Master#(
        .DATA_BITWIDTH(8),
        .FIFO_SIZE(10)
    )
    AXIS_Master_inst(
        .m_axis_aclk(i_axis_aclk),
        .m_axis_aresetn(i_axis_aresetn),
        .i_data(send_data),
        .i_valid(send_valid),
        .i_data_end(send_last),
        .o_wait(Master_wait),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tstrb(m_axis_tstrb),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tready(m_axis_tready)
    );
    

//------------------------------------------------------------------------------------
//yuv  
//------------------------------------------------------------------------------------
    // wire [PIXEL_BITWIDTH-1:0] yuv_data;
    // wire                      yuv_tlast;
    // wire                      yuv_tuser;    
    // wire                      yuv_tvalid;    
     rgb2yuv#(
        .PIXEL_BITWIDTH(PIXEL_BITWIDTH),
        .RGB_BITWIDTH(RGB_BITWIDTH)
    )
    rgb2yuv_inst(
        .clk(i_axis_aclk),
        .n_rst(i_axis_aresetn),
        .i_wait(mcu_fifo_full),
        .i_tdata(i_axis_tdata),
        .i_tlast(i_axis_tlast),
        .i_tuser(i_axis_tuser),
        .i_tvalid(i_axis_tvalid),
        .o_yuv(yuv_data),
        .o_tlast(yuv_tlast),
        .o_tuser(yuv_tuser),
        .o_tvalid(yuv_tvalid)
    );



//------------------------------------------------------------------------------------
//mcu_spliter 
//------------------------------------------------------------------------------------
    wire mcu_fifo_full;

    wire mcu_last;
    // wire fifo_we;
    // wire [MCU_SIZE-1:0][MCU_SIZE-1:0][PIXEL_BITWIDTH-1:0] mcu_data;
    assign o_axis_ready = !mcu_fifo_full;
    mcu_spliter#(
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT),
        .PIXEL_BITWIDTH(PIXEL_BITWIDTH),
        .MCU_SIZE(MCU_SIZE)
    )
    mcu_spliter_inst(
        .clk(i_axis_aclk),
        .n_rst(i_axis_aresetn),
        .i_yuv(yuv_data),
        .i_tlast(yuv_tlast),
        .i_tuser(yuv_tuser),
        .i_tvalid(yuv_tvalid),
        .i_wait(mcu_fifo_full),
        .o_mcu(mcu_data),
        .o_valid(fifo_we),
        .o_last(mcu_last)
    );

//------------------------------------------------------------------------------------
//mcu_fifo
//------------------------------------------------------------------------------------
    
    //wire [MCU_SIZE-1:0][MCU_SIZE-1:0][PIXEL_BITWIDTH-1:0] mcu_fifo_dout;
    wire mcu_fifo_emp;
    wire mcu_fifo_valid;
    logic mcu_fifo_re;
    wire mcu_fifo_last;

    wire dct_ready;

    // always_ff @(posedge i_axis_aclk) begin
    //     if(!i_axis_aresetn) begin
    //         mcu_fifo_re <= 1'b0;
    //     end
    //     else begin
    //         mcu_fifo_re <= dct_ready;
    //     end
    // end
    always_comb begin
        mcu_fifo_re = dct_ready & !mcu_fifo_emp & !zig_fifo_full;
    end    

    mcu_fifo#(
        .FIFO_SIZE(MCU_FIFO_SIZE),
        .MCU_SIZE(MCU_SIZE),
        .BIT_WIDTH(PIXEL_BITWIDTH)
    )
    mcu_fifo_inst(
        .clk(i_axis_aclk),
        .n_rst(i_axis_aresetn),
        .we(fifo_we),
        .re(mcu_fifo_re),
        .din(mcu_data),
        .i_last(mcu_last),
        .empty(mcu_fifo_emp),
        .full(mcu_fifo_full),
        .dout(mcu_fifo_dout),
        .o_last(mcu_fifo_last),
        .o_valid(mcu_fifo_valid)
    );


//------------------------------------------------------------------------------------
//dct calc
//------------------------------------------------------------------------------------
    // localparam int DCT_BITWIDTH = 12;
    // wire [MCU_SIZE-1:0][MCU_SIZE-1:0][DCT_BITWIDTH-1:0] dct_y;
    // wire [MCU_SIZE-1:0][MCU_SIZE-1:0][DCT_BITWIDTH-1:0] dct_u;
    // wire [MCU_SIZE-1:0][MCU_SIZE-1:0][DCT_BITWIDTH-1:0] dct_v;
    // wire                                                dct_valid;
    wire dct_last;

    yuv_dct_calclator#(
        .MCU_SIZE(MCU_SIZE),
        .PIXEL_BITWIDTH(PIXEL_BITWIDTH),
        .YUV_BITWIDTH(RGB_BITWIDTH),
        .OUT_BITWIDTH(DCT_BITWIDTH)
    )
    yuv_dct_calclator_inst(
        .clk(i_axis_aclk),
        .n_rst(i_axis_aresetn),
        .i_start(mcu_fifo_valid),
        .i_mcu(mcu_fifo_dout),
        .i_last(mcu_fifo_last),
        .i_wait(zig_fifo_full),
        .o_ready(dct_ready),
        .o_y(dct_y),
        .o_u(dct_u),
        .o_v(dct_v),
        .o_last(dct_last),
        .o_valid(dct_valid)
    );


//------------------------------------------------------------------------------------
//quantization 
//------------------------------------------------------------------------------------


    // wire quan_valid;
    // logic signed [MCU_SIZE-1:0][MCU_SIZE-1:0][DCT_BITWIDTH-1:0] quan_y;
    // logic signed [MCU_SIZE-1:0][MCU_SIZE-1:0][DCT_BITWIDTH-1:0] quan_u;
    // logic signed [MCU_SIZE-1:0][MCU_SIZE-1:0][DCT_BITWIDTH-1:0] quan_v;
    wire quan_last;

    yuv_quantizer #(
        .MCU_SIZE(MCU_SIZE),
        .DCT_BITWIDTH(DCT_BITWIDTH),
        .QUAN_BITWIDTH(QUAN_BITWIDTH)
    )
    yuv_quantizer_inst(
        .clk(i_axis_aclk),
        .n_rst(i_axis_aresetn),
        .i_dct_valid(dct_valid),
        .i_dct_y(dct_y),
        .i_dct_u(dct_u),
        .i_dct_v(dct_v),
        .i_last(dct_last),
        .i_y_quan_table(y_quan_table),
        .i_uv_quan_table(uv_quan_table),
        .i_wait(zig_fifo_full),
        .o_quan_valid(quan_valid),
        .o_quan_y(quan_y),
        .o_quan_u(quan_u),
        .o_quan_v(quan_v),
        .o_last(quan_last)
    );

//------------------------------------------------------------------------------------
//zigzag scan
//------------------------------------------------------------------------------------p
    // wire                                            zig_valid;
    // wire [MCU_SIZE*MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] zig_y;
    // wire [MCU_SIZE*MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] zig_u;
    // wire [MCU_SIZE*MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] zig_v;
    wire zig_last;

    zigzag_scan#(
        .MCU_SIZE(MCU_SIZE),
        .QUAN_BITWIDTH(QUAN_BITWIDTH)
    )
    zigzag_scan_inst(
        .clk(i_axis_aclk),
        .n_rst(i_axis_aresetn),
        .idata_en(quan_valid),
        .i_quan_y(quan_y),
        .i_quan_u(quan_u),
        .i_quan_v(quan_v),
        .i_last(quan_last),
        .i_wait(zig_fifo_full),
        .o_zig_y(zig_y),
        .o_zig_u(zig_u),
        .o_zig_v(zig_v),
        .o_last(zig_last),
        .o_data_valid(zig_valid)
    );

//------------------------------------------------------------------------------------
//zig_fifo
//------------------------------------------------------------------------------------p
    logic  zig_fifo_empty;
    // wire [MCU_SIZE*MCU_SIZE-1:0][QUAN_BITWIDTH-1:0]  zig_fifo_y;
    // wire [MCU_SIZE*MCU_SIZE-1:0][QUAN_BITWIDTH-1:0]  zig_fifo_u;
    // wire [MCU_SIZE*MCU_SIZE-1:0][QUAN_BITWIDTH-1:0]  zig_fifo_v;
    // logic  zig_fifo_valid;

    wire zig_fifo_last;
    logic zig_fifo_re;

    always_comb begin
        zig_fifo_re = !zig_fifo_empty & huffman_ready;
    end

    zig_fifo#(
        .FIFO_SIZE(ZIG_FIFO_SIZE),
        .MCU_SIZE(MCU_SIZE),
        .BIT_WIDTH(QUAN_BITWIDTH)
    )
    zig_fifo_inst(
        .clk(i_axis_aclk),
        .n_rst(i_axis_aresetn),
        .i_we(zig_valid),
        .i_re(zig_fifo_re),
        .i_y(zig_y),
        .i_u(zig_u),
        .i_v(zig_v),
        .i_wait(Master_wait),
        .i_last(zig_last),
        .o_empty(zig_fifo_empty),
        .o_full(zig_fifo_full),
        .o_y(zig_fifo_y),
        .o_u(zig_fifo_u),
        .o_v(zig_fifo_v),
        .o_last(zig_fifo_last),
        .o_valid(zig_fifo_valid)
    );



//------------------------------------------------------------------------------------
//huffman encode 
//------------------------------------------------------------------------------------p


    yuv_huffman_encoder#(
        .MCU_SIZE(MCU_SIZE),
        .DATA_BITWIDTH(QUAN_BITWIDTH),
        .DC_VVEC_SIZE(DC_VVEC_SIZE)
    )
    yuv_huffman_encoder_inst(
        .clk(i_axis_aclk),
        .n_rst(i_axis_aresetn),
        .dhtif(dhtif),
        .i_mcu_y(zig_fifo_y),
        .i_mcu_u(zig_fifo_u),
        .i_mcu_v(zig_fifo_v),
        .i_send_ready(send_data_ready),
        .i_start(zig_fifo_valid),        
        .i_data_end(zig_fifo_last),
        .i_wait(Master_wait),
        .o_ready(huffman_ready),
        .o_done(huffman_done),
        .o_data(huffman_data),
        .o_last(huffman_last),
        .o_valid(huffman_valid)
    );

//    assign                    mcu_fifo_f=mcu_fifo_full;
//    assign                    mcu_fifo_e=mcu_fifo_emp;
//    assign                    zig_fifo_f=zig_fifo_full;
//    assign                    yuv_va = yuv_tvalid;
//    assign                    yuv_llast = yuv_tlast;
//    assign                    mcu_llast = mcu_last;
//    assign                    mcu_fifo_w = fifo_we;
//    assign                    mcu_fifo_r = mcu_fifo_re;
//    assign                    mcu_fifo_llast = mcu_fifo_last;
//    assign                    dct_va = dct_valid;
//    assign                    dct_rready = dct_ready;
//    assign                    quan_va = quan_valid;
//    assign                    zig_fifo_r = zig_fifo_re;
//    assign                    dct_llast = dct_last;
//    assign                    quan_llast = quan_last;
//    assign                    huffman_llast = huffman_last;
   

endmodule

`default_nettype wire
