// mr4a.v: Minimally Redundant Radix-4 Adder from HRCIM-NTT Fig. 6(b)
// Adds two redundant digits X_i and Y_i in {-2..2} digit-serially
//
// Inputs:
//   clk, rst_n
//   X: x_neg2 (-2), x_pos (+1), x_pp (+1)
//   Y: y_neg2 (-2), y_pos (+1), y_pp (+1)
//
// Outputs:
//   S: s_neg2 (-2), s_pos (+1), s_pp (+1)

`timescale 1ns/1ps

module mr4a (
    input  wire clk,
    input  wire rst_n,
    // Redundant digit X
    input  wire x_neg2,
    input  wire x_pos,
    input  wire x_pp,
    // Redundant digit Y
    input  wire y_neg2,
    input  wire y_pos,
    input  wire y_pp,
    // Redundant digit Sum
    output wire s_neg2,
    output wire s_pos,
    output wire s_pp
);

    wire s_fa, c_fa;
    wire tl_carry, tl_sum;
    wire br_carry;
    wire bl_carry;
    wire d_top_q;

    // 1. FA adds three weight-1 bits
    fa u_fa (
        .a(x_pos),
        .b(x_pp),
        .cin(y_pos),
        .s(s_fa),
        .cout(c_fa)
    );

    // 2. Top-Left PPM: inputs are y_pp (+), x_neg2 (-), c_fa (+)
    ppm u_ppm_tl (
        .y_i(y_pp),
        .x_neg(x_neg2),
        .x_pos(c_fa),
        .s_next_pos(tl_carry),
        .s_neg(tl_sum)
    );

    // Flip-flop D holding upper transfer bit
    dff u_dff_top (
        .clk(clk),
        .rst_n(rst_n),
        .d(tl_carry),
        .q(d_top_q)
    );

    // 3. Bottom-Right PPM: inputs are d_top_q (+), y_pp (-), s_fa (+)
    ppm u_ppm_br (
        .y_i(d_top_q),
        .x_neg(y_pp),
        .x_pos(s_fa),
        .s_next_pos(br_carry),
        .s_neg(s_pos)
    );

    // 4. Bottom-Left MMP: inputs are y_neg2 (-), tl_sum (-), br_carry (+)
    mmp u_mmp_bl (
        .y_neg(y_neg2),
        .x_neg(tl_sum),
        .x_pos(br_carry),
        .s_next_neg(bl_carry),
        .s_pos(s_neg2)
    );

    // Flip-flop D holding lower transfer bit (output s_pp)
    dff u_dff_bot (
        .clk(clk),
        .rst_n(rst_n),
        .d(bl_carry),
        .q(s_pp)
    );

endmodule
