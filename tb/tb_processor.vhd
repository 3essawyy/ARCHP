-- =============================================================================
-- tb_processor : system testbench (ADR-013)
--   * loads G_PROGRAM (.mem) into the memory, resets, runs
--   * IN.PORT: next value of G_INPUTS (hex, one per line) each time the core
--     consumes it (dbg_in_rd); 0 once the list is exhausted
--   * INTR.IN: one-cycle pulse at each cycle listed in G_INTR (decimal)
--   * keeps a shadow copy of memory (program + every write) for the dump
--   * stops when halted and the pipeline is empty (or after G_MAX_CYCLES)
--   * writes the architectural state, OUT log and interrupt log to G_DUMP
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.archp_pkg.all;
use work.tb_util_pkg.all;

entity tb_processor is
  generic (
    G_PROGRAM    : string  := "program.mem";
    G_INPUTS     : string  := "";
    G_INTR       : string  := "";
    G_DUMP       : string  := "dump.txt";
    G_MAX_CYCLES : integer := 20000;
    G_DYNAMIC_BP : boolean := false
  );
end entity;

architecture sim of tb_processor is
  constant T : time := 10 ns;

  signal clk      : std_logic := '0';
  signal rst      : std_logic := '1';
  signal intr     : std_logic := '0';
  signal in_port  : word_t := (others => '0');
  signal out_port : word_t;
  signal done     : boolean := false;

  signal dbg_regs                         : reg_array_t;
  signal dbg_pc, dbg_sp, dbg_halt_pc      : word_t;
  signal dbg_flags                        : std_logic_vector(3 downto 0);
  signal dbg_halted, dbg_idle, dbg_retire : std_logic;
  signal dbg_hwint, dbg_in_rd, dbg_out_we : std_logic;
  signal dbg_out_data, dbg_mem_din        : word_t;
  signal dbg_mem_we                       : std_logic;
  signal dbg_mem_addr                     : addr_t;

  type word_list_t is array (0 to 1023) of word_t;
  type int_list_t is array (0 to 1023) of integer;
  type mem_t is array (0 to 4095) of word_t;

  impure function load_words(fname : string; max : integer) return word_list_t is
    file f      : text;
    variable st : file_open_status;
    variable l  : line;
    variable r  : word_list_t := (others => (others => '0'));
    variable i  : integer := 0;
  begin
    if fname'length = 0 then return r; end if;
    file_open(st, f, fname, read_mode);
    assert st = open_ok report "cannot open " & fname severity failure;
    while not endfile(f) and i < max loop
      readline(f, l);
      if l'length > 0 and l(l'left) /= '/' and l(l'left) /= '#' then
        r(i) := hex_to_slv(l.all, 32);
        i := i + 1;
      end if;
      deallocate(l);
    end loop;
    file_close(f);
    return r;
  end function;

  impure function count_lines(fname : string) return integer is
    file f      : text;
    variable st : file_open_status;
    variable l  : line;
    variable i  : integer := 0;
  begin
    if fname'length = 0 then return 0; end if;
    file_open(st, f, fname, read_mode);
    if st /= open_ok then return 0; end if;
    while not endfile(f) loop
      readline(f, l);
      if l'length > 0 and l(l'left) /= '/' and l(l'left) /= '#' then i := i + 1; end if;
      deallocate(l);
    end loop;
    file_close(f);
    return i;
  end function;

  impure function load_ints(fname : string) return int_list_t is
    file f      : text;
    variable st : file_open_status;
    variable l  : line;
    variable r  : int_list_t := (others => -1);
    variable i  : integer := 0;
    variable v  : integer;
  begin
    if fname'length = 0 then return r; end if;
    file_open(st, f, fname, read_mode);
    assert st = open_ok report "cannot open " & fname severity failure;
    while not endfile(f) and i < 1023 loop
      readline(f, l);
      if l'length > 0 then
        read(l, v);
        r(i) := v;
        i := i + 1;
      end if;
      deallocate(l);
    end loop;
    file_close(f);
    return r;
  end function;

  constant INPUTS  : word_list_t := load_words(G_INPUTS, 1024);
  constant N_IN    : integer := count_lines(G_INPUTS);
  constant INTRS   : int_list_t := load_ints(G_INTR);
begin
  clk <= not clk after T / 2 when not done else '0';

  dut : entity work.processor_core
    generic map (G_INIT_FILE => G_PROGRAM, G_DYNAMIC_BP => G_DYNAMIC_BP)
    port map (clk => clk, rst => rst, intr => intr, in_port => in_port, out_port => out_port,
              dbg_regs => dbg_regs, dbg_pc => dbg_pc, dbg_sp => dbg_sp, dbg_flags => dbg_flags,
              dbg_halted => dbg_halted, dbg_halt_pc => dbg_halt_pc, dbg_idle => dbg_idle,
              dbg_retire => dbg_retire, dbg_hwint => dbg_hwint, dbg_in_rd => dbg_in_rd,
              dbg_out_we => dbg_out_we, dbg_out_data => dbg_out_data, dbg_mem_we => dbg_mem_we,
              dbg_mem_addr => dbg_mem_addr, dbg_mem_din => dbg_mem_din);

  process
    variable mem      : mem_t;
    variable prog     : word_list_t;
    variable cycle    : integer := 0;
    variable retired  : integer := 0;
    variable in_idx   : integer := 0;
    variable intr_idx : integer := 0;
    variable outs     : word_list_t;
    variable n_out    : integer := 0;
    variable ints     : int_list_t;
    variable n_int    : integer := 0;
    variable status   : string(1 to 7) := "TIMEOUT";
    file     f        : text;
    variable st       : file_open_status;
    variable l        : line;
    -- shadow memory: same file format as unified_memory (one word per line)
    procedure load_mem is
      file pf      : text;
      variable ps  : file_open_status;
      variable pl  : line;
      variable a   : integer := 0;
    begin
      mem := (others => (others => '0'));
      file_open(ps, pf, G_PROGRAM, read_mode);
      assert ps = open_ok report "cannot open " & G_PROGRAM severity failure;
      while not endfile(pf) and a < 4096 loop
        readline(pf, pl);
        if pl'length > 0 and pl(pl'left) /= '/' and pl(pl'left) /= '#' then
          if pl(pl'left) = '@' then
            a := to_integer(unsigned(hex_to_slv(pl.all, 12)));
          else
            mem(a) := hex_to_slv(pl.all, 32);
            a := a + 1;
          end if;
        end if;
        deallocate(pl);
      end loop;
      file_close(pf);
    end procedure;
  begin
    load_mem;
    if N_IN > 0 then in_port <= INPUTS(0); end if;
    rst <= '1';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait for 1 ns;
    rst <= '0';
    loop
      wait until rising_edge(clk);
      cycle := cycle + 1;
      -- observe the cycle that just ended
      if dbg_mem_we = '1' then
        mem(to_integer(unsigned(dbg_mem_addr))) := dbg_mem_din;
      end if;
      if dbg_hwint = '1' then
        ints(n_int) := retired;
        n_int := n_int + 1;
      end if;
      if dbg_retire = '1' then
        retired := retired + 1;
      end if;
      if dbg_out_we = '1' then
        outs(n_out) := dbg_out_data;
        n_out := n_out + 1;
      end if;
      if dbg_in_rd = '1' then
        in_idx := in_idx + 1;
        if in_idx < N_IN then
          in_port <= INPUTS(in_idx);
        else
          in_port <= (others => '0');
        end if;
      end if;
      -- drive INTR for the next cycle
      if INTRS(intr_idx) = cycle then
        intr <= '1';
        intr_idx := intr_idx + 1;
      else
        intr <= '0';
      end if;
      if dbg_halted = '1' and dbg_idle = '1' then
        status := "HALTED ";
        exit;
      end if;
      exit when cycle >= G_MAX_CYCLES;
    end loop;

    file_open(st, f, G_DUMP, write_mode);
    write(l, string'("STATUS ")); write(l, status); writeline(f, l);
    write(l, string'("CYCLES ")); write(l, cycle); writeline(f, l);
    write(l, string'("RETIRED ")); write(l, retired); writeline(f, l);
    write(l, string'("PC ")); write(l, to_hex(dbg_halt_pc(11 downto 0))); writeline(f, l);
    write(l, string'("SP ")); write(l, to_hex(dbg_sp(11 downto 0))); writeline(f, l);
    write(l, string'("FLAGS ")); write(l, to_hex(dbg_flags)); writeline(f, l);
    for i in 0 to 7 loop
      write(l, string'("R")); write(l, i); write(l, string'(" "));
      write(l, to_hex(dbg_regs(i))); writeline(f, l);
    end loop;
    for i in 0 to n_out - 1 loop
      write(l, string'("OUT ")); write(l, to_hex(outs(i))); writeline(f, l);
    end loop;
    for i in 0 to n_int - 1 loop
      write(l, string'("INT ")); write(l, ints(i)); writeline(f, l);
    end loop;
    for a in 0 to 4095 loop
      if mem(a) /= C_ZERO_WORD then
        write(l, string'("M ")); write(l, to_hex(std_logic_vector(to_unsigned(a, 12))));
        write(l, string'(" ")); write(l, to_hex(mem(a))); writeline(f, l);
      end if;
    end loop;
    file_close(f);
    report "TB_DONE " & status & " cycles=" & integer'image(cycle);
    done <= true;
    wait;
  end process;
end architecture;
