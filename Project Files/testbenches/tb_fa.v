`timescale 1ns/1ps

module tb_fa;
    reg  a;
    reg  b;
    reg  cin;
    wire s;
    wire cout;

    integer i;
    integer errors;
    integer val_in, val_out;

    fa uut (
        .a(a),
        .b(b),
        .cin(cin),
        .s(s),
        .cout(cout)
    );

    initial begin
        $dumpfile("fa_waves.vcd");
        $dumpvars(0, tb_fa);
        errors = 0;
        $display("==================================================");
        $display("        TESTBENCH: Full Adder (FA) Truth Table    ");
        $display("==================================================");
        $display(" a  b  cin | cout  s | Val_In  Val_Out | Status");
        $display("-----------|---------|-----------------|-------");

        for (i = 0; i < 8; i = i + 1) begin
            {a, b, cin} = i[2:0];
            #10;
            val_in  = (a ? 1 : 0) + (b ? 1 : 0) + (cin ? 1 : 0);
            val_out = 2 * (cout ? 1 : 0) + (s ? 1 : 0);

            if (val_in === val_out) begin
                $display(" %b  %b   %b  |   %b   %b |    %d        %d    | PASS",
                         a, b, cin, cout, s, val_in, val_out);
            end else begin
                $display(" %b  %b   %b  |   %b   %b |    %d        %d    | FAIL ***",
                         a, b, cin, cout, s, val_in, val_out);
                errors = errors + 1;
            end
        end

        $display("==================================================");
        if (errors == 0)
            $display("   >>> ALL 8/8 COMBINATIONS PASSED! FA VERIFIED! <<<");
        else
            $display("   >>> ERROR: %0d FAILURES DETECTED IN FA! <<<", errors);
        $display("==================================================");
        $finish;
    end
endmodule
