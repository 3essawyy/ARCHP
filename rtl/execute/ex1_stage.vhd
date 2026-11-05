-- =============================================================================
-- ex1_stage : Execute-1 — HLD 4.3
--   register-file read (addresses from ID/EX1) + forwarding muxes A/B,
--   immediate extension, ALU, IN.PORT sample,
--   flag-write requests to the CCR, next EX1/EX2 register value.
--   Everything is suppressed when EX2 flushes this stage (wrong path).
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use work.archp_pkg.all;

entity ex1_stage is
  port (
    d          : in  id_ex1_t;       -- ID/EX1 register
    flush      : in  std_logic;      -- EX2 redirect kills this instruction
    ra_data    : in  word_t;         -- register file, read with d.ra / d.rb (ADR-015)
    rb_data    : in  word_t;
    -- forwarding sources
    ex2_ctrl   : in  ctrl_t;
    ex2_result : in  word_t;
    mem_ctrl   : in  ctrl_t;
    mem_data   : in  word_t;
    wb_ctrl    : in  ctrl_t;
    wb_data    : in  word_t;
    in_port    : in  word_t;
    -- outputs
    q          : out ex1_ex2_t;      -- next EX1/EX2 register value
    zn_we      : out std_logic;      -- CCR write requests
    c_we       : out std_logic;
    z, n, c    : out std_logic;
    in_rd      : out std_logic       -- IN.PORT consumed this cycle (testbench strobe)
  );
end entity ex1_stage;

architecture rtl of ex1_stage is
  signal sel_a, sel_b   : std_logic_vector(1 downto 0);
  signal fa, fb         : word_t;
  signal imm_ext        : word_t;
  signal alu_b          : word_t;
  signal result         : word_t;
  signal a_zn, a_c      : std_logic;
  signal live           : std_logic;
begin
  fwd : entity work.forwarding_unit
    port map (ra => d.ra, rb => d.rb, swap2 => d.ctrl.swap2, ex2_ctrl => ex2_ctrl,
              mem_ctrl => mem_ctrl, wb_ctrl => wb_ctrl, sel_a => sel_a, sel_b => sel_b);

  with sel_a select fa <=
    ex2_result when "01",
    mem_data   when "10",
    wb_data    when "11",
    ra_data    when others;

  with sel_b select fb <=
    ex2_result when "01",
    mem_data   when "10",
    wb_data    when "11",
    rb_data    when others;

  imm_ext(15 downto 0)  <= d.imm;
  imm_ext(31 downto 16) <= (others => d.imm(15) and d.ctrl.imm_sext);
  alu_b <= imm_ext when d.ctrl.b_imm = '1' else fb;

  u_alu : entity work.alu
    port map (op => d.ctrl.alu_op, a => fa, b => alu_b, shamt => d.imm(4 downto 0),
              in_port => in_port, result => result, z => z, n => n, c => c,
              zn_we => a_zn, c_we => a_c);

  live  <= d.ctrl.valid and not flush;
  zn_we <= live and d.ctrl.flags_we and a_zn;
  c_we  <= live and d.ctrl.flags_we and a_c;
  in_rd <= '1' when live = '1' and d.ctrl.alu_op = ALU_IN else '0';

  process (d, live, result, fb)
  begin
    q        <= C_EX1_EX2_NOP;
    if live = '1' then
      q.ctrl   <= d.ctrl;
      q.result <= result;
      q.b      <= fb;                    -- store data (PUSH/STD), never the immediate
      q.target <= d.imm(C_ADDR_W - 1 downto 0);
      q.ret_pc <= d.ret_pc;
    end if;
  end process;
end architecture rtl;
