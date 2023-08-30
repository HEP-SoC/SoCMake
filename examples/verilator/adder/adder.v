`timescale 10ns/10ps

module adder (
    input [7:0] a,
    input [7:0] b,
    output [8:0] o
);

    assign o = a + b;
 endmodule
