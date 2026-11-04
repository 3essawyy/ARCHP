-- =============================================================================
-- control_unit : opcode (+ micro-op phase) -> control word (HLD 4.2, ADR-003)
-- Purely combinational. One row per instruction; multi-micro-op instructions
-- (SWAP, INT, hardware interrupt) select their row with `phase` / `hw`.
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use work.archp_pkg.all;

entity control_unit is
  port (
    opcode : in  opcode_t;
    phase  : in  std_logic;     -- 0 = first micro-op, 1 = second micro-op
    hw     : in  std_logic;     -- hardware-interrupt micro-ops (ignore opcode)
    ctrl   : out ctrl_t;        -- valid/retire/rd are completed by decode
    use_a  : out std_logic;     -- reads register port A (Ra)
    use_b  : out std_logic      -- reads register port B (Rb)
  );
end entity control_unit;

architecture rtl of control_unit is
begin
  process (opcode, phase, hw)
    variable c : ctrl_t;
    variable a, b : std_logic;
  begin
    c := C_CTRL_NOP;
    a := '0';
    b := '0';
    if hw = '1' then
      -- hardware interrupt: push {flags, PC of the interrupted instruction},
      -- then read the vector M[1] into PC (ADR-007)
      if phase = '0' then
        c.mem_wr := '1'; c.stack := STK_PUSH; c.wsel := WSEL_CTX; c.hwint := '1';
      else
        c.alu_op := ALU_PASSB; c.b_imm := '1'; c.mem_rd := '1'; c.pc_load := '1';
      end if;
    else
      case opcode is
        when OP_SETC =>
          c.alu_op := ALU_SETC; c.flags_we := '1';
        when OP_NOT =>
          c.alu_op := ALU_NOT; c.flags_we := '1'; c.reg_we := '1'; a := '1';
        when OP_INC =>
          c.alu_op := ALU_INC; c.flags_we := '1'; c.reg_we := '1'; a := '1';
        when OP_OUT =>
          c.alu_op := ALU_PASSA; c.is_out := '1'; a := '1';
        when OP_IN =>
          c.alu_op := ALU_IN; c.reg_we := '1';
        when OP_MOV =>
          c.alu_op := ALU_PASSA; c.reg_we := '1'; a := '1';
        when OP_SWAP =>                          -- uop1: Rd <- R[Ra]; uop2: Ra <- R[Rb]
          c.reg_we := '1'; a := '1'; b := '1';
          if phase = '0' then
            c.alu_op := ALU_PASSA;
          else
            c.alu_op := ALU_PASSB; c.swap2 := '1';
          end if;
        when OP_ADD =>
          c.alu_op := ALU_ADD; c.flags_we := '1'; c.reg_we := '1'; a := '1'; b := '1';
        when OP_SUB =>
          c.alu_op := ALU_SUB; c.flags_we := '1'; c.reg_we := '1'; a := '1'; b := '1';
        when OP_AND =>
          c.alu_op := ALU_AND; c.flags_we := '1'; c.reg_we := '1'; a := '1'; b := '1';
        when OP_IADD =>
          c.alu_op := ALU_ADD; c.b_imm := '1'; c.imm_sext := '1'; c.flags_we := '1';
          c.reg_we := '1'; a := '1';
        when OP_CMP =>
          c.alu_op := ALU_SUB; c.flags_we := '1'; a := '1'; b := '1';
        when OP_SHR =>
          c.alu_op := ALU_SHR; c.flags_we := '1'; c.reg_we := '1'; a := '1';
        when OP_SHL =>
          c.alu_op := ALU_SHL; c.flags_we := '1'; c.reg_we := '1'; a := '1';
        when OP_PUSH =>
          c.mem_wr := '1'; c.stack := STK_PUSH; c.wsel := WSEL_B; b := '1';
        when OP_POP =>
          c.mem_rd := '1'; c.stack := STK_POP; c.reg_we := '1'; c.wb_mem := '1';
        when OP_LDM =>
          c.alu_op := ALU_PASSB; c.b_imm := '1'; c.reg_we := '1';
        when OP_LDD =>                           -- address = Ra + sext(off), no flags
          c.alu_op := ALU_ADD; c.b_imm := '1'; c.imm_sext := '1';
          c.mem_rd := '1'; c.reg_we := '1'; c.wb_mem := '1'; a := '1';
        when OP_STD =>                           -- M[Ra + sext(off)] <- R[Rb]
          c.alu_op := ALU_ADD; c.b_imm := '1'; c.imm_sext := '1';
          c.mem_wr := '1'; c.wsel := WSEL_B; a := '1'; b := '1';
        when OP_JZ | OP_JN | OP_JC =>
          c.br := opcode(1 downto 0);
        when OP_CALL =>
          c.mem_wr := '1'; c.stack := STK_PUSH; c.wsel := WSEL_RET;
        when OP_RET =>
          c.mem_rd := '1'; c.stack := STK_POP; c.pc_load := '1';
        when OP_RTI =>
          c.mem_rd := '1'; c.stack := STK_POP; c.pc_load := '1'; c.rti := '1';
        when OP_INT =>                           -- push {flags, PC+1}; then PC <- M[2+idx]
          if phase = '0' then
            c.mem_wr := '1'; c.stack := STK_PUSH; c.wsel := WSEL_CTX;
          else
            c.alu_op := ALU_PASSB; c.b_imm := '1'; c.mem_rd := '1'; c.pc_load := '1';
          end if;
        when others =>                           -- NOP, HLT, JMP, unused: no datapath action
          null;
      end case;
    end if;
    ctrl  <= c;
    use_a <= a;
    use_b <= b;
  end process;
end architecture rtl;
