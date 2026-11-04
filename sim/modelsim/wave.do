# =============================================================================
# ARCHP - demo waveform: the main signals only (brief: R0-R7, PC, SP, Flags,
# CLK, Reset, Interrupt, IN.port, OUT.port). Values in hex.
# =============================================================================
onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -label CLK                 /tb_processor/clk
add wave -noupdate -label Reset               /tb_processor/rst
add wave -noupdate -label Interrupt           /tb_processor/intr
add wave -noupdate -label IN.port  -radix hex /tb_processor/in_port
add wave -noupdate -label OUT.port -radix hex /tb_processor/out_port
add wave -noupdate -label PC       -radix hex /tb_processor/dbg_pc
add wave -noupdate -label SP       -radix hex /tb_processor/dbg_sp
add wave -noupdate -label {Flags (0CNZ)} -radix binary /tb_processor/dbg_flags
add wave -noupdate -label R0 -radix hex {/tb_processor/dbg_regs(0)}
add wave -noupdate -label R1 -radix hex {/tb_processor/dbg_regs(1)}
add wave -noupdate -label R2 -radix hex {/tb_processor/dbg_regs(2)}
add wave -noupdate -label R3 -radix hex {/tb_processor/dbg_regs(3)}
add wave -noupdate -label R4 -radix hex {/tb_processor/dbg_regs(4)}
add wave -noupdate -label R5 -radix hex {/tb_processor/dbg_regs(5)}
add wave -noupdate -label R6 -radix hex {/tb_processor/dbg_regs(6)}
add wave -noupdate -label R7 -radix hex {/tb_processor/dbg_regs(7)}
TreeUpdate [SetDefaultTree]
configure wave -namecolwidth 140
configure wave -valuecolwidth 90
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {400 ns}
