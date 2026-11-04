-- =============================================================================
-- ccr : condition-code register CCR<2:0> = C N Z  (ADR-006)
-- Write sources, in program order (older first):
--   WB  RTI restore  (exclusive: decode waits after RTI, so EX1/EX2 are empty)
--   EX2 taken JZ/JN/JC clears its flag
--   EX1 ALU update   (younger than EX2, so it wins for the bits it writes)
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use work.archp_pkg.all;

entity ccr is
  port (
    clk, rst   : in  std_logic;
    -- EX1 (already gated with valid and not-flushed)
    ex1_zn_we  : in  std_logic;
    ex1_c_we   : in  std_logic;
    ex1_z      : in  std_logic;
    ex1_n      : in  std_logic;
    ex1_c      : in  std_logic;
    -- EX2: clear one flag (Z, N or C) of a taken conditional jump
    ex2_clr    : in  br_t;
    -- WB: RTI restore
    wb_rti     : in  std_logic;
    wb_flags   : in  std_logic_vector(2 downto 0);  -- C N Z
    flags      : out std_logic_vector(2 downto 0)   -- C N Z
  );
end entity ccr;

architecture rtl of ccr is
  signal f : std_logic_vector(2 downto 0) := (others => '0');
begin
  process (clk)
    variable v : std_logic_vector(2 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        f <= (others => '0');
      elsif wb_rti = '1' then
        f <= wb_flags;
      else
        v := f;
        case ex2_clr is
          when BR_Z   => v(0) := '0';
          when BR_N   => v(1) := '0';
          when BR_C   => v(2) := '0';
          when others => null;
        end case;
        if ex1_zn_we = '1' then
          v(0) := ex1_z;
          v(1) := ex1_n;
        end if;
        if ex1_c_we = '1' then
          v(2) := ex1_c;
        end if;
        f <= v;
      end if;
    end if;
  end process;
  flags <= f;
end architecture rtl;
