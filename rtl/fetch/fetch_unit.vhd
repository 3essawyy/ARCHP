-- =============================================================================
-- fetch_unit : Fetch (IF) — HLD 4.1, ADR-004
--   PC (12 bit), next-address priority mux, fetch enable, IF/ID side registers
--   (fetch_valid, id_pc) and the reset boot sequence (PC <- M[0]).
--   The instruction word itself is the RAM output (registered address).
--   G_DYNAMIC_BP (bonus, ADR-012): a BTB looked up with the fetch address
--   predicts the next PC in the fetch cycle (address calculation in fetch).
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archp_pkg.all;

entity fetch_unit is
  generic (
    G_DYNAMIC_BP : boolean := false
  );
  port (
    clk, rst     : in  std_logic;
    -- redirect requests, highest priority first
    pcl_valid    : in  std_logic;   -- WB: PC <- memory data (RET/RTI/vectors)
    pcl_addr     : in  addr_t;      -- memory data (11:0)
    ex2_redirect : in  std_logic;   -- EX2: branch mispredict
    ex2_target   : in  addr_t;
    id_redirect  : in  std_logic;   -- ID: JMP / CALL
    id_target    : in  addr_t;
    id_replay    : in  std_logic;   -- ID: re-fetch the instruction in decode
    -- fetch permission
    mem_busy     : in  std_logic;   -- MEM stage owns the memory port (structural hazard)
    block_fetch  : in  std_logic;   -- halted / waiting for a PC load
    -- outputs
    fetch_addr   : out addr_t;      -- memory address when fetching
    fetch_valid  : out std_logic;   -- IF/ID: RAM output is an instruction
    id_pc        : out addr_t;      -- IF/ID: its address
    id_npc       : out addr_t;      -- IF/ID: its address + 1
    id_pred      : out std_logic;   -- IF/ID: fetched instruction was predicted taken
    pc_out       : out addr_t;      -- PC register (waveform)
    -- predictor update from EX2 (dynamic build only)
    bp_valid     : in  std_logic;
    bp_npc       : in  addr_t;
    bp_taken     : in  std_logic;
    bp_target    : in  addr_t
  );
end entity fetch_unit;

architecture rtl of fetch_unit is
  signal pc, id_pc_r     : addr_t;
  signal fv              : std_logic;
  signal boot, bootq     : std_logic;     -- reset: read M[0], then load it into PC
  signal target          : addr_t;
  signal fetch_en        : std_logic;
  signal target_inc      : addr_t;
  signal pred_taken      : std_logic;   -- BTB says: the instruction at target is a taken branch
  signal pred_tgt        : addr_t;
  signal next_pc         : addr_t;
  signal npc_r           : addr_t;
  signal pred_r          : std_logic;
begin
  target <= pcl_addr   when (pcl_valid or bootq) = '1' else
            ex2_target when ex2_redirect = '1' else
            id_target  when id_redirect = '1' else
            id_pc_r    when id_replay = '1' else
            pc;

  target_inc <= std_logic_vector(unsigned(target) + 1);
  fetch_en   <= not mem_busy and not boot and (not block_fetch or pcl_valid or bootq);

  g_dyn : if G_DYNAMIC_BP generate
    u_btb : entity work.btb
      port map (clk => clk, rst => rst, lk_npc => target_inc, pred_taken => pred_taken,
                pred_tgt => pred_tgt, up_valid => bp_valid, up_npc => bp_npc,
                up_taken => bp_taken, up_tgt => bp_target);
  end generate;
  g_static : if not G_DYNAMIC_BP generate
    pred_taken <= '0';
    pred_tgt   <= (others => '0');
  end generate;

  next_pc <= pred_tgt when pred_taken = '1' else target_inc;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        pc      <= (others => '0');     -- boot reads M[0]
        id_pc_r <= (others => '0');
        fv      <= '0';
        boot    <= '1';
        bootq   <= '0';
      else
        boot  <= '0';
        bootq <= boot;
        if fetch_en = '1' then
          pc      <= next_pc;
          id_pc_r <= target;
          fv      <= '1';
        else
          pc <= target;                 -- remember where to fetch next
          fv <= '0';
        end if;
      end if;
    end if;
  end process;

  fetch_addr  <= target;
  fetch_valid <= fv;
  id_pc       <= id_pc_r;
  pc_out      <= pc;

  -- static build: PC = id_pc + 1 whenever fv = 1, so no extra register;
  -- dynamic build: PC may hold a predicted target, so keep npc and the prediction
  g_npc_static : if not G_DYNAMIC_BP generate
    id_npc  <= pc;
    id_pred <= '0';
  end generate;
  g_npc_dyn : if G_DYNAMIC_BP generate
    process (clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          npc_r  <= (others => '0');
          pred_r <= '0';
        elsif fetch_en = '1' then
          npc_r  <= target_inc;
          pred_r <= pred_taken;
        end if;
      end if;
    end process;
    id_npc  <= npc_r;
    id_pred <= pred_r;
  end generate;
end architecture rtl;
