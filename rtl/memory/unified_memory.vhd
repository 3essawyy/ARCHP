-- =============================================================================
-- unified_memory : the single Von-Neumann memory, 4096 x 32, single port,
-- synchronous read (data appears one clock after the address), ADR-004.
-- Coded in Intel's single-port RAM inference style (registered address) so
-- Quartus maps it onto M10K blocks (16 x M10K, 131072 bits).
-- Simulation initialisation: G_INIT_FILE = text file with one 32-bit hex word
-- per line, address 0 first (archp asm .mem output). Lines starting with '/'
-- or '#' and empty lines are skipped; '@hex' sets the next address.
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- synthesis translate_off
use std.textio.all;
-- synthesis translate_on
use work.archp_pkg.all;

entity unified_memory is
  generic (
    G_INIT_FILE : string := ""
  );
  port (
    clk  : in  std_logic;
    we   : in  std_logic;
    addr : in  addr_t;
    din  : in  word_t;
    dout : out word_t
  );
end entity unified_memory;

architecture rtl of unified_memory is
  type ram_t is array (0 to 2 ** C_ADDR_W - 1) of word_t;

  impure function init_ram(fname : string) return ram_t is
    variable r    : ram_t := (others => (others => '0'));
    -- synthesis translate_off
    file     f    : text;
    variable st   : file_open_status;
    variable l    : line;
    variable ch   : character;
    variable w    : unsigned(31 downto 0);
    variable nib  : integer;
    variable waddr : integer := 0;
    variable at   : boolean;
    variable got  : boolean;
    -- synthesis translate_on
  begin
    -- synthesis translate_off
    if fname'length > 0 then
      file_open(st, f, fname, read_mode);
      assert st = open_ok report "unified_memory: cannot open " & fname severity failure;
      while not endfile(f) loop
        readline(f, l);
        w   := (others => '0');
        at  := false;
        got := false;
        for i in 1 to l'length loop
          ch := l(i);
          exit when ch = '/' or ch = '#';
          nib := -1;
          if ch >= '0' and ch <= '9' then
            nib := character'pos(ch) - character'pos('0');
          elsif ch >= 'A' and ch <= 'F' then
            nib := character'pos(ch) - character'pos('A') + 10;
          elsif ch >= 'a' and ch <= 'f' then
            nib := character'pos(ch) - character'pos('a') + 10;
          elsif ch = '@' then
            at := true;
          end if;
          if nib >= 0 then
            w   := shift_left(w, 4) or to_unsigned(nib, 32);
            got := true;
          end if;
        end loop;
        if at then
          waddr := to_integer(w(C_ADDR_W - 1 downto 0));
        elsif got and waddr < 2 ** C_ADDR_W then
          r(waddr) := std_logic_vector(w);
          waddr   := waddr + 1;
        end if;
        deallocate(l);
      end loop;
      file_close(f);
    end if;
    -- synthesis translate_on
    return r;
  end function;

  signal ram      : ram_t := init_ram(G_INIT_FILE);
  signal addr_reg : addr_t := (others => '0');
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if we = '1' then
        ram(to_integer(unsigned(addr))) <= din;
      end if;
      addr_reg <= addr;
    end if;
  end process;

  dout <= ram(to_integer(unsigned(addr_reg)));
end architecture rtl;
