// fa.v: Standard Full Adder (weight-1 inputs)
// s = a ^ b ^ cin
// cout = (a & b) | (cin & (a ^ b))

`timescale 1ns/1ps

module fa (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire s,
    output wire cout
);

    wire axorb;
    wire aandb;
    wire cin_and_axorb;

    // Structural gate implementation
    xor2_gate u_xor1 (.a(a), .b(b), .y(axorb));
    xor2_gate u_xor2 (.a(axorb), .b(cin), .y(s));

    and2_gate u_and1 (.a(a), .b(b), .y(aandb));
    and2_gate u_and2 (.a(cin), .b(axorb), .y(cin_and_axorb));
    or2_gate  u_or1  (.a(aandb), .b(cin_and_axorb), .y(cout));

endmodule

// Basic 2-input primitive gates for clean 1:1 Cadence mapping
module and2_gate (input wire a, input wire b, output wire y);
    assign y = a & b;
endmodule

module or2_gate (input wire a, input wire b, output wire y);
    assign y = a | b;
endmodule

module xor2_gate (input wire a, input wire b, output wire y);
    assign y = a ^ b;
endmodule

module inv_gate (input wire a, output wire y);
    assign y = ~a;
endmodule

module nand2_gate (input wire a, input wire b, output wire y);
    assign y = ~(a & b);
endmodule

module nand3_gate (input wire a, input wire b, input wire c, output wire y);
    assign y = ~(a & b & c);
endmodule
