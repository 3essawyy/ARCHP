-- =============================================================================
-- fetch_unit : Fetch (IF) — HLD 4.1, ADR-004
--   PC (12 bit), next-address priority mux, fetch enable, IF/ID side registers
--   (fetch_valid, id_pc) and the reset boot sequence (PC <- M[0]).
--   The instruction word itself is the RAM output (registered address).
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archp_pkg.all;

entity fetch_unit is
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
    pc_out       : out addr_t       -- PC register (waveform)
  );
end entity fetch_unit;

architecture rtl of fetch_unit is
  signal pc, id_pc_r     : addr_t;
  signal fv              : std_logic;
  signal boot, bootq     : std_logic;     -- reset: read M[0], then load it into PC
  signal target          : addr_t;
  signal fetch_en        : std_logic;
  signal target_inc      : addr_t;
begin
  target <= pcl_addr   when (pcl_valid or bootq) = '1' else
            ex2_target when ex2_redirect = '1' else
            id_target  when id_redirect = '1' else
            id_pc_r    when id_replay = '1' else
            pc;

  target_inc <= std_logic_vector(unsigned(target) + 1);
  fetch_en   <= not mem_busy and not boot and (not block_fetch or pcl_valid or bootq);

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
          pc      <= target_inc;
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
  id_npc      <= pc;                    -- static build: PC = id_pc + 1 whenever fv = 1
  pc_out      <= pc;
end architecture rtl;
