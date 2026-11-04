-- =============================================================================
-- decode_stage : Decode (ID) — HLD 4.2
--   * instruction word = RAM output (the RAM's registered address makes it the
--     IF/ID instruction register, ADR-004); valid when fetch_valid = 1
--   * control unit, register-file read addresses, immediate, return PC
--   * load-use hazard detection unit (HDU): stall = bubble + replay
--   * micro-op sequencer: SWAP, INT and the hardware interrupt (2 uops each,
--     ADR-007/008); interrupt injection replaces the valid instruction in ID
--   * HLT: stop fetching, let older instructions drain (ADR-010)
--   * JMP/CALL: redirect fetch in this cycle (0 bubbles, ADR-011)
--   * RET/RTI: stop fetching until WB loads PC from the stack (`wait`)
--   * a flush (older branch mispredicted in EX2) cancels everything decode
--     started: micro-op phase, wait, and even a speculative HLT
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use work.archp_pkg.all;

entity decode_stage is
  port (
    clk, rst    : in  std_logic;
    instr       : in  word_t;        -- RAM output
    fetch_valid : in  std_logic;     -- instr is a fetched instruction
    id_pc       : in  addr_t;        -- address of instr
    id_npc      : in  addr_t;        -- address of instr + 1
    id_pred     : in  std_logic;     -- fetch predicted this instruction as a taken jump
    flush       : in  std_logic;     -- EX2 redirect: kill the instruction in ID
    mem_busy    : in  std_logic;     -- MEM stage owns the memory this cycle
    pcl_valid   : in  std_logic;     -- WB loads PC this cycle (ends `wait`)
    int_pending : in  std_logic;     -- latched INTR.IN request
    -- hazard detection inputs (instructions in EX1 and EX2)
    ex1_ctrl    : in  ctrl_t;
    ex2_ctrl    : in  ctrl_t;
    -- register file read
    ra_addr     : out reg_addr_t;
    rb_addr     : out reg_addr_t;
    ra_data     : in  word_t;
    rb_data     : in  word_t;
    -- outputs
    id_ex1_d    : out id_ex1_t;      -- next ID/EX1 register value
    replay      : out std_logic;     -- re-fetch id_pc (instruction not consumed)
    redirect    : out std_logic;     -- JMP/CALL: fetch from `target` now
    target      : out addr_t;
    block_fetch : out std_logic;     -- do not fetch this cycle
    halted      : out std_logic;
    halt_pc     : out addr_t
  );
end entity decode_stage;

architecture rtl of decode_stage is
  signal opcode            : opcode_t;
  signal f_rd, f_ra, f_rb  : reg_addr_t;
  signal phase, phase_n    : std_logic;     -- 2nd micro-op of SWAP / INT
  signal hw_phase, hw_n    : std_logic;     -- 2nd micro-op of a hardware interrupt
  signal inject            : std_logic;     -- start a hardware interrupt now
  signal cu_hw, cu_phase   : std_logic;
  signal is_int            : std_logic;
  signal is_cond           : std_logic;
  signal redirect_i        : std_logic;
  signal fix_i             : std_logic;
  signal halt_now          : std_logic;
  signal halted_r          : std_logic;
  signal halt_pc_r         : addr_t;
  signal cu_ctrl           : ctrl_t;
  signal use_a, use_b      : std_logic;
  signal valid_in          : std_logic;
  signal lu_stall          : std_logic;
  signal is_swap, is_hlt   : std_logic;
  signal is_jump, is_ret   : std_logic;
  signal wait_r            : std_logic;     -- waiting for a PC load (RET/RTI)
  signal start_wait        : std_logic;

  function load_hazard(c : ctrl_t; r : reg_addr_t) return std_logic is
  begin
    if c.valid = '1' and c.wb_mem = '1' and c.rd = r then
      return '1';
    end if;
    return '0';
  end function;
