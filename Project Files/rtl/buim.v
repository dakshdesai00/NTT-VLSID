// buim.v: Butterfly Unit in Memory (BUIM) Top-Level
// Integrates:
//   - Twiddle factor SRAM storage (W' = W * 4^7 mod 3329)
//   - B2R converters for binary inputs X and Y
//   - Booth Encoder and PPG Array
//   - Hybrid-Redundant Arithmetic Unit (HRAU)
//   - FSM controller (8 multiply cycles + 8 add/sub cycles = 16 clock cycles)

`timescale 1ns/1ps

module buim #(
    parameter L = 12,
    parameter M = 8,
    parameter q = 3329
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [L-1:0] x_in,       // Polynomial coefficient X
    input  wire [L-1:0] y_in,       // Polynomial coefficient Y
    input  wire [L-1:0] w_in,       // Twiddle factor W
    
    output reg         busy,
    output reg         done,
    output wire [M-1:0] d_neg2_mon, // Monitoring accumulators
    output wire [M-1:0] d_pos_mon,
    output wire [M-1:0] d_pp_mon,
    
    // Serial redundant outputs
    output wire        z0_neg2,
    output wire        z0_pos,
    output wire        z0_pp,
    output wire        z1_neg2,
    output wire        z1_pos,
    output wire        z1_pp,
    
    // Reconstructed integer outputs mod q
    output reg  [L-1:0] z0_out,
    output reg  [L-1:0] z1_out
);

    // -------------------------------------------------------------
    // FSM State Encoding
    // -------------------------------------------------------------
    localparam IDLE    = 2'b00;
    localparam MULT    = 2'b01; // Cycles 0 to 7: CFMM Modular Multiplication
    localparam ADDSUB  = 2'b10; // Cycles 8 to 15: Digit-Serial Butterfly
    localparam FINISH  = 2'b11;

    reg [1:0] state;
    reg [3:0] count;

    // -------------------------------------------------------------
    // Twiddle Precomputation: W' = (W * 4^(M-1)) mod q
    // In SRAM hardware, W' is preloaded into the 12-column SRAM row
    // -------------------------------------------------------------
    // 4^7 mod 3329: 4^7 = 16384 = 4 * 3329 + 3068 => 16384 % 3329 = 3068
    localparam W_FACTOR = 16384 % q; // 3068
    reg [L-1:0] w_prime;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            w_prime <= {L{1'b0}};
        else if (start)
            w_prime <= (w_in * W_FACTOR) % q;
    end

    // -------------------------------------------------------------
    // B2R Conversion for X and Y
    // -------------------------------------------------------------
    wire [M-1:0] x_mr4_n2, x_mr4_p, x_mr4_pp;
    wire [M-1:0] y_mr4_n2, y_mr4_p, y_mr4_pp;

    b2r #(.L(L), .M(M)) u_b2r_x (
        .bin_in(x_in),
        .mr4_neg2(x_mr4_n2),
        .mr4_pos(x_mr4_p),
        .mr4_pp(x_mr4_pp)
    );

    b2r #(.L(L), .M(M)) u_b2r_y (
        .bin_in(y_in),
        .mr4_neg2(y_mr4_n2),
        .mr4_pos(y_mr4_p),
        .mr4_pp(y_mr4_pp)
    );

    // Shift register R1 for redundant Y'
    reg [M-1:0] r1_neg2, r1_pos, r1_pp;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r1_neg2 <= {M{1'b0}};
            r1_pos  <= {M{1'b0}};
            r1_pp   <= {M{1'b0}};
        end else if (start) begin
            r1_neg2 <= y_mr4_n2;
            r1_pos  <= y_mr4_p;
            r1_pp   <= y_mr4_pp;
        end else if (state == ADDSUB) begin
            r1_neg2 <= {1'b0, r1_neg2[M-1:1]};
            r1_pos  <= {1'b0, r1_pos[M-1:1]};
            r1_pp   <= {1'b0, r1_pp[M-1:1]};
        end
    end

    // -------------------------------------------------------------
    // Booth Encoder for current X' digit
    // -------------------------------------------------------------
    // At cycle i, feed X'[i] into booth encoder
    reg x_msb, x_mid, x_lsb;
    wire [2*M-1:0] x_ext;
    assign x_ext = { {(2*M-L){1'b0}}, x_in };

    always @(*) begin
        if (state == MULT) begin
            x_msb = x_ext[2*count + 1];
            x_mid = x_ext[2*count];
            x_lsb = (count == 0) ? 1'b0 : x_ext[2*count - 1];
        end else begin
            x_msb = 1'b0;
            x_mid = 1'b0;
            x_lsb = 1'b0;
        end
    end

    wire one, onen, two, twon;
    booth_enc u_booth_enc (
        .x_msb(x_msb),
        .x_mid(x_mid),
        .x_lsb(x_lsb),
        .one(one),
        .onen(onen),
        .two(two),
        .twon(twon)
    );

    // -------------------------------------------------------------
    // PPG (Partial Product Generator) Array
    // -------------------------------------------------------------
    // Evaluates 16-bit 2's complement P_i = W' * X'[i]
    wire signed [2:0] booth_digit;
    assign booth_digit = -2*$signed({1'b0, x_msb}) + $signed({1'b0, x_mid}) + $signed({1'b0, x_lsb});
    
    reg signed [15:0] p_partial;
    always @(*) begin
        if (state == MULT)
            p_partial = $signed({4'b0000, w_prime}) * booth_digit;
        else
            p_partial = 16'sh0000;
    end

    // -------------------------------------------------------------
    // HRAU Instance
    // -------------------------------------------------------------
    wire clr_acc  = start;
    wire en_mul   = (state == MULT);
    wire load_r0  = (state == MULT && count == M - 1);
    wire shift_bs = (state == ADDSUB);

    hrau #(.M(M), .L(L), .l(3)) u_hrau (
        .clk(clk),
        .rst_n(rst_n),
        .clr_acc(clr_acc),
        .en_mul(en_mul),
        .load_r0(load_r0),
        .shift_bs(shift_bs),
        .p_in(p_partial),
        .y_neg2(r1_neg2[0]),
        .y_pos(r1_pos[0]),
        .y_pp(r1_pp[0]),
        .d_neg2_out(d_neg2_mon),
        .d_pos_out(d_pos_mon),
        .d_pp_out(d_pp_mon),
        .z0_neg2(z0_neg2),
        .z0_pos(z0_pos),
        .z0_pp(z0_pp),
        .z1_neg2(z1_neg2),
        .z1_pos(z1_pos),
        .z1_pp(z1_pp)
    );

    // -------------------------------------------------------------
    // FSM Control & Output Accumulation
    // -------------------------------------------------------------
    reg signed [31:0] acc_z0, acc_z1;
    reg signed [31:0] s_final_int;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= IDLE;
            count   <= 4'd0;
            busy    <= 1'b0;
            done    <= 1'b0;
            z0_out  <= {L{1'b0}};
            z1_out  <= {L{1'b0}};
            acc_z0  <= 32'sd0;
            acc_z1  <= 32'sd0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        busy    <= 1'b1;
                        state   <= MULT;
                        count   <= 4'd0;
                        acc_z0  <= 32'sd0;
                        acc_z1  <= 32'sd0;
                    end
                end

                MULT: begin
                    if (count == M - 1) begin
                        count <= 4'd0;
                        state <= ADDSUB;
                    end else begin
                        count <= count + 1'b1;
                    end
                end

                ADDSUB: begin
                    // At cycle count=7 (after 8 clocks of multiplication),
                    // the sum S in HRAU is complete.
                    // Accumulate Z0 and Z1 stream:
                    if (count == M - 1) begin
                        state <= FINISH;
                    end else begin
                        count <= count + 1'b1;
                    end
                end

                FINISH: begin
                    busy   <= 1'b0;
                    done   <= 1'b1;
                    // Compute canonical output modulo q
                    // Using the final accumulated sum S in D registers
                    s_final_int = -2*$signed({24'd0, d_neg2_mon[0]}) + $signed({24'd0, d_pos_mon[0]}) + $signed({24'd0, d_pp_mon[0]}) +
                                  (-2*$signed({24'd0, d_neg2_mon[1]}) + $signed({24'd0, d_pos_mon[1]}) + $signed({24'd0, d_pp_mon[1]}))*4 +
                                  (-2*$signed({24'd0, d_neg2_mon[2]}) + $signed({24'd0, d_pos_mon[2]}) + $signed({24'd0, d_pp_mon[2]}))*16 +
                                  (-2*$signed({24'd0, d_neg2_mon[3]}) + $signed({24'd0, d_pos_mon[3]}) + $signed({24'd0, d_pp_mon[3]}))*64 +
                                  (-2*$signed({24'd0, d_neg2_mon[4]}) + $signed({24'd0, d_pos_mon[4]}) + $signed({24'd0, d_pp_mon[4]}))*256 +
                                  (-2*$signed({24'd0, d_neg2_mon[5]}) + $signed({24'd0, d_pos_mon[5]}) + $signed({24'd0, d_pp_mon[5]}))*1024 +
                                  (-2*$signed({24'd0, d_neg2_mon[6]}) + $signed({24'd0, d_pos_mon[6]}) + $signed({24'd0, d_pp_mon[6]}))*4096 +
                                  (-2*$signed({24'd0, d_neg2_mon[7]}) + $signed({24'd0, d_pos_mon[7]}) + $signed({24'd0, d_pp_mon[7]}))*16384;

                    // Modulo reduction to canonical range [0, q-1]
                    z0_out <= ((($signed({20'd0, y_in}) + s_final_int) % $signed(q)) + $signed(q)) % $signed(q);
                    z1_out <= ((($signed({20'd0, y_in}) - s_final_int) % $signed(q)) + $signed(q)) % $signed(q);
                    state  <= IDLE;
                end
            endcase
        end
    end

endmodule
