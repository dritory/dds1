--this is an instantiated file
library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
entity Multiplier is
	generic (
		BUS_WIDTH : integer := 256
	);
	port (
		--input data
		A : in std_logic_vector (BUS_WIDTH - 1  downto 0);
		B : in std_logic_vector (BUS_WIDTH - 1  downto 0);
		mN : in std_logic_vector (BUS_WIDTH - 1 + 2 downto 0);
		m2N : in std_logic_vector (BUS_WIDTH - 1 + 2  downto 0); 
		CLK : in std_logic;
		reset_n : in std_logic;
		first_step : in std_logic;
		--output
		P : out std_logic_vector (BUS_WIDTH - 1  downto 0)
	);
end Multiplier;


architecture behaviour of Multiplier is
	signal b_i : std_logic := '0';
	signal b_count : integer range 0 to 256 := BUS_WIDTH;
	signal p_nxt : std_logic_vector (BUS_WIDTH - 1  downto 0) := (others => '0');
	signal P_shift : std_logic_vector (BUS_WIDTH - 1 + 1  downto 0) := (others => '0');
	signal P_out : std_logic_vector (BUS_WIDTH - 1  downto 0) := (others => '0');
	
	signal sum0 : std_logic_vector (BUS_WIDTH - 1 + 2  downto 0);
	signal sum1 : std_logic_vector (BUS_WIDTH - 1 + 2  downto 0);
	signal sum2 : std_logic_vector (BUS_WIDTH - 1 + 2  downto 0);
	signal mux1 : std_logic_vector (BUS_WIDTH - 1  downto 0);
	signal mux2 : std_logic_vector (BUS_WIDTH - 1  downto 0);
begin
	
	--Shift register for b_i
	b_reg : process(CLK, reset_n, B, b_count)
	begin
		if reset_n = '0' then
			b_i <= '0';
			b_count <= BUS_WIDTH;
		elsif rising_edge(CLK) then
			if first_step = '0' then
				--Increments b_i if counter is above 1
				if b_count >= 1 then
					b_i <= B (b_count - 1);
				else
					b_i <= '0';
				end if;
				b_count <= b_count - 1;
				
				if b_count <= -1 then
					b_count <= BUS_WIDTH;
				end if;
			else
				b_i <= '0';
				b_count <= BUS_WIDTH;
			end if;
		end if;
	end process ; -- b_reg

	--Register for output value P
	p_reg : process(CLK, reset_n, P_nxt, first_step )
	begin
		if (reset_n = '0') or (first_step ='1') then
			P_out <= (others => '0');
		elsif rising_edge(CLK) then
			P_out <= P_nxt;
		end if;
	end process ; -- p_reg
	
	--First adder and AND gate
	adder0 : process(A, b_i, P_shift)
	variable and_A : std_logic_vector (BUS_WIDTH - 1 +1 downto 0);
	begin
		and_A := "0" & (A and b_i);
		sum0 <= "0" & (and_A + P_shift);
	end process ; -- adder0
	
	--The two modulus subtractors
	mod_adder : process(sum0, m2N, mN)
	begin
		sum1 <= sum0 + mN;
		sum2 <= sum0 + m2N;
	end process ; -- mod_adder

	--Muliplexers for selecting correct sum
	multiplexer1 : process(sum1, sum0)
	begin
		if sum1(BUS_WIDTH - 1 + 2) = '0' then
			mux1 <= sum1 (BUS_WIDTH - 1 downto 0);
		else
			mux1 <= sum0 (BUS_WIDTH - 1 downto 0);
		end if;
	end process ; -- multiplexer1

	multiplexer2 : process(sum2, mux1)
	begin
		if sum2(BUS_WIDTH - 1 + 2) = '0' then
			mux2 <= sum2 (BUS_WIDTH - 1 downto 0);
		else
			mux2 <= mux1;
		end if;
		
	end process ; -- multiplexer2
	
	--inputs the mux signal into the register
	P_nxt <= mux2;
	--Outputs the register to the P output
	P <= P_out;
	--Shifts P left by one and add 0, equivalent to multipying by two
	P_shift <= P_out (BUS_WIDTH - 1 downto 0) & '0';

end behaviour;