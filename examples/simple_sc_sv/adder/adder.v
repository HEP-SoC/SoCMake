module adder(
    input [7:0] a,
    input [7:0] b,

    output [8:0] out
);

    assign out = a + b;

endmodule;
