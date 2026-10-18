// hrau.v: Hybrid-Redundant Arithmetic Unit from HRCIM-NTT Fig. 5
// Combines:
//   1. 8-digit accumulator registers D0..D7
//   2. Row 1 mrHY4A cells for partial product accumulation (S_{i-1}/4 + P_i)
//   3. Row 2 mrHY4A cells for on-the-fly modulo reduction (adding R = S[0]*(-13) at digit 3)
//   4. Digit-serial mr4a (Z0 = Y + S) and mr4s (Z1 = Y - S)

`timescale 1ns/1ps

module hrau #(
    parameter M = 8,
    parameter L = 12,
    parameter l = 3   // e/2 - 1 = 8/2 - 1 = 3
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        clr_acc,    // Clears accumulator D registers before new multiplication
    input  wire        en_mul,     // Active during 8 multiplication cycles
    input  wire        load_r0,    // Load accumulator sum S into shift register R0
    input  wire        shift_bs,   // Shift R0 and R1 during 8 butterfly cycles
    input  wire [15:0] p_in,       // 16-bit 2's complement partial product from PPG
    
    // Y' stream for butterfly (from B2R / R1)
    input  wire        y_neg2,
    input  wire        y_pos,
    input  wire        y_pp,
    
    // Outputs
    output wire [M-1:0] d_neg2_out,
    output wire [M-1:0] d_pos_out,
    output wire [M-1:0] d_pp_out,
    
    // Butterfly outputs (digit-serial)
    output wire        z0_neg2,
    output wire        z0_pos,
    output wire        z0_pp,
    output wire        z1_neg2,
    output wire        z1_pos,
    output wire        z1_pp
);

    // Accumulator registers D0..D7
    reg [M-1:0] d_neg2;
    reg [M-1:0] d_pos;
    reg [M-1:0] d_pp;

    assign d_neg2_out = d_neg2;
    assign d_pos_out  = d_pos;
    assign d_pp_out   = d_pp;

    // -------------------------------------------------------------
    // Step 1: Abandoned LSD (S[0]) detection and Compensation R
    // -------------------------------------------------------------
    // S[0] in {-2, -1, 0, 1, 2}
    // R = S[0] * (-13)
    reg [15:0] r_comp;
    wire signed [2:0] s0_val;
    assign s0_val = -2*$signed({1'b0, d_neg2[0]}) + $signed({1'b0, d_pos[0]}) + $signed({1'b0, d_pp[0]});

    always @(*) begin
        case (s0_val)
            3'sd1:   r_comp = 16'hFFF3; // -13 in 16-bit 2's complement
            3'sd2:   r_comp = 16'hFFE6; // -26 in 16-bit 2's complement
            -3'sd1:  r_comp = 16'h000D; // +13 in 16-bit 2's complement
            -3'sd2:  r_comp = 16'h001A; // +26 in 16-bit 2's complement
            default: r_comp = 16'h0000; // 0
        endcase
    end

    // -------------------------------------------------------------
    // Step 2: Row 1 of mrHY4A (T = S_{i-1}/4 + P_i)
    // -------------------------------------------------------------
    wire [M-1:0] t_neg2;
    wire [M-1:0] t_pos;
    wire [M-1:0] t_pp;
    wire [M:0]   c_row1;

    assign c_row1[0] = 1'b0;

    genvar j;
    generate
        // Digits 0 to M-2 (0 to 6): add shifted D[j+1] and P_in[2j+1:2j]
        for (j = 0; j < M - 1; j = j + 1) begin : gen_row1
            mrhy4a u_mrhy4a_row1 (
                .x_neg2(d_neg2[j + 1]),
                .x_pos(d_pos[j + 1]),
                .x_pp(d_pp[j + 1]),
                .y_pos2(p_in[2*j + 1]),
                .y_pos(p_in[2*j]),
                .s_next_pp(c_row1[j + 1]),
                .s_neg2(t_neg2[j]),
                .s_pos(t_pos[j])
            );
            assign t_pp[j] = c_row1[j];
        end

        // Digit M-1 (Digit 7): sign extension addition
        mrhy4a u_mrhy4a_row1_msb (
            .x_neg2(1'b0),
            .x_pos(1'b0),
            .x_pp(1'b0),
            .y_pos2(p_in[15]),
            .y_pos(p_in[14]),
            .s_next_pp(c_row1[M]),
            .s_neg2(t_neg2[M - 1]),
            .s_pos(t_pos[M - 1])
        );
        assign t_pp[M - 1] = c_row1[M - 1];
    endgenerate

    // -------------------------------------------------------------
    // Step 3: Row 2 of mrHY4A (Modulo Reduction with R)
    // -------------------------------------------------------------
    wire [M-1:0] d_next_neg2;
    wire [M-1:0] d_next_pos;
    wire [M-1:0] d_next_pp;
    wire [M:l]   c_row2;

    assign c_row2[l] = 1'b0;

    // Digits 0 to l-1 (0 to 2) bypass Row 2 directly
    genvar k_low;
    generate
        for (k_low = 0; k_low < l; k_low = k_low + 1) begin : gen_row2_bypass
            assign d_next_neg2[k_low] = t_neg2[k_low];
            assign d_next_pos[k_low]  = t_pos[k_low];
            assign d_next_pp[k_low]   = t_pp[k_low];
        end
    endgenerate

    // Digits l to M-1 (3 to 7) add R[2(k-l)+1 : 2(k-l)]
    genvar k;
    generate
        for (k = l; k < M; k = k + 1) begin : gen_row2_comp
            localparam p = 2 * (k - l);
            mrhy4a u_mrhy4a_row2 (
                .x_neg2(t_neg2[k]),
                .x_pos(t_pos[k]),
                .x_pp(t_pp[k]),
                .y_pos2(r_comp[p + 1]),
                .y_pos(r_comp[p]),
                .s_next_pp(c_row2[k + 1]),
                .s_neg2(d_next_neg2[k]),
                .s_pos(d_next_pos[k])
            );
            assign d_next_pp[k] = c_row2[k];
        end
    endgenerate

    // -------------------------------------------------------------
    // Step 4: Accumulator Register Updates
    // -------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d_neg2 <= {M{1'b0}};
            d_pos  <= {M{1'b0}};
            d_pp   <= {M{1'b0}};
        end else if (clr_acc) begin
            d_neg2 <= {M{1'b0}};
            d_pos  <= {M{1'b0}};
            d_pp   <= {M{1'b0}};
        end else if (en_mul) begin
            d_neg2 <= d_next_neg2;
            d_pos  <= d_next_pos;
            d_pp   <= d_next_pp;
        end
    end

    // -------------------------------------------------------------
    // Step 5: Shift Register R0 (holding S) & Butterfly mr4a / mr4s
    // -------------------------------------------------------------
    reg [M-1:0] r0_neg2;
    reg [M-1:0] r0_pos;
    reg [M-1:0] r0_pp;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r0_neg2 <= {M{1'b0}};
            r0_pos  <= {M{1'b0}};
            r0_pp   <= {M{1'b0}};
        end else if (load_r0) begin
            r0_neg2 <= d_neg2;
            r0_pos  <= d_pos;
            r0_pp   <= d_pp;
        end else if (shift_bs) begin
            r0_neg2 <= {1'b0, r0_neg2[M-1:1]};
            r0_pos  <= {1'b0, r0_pos[M-1:1]};
            r0_pp   <= {1'b0, r0_pp[M-1:1]};
        end
    end

    // Adder mr4a for Z0 = Y + S
    mr4a u_butterfly_add (
        .clk(clk),
        .rst_n(rst_n),
        .x_neg2(r0_neg2[0]),
        .x_pos(r0_pos[0]),
        .x_pp(r0_pp[0]),
        .y_neg2(y_neg2),
        .y_pos(y_pos),
        .y_pp(y_pp),
        .s_neg2(z0_neg2),
        .s_pos(z0_pos),
        .s_pp(z0_pp)
    );

    // Subtractor mr4s for Z1 = Y - S
    mr4s u_butterfly_sub (
        .clk(clk),
        .rst_n(rst_n),
        .x_neg2(r0_neg2[0]),
        .x_pos(r0_pos[0]),
        .x_pp(r0_pp[0]),
        .y_neg2(y_neg2),
        .y_pos(y_pos),
        .y_pp(y_pp),
        .d_neg2(z1_neg2),
        .d_pos(z1_pos),
        .d_pp(z1_pp)
    );

endmodule
