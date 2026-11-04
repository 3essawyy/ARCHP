-- =============================================================================
-- btb : branch target buffer with 2-bit saturating counters (bonus, ADR-012)
--   8 entries, direct mapped. Key = address of the branch + 1 ("npc"), which
--   fetch already computes (target + 1) and EX2 already carries (ret_pc), so
--   no extra adder is needed. Lookup is combinational in the fetch cycle:
--   hit with counter >= 2 -> predict taken, next PC = stored target.
--   Update in EX2 for every resolved conditional jump: counter +/- 1, target
--   refreshed; a miss allocates only when taken (counter = 10, weakly taken).
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archp_pkg.all;

entity btb is
  port (
    clk, rst   : in  std_logic;
    -- lookup (fetch)
    lk_npc     : in  addr_t;
    pred_taken : out std_logic;
    pred_tgt   : out addr_t;
    -- update (EX2)
    up_valid   : in  std_logic;       -- a conditional jump resolved this cycle
    up_npc     : in  addr_t;
    up_taken   : in  std_logic;
    up_tgt     : in  addr_t
  );
end entity btb;

architecture rtl of btb is
  constant IDX_W : natural := 3;
  subtype tag_t is std_logic_vector(C_ADDR_W - 1 downto IDX_W);
  type tag_arr_t is array (0 to 2 ** IDX_W - 1) of tag_t;
  type tgt_arr_t is array (0 to 2 ** IDX_W - 1) of addr_t;
  type ctr_arr_t is array (0 to 2 ** IDX_W - 1) of unsigned(1 downto 0);

  signal vld  : std_logic_vector(0 to 2 ** IDX_W - 1);
  signal tags : tag_arr_t;
  signal tgts : tgt_arr_t;
  signal ctrs : ctr_arr_t;
  signal li, ui : integer range 0 to 2 ** IDX_W - 1;
begin
  li <= to_integer(unsigned(lk_npc(IDX_W - 1 downto 0)));
  ui <= to_integer(unsigned(up_npc(IDX_W - 1 downto 0)));

  pred_taken <= '1' when vld(li) = '1' and tags(li) = lk_npc(C_ADDR_W - 1 downto IDX_W)
                         and ctrs(li)(1) = '1' else '0';
  pred_tgt   <= tgts(li);

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        vld  <= (others => '0');
        tags <= (others => (others => '0'));
        tgts <= (others => (others => '0'));
        ctrs <= (others => "00");
      elsif up_valid = '1' then
        if vld(ui) = '1' and tags(ui) = up_npc(C_ADDR_W - 1 downto IDX_W) then
          tgts(ui) <= up_tgt;
          if up_taken = '1' and ctrs(ui) /= "11" then
            ctrs(ui) <= ctrs(ui) + 1;
          elsif up_taken = '0' and ctrs(ui) /= "00" then
            ctrs(ui) <= ctrs(ui) - 1;
          end if;
        elsif up_taken = '1' then
          vld(ui)  <= '1';
          tags(ui) <= up_npc(C_ADDR_W - 1 downto IDX_W);
          tgts(ui) <= up_tgt;
          ctrs(ui) <= "10";
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
