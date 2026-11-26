`include "header.vh"

module tb;
    initial begin
        $display("Simulated with Verilator, from SoCMake build system");

        if (`SOME_DEF1 != 100) begin
            $display("FAIL: macro SOME_DEF1 either not defined or not equal to 100, error with SoCMake ip_compile_definitions()");
            $fatal;
        end

        if (`INCLUDED_NUM != 55) begin
            $display("FAIL: file header.vh not included, error with SoCMake ip_include_directories()");
            $fatal;
        end

        $display("PASS: compile definitions and include directories forwarded correctly");
        $finish;
    end
endmodule
