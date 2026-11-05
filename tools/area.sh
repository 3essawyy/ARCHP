#!/usr/bin/env bash
# Area estimate (proxy for the Quartus ranking, NOT the official number):
# GHDL synthesis -> Verilog -> Yosys synth_intel_alm (Cyclone V ALM mapping).
# Usage: tools/area.sh [true|false]   (G_DYNAMIC_BP, default false)
# Initial values (RAM contents, address register) are stripped first so Yosys
# maps the RAM onto 16 M10K blocks instead of flip-flops; the RAM's own few
# bypass LUTs are a Yosys artifact (M10K new-data read-during-write is native).
set -euo pipefail
dyn=${1:-false}
root=$(cd "$(dirname "$0")/.." && pwd)
w=$(mktemp -d)
ghdl -i --std=93c --workdir="$w" $(find "$root/rtl" -name '*.vhd')
ghdl -m --std=93c --workdir="$w" processor_top > /dev/null
ghdl --synth --std=93c --workdir="$w" -gG_DYNAMIC_BP="$dyn" --out=verilog processor_top > "$w/top.v"
# native yosys if installed (apt install yosys), else YoWASP (WebAssembly, slow;
# it only sees the current directory, hence the cd)
Y=$(command -v yosys || command -v yowasp-yosys)
(cd "$w" && "$Y" -q -p "read_verilog top.v; proc; attrmap -remove init; delete t:\$meminit_v2; synth_intel_alm -family cyclonev -top processor_top; tee -o stat.txt stat" > /dev/null)
cat "$w/stat.txt"
rm -rf "$w"
