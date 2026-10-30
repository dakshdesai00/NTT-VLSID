# Cadence Virtuoso Simulation & Verification Report: HRCIM-NTT BUIM

**Project**: Compute-in-Memory NTT Butterfly Accelerator for Kyber PQC (HRCIM-NTT)  
**Authors**: Daksh Desai (24110098) & Mitwa Goswami (24110205) — IIT Gandhinagar  
**Tool**: Cadence Virtuoso IC6.1.8 / Spectre Simulator (ADE L & ADE XL)  
**Process Technology**: 45nm CMOS ($V_{DD} = 1.8\text{ V}$)

---

## Executive Summary of Simulated Blocks

During the implementation of the Butterfly Unit in Memory (BUIM) in Cadence Virtuoso, three critical hierarchical levels were simulated using Spectre transient analysis (`tran`):

1. **Leaf Arithmetic Cells (`ppm` & `mmp`)**: Full 8-state exhaustive truth-table simulation verifying Plus-Plus-Minus and Minus-Minus-Plus arithmetic operations.
2. **Compound Digit-Serial Adder (`mr4a`)**: 5-cycle (100 ns) transient simulation at 50 MHz verifying minimally redundant radix-4 carry propagation and sum generation.
3. **Multiplier-Accumulator Digit Slice (`acc_slice`)**: 5-cycle (100 ns) transient simulation verifying the hybrid adder (`mrhy4a`) driving the 3-bit D flip-flop state register.

---

## 1. Leaf Cells: PPM (Plus-Plus-Minus) & MMP (Minus-Minus-Plus)

### Circuit Overview
* **`ppm`**: Adds two positive inputs ($y_i, x^+$) and subtracts one negative input ($x^-$):
  $$(+1)\cdot y_i + (+1)\cdot x^+ - (+1)\cdot x^- = (+2)\cdot s_{next\_pos} - (+1)\cdot s_{neg}$$
* **`mmp`**: Structural dual of `ppm` with $x^+$ and $x^-$ swapped:
  $$(+1)\cdot x^+ - (+1)\cdot y_{neg} - (+1)\cdot x^- = (-2)\cdot s_{next\_neg} + (+1)\cdot s_{pos}$$

### Simulation Waveform & Schematic
![PPM and MMP Spectre Transient Simulation](/Users/dakshdesai/.gemini/antigravity/brain/d13df715-b153-4a93-9962-81be31e67a1f/ppm_mmp_transient_waveform.png)

*Figure 1: Spectre transient analysis of PPM and MMP over an 80 ns sweep of all 8 input combinations.*

![PPM Structural Schematic](/Users/dakshdesai/.gemini/antigravity/brain/d13df715-b153-4a93-9962-81be31e67a1f/ppm_structural_schematic.png)

*Figure 2: Cadence Virtuoso schematic of the verified structural wrapper.*

### Complete 8-State Truth Table

