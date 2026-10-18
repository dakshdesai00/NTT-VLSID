// b2r.v: Binary to Redundant (B2R) Converter from HRCIM-NTT Eq. (10)-(11)
//
// Converts a 12-bit binary number X[11:0] into M=8 minimally redundant radix-4 digits X'[7:0]
// Each digit consists of 3 bits: (d_neg2, d_pos, d_pp) with weights (-2, +1, +1)
//
// Equations:
//   d_neg2[i] = x[2i+1]
//   d_pos[i]  = x[2i]
//   d_pp[i]   = x[2i-1]   (with x[-1] = 0)

`timescale 1ns/1ps

module b2r #(
    parameter L = 12,
    parameter M = 8
)(
    input  wire [L-1:0] bin_in,
    output wire [M-1:0] mr4_neg2,
    output wire [M-1:0] mr4_pos,
    output wire [M-1:0] mr4_pp
);

    // Zero-extended binary input to cover all 2*M bits (16 bits for M=8)
    wire [2*M-1:0] bin_ext;
    assign bin_ext = { {(2*M - L){1'b0}}, bin_in };

    genvar i;
    generate
        for (i = 0; i < M; i = i + 1) begin : gen_b2r_digits
            assign mr4_neg2[i] = bin_ext[2*i + 1];
            assign mr4_pos[i]  = bin_ext[2*i];
            if (i == 0)
                assign mr4_pp[i] = 1'b0; // x[-1] = 0
            else
                assign mr4_pp[i] = bin_ext[2*i - 1];
        end
    endgenerate

endmodule
