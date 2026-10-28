# HRCIM-NTT: Compute-in-Memory Butterfly Unit (BUIM) Accelerator

[![Verilog RTL](https://img.shields.io/badge/RTL-Verilog%202001-blue.svg)](file:///Users/dakshdesai/Desktop/VLSI/Project%20Files/rtl)
[![Simulation](https://img.shields.io/badge/Simulation-Cadence%20Virtuoso%20%7C%20Spectre-green.svg)]()
[![Target](https://img.shields.io/badge/Target-CRYSTALS--Kyber%20(FIPS%20203)-orange.svg)]()
[![Institution](https://img.shields.io/badge/Institution-IIT%20Gandhinagar-red.svg)]()

> **Implementation of an SRAM-based Compute-in-Memory (CIM) Butterfly Unit (BUIM) for Number Theoretic Transform (NTT) acceleration in Post-Quantum Cryptography (CRYSTALS-Kyber), designed in Structural Verilog RTL and Cadence Virtuoso CMOS schematics.**

Based on the IEEE TCAS-I 2025 research:
* **Reference**: *X. Zhang, et al., "HRCIM-NTT: An Efficient Compute-in-Memory NTT Accelerator With Hybrid-Redundant Numbers," IEEE Transactions on Circuits and Systems I: Regular Papers, 2025.*
* **Authors**: Daksh Desai (24110098) & Mitwa Goswami (24110205) — Indian Institute of Technology Gandhinagar (IITGN).

---

## 📌 Architectural Overview

The **Butterfly Unit in Memory (BUIM)** integrates modular multiplication and butterfly addition/subtraction directly adjacent to SRAM bitlines, eliminating the memory bandwidth bottleneck in lattice-based cryptography.

```
                    ┌──────────────────────────────────────────────┐
                    │               SRAM Bitlines                  │
                    │   BL[11:0], BLB[11:0] (Twiddle Factor W')    │
                    └──────────────────────┬───────────────────────┘
                                           │
  Polynomial Coeff X                       ▼
  (2 bits/cycle) ──────► ┌───────────────────────────────────┐
                         │   Booth Encoder & PPG MUX Array   │
                         └─────────────────┬─────────────────┘
                                           │ Partial Product P_i (14-bit)
                                           ▼
                         ┌───────────────────────────────────┐
                         │     8-Digit HRAU Accumulator      │
                         │   (Row 1: mrHY4A Accumulation)    │
                         │   (Row 2: Modulo-3329 Reduction)  │
                         └─────────────────┬─────────────────┘
                                           │ 8-Cycle Redundant Stream S
                                           ▼
  Polynomial Coeff Y ──► ┌───────────────────────────────────┐ ──► Z0 = Y + S mod q
  (1 digit/cycle)        │       Digit-Serial Butterfly      │
                         │     mr4a (Add) & mr4s (Sub)       │ ──► Z1 = Y - S mod q
                         └───────────────────────────────────┘
```

### Key Parameters (CRYSTALS-Kyber / ML-KEM)
* **Polynomial Degree**: $N = 256$
* **Modulus**: $q = 3329 = 13 \times 2^8 + 1 \implies \delta = 13, e = 8$
* **Coefficient Bitwidth**: $L = 12\text{ bits}$
* **Radix-4 Digit Count**: $M = \frac{L}{2} + 2 = 8\text{ digits}$
* **Throughput**: **1 Butterfly completed every 8 clock cycles** (fully pipelined).

---

## ⚡ Core Innovations & Mathematical Identities

### 1. Minimally Redundant Radix-4 Representation
Each digit $D \in \{-2, -1, 0, 1, 2\}$ is encoded with **3 bits**:
$$D_k = -2 \cdot d_{neg2}[k] + 1 \cdot d_{pos}[k] + 1 \cdot d_{pp}[k]$$
This allows carry-free addition and eliminates multi-bit propagation delays in the accumulator.

### 2. Carry-Free Modular Multiplication (CFMM)
To prevent wordlength expansion while accumulating $P_i = X'[i] \cdot W'$, the accumulator right-shifts by 1 digit (division by 4: $S/4$) each cycle. In modular arithmetic modulo $q = 3329$:
$$\frac{1}{4} \pmod{3329} \equiv -\delta \cdot 2^{e-2} = -13 \cdot 2^6 = -13 \cdot 4^3$$
The abandoned least significant digit $S[0]$ is dynamically compensated by adding:
$$R = S[0] \cdot (-13)$$
into **Digit 3** ($4^3$). The running sum is mathematically bounded within $(-4q, 4q)$ with **zero overflow** and no dedicated reduction cycles.

### 3. Synchronized 2-Stage Systolic Pipeline
* **Phase 1 (Multiplication)**: Takes $M = 8$ clock cycles in HRAU.
* **Phase 2 (Butterfly Stage)**: Streams out 1 redundant digit per cycle over $M = 8$ clock cycles.
* **Zero-Stall Overlap**: While Butterfly Stage processes Stage $s$, the Multiplier processes Stage $s+1$ simultaneously.

---

## 🧩 Module Hierarchy & Cadence Virtuoso Cells

| Cell Name | Category | Description | Transistors / Primitives |
| :--- | :--- | :--- | :--- |
| **`fa`** | Leaf Cell | 1-bit Full Adder (Weight 1) | 24T transmission-gate / mirror CMOS |
| **`ppm`** | Leaf Cell | Plus-Plus-Minus Cell ($y^+ + x^+ - x^- = 2 s_{next}^+ - s^-$) | Custom complex CMOS (3 NAND + 2 XOR) |
| **`mmp`** | Leaf Cell | Minus-Minus-Plus Cell ($x^+ - x^- - y^- = -2 s_{next}^- + s^+$) | Structural dual of `ppm` ($x^+, x^-$ swapped) |
| **`dff`** | Leaf Cell | Transmission-Gate D Flip-Flop | Master-slave TG without reset overhead |
| **`mrhy4a`** | Compound | Hybrid Radix-4 Adder: adds redundant $X \in \{-2..2\}$ to 2's comp $Y \in \{0..3\}$ | 1 `fa` + 1 `ppm` |
| **`mr4a`** | Compound | Minimally Redundant Radix-4 Adder (2 redundant operands) | 1 `fa` + 2 `ppm` + 1 `mmp` + 2 `dff` |
| **`mr4s`** | Compound | Minimally Redundant Radix-4 Subtractor ($Y - X$) | `mr4a` with polarity-swapped $X$ inputs |
| **`acc_slice`** | Datapath | 1-Digit Accumulator slice with state register | 1 `mrhy4a` + 3 `dff` |
| **`hrau_acc8`** | Datapath | Complete 8-digit accumulator row with shift feedback | 8 `acc_slice` instances |
| **`butterfly_stage`** | Datapath | Parallel dual-output butterfly engine ($Z_0 = Y+S, Z_1 = Y-S$) | 1 `mr4a` + 1 `mr4s` |
| **`buim_datapath`** | Top-Level | Integrated arithmetic datapath | `hrau_acc8` + `butterfly_stage` |

---

## 🔬 Simulation & Verification Results

### 1. Cadence Virtuoso Spectre Transient Verification
* **Leaf Cells**: 100% truth-table verification across all 8 input states for `ppm`, `mmp`, and `fa`.
* **Short-Circuit & Contention Analysis**: Driver contention on intermediate nodes successfully identified via pixel-level path tracing and eliminated; full rail-to-rail swing ($0\text{ V} \leftrightarrow 1.8\text{ V}$) confirmed.
* **Accumulator Latching**: Verified `acc_slice` and `hrau_acc8` under 50 MHz clocking ($20\text{ ns}$ period) with sub-nanosecond rise/fall times.
* **Digit-Serial Butterfly Streaming**: Verified parallel outputs $Z_0$ and $Z_1$ streaming out digits over 8 consecutive clock cycles.

### 2. Verilog RTL Simulation
* Exhaustive self-checking testbenches covering all functional corner cases.
* End-to-end Kyber NTT butterfly verification (`tb_buim.v`) passing **50/50 test vectors**.

To re-run Verilog simulations locally:
```bash
# Verify Leaf Cells
iverilog -o sim_leaf "Project Files/rtl/fa.v" "Project Files/rtl/ppm.v" "Project Files/rtl/mmp.v" "Project Files/testbenches/tb_leaf_cells.v"
vvp sim_leaf

# Verify Complete BUIM Butterfly
iverilog -o sim_buim "Project Files/rtl/"*.v "Project Files/testbenches/tb_buim.v"
vvp sim_buim
```

---

## 📁 Repository Structure

```
.
├── README.md               # Complete Project Documentation
├── VLSI_Presentation.pdf   # Technical Slide Deck & Architecture Review
└── Project Files/
    ├── rtl/                # Verilog Structural RTL
    │   ├── fa.v            # Full Adder
    │   ├── ppm.v           # Plus-Plus-Minus cell
    │   ├── mmp.v           # Minus-Minus-Plus cell
    │   ├── dff.v           # D Flip-Flop
    │   ├── mrhy4a.v        # Hybrid Radix-4 Adder
    │   ├── mr4a.v          # Radix-4 Redundant Adder
    │   ├── mr4s.v          # Radix-4 Redundant Subtractor
    │   ├── booth_enc.v     # Radix-4 Booth Encoder
    │   ├── ppg_mux.v       # Partial Product Generator MUX
    │   ├── b2r.v           # Binary-to-Redundant Converter
    │   ├── hrau.v          # Hybrid Redundant Arithmetic Unit
    │   └── buim.v          # Top-Level BUIM Module
    ├── testbenches/        # Self-Checking Testbenches
    │   ├── tb_leaf_cells.v
    │   ├── tb_mrhy4a.v
    │   ├── tb_mr4a.v
    │   ├── tb_mr4s.v
    │   ├── tb_hrau.v
    │   └── tb_buim.v
    └── model/              # Python Golden Reference Models
```

---

## 👥 Contributors

* **Daksh Desai** (Roll: 24110098) — *Arithmetic Datapath, HRAU, Virtuoso Schematics, and RTL Verification*
* **Mitwa Goswami** (Roll: 24110205) — *SRAM Arrays, Bitline Peripherals, Booth Encoder, and PPG MUX*
* **Institution**: Indian Institute of Technology Gandhinagar (IITGN)
