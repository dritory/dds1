--this is an instantiated file
library ieee;
use ieee.std_logic_1164.all;

entity Multiplier is
	generic (
		somegeneric : integer := 256
	);
	port (
		--input data
		data_in : in std_logic;
		--output
		data_out : out std_logic
	);
end Multiplier;


architecture behaviour of Multiplier is
begin
	data_out <= data_in;
end behaviour;