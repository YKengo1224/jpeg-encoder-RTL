`default_nettype none
module add(
        a, 
        b, 
        s, 
        cout
);
        input  [3:0] a, b;
        output [3:0] s;
        output       cout;

        assign {cout,s} = a + b;

endmodule // add4
`default_nettype wire