library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity test_env is
  Port (
    clk       : in  STD_LOGIC;
    btn_enable: in  STD_LOGIC;
    btn_reset : in  STD_LOGIC;
    sw        : in  STD_LOGIC_VECTOR(7 downto 0);
    cathodes  : out STD_LOGIC_VECTOR(6 downto 0);
    anodes    : out STD_LOGIC_VECTOR(3 downto 0);
    leds      : out STD_LOGIC_VECTOR(7 downto 0)
  );
end entity;

architecture Behavioral of test_env is

  -- Enable signal for pipeline registers and components
  signal enable_MPG : std_logic;

  -- IF stage outputs
  signal instr_IF       : std_logic_vector(15 downto 0);
  signal PCPlus1_IF     : std_logic_vector(15 downto 0);
  signal instr_next_IF  : std_logic_vector(15 downto 0);
  signal branchTargetAddress_EX : std_logic_vector(15 downto 0);
  signal jumpTargetAddress   : std_logic_vector(15 downto 0);
  signal jumpCtrl       : std_logic;
  signal PCSrc          : std_logic;

  -- IF/ID pipeline registers
  signal IF_ID_instr    : std_logic_vector(15 downto 0);
  signal IF_ID_PCPlus1  : std_logic_vector(15 downto 0);

  -- ID stage outputs
  signal rd1_ID         : std_logic_vector(15 downto 0);
  signal rd2_ID         : std_logic_vector(15 downto 0);
  signal ext_imm_ID     : std_logic_vector(15 downto 0);
  signal func_ID        : std_logic_vector(2 downto 0);
  signal shamt_ID       : std_logic;
  signal rt_ID          : std_logic_vector(2 downto 0);
  signal rd_ID          : std_logic_vector(2 downto 0);

  -- Control signals from Control Unit at ID
  signal RegDst_ID      : std_logic;
  signal RegWrite_ID    : std_logic;
  signal ALUSrc_ID      : std_logic;
  signal ExtOp_ID       : std_logic;
  signal MemRead_ID     : std_logic;
  signal MemWrite_ID    : std_logic;
  signal MemtoReg_ID    : std_logic;
  signal ALUOp_ID       : std_logic_vector(1 downto 0);
  signal jump_ID        : std_logic;

  -- ID/EX pipeline registers
  signal ID_EX_rd1          : std_logic_vector(15 downto 0);
  signal ID_EX_rd2          : std_logic_vector(15 downto 0);
  signal ID_EX_ext_imm      : std_logic_vector(15 downto 0);
  signal ID_EX_func         : std_logic_vector(2 downto 0);
  signal ID_EX_shamt        : std_logic;
  signal ID_EX_rt           : std_logic_vector(2 downto 0);
  signal ID_EX_rd           : std_logic_vector(2 downto 0);
  signal ID_EX_RegDst       : std_logic;
  signal ID_EX_RegWrite     : std_logic;
  signal ID_EX_ALUSrc       : std_logic;
  signal ID_EX_MemWrite     : std_logic;
  signal ID_EX_MemtoReg     : std_logic;
  signal ID_EX_ExtOp        : std_logic;
  signal ID_EX_ALUOp        : std_logic_vector(1 downto 0);
  signal ID_EX_PCPlus1      : std_logic_vector(15 downto 0);

  -- EX stage outputs
  signal ALURes_EX          : std_logic_vector(15 downto 0);
  signal Zero_EX            : std_logic;
  signal branchTargetAddress : std_logic_vector(15 downto 0);

  -- EX/MEM pipeline registers
  signal EX_MEM_ALURes      : std_logic_vector(15 downto 0);
  signal EX_MEM_rd2         : std_logic_vector(15 downto 0);
  signal EX_MEM_RegWrite    : std_logic;
  signal EX_MEM_MemWrite    : std_logic;
  signal EX_MEM_MemtoReg    : std_logic;
  signal EX_MEM_WriteReg    : std_logic_vector(2 downto 0);

  -- MEM stage outputs
  signal MemData_MEM        : std_logic_vector(15 downto 0);

  -- MEM/WB pipeline registers
  signal MEM_WB_MemData     : std_logic_vector(15 downto 0);
  signal MEM_WB_ALURes      : std_logic_vector(15 downto 0);
  signal MEM_WB_RegWrite    : std_logic;
  signal MEM_WB_MemtoReg    : std_logic;
  signal MEM_WB_WriteReg    : std_logic_vector(2 downto 0);

  -- WriteBack output
  signal WriteData          : std_logic_vector(15 downto 0);

  -- Debug vector for LEDs
  signal dbg_vector         : std_logic_vector(7 downto 0);

