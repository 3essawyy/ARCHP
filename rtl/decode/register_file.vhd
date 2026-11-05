-- =============================================================================
-- register_file : R0..R7 (8 x 32 flip-flops), 2 combinational read ports,
-- 1 synchronous write port (WB). Read in EX1 (ADR-015): a value being written
-- this cycle reaches EX1 through WB forwarding, so no internal bypass is needed.
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archp_pkg.all;

entity register_file is
  port (
    clk, rst : in  std_logic;
    ra_addr  : in  reg_addr_t;
    rb_addr  : in  reg_addr_t;
    ra_data  : out word_t;
    rb_data  : out word_t;
    we       : in  std_logic;
    wa       : in  reg_addr_t;
    wd       : in  word_t;
    regs_out : out reg_array_t      -- debug / waveform (R0..R7)
  );
end entity register_file;

architecture rtl of register_file is
  signal regs : reg_array_t := (others => (others => '0'));
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        regs <= (others => (others => '0'));
      elsif we = '1' then
        regs(to_integer(unsigned(wa))) <= wd;
      end if;
    end if;
  end process;

  ra_data <= regs(to_integer(unsigned(ra_addr)));
  rb_data <= regs(to_integer(unsigned(rb_addr)));
  regs_out <= regs;
end architecture rtl;
