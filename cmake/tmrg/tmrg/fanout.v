module fanout #(parameter WIDTH = 1) (
  input   [(WIDTH-1):0]   in,
  output  [(WIDTH-1):0]   outA, outB, outC
);
    `ifdef SYNTHESIS
        genvar i;
        generate
            for(i=0; i<WIDTH; i=i+1) begin
                CKBD2BWP35P140 fanout_preserveA (
                    .I(in[i]),
                    .Z(outA[i])
                );

                CKBD2BWP35P140 fanout_preserveB (
                    .I(in[i]),
                    .Z(outB[i])
                );

                CKBD2BWP35P140 fanout_preserveC (
                    .I(in[i]),
                    .Z(outC[i])
                );
            end
        endgenerate
    `else
        assign outA = in;
        assign outB = in;
        assign outC = in;
    `endif
endmodule
