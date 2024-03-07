`default_nettype none

module line_buffer#(
	parameter int LINE_BUFFER_SIZE = -1,
    parameter int BIT_WIDTH = -1
	      )
(
	input wire                 clk, 
	input wire                 n_rst,
	input wire                 i_wait,
	input wire [BIT_WIDTH-1:0] i_data,
	output wire [BIT_WIDTH-1:0] o_data,
	output logic                 o_valid
	);

	localparam int ADDR_BITWIDTH = $clog2(LINE_BUFFER_SIZE);

	wire                                 we;
	wire                                 re;
	logic [ADDR_BITWIDTH-1:0] waddr;
	logic [ADDR_BITWIDTH-1:0] raddr;

	dpram #(
		.FIFO_SIZE(LINE_BUFFER_SIZE),
		.BIT_WIDTH(BIT_WIDTH)
	)
	dpram_inst
	(
		.clk(clk),
		.n_rst(n_rst),
		.we(we),
		.re(re),
		.raddr(raddr),
		.waddr(waddr),
		.din(i_data),
		.dout(o_data)
	);

	assign re = !i_wait;
	assign we = !i_wait;


	always_ff @(posedge clk) begin
		if(!n_rst) begin
			waddr <= ADDR_BITWIDTH'('d0);
		end
		else if(!i_wait) begin	
			if(waddr == (LINE_BUFFER_SIZE - 1) ) begin
				waddr <= ADDR_BITWIDTH'('d0);
			end
			else begin
				waddr <= waddr + ADDR_BITWIDTH'('d1);
			end
		end
		else begin
			waddr <= waddr;
		end
	end

	always_ff @(posedge clk) begin
		if(!n_rst) begin
			raddr <= ADDR_BITWIDTH'('d1);
		end
		else if(!i_wait) begin	
			if(raddr == (LINE_BUFFER_SIZE - 1) ) begin
				raddr <= ADDR_BITWIDTH'('d0);
			end
			else begin
				raddr <= raddr + ADDR_BITWIDTH'('d1);
			end
		end
		else begin
			raddr <= raddr;
		end
	end


	always_ff @(posedge clk) begin
		if(!n_rst)begin
			o_valid <= 1'b0;
		end
		else begin
			o_valid <= we;
		end
	end

endmodule

`default_nettype wire