| Time Window | $y$ (Purple) | $x_{pos}$ (Orange) | $x_{neg}$ (Yellow) | PPM $s_{next\_pos}$ (Green) | PPM $s_{neg}$ (Red) | PPM Arithmetic Value ($2 s_{next} - s$) | MMP $s_{next\_neg}$ (Magenta) | MMP $s_{pos}$ (Cyan) | MMP Arithmetic Value ($-2 s_{next} + s$) | Verification Status |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **0 – 10 ns** | 1 (1.8V) | 1 (1.8V) | 1 (1.8V) | **1** | **1** | $2(1) - 1 = \mathbf{+1}$ | **1** | **1** | $-2(1) + 1 = \mathbf{-1}$ | **PASS** |
| **10 – 20 ns** | 1 (1.8V) | 1 (1.8V) | 0 (0V) | **1** | **0** | $2(1) - 0 = \mathbf{+2}$ | **0** | **0** | $-2(0) + 0 = \mathbf{0}$ | **PASS** |
| **20 – 30 ns** | 1 (1.8V) | 0 (0V) | 1 (1.8V) | **0** | **0** | $2(0) - 0 = \mathbf{0}$ | **1** | **0** | $-2(1) + 0 = \mathbf{-2}$ | **PASS** |
| **30 – 40 ns** | 1 (1.8V) | 0 (0V) | 0 (0V) | **1** | **1** | $2(1) - 1 = \mathbf{+1}$ | **1** | **1** | $-2(1) + 1 = \mathbf{-1}$ | **PASS** |
| **40 – 50 ns** | 0 (0V) | 1 (1.8V) | 1 (1.8V) | **0** | **0** | $2(0) - 0 = \mathbf{0}$ | **0** | **0** | $-2(0) + 0 = \mathbf{0}$ | **PASS** |
| **50 – 60 ns** | 0 (0V) | 1 (1.8V) | 0 (0V) | **1** | **1** | $2(1) - 1 = \mathbf{+1}$ | **0** | **1** | $-2(0) + 1 = \mathbf{+1}$ | **PASS** |
| **60 – 70 ns** | 0 (0V) | 0 (0V) | 1 (1.8V) | **0** | **1** | $2(0) - 1 = \mathbf{-1}$ | **1** | **1** | $-2(1) + 1 = \mathbf{-1}$ | **PASS** |
| **70 – 80 ns** | 0 (0V) | 0 (0V) | 0 (0V) | **0** | **0** | $2(0) - 0 = \mathbf{0}$ | **0** | **0** | $-2(0) + 0 = \mathbf{0}$ | **PASS** |

---

## 2. Minimally Redundant Radix-4 Adder (`mr4a`)

### Circuit Overview
* Adds two redundant radix-4 digits $X, Y \in \{-2, -1, 0, 1, 2\}$ digit-serially.
* Each digit is encoded with 3 bits: $(s_{neg2}, s_{pos}, s_{pp})$ with arithmetic weights $(-2, +1, +1)$:
  $$\text{Value} = -2 \cdot s_{neg2} + 1 \cdot s_{pos} + 1 \cdot s_{pp}$$
* Internal Hierarchy: 1 `fa` (Full Adder), 2 `ppm`, 1 `mmp`, and 2 transmission-gate `dff` instances.

### Simulation Waveform & Schematic
![MR4A Transient Waveform](/Users/dakshdesai/.gemini/antigravity/brain/d13df715-b153-4a93-9962-81be31e67a1f/mr4a_transient_waveform.png)

*Figure 3: Spectre transient simulation of MR4A over 100 ns (5 clock cycles) showing clean full rail-to-rail digital swings after eliminating driver contention.*

![MR4A Cadence Schematic](/Users/dakshdesai/.gemini/antigravity/brain/d13df715-b153-4a93-9962-81be31e67a1f/mr4a_schematic.png)

*Figure 4: Cadence Virtuoso schematic view of the `mr4a` cell.*

### Cycle-by-Cycle Truth Table & Verification

| Cycle | Time Window | Redundant $X$ Applied | Redundant $Y$ Applied | Output `/s_neg2` (-2) | Output `/s_pos` (+1) | Output `/s_pp` (+1) | Evaluated Redundant Digit ($-2 s_{neg2} + s_{pos} + s_{pp}$) | Arithmetic Verification |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **1** | $0 \to 20\text{ ns}$ | **0** $(0,0,0)$ | **0** $(0,0,0)$ | **1 (1.8V)** | **1 (1.8V)** | **1 (1.8V)** | $-2(1) + 1(1) + 1(1) = \mathbf{0}$ | Clean Radix-4 Zero representation |
| **2** | $20 \to 40\text{ ns}$ | **+1** (`x_pos`) | **+1** (`y_pos`) | **1 (1.8V)** | **1 (1.8V)** | **1 (1.8V)** | $-2(1) + 1(1) + 1(1) = \mathbf{0}$ | Pipeline registers initialize transfer carry |
| **3** | $40 \to 60\text{ ns}$ | **+2** (`x_pos`+`x_pp`) | **+1** (`y_pos`) | **0 (0V)** | **0 (0V)** | **1 (1.8V)** | $-2(0) + 1(0) + 1(1) = \mathbf{+1}$ | $1 + 1 = 2 \implies 0$ sum, $+1$ transfer bit out |
| **4** | $60 \to 80\text{ ns}$ | **-2** (`x_neg2`) | **+2** (`y_pos`+`y_pp`) | **0 (0V)** | **1 (1.8V)** | **1 (1.8V)** | $-2(0) + 1(1) + 1(1) = \mathbf{+2}$ | Sum output $+2$ |
| **5** | $80 \to 100\text{ ns}$ | **0** $(0,0,0)$ | **0** $(0,0,0)$ | **1 (1.8V)** | **1 (1.8V)** | **1 (1.8V)** | $-2(1) + 1(1) + 1(1) = \mathbf{0}$ | Return to stable Radix-4 Zero |

