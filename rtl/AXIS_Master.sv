`timescale 1ns/1ps
`default_nettype none

module AXIS_Master#(
        parameter int DATA_BITWIDTH = 8,
        parameter int FIFO_SIZE = 10
    )
    (
        input wire m_axis_aclk,
        input wire m_axis_aresetn,

        input wire[DATA_BITWIDTH-1:0] i_data,
        input wire                    i_valid,
        input wire                    i_data_end,
        output wire                   o_wait,

        output logic                        m_axis_tvalid,
        output wire[DATA_BITWIDTH-1:0]      m_axis_tdata,
        output wire [(DATA_BITWIDTH/8)-1:0] m_axis_tstrb,
        output wire                         m_axis_tlast,
        input  wire                         m_axis_tready

    );


    wire [DATA_BITWIDTH:0]  fifo_idata;
    wire                      fifo_re;
    wire                      fifo_we;
    wire                      fifo_emp;
    wire                      fifo_full;
    wire [DATA_BITWIDTH:0]  fifo_odata;

    assign o_wait = fifo_full;
    assign fifo_idata = {i_data,i_data_end};
    assign fifo_we = i_valid & !fifo_full;
    assign fifo_re = !fifo_emp & m_axis_tready;

    fifo#(
        .FIFO_SIZE(FIFO_SIZE),
        .BIT_WIDTH(DATA_BITWIDTH+1)
    )
    fifo_inst(
        .clk(m_axis_aclk),
        .n_rst(m_axis_aresetn),
        .we(fifo_we),
        .re(fifo_re),
        .din(fifo_idata),
        .empty(fifo_emp),
        .full(fifo_full),
        .dout(fifo_odata)
    );

    assign m_axis_tstrb = {(DATA_BITWIDTH/8){1'b1}};
    assign m_axis_tdata = fifo_odata[DATA_BITWIDTH -: DATA_BITWIDTH];
    assign m_axis_tlast = fifo_odata[0];
    always_ff @(posedge m_axis_aclk) begin
        if(!m_axis_aresetn) begin
            m_axis_tvalid <= 1'b0;
        end
        else begin
            m_axis_tvalid <= fifo_re;
        end
    end

endmodule
`default_nettype wire