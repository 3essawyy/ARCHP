-- Unified memory unit testbench: file initialisation, one-cycle read latency,
-- write then read back, '@' address records.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archp_pkg.all;
use work.tb_util_pkg.all;

entity tb_memory is
  generic (G_INIT_FILE : string := "mem_init.txt");
end entity;

architecture sim of tb_memory is
  signal clk, we   : std_logic := '0';
  signal addr      : addr_t := (others => '0');
  signal din, dout : word_t := (others => '0');
  signal done      : boolean := false;
begin
  clk <= not clk after 5 ns when not done else '0';
  dut : entity work.unified_memory
    generic map (G_INIT_FILE => G_INIT_FILE)
    port map (clk => clk, we => we, addr => addr, din => din, dout => dout);

  process
    procedure expect_at(a : integer; v : word_t) is
    begin
      wait until falling_edge(clk);
      addr <= std_logic_vector(to_unsigned(a, 12));
      wait until falling_edge(clk);   -- one clock later the data is valid
      assert dout = v report "M[" & integer'image(a) & "] = " & to_hex(dout) & " expected "
        & to_hex(v) severity error;
    end procedure;
  begin
    -- init file: 00000004, 11111111, 22222222, then @0FF -> ABCD0123 at 0x0FF
    expect_at(0, x"00000004");
    expect_at(1, x"11111111");
    expect_at(2, x"22222222");
    expect_at(3, x"00000000");
    expect_at(16#0FF#, x"ABCD0123");
    -- latency: data must NOT change in the same cycle the address changes
    wait until falling_edge(clk);
    addr <= std_logic_vector(to_unsigned(1, 12));
    wait for 1 ns;
    assert dout = x"ABCD0123" report "read is not synchronous" severity error;
    -- write then read back
    wait until falling_edge(clk);
    addr <= x"FFF"; din <= x"CAFEF00D"; we <= '1';
    wait until falling_edge(clk);
    we <= '0';
    expect_at(16#FFF#, x"CAFEF00D");
    expect_at(1, x"11111111");
    report "TB_DONE";
    done <= true;
    wait;
  end process;
end architecture;
