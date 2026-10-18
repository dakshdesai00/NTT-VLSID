// mrhy4a.v: Minimal Redundant Hybrid Radix-4 Adder from HRCIM-NTT Fig. 6(a)
// Adds one redundant digit X in {-2..+2} and one 2-bit two's complement digit Y in {0..3}
//
// Inputs:
//   x_neg2 : X weight -2 (x^{2-})
//   x_pos  : X weight +1 (x^{+})
//   x_pp   : X weight +1 (x^{++})
//   y_pos2 : Y weight +2 (y^{+2})
//   y_pos  : Y weight +1 (y^{+})
//
// Outputs:
//   s_next_pp : Carry out to next digit (weight +4 = weight +1 at next digit)
//   s_neg2    : Current digit sum weight -2 (s^{2-})
//   s_pos     : Current digit sum weight +1 (s^{+})

`timescale 1ns/1ps

module mrhy4a (
    // Redundant digit X
    input  wire x_neg2,
    input  wire x_pos,
    input  wire x_pp,
    // 2-bit two's complement digit Y
    input  wire y_pos2,
    input  wire y_pos,
    // Outputs
    output wire s_next_pp,
    output wire s_neg2,
    output wire s_pos
);

    wire c_pos2; // Carry from FA to PPM with weight +2

    // Step 1: FA adds three weight-1 bits (x_pos, x_pp, y_pos)
    fa u_fa (
        .a(x_pos),
        .b(x_pp),
        .cin(y_pos),
        .s(s_pos),
        .cout(c_pos2)
    );

    // Step 2: PPM adds weight-2 bits (y_pos2, c_pos2) and subtracts x_neg2
    ppm u_ppm (
        .y_i(y_pos2),
        .x_neg(x_neg2),
        .x_pos(c_pos2),
        .s_next_pos(s_next_pp),
        .s_neg(s_neg2)
    );

endmodule
