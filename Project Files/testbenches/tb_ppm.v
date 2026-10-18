`timescale 1ns/1ps

module tb_ppm;
    reg  y_i;
    reg  x_neg;
    reg  x_pos;
    wire s_next_pos;
    wire s_neg;

    integer i;
    integer errors;
    integer val_in, val_out;

    ppm uut (
        .y_i(y_i),
        .x_neg(x_neg),
        .x_pos(x_pos),
        .s_next_pos(s_next_pos),
        .s_neg(s_neg)
    );

    initial begin
        $dumpfile("ppm_waves.vcd");
        $dumpvars(0, tb_ppm);
        errors = 0;
        $display("==================================================");
        $display("   TESTBENCH: Plus-Plus-Minus (PPM) Truth Table   ");
        $display("==================================================");
        $display(" y_i  x_neg  x_pos | s_next_pos  s_neg | Val_In  Val_Out | Status");
        $display("-------------------|-------------------|-----------------|-------");

        for (i = 0; i < 8; i = i + 1) begin
            {y_i, x_neg, x_pos} = i[2:0];
            #10;
            // Arithmetic identity: (+1)*y_i + (+1)*x_pos - (+1)*x_neg = 2*(s_next_pos) - 1*(s_neg)
            val_in  = (y_i ? 1 : 0) + (x_pos ? 1 : 0) - (x_neg ? 1 : 0);
            val_out = 2 * (s_next_pos ? 1 : 0) - (s_neg ? 1 : 0);

            if (val_in === val_out) begin
                $display("  %b     %b      %b   |      %b        %b   |   %2d       %2d   | PASS",
                         y_i, x_neg, x_pos, s_next_pos, s_neg, val_in, val_out);
            end else begin
                $display("  %b     %b      %b   |      %b        %b   |   %2d       %2d   | FAIL ***",
                         y_i, x_neg, x_pos, s_next_pos, s_neg, val_in, val_out);
                errors = errors + 1;
            end
        end

        $display("==================================================");
        if (errors == 0)
            $display("   >>> ALL 8/8 COMBINATIONS PASSED! PPM VERIFIED! <<<");
        else
            $display("   >>> ERROR: %0d FAILURES DETECTED IN PPM! <<<", errors);
        $display("==================================================");
        $finish;
    end
endmodule
