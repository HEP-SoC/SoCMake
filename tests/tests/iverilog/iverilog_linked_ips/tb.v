module tb;
    wire out;
    mod u_mod(.out(out));
    initial begin
        #1;
        if (out !== 1'b1) begin
            $display("FAIL: mod output not driven correctly");
            $fatal;
        end
        $display("PASS: linked IP sources compiled successfully");
        $finish;
    end
endmodule
