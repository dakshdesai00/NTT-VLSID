`timescale 1ns/1ps

module tb_ppg_mux;
    reg bl;
    reg blb;
    reg bl_shift;
    reg blb_shift;
    reg one;
    reg onen;
    reg two;
    reg twon;
    wire p_out;

    integer errors;

    ppg_mux uut (
        .bl(bl),
        .blb(blb),
        .bl_shift(bl_shift),
        .blb_shift(blb_shift),
        .one(one),
        .onen(onen),
        .two(two),
        .twon(twon),
        .p_out(p_out)
    );

    initial begin
        $dumpfile("ppg_mux_waves.vcd");
        $dumpvars(0, tb_ppg_mux);
        errors = 0;
        $display("==================================================================");
        $display("          TESTBENCH: PPG 4:1 Multiplexer Bit-Slice                ");
        $display("==================================================================");

        // Twiddle W' bit: bl=1, blb=0; shifted W' bit: bl_shift=0, blb_shift=1
        bl = 1'b1; blb = 1'b0; bl_shift = 1'b0; blb_shift = 1'b1;

        // Test 1: Zero (all selects 0)
        {two, twon, one, onen} = 4'b0000; #10;
        if (p_out !== 1'b0) begin $display("FAIL: Zero expected 0, got %b", p_out); errors = errors + 1; end
        else $display("PASS: Zero select -> p_out = %b", p_out);

        // Test 2: Select +1*W' (one=1)
        {two, twon, one, onen} = 4'b0010; #10;
        if (p_out !== bl) begin $display("FAIL: +1*W' expected %b, got %b", bl, p_out); errors = errors + 1; end
        else $display("PASS: +1*W' select -> p_out = %b (matches bl)", p_out);

        // Test 3: Select -1*W' (onen=1)
        {two, twon, one, onen} = 4'b0001; #10;
        if (p_out !== blb) begin $display("FAIL: -1*W' expected %b, got %b", blb, p_out); errors = errors + 1; end
        else $display("PASS: -1*W' select -> p_out = %b (matches blb)", p_out);

        // Test 4: Select +2*W' (two=1)
        {two, twon, one, onen} = 4'b1000; #10;
        if (p_out !== bl_shift) begin $display("FAIL: +2*W' expected %b, got %b", bl_shift, p_out); errors = errors + 1; end
        else $display("PASS: +2*W' select -> p_out = %b (matches bl_shift)", p_out);

        // Test 5: Select -2*W' (twon=1)
        {two, twon, one, onen} = 4'b0100; #10;
        if (p_out !== blb_shift) begin $display("FAIL: -2*W' expected %b, got %b", blb_shift, p_out); errors = errors + 1; end
        else $display("PASS: -2*W' select -> p_out = %b (matches blb_shift)", p_out);

        $display("==================================================================");
        if (errors == 0)
            $display("   >>> ALL MODES PASSED! PPG MUX VERIFIED! <<<");
        else
            $display("   >>> ERROR: %0d FAILURES DETECTED IN PPG MUX! <<<", errors);
        $display("==================================================================");
        $finish;
    end
endmodule
