`default_nettype none

module dht_marker
#(
    parameter int DC_VVEC_SIZE = 12,
    parameter int AC_VVEC_SIZE = 162,
    parameter int BYTE_NUM = -1
)
(
    input wire     clk,
    input wire     n_rst,
    dht_if.master  dhtif,
    output logic [BYTE_NUM-1:0][7:0] marker
);

    
///------------各長さのハフマン符号が何個あるかを表す配列-----------
    
    ///DHTマーカーのヘッダー
    localparam [15:0] HEADER = 16'hFFC4;

    ///各セグメントのビット数
    localparam [15:0] Y_DC_LH = 16'h001F;
    localparam [15:0] UV_DC_LH = 16'h001F;
    localparam [15:0] Y_AC_LH = 16'h00B5;
    localparam [15:0] UV_AC_LH = 16'h00B5;

    ///上位４ビット：AC用かDC用かの識別番号
    ///下位４ビット：各セグメントの識別番号
    localparam [7:0] Y_DC_THN = 8'h00;
    localparam [7:0] UV_DC_THN = 8'h01;
    localparam [7:0] Y_AC_THN = 8'h10;
    localparam [7:0] UV_AC_THN = 8'h11;

///-----------------各セグメントのハフマン符号における，各ビット長の符号の個数--------------------
    // localparam [7:0] Y_DC_LVEC [15:0] = '{
    // localparam [(16*8)-1:0] Y_DC_LVEC = {
    //     8'h00, // 16bit
    //     8'h00, // 15bit
    //     8'h00, // 14bit
    //     8'h00, // 13bit
    //     8'h00, // 12bit
    //     8'h00, // 11bit
    //     8'h00, // 10bit
    //     8'h01, // 9bit
    //     8'h01, // 8bit
    //     8'h01, // 7bit
    //     8'h01, // 6bit
    //     8'h01, // 5bit
    //     8'h01, // 4bit
    //     8'h05, // 3bit
    //     8'h01, // 2bit
    //     8'h00  // 1bit;
    // };
    localparam [(16*8)-1:0] Y_DC_LVEC = {
        8'h00,  // 1bit;
        8'h01, // 2bit
        8'h05, // 3bit
        8'h01, // 4bit
        8'h01, // 5bit
        8'h01, // 6bit
        8'h01, // 7bit        
        8'h01, // 8bit
        8'h01, // 9bit
        8'h00, // 10bit
        8'h00, // 11bit
        8'h00, // 12bit
        8'h00, // 13bit
        8'h00, // 14bit
        8'h00, // 15bit
        8'h00 // 16bit
    };

    // localparam [7:0] UV_DC_LVEC [15:0] = '{
    // localparam [(16*8)-1:0] UV_DC_LVEC = {
    //     8'h00, // 16bit
    //     8'h00, // 15bit
    //     8'h00, // 14bit
    //     8'h00, // 13bit
    //     8'h00, // 12bit
    //     8'h01, // 11bit
    //     8'h01, // 10bit
    //     8'h01, // 9bit
    //     8'h01, // 8bit
    //     8'h01, // 7bit
    //     8'h01, // 6bit
    //     8'h01, // 5bit
    //     8'h01, // 4bit
    //     8'h01, // 3bit
    //     8'h03, // 2bit
    //     8'h00  // 1bit
    // };
        localparam [(16*8)-1:0] UV_DC_LVEC = {
        8'h00,  // 1bit
        8'h03, // 2bit
        8'h01, // 3bit
        8'h01, // 4bit
        8'h01, // 5bit
        8'h01, // 6bit
        8'h01, // 7bit
        8'h01, // 8bit
        8'h01, // 9bit
        8'h01, // 10bit
        8'h01, // 11bit
        8'h00, // 12bit
        8'h00, // 13bit
        8'h00, // 14bit
        8'h00, // 15bit
        8'h00 // 16bit

    };


    // localparam [7:0] Y_AC_LVEC [15:0] = '{
    // localparam [(16*8)-1:0] Y_AC_LVEC = {
    //     8'h7D, // 16bit
    //     8'h01, // 15bit
    //     8'h00, // 14bit
    //     8'h00, // 13bit
    //     8'h04, // 12bit
    //     8'h04, // 11bit
    //     8'h05, // 10bit
    //     8'h05, // 9bit
    //     8'h03, // 8bit
    //     8'h04, // 7bit
    //     8'h02, // 6bit
    //     8'h03, // 5bit
    //     8'h03, // 4bit
    //     8'h01, // 3bit
    //     8'h02, // 2bit
    //     8'h00  // 1bit
    // };
    localparam [(16*8)-1:0] Y_AC_LVEC = {
        8'h00, // 1bit
        8'h02, // 2bit
        8'h01, // 3bit
        8'h03, // 4bit
        8'h03, // 5bit
        8'h02, // 6bit
        8'h04, // 7bit
        8'h03, // 8bit
        8'h05, // 9bit
        8'h05, // 10bit
        8'h04, // 11bit
        8'h04, // 12bit
        8'h00, // 13bit
        8'h00, // 14bit
        8'h01, // 15bit
        8'h7D  // 16bit
    };



    // localparam [7:0] UV_AC_LVEC [15:0] = '{
    // localparam [(16*8)-1:0] UV_AC_LVEC = {
    //     8'h77, // 16bit
    //     8'h02, // 15bit
    //     8'h01, // 14bit
    //     8'h00, // 13bit
    //     8'h04, // 12bit
    //     8'h04, // 11bit
    //     8'h05, // 10bit
    //     8'h07, // 9bit
    //     8'h04, // 8bit
    //     8'h03, // 7bit
    //     8'h04, // 6bit
    //     8'h04, // 5bit
    //     8'h02, // 4bit
    //     8'h01, // 3bit
    //     8'h02, // 2bit
    //     8'h00  // 1bit
    // };
    localparam [(16*8)-1:0] UV_AC_LVEC = {
        8'h00, // 1bit
        8'h02, // 2bit
        8'h01, // 3bit
        8'h02, // 4bit
        8'h04, // 5bit
        8'h04, // 6bit
        8'h03, // 7bit
        8'h04, // 8bit
        8'h07, // 9bit
        8'h05, // 10bit
        8'h04, // 11bit
        8'h04, // 12bit
        8'h00, // 13bit
        8'h01, // 14bit
        8'h02, // 15bit
        8'h77  // 16bit
    };

//---------------------------------------------------------------------------------------

///----------------------DC成分のセグメントの各カテゴリに対する符号の割当て-----------------------
///DC成分は１個前のMCUのDC成分との差に対して符号化を行う  
///ex：１個前のMCUのDC成分が125，現在のMCUのDC成分が127 -> 127 - 125 = 2 に対して符号化する

    // localparam [(12*8)-1:0]Y_DC_VVEC  = {
    //     8'h0B, // Category 11
    //     8'h0A, // Category 10
    //     8'h09, // Category 9
    //     8'h08, // Category 8
    //     8'h07, // Category 7
    //     8'h06, // Category 6
    //     8'h05, // Category 5
    //     8'h04, // Category 4
    //     8'h03, // Category 3
    //     8'h02, // Category 2
    //     8'h01, // Category 1
    //     8'h00  // Category 0
    // };
    localparam [(12*8)-1:0]Y_DC_VVEC  = {
        8'h00, // Category 0
        8'h01, // Category 1
        8'h02, // Category 2
        8'h03, // Category 3
        8'h04, // Category 4
        8'h05, // Category 5
        8'h06, // Category 6
        8'h07, // Category 7
        8'h08, // Category 8
        8'h09, // Category 9
        8'h0A, // Category 10
        8'h0B  // Category 11
    };


    // localparam [(12*8)-1:0]UV_DC_VVEC  = {
    //     8'h0B, // Category 11
    //     8'h0A, // Category 10
    //     8'h09, // Category 9
    //     8'h08, // Category 8
    //     8'h07, // Category 7
    //     8'h06, // Category 6
    //     8'h05, // Category 5
    //     8'h04, // Category 4
    //     8'h03, // Category 3
    //     8'h02, // Category 2
    //     8'h01, // Category 1
    //     8'h00  // Category 0
    // };
    localparam [(12*8)-1:0]UV_DC_VVEC  = {
        8'h00, // Category 0
        8'h01, // Category 1
        8'h02, // Category 2
        8'h03, // Category 3
        8'h04, // Category 4
        8'h05, // Category 5
        8'h06, // Category 6
        8'h07, // Category 7
        8'h08, // Category 8
        8'h09, // Category 9
        8'h0A, // Category 10
        8'h0B  // Category 11
    };


//--------------------------------------------------------------------------------------    

///----------------------AC成分のセグメントの符号の割当て-------------------------------------
    // localparam [(AC_VVEC_SIZE*8)-1:0]Y_AC_VVEC  = {
    //     8'hFA, 8'hF9, 8'hF8, 8'hF7, 8'hF6, 8'hF5, 8'hF4, 8'hF3, //16bit
    //     8'hF2, 8'hF1, 8'hEA, 8'hE9, 8'hE8, 8'hE7, 8'hE6, 8'hE5,
    //     8'hE4, 8'hE3, 8'hE2, 8'hE1, 8'hDA, 8'hD9, 8'hD8, 8'hD7,
    //     8'hD6, 8'hD5, 8'hD4, 8'hD3, 8'hD2, 8'hCA, 8'hC9, 8'hC8,
    //     8'hC7, 8'hC6, 8'hC5, 8'hC4, 8'hC3, 8'hC2, 8'hBA, 8'hB9,
    //     8'hB8, 8'hB7, 8'hB6, 8'hB5, 8'hB4, 8'hB3, 8'hB2, 8'hAA,
    //     8'hA9, 8'hA8, 8'hA7, 8'hA6, 8'hA5, 8'hA4, 8'hA3, 8'hA2,
    //     8'h9A, 8'h99, 8'h98, 8'h97, 8'h96, 8'h95, 8'h94, 8'h93,
    //     8'h92, 8'h8A, 8'h89, 8'h88, 8'h87, 8'h86, 8'h85, 8'h84,
    //     8'h83, 8'h7A, 8'h79, 8'h78, 8'h77, 8'h76, 8'h75, 8'h74,
    //     8'h73, 8'h6A, 8'h69, 8'h68, 8'h67, 8'h66, 8'h65, 8'h64,
    //     8'h63, 8'h5A, 8'h59, 8'h58, 8'h57, 8'h56, 8'h55, 8'h54,
    //     8'h53, 8'h4A, 8'h49, 8'h48, 8'h47, 8'h46, 8'h45, 8'h44,
    //     8'h43, 8'h3A, 8'h39, 8'h38, 8'h37, 8'h36, 8'h35, 8'h34,
    //     8'h2A, 8'h29, 8'h28, 8'h27, 8'h26, 8'h25, 8'h1A, 8'h19,
    //     8'h18, 8'h17, 8'h16, 8'h0A, 8'h09, 
    //     8'h82, //15bit
    //     8'h72, 8'h62,8'h33, 8'h24, //12bit
    //     8'hF0, 8'hD1, 8'h52, 8'h15, //11bit
    //     8'hC1, 8'hB1, 8'h42, 8'h23, 8'h08, //10bit
    //     8'hA1, 8'h91, 8'h81, 8'h32, 8'h14, //9bit
    //     8'h71, 8'h22, 8'h07, //8bit
    //     8'h61, 8'h51, 8'h13, 8'h06, //7bit
    //     8'h41, 8'h31,  //6bit
    //     8'h21, 8'h12, 8'h05, //5bit
    //     8'h11, 8'h04, 8'h00, //4bit
    //     8'h03, //3bit
    //     8'h02, 8'h01 //2bit
    // };
    localparam [(AC_VVEC_SIZE*8)-1:0]Y_AC_VVEC  = {
        8'h01, 8'h02, //2bit
        8'h03, //3bit
        8'h00, 8'h04, 8'h11, //4bit
        8'h05, 8'h12, 8'h21, //5bit
        8'h31, 8'h41, //6bit
        8'h06, 8'h13, 8'h51, 8'h61, //7bit
        8'h07, 8'h22, 8'h71, //8bit
        8'h14, 8'h32, 8'h81, 8'h91, 8'hA1, //9bit
        8'h08, 8'h23, 8'h42, 8'hB1, 8'hC1, //10bit
        8'h15, 8'h52, 8'hD1, 8'hF0, //11bit
        8'h24, 8'h33, 8'h62, 8'h72, //12bit
        8'h82, //15bit
        8'h09, 8'h0A, 
        8'h16, 8'h17, 8'h18, 8'h19, 8'h1A, 8'h25, 8'h26, 8'h27, 8'h28, 8'h29, 8'h2A,
        8'h34, 8'h35, 8'h36, 8'h37, 8'h38, 8'h39, 8'h3A, 8'h43, 8'h44, 8'h45, 8'h46,
        8'h47, 8'h48, 8'h49, 8'h4A, 8'h53, 8'h54, 8'h55, 8'h56, 8'h57, 8'h58, 8'h59,
        8'h5A, 8'h63, 8'h64, 8'h65, 8'h66, 8'h67, 8'h68, 8'h69, 8'h6A, 8'h73, 8'h74,
        8'h75, 8'h76, 8'h77, 8'h78, 8'h79, 8'h7A, 8'h83, 8'h84, 8'h85, 8'h86, 8'h87,
        8'h88, 8'h89, 8'h8A, 8'h92, 8'h93, 8'h94, 8'h95, 8'h96, 8'h97, 8'h98, 8'h99,
        8'h9A, 8'hA2, 8'hA3, 8'hA4, 8'hA5, 8'hA6, 8'hA7, 8'hA8, 8'hA9, 8'hAA, 8'hB2,
        8'hB3, 8'hB4, 8'hB5, 8'hB6, 8'hB7, 8'hB8, 8'hB9, 8'hBA, 8'hC2, 8'hC3, 8'hC4,
        8'hC5, 8'hC6, 8'hC7, 8'hC8, 8'hC9, 8'hCA, 8'hD2, 8'hD3, 8'hD4, 8'hD5, 8'hD6,
        8'hD7, 8'hD8, 8'hD9, 8'hDA, 8'hE1, 8'hE2, 8'hE3, 8'hE4, 8'hE5, 8'hE6, 8'hE7,
        8'hE8, 8'hE9, 8'hEA, 8'hF1, 8'hF2, 8'hF3, 8'hF4, 8'hF5, 8'hF6, 8'hF7, 8'hF8,
        8'hF9, 8'hFA //16bit
    };



    // localparam [(AC_VVEC_SIZE*8)-1:0]UV_AC_VVEC = {
    //     8'hFA, 8'hF9, 8'hF8, 8'hF7, 8'hF6, 8'hF5, 8'hF4, 8'hF3,
    //     8'hF2, 8'hEA, 8'hE9, 8'hE8, 8'hE7, 8'hE6, 8'hE5, 8'hE4,
    //     8'hE3, 8'hE2, 8'hDA, 8'hD9, 8'hD8, 8'hD7, 8'hD6, 8'hD5,
    //     8'hD4, 8'hD3, 8'hD2, 8'hCA, 8'hC9, 8'hC8, 8'hC7, 8'hC6,
    //     8'hC5, 8'hC4, 8'hC3, 8'hC2, 8'hBA, 8'hB9, 8'hB8, 8'hB7,
    //     8'hB6, 8'hB5, 8'hB4, 8'hB3, 8'hB2, 8'hAA, 8'hA9, 8'hA8,
    //     8'hA7, 8'hA6, 8'hA5, 8'hA4, 8'hA3, 8'hA2, 8'h9A, 8'h99,
    //     8'h98, 8'h97, 8'h96, 8'h95, 8'h94, 8'h93, 8'h92, 8'h8A,
    //     8'h89, 8'h88, 8'h87, 8'h86, 8'h85, 8'h84, 8'h83, 8'h82,
    //     8'h7A, 8'h79, 8'h78, 8'h77, 8'h76, 8'h75, 8'h74, 8'h73,
    //     8'h6A, 8'h69, 8'h68, 8'h67, 8'h66, 8'h65, 8'h64, 8'h63,
    //     8'h5A, 8'h59, 8'h58, 8'h57, 8'h56, 8'h55, 8'h54, 8'h53,
    //     8'h4A, 8'h49, 8'h48, 8'h47, 8'h46, 8'h45, 8'h44, 8'h43,
    //     8'h3A, 8'h39, 8'h38, 8'h37, 8'h36, 8'h35, 8'h2A, 8'h29,
    //     8'h28, 8'h27, 8'h26, 8'h1A, 8'h19, 8'h18, 8'h17,  //16bit
    //     8'hF1, 8'h25, //15bit
    //     8'hE1, //14bit
    //     8'h34, 8'h24, 8'h16, 8'h0A, //12bit
    //     8'hD1, 8'h72, 8'h62, 8'h15, //11bit
    //     8'hF0, 8'h52, 8'h33, 8'h23, 8'h09, //10bit
    //     8'hC1, 8'hB1, 8'hA1, 8'h91, 8'h42, 8'h14, 8'h08, //9bit
    //     8'h81, 8'h32, 8'h22, 8'h13, //8bit
    //     8'h71, 8'h61, 8'h07, //7bit
    //     8'h51, 8'h41, 8'h12, 8'h06, //6bit
    //     8'h31, 8'h21, 8'h05, 8'h04, //5bit
    //     8'h11, 8'h03, //4bit
    //     8'h02, //3bit
    //     8'h01, 8'h00 //2bit
    // };
    localparam [(AC_VVEC_SIZE*8)-1:0]UV_AC_VVEC = {
        8'h00, 8'h01, //2bit
        8'h02, //3bit
        8'h03, 8'h11, //4bit
        8'h04, 8'h05, 8'h21, 8'h31, //5bit
        8'h06, 8'h12, 8'h41, 8'h51, //6bit
        8'h07, 8'h61, 8'h71, //7bit
        8'h13, 8'h22, 8'h32, 8'h81, //8bit
        8'h08, 8'h14, 8'h42, 8'h91, 8'hA1, 8'hB1, 8'hC1, //9bit
        8'h09, 8'h23, 8'h33, 8'h52, 8'hF0, //10bit
        8'h15, 8'h62, 8'h72, 8'hD1, //11bit
        8'h0A, 8'h16, 8'h24, 8'h34, //12bit
        8'hE1, //14bit
        8'h25, 8'hF1, //15bit
        8'h17, 8'h18, 8'h19, 8'h1A, 8'h26, 8'h27, 8'h28, 8'h29, 8'h2A, 8'h35, 8'h36,
        8'h37, 8'h38, 8'h39, 8'h3A, 8'h43, 8'h44, 8'h45, 8'h46, 8'h47, 8'h48, 8'h49,
        8'h4A, 8'h53, 8'h54, 8'h55, 8'h56, 8'h57, 8'h58, 8'h59, 8'h5A, 8'h63, 8'h64,
        8'h65, 8'h66, 8'h67, 8'h68, 8'h69, 8'h6A, 8'h73, 8'h74, 8'h75, 8'h76, 8'h77,
        8'h78, 8'h79, 8'h7A, 8'h82, 8'h83, 8'h84, 8'h85, 8'h86, 8'h87, 8'h88, 8'h89,
        8'h8A, 8'h92, 8'h93, 8'h94, 8'h95, 8'h96, 8'h97, 8'h98, 8'h99, 8'h9A, 8'hA2,
        8'hA3, 8'hA4, 8'hA5, 8'hA6, 8'hA7, 8'hA8, 8'hA9, 8'hAA, 8'hB2, 8'hB3, 8'hB4,
        8'hB5, 8'hB6, 8'hB7, 8'hB8, 8'hB9, 8'hBA, 8'hC2, 8'hC3, 8'hC4, 8'hC5, 8'hC6,
        8'hC7, 8'hC8, 8'hC9, 8'hCA, 8'hD2, 8'hD3, 8'hD4, 8'hD5, 8'hD6, 8'hD7, 8'hD8,
        8'hD9, 8'hDA, 8'hE2, 8'hE3, 8'hE4, 8'hE5, 8'hE6, 8'hE7, 8'hE8, 8'hE9, 8'hEA,
        8'hF2, 8'hF3, 8'hF4, 8'hF5, 8'hF6, 8'hF7, 8'hF8, 8'hF9, 8'hFA //16bit
    };



//--------------------------------------------------------------------------------------

    ///4つのDHTYセグメントをひとつのビット列に結合
    always_comb begin
        marker = {HEADER,Y_DC_LH,Y_DC_THN,Y_DC_LVEC,Y_DC_VVEC,
                            HEADER,UV_DC_LH,UV_DC_THN,UV_DC_LVEC,UV_DC_VVEC,
                            HEADER,Y_AC_LH,Y_AC_THN,Y_AC_LVEC,Y_AC_VVEC,
                            HEADER,UV_AC_LH,UV_AC_THN,UV_AC_LVEC,UV_AC_VVEC
                            };
    end


    ///符号長配列を１次元で取得（functionの戻り値は１次元しか無理なので）
    localparam  [8*(DC_VVEC_SIZE+1)-1:0] Y_DC_HUFFLENGTH_1D  = gen_DC_hufflength(Y_DC_LVEC);
    localparam  [8*(DC_VVEC_SIZE+1)-1:0] UV_DC_HUFFLENGTH_1D = gen_DC_hufflength(UV_DC_LVEC);
    localparam  [(8*AC_VVEC_SIZE+1)-1:0] Y_AC_HUFFLENGTH_1D  = gen_AC_hufflength(Y_AC_LVEC);
    localparam  [(8*AC_VVEC_SIZE+1)-1:0] UV_AC_HUFFLENGTH_1D = gen_AC_hufflength(UV_AC_LVEC);
    localparam  [(8*AC_VVEC_SIZE+1)-1:0] Y_AC_HUFFLENGTH_3D  = gen_AC_hufflength_3d(Y_AC_HUFFLENGTH_1D,Y_AC_VVEC);
    localparam  [(8*AC_VVEC_SIZE+1)-1:0] UV_AC_HUFFLENGTH_3D = gen_AC_hufflength_3d(UV_AC_HUFFLENGTH_1D,UV_AC_VVEC);
    
    localparam [(16*DC_VVEC_SIZE)-1:0]  Y_DC_HUFFCODE_1D    = gen_DC_huffcode(Y_DC_HUFFLENGTH_1D);     
    localparam [(16*DC_VVEC_SIZE)-1:0]  UV_DC_HUFFCODE_1D   = gen_DC_huffcode(UV_DC_HUFFLENGTH_1D);     
    localparam [(16*AC_VVEC_SIZE)-1:0]  Y_AC_HUFFCODE_1D    = gen_AC_huffcode(Y_AC_HUFFLENGTH_1D);
    localparam [(16*AC_VVEC_SIZE)-1:0]  UV_AC_HUFFCODE_1D   = gen_AC_huffcode(UV_AC_HUFFLENGTH_1D);
    localparam [(16*AC_VVEC_SIZE)-1:0] Y_AC_HUFFCODE_3D  = gen_AC_huffcode_3d(Y_AC_HUFFCODE_1D,Y_AC_VVEC);
    localparam [(16*AC_VVEC_SIZE)-1:0] UV_AC_HUFFCODE_3D  = gen_AC_huffcode_3d(UV_AC_HUFFCODE_1D,UV_AC_VVEC);

//dc成分
    int i;
    always_comb begin
        for (i = 0;i<DC_VVEC_SIZE;i++) begin
            dhtif.y_dc_hufflength[i]  = Y_DC_HUFFLENGTH_1D[i*8 +: 8];
            dhtif.uv_dc_hufflength[i] = UV_DC_HUFFLENGTH_1D[i*8 +: 8];
            dhtif.y_dc_huffcode[i]    = Y_DC_HUFFCODE_1D[i*16 +: 16] ;
            dhtif.uv_dc_huffcode[i]   = UV_DC_HUFFCODE_1D[i*16 +: 16] ;
        end 
    end


//ac成分
    int j,k;
    always_comb begin
        for(j = 0;j < 16;j++) begin
            for(k = 0;k < 10;k++) begin
                dhtif.y_ac_hufflength[j][k] = Y_AC_HUFFLENGTH_3D[(j*10+k) *8 +: 8]; 
                dhtif.y_ac_huffcode[j][k]   = Y_AC_HUFFCODE_3D[(j*10+k) *16 +: 16]; 
                dhtif.uv_ac_hufflength[j][k] = UV_AC_HUFFLENGTH_3D[(j*10+k) *8 +: 8]; 
                dhtif.uv_ac_huffcode[j][k]   = UV_AC_HUFFCODE_3D[(j*10+k) *16 +: 16]; 
            end
        end
        // for(j = 0;j < 160;j++) begin
        //         dhtif.y_ac_hufflength[j] = Y_AC_HUFFLENGTH_3D[(j *8) +: 8]; 
        //         dhtif.y_ac_huffcode[j]   = Y_AC_HUFFCODE_3D[(j *16) +: 16]; 
        //         dhtif.uv_ac_hufflength[j] = UV_AC_HUFFLENGTH_3D[(j *8) +: 8]; 
        //         dhtif.uv_ac_huffcode[j]   = UV_AC_HUFFCODE_3D[(j *16) +: 16]; 
        // end


        dhtif.y_eob_len  = Y_AC_HUFFLENGTH_3D[(AC_VVEC_SIZE-2)*8 +: 8];
        dhtif.y_eob      = Y_AC_HUFFCODE_3D[(AC_VVEC_SIZE-2)*16 +: 16];
        dhtif.uv_eob_len = UV_AC_HUFFLENGTH_3D[(AC_VVEC_SIZE-2)*8 +: 8];
        dhtif.uv_eob     = UV_AC_HUFFCODE_3D[(AC_VVEC_SIZE-2)*16 +: 16];
        dhtif.y_zrl_len  = Y_AC_HUFFLENGTH_3D[(AC_VVEC_SIZE-1)*8 +: 8];
        dhtif.y_zrl      = Y_AC_HUFFCODE_3D[(AC_VVEC_SIZE-1)*16 +: 16];
        dhtif.uv_zrl_len = UV_AC_HUFFLENGTH_3D[(AC_VVEC_SIZE-1)*8 +: 8];
        dhtif.uv_zrl     = UV_AC_HUFFCODE_3D[(AC_VVEC_SIZE-1)*16 +: 16];

    end






//---------------huffman符号のfunction--------------------------
    ///DC成分の各ハフマン符号の長さを計算
    function [8*(DC_VVEC_SIZE+1)-1:0] gen_DC_hufflength(  //8 bytes * 12+1 category bits
        input [(8*16)-1:0] LVEC
    );
        byte huff_length[DC_VVEC_SIZE:0];
        byte unsigned i;
        byte unsigned j;
        byte unsigned k;

        i = 1;
        j = 1;
        k = 0;

        while (!(i > 16)) begin
            //if(j > LVEC[(i-1)*8 +: 8]) begin
            if(j > LVEC[(16-i)*8 +: 8]) begin
                i = i+1;
                j = 1;
            end
            else begin
                //huff_length[k] = LVEC[1*8 +: 8];
                huff_length[k] = i;
                k = k+1;
                j = j+1;
            end
        end

        for(int l = 0;l<DC_VVEC_SIZE+1;l++) begin
            gen_DC_hufflength[8*l +: 8] = huff_length[l];
        end

    endfunction

    ///DC成分のハフマン符号語を計算
    function  [(16*DC_VVEC_SIZE)-1:0] gen_DC_huffcode(
        //input logic [7:0] HUFF_LENGTH [12:0]
        input [8*(DC_VVEC_SIZE+1)-1:0] HUFF_LENGTH 
    );
        byte k;
        shortint huff_table[DC_VVEC_SIZE-1:0];
        int code;
        byte si;
        
        k = 0;
        code = 0;
        si = HUFF_LENGTH[0 +: 8];

        while(HUFF_LENGTH[(k*8) +: 8] == si) begin
            huff_table[k] = code;
            code++;     
            k++;
            if(HUFF_LENGTH[(k*8) +: 8] == si) begin
                continue;
            end 
            else begin
                if(HUFF_LENGTH[(k*8) +: 8] == 0) begin
                    break;
                end
                else begin
                    code = code << 1;
                    si++;
                    while(1) begin
                        if(HUFF_LENGTH[(k*8) +: 8] == si) begin
                            break;
                        end
                        else begin
                            code = code << 1;
                            si++;
                        end
                    end
                end
            end
        end

        for(int l = 0;l<DC_VVEC_SIZE;l++) begin
            gen_DC_huffcode[l*16 +: 16] = huff_table[l];    
        end

    endfunction 

    ///AC成分の各ハフマン符号語の符号長を計算
    function [8*(AC_VVEC_SIZE+1)-1:0] gen_AC_hufflength(  //8 bytes * 162+1 num at code
         input [(16*8)-1:0] LVEC
     );
         byte huff_length[162:0];
         byte unsigned i;
         byte unsigned j;
         byte unsigned k;
    

         i = 1;
         j = 1;
         k = 0;

         while (!(i > 16)) begin
             if(j > LVEC[(16-i)*8 +: 8]) begin
                 i = i+1;
                 j = 1;
             end
             else begin
                 //huff_length[k] = LVEC[0*8 +: 8];
                 huff_length[k] = i;
                 k = k+1;
                 j = j+1;
             end
         end

         for(int l = 0;l<AC_VVEC_SIZE+1;l++) begin
             gen_AC_hufflength[8*l +: 8] = huff_length[l];
             //gen_AC_hufflength[8*l +: 8] = huff_length_second[78];

         end

     endfunction

    ///AC成分の各ハフマン符号語を計算
    function  unsigned [(16*162)-1:0] gen_AC_huffcode(
        //input logic [7:0] HUFF_LENGTH [12:0]
        input [8*(162+1)-1:0] HUFF_LENGTH 
    );
        byte unsigned k;
        shortint unsigned huff_table[161:0];
        int unsigned code;
        byte unsigned si;

        k = 0;
        code = 0;
        si = HUFF_LENGTH[0 +: 8];

        while(HUFF_LENGTH[(k*8) +: 8] == si) begin
            huff_table[k] = code;
            code++;     
            k++;
            if(HUFF_LENGTH[(k*8) +: 8] == si) begin
                continue;
            end 
            else begin
                if(HUFF_LENGTH[(k*8) +: 8] == 0) begin
                    break;
                end
                else begin
                    code = code << 1;
                    si++;
                    while(1) begin
                        if(HUFF_LENGTH[(k*8) +: 8] == si) begin
                            break;
                        end
                        else begin
                            code = code << 1;
                            si++;
                        end
                    end
                end
            end
        end

        for(int l = 0;l<AC_VVEC_SIZE;l++) begin
            gen_AC_huffcode[l*16 +: 16] = huff_table[l];    
        end

    endfunction 


    function [(8*(AC_VVEC_SIZE))-1:0] gen_AC_hufflength_3d(
        input [(16*AC_VVEC_SIZE)-1:0] HUFF_LENGTH_1D,
        input [(AC_VVEC_SIZE*8)-1:0] VVEC
    );
        byte  out[16][10];
        byte  target_LENGTH;
        byte  target_VVEC;
        byte  eob_len;
        byte  zrl_len;

        logic [3:0] length;
        logic [3:0] bits;
        
        for(int i=0; i< AC_VVEC_SIZE;i++) begin
            target_LENGTH = HUFF_LENGTH_1D[i*8 +: 8];
            //target_VVEC = VVEC[i*8 +: 8];
            target_VVEC = VVEC[(AC_VVEC_SIZE-i-1)*8 +: 8];
            length      = target_VVEC[7:4];
            bits        = target_VVEC[3:0];

            if((length==0) && (bits ==4'b0)) begin
                eob_len = target_LENGTH;
            end 
            else if((length==4'hF) && (bits== 4'b0)) begin
                zrl_len = target_LENGTH;
            end
            else begin
                out[length][bits-1] = target_LENGTH;
            end
        end

        for(int i = 0; i<16;i++) begin
            for(int j = 0;j<10;j++) begin
            gen_AC_hufflength_3d[(i*10 + j)*8 +: 8] = out[i][j];
            end
        end

        gen_AC_hufflength_3d[(AC_VVEC_SIZE-2)*8 +: 8] = eob_len;
        gen_AC_hufflength_3d[(AC_VVEC_SIZE-1)*8 +: 8] = zrl_len;


    endfunction


    function  unsigned [(16*(AC_VVEC_SIZE))-1:0] gen_AC_huffcode_3d(
        input [(16*AC_VVEC_SIZE)-1:0] HUFF_CODE_1D,
        input [(AC_VVEC_SIZE*8)-1:0] VVEC
    );
        shortint  out[16][10];
        shortint  target_CODE;
        byte      target_VVEC;
        shortint  eob_code;
        shortint  zrl_code;

        logic [3:0]     length;
        logic [3:0]     bits;
        
        for(int i=0; i< AC_VVEC_SIZE;i++) begin
            target_CODE = HUFF_CODE_1D[i*16 +: 16];
            //target_VVEC = VVEC[i*8 +: 8];
            target_VVEC = VVEC[(AC_VVEC_SIZE-i-1)*8 +: 8];
            length      = target_VVEC[7:4];
            bits        = target_VVEC[3:0];

            if((length==0) && (bits ==4'b0)) begin
                eob_code = target_CODE;
            end 
            else if((length==4'hF) && (bits== 4'b0)) begin
                zrl_code = target_CODE;
            end
            else begin
                out[length][bits-1] = target_CODE;
            end
        end

        for(int i = 0; i<16;i++) begin
            for(int j = 0;j<10;j++) begin
            gen_AC_huffcode_3d[(i*10 + j)*16 +: 16] = out[i][j];
            end
        end
        
        gen_AC_huffcode_3d[(AC_VVEC_SIZE-2)*16 +: 16] = eob_code;
        gen_AC_huffcode_3d[(AC_VVEC_SIZE-1)*16 +: 16] = zrl_code;

    endfunction

endmodule

`default_nettype wire   