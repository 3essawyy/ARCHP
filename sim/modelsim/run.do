# =============================================================================
# ARCHP - load a program into the RAM, reset, run, show the main signals.
# Run from sim/modelsim after "do compile.do":
#
#   do run.do ../../programs/branch            ;# stem: uses branch.mem/.in/.intr
#   do run.do ../../programs/branch dynamic    ;# bonus predictor build
#
# Assemble first:  uv run archp asm programs/branch.asm
# (writes .mem = RAM image, .in = IN.PORT values, .intr = INTR cycles).
# The testbench resets the processor for two cycles, then PC <- M[0].
# =============================================================================
if {$argc < 1} { echo "usage: do run.do <program stem> ?dynamic?"; return }
set stem $1
set dyn false
if {$argc >= 2 && $2 == "dynamic"} { set dyn true }
set in_file ""
set intr_file ""
if {[file exists $stem.in]}   { set in_file   $stem.in }
if {[file exists $stem.intr]} { set intr_file $stem.intr }

vsim -t ns -gG_PROGRAM=$stem.mem -gG_INPUTS=$in_file -gG_INTR=$intr_file \
     -gG_DUMP=$stem.dump -gG_DYNAMIC_BP=$dyn work.tb_processor
do wave.do
run -all
wave zoom full
echo "final state written to $stem.dump"
