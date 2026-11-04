-- =============================================================================
-- ex2_stage : Execute-2 — HLD 4.4
--   * stack unit: SP (12 bit, reset 0xFFF) and SP+-1; push addr = SP,
--     pop addr = SP+1 (ADR-009, ADR-014)
--   * final memory address and store-data word
--   * branch resolution: JZ/JN/JC test the CCR (every older flag writer has
--     already passed EX1). Taken -> clear that flag. Mispredict (taken xor
--     predicted) -> flush ID+EX1 and redirect fetch (ADR-011, ADR-012).
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archp_pkg.all;

entity ex2_stage is
  port (
    clk, rst  : in  std_logic;
    d         : in  ex1_ex2_t;       -- EX1/EX2 register
    flags     : in  std_logic_vector(2 downto 0);  -- CCR: C N Z
    q         : out ex2_mem_t;       -- next EX2/MEM register value
    redirect  : out std_logic;       -- mispredict: flush younger stages, refetch
    target    : out addr_t;          -- correct next PC
    clr       : out br_t;            -- flag to clear (taken JZ/JN/JC)
    bp_valid  : out std_logic;       -- predictor update: a conditional jump resolved
    bp_taken  : out std_logic;
    sp_out    : out addr_t
  );
end entity ex2_stage;

architecture rtl of ex2_stage is
  signal sp     : addr_t;
  signal sp_pm  : addr_t;            -- SP + 1 (pop) or SP - 1 (push)
  signal active : std_logic;
  signal cond   : std_logic;
  signal taken  : std_logic;
begin
  -- ---------------------------------------------------------------- branch unit
  with d.ctrl.br select cond <=
    flags(0) when BR_Z,
    flags(1) when BR_N,
    flags(2) when BR_C,
    '0'      when others;
  taken    <= d.ctrl.valid and cond;
  redirect <= d.ctrl.valid and (taken xor d.ctrl.pred);
  target   <= d.target when taken = '1' else d.ret_pc;
  clr      <= d.ctrl.br when taken = '1' else BR_NONE;
  bp_valid <= d.ctrl.valid when d.ctrl.br /= BR_NONE else '0';
  bp_taken <= taken;

  active <= d.ctrl.valid when d.ctrl.stack /= STK_NONE else '0';
  sp_pm  <= std_logic_vector(unsigned(sp) + 1) when d.ctrl.stack = STK_POP else
            std_logic_vector(unsigned(sp) - 1);

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        sp <= C_SP_RESET;
      elsif active = '1' then
        sp <= sp_pm;
      end if;
    end if;
  end process;

  process (d, sp, sp_pm, flags)
    variable o : ex2_mem_t;
  begin
    o := C_EX2_MEM_NOP;
    if d.ctrl.valid = '1' then
      o.ctrl := d.ctrl;
      -- address: push -> SP, pop -> SP+1, otherwise the ALU result (LDD/STD/vector)
      if d.ctrl.stack = STK_PUSH then
        o.addr := sp;
      elsif d.ctrl.stack = STK_POP then
        o.addr := sp_pm;
      else
        o.addr := d.result(C_ADDR_W - 1 downto 0);
      end if;
      -- data: store word for writes, ALU result otherwise
      if d.ctrl.mem_wr = '1' then
        case d.ctrl.wsel is
          when WSEL_RET =>
            o.data := (others => '0');
            o.data(C_ADDR_W - 1 downto 0) := d.ret_pc;
          when WSEL_CTX =>
            o.data := (others => '0');
            o.data(31 downto 29) := flags;            -- C N Z (ADR-007)
            o.data(C_ADDR_W - 1 downto 0) := d.ret_pc;
          when others =>
            o.data := d.b;
        end case;
      else
        o.data := d.result;
      end if;
    end if;
    q <= o;
  end process;

  sp_out <= sp;
end architecture rtl;
