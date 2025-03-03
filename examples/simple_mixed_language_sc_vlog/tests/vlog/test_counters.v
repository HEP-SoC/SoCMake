`timescale 1ns / 1ns

module test_counters();

    reg clk;
    reg rst;


    initial begin
        clk = 1'b0;
    end

    always begin 
        #10 clk = ~clk;
    end

    initial begin
        rst = 1'b1;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        rst = 1'b0;
    end

    wire [7:0] cnt1_out;
    wire [7:0] cnt2_out;

    counters counters_i(
        .clk(clk),
        .rst(rst),

        .cnt1_out(cnt1_out),
        .cnt2_out(cnt2_out)
        );


    always @(posedge clk) begin
        $display("Current simulation time is: ", $time);
        $display("CNT1: %d", cnt1_out);
        $display("CNT2: %d", cnt2_out);

        if(cnt2_out == 208)
            $finish();
    end

endmodule

