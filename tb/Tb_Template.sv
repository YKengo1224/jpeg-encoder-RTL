`default_nettype none

`timescale 1ns/1ps
module Tb_Template();

    localparam integer CLOCK_PERIOD  = 100e6;  //一秒
    localparam integer CLOCK_FREQ    = 50;     //周波数
    localparam integer CLOCK_PERIOD_NS = CLOCK_PERIOD / CLOCK_FREQ; //クロック周期

    //テストモジュールへの入力信号の準備
    reg [3:0] a;
    reg [3:0] b;
    //テストモジュールへの出力信号の準備
    wire [3:0] s;
    wire cout;

    //テストモジュールのインスタンス化
    add add_inst(
        .a(a),
        .b(b),
        .s(s),
        .cout(cout)
    );



    // //クロックの生成
    // initial begin
    //     clk <= 1'b0;
    //     forever begin             //終了するまで永遠に繰り替えす
    //         #(CLOCK_PERIOD_NS/2)    //(CLOCK_FREQ_NS/2)タイムスケール後に
    //         clk <= ~clk;          //クロック信号を反転する
    //     end
    // end

    // //リセット信号
    // initial begin
    //     n_rst <= 1'b1;
    //     repeat(2) begin          //2回繰り返す
    //         #(CLOCK_PERIOD_NS)
    //         n_rst <= ~n_rst;
    //     end
    // end


    //その他の入力信号の生成
    initial begin      
        a <= 4'd0;b <= 4'd0;
        #(CLOCK_PERIOD_NS*3)
        a <= 4'd2;b <= 4'd3;
        #(CLOCK_PERIOD_NS*2)
        a <= 4'd9;b <= 4'd9;
        #(CLOCK_PERIOD_NS*5)
        $finish;
    end


    //コマンドライン、波形出力
    initial begin
        //コマンドライン出力
        $monitor($time,"a=%d,b=%d,s=%d,cout1=%d",
                a,b,s,cout);
        //波形出力
        //$shm_open("result.shm");
        //$shm_probe("AS");
        $dumpfile("Tb_Template.vcd");
        $dumpvars(0,add_inst);
    end

    //1秒たったら強制終了
    initial begin
        #(CLOCK_PERIOD);
        $finish;
    end


endmodule

`default_nettype wire
