`timescale 1ns/1ps

module tb_mmp;
    reg  y_neg;
    reg  x_neg;
    reg  x_pos;
    wire s_next_neg;
    wire s_pos;

    integer i;
    integer errors;
    integer val_in, val_out;

    mmp uut (
        .y_neg(y_neg),
        .x_neg(x_neg),
        .x_pos(x_pos),
        .s_next_neg(s_next_neg),
        .s_pos(s_pos)
    );

    initial begin
        $dumpfile("mmp_waves.vcd");
        $dumpvars(0, tb_mmp);
        errors = 0;
        $display("==================================================");
        $display("  TESTBENCH: Minus-Minus-Plus (MMP) Truth Table   ");
        $display("==================================================");
        $display(" y_neg  x_neg  x_pos | s_next_neg  s_pos | Val_In  Val_Out | Status");
        $display("---------------------|-------------------|-----------------|-------");

        for (i = 0; i < 8; i = i + 1) begin
            {y_neg, x_neg, x_pos} = i[2:0];
            #10;
            // Arithmetic identity: (+1)*x_pos - (+1)*y_neg - (+1)*x_neg = -2*(s_next_neg) + 1*(s_pos)
            val_in  = (x_pos ? 1 : 0) - (y_neg ? 1 : 0) - (x_neg ? 1 : 0);
            val_out = -2 * (s_next_neg ? 1 : 0) + (s_pos ? 1 : 0);

            if (val_in === val_out) begin
                $display("   %b      %b      %b   |      %b         %b   |   %2d       %2d   | PASS",
                         y_neg, x_neg, x_pos, s_next_neg, s_pos, val_in, val_out);
            end else begin
                $display("   %b      %b      %b   |      %b         %b   |   %2d       %2d   | FAIL ***",
                         y_neg, x_neg, x_pos, s_next_neg, s_pos, val_in, val_out);
                errors = errors + 1;
            end
        end

        $display("==================================================");
        if (errors == 0)
            $display("   >>> ALL 8/8 COMBINATIONS PASSED! MMP VERIFIED! <<<");
        else
            $display("   >>> ERROR: %0d FAILURES DETECTED IN MMP! <<<", errors);
        $display("==================================================");
        $finish;
    end
endmodule
