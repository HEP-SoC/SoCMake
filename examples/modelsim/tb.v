module tb;
 initial begin
     $display("Hello world, from SoCMake build system\n");
     $finish();
 end

 wire [4:0] a, b, o;

 adder adder_i (
     .NUM1(a),
     .NUM2(b),
     .SUM(o)
     );

 endmodule
