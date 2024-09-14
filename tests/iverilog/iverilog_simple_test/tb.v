`include "header.vh"

module tb;
 initial begin
     $display("Simulated with Iverilog, from SoCMake build system\n");

     if(`SOME_DEF1 != 100) begin
         $warning("Macro SOME_DEF1 either not defined or not equal to 100\n         Error with SoCMake ip_compile_definitions()");
         $fatal();
     end

     if(`INCLUDED_NUM != 55) begin
         $warning("File header.vh not included\n         Error with SoCMake ip_include_directories()");
         $fatal();
     end

     $finish();
 end

 endmodule
