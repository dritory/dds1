----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 13.10.2020 10:57:42
-- Design Name: 
-- Module Name: adder - Behavioral
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

use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity adder is
    Generic (
        BUS_WIDTH : integer -- Structure
    );
    Port ( a : in STD_LOGIC_VECTOR (BUS_WIDTH - 1 downto 0);
           b : in STD_LOGIC_VECTOR (BUS_WIDTH - 1 downto 0);
           clk : in STD_LOGIC;
           y : out STD_LOGIC_VECTOR (BUS_WIDTH - 1 downto 0);
           z : out std_logic
        );
           
end adder;

architecture Behavioral of adder is
   signal a_nxt : STD_LOGIC_VECTOR (BUS_WIDTH - 1 downto 0);
   signal b_nxt : STD_LOGIC_VECTOR (BUS_WIDTH - 1 downto 0);
   constant zeros : STD_LOGIC_VECTOR(BUS_WIDTH - 1 downto 0) := (others => '0');
begin
    process (clk)
    variable y_nxt : STD_LOGIC_VECTOR (BUS_WIDTH - 1 downto 0);
    begin
        if clk'event and clk = '1' then
            y_nxt := a_nxt + b_nxt;
            if y_nxt(BUS_WIDTH - 1) = '0' then
                z <= '0';
            else
                z <= '1';
            end if;
            y <= y_nxt;

            a_nxt <= a;
            b_nxt <= b;
        end if;
    end process;
    
end Behavioral;
