#!/usr/bin/env bash
# Build and run TestBench.vhd with GHDL without modifying the original sources.
#
# Usage: sim/run_sim.sh <repo_dir> <build_dir> <input.txt> <output.txt> [08|93c] [extra sed expr...]
#
# The testbench hard-codes Windows file paths, so a patched copy is written to
# <build_dir>. Extra sed expressions are applied to that copy too (used for
# the timing-perturbation experiments described in REVIEW.md).
set -euo pipefail
REPO=$1; BUILD=$2; IN=$3; OUT=$4; STD=${5:-08}; shift 5 || true
rm -rf "$BUILD"; mkdir -p "$BUILD"
FLAGS="--std=$STD"
# VHDL-93 needs the non-standard Synopsys std_logic_textio; strict --std=93
# also refuses to default-bind the components, so use the relaxed 93c.
[ "$STD" != "08" ] && FLAGS="$FLAGS -fsynopsys"
SEDARGS=(-e "s#C:/Users/ahmed/Desktop/UnfilteredImage.txt#$IN#" -e "s#C:/Users/ahmed/Desktop/FilteredImage.txt#$OUT#")
for e in "$@"; do SEDARGS+=(-e "$e"); done
sed "${SEDARGS[@]}" "$REPO/TestBench.vhd" > "$BUILD/TestBench.vhd"
for f in FullAdder Adder AdderEdge InputPixelRegister InputMemory Median MedianEdge MedianFilter; do
  ghdl -a $FLAGS --workdir="$BUILD" "$REPO/$f.vhd"
done
ghdl -a $FLAGS --workdir="$BUILD" "$BUILD/TestBench.vhd"
ghdl -e $FLAGS --workdir="$BUILD" TestBench
# The testbench never stops on its own (free-running clocks, no std.env.finish),
# so the run must be bounded. 100 rows x 160 ns = 16 us.
ghdl -r $FLAGS --workdir="$BUILD" TestBench --stop-time=16001ns
