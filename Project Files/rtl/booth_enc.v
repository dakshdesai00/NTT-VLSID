// booth_enc.v: Radix-4 Booth Encoder from HRCIM-NTT Table I
//
// Inputs:
//   x_msb : x[2i+1]
//   x_mid : x[2i]
//   x_lsb : x[2i-1]
//
// Outputs:
//   one   : select +1*W'
//   onen  : select -1*W' (1's complement)
//   two   : select +2*W' (shifted bitline)
//   twon  : select -2*W' (shifted bit-bar line)

`timescale 1ns/1ps

module booth_enc (
    input  wire x_msb,
    input  wire x_mid,
    input  wire x_lsb,
    output wire one,
    output wire onen,
    output wire two,
    output wire twon
);

    wire x_msb_bar;
    wire x_mid_bar;
    wire x_lsb_bar;
    wire mid_xor_lsb;
    wire mid_nor_lsb;
    wire mid_and_lsb;

    // Inversions
    inv_gate u_inv_msb (.a(x_msb), .y(x_msb_bar));
    inv_gate u_inv_mid (.a(x_mid), .y(x_mid_bar));
    inv_gate u_inv_lsb (.a(x_lsb), .y(x_lsb_bar));

    // Intermediate combinations
    xor2_gate u_xor_mid_lsb (.a(x_mid), .b(x_lsb), .y(mid_xor_lsb));
    and2_gate u_and_mid_lsb (.a(x_mid), .b(x_lsb), .y(mid_and_lsb));
    and2_gate u_and_nor     (.a(x_mid_bar), .b(x_lsb_bar), .y(mid_nor_lsb));

    // Encoder outputs per Table I
    and2_gate u_and_one  (.a(x_msb_bar), .b(mid_xor_lsb), .y(one));
    and2_gate u_and_onen (.a(x_msb),     .b(mid_xor_lsb), .y(onen));
    and2_gate u_and_two  (.a(x_msb_bar), .b(mid_and_lsb), .y(two));
    and2_gate u_and_twon (.a(x_msb),     .b(mid_nor_lsb), .y(twon));

endmodule
