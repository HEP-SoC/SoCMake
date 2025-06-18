module tb;
 reg [4:0] a, b;
 wire [4:0] o;

 adder adder_i (
     .NUM1(a),
     .NUM2(b),
     .SUM(o)
     );

 initial begin
     a = 5;
     b = 10;
     #1;

     $display("Hello world, from SoCMake build system\n");
     $display("%d + %d = %d", a, b, o);
     $finish();
 end


 endmodule

