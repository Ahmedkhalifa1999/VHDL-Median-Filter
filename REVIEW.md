# Code review: VHDL-Median-Filter

Reviewed at commit `e310fc0` ("Add files via upload"). The design was built and
simulated on Linux with GHDL 4.1.0; the reproduction scripts are in `sim/`.

## Summary

The core idea is good and the RTL is functionally correct: a row-parallel,
bit-serial 3x3 median filter that resolves one output bit per clock, MSB
first, with 100 rank-selection units working on a row at once. Simulating the
committed sources on `Unfiltered.png` reproduces the committed `Filtered.png`
bit-for-bit (10,000 of 10,000 pixels) and matches an independent software
model of the intended algorithm exactly.

Everything around that core is in poor shape:

- The design is a simulation-only construct. It cannot be synthesized to real
  hardware as written (asynchronous data loads, non-constant asynchronous
  reset values, three phase-shifted clocks, a 3,205-pin top level).
- Correct operation depends on 1 ns phase relationships between three clocks
  and a reset pulse. Moving any of them by 1 ns corrupts 100% of the output.
- The testbench is not runnable without editing (hard-coded `C:/Users/ahmed`
  paths), does not check anything, and never terminates.
- The MATLAB helper scripts do not work as committed. `InputImage.m` never
  reads the image it is supposed to convert.
- The committed MATLAB comparison image disagrees with the hardware output on
  383 border pixels (max difference 122 grey levels) and nothing documents why.
- The README is a single title line. There is no description, no build or run
  procedure, no explanation of the algorithm, and no license.

## What was done

| Step | Result |
|---|---|
| `ghdl -a --std=08` on all 9 files | Clean. Two `-Wall` warnings (redundant `others`). |
| `ghdl -a --std=93` | Testbench fails: `std_logic_textio` needs `-fsynopsys`. Strict 93 also leaves every component unbound; relaxed `93c` works. |
| `ghdl --synth` on `MedianFilter` | Completes, but infers an asynchronous data-load register and a mux-driven asynchronous reset value (details below). |
| Full-image simulation, 2008 and 93c | Identical output. 1.4 s wall time for 16 us of simulated time. |
| Output vs committed `Filtered.png` | 0 mismatches. |
| Output vs software model (upper median of valid neighbours) | 0 mismatches. |
| Output vs `medfilt2` zero-padding model | 383 border mismatches, 0 interior. |
| Committed `MATLAB-Filtered.png` vs `medfilt2` zero-padding model | 0 mismatches. |
| Reset pulse widened from 2 ns to 3 ns | 10,000 of 10,000 pixels wrong, 100 `U` bits. |
| Output clock phase moved from 3 ns to 1 ns | 10,000 of 10,000 pixels wrong, 100 `U` bits. |
| VSG style linter | 262 findings across 9 files, dominated by layout rules. |

## Findings

### 1. Hardware realizability (critical if this is meant to be synthesized)

**Asynchronous parallel load in `InputPixelRegister.vhd:16-23`.** The process
is sensitive to `DataIn` and loads the register whenever `wren = '1'`, with
the clocked shift in the `elsif`. This describes a transparent latch on the
data bus that overrides a flip-flop. GHDL's synthesizer emits it as
`if wren = '1' then q <= DataIn; elsif rising_edge(clk)`. FPGA flip-flops only
support asynchronous set or reset to a constant, so vendor tools will either
reject this or build 2,400 latches with the associated timing hazards. The
load should be synchronous.

**Non-constant asynchronous reset value in `Median.vhd:29-36` and
`MedianEdge.vhd`.** `MedianPos` is initialised inside the `if reset = '1'`
branch from `mode`. The synthesized netlist shows a `with mode select`
mux feeding the asynchronous reset input of the register. Again, hardware
asynchronous resets take constants only. The same process also lists `mode`
in its sensitivity list, which is required for the simulation to work (see
finding 2) but is not a clocked-process idiom that synthesis tools accept.

**Three clocks.** The top level takes `clk`, `Iregclk` and `Oregclk`, which
the testbench generates as the same 20 ns clock offset by 1 ns, 2 ns and 3 ns.
The synthesized netlist confirms two clock domains driving nine register
groups. This is a single-clock design expressed as three clocks to get
ordering right in simulation. It should be one clock with enables, or at least
one clock with the input shift, compute and output shift scheduled explicitly.

