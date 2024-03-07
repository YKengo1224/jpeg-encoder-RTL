`default_nettype none

module fifo#(
	     parameter int FIFO_SIZE = -1,
	     parameter int BIT_WIDTH = -1
)

(clk, n_rst, we, re, din, empty,full,dout);

      
   input wire		       clk;
   input wire		       n_rst;
   input wire		       we;
   input wire		       re;
   input wire [BIT_WIDTH-1:0] din;
   output logic		      empty;
   output logic		      full;
   output wire [BIT_WIDTH-1:0] dout;
   
   localparam  int	       FIFO_WIDTH = $clog2(FIFO_SIZE+1);
   
      
   
   logic [(FIFO_WIDTH)-1:0]      waddr;
   logic [(FIFO_WIDTH)-1:0]      raddr;
   logic [(FIFO_WIDTH)-1:0]      raddr_in;

   logic			       we_in;
   logic			       re_in;
   
   
   
   dpram #(
	   .FIFO_SIZE(FIFO_SIZE+1),
	   .BIT_WIDTH(BIT_WIDTH)
	   )
   dpram_inst(
	      .clk(clk),
	      .n_rst(n_rst),
	      .we(we_in),
	      .re(re_in),
	      .waddr(waddr),
	      .raddr(raddr_in),
	      .din(din),
	      .dout(dout)
	      );

   
   // initial begin
   //    waddr = 'd1;
   //    raddr = 'd0;
   // end

   
   assign we_in = we && !full;
   assign re_in = re && !empty;

   always_ff @(posedge clk ) begin 
      if(!n_rst)begin
         waddr <= FIFO_WIDTH'('b1);
      end
      else begin
         if(we_in) begin
            waddr <= ((FIFO_SIZE-1) == waddr)? {FIFO_WIDTH{1'b0}} : waddr + 'b1;
         end
         else begin
            waddr <= waddr;
         end
      end
   end



   always_ff @(posedge clk ) begin 
      if(!n_rst)begin
         raddr <= {FIFO_WIDTH{1'b0}};
      end
      else begin
         if(re_in) begin
            raddr <= ((FIFO_SIZE-1) == raddr)? {FIFO_WIDTH{1'b0}} : raddr + 'b1;
         end
         else begin
            raddr <= raddr;
         end
      end
   end

   //assign raddr_in = raddr + 'b1;
   always_comb begin
      raddr_in = ((FIFO_SIZE-1) == raddr)? {FIFO_WIDTH{1'b0}} : raddr + FIFO_WIDTH'('d1);
   end

   assign full = (waddr==raddr);
   assign empty = (raddr_in == waddr);
   // assign full = waddr_in == raddr;
   // assign empty = waddr == raddr;
   
	   


endmodule



`default_nettype wire
