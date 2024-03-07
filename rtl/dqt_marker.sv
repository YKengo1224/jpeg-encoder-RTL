`default_nettype none

module dqt_marker
#(
    parameter int MCU_SIZE = -1,
    parameter int QUAN_BITWIDTH = -1,
    parameter [15:0] LQ = 16'h0084,
    parameter int BYTE_NUM = 'h2+LQ
)
//量子化後のビット幅をDCT変換後から２削りたい場合，量子化テーブルは必ず４以上にすること
//3ビット削りたいときは8以上にすること
(
    output logic [BYTE_NUM-1:0][7:0] marker_array,
    output logic [MCU_SIZE-1:0][MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] y_quan_table,
    output logic [MCU_SIZE-1:0][MCU_SIZE-1:0][QUAN_BITWIDTH-1:0] uv_quan_table
    //output logic [QUAN_BITWIDTH-1:0] y_quan_table[MCU_SIZE-1:0][MCU_SIZE-1:0],
    //output logic [QUAN_BITWIDTH-1:0] uv_quan_table[MCU_SIZE-1:0][MCU_SIZE-1:0]

);


    localparam [7:0] Y_QUAN [0:7][0:7] = '{
        '{16, 11, 10, 16, 24, 40, 51, 61}, 
        '{12, 12, 14, 19, 26, 58, 60, 55}, 
        '{14, 13, 16, 24, 40, 57, 69, 56}, 
        '{14, 17, 22, 29, 51, 87, 80, 62}, 
        '{18, 22, 37, 56, 68, 109, 103, 77}, 
        '{24, 35, 55, 64, 81, 104, 113, 92}, 
        '{49, 64, 78, 87, 103, 121, 120, 101}, 
        '{72, 92, 95, 98, 112, 100, 103, 99}
    };

    // localparam [7:0] Y_QUAN [0:63] = '{
    //     16, 11, 10, 16, 24, 40, 51, 61, 
    //     12, 12, 14, 19, 26, 58, 60, 55, 
    //     14, 13, 16, 24, 40, 57, 69, 56, 
    //     14, 17, 22, 29, 51, 87, 80, 62, 
    //     18, 22, 37, 56, 68, 109, 103, 77, 
    //     24, 35, 55, 64, 81, 104, 113, 92, 
    //     49, 64, 78, 87, 103, 121, 120, 101, 
    //     72, 92, 95, 98, 112, 100, 103, 99
    // };

    localparam [7:0] UV_QUAN[0:7][0:7] = '{
        '{17, 18, 24, 47, 99, 99, 99, 99},
        '{18, 21, 26, 66, 99, 99, 99, 99},
        '{24, 26, 56, 99, 99, 99, 99, 99},
        '{47, 66, 99, 99, 99, 99, 99, 99},
        '{99, 99, 99, 99, 99, 99, 99, 99},
        '{99, 99, 99, 99, 99, 99, 99, 99},
        '{99, 99, 99, 99, 99, 99, 99, 99},
        '{99, 99, 99, 99, 99, 99, 99, 99}
    };


    // localparam [7:0] UV_QUAN [0:63] = '{
    //     17, 18, 24, 47, 99, 99, 99, 99,
    //     18, 21, 26, 66, 99, 99, 99, 99,
    //     24, 26, 56, 99, 99, 99, 99, 99,
    //     47, 66, 99, 99, 99, 99, 99, 99,
    //     99, 99, 99, 99, 99, 99, 99, 99,
    //     99, 99, 99, 99, 99, 99, 99, 99,
    //     99, 99, 99, 99, 99, 99, 99, 99,
    //     99, 99, 99, 99, 99, 99, 99, 99
    // };




    localparam FIXED = 1<<QUAN_BITWIDTH;
    
    localparam int Y_QUAN_FIXED[0:7][0:7] = '{
        '{FIXED/Y_QUAN[0][0], FIXED/Y_QUAN[0][1], FIXED/Y_QUAN[0][2], FIXED/Y_QUAN[0][3], FIXED/Y_QUAN[0][4], FIXED/Y_QUAN[0][5], FIXED/Y_QUAN[0][6], FIXED/Y_QUAN[0][7]},
        '{FIXED/Y_QUAN[1][0], FIXED/Y_QUAN[1][1], FIXED/Y_QUAN[1][2], FIXED/Y_QUAN[1][3], FIXED/Y_QUAN[1][4], FIXED/Y_QUAN[1][5], FIXED/Y_QUAN[1][6], FIXED/Y_QUAN[1][7]},
        '{FIXED/Y_QUAN[2][0], FIXED/Y_QUAN[2][1], FIXED/Y_QUAN[2][2], FIXED/Y_QUAN[2][3], FIXED/Y_QUAN[2][4], FIXED/Y_QUAN[2][5], FIXED/Y_QUAN[2][6], FIXED/Y_QUAN[2][7]},
        '{FIXED/Y_QUAN[3][0], FIXED/Y_QUAN[3][1], FIXED/Y_QUAN[3][2], FIXED/Y_QUAN[3][3], FIXED/Y_QUAN[3][4], FIXED/Y_QUAN[3][5], FIXED/Y_QUAN[3][6], FIXED/Y_QUAN[3][7]},
        '{FIXED/Y_QUAN[4][0], FIXED/Y_QUAN[4][1], FIXED/Y_QUAN[4][2], FIXED/Y_QUAN[4][3], FIXED/Y_QUAN[4][4], FIXED/Y_QUAN[4][5], FIXED/Y_QUAN[4][6], FIXED/Y_QUAN[4][7]},
        '{FIXED/Y_QUAN[5][0], FIXED/Y_QUAN[5][1], FIXED/Y_QUAN[5][2], FIXED/Y_QUAN[5][3], FIXED/Y_QUAN[5][4], FIXED/Y_QUAN[5][5], FIXED/Y_QUAN[5][6], FIXED/Y_QUAN[5][7]},
        '{FIXED/Y_QUAN[6][0], FIXED/Y_QUAN[6][1], FIXED/Y_QUAN[6][2], FIXED/Y_QUAN[6][3], FIXED/Y_QUAN[6][4], FIXED/Y_QUAN[6][5], FIXED/Y_QUAN[6][6], FIXED/Y_QUAN[6][7]},
        '{FIXED/Y_QUAN[7][0], FIXED/Y_QUAN[7][1], FIXED/Y_QUAN[7][2], FIXED/Y_QUAN[7][3], FIXED/Y_QUAN[7][4], FIXED/Y_QUAN[7][5], FIXED/Y_QUAN[7][6], FIXED/Y_QUAN[7][7]}
    };

    // localparam [QUAN_BITWIDTH-1:0] Y_QUAN_FIXED[0:7][0:7] = '{
    //     '{FIXED/Y_QUAN[0], FIXED/Y_QUAN[1], FIXED/Y_QUAN[2], FIXED/Y_QUAN[3], FIXED/Y_QUAN[4], FIXED/Y_QUAN[5], FIXED/Y_QUAN[6], FIXED/Y_QUAN[7]},
    //     '{FIXED/Y_QUAN[8], FIXED/Y_QUAN[9], FIXED/Y_QUAN[10], FIXED/Y_QUAN[11], FIXED/Y_QUAN[12], FIXED/Y_QUAN[13], FIXED/Y_QUAN[14], FIXED/Y_QUAN[15]},
    //     '{FIXED/Y_QUAN[16], FIXED/Y_QUAN[17], FIXED/Y_QUAN[18], FIXED/Y_QUAN[19], FIXED/Y_QUAN[20], FIXED/Y_QUAN[21], FIXED/Y_QUAN[22], FIXED/Y_QUAN[23]},
    //     '{FIXED/Y_QUAN[24], FIXED/Y_QUAN[25], FIXED/Y_QUAN[26], FIXED/Y_QUAN[27], FIXED/Y_QUAN[28], FIXED/Y_QUAN[29], FIXED/Y_QUAN[30], FIXED/Y_QUAN[31]},
    //     '{FIXED/Y_QUAN[32], FIXED/Y_QUAN[33], FIXED/Y_QUAN[34], FIXED/Y_QUAN[35], FIXED/Y_QUAN[36], FIXED/Y_QUAN[37], FIXED/Y_QUAN[38], FIXED/Y_QUAN[39]},
    //     '{FIXED/Y_QUAN[40], FIXED/Y_QUAN[41], FIXED/Y_QUAN[42], FIXED/Y_QUAN[43], FIXED/Y_QUAN[44], FIXED/Y_QUAN[45], FIXED/Y_QUAN[46], FIXED/Y_QUAN[47]},
    //     '{FIXED/Y_QUAN[48], FIXED/Y_QUAN[49], FIXED/Y_QUAN[50], FIXED/Y_QUAN[51], FIXED/Y_QUAN[52], FIXED/Y_QUAN[53], FIXED/Y_QUAN[54], FIXED/Y_QUAN[55]},
    //     '{FIXED/Y_QUAN[56], FIXED/Y_QUAN[57], FIXED/Y_QUAN[58], FIXED/Y_QUAN[59], FIXED/Y_QUAN[60], FIXED/Y_QUAN[61], FIXED/Y_QUAN[62], FIXED/Y_QUAN[63]}
    // };

    localparam [QUAN_BITWIDTH-1:0] UV_QUAN_FIXED[0:7][0:7] = '{
        '{FIXED/UV_QUAN[0][0], FIXED/UV_QUAN[0][1], FIXED/UV_QUAN[0][2], FIXED/UV_QUAN[0][3], FIXED/UV_QUAN[0][4], FIXED/UV_QUAN[0][5], FIXED/UV_QUAN[0][6], FIXED/UV_QUAN[0][7]},
        '{FIXED/UV_QUAN[1][0], FIXED/UV_QUAN[1][1], FIXED/UV_QUAN[1][2], FIXED/UV_QUAN[1][3], FIXED/UV_QUAN[1][4], FIXED/UV_QUAN[1][5], FIXED/UV_QUAN[1][6], FIXED/UV_QUAN[1][7]},
        '{FIXED/UV_QUAN[2][0], FIXED/UV_QUAN[2][1], FIXED/UV_QUAN[2][2], FIXED/UV_QUAN[2][3], FIXED/UV_QUAN[2][4], FIXED/UV_QUAN[2][5], FIXED/UV_QUAN[2][6], FIXED/UV_QUAN[2][7]},
        '{FIXED/UV_QUAN[3][0], FIXED/UV_QUAN[3][1], FIXED/UV_QUAN[3][2], FIXED/UV_QUAN[3][3], FIXED/UV_QUAN[3][4], FIXED/UV_QUAN[3][5], FIXED/UV_QUAN[3][6], FIXED/UV_QUAN[3][7]},
        '{FIXED/UV_QUAN[4][0], FIXED/UV_QUAN[4][1], FIXED/UV_QUAN[4][2], FIXED/UV_QUAN[4][3], FIXED/UV_QUAN[4][4], FIXED/UV_QUAN[4][5], FIXED/UV_QUAN[4][6], FIXED/UV_QUAN[4][7]},
        '{FIXED/UV_QUAN[5][0], FIXED/UV_QUAN[5][1], FIXED/UV_QUAN[5][2], FIXED/UV_QUAN[5][3], FIXED/UV_QUAN[5][4], FIXED/UV_QUAN[5][5], FIXED/UV_QUAN[5][6], FIXED/UV_QUAN[5][7]},
        '{FIXED/UV_QUAN[6][0], FIXED/UV_QUAN[6][1], FIXED/UV_QUAN[6][2], FIXED/UV_QUAN[6][3], FIXED/UV_QUAN[6][4], FIXED/UV_QUAN[6][5], FIXED/UV_QUAN[6][6], FIXED/UV_QUAN[6][7]},
        '{FIXED/UV_QUAN[7][0], FIXED/UV_QUAN[7][1], FIXED/UV_QUAN[7][2], FIXED/UV_QUAN[7][3], FIXED/UV_QUAN[7][4], FIXED/UV_QUAN[7][5], FIXED/UV_QUAN[7][6], FIXED/UV_QUAN[7][7]}
    };

    // localparam [QUAN_BITWIDTH-1:0] UV_QUAN_FIXED[0:7][0:7] = '{
    //     '{FIXED/UV_QUAN[0], FIXED/UV_QUAN[1], FIXED/UV_QUAN[2], FIXED/UV_QUAN[3], FIXED/UV_QUAN[4], FIXED/UV_QUAN[5], FIXED/UV_QUAN[6], FIXED/UV_QUAN[7]},
    //     '{FIXED/UV_QUAN[8], FIXED/UV_QUAN[9], FIXED/UV_QUAN[10], FIXED/UV_QUAN[11], FIXED/UV_QUAN[12], FIXED/UV_QUAN[13], FIXED/UV_QUAN[14], FIXED/UV_QUAN[15]},
    //     '{FIXED/UV_QUAN[16], FIXED/UV_QUAN[17], FIXED/UV_QUAN[18], FIXED/UV_QUAN[19], FIXED/UV_QUAN[20], FIXED/UV_QUAN[21], FIXED/UV_QUAN[22], FIXED/UV_QUAN[23]},
    //     '{FIXED/UV_QUAN[24], FIXED/UV_QUAN[25], FIXED/UV_QUAN[26], FIXED/UV_QUAN[27], FIXED/UV_QUAN[28], FIXED/UV_QUAN[29], FIXED/UV_QUAN[30], FIXED/UV_QUAN[31]},
    //     '{FIXED/UV_QUAN[32], FIXED/UV_QUAN[33], FIXED/UV_QUAN[34], FIXED/UV_QUAN[35], FIXED/UV_QUAN[36], FIXED/UV_QUAN[37], FIXED/UV_QUAN[38], FIXED/UV_QUAN[39]},
    //     '{FIXED/UV_QUAN[40], FIXED/UV_QUAN[41], FIXED/UV_QUAN[42], FIXED/UV_QUAN[43], FIXED/UV_QUAN[44], FIXED/UV_QUAN[45], FIXED/UV_QUAN[46], FIXED/UV_QUAN[47]},
    //     '{FIXED/UV_QUAN[48], FIXED/UV_QUAN[49], FIXED/UV_QUAN[50], FIXED/UV_QUAN[51], FIXED/UV_QUAN[52], FIXED/UV_QUAN[53], FIXED/UV_QUAN[54], FIXED/UV_QUAN[55]},
    //     '{FIXED/UV_QUAN[56], FIXED/UV_QUAN[57], FIXED/UV_QUAN[58], FIXED/UV_QUAN[59], FIXED/UV_QUAN[60], FIXED/UV_QUAN[61], FIXED/UV_QUAN[62], FIXED/UV_QUAN[63]}
    // };



    localparam [15:0] HEADER = 16'hFFDB;

    localparam [7:0] Y_PQN_TQN = 8'h00;
    localparam [7:0] UV_PQN_TQN = 8'h01;

    logic [0:(8*MCU_SIZE*MCU_SIZE)-1] y_quan_1d;
    logic [0:(8*MCU_SIZE*MCU_SIZE)-1] uv_quan_1d;

    int i,j;
    always_comb begin
        for(i=0;i<MCU_SIZE;i++) begin
            for(j=0;j<MCU_SIZE;j++) begin
                y_quan_table[i][j][QUAN_BITWIDTH-1:0] = Y_QUAN_FIXED[i][j];
                uv_quan_table[i][j][QUAN_BITWIDTH-1:0] = UV_QUAN_FIXED[i][j];
                y_quan_1d[(i*8+j)*8 +: 8] = Y_QUAN[i][j];
                uv_quan_1d[(i*8+j)*8 +: 8] = UV_QUAN[i][j];
            end
        end
    end


    always_comb begin
        marker_array = {HEADER,LQ,Y_PQN_TQN,y_quan_1d,UV_PQN_TQN,uv_quan_1d};
    end

endmodule

`default_nettype wire