**Port widths.** `MedianFilter.vhd:8-9` declares a 2,400-bit input and an
800-bit output. With the five control pins that is 3,205 top-level pins.
`InputMemory` is a parallel-loaded bank of 300 shift registers fed straight
from that bus. A realizable version needs a streaming pixel interface and a
line buffer. The comment in `InputMemory.vhd:6` acknowledges the parallel
load is a choice; it should be called out as a simulation shortcut.

### 2. Timing fragility (critical for anyone who touches the testbench)

The design has no state counter, no `done` flag and no handshake. `Median`
resolves a bit on every `clk` edge forever; it only stops because the
testbench asserts `NewRow` (used as the reset) every 160 ns. The bookkeeping
that makes this work is:

- `NewRow` is high from t = 0 to t = 2 ns (`TestBench.vhd:66-74`).
- `clk` rises at t = 2 ns (`TestBench.vhd:47`), in the same delta cycle that
  `NewRow` falls. `Median` sees `reset = '0'` only because both signals are
  updated in the same simulation delta.
- `Oregclk` rises at t = 3 ns, one nanosecond after the bit is decided.
- `Iregclk` rises at t = 1 ns, while `wren` is still high, so the first edge
  reloads instead of shifting.
- The testbench samples `DataOut` at exactly t = 160 ns, in the same delta
  that the next reset asserts.

I widened the reset pulse by 1 ns: every output pixel was wrong and the
first bit of every column became `U`. I moved the output clock 2 ns earlier:
same result. In silicon the reset-to-clock coincidence at t = 2 ns is a
reset-recovery violation, not a design.

Also note `Median.vhd:29`: `mode` is in the sensitivity list of the clocked
process because at t = 0 the reset fires before `mode` has been driven, so
`MedianPos` is first set to `"---"` and then corrected when `mode` arrives a
delta later. The design works because of a sensitivity-list side effect.

### 3. RTL quality

- **Duplicated modules.** `MedianEdge.vhd` is `Median.vhd` with widths
  changed; `AdderEdge.vhd` is `Adder.vhd` with one fewer full adder. One
  generic entity (`N_INPUTS`, `RANK`) replaces all four files.
- **No generics anywhere.** The image width 100 is baked into
  `MedianFilter.vhd` (`98 downto 1`, `299 downto 0`, `2399 downto 0`),
  `InputMemory.vhd`, `TestBench.vhd:90` (`row = 99`) and both `.m` files.
- **Popcount by hand.** `Adder.vhd` builds a 9-input population count out of
  three `FullAdder` instances and declares `term1..term3` four bits wide with
  initialisers so the undriven upper bits read as zero (GHDL synth warns
  "no assignment for offsets 2:3"). A `for` loop summing bits is clearer and
  synthesizes to the same thing.
- **`mode` means different things in different entities.** In `Median`,
  `'1'` means "edge row"; in `MedianEdge`, `'1'` means "corner". The
  testbench drives one `mode` for the whole row and it happens to line up.
  Name it `edge_row` and document the rank each unit selects.
- **Undocumented boundary convention.** Top and bottom rows are zero-padded
  by the file format (which the RTL relies on: padding must sort below every
  real pixel), while left and right columns use 6-input units. The chosen
  rank is `ceil(n/2)`-th largest of the valid neighbours, i.e. the upper
  median for 6- and 4-pixel windows. This is a reasonable convention and
  avoids the dark border that zero-padding causes, but nothing says so, and
  the committed `MATLAB-Filtered.png` (which is exactly `medfilt2` with zero
  padding) silently disagrees with the RTL on every border pixel that
  matters. Either document the difference or generate the MATLAB reference
  with the same convention.
- **Redundant `when others` on a boolean `case`** in `Median.vhd:42` and
  `MedianEdge.vhd:39` (GHDL `-Wall` flags both). `'0' & MedianPos` in the
  comparison is also unnecessary; `numeric_std` compares unequal widths.
- **Pass-through signals.** `InputMemory.vhd:17-18,25` copy the ports into
  `DataI`/`DataO` for no reason.
- **Missing port modes.** `InputMemory.vhd:8` declares `clk, wren :
  std_logic;` with no `in`. Legal, but inconsistent with every other file.
- **No reset on `OutReg` or `BitOut`.** Harmless here, but the first
  `Oregclk` edge shifts whatever `BitOut` holds, which is how the `U` bits
  appeared in the perturbation experiments.
- **Comment/behaviour mismatch.** `Median.vhd:6` says the median is computed
  "in 8 clock cycles"; the entity has no notion of 8 and relies on being
  reset externally.

### 4. Testbench

