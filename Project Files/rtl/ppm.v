// ppm.v: Plus-Plus-Minus cell from HRCIM-NTT Fig. 1(b)
// Inputs:
//   y_i    : positive weight (+1)
//   x_neg  : negative weight (-1)
//   x_pos  : positive weight (+1)
// Outputs:
//   s_next_pos : next digit positive carry (+2) -> weight +1 at next digit
//   s_neg      : current digit negative sum (-1)
//
// Arithmetic identity:
//   (+1)*y_i + (+1)*x_pos - (+1)*x_neg = 2*(s_next_pos) - 1*(s_neg)

`timescale 1ns/1ps

module ppm (
    input  wire y_i,
    input  wire x_neg,
    input  wire x_pos,
    output wire s_next_pos,
    output wire s_neg
);

    wire x_neg_bar;
    wire n1, n2, n3;
    wire xor_pos_y;

    // Invert negative input
    inv_gate u_inv (.a(x_neg), .y(x_neg_bar));

    // Majority-like logic for positive carry out (NAND-NAND structure)
    nand2_gate u_nand1 (.a(y_i),   .b(x_pos),     .y(n1));
    nand2_gate u_nand2 (.a(y_i),   .b(x_neg_bar), .y(n2));
    nand2_gate u_nand3 (.a(x_pos), .b(x_neg_bar), .y(n3));

    nand3_gate u_nand_out (.a(n1), .b(n2), .c(n3), .y(s_next_pos));

    // Parity / current digit sum (2-level XOR)
    xor2_gate u_xor1 (.a(x_pos),     .b(y_i),   .y(xor_pos_y));
    xor2_gate u_xor2 (.a(xor_pos_y), .b(x_neg), .y(s_neg));

endmodule
