`timescale 1ns/1ps

module tb_mrhy4a;
    reg  x_neg2;
    reg  x_pos;
    reg  x_pp;
    reg  y_pos2;
    reg  y_pos;

    wire s_next_pp;
    wire s_neg2;
    wire s_pos;

    integer i;
    integer errors;
    integer val_x, val_y, val_in, val_out;

    mrhy4a uut (
        .x_neg2(x_neg2),
        .x_pos(x_pos),
        .x_pp(x_pp),
        .y_pos2(y_pos2),
        .y_pos(y_pos),
        .s_next_pp(s_next_pp),
        .s_neg2(s_neg2),
        .s_pos(s_pos)
    );

    initial begin
        $dumpfile("mrhy4a_waves.vcd");
        $dumpvars(0, tb_mrhy4a);
        errors = 0;
        $display("==========================================================================");
        $display("       TESTBENCH: Minimal Redundant Hybrid Radix-4 Adder (mrHY4A)        ");
        $display("==========================================================================");
        $display(" X(n2,p,pp)  Y(p2,p) | S_next_pp S_neg2 S_pos | Val_X Val_Y Sum_In Sum_Out | St");
        $display("---------------------|------------------------|---------------------------|---");

        for (i = 0; i < 32; i = i + 1) begin
            {x_neg2, x_pos, x_pp, y_pos2, y_pos} = i[4:0];
            #10;
            // X: -2*x_neg2 + 1*x_pos + 1*x_pp
            val_x = -2*(x_neg2 ? 1 : 0) + (x_pos ? 1 : 0) + (x_pp ? 1 : 0);
            // Y: +2*y_pos2 + 1*y_pos
            val_y =  2*(y_pos2 ? 1 : 0) + (y_pos ? 1 : 0);
            val_in = val_x + val_y;

            // Output representation: +4*s_next_pp - 2*s_neg2 + 1*s_pos
            val_out = 4*(s_next_pp ? 1 : 0) - 2*(s_neg2 ? 1 : 0) + (s_pos ? 1 : 0);

            if (val_in === val_out) begin
                $display("   %b  %b  %b      %b  %b   |     %b       %b      %b    |   %2d    %2d     %2d      %2d   | OK",
                         x_neg2, x_pos, x_pp, y_pos2, y_pos, s_next_pp, s_neg2, s_pos, val_x, val_y, val_in, val_out);
            end else begin
                $display("   %b  %b  %b      %b  %b   |     %b       %b      %b    |   %2d    %2d     %2d      %2d   | FAIL ***",
                         x_neg2, x_pos, x_pp, y_pos2, y_pos, s_next_pp, s_neg2, s_pos, val_x, val_y, val_in, val_out);
                errors = errors + 1;
            end
        end

        $display("==========================================================================");
        if (errors == 0)
            $display("   >>> ALL 32/32 COMBINATIONS PASSED! mrHY4A VERIFIED! <<<");
        else
            $display("   >>> ERROR: %0d FAILURES DETECTED IN mrHY4A! <<<", errors);
        $display("==========================================================================");
        $finish;
    end
endmodule