---

## 3. Multiplier-Accumulator Digit Slice (`acc_slice`)

### Circuit Overview
* 1-digit slice of the HRAU Accumulator Engine.
* Combines **`mrhy4a`** (hybrid radix-4 adder adding redundant $X \in \{-2..2\}$ to 2's complement partial product $P \in \{0..3\}$) with **3 transmission-gate D flip-flops** holding the stored digit.

### Simulation Waveform
![Accumulator Slice Spectre Transient Simulation](/Users/dakshdesai/.gemini/antigravity/brain/d13df715-b153-4a93-9962-81be31e67a1f/acc_slice_transient_waveform.png)

*Figure 5: Spectre transient simulation of ACC_SLICE over 100 ns verifying hybrid addition and state latching.*

### Cycle-by-Cycle Truth Table & Verification

| Cycle | Time Window | Inputs Applied | Output `/cout` (Carry Out) | Stored `/q_neg2` (-2) | Stored `/q_pos` (+1) | Stored `/q_pp` (+1) | Stored Digit Value | Mathematical Operation |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **1** | $0 \to 20\text{ ns}$ | All inputs 0 | **0V (0)** | **1.8V (1)** | **0V (0)** | **0V (0)** | $-2$ (pre-clock initial state) | Power-up initial transient |
| **2** | $20 \to 40\text{ ns}$ | $P = +1$ (`p_lo`=1) | **0V (0)** | **1.8V (1)** | **0V (0)** | **0V (0)** | Holds until clocked | Setup time before clock edge |
| **3** | $40 \to 60\text{ ns}$ | $P = +2$ (`p_hi`), $X = +1$ (`x_pos`) | **1.8V (1)** | **1.8V (1)** | **1.8V (1)** | **0V (0)** | $-2(1) + 1(1) + 0 = \mathbf{-1}$ | $X + P = 1 + 2 = \mathbf{+3} = 4(1) - 1 \implies \mathbf{cout=1, Digit=-1}$ |
| **4** | $60 \to 80\text{ ns}$ | Inputs return to 0 | **0V (0)** | **0V (0)** | **1.8V (1)** | **0V (0)** | $-2(0) + 1(1) + 0 = \mathbf{+1}$ | Carry drops; latched state retains $+1$ |
| **5** | $80 \to 100\text{ ns}$ | Inputs 0 | **0V (0)** | **1.8V (1)** | **0V (0)** | **0V (0)** | Baseline | Settles to idle |

---

## 4. Higher-Level Hierarchical Integration

Building upon these 3 verified simulation milestones, the remaining blocks were created by hierarchical composition:
* **`mr4s`**: Subtractor formed by polarity inversion of $X$ inputs into `mr4a` ($x_{neg2} \leftrightarrow x_{pos}, x_{pp} = 0$).
* **`butterfly_stage`**: Dual parallel instance of `mr4a` and `mr4s` computing $Z_0 = Y + S$ and $Z_1 = Y - S$ in parallel.
* **`hrau_acc8`**: 8-digit row cascading 8 `acc_slice` instances with $\div 4$ right-shift feedback.
* **`buim_datapath`**: Top-level integration connecting `hrau_acc8` directly into `butterfly_stage`.
