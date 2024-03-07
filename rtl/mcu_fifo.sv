`default_nettype none

module mcu_fifo
#(
    parameter int FIFO_SIZE = -1,
    parameter int MCU_SIZE =  -1,
    parameter int BIT_WIDTH = -1
)
(
    input wire clk,
    input wire n_rst,
    input wire we,  
    input wire re,
    input wire [0:MCU_SIZE-1][0:MCU_SIZE-1][BIT_WIDTH-1:0] din,
    input wire                                             i_last,
    output wire empty,
    output wire full,
    output wire [0:MCU_SIZE-1][0:MCU_SIZE-1][BIT_WIDTH-1:0] dout,
    output wire                                             o_last,
    output logic                                            o_valid
);

    always_ff @(posedge clk) begin
        if(!n_rst) begin
            o_valid <= 1'b0;
        end
        else begin
            o_valid <= re & !empty;
        end
    end

   
   wire [(MCU_SIZE*MCU_SIZE)-1:0]  emp_reg;
   wire [(MCU_SIZE*MCU_SIZE)-1:0]  full_reg;
   assign empty = emp_reg[0];
   assign full = full_reg[0];
   
   //assign o_last = i_last;

   //combine last signal
   wire [BIT_WIDTH:0]              data_0;
   wire [BIT_WIDTH:0]              data_0_o;
   assign data_0 = {i_last,din[0][0]};
   
   
   // wire [1:0]   tmp_o;
   // wire [1:0]   tmp_i;
   // assign tmp_i = {1'b0,i_last};
   // assign o_last = tmp_o[0];
   //  //last
   //  fifo
   //  #(
   //      .FIFO_SIZE(FIFO_SIZE),
   //      .BIT_WIDTH(2)
   //  )
   //  fifo_last_inst(
   //      .clk(clk),
   //      .n_rst(n_rst),
   //      .we(we),
   //      .re(re),
   //      .din(tmp_i),
   //      .dout(tmp_o)
   //  );


   


    genvar i,j;
    generate
        for(i=0;i<MCU_SIZE;i++) begin
            for(j=0;j<MCU_SIZE;j++) begin
                if((i==0) && (j==0)) begin  
                    fifo
                    #(
                        .FIFO_SIZE(FIFO_SIZE),
                        .BIT_WIDTH(BIT_WIDTH+1)
                    )
                    fifo_inst
                    (
                        .clk(clk),
                        .n_rst(n_rst),
                        .we(we),
                        .re(re),
                        .din(data_0),
                        .empty(emp_reg[0]),
                        .full(full_reg[0]),
                        .dout(data_0_o)    
                    );
                   assign o_last = data_0_o[BIT_WIDTH];
                   assign dout[i][j] =  data_0_o[0 +:BIT_WIDTH];

                    end
                else begin
                    fifo
                    #(
                        .FIFO_SIZE(FIFO_SIZE),
                        .BIT_WIDTH(BIT_WIDTH)
                    )
                    fifo_inst
                    (
                        .clk(clk),
                        .n_rst(n_rst),
                        .we(we),
                        .re(re),
                        .din(din[i][j]),
                        .empty(emp_reg[i*(MCU_SIZE)+j]),
                        .full(full_reg[i*(MCU_SIZE)+j]),
                        .dout(dout[i][j])    
                    );
                end


            end
        end
    endgenerate





endmodule

`default_nettype wire
