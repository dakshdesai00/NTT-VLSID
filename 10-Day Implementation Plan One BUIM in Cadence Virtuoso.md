# 10-Day Implementation Plan

The biggest risk in this project is not drawing the schematics. It is that the paper leaves details ambiguous (digit alignment, the final reduction, sign handling). So the plan is **software** **model first, RTL second, transistors last**.

Assumptions: a 45 nm PDK (e.g. gpdk045) and the two of you working in parallel. Adjust if your PDK differs.

## Overview

| Day | Focus | Deliverable |
| --- | --- | --- |
| 1 | Python golden model of CFMM + butterfly | Bit-accurate model, test vectors |
| 2 | Verilog: leaf cells and Booth/PPG | Passing testbenches |
| 3 | Verilog: mrHY4A, HRAU, mr4a/mr4s, BUIM top | Full RTL matches Python |
| 4 | Virtuoso setup, gate library, PPM/MMP/FA | Verified leaf cell schematics |
| 5 | mrHY4A, Booth encoder, PPG mux | Symbols + truth-table sims |
| 6 | 6T SRAM cell, 12-column row, read | WL/BL/BLB waveforms |
| 7 | HRAU: register rows, mr4a/mr4s | HRAU schematic + sim |
| 8 | BUIM top-level integration | Full-butterfly transient run |
| 9 | Verification, fixes, waveform capture | Final plots |
| 10 | Buffer, report/slides, backup | Final submission |

## Day 1: Python model

**Daksh: model the algorithm.**

- Implement radix-4 Booth recoding: X'\[i\] = -2x\[2i+1\] + x\[2i\] + x\[2i-1\], with M = 8 digits.
- Implement the LSD-first loop with W' = W·4^(M-1) mod q. Each iteration does S\_i = S\_(i-1)/4 + P\_i, with the dropped digit S\_(i-1)\[0\] compensated by S\_(i-1)\[0\]·(-δ) at digit position e/2 - 1 = 3.
- Check the identity yourself: 4·(−13·64) = −3328 ≡ 1 (mod 3329), so 4⁻¹ ≡ −δ·2^(e−2).
- Verify final S ≡ W·X (mod q) for all W in \[0, q) and many X.

**Mitwa: model the data representation.**

- Write functions to convert between integers and the 3-bit-per-digit redundant format (weights −2, +1, +1), including B2R.
- Model PPM, MMP, FA, mrHY4A, mr4a and mr4s as truth-table functions, and check each against the equations on slide 5.
- Compute Z0 = Y + S and Z1 = Y − S.

**Track these questions now:**

- The maximum |S| over all inputs (does it really stay inside (−4q, 4q)?).
- The range of Z0/Z1. Since Y is not reduced, Y ± S can exceed 4q. This is your "final reduction" question from slide 16. Decide and document your answer (e.g. "output is correct mod q; congruence is what we verify").
- Dump 50 to 100 test vectors (Y, X, W, expected Z0 mod q, Z1 mod q) to a file. You will reuse them until Day 9.

**Exit criterion:** the model matches (Y ± X·W) mod q for 100,000 random cases.

## Day 2: Verilog, leaf blocks

- **Daksh:** booth\_enc.v (one/onen/two/twon from Table I), ppg\_mux.v (4:1 mux per bit using BL/BLB/shifted-BL), plus a small SRAM-row behavioural model that outputs W' and its complement.
- **Mitwa:** ppm.v, mmp.v, fa.v, mrhy4a.v, each with an exhaustive truth-table testbench.
- Keep every module **purely structural** (assign statements using AND/OR/XOR), so you can see exactly which gates appear. This is step 2 in your slides ("see which gates each unit uses").

**Exit criterion:** every leaf module passes exhaustive tests against the Day 1 Python functions.

## Day 3: Verilog, HRAU and BUIM

- Build hrau.v: D0..D7 registers, first-row mrHY4A, second-row compensation (R = S\[0\]·(−δ)), ÷4 as wiring, R0/R1 shift registers, and mr4a/mr4s (with D flip-flops).
- Build buim.v: SRAM row → PPG → HRAU, with a small control FSM that counts 8 multiply clocks then 8 add/sub clocks.
- Write a testbench that reads your Day 1 vectors and compares Z0 and Z1 mod q.

**Exit criterion:** the full RTL butterfly passes all vectors and you have a waveform with the 8+8 clock timing. If a mismatch appears, debug with the Python model digit by digit. This is why Day 1 matters.

**Cut tip:** if mr4a/mr4s fails, get Day 3 working up to S in R0 first, and finish the add/sub on Day 4's evening.

## Day 4: Virtuoso setup and basic cells

- Create the library, set up the PDK, and make a test bench cell with VDD/GND and pulse sources.
- Decide your supply and clock. The paper reports 714 MHz, but for a student schematic simulation, **run at a relaxed clock like 100 to 200 MHz** to avoid fighting timing.
- Draw transistor-level **INV, NAND2, NAND3, NOR2, XOR2, XNOR2, mux** using minimum-length devices and sensible W/L (PMOS about 2× NMOS).
- Build the **PPM** from the paper's Fig. 1(b) gate-level circuit, then **MMP** (same cell, rewired), and **FA**.
- Create symbols for each.
- Simulate with a transient that sweeps all 8 input combinations and compare against the truth tables.

