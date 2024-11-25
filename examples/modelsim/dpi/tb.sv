module tb;

    import "DPI-C" function int unsigned hello(input int unsigned data);

    initial begin
        $display("From DPI-C 5 + 10 is: %d", hello(5));
        $finish();
    end
endmodule
