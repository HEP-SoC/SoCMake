`timescale 1ns / 1ns

module counter2 (
    input clk,
    input rst,
    output [7:0] cnt_out
);

    reg [7:0] cnt_reg;
    assign cnt_out = cnt_reg;

    always @(posedge clk) begin
        if(rst) begin
            cnt_reg <= 8'h00;
        end else begin
            cnt_reg <= cnt_reg + 2;
        end
    end

endmodule

