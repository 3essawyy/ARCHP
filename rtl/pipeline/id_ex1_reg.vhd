-- =============================================================================
-- id_ex1_reg : pipeline register ID/EX1 (between Decode and Execute-1)
-- Always advances (stalls never reach past ID, see HLD 6); bubbles and flushes
-- arrive as a NOP value on d. Synchronous reset to NOP (valid = 0).
-- Field list and sizes: archp_pkg.id_ex1_t, HLD section 5.
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use work.archp_pkg.all;

entity id_ex1_reg is
  port (
    clk, rst : in  std_logic;
    d        : in  id_ex1_t;
    q        : out id_ex1_t
  );
end entity id_ex1_reg;

architecture rtl of id_ex1_reg is
  signal r : id_ex1_t := C_ID_EX1_NOP;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        r <= C_ID_EX1_NOP;
      else
        r <= d;
      end if;
    end if;
  end process;
  q <= r;
end architecture rtl;
