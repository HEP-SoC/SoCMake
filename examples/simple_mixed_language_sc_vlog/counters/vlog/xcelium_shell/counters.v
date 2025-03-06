`timescale 1 ns / 1 ns

module counters(
	clk, rst, cnt1_out, cnt2_out
)
	(* const integer foreign = "SystemC"; *);
input clk;
input rst;
output [7:0] cnt1_out;
output [7:0] cnt2_out;

endmodule

