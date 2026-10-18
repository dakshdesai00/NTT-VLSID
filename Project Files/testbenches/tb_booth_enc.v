`timescale 1ns/1ps

module tb_booth_enc;
    reg  x_msb;
    reg  x_mid;
    reg  x_lsb;
    wire one;
    wire onen;
    wire two;
    wire twon;

    integer i;
    integer errors;
    reg exp_one, exp_onen, exp_two, exp_twon;

    booth_enc uut (
        .x_msb(x_msb),
        .x_mid(x_mid),
        .x_lsb(x_lsb),
        .one(one),
        .onen(onen),
        .two(two),
        .twon(twon)
    );

    initial begin
        $dumpfile("booth_enc_waves.vcd");
        $dumpvars(0, tb_booth_enc);
        errors = 0;
        $display("==================================================================");
        $display("       TESTBENCH: Radix-4 Booth Encoder (Table I Verification)    ");
        $display("==================================================================");
        $display(" x[2i+1] x[2i] x[2i-1] | two twon one onen | Expected | Status");
        $display("-----------------------|-------------------|----------|-------");

        for (i = 0; i < 8; i = i + 1) begin
            {x_msb, x_mid, x_lsb} = i[2:0];
            #10;
            // Table I exact truth table
            case (i[2:0])
                3'b000: {exp_two, exp_twon, exp_one, exp_onen} = 4'b0000;
                3'b001: {exp_two, exp_twon, exp_one, exp_onen} = 4'b0010;
                3'b010: {exp_two, exp_twon, exp_one, exp_onen} = 4'b0010;
                3'b011: {exp_two, exp_twon, exp_one, exp_onen} = 4'b1000;
                3'b100: {exp_two, exp_twon, exp_one, exp_onen} = 4'b0100;
                3'b101: {exp_two, exp_twon, exp_one, exp_onen} = 4'b0001;
                3'b110: {exp_two, exp_twon, exp_one, exp_onen} = 4'b0001;
                3'b111: {exp_two, exp_twon, exp_one, exp_onen} = 4'b0000;
            endcase

            if ({two, twon, one, onen} === {exp_two, exp_twon, exp_one, exp_onen}) begin
                $display("    %b      %b       %b   |   %b    %b    %b    %b  |   %b   | PASS",
                         x_msb, x_mid, x_lsb, two, twon, one, onen, {exp_two, exp_twon, exp_one, exp_onen});
            end else begin
                $display("    %b      %b       %b   |   %b    %b    %b    %b  |   %b   | FAIL ***",
                         x_msb, x_mid, x_lsb, two, twon, one, onen, {exp_two, exp_twon, exp_one, exp_onen});
                errors = errors + 1;
            end
        end

        $display("==================================================================");
        if (errors == 0)
            $display("   >>> ALL 8/8 COMBINATIONS PASSED! BOOTH ENCODER VERIFIED! <<<");
        else
            $display("   >>> ERROR: %0d FAILURES DETECTED IN BOOTH ENCODER! <<<", errors);
        $display("==================================================================");
        $finish;
    end
endmodule
