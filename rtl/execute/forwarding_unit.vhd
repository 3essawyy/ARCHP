-- =============================================================================
-- forwarding_unit : operand selection for EX1 (data hazards, HLD 6.2)
--   Sources, youngest first: EX2 (ALU result), MEM (ALU result), WB (ALU
--   result or memory data). Loads in EX2/MEM have no data yet; the decode HDU
--   guarantees no consumer is in EX1 then.
--   SWAP uop2 must NOT take uop1's result from EX2 (ADR-008).
--   sel: "00" register file, "01" EX2, "10" MEM, "11" WB
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use work.archp_pkg.all;

entity forwarding_unit is
  port (
    ra, rb    : in  reg_addr_t;   -- sources of the instruction in EX1
    swap2     : in  std_logic;    -- instruction in EX1 is SWAP uop2
    ex2_ctrl  : in  ctrl_t;
    mem_ctrl  : in  ctrl_t;
    wb_ctrl   : in  ctrl_t;
    sel_a     : out std_logic_vector(1 downto 0);
    sel_b     : out std_logic_vector(1 downto 0)
  );
end entity forwarding_unit;

architecture rtl of forwarding_unit is
  function writes(c : ctrl_t; r : reg_addr_t) return boolean is
  begin
    return c.valid = '1' and c.reg_we = '1' and c.rd = r;
  end function;

  function pick(r : reg_addr_t; sw : std_logic; e2, m, w : ctrl_t)
    return std_logic_vector is
  begin
    if writes(e2, r) and e2.wb_mem = '0' and sw = '0' then
      return "01";
    elsif writes(m, r) and m.wb_mem = '0' then
      return "10";
    elsif writes(w, r) then
      return "11";
    end if;
    return "00";
  end function;
begin
  sel_a <= pick(ra, swap2, ex2_ctrl, mem_ctrl, wb_ctrl);
  sel_b <= pick(rb, swap2, ex2_ctrl, mem_ctrl, wb_ctrl);
end architecture rtl;
