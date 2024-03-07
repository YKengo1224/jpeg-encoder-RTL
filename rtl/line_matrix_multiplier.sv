`default_nettype none

module line_matrix_multiplier
#(
    parameter int MATRIX_SIZE = -1,
    parameter int LINE_BITWIDTH = -1,
    parameter int MAT_BITWIDTH = -1,
    parameter int OUT_BITWIDTH = LINE_BITWIDTH+MAT_BITWIDTH+1
)
(
    input wire                                                             clk,
    input wire                                                             n_rst,
    input wire                                                             i_start,
    input wire signed [MATRIX_SIZE-1:0][LINE_BITWIDTH-1:0]                 i_line,
    input wire signed [MATRIX_SIZE-1:0][MATRIX_SIZE-1:0][MAT_BITWIDTH-1:0] i_matrix,
    input wire                                                             i_wait,
    output logic signed [MATRIX_SIZE-1:0][OUT_BITWIDTH-1:0]                o_line,
    output logic                                                           o_valid
);

    localparam int MAX_COUNT = (MATRIX_SIZE);
    localparam int COUNT_BITWIDTH = $clog2(MAX_COUNT);

    logic [COUNT_BITWIDTH:0] count;
    logic [MATRIX_SIZE-1:0][MAT_BITWIDTH-1:0] selected_line;
    logic [MATRIX_SIZE-1:0][OUT_BITWIDTH-1:0] calc_reg;

    wire                                      i_start_evec_flag;
    logic                                     i_start_evac;  //i_start 退避用

    assign i_start_evec_flag = i_start & i_wait;

    //count
    always_ff@(posedge clk) begin
        if(!n_rst) begin
            count <= COUNT_BITWIDTH'('b0);
        end
        else begin
            if(i_wait) begin
                count <= count;
            end
            else if(count==0 && i_start) begin
                count <= 'b1;
            end
            else if(count == MAX_COUNT) begin
                count <= 'b0;
            end
            else if(count != 'b0) begin
                count <= count + 'b1;
            end
            else begin
                count <= 'b0;
            end
        end
    end

    // valid
    always_ff @(posedge clk) begin
        if(!n_rst) begin
            o_valid <= 1'b0;
        end
        else begin
            o_valid <= count == (COUNT_BITWIDTH+1)'(MAX_COUNT);
        end
    end

    int i,j,k;
    always_ff @(posedge clk) begin         
        if(!n_rst) begin
            for(i=0;i<MATRIX_SIZE;i++) begin
                selected_line[i] <= {LINE_BITWIDTH{1'b0}};
            end
        end
        else if(i_wait) begin
            for(i=0;i<MATRIX_SIZE;i++) begin
                selected_line[i] <= selected_line[i];
            end
        end
        else if(count < MATRIX_SIZE) begin
            for(i=0;i<MATRIX_SIZE;i++) begin
                selected_line[i] <= i_matrix[count][i];
            end
        end
        else begin
            for(i=0;i<MATRIX_SIZE;i++) begin
                selected_line[i] <= {LINE_BITWIDTH{1'b0}};
            end
        end
    end


    always_ff @(posedge clk) begin
        if(!n_rst) begin
            for(k=0;k<MATRIX_SIZE;k++) begin
                calc_reg[k] <= {OUT_BITWIDTH{1'b0}};
            end
        end
        else if(i_wait) begin
            for(k=0;k<MATRIX_SIZE;k++) begin
                calc_reg[k] <= calc_reg[k];
            end
        end
        else if(count != 'b0) begin
            for(k=0;k<MATRIX_SIZE;k++) begin
                calc_reg[k] <= calc_reg[k] + ((OUT_BITWIDTH)'(signed'(i_line[count-1])) * (OUT_BITWIDTH)'(signed'(selected_line[k])));
            end
        end
        else begin
            for(k=0;k<MATRIX_SIZE;k++) begin
                calc_reg[k] <= {OUT_BITWIDTH{1'b0}};
            end
        end
    end

    always_comb begin
        for(j=0;j<MATRIX_SIZE;j++) begin
            o_line[j] <= calc_reg[j];        
        end
    end




endmodule

`default_nettype wire