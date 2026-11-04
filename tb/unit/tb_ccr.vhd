-- CCR unit testbench: reset, EX1 updates, EX2 clear, younger EX1 wins, RTI restore.
library ieee;
use ieee.std_logic_1164.all;
use work.archp_pkg.all;

entity tb_ccr is
end entity;

architecture sim of tb_ccr is
  signal clk, rst                         : std_logic := '0';
  signal zn_we, c_we, z, n, c, rti        : std_logic := '0';
  signal clr                              : br_t := BR_NONE;
  signal wbf, flags                       : std_logic_vector(2 downto 0) := "000";
  signal done                             : boolean := false;
begin
  clk <= not clk after 5 ns when not done else '0';
  dut : entity work.ccr
    port map (clk => clk, rst => rst, ex1_zn_we => zn_we, ex1_c_we => c_we, ex1_z => z,
              ex1_n => n, ex1_c => c, ex2_clr => clr, wb_rti => rti, wb_flags => wbf,
              flags => flags);
  process
    procedure tick is
    begin
      wait until falling_edge(clk);
    end procedure;
  begin
    rst <= '1'; tick; rst <= '0';
    assert flags = "000" report "reset" severity error;
    zn_we <= '1'; c_we <= '1'; z <= '1'; n <= '1'; c <= '1'; tick;
    assert flags = "111" report "ex1 write" severity error;
    zn_we <= '0'; c_we <= '0'; clr <= BR_N; tick;
    assert flags = "101" report "ex2 clear N" severity error;
    -- same cycle: EX2 clears Z, EX1 (younger) writes Z=1 -> Z stays 1; C kept
    clr <= BR_Z; zn_we <= '1'; z <= '1'; n <= '0'; tick;
    assert flags = "101" report "younger EX1 must win" severity error;
    -- EX2 clears C while EX1 only writes Z,N -> C cleared
    clr <= BR_C; zn_we <= '1'; z <= '0'; n <= '1'; tick;
    assert flags = "010" report "clear C with zn write" severity error;
    clr <= BR_NONE; zn_we <= '0';
    rti <= '1'; wbf <= "101"; tick; rti <= '0';
    assert flags = "101" report "rti restore" severity error;
    c_we <= '1'; c <= '0'; tick; c_we <= '0';
    assert flags = "001" report "c only" severity error;
    report "TB_DONE";
    done <= true;
    wait;
  end process;
end architecture;
