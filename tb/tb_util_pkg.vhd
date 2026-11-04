-- Testbench helpers (VHDL-93): hex <-> std_logic_vector without std_logic_textio.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package tb_util_pkg is
  function hex_to_slv(s : string; bits : natural) return std_logic_vector;
  function to_hex(v : std_logic_vector) return string;
  function hex_digit(c : character) return integer;
end package;

package body tb_util_pkg is
  function hex_digit(c : character) return integer is
  begin
    if c >= '0' and c <= '9' then return character'pos(c) - character'pos('0');
    elsif c >= 'A' and c <= 'F' then return character'pos(c) - character'pos('A') + 10;
    elsif c >= 'a' and c <= 'f' then return character'pos(c) - character'pos('a') + 10;
    else return -1;
    end if;
  end function;

  function hex_to_slv(s : string; bits : natural) return std_logic_vector is
    variable w : unsigned(bits + 3 downto 0) := (others => '0');
    variable d : integer;
  begin
    for i in s'range loop
      d := hex_digit(s(i));
      if d >= 0 then
        w := shift_left(w, 4) or to_unsigned(d, bits + 4);
      end if;
    end loop;
    return std_logic_vector(w(bits - 1 downto 0));
  end function;

  function to_hex(v : std_logic_vector) return string is
    constant n   : natural := (v'length + 3) / 4;
    variable x   : unsigned(n * 4 - 1 downto 0) := (others => '0');
    variable s   : string(1 to n);
    constant hex : string(1 to 16) := "0123456789ABCDEF";
    variable d   : integer;
  begin
    x(v'length - 1 downto 0) := unsigned(v);
    for i in 0 to n - 1 loop
      if is_x(std_logic_vector(x(i * 4 + 3 downto i * 4))) then
        s(n - i) := 'X';
      else
        d := to_integer(x(i * 4 + 3 downto i * 4));
        s(n - i) := hex(d + 1);
      end if;
    end loop;
    return s;
  end function;
end package body;
