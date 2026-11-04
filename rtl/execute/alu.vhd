-- =============================================================================
-- alu : 32-bit ALU of Execute-1 (combinational)
-- One shared 34-bit adder serves ADD/IADD/address (A+B), SUB/CMP (A+~B+1) and
-- INC (A+0+1). Flags and their write enables follow ADR-006.
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archp_pkg.all;

entity alu is
  port (
    op      : in  alu_op_t;
    a       : in  word_t;
    b       : in  word_t;                       -- register B or extended immediate
    shamt   : in  std_logic_vector(4 downto 0); -- imm(4:0) for SHL/SHR
    in_port : in  word_t;                       -- IN.PORT for ALU_IN
    result  : out word_t;
    z       : out std_logic;
    n       : out std_logic;
    c       : out std_logic;
    zn_we   : out std_logic;                    -- operation defines Z,N
    c_we    : out std_logic                     -- operation defines C
  );
end entity alu;

architecture rtl of alu is
  signal bx    : word_t;
  signal cin   : std_logic;
  signal sum   : unsigned(33 downto 0);         -- '0'&a&'1' + '0'&bx&cin
  signal cout  : std_logic;
  signal shl_v : unsigned(32 downto 0);         -- bit 32 = last bit shifted out
  signal shr_v : unsigned(31 downto 0);
  signal res   : word_t;
begin
  -- adder operand select: ADD (B, 0), SUB (~B, 1), INC (0, 1)
  bx  <= not b when op = ALU_SUB else
         (others => '0') when op = ALU_INC else
         b;
  cin <= '1' when op = ALU_SUB or op = ALU_INC else '0';

  -- carry-in folded in as an extra LSB so a single adder is inferred
  sum  <= unsigned('0' & a & '1') + unsigned('0' & bx & cin);
  cout <= sum(33);

  shl_v <= shift_left(unsigned('0' & a), to_integer(unsigned(shamt)));
  shr_v <= shift_right(unsigned(a), to_integer(unsigned(shamt)));

  with op select res <=
    std_logic_vector(sum(32 downto 1)) when ALU_ADD | ALU_SUB | ALU_INC,
    a and b                            when ALU_AND,
    not a                              when ALU_NOT,
    b                                  when ALU_PASSB,
    std_logic_vector(shl_v(31 downto 0)) when ALU_SHL,
    std_logic_vector(shr_v)            when ALU_SHR,
    in_port                            when ALU_IN,
    a                                  when others;   -- PASSA, SETC

  result <= res;
  z      <= '1' when res = C_ZERO_WORD else '0';
  n      <= res(31);

  -- carry: adder carry-out; SUB/CMP borrow = not carry-out (ADR-006); SHL last bit out
  c <= '1'           when op = ALU_SETC else
       shl_v(32)     when op = ALU_SHL else
       not cout      when op = ALU_SUB and C_SUB_CARRY_IS_BORROW else
       cout;

  with op select zn_we <=
    '1' when ALU_ADD | ALU_SUB | ALU_INC | ALU_AND | ALU_NOT | ALU_SHL | ALU_SHR,
    '0' when others;

  c_we <= '1' when op = ALU_ADD or op = ALU_SUB or op = ALU_INC or op = ALU_SETC else
          '1' when op = ALU_SHL and shamt /= "00000" else
          '0';
end architecture rtl;
