// ppg_mux.v: 4:1 Partial Product Generator Mux Bit-Slice from HRCIM-NTT Fig. 4
//
// Inputs:
//   bl        : Bitline for W'[j]
//   blb       : Complementary Bitline for ~W'[j]
//   bl_shift  : Bitline from adjacent column j-1 for 2W'[j]
//   blb_shift : Complementary Bitline from adjacent column j-1 for ~2W'[j]
//   one       : Select 1*W'
//   onen      : Select ~1*W'
//   two       : Select 2*W'
//   twon      : Select ~2*W'
//
// Output:
//   p_out     : 1 bit of partial product P_i[j]

`timescale 1ns/1ps

module ppg_mux (
    input  wire bl,
    input  wire blb,
    input  wire bl_shift,
    input  wire blb_shift,
    input  wire one,
    input  wire onen,
    input  wire two,
    input  wire twon,
    output wire p_out
);

    wire term_one;
    wire term_onen;
    wire term_two;
    wire term_twon;
    wire or1, or2;

    and2_gate u_and1 (.a(one),  .b(bl),        .y(term_one));
    and2_gate u_and2 (.a(onen), .b(blb),       .y(term_onen));
    and2_gate u_and3 (.a(two),  .b(bl_shift),  .y(term_two));
    and2_gate u_and4 (.a(twon), .b(blb_shift), .y(term_twon));

    or2_gate u_or1 (.a(term_one), .b(term_onen), .y(or1));
    or2_gate u_or2 (.a(term_two), .b(term_twon), .y(or2));
    or2_gate u_or3 (.a(or1),      .b(or2),       .y(p_out));

endmodule