begin

  -- Multipulse Generator instance for enable control
  mpg_inst : entity work.mpg
    port map(
      btn    => btn_enable,
      clk    => clk,
      enable => enable_MPG
    );

  -- Instruction Fetch stage
  InstructionFetch_inst : entity work.InstructionFetch
    port map(
      clk                     => clk,
      reset                   => btn_reset,
      enable                  => enable_MPG,
      branchTargetAddress     => branchTargetAddress_EX,
      jumpTargetAddress       => jumpTargetAddress,
      jumpCtrl                => jump_ID,
      PCSrcCtrl               => PCSrc,
      instructionToBeExecuted => instr_IF,
      nextSequentialInstruction => PCPlus1_IF,
      nextInstruction         => instr_next_IF
    );

  -- Calculate jump target address
  jumpTargetAddress <= IF_ID_PCPlus1(15 downto 13) & IF_ID_instr(12 downto 0);

  -- IF/ID pipeline registers
  process(clk)
  begin
    if rising_edge(clk) then
      if btn_reset = '1' then
        IF_ID_instr <= (others => '0');
        IF_ID_PCPlus1 <= (others => '0');
      elsif enable_MPG = '1' then
        IF_ID_instr <= instr_IF;
        IF_ID_PCPlus1 <= PCPlus1_IF;
      end if;
    end if;
  end process;

  -- Main Control Unit
  MainControlUnit_inst : entity work.MainControlUnit
    port map(
      opcode    => IF_ID_instr(15 downto 13),
      func      => IF_ID_instr(2 downto 0),
      RegDst    => RegDst_ID,
      RegWrite  => RegWrite_ID,
      ALUSrc    => ALUSrc_ID,
      PCSrc     => PCSrc,
      MemRead   => MemRead_ID,
      MemWrite  => MemWrite_ID,
      MemtoReg  => MemtoReg_ID,
      ALUOp     => ALUOp_ID,
      jump      => jump_ID,
      ExtOp     => ExtOp_ID
    );

