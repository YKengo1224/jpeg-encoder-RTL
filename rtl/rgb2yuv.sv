`default_nettype none

module  rgb2yuv
#(
        parameter int PIXEL_BITWIDTH = -1,
        parameter int RGB_BITWIDTH = -1
        )
(    
    input wire clk,
    input wire n_rst,
    input wire                       i_wait,
    input wire [PIXEL_BITWIDTH-1:0]  i_tdata,
    input wire                       i_tlast,
    input wire                       i_tuser,
    input wire                       i_tvalid,

    output logic [PIXEL_BITWIDTH-1:0] o_yuv,
    output logic                     o_tlast,
    output logic                      o_tuser,
    output logic                      o_tvalid

    // input wire en,
    // input wire[PIXEL_BITWIDTH-1:0] rgb,
    // output logic[PIXEL_BITWIDTH-1:0] yuv
    // test bench
    // output logic[7:0] r,
    // output logic[7:0] g,
    // output logic[7:0] b,
    // output logic signed [23:0] y_pre,
    // output logic signed [23:0] u_pre,
    // output logic signed [23:0] v_pre,

    
);

    localparam int SHIFT_128 = 2097152;
    localparam PRE_BITWIDTH = RGB_BITWIDTH + 14;  


    //waitの立上り ＆ 立ち下がりエッジ
    logic                           wait_prev;                            
    logic                           wait_pogi;
    logic                           wait_neg;

    logic [PIXEL_BITWIDTH-1:0]      tdata_evac_reg;
    logic[RGB_BITWIDTH-1:0]         r_evac;
    logic[RGB_BITWIDTH-1:0]         g_evac;
    logic[RGB_BITWIDTH-1:0]         b_evac;
    logic                           tlast_evac_reg;
    logic                           tuser_evac_reg;
    logic                           tvalid_evac_reg;

    logic[RGB_BITWIDTH-1:0]         r;
    logic[RGB_BITWIDTH-1:0]         g;
    logic[RGB_BITWIDTH-1:0]         b;

    logic [2:0][13:0]               y_weight;
    logic [2:0][13:0]               u_weight;
    logic [2:0][13:0]               v_weight;

    logic [PRE_BITWIDTH-1:0]        y_pre;
    logic [PRE_BITWIDTH-1:0]        u_pre;
    logic [PRE_BITWIDTH-1:0]        v_pre;

    logic signed [RGB_BITWIDTH-1:0] y;
    logic signed [RGB_BITWIDTH-1:0] u;
    logic signed [RGB_BITWIDTH-1:0] v;
    // logic [RGB_BITWIDTH-1:0] y;
    // logic [RGB_BITWIDTH-1:0] u;
    // logic [RGB_BITWIDTH-1:0] v;



    //waitのエッジ検出
    always_ff @(posedge clk) begin
        if(!n_rst) begin
            wait_prev <= 1'b0;
        end
        else begin
            wait_prev <= i_wait;
        end
    end
    assign wait_pogi = !wait_prev & i_wait;
    assign wait_neg  = wait_prev & !i_wait;

    //split yuv
    always_comb begin : split_rgb
        r = i_tdata[(PIXEL_BITWIDTH-1) -:RGB_BITWIDTH];
        b = i_tdata[(PIXEL_BITWIDTH-RGB_BITWIDTH-1) -: RGB_BITWIDTH];
        g = i_tdata[RGB_BITWIDTH-1:0];
    end



    //退避用レジスタ
    always_ff @( posedge clk ) begin
        if(!n_rst) begin
            tdata_evac_reg  <= PIXEL_BITWIDTH'('d0);
            tlast_evac_reg  <= 1'd0;
            tuser_evac_reg  <= 1'd0;
            tvalid_evac_reg <= 1'd0;
        end
        else if(wait_pogi) begin
            tdata_evac_reg  <= i_tdata;
            tlast_evac_reg  <= i_tlast;
            tuser_evac_reg  <= i_tuser;
            tvalid_evac_reg <= i_tvalid;
        end
        else if(wait_neg) begin
            tdata_evac_reg  <= PIXEL_BITWIDTH'('d0);
            tlast_evac_reg  <= 1'd0;
            tuser_evac_reg  <= 1'd0;
            tvalid_evac_reg <= 1'd0;            
        end
        else begin
            tdata_evac_reg  <= tdata_evac_reg;
            tlast_evac_reg  <= tlast_evac_reg;
            tuser_evac_reg  <= tuser_evac_reg;
            tvalid_evac_reg <= tvalid_evac_reg;        
        end
    end
    always_comb begin 
        r_evac = tdata_evac_reg[(PIXEL_BITWIDTH-1) -:RGB_BITWIDTH];
        b_evac = tdata_evac_reg[(PIXEL_BITWIDTH-RGB_BITWIDTH-1) -: RGB_BITWIDTH];
        g_evac = tdata_evac_reg[RGB_BITWIDTH-1:0];
    end

    always_comb begin
        y_weight[0]=14'd4899;  //0.299
        y_weight[1]=14'd9617;  //0.587
        y_weight[2]=14'd1868;  //0.114
        u_weight[0]=14'd2764;  //0.1687
        u_weight[1]=14'd5428;  //0.3315
        u_weight[2]=14'd8192;  //0.5
        v_weight[0]=14'd8192;  //0.5
        v_weight[1]=14'd6860;  //0.4188
        v_weight[2]=14'd1332;  //0.0813
    end


    //calc
    always_ff @(posedge clk) begin : calc_yuv
        if(!n_rst) begin
            y_pre <= 23'd0;
            u_pre <= 23'd0;   
            v_pre <= 23'd0;
        end
        //waitの立ちさがりのときは退避レジスタから読み込み
        else if (wait_neg) begin
            y_pre <= y_weight[0]*r_evac  + y_weight[1]*g_evac + y_weight[2]*b_evac - SHIFT_128;
            u_pre <= -u_weight[0]*r_evac - u_weight[1]*g_evac + u_weight[2]*b_evac;
            v_pre <= v_weight[0]*r_evac  - v_weight[1]*g_evac - v_weight[2]*b_evac;
          
        end
        else if(!i_wait & i_tvalid)begin
            y_pre <= y_weight[0]*r + y_weight[1]*g + y_weight[2]*b - SHIFT_128;
            u_pre <= -u_weight[0]*r - u_weight[1]*g + u_weight[2]*b;
            v_pre <= v_weight[0]*r - v_weight[1]*g - v_weight[2]*b;
            // y_pre <= y_weight[0]*r + y_weight[1]*g + y_weight[2]*b ;
            // u_pre <= SHIFT_128 + -u_weight[0]*r - u_weight[1]*g + u_weight[2]*b;
            // v_pre <= SHIFT_128 + v_weight[0]*r - v_weight[1]*g - v_weight[2]*b;

        end
        else begin
            y_pre <= y_pre;
            u_pre <= u_pre;
            v_pre <= v_pre;
        end
    end
    
    //
    
    always_comb begin
        if((y_pre[13] & (y_pre[PRE_BITWIDTH-2 -:7]!= 7'd127)) && !y_pre[PRE_BITWIDTH-1]) begin
        //if((y_pre[13] & (y_pre[PRE_BITWIDTH-1 -:8]!= 8'd255))) begin
	        y = y_pre[PRE_BITWIDTH-1:14] + 1;
       end
        else begin
	        y = y_pre[PRE_BITWIDTH-1:14];
        end
    end
   
    always_comb begin       
        if((u_pre[13] & (u_pre[PRE_BITWIDTH-2 -:7]!= 7'd127)) && !u_pre[PRE_BITWIDTH-1]) begin
        //if((u_pre[13] & (u_pre[PRE_BITWIDTH-1 -:8]!= 8'd255))) begin
            u = u_pre[PRE_BITWIDTH-1:14] + 1;
        end
        else begin
            u = u_pre[PRE_BITWIDTH-1:14];
        end
    end

    always_comb begin       
        if((v_pre[13] & (v_pre[PRE_BITWIDTH-2 -:7]!= 7'd127)) && !v_pre[PRE_BITWIDTH-1]) begin
        //if(v_pre[13] & (v_pre[PRE_BITWIDTH-1 -:8]!= 8'hFF)) begin
    	    v = v_pre[PRE_BITWIDTH-1:14] + 1;
      end
        else begin
	        v = v_pre[PRE_BITWIDTH-1:14];
        end
   end
   
       
       // y =  y_pre[13] & (y_pre[PRE_BITWIDTH-1:8]!= 8'd255) ? y_pre[PRE_BITWIDTH-1:14] + 1: y_pre[PRE_BITWIDTH-1:14];
       // u =  y_pre[13] & (u_pre[PRE_BITWIDTH-1:8]!= 8'd255) ? u_pre[PRE_BITWIDTH-1:14] + 1: u_pre[PRE_BITWIDTH-1:14];
       // v =  y_pre[13] & (v_pre[PRE_BITWIDTH-1:8]!= 8'd255) ? v_pre[PRE_BITWIDTH-1:14] + 1: v_pre[PRE_BITWIDTH-1:14];
    //end

    always_ff @(posedge clk) begin
        if(!n_rst) begin
            o_tlast <= 1'b0;
            o_tuser <= 1'b0;
            o_tvalid <= 1'b0;
        end
        else if(i_wait) begin
            o_tlast  <= o_tlast;
            o_tuser  <= o_tuser;
            o_tvalid <= o_tvalid;            
        end
        //waitの立ちさがりのときは退避レジスタから読み込み
        else if(wait_neg)begin
            o_tlast  <= tlast_evac_reg;
            o_tuser  <= tuser_evac_reg;
            o_tvalid <= tvalid_evac_reg;
        end

        else begin
            o_tlast  <= i_tlast;
            o_tuser  <= i_tuser;
            o_tvalid <= i_tvalid;
        end
    end

    assign o_yuv = {y[RGB_BITWIDTH-1:0],u[RGB_BITWIDTH-1:0],v[RGB_BITWIDTH-1:0]};



   
endmodule


`default_nettype wire
