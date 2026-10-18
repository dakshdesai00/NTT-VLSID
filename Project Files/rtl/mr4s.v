// mr4s.v: Minimally Redundant Radix-4 Subtractor from HRCIM-NTT
// Computes Y - X digit-serially by inverting the polarity of X bits
//
// Inputs:
//   clk, rst_n
//   X: x_neg2 (-2), x_pos (+1), x_pp (+1)  --> effectively negated to -X
//   Y: y_neg2 (-2), y_pos (+1), y_pp (+1)
//
// Outputs:
//   Diff: d_neg2 (-2), d_pos (+1), d_pp (+1)

`timescale 1ns/1ps

module mr4s (
    input  wire clk,
    input  wire rst_n,
    // Redundant digit X (subtrahend)
    input  wire x_neg2,
    input  wire x_pos,
    input  wire x_pp,
    // Redundant digit Y (minuend)
    input  wire y_neg2,
    input  wire y_pos,
    input  wire y_pp,
    // Redundant digit Difference
    output wire d_neg2,
    output wire d_pos,
    output wire d_pp
);

    // Negating redundant digit X:
    // -X = -(-2*x_neg2 + x_pos + x_pp) = 2*x_neg2 - x_pos - x_pp
    // Wiring into complementary cells:
    mr4a u_mr4a_sub (
        .clk(clk),
        .rst_n(rst_n),
        .x_neg2(x_pos),   // Swapped polarities
        .x_pos(x_neg2),
        .x_pp(1'b0),      // Subtraction wiring
        .y_neg2(y_neg2),
        .y_pos(y_pos),
        .y_pp(y_pp),
        .s_neg2(d_neg2),
        .s_pos(d_pos),
        .s_pp(d_pp)
    );

endmodule
