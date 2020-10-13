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
    Port ( a : in STD_LOGIC_VECTOR (255 downto 0);
           b : in STD_LOGIC_VECTOR (255 downto 0);
           clk : in STD_LOGIC;
           y : out STD_LOGIC_VECTOR (255 downto 0));
           
end adder;

architecture Behavioral of adder is
   signal a_nxt : STD_LOGIC_VECTOR (255 downto 0);
   signal b_nxt : STD_LOGIC_VECTOR (255 downto 0);
begin
    process (clk)
    begin
        if clk'event and clk = '1' then
            y <= a_nxt + b_nxt;

            a_nxt <= a;
            b_nxt <= b;
        end if;
    end process;
    
end Behavioral;
