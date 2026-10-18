// mmp.v: Minus-Minus-Plus cell from HRCIM-NTT Fig. 1(c)
// Inputs:
//   y_neg   : negative weight (-1)
//   x_neg   : negative weight (-1)
//   x_pos   : positive weight (+1)
// Outputs:
//   s_next_neg : next digit negative carry (-2) -> weight -1 at next digit
//   s_pos      : current digit positive sum (+1)
//
// Arithmetic identity:
//   (+1)*x_pos - (+1)*y_neg - (+1)*x_neg = -2*(s_next_neg) + 1*(s_pos)

`timescale 1ns/1ps

module mmp (
    input  wire y_neg,
    input  wire x_neg,
    input  wire x_pos,
    output wire s_next_neg,
    output wire s_pos
);

    wire x_pos_bar;
    wire n1, n2, n3;
    wire xor_neg_y;

    // Invert positive input
    inv_gate u_inv (.a(x_pos), .y(x_pos_bar));

    // Majority logic: carry active when (y_neg + x_neg - x_pos) >= 1
    nand2_gate u_nand1 (.a(y_neg), .b(x_neg),     .y(n1));
    nand2_gate u_nand2 (.a(y_neg), .b(x_pos_bar), .y(n2));
    nand2_gate u_nand3 (.a(x_neg), .b(x_pos_bar), .y(n3));

    nand3_gate u_nand_out (.a(n1), .b(n2), .c(n3), .y(s_next_neg));

    // Parity sum
    xor2_gate u_xor1 (.a(x_neg),     .b(y_neg), .y(xor_neg_y));
    xor2_gate u_xor2 (.a(xor_neg_y), .b(x_pos), .y(s_pos));

endmodule
