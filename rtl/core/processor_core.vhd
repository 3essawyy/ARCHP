-- =============================================================================
-- processor_core : ARCHP six-stage pipelined processor (integration)
--   IF -> ID -> EX1 -> EX2 -> MEM -> WB around one unified memory (HLD 4).
--   The dbg_* outputs exist for the testbench/waveform only; processor_top
--   leaves them open, so synthesis removes anything that only feeds them.
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use work.archp_pkg.all;

entity processor_core is
  generic (
    G_INIT_FILE  : string  := "";      -- simulation memory image (.mem)
    G_DYNAMIC_BP : boolean := false    -- bonus predictor (ADR-012); false = ranked build
  );
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;          -- RESET.IN (synchronous, active high)
    intr     : in  std_logic;          -- INTR.IN
    in_port  : in  word_t;             -- IN.PORT
    out_port : out word_t;             -- OUT.PORT
    -- debug / waveform
    dbg_regs     : out reg_array_t;
    dbg_pc       : out word_t;
    dbg_sp       : out word_t;
    dbg_flags    : out std_logic_vector(3 downto 0);   -- CCR<3:0> = 0 C N Z
    dbg_halted   : out std_logic;
    dbg_halt_pc  : out word_t;
    dbg_idle     : out std_logic;
    dbg_retire   : out std_logic;
    dbg_hwint    : out std_logic;
    dbg_in_rd    : out std_logic;
    dbg_out_we   : out std_logic;
    dbg_out_data : out word_t;
    dbg_mem_we   : out std_logic;
    dbg_mem_addr : out addr_t;
    dbg_mem_din  : out word_t
  );
end entity processor_core;

architecture rtl of processor_core is
  -- fetch
  signal fetch_addr, id_pc, id_npc, pc : addr_t;
  signal fetch_valid                    : std_logic;
  -- memory
  signal mem_busy, mem_we               : std_logic;
  signal mem_addr                       : addr_t;
  signal mem_din, mem_dout              : word_t;
  -- decode
  signal ra_addr, rb_addr               : reg_addr_t;
  signal ra_data, rb_data               : word_t;
  signal replay, block_fetch, halted    : std_logic;
  signal halt_pc                        : addr_t;
  -- pipeline registers (d = next value, q = current)
  signal ide_d, ide_q                   : id_ex1_t;
  signal e12_d, e12_q                   : ex1_ex2_t;
  signal e2m_d, e2m_q                   : ex2_mem_t;
  signal mwb_d, mwb_q                   : mem_wb_t;
  -- execute
  signal ex1_zn_we, ex1_c_we            : std_logic;
  signal ex1_z, ex1_n, ex1_c            : std_logic;
  signal in_rd                          : std_logic;
  signal flags                          : std_logic_vector(2 downto 0);
  signal sp                             : addr_t;
  signal flush                          : std_logic;
  signal ex2_redirect                   : std_logic;
  signal ex2_target                     : addr_t;
  signal ex2_clr                        : br_t;
  -- write-back
  signal wb_data                        : word_t;
  signal wb_we, pcl_valid, wb_rti       : std_logic;
  signal out_r                          : word_t;
  signal regs                           : reg_array_t;
