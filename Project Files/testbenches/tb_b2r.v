`timescale 1ns/1ps

module tb_b2r;
    parameter L = 12;
    parameter M = 8;

    reg  [L-1:0] bin_in;
    wire [M-1:0] mr4_neg2;
    wire [M-1:0] mr4_pos;
    wire [M-1:0] mr4_pp;

    integer i, k;
    integer errors;
    integer reconstructed_val;
    integer digit_val;

    b2r #(.L(L), .M(M)) uut (
        .bin_in(bin_in),
        .mr4_neg2(mr4_neg2),
        .mr4_pos(mr4_pos),
        .mr4_pp(mr4_pp)
    );

    initial begin
        $dumpfile("b2r_waves.vcd");
        $dumpvars(0, tb_b2r);
        errors = 0;
        $display("==================================================================");
        $display("   TESTBENCH: Binary to Redundant (B2R) Converter Verification   ");
        $display("==================================================================");

        // Test vectors: 0, 1, 100, 500, 3328 (q-1), 4095
        for (i = 0; i < 20; i = i + 1) begin
            case (i)
                0: bin_in = 12'd0;
                1: bin_in = 12'd1;
                2: bin_in = 12'd2;
                3: bin_in = 12'd3;
                4: bin_in = 12'd4;
                5: bin_in = 12'd100;
                6: bin_in = 12'd500;
                7: bin_in = 12'd1200;
                8: bin_in = 12'd1945;
                9: bin_in = 12'd3328;
                10: bin_in = 12'd4095;
                default: bin_in = $random % 4096;
            endcase
            #10;

            // Reconstruct value from radix-4 digits: sum_{k=0}^{M-1} Digit[k] * 4^k
            reconstructed_val = 0;
            for (k = 0; k < M; k = k + 1) begin
                digit_val = -2 * (mr4_neg2[k] ? 1 : 0) + (mr4_pos[k] ? 1 : 0) + (mr4_pp[k] ? 1 : 0);
                reconstructed_val = reconstructed_val + digit_val * (1 << (2*k));
            end

            if (reconstructed_val === bin_in) begin
                $display("Binary in = %4d | Reconstructed = %4d | PASS", bin_in, reconstructed_val);
            end else begin
                $display("Binary in = %4d | Reconstructed = %4d | FAIL ***", bin_in, reconstructed_val);
                errors = errors + 1;
            end
        end

        $display("==================================================================");
        if (errors == 0)
            $display("   >>> ALL 20 TEST VECTORS PASSED! B2R VERIFIED! <<<");
        else
            $display("   >>> ERROR: %0d FAILURES DETECTED IN B2R! <<<", errors);
        $display("==================================================================");
        $finish;
    end
endmodule
