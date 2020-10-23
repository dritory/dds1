--this is an instantiated file
library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

use IEEE.STD_LOGIC_SIGNED.ALL;
entity Multiplier_tb is
	generic (
		BUS_WIDTH : integer := 16
	);
end Multiplier_tb;


architecture behaviour of Multiplier_tb is
	signal A : std_logic_vector (BUS_WIDTH - 1  downto 0) := std_logic_vector(to_signed(100, BUS_WIDTH));
	signal B : std_logic_vector (BUS_WIDTH - 1  downto 0) := std_logic_vector(to_signed(230, BUS_WIDTH));
	signal CLK : std_logic := '0';
	signal P : std_logic_vector (BUS_WIDTH - 1  downto 0);
	signal READY : std_logic;
	signal N : std_logic_vector (BUS_WIDTH - 1 downto 0) := std_logic_vector(to_signed(-516, BUS_WIDTH)); --296
	signal mN : std_logic_vector (BUS_WIDTH - 1 + 2 downto 0);
	signal m2N : std_logic_vector (BUS_WIDTH - 1 + 2  downto 0) ; 
	constant clk_period : time := 20ns;

begin
	mN <= "11" & N;
	m2N <= "1" & (N(BUS_WIDTH - 1 downto 0) & "0");

	i_Multiplier : entity work.Multiplier
		generic map (
			BUS_WIDTH => BUS_WIDTH
		)
		port map (
			A  => A,
			B => B,
			P => P,
			CLK => CLK,
			READY => READY,
			m2N => m2N,
			mN => mN
		);
	
	clk_proc : process
	begin
		wait for clk_period/2;
		clk <='0';
        wait for clk_period/2;
		clk <= '1';
		
	end process ; -- clk_proc
	
end behaviour;