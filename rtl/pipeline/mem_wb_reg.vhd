-- =============================================================================
-- mem_wb_reg : pipeline register MEM/WB (between Memory and Write-Back)
-- Always advances (stalls never reach past ID, see HLD 6); bubbles and flushes
-- arrive as a NOP value on d. Synchronous reset to NOP (valid = 0).
-- Field list and sizes: archp_pkg.mem_wb_t, HLD section 5.
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use work.archp_pkg.all;

entity mem_wb_reg is
  port (
    clk, rst : in  std_logic;
    d        : in  mem_wb_t;
    q        : out mem_wb_t
  );
end entity mem_wb_reg;

architecture rtl of mem_wb_reg is
  signal r : mem_wb_t := C_MEM_WB_NOP;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        r <= C_MEM_WB_NOP;
      else
        r <= d;
      end if;
    end if;
  end process;
  q <= r;
end architecture rtl;
