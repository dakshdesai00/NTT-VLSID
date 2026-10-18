`timescale 1ns/1ps

module tb_buim;
    parameter L = 12;
    parameter M = 8;
    parameter q = 3329;

    reg clk;
    reg rst_n;
    reg start;
    reg [L-1:0] x_in;
    reg [L-1:0] y_in;
    reg [L-1:0] w_in;

    wire busy;
    wire done;
    wire [M-1:0] d_neg2_mon;
    wire [M-1:0] d_pos_mon;
    wire [M-1:0] d_pp_mon;
    wire z0_neg2, z0_pos, z0_pp;
    wire z1_neg2, z1_pos, z1_pp;
    wire [L-1:0] z0_out;
    wire [L-1:0] z1_out;

    integer errors;
    integer exp_z0, exp_z1;
    integer test_idx;

    buim #(
        .L(L),
        .M(M),
        .q(q)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .x_in(x_in),
        .y_in(y_in),
        .w_in(w_in),
        .busy(busy),
        .done(done),
        .d_neg2_mon(d_neg2_mon),
        .d_pos_mon(d_pos_mon),
        .d_pp_mon(d_pp_mon),
        .z0_neg2(z0_neg2),
        .z0_pos(z0_pos),
        .z0_pp(z0_pp),
        .z1_neg2(z1_neg2),
        .z1_pos(z1_pos),
        .z1_pp(z1_pp),
        .z0_out(z0_out),
        .z1_out(z1_out)
    );

    // 100 MHz clock generation (10 ns period)
    initial clk = 0;
    always #5 clk = ~clk;

    task run_butterfly(
        input [L-1:0] x_val,
        input [L-1:0] y_val,
        input [L-1:0] w_val
    );
        integer s_mod;
        begin
            @(negedge clk);
            x_in  = x_val;
            y_in  = y_val;
            w_in  = w_val;
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;

            // Wait for completion (16 clock cycles)
            while (!done) @(negedge clk);

            // Compute expected answers with signed math
            s_mod  = (x_val * w_val) % q;
            exp_z0 = (y_val + s_mod) % q;
            exp_z1 = (($signed({20'd0, y_val}) - $signed(s_mod)) % $signed(q) + $signed(q)) % $signed(q);

            if (z0_out === exp_z0 && z1_out === exp_z1) begin
                $display("Test %2d: X=%4d, Y=%4d, W=%4d | Got: Z0=%4d, Z1=%4d | Expected: Z0=%4d, Z1=%4d | PASS",
                         test_idx, x_val, y_val, w_val, z0_out, z1_out, exp_z0, exp_z1);
            end else begin
                $display("Test %2d: X=%4d, Y=%4d, W=%4d | Got: Z0=%4d, Z1=%4d | Expected: Z0=%4d, Z1=%4d | FAIL ***",
                         test_idx, x_val, y_val, w_val, z0_out, z1_out, exp_z0, exp_z1);
                errors = errors + 1;
            end
            test_idx = test_idx + 1;
            @(negedge clk);
        end
    endtask

    initial begin
        $dumpfile("buim_waves.vcd");
        $dumpvars(0, tb_buim);
        rst_n = 1'b0;
        start = 1'b0;
        x_in  = 0;
        y_in  = 0;
        w_in  = 0;
        errors = 0;
        test_idx = 1;

        #20;
        rst_n = 1'b1;
        #20;

        $display("==========================================================================================");
        $display("                 FULL SYSTEM TESTBENCH: BUIM (1 Butterfly Unit in Memory)                 ");
        $display("==========================================================================================");

        // Test 1: Zero X input
        run_butterfly(12'd0, 12'd500, 12'd100);

        // Test 2: Standard Kyber butterfly
        run_butterfly(12'd1200, 12'd500, 12'd1945);

        // Test 3: W = 1 identity test
        run_butterfly(12'd700, 12'd300, 12'd1);

        // Test 4: Maximum corner values
        run_butterfly(12'd3328, 12'd3328, 12'd3328);

        // Test 5: Small values
        run_butterfly(12'd10, 12'd50, 12'd20);

        // Test 6-50: 45 Random test vectors
        for (test_idx = 6; test_idx <= 50; test_idx = test_idx + 1) begin
            run_butterfly($random % q, $random % q, $random % q);
        end

        $display("==========================================================================================");
        if (errors == 0)
            $display("   >>> ALL BUTTERFLY TESTS PASSED! BUIM SYSTEM FULLY OPERATIONAL & VERIFIED! <<<");
        else
            $display("   >>> ERROR: %0d FAILURES DETECTED IN BUIM! <<<", errors);
        $display("==========================================================================================");
        $finish;
    end
endmodule
