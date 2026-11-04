-- ALU unit testbench: replays vectors generated from the golden model's alu()
-- (tests/test_rtl_units.py). Line format (fixed width, hex):
--   op(1) a(8) b(8) shamt(2) in(8) result(8) z n c zn_we c_we
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.archp_pkg.all;
use work.tb_util_pkg.all;

entity tb_alu is
  generic (G_VECTORS : string := "alu_vectors.txt");
end entity;

architecture sim of tb_alu is
  signal op                    : alu_op_t;
  signal a, b, in_port, result : word_t;
  signal shamt                 : std_logic_vector(4 downto 0);
  signal z, n, c, zn_we, c_we  : std_logic;
begin
  dut : entity work.alu
    port map (op => op, a => a, b => b, shamt => shamt, in_port => in_port,
              result => result, z => z, n => n, c => c, zn_we => zn_we, c_we => c_we);

  process
    file f        : text;
    variable st   : file_open_status;
    variable l    : line;
    variable s1   : string(1 to 1);
    variable s2   : string(1 to 2);
    variable s8   : string(1 to 8);
    variable sp   : character;
    variable e_res : word_t;
    variable e_z, e_n, e_c, e_zn, e_cw : std_logic;
    variable count, errors : integer := 0;
    function bit_of(s : string) return std_logic is
    begin
      if s(1) = '1' then return '1'; else return '0'; end if;
    end function;
  begin
    file_open(st, f, G_VECTORS, read_mode);
    assert st = open_ok report "cannot open vectors" severity failure;
    while not endfile(f) loop
      readline(f, l);
      read(l, s1); op <= hex_to_slv(s1, 4); read(l, sp);
      read(l, s8); a <= hex_to_slv(s8, 32); read(l, sp);
      read(l, s8); b <= hex_to_slv(s8, 32); read(l, sp);
      read(l, s2); shamt <= hex_to_slv(s2, 5); read(l, sp);
      read(l, s8); in_port <= hex_to_slv(s8, 32); read(l, sp);
      read(l, s8); e_res := hex_to_slv(s8, 32); read(l, sp);
      read(l, s1); e_z := bit_of(s1); read(l, sp);
      read(l, s1); e_n := bit_of(s1); read(l, sp);
      read(l, s1); e_c := bit_of(s1); read(l, sp);
      read(l, s1); e_zn := bit_of(s1); read(l, sp);
      read(l, s1); e_cw := bit_of(s1);
      wait for 1 ns;
      count := count + 1;
      if result /= e_res or z /= e_z or n /= e_n or zn_we /= e_zn or c_we /= e_cw
         or (e_cw = '1' and c /= e_c) then
        errors := errors + 1;
        report "ALU mismatch #" & integer'image(count) & " op=" & to_hex(op) & " a=" & to_hex(a)
          & " b=" & to_hex(b) & " got " & to_hex(result) & " z" & std_logic'image(z)
          & " n" & std_logic'image(n) & " c" & std_logic'image(c)
          & " expected " & to_hex(e_res) severity error;
      end if;
    end loop;
    file_close(f);
    report "TB_DONE vectors=" & integer'image(count) & " errors=" & integer'image(errors);
    wait;
  end process;
end architecture;
