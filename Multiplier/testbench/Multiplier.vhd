--this is an instantiated file
library ieee;
use ieee.std_logic_1164.all;

entity Multiplier_tb is
	generic (
		somegeneric : integer := 256
	);
end Multiplier_tb;


architecture behaviour of Multiplier_tb is
	signal data_in : std_logic;
	signal data_out : std_logic;
begin
	i_Multiplier : entity work.Multiplier
		generic map (
			somegeneric => somegeneric
		)
		port map (
			data_in  => data_in,
			data_out => data_out
		);
end behaviour;