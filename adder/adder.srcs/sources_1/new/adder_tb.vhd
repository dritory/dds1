----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 13.10.2020 10:57:42
-- Design Name: 
-- Module Name: adder_tb - Behavioral
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity adder_tb is
--  Port ( );
end adder_tb;

architecture Behavioral of adder_tb is
    component adder
    Port ( a : in STD_LOGIC_VECTOR (255 downto 0);
           b : in STD_LOGIC_VECTOR (255 downto 0);
           clk : in STD_LOGIC;
           y : out STD_LOGIC_VECTOR (255 downto 0));
    end component;

    signal a : STD_LOGIC_VECTOR (255 downto 0) := x"000000000000000000000000000000000000000000000000AAAABBBBCCCCDDDD";
    signal b : STD_LOGIC_VECTOR (255 downto 0) := x"000000000000000000000000000000000000000000000000AAAABBBBCCCCDDDD";
    signal y : STD_LOGIC_VECTOR (255 downto 0);
    signal clk : STD_LOGIC := '0';

    constant clk_period : time := 50ns;

begin
    UUT: adder
    port map(
        a => a,
        b => b,
        clk => clk,
        y => y
    );

    clk_process : process
    begin 
        clk <='0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;
    sim: process
    begin
        wait for 100us;

        wait for 100us;

    end process;

end Behavioral;
