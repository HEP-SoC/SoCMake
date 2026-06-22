// Verifies that SV_COMPILE_ARGS are forwarded to iverilog.
// The -DEXTRA_DEF flag must be passed either via SV_COMPILE_ARGS or COMPILE_DEFINITIONS for this to pass.
module tb;
    initial begin
        `ifndef EXTRA_DEF
            $display("FAIL: EXTRA_DEF not defined — SV_COMPILE_ARGS not forwarded");
            $fatal;
        `endif
        $display("PASS: SV_COMPILE_ARGS forwarded correctly");
        $finish;
    end
endmodule
