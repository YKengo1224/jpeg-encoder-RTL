`default_nettype none

module dpram (clk, n_rst, we, re, raddr, waddr, din, dout);
    parameter FIFO_SIZE = 1024;
    parameter BIT_WIDTH = 8;

    input wire                         clk, n_rst, we, re;
    input wire [$clog2(FIFO_SIZE)-1:0] raddr, waddr;
    input wire [BIT_WIDTH-1:0]         din;
    output reg [BIT_WIDTH-1:0]         dout;

    //(* ram_style = "block" *) 
    (* ram_style = "distributed" *) 
    reg [BIT_WIDTH-1:0] mem [FIFO_SIZE-1:0];

    always @(posedge clk) begin
        if (!n_rst)  dout <= 1'd0;
        else if (re) dout <= mem[raddr];
    end

    always @(posedge clk) begin
        if (we) mem[waddr] <= din;
    end

   integer i;   
   initial begin
        for(i = 0; i < FIFO_SIZE; i = i+1) mem[i] = 'b0;
    end
endmodule



`default_nettype wire