begin
  -- ===================================================================== IF
  u_fetch : entity work.fetch_unit
    port map (clk => clk, rst => rst,
              pcl_valid => pcl_valid, pcl_addr => mem_dout(C_ADDR_W - 1 downto 0),
              ex2_redirect => ex2_redirect, ex2_target => ex2_target,
              id_redirect => '0', id_target => (others => '0'),
              id_replay => replay, mem_busy => mem_busy, block_fetch => block_fetch,
              fetch_addr => fetch_addr, fetch_valid => fetch_valid,
              id_pc => id_pc, id_npc => id_npc, pc_out => pc);

  -- ===================================================================== memory
  -- structural hazard: the MEM stage owns the single port when it needs it
  mem_busy <= e2m_q.ctrl.valid and (e2m_q.ctrl.mem_rd or e2m_q.ctrl.mem_wr);
  mem_addr <= e2m_q.addr when mem_busy = '1' else fetch_addr;
  mem_we   <= e2m_q.ctrl.valid and e2m_q.ctrl.mem_wr;
  mem_din  <= e2m_q.data;

  u_mem : entity work.unified_memory
    generic map (G_INIT_FILE => G_INIT_FILE)
    port map (clk => clk, we => mem_we, addr => mem_addr, din => mem_din, dout => mem_dout);

  -- ===================================================================== ID
  u_decode : entity work.decode_stage
    port map (clk => clk, rst => rst, instr => mem_dout, fetch_valid => fetch_valid,
              id_pc => id_pc, id_npc => id_npc, flush => flush, mem_busy => mem_busy,
              ex1_ctrl => ide_q.ctrl, ex2_ctrl => e12_q.ctrl,
              ra_addr => ra_addr, rb_addr => rb_addr, ra_data => ra_data, rb_data => rb_data,
              id_ex1_d => ide_d, replay => replay, block_fetch => block_fetch,
              halted => halted, halt_pc => halt_pc);

  u_rf : entity work.register_file
    port map (clk => clk, rst => rst, ra_addr => ra_addr, rb_addr => rb_addr,
              ra_data => ra_data, rb_data => rb_data,
              we => wb_we, wa => mwb_q.ctrl.rd, wd => wb_data, regs_out => regs);

  u_id_ex1 : entity work.id_ex1_reg port map (clk => clk, rst => rst, d => ide_d, q => ide_q);

  -- ===================================================================== EX1
  u_ex1 : entity work.ex1_stage
    port map (d => ide_q, flush => flush,
              ex2_ctrl => e12_q.ctrl, ex2_result => e12_q.result,
              mem_ctrl => e2m_q.ctrl, mem_data => e2m_q.data,
              wb_ctrl => mwb_q.ctrl, wb_data => wb_data, in_port => in_port,
              q => e12_d, zn_we => ex1_zn_we, c_we => ex1_c_we,
              z => ex1_z, n => ex1_n, c => ex1_c, in_rd => in_rd);

  u_ccr : entity work.ccr
    port map (clk => clk, rst => rst, ex1_zn_we => ex1_zn_we, ex1_c_we => ex1_c_we,
              ex1_z => ex1_z, ex1_n => ex1_n, ex1_c => ex1_c, ex2_clr => ex2_clr,
              wb_rti => wb_rti, wb_flags => mem_dout(31 downto 29), flags => flags);

  u_ex1_ex2 : entity work.ex1_ex2_reg port map (clk => clk, rst => rst, d => e12_d, q => e12_q);

  -- ===================================================================== EX2
  u_ex2 : entity work.ex2_stage
    port map (clk => clk, rst => rst, d => e12_q, flags => flags, q => e2m_d, sp_out => sp);

  -- control flow (T-007)
  flush        <= '0';
  ex2_redirect <= '0';
  ex2_target   <= (others => '0');
  ex2_clr      <= BR_NONE;

  u_ex2_mem : entity work.ex2_mem_reg port map (clk => clk, rst => rst, d => e2m_d, q => e2m_q);

  -- ===================================================================== MEM
  mwb_d.ctrl <= e2m_q.ctrl;
  mwb_d.data <= e2m_q.data;

  u_mem_wb : entity work.mem_wb_reg port map (clk => clk, rst => rst, d => mwb_d, q => mwb_q);

  -- ===================================================================== WB
  wb_data   <= mem_dout when mwb_q.ctrl.wb_mem = '1' else mwb_q.data;
  wb_we     <= mwb_q.ctrl.valid and mwb_q.ctrl.reg_we;
  pcl_valid <= mwb_q.ctrl.valid and mwb_q.ctrl.pc_load;
  wb_rti    <= mwb_q.ctrl.valid and mwb_q.ctrl.rti;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        out_r <= (others => '0');
      elsif mwb_q.ctrl.valid = '1' and mwb_q.ctrl.is_out = '1' then
        out_r <= mwb_q.data;
      end if;
    end if;
  end process;
  out_port <= out_r;

  -- ===================================================================== debug
  dbg_regs     <= regs;
  dbg_pc       <= x"00000" & pc;
  dbg_sp       <= x"00000" & sp;
  dbg_flags    <= '0' & flags;
  dbg_halted   <= halted;
  dbg_halt_pc  <= x"00000" & halt_pc;
  dbg_idle     <= not (ide_q.ctrl.valid or e12_q.ctrl.valid or e2m_q.ctrl.valid or
                       mwb_q.ctrl.valid);
  dbg_retire   <= mwb_q.ctrl.valid and mwb_q.ctrl.retire;
  dbg_hwint    <= mwb_q.ctrl.valid and mwb_q.ctrl.hwint;
  dbg_in_rd    <= in_rd;
  dbg_out_we   <= mwb_q.ctrl.valid and mwb_q.ctrl.is_out;
  dbg_out_data <= mwb_q.data;
  dbg_mem_we   <= mem_we;
  dbg_mem_addr <= mem_addr;
  dbg_mem_din  <= mem_din;
end architecture rtl;