- Hard-coded absolute Windows paths (`TestBench.vhd:12-13`). Should be
  generics with relative defaults.
- No self-checking. It writes a text file and reports "Test Finished". Add a
  golden-file comparison or an in-testbench reference model and `assert`.
- Never terminates: all four clock processes loop forever and there is no
  `std.env.finish`/`stop`, so every run must be bounded externally
  (`--stop-time` in GHDL, `run 16 us` in ModelSim).
- Uses `ieee.std_logic_textio`, a Synopsys package that only exists in
  VHDL-2008 as part of the standard. Under VHDL-93 it needs vendor flags.
- Relies on the delta-cycle races described in finding 2.
- No test of anything but the one image: no all-zero, all-255, constant, or
  single-unit directed vectors, and no check of the edge/corner modes in
  isolation.

### 5. MATLAB scripts

- `InputImage.m` declares `image` as its return value, never assigns it, and
  never uses `imagePath`. As committed it cannot run. The four blank lines
  after `fopen` suggest the `imread`/padding lines were deleted before
  upload. It also indexes rows up to 102, so the intended input was a
  100x100 image zero-padded to 102 rows; this requirement is not written
  anywhere.
- Both scripts shadow MATLAB's built-in `image` function with a variable.
- `OutputImage.m` displays with `imshow` (Image Processing Toolbox) but does
  not save, so `Filtered.png` was produced by hand.
- There is no script that produced `MATLAB-Filtered.png`, so the reference
  is not reproducible.

### 6. Repository hygiene

- `README.md` contains only the title. No description of the architecture,
  the bit-serial rank-selection algorithm (which deserves a paragraph, it is
  the interesting part of the project), tool versions, or how to run.
- No license file.
- No build script, project file, Makefile or CI. The dependency order of the
  nine files is not recorded anywhere.
- Single "Add files via upload" commit; no history.
- CRLF line endings throughout, tabs for indentation with space-aligned
  continuation lines, trailing whitespace on 32 lines, and four files
  (`Adder`, `AdderEdge`, `Median`, `MedianEdge`) end in lines that contain
  only tabs.
- Architecture names are inconsistent (`RTL`, `behavior`, `FSM`,
  `Components`); port names mix `clk`, `wren`, `DataIn`, `Oregclk`.
- The sample input text file and expected output text file are not
  committed, so the simulation could not be reproduced without rewriting the
  MATLAB converter.

## Recommendations, in order

1. Make it one clock. Replace the three clocks and the `NewRow` reset with a
   single `clk`, a synchronous `start`/`load` and a 3-bit bit counter inside
   the median unit that raises `done` after the 8th bit.
2. Make the input register load synchronous and give every register a
   synchronous reset with a constant value. Move the `mode`-dependent rank
   into a registered input, not a reset value.
3. Collapse `Median`/`MedianEdge` and `Adder`/`AdderEdge` into generic
   entities; parameterise the image width.
4. Fix the testbench: generics for paths, a reference model or golden file
   with `assert`, `std.env.finish` at the end, and a handful of directed
   vectors for the edge and corner ranks.
5. Fix or replace the MATLAB scripts (the Python versions in `sim/` work),
   document the boundary convention, and regenerate the MATLAB comparison
   with the same convention or explain the difference.
6. Write the README: what the algorithm is, the row-parallel/bit-serial
   architecture, throughput (8 clocks per row), the boundary handling, how to
   build and run, and a license.
7. Normalise line endings and whitespace; add `.gitattributes` and
   `.editorconfig`.

## Reproduction

```sh
apt-get install ghdl && pip install numpy pillow
python3 sim/png_to_tb_input.py Unfiltered.png /tmp/in.txt
sim/run_sim.sh . /tmp/build /tmp/in.txt /tmp/out.txt 08
python3 sim/tb_output_to_png.py /tmp/out.txt /tmp/hw.png
python3 sim/compare.py . /tmp/out.txt
```

Perturbation experiments (extra `sed` expressions applied to a scratch copy
of the testbench):

```sh
# reset pulse 3 ns instead of 2 ns
sim/run_sim.sh . /tmp/bA /tmp/in.txt /tmp/outA.txt 08 \
  's/wait for 2 ns;\(\r\)$/wait for 3 ns;\1/; s/wait for 158 ns;/wait for 157 ns;/'
# output clock at 1 ns instead of 3 ns
sim/run_sim.sh . /tmp/bB /tmp/in.txt /tmp/outB.txt 08 \
  '0,/wait for 3 ns;/s/wait for 3 ns;/wait for 1 ns;/'
```