**Exit criterion:** PPM, MMP, FA symbols are done and verified.

## Day 5: mrHY4A, Booth encoder, PPG

- **Daksh:** Booth encoder schematic from your Verilog equations (about 10 gates). Test all 8 input combos from Table I. Then the 4:1 mux PPG bit-slice (transmission-gate or AOI), plus an array of 12 for one digit.
- **Mitwa:** mrHY4A = FA + PPM wired per slide 10. Test against the Python table, covering all valid input combinations.
- Make symbols for each.

**Exit criterion:** the Booth encoder and mrHY4A truth-table plots are captured. They are slide-ready as items 2 and 6 of your waveform list.

## Day 6: SRAM

- Draw a **6T SRAM cell**, sizing it with the usual cell ratio and pull-up ratio so a read does not disturb it.
- Build a 12-column row (storing W' in 2's complement) with precharge, a wordline driver, and BL/BLB outputs.
- Simulate: write W' (or preload with an initial condition), precharge, assert WL, and capture **WL, BL, BLB**.
- Connect BL/BLB to the PPG mux inputs and check the shifted-bitline trick (2W' uses the neighbouring bitline).

**Exit criterion:** the SRAM read waveform is captured (item 1 of your waveform list) and the PPG produces correct Pᵢ from a real SRAM read.

**Simplification:** if time is tight, preload the cells using ic statements instead of simulating a write cycle. Mention this explicitly in your report.

## Day 7: HRAU

- Draw the D-register (D flip-flop or latch pair) and a 3-bit digit register.
- Assemble the HRAU: 8 mrHY4A in the first row, the second-level row for compensation, D0..D7, and the R0/R1 shift registers.
- Build the mr4a/mr4s cell from its figure (FAs, PPM, MMP and D flops). Remember that mr4s is mr4a with some wires swapped.
- Test the HRAU alone with a **PWL source feeding 8 pre-computed Pᵢ** values from your Python model, and compare the registers' final S with Python.

**Exit criterion:** HRAU holds the correct S after 8 clocks (item 4). Both partners should work on this, since it is the largest block. Split the work: one does the accumulator, the other does R0/R1 and mr4a/mr4s.

## Day 8: BUIM integration

- Make symbols for the HRAU, PPG and SRAM row, and place them in a BUIM top-level cell.
- Add a clock and control stimulus. This can be an ideal pulse/PWL source for the Booth-select timing and the multiply-to-add switch, rather than a transistor-level FSM.
- Run one complete butterfly: load W' and Y', apply X' digit by digit, run 8 multiply clocks, then 8 add/sub clocks.
- Debug interface timing (setup and hold, correct digit being applied each clock, sign bit/+1 injection for negated partial products).

**Exit criterion:** Z0 and Z1 appear at the outputs. Even if the values are wrong, you have a complete working structure to debug on Day 9.

## Day 9: Verification and waveform capture

- Run at least **10 to 20 test vectors** from your Day 1 file, including corner cases (X=0, W=1, max X, negative-digit-heavy X).
- Decode the output digits back to integers and check Z0 ≡ Y + XW and Z1 ≡ Y − XW (mod q).
- Capture clean plots for your six waveform items: SRAM read, Booth outputs, Pᵢ per digit, D registers over 8 clocks, Z0/Z1 over the next 8, and the PPM/mrHY4A truth-table check.
- Record the supply current to estimate energy per butterfly, and the critical-path delay of one mrHY4A. You can compare these with the paper's 1.33 ns, but treat them as sanity comparisons since your sizing is not the paper's.

## Day 10: Buffer, report, slides

- Use the first half for any outstanding bug.
- Update the slides: add schematics, waveforms, the pass/fail table, and an honest "differences from the paper" slide.
- Back up the library, export the netlists, and write a one-page README listing the hierarchy and how to rerun.

## Risks and how to handle them

| Risk | Mitigation |
| --- | --- |
| Paper's digit alignment is unclear | Resolve in Python on Day 1, and never debug alignment in Virtuoso |
| Final reduction unspecified | Verify congruence mod q, and state clearly that outputs stay in the lazy range |
| Transient sim won't converge or is slow | Relax the clock, use ideal sources for control, simulate sub-blocks separately |
| HRAU too large to draw in time | Draw one slice, then replicate; keep schematics hierarchical |
| Running behind | Drop the transistor-level control FSM and the SRAM write; keep the **read** and everything else |

## Fallback if time runs out

Synthesize your Verilog (Genus, or yosys if you have it) and import the structural netlist into Virtuoso to get a baseline schematic, then hand-draw only the leaf cells and the SRAM. Check with your instructor that this is acceptable, since your slides promise hand-recreated schematics.
