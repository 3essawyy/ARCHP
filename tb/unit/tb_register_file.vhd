-- Register file unit testbench: reset, write/read, both ports, write-back bypass.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archp_pkg.all;
use work.tb_util_pkg.all;

entity tb_register_file is
end entity;

architecture sim of tb_register_file is
  signal clk, rst, we       : std_logic := '0';
  signal ra, rb, wa         : reg_addr_t := "000";
  signal rda, rdb, wd       : word_t := (others => '0');
  signal regs               : reg_array_t;
  signal done               : boolean := false;
begin
  clk <= not clk after 5 ns when not done else '0';
  dut : entity work.register_file
    port map (clk => clk, rst => rst, ra_addr => ra, rb_addr => rb, ra_data => rda,
              rb_data => rdb, we => we, wa => wa, wd => wd, regs_out => regs);

  process
    procedure write_reg(r : integer; v : word_t) is
    begin
      wait until falling_edge(clk);
      we <= '1'; wa <= std_logic_vector(to_unsigned(r, 3)); wd <= v;
      wait until falling_edge(clk);
      we <= '0';
    end procedure;
  begin
    rst <= '1';
    wait until falling_edge(clk);
    rst <= '0';
    for i in 0 to 7 loop
      assert regs(i) = C_ZERO_WORD report "reset value" severity error;
    end loop;
    for i in 0 to 7 loop
      write_reg(i, std_logic_vector(to_unsigned(i * 16#01010101# + 1, 32)));
    end loop;
    for i in 0 to 7 loop
      ra <= std_logic_vector(to_unsigned(i, 3));
      rb <= std_logic_vector(to_unsigned(7 - i, 3));
      wait for 1 ns;
      assert rda = std_logic_vector(to_unsigned(i * 16#01010101# + 1, 32))
        report "port A R" & integer'image(i) & " = " & to_hex(rda) severity error;
      assert rdb = std_logic_vector(to_unsigned((7 - i) * 16#01010101# + 1, 32))
        report "port B" severity error;
    end loop;
    -- bypass: value being written this cycle is visible on both read ports
    wait until falling_edge(clk);
    ra <= "011"; rb <= "011"; we <= '1'; wa <= "011"; wd <= x"DEADBEEF";
    wait for 1 ns;
    assert rda = x"DEADBEEF" and rdb = x"DEADBEEF" report "bypass" severity error;
    -- no bypass for a different register
    ra <= "010";
    wait for 1 ns;
    assert rda = std_logic_vector(to_unsigned(2 * 16#01010101# + 1, 32))
      report "false bypass" severity error;
    wait until falling_edge(clk);
    we <= '0';
    assert regs(3) = x"DEADBEEF" report "write after bypass" severity error;
    report "TB_DONE";
    done <= true;
    wait;
  end process;
end architecture;
