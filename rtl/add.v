`default_nettype wire
module add(
        a, 
        b, 
        s, 
        cout
);
        input  wire [3:0] a, b;
        output wire [3:0] s;
        output wire       cout;

        assign {cout,s} = a + b;

endmodule // add4
`default_nettype wire