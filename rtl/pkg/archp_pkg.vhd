-- =============================================================================
-- archp_pkg : constants, opcodes, control word and pipeline-register records
-- ARCHP six-stage pipelined processor (CMPS 301, Fall 2026)
-- VHDL-93 (Quartus Prime 16.1 default, ADR-002)
-- Encoding: HLD section 3 / ADR-003. Keep in sync with src/archp/isa.py.
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package archp_pkg is

  -- ---------------------------------------------------------------- widths
  constant C_ADDR_W : natural := 12;                       -- 4K words (ADR-009)
  subtype word_t     is std_logic_vector(31 downto 0);
  subtype addr_t     is std_logic_vector(C_ADDR_W - 1 downto 0);
  subtype reg_addr_t is std_logic_vector(2 downto 0);
  subtype opcode_t   is std_logic_vector(4 downto 0);
  subtype imm_t      is std_logic_vector(15 downto 0);

  constant C_ZERO_WORD : word_t := (others => '0');
  constant C_SP_RESET  : addr_t := (others => '1');       -- SP = 2^12 - 1

  -- ADR-006: SUB/CMP carry = unsigned borrow (A < B). One switch, mirrored by
  -- archp.golden.SUB_CARRY_IS_BORROW.
  constant C_SUB_CARRY_IS_BORROW : boolean := true;

  -- ---------------------------------------------------------------- opcodes
  constant OP_NOP  : opcode_t := "00000";
  constant OP_HLT  : opcode_t := "00001";
  constant OP_SETC : opcode_t := "00010";
  constant OP_NOT  : opcode_t := "00011";
  constant OP_INC  : opcode_t := "00100";
  constant OP_OUT  : opcode_t := "00101";
  constant OP_IN   : opcode_t := "00110";
  constant OP_MOV  : opcode_t := "00111";
  constant OP_SWAP : opcode_t := "01000";
  constant OP_ADD  : opcode_t := "01001";
  constant OP_SUB  : opcode_t := "01010";
  constant OP_AND  : opcode_t := "01011";
  constant OP_IADD : opcode_t := "01100";
  constant OP_CMP  : opcode_t := "01101";
  constant OP_SHR  : opcode_t := "01110";
  constant OP_SHL  : opcode_t := "01111";
  constant OP_PUSH : opcode_t := "10000";
  constant OP_POP  : opcode_t := "10001";
  constant OP_LDM  : opcode_t := "10010";
  constant OP_LDD  : opcode_t := "10011";
  constant OP_STD  : opcode_t := "10100";
  constant OP_JZ   : opcode_t := "10101";
  constant OP_JN   : opcode_t := "10110";
  constant OP_JC   : opcode_t := "10111";
  constant OP_JMP  : opcode_t := "11000";
  constant OP_CALL : opcode_t := "11001";
  constant OP_RET  : opcode_t := "11010";
  constant OP_INT  : opcode_t := "11011";
  constant OP_RTI  : opcode_t := "11100";

  -- ---------------------------------------------------------------- ALU ops
  subtype alu_op_t is std_logic_vector(3 downto 0);
  constant ALU_ADD   : alu_op_t := "0000";  -- A + B          (ADD, IADD, LDD/STD address)
  constant ALU_SUB   : alu_op_t := "0001";  -- A - B          (SUB, CMP)
  constant ALU_AND   : alu_op_t := "0010";
  constant ALU_NOT   : alu_op_t := "0011";
  constant ALU_INC   : alu_op_t := "0100";  -- A + 1
  constant ALU_PASSA : alu_op_t := "0101";  -- MOV, OUT, SWAP uop1
  constant ALU_PASSB : alu_op_t := "0110";  -- LDM, SWAP uop2, vector address
  constant ALU_SHL   : alu_op_t := "0111";
  constant ALU_SHR   : alu_op_t := "1000";
  constant ALU_IN    : alu_op_t := "1001";  -- IN.PORT
  constant ALU_SETC  : alu_op_t := "1010";

  -- ---------------------------------------------------------------- small enums
  subtype stack_t is std_logic_vector(1 downto 0);
  constant STK_NONE : stack_t := "00";
  constant STK_PUSH : stack_t := "01";      -- addr = SP,   SP <- SP - 1
  constant STK_POP  : stack_t := "10";      -- SP <- SP + 1, addr = SP + 1

  subtype wsel_t is std_logic_vector(1 downto 0);  -- store-data select (EX2)
  constant WSEL_B   : wsel_t := "00";       -- PUSH / STD data register
  constant WSEL_RET : wsel_t := "01";       -- CALL: return PC
  constant WSEL_CTX : wsel_t := "10";       -- INT / interrupt: {C N Z, return PC}

  subtype br_t is std_logic_vector(1 downto 0);    -- = opcode(1:0) of JZ/JN/JC
  constant BR_NONE : br_t := "00";
  constant BR_Z    : br_t := "01";
  constant BR_N    : br_t := "10";
  constant BR_C    : br_t := "11";

  -- ---------------------------------------------------------------- control word
  -- Produced by the control unit in ID and carried down the pipeline; each stage
  -- uses its own fields (unused flip-flops are removed by synthesis).
  type ctrl_t is record
    valid    : std_logic;   -- micro-op present (0 = bubble)
    retire   : std_logic;   -- last micro-op of an architectural instruction
    reg_we   : std_logic;   -- write register file in WB
    rd       : reg_addr_t;  -- destination register
    wb_mem   : std_logic;   -- WB data comes from memory (LDD, POP)
    alu_op   : alu_op_t;
    b_imm    : std_logic;   -- ALU B input = extended immediate
    imm_sext : std_logic;   -- 1 = sign-extend imm, 0 = zero-extend
    flags_we : std_logic;   -- allow the ALU to update CCR
    is_out   : std_logic;   -- OUT.PORT <- data in WB
    mem_rd   : std_logic;
    mem_wr   : std_logic;
    stack    : stack_t;
    wsel     : wsel_t;
    br       : br_t;        -- conditional jump on Z / N / C
    pc_load  : std_logic;   -- WB: PC <- memory data (RET, RTI, vectors)
    rti      : std_logic;   -- WB: CCR <- memory data(31:29)
    swap2    : std_logic;   -- SWAP second micro-op: no forwarding from EX2
    hwint    : std_logic;   -- hardware-interrupt push micro-op
    pred     : std_logic;   -- predicted taken (dynamic predictor, bonus)
  end record;

  constant C_CTRL_NOP : ctrl_t := (
    valid => '0', retire => '0', reg_we => '0', rd => "000", wb_mem => '0',
    alu_op => ALU_PASSA, b_imm => '0', imm_sext => '0', flags_we => '0',
    is_out => '0', mem_rd => '0', mem_wr => '0', stack => STK_NONE,
    wsel => WSEL_B, br => BR_NONE, pc_load => '0', rti => '0', swap2 => '0',
    hwint => '0', pred => '0');

  -- ---------------------------------------------------------------- pipeline registers
  type id_ex1_t is record
    ctrl   : ctrl_t;
    ra     : reg_addr_t;    -- source registers: read in EX1 + forwarding (ADR-015)
    rb     : reg_addr_t;
    imm    : imm_t;
    ret_pc : addr_t;        -- return / fall-through PC
  end record;

  type ex1_ex2_t is record
    ctrl   : ctrl_t;
    result : word_t;        -- ALU result (also LDD/STD effective address)
    b      : word_t;        -- forwarded B (store data)
    target : addr_t;        -- jump target = imm(11:0)
    ret_pc : addr_t;
  end record;

  type ex2_mem_t is record
    ctrl : ctrl_t;
    addr : addr_t;          -- memory address
    data : word_t;          -- store data (mem_wr) or ALU result
  end record;

  type mem_wb_t is record
    ctrl : ctrl_t;
    data : word_t;          -- ALU result (memory read data comes from the RAM)
  end record;

  constant C_ID_EX1_NOP  : id_ex1_t  := (C_CTRL_NOP, "000", "000", (others => '0'),
                                         (others => '0'));
  constant C_EX1_EX2_NOP : ex1_ex2_t := (C_CTRL_NOP, C_ZERO_WORD, C_ZERO_WORD,
                                         (others => '0'), (others => '0'));
  constant C_EX2_MEM_NOP : ex2_mem_t := (C_CTRL_NOP, (others => '0'), C_ZERO_WORD);
  constant C_MEM_WB_NOP  : mem_wb_t  := (C_CTRL_NOP, C_ZERO_WORD);

  type reg_array_t is array (0 to 7) of word_t;

end package archp_pkg;
