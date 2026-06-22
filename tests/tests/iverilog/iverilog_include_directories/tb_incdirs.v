// Verifies that ip_include_directories are forwarded to iverilog.
// inc_header.vh (in the inc/ subdirectory) must be found via the include path.
`include "inc_header.vh"

module tb_incdirs;
    initial begin
        `ifndef INC_DIRS_PASS
            $display("FAIL: INC_DIRS_PASS not defined — ip_include_directories not forwarded");
            $fatal;
        `endif
        $display("PASS: ip_include_directories forwarded correctly");
        $finish;
    end
endmodule