InstructionDecode_inst : entity work.InstructionDecode
    port map(
      clk        => clk,
      instr      => IF_ID_instr,
      write_data => WriteData,
      RegWrite   => MEM_WB_RegWrite,
      RegDst     => '0',         
      ExtOp      => ExtOp_ID,
      rd1        => rd1_ID,
      rd2        => rd2_ID,
      ext_imm    => ext_imm_ID,
      func       => func_ID,
      shamt      => shamt_ID,
      rs         => open,
      rt         => rt_ID,
      rd         => rd_ID
    );


  -- ID/EX pipeline registers
  process(clk)
  begin
    if rising_edge(clk) then
      if btn_reset = '1' then
        ID_EX_rd1       <= (others => '0');
        ID_EX_rd2       <= (others => '0');
        ID_EX_ext_imm   <= (others => '0');
        ID_EX_func      <= (others => '0');
        ID_EX_shamt     <= '0';
        ID_EX_rt        <= (others => '0');
        ID_EX_rd        <= (others => '0');
        ID_EX_RegDst    <= '0';
        ID_EX_RegWrite  <= '0';
        ID_EX_ALUSrc    <= '0';
        ID_EX_MemWrite  <= '0';
        ID_EX_MemtoReg  <= '0';
        ID_EX_ExtOp     <= '0';
        ID_EX_ALUOp     <= (others => '0');
        ID_EX_PCPlus1   <= (others => '0');
      elsif enable_MPG = '1' then
        ID_EX_rd1       <= rd1_ID;
        ID_EX_rd2       <= rd2_ID;
        ID_EX_ext_imm   <= ext_imm_ID;
        ID_EX_func      <= func_ID;
        ID_EX_shamt     <= shamt_ID;
        ID_EX_rt        <= rt_ID;
        ID_EX_rd        <= rd_ID;
        ID_EX_RegDst    <= RegDst_ID;
        ID_EX_RegWrite  <= RegWrite_ID;
        ID_EX_ALUSrc    <= ALUSrc_ID;
        ID_EX_MemWrite  <= MemWrite_ID;
        ID_EX_MemtoReg  <= MemtoReg_ID;
        ID_EX_ExtOp     <= ExtOp_ID;
        ID_EX_ALUOp     <= ALUOp_ID;
        ID_EX_PCPlus1   <= IF_ID_PCPlus1;
      end if;
    end if;
  end process;

  -- Execution Unit
  ExecutionUnit_inst : entity work.ExecutionUnit
    port map(
      PCPlus1               => ID_EX_PCPlus1,
      rd1                   => ID_EX_rd1,
      rd2                   => ID_EX_rd2,
      ext_imm               => ID_EX_ext_imm,
      func                  => ID_EX_func,
      shamt                 => ID_EX_shamt,
      ALUSrc                => ID_EX_ALUSrc,
      ALUOp                 => ID_EX_ALUOp,
      branch_target_address => branchTargetAddress,
      ALURes                => ALURes_EX,
      Zero                  => Zero_EX
    );

  -- EX/MEM pipeline registers
  process(clk)
  begin
    if rising_edge(clk) then
      if btn_reset = '1' then
        EX_MEM_ALURes     <= (others => '0');
        EX_MEM_rd2        <= (others => '0');
        EX_MEM_RegWrite   <= '0';
        EX_MEM_MemWrite   <= '0';
        EX_MEM_MemtoReg   <= '0';
        EX_MEM_WriteReg   <= (others => '0');
      elsif enable_MPG = '1' then
        EX_MEM_ALURes     <= ALURes_EX;
        EX_MEM_rd2        <= ID_EX_rd2;
        EX_MEM_RegWrite   <= ID_EX_RegWrite;
        EX_MEM_MemWrite   <= ID_EX_MemWrite;
        EX_MEM_MemtoReg   <= ID_EX_MemtoReg;
        if ID_EX_RegDst = '1' then
          EX_MEM_WriteReg <= ID_EX_rd;
        else
          EX_MEM_WriteReg <= ID_EX_rt;
        end if;
      end if;
    end if;
  end process;

  -- Memory Unit
  MemoryUnit_inst : entity work.MemoryUnit
    port map(
      clk        => clk,
      MemWrite   => EX_MEM_MemWrite,
      ALURes     => EX_MEM_ALURes,
      RD2        => EX_MEM_rd2,
      MemData    => MemData_MEM,
      ALURes_out => open
    );

  -- MEM/WB pipeline registers
  process(clk)
  begin
    if rising_edge(clk) then
      if btn_reset = '1' then
        MEM_WB_MemData    <= (others => '0');
        MEM_WB_ALURes     <= (others => '0');
        MEM_WB_RegWrite   <= '0';
        MEM_WB_MemtoReg   <= '0';
        MEM_WB_WriteReg   <= (others => '0');
      elsif enable_MPG = '1' then
        MEM_WB_MemData    <= MemData_MEM;
        MEM_WB_ALURes     <= EX_MEM_ALURes;
        MEM_WB_RegWrite   <= EX_MEM_RegWrite;
        MEM_WB_MemtoReg   <= EX_MEM_MemtoReg;
        MEM_WB_WriteReg   <= EX_MEM_WriteReg;
      end if;
    end if;
  end process;

  -- WriteBack stage
  WriteBack_inst : entity work.WriteBack
    port map(
      MemtoReg  => MEM_WB_MemtoReg,
      ALURes    => MEM_WB_ALURes,
      MemData   => MEM_WB_MemData,
      WriteData => WriteData
    );

  -- SevenSegmentDisplay for debug and output
  SevenSegmentDisplay_inst : entity work.SevenSegmentDisplay
    port map(
      clk         => clk,
      sw          => sw,
      instr       => IF_ID_instr,
      pc_plus1    => IF_ID_PCPlus1,
      rd1         => ID_EX_rd1,
      rd2         => ID_EX_rd2,
      ext_imm     => ID_EX_ext_imm,
      alu_res     => ALURes_EX,
      mem_data    => MemData_MEM,
      write_data  => WriteData,
      instr_next  => instr_next_IF,
      cathodes    => cathodes,
      anodes      => anodes
    );

  -- LEDs for control signals debug
  dbg_vector <=
       RegDst_ID   &    -- LED 7
       RegWrite_ID &    -- LED 6
       ALUSrc_ID   &    -- LED 5
       PCSrc       &    -- LED 4
       MemRead_ID  &    -- LED 3
       MemWrite_ID &    -- LED 2
       MemtoReg_ID &    -- LED 1
       jump_ID;         -- LED 0

  leds <= dbg_vector when sw(0) = '0' else ("000000" & ALUOp_ID);

end Behavioral;
