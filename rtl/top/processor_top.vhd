-- =============================================================================
-- processor_top : Quartus top level — exactly the ports of the brief
--   CLK, RESET.IN, INTR.IN, IN.PORT<31:0>, OUT.PORT<31:0>
-- The core's debug outputs are left open, so synthesis removes everything that
-- only fed them. G_DYNAMIC_BP = false is the ranked static-prediction build.
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use work.archp_pkg.all;

entity processor_top is
  generic (
    G_DYNAMIC_BP : boolean := false
  );
  port (
    clk      : in  std_logic;
    reset_in : in  std_logic;
    intr_in  : in  std_logic;
    in_port  : in  std_logic_vector(31 downto 0);
    out_port : out std_logic_vector(31 downto 0)
  );
end entity processor_top;

architecture rtl of processor_top is
begin
  u_core : entity work.processor_core
    generic map (G_INIT_FILE => "", G_DYNAMIC_BP => G_DYNAMIC_BP)
    port map (
      clk => clk, rst => reset_in, intr => intr_in, in_port => in_port, out_port => out_port,
      dbg_regs => open, dbg_pc => open, dbg_sp => open, dbg_flags => open,
      dbg_halted => open, dbg_halt_pc => open, dbg_idle => open, dbg_retire => open,
      dbg_hwint => open, dbg_in_rd => open, dbg_out_we => open, dbg_out_data => open,
      dbg_mem_we => open, dbg_mem_addr => open, dbg_mem_din => open);
end architecture rtl;
