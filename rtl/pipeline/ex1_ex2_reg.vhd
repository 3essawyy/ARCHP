-- =============================================================================
-- ex1_ex2_reg : pipeline register EX1/EX2 (between Execute-1 and Execute-2)
-- Always advances (stalls never reach past ID, see HLD 6); bubbles and flushes
-- arrive as a NOP value on d. Synchronous reset to NOP (valid = 0).
-- Field list and sizes: archp_pkg.ex1_ex2_t, HLD section 5.
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use work.archp_pkg.all;

entity ex1_ex2_reg is
  port (
    clk, rst : in  std_logic;
    d        : in  ex1_ex2_t;
    q        : out ex1_ex2_t
  );
end entity ex1_ex2_reg;

architecture rtl of ex1_ex2_reg is
  signal r : ex1_ex2_t := C_EX1_EX2_NOP;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        r <= C_EX1_EX2_NOP;
      else
        r <= d;
      end if;
    end if;
  end process;
  q <= r;
end architecture rtl;
