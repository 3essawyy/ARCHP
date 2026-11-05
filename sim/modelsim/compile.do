# =============================================================================
# ARCHP - compile all VHDL (VHDL-93) into library "work".
# Run from sim/modelsim:   do compile.do
# Order matters (dependencies first); tests/test_modelsim.py re-checks it.
# =============================================================================
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work

set RTL ../../rtl
set TB  ../../tb

vcom -93 -work work $RTL/pkg/archp_pkg.vhd
vcom -93 -work work $RTL/memory/unified_memory.vhd
vcom -93 -work work $RTL/decode/register_file.vhd
vcom -93 -work work $RTL/decode/control_unit.vhd
vcom -93 -work work $RTL/decode/decode_stage.vhd
vcom -93 -work work $RTL/execute/alu.vhd
vcom -93 -work work $RTL/execute/ccr.vhd
vcom -93 -work work $RTL/execute/forwarding_unit.vhd
vcom -93 -work work $RTL/execute/ex1_stage.vhd
vcom -93 -work work $RTL/execute/ex2_stage.vhd
vcom -93 -work work $RTL/pipeline/id_ex1_reg.vhd
vcom -93 -work work $RTL/pipeline/ex1_ex2_reg.vhd
vcom -93 -work work $RTL/pipeline/ex2_mem_reg.vhd
vcom -93 -work work $RTL/pipeline/mem_wb_reg.vhd
vcom -93 -work work $RTL/fetch/btb.vhd
vcom -93 -work work $RTL/fetch/fetch_unit.vhd
vcom -93 -work work $RTL/core/processor_core.vhd
vcom -93 -work work $RTL/top/processor_top.vhd
vcom -93 -work work $TB/tb_util_pkg.vhd
vcom -93 -work work $TB/tb_processor.vhd
