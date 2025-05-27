----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/27/2025 09:44:24 AM
-- Design Name: 
-- Module Name: InstructionFetch - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity InstructionFetch is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           enable : in STD_LOGIC;
           branchTargetAddress : in STD_LOGIC_VECTOR (15 downto 0);
           jumpTargetAddress : in STD_LOGIC_VECTOR (15 downto 0);
           jumpCtrl : in STD_LOGIC;
           PCSrcCtrl : in STD_LOGIC;
           instructionToBeExecuted : out STD_LOGIC_VECTOR (15 downto 0);
           nextSequentialInstruction : out STD_LOGIC_VECTOR (15 downto 0);
           nextInstruction : out STD_LOGIC_VECTOR(15 downto 0));  -- added to be able to display PCPlus1);
end InstructionFetch;

architecture Behavioral of InstructionFetch is
signal PC: STD_LOGIC_VECTOR(15 downto 0):=(others=>'0');
signal PCPlus1: STD_LOGIC_VECTOR(15 downto 0):=(others=>'0');
--signal outMUX: STD_LOGIC_VECTOR(15 downto 0);
signal nextPC: STD_LOGIC_VECTOR(15 downto 0);

type ROM_TYPE is array (0 to 255) of STD_LOGIC_VECTOR(15 downto 0); 
signal rom : ROM_Type := (
  -- Initialize registers
  B"001_000_001_0000000",  -- addi $1, $0, 0      ; $1 = 0
  B"001_000_010_0000001",  -- addi $2, $0, 1      ; $2 = 1
  B"001_000_011_0000000",  -- addi $3, $0, 0      ; $3 = 0 (address base)
  B"001_000_100_0000100",  -- addi $4, $0, 4      ; $4 = 4 (address base aligned)

  -- Store $1 at 0($3) → RAM[0]
  B"011_011_001_0000000",  -- sw $1, 0($3)
  -- Store $2 at 0($4) → RAM[1] (4 bytes offset)
  B"011_100_010_0000000",  -- sw $2, 0($4)

  -- Load $1 from 0($3)
  B"010_011_001_0000000",  -- lw $1, 0($3)
  B"000_000_000_000_0_000",-- NoOp
  B"000_000_000_000_0_000",-- NoOp

  -- Load $2 from 0($4)
  B"010_100_010_0000000",  -- lw $2, 0($4)
  B"000_000_000_000_0_000",-- NoOp
  B"000_000_000_000_0_000",-- NoOp
  B"000_000_000_000_0_000",-- NoOp

  -- Fibonacci addition $5 = $1 + $2
  B"000_001_010_101_0_000",-- add $5, $1, $2
  B"000_000_000_000_0_000",-- NoOp
  B"000_000_000_000_0_000",-- NoOp

  -- Next steps: update registers for next Fibonacci terms
  B"000_000_010_001_0_000",-- add $1, $0, $2   ; $1 = $2 (next term)
  B"000_000_101_010_0_000",-- add $2, $0, $5   ; $2 = $5 (next term)
  B"000_000_000_000_0_000",-- NoOp (delay slot)

  -- Jump to loop start at address 12 (index 12 in ROM)
  B"111_000_000_0001100",  -- jump to address 12 (hex E00C)

  others => X"0000"
);


begin

PCget: process(clk, reset)
begin
    if reset='1' then
        PC<=(others=>'0');
    else
        if rising_edge (clk) then
            if enable='1' then
                PC<=nextPC;
            end if;
        end if;
    end if;
end process;

-- Fixed: Use consistent signal name PCPlus1
PCPlus1get: PCPlus1 <= STD_LOGIC_VECTOR(unsigned(PC) + to_unsigned(1, 16));

-- Fixed: Use consistent signal name PCPlus1
nextSequentialInstruction <= PCPlus1;

-- Fixed: Use consistent signal name PCPlus1 in sensitivity list
NextPCget: process(PCPlus1, jumpCtrl, PCSrcCtrl, jumpTargetAddress, branchTargetAddress)
begin
    if jumpCtrl='1' then
        nextPC <= jumpTargetAddress;
    else
        if PCSrcCtrl='1' then
            nextPC <= branchTargetAddress;
            --nextPC<=branchTargetAddress+PC;
        else
            -- Fixed: Use consistent signal name PCPlus1
            nextPC <= PCPlus1;
        end if;
    end if;
end process; 

instructionToBeExecuted <= ROM(to_integer(unsigned(PC(7 downto 0))));-- we only need 8 bits for 0 to 255
nextInstruction <= ROM(to_integer(unsigned(PCPlus1(7 downto 0)))); -- next instruction to display

end Behavioral;