`timescale 1ps / 1ps

module counters (
    input clk,
    input rst,

    output [7:0] cnt1_out,
    output [7:0] cnt2_out
    );

    counter1 cnt1_i(
        .clk(clk),
        .rst(rst),

        .cnt_out(cnt1_out)
    );

    counter2 cnt2_i(
        .clk(clk),
        .rst(rst),

        .cnt_out(cnt2_out)
    );

endmodule
