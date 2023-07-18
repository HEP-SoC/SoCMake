module majorityVoter #(parameter WIDTH = 1) (
    input  wire [WIDTH-1:0] inA, inB, inC,
    output wire [WIDTH-1:0] out,
    output reg             tmrErr
);
    `ifdef SYNTHESIS
        wire [WIDTH-1:0] z_int;
        wire err_int;

        genvar i;
        generate
            for(i=0; i<WIDTH; i=i+1) begin
                MAOI222D2BWP35P140 MV_preserve (
                    .A(inA[i]),
                    .B(inB[i]),
                    .C(inC[i]),
                    .ZN(z_int[i])
                );

                CKND2BWP35P140 MV_out_inv_preserve (
                    .I(z_int[i]),
                    .ZN(out[i])
                );
            end
        endgenerate

        always @(inA or inB or inC) begin
            if (inA!=inB || inA!=inC || inB!=inC)
                err_int = 1;
            else
                err_int = 0;
        end

        CKBD2BWP35P140 tmrErr_buf_preserve (
            .I(err_int),
            .Z(tmrErr)
        );
    `else
        assign out = (inA&inB) | (inA&inC) | (inB&inC);

        always @(inA or inB or inC) begin
            if (inA!=inB || inA!=inC || inB!=inC)
            tmrErr = 1;
            else
            tmrErr = 0;
        end
    `endif

endmodule