begin
  opcode <= instr(31 downto 27);
  f_rd   <= instr(26 downto 24);
  f_ra   <= instr(23 downto 21);
  f_rb   <= instr(20 downto 18);

  cu : entity work.control_unit
    port map (opcode => opcode, phase => cu_phase, hw => cu_hw,
              ctrl => cu_ctrl, use_a => use_a, use_b => use_b);

  ra_addr <= f_ra;
  rb_addr <= f_rb;

  valid_in <= fetch_valid and not halted_r and not wait_r and not flush;
  is_swap  <= '1' when opcode = OP_SWAP else '0';
  is_hlt   <= '1' when opcode = OP_HLT else '0';
  is_jump  <= '1' when opcode = OP_JMP or opcode = OP_CALL else '0';
  is_ret   <= '1' when opcode = OP_RET or opcode = OP_RTI else '0';
  is_int   <= '1' when opcode = OP_INT else '0';
  is_cond  <= '1' when opcode = OP_JZ or opcode = OP_JN or opcode = OP_JC else '0';

  -- hardware interrupt (ADR-007): replaces the valid instruction in ID, never
  -- inside a micro-op sequence; its return address is that instruction's PC
  inject   <= valid_in and int_pending and not phase and not hw_phase;
  cu_hw    <= hw_phase or inject;
  cu_phase <= phase or hw_phase;

  -- load-use: a source in use is the destination of a load (LDD/POP) in EX1 or
  -- EX2; its data only exists in WB (synchronous RAM) -> stall until then.
  lu_stall <= (use_a and (load_hazard(ex1_ctrl, f_ra) or load_hazard(ex2_ctrl, f_ra))) or
              (use_b and (load_hazard(ex1_ctrl, f_rb) or load_hazard(ex2_ctrl, f_rb)));

  process (cu_ctrl, valid_in, lu_stall, is_swap, is_int, is_hlt, is_jump, is_ret, is_cond, phase,
           hw_phase, inject, mem_busy, f_rd, f_ra, f_rb, ra_data, rb_data, instr, id_pc, id_npc,
           id_pred)
    variable o   : id_ex1_t;
    variable rep : std_logic;
    variable pn  : std_logic;
    variable hn  : std_logic;
    variable sw  : std_logic;       -- start waiting for a PC load
    variable rd  : std_logic;       -- JMP/CALL redirect
    variable hl  : std_logic;       -- HLT
    variable fix : std_logic;       -- predicted taken but not a conditional jump
  begin
    o          := C_ID_EX1_NOP;
    o.ra       := f_ra;
    o.rb       := f_rb;
    o.a        := ra_data;
    o.b        := rb_data;
    o.imm      := instr(15 downto 0);
    o.ret_pc   := id_npc;
    rep        := '0';
    pn         := phase;
    hn         := hw_phase;
    sw         := '0';
    rd         := '0';
    hl         := '0';
    fix        := '0';

    if valid_in = '1' then
      if hw_phase = '1' then                          -- interrupt uop2: PC <- M[1]
        o.ctrl       := cu_ctrl;
        o.ctrl.valid := '1';
        o.imm        := x"0001";
        hn           := '0';
        sw           := '1';
      elsif inject = '1' then                         -- interrupt uop1: push {flags, PC}
        o.ctrl       := cu_ctrl;
        o.ctrl.valid := '1';
        o.ret_pc     := id_pc;                        -- resume at this instruction
        hn           := '1';
        rep          := '1';
      elsif lu_stall = '1' then
        rep := '1';                                   -- bubble, replay
      elsif is_swap = '1' and phase = '0' then
        if mem_busy = '0' then                        -- uop2 must follow at once
          o.ctrl       := cu_ctrl;
          o.ctrl.valid := '1';
          o.ctrl.rd    := f_rd;                       -- Rdst <- R[Rsrc]
          pn           := '1';
        end if;
        rep := '1';
      elsif is_int = '1' and phase = '0' then         -- INT uop1: push {flags, PC+1}
        o.ctrl       := cu_ctrl;
        o.ctrl.valid := '1';
        pn           := '1';
        rep          := '1';
      else
        o.ctrl        := cu_ctrl;
        o.ctrl.valid  := '1';
        o.ctrl.retire := '1';
        o.ctrl.rd     := f_rd;
        if is_swap = '1' then
          o.ctrl.rd := f_ra;                          -- SWAP uop2: Rsrc <- R[Rdst]
          pn        := '0';
        elsif is_int = '1' then                       -- INT uop2: PC <- M[2 + index]
          o.imm     := "00000000000000" & '1' & instr(0);
          pn        := '0';
          sw        := '1';
        elsif is_ret = '1' then
          sw := '1';
        elsif is_jump = '1' then
          rd := '1';
        elsif is_hlt = '1' then
          hl := '1';
        elsif is_cond = '1' then
          o.ctrl.pred := id_pred;                     -- EX2 checks the prediction
        elsif id_pred = '1' then
          fix := '1';                                 -- stale BTB hit: back to npc
        end if;
      end if;
    end if;
    id_ex1_d   <= o;
    replay     <= rep;
    phase_n    <= pn;
    hw_n       <= hn;
    start_wait <= sw;
    redirect_i <= rd or fix;
    fix_i      <= fix;
    halt_now   <= hl;
  end process;

  redirect    <= redirect_i;
  target      <= id_npc when fix_i = '1' else instr(C_ADDR_W - 1 downto 0);
  block_fetch <= halted_r or wait_r or halt_now or start_wait;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        phase     <= '0';
        hw_phase  <= '0';
        wait_r    <= '0';
        halted_r  <= '0';
        halt_pc_r <= (others => '0');
      else
        if flush = '1' then                -- wrong path: undo everything decode started
          phase    <= '0';
          hw_phase <= '0';
          wait_r   <= '0';
          halted_r <= '0';
        else
          phase    <= phase_n;
          hw_phase <= hw_n;
          if halt_now = '1' then
            halted_r  <= '1';
            halt_pc_r <= id_pc;
          end if;
          if start_wait = '1' then
            wait_r <= '1';
          elsif pcl_valid = '1' then
            wait_r <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

  halted  <= halted_r;
  halt_pc <= halt_pc_r;
end architecture rtl;
