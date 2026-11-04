-- Toolchain smoke test (T-002): proves GHDL runs a VHDL-93 testbench and that
-- a failing assertion is reported. Replaced by real unit benches in T-005.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_smoke is
  generic (G_FAIL : boolean := false);
end entity;

architecture sim of tb_smoke is
  signal a : unsigned(7 downto 0) := x"7F";
begin
  process
  begin
    a <= a + 1;
    wait for 1 ns;
    assert a = x"80" report "adder broken" severity error;
    assert not G_FAIL report "forced failure" severity error;
    report "TB_PASS" severity note;
    wait;
  end process;
end architecture;
