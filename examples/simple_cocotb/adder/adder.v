module adder(
    input [4:0] NUM1,
    input [4:0] NUM2,
    output [4:0] SUM
    );

    assign SUM = NUM1 + NUM2;
endmodule
