library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity exponentiation is
	generic (
		C_block_size : integer := 256
	);
	port (
		--input control
		valid_in	: in STD_LOGIC;
		ready_in	: out STD_LOGIC;
		msgin_last  : in STD_LOGIC;
		--input data
		message 	: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );
		key_e_d 	: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );

		--ouput control
		ready_out	: in STD_LOGIC;
		valid_out	: out STD_LOGIC;

		--output data
		result 		: out STD_LOGIC_VECTOR(C_block_size-1 downto 0);

		--modulus
		key_n 	: in STD_LOGIC_VECTOR(C_block_size-1 downto 0);

		--utility
		clk 		: in STD_LOGIC;
		reset_n 	: in STD_LOGIC
	);
end exponentiation;


architecture expBehave of exponentiation is
	signal P0_nxt : std_logic_vector(C_BLOCK_SIZE -1 downto 0) := (others => '0');
	signal P0_out : std_logic_vector(C_BLOCK_SIZE -1 downto 0) := (others => '0');
	signal P1_nxt : std_logic_vector(C_BLOCK_SIZE -1 downto 0) := (others => '0');
	signal P1_out : std_logic_vector(C_BLOCK_SIZE -1 downto 0) := (others => '0');
	signal c0_nxt : std_logic_vector(C_BLOCK_SIZE -1 downto 0) := (others => '0');
	signal c0_out : std_logic_vector(C_BLOCK_SIZE -1 downto 0) := (others => '0');
	signal c1_nxt : std_logic_vector(C_BLOCK_SIZE -1 downto 0) := (others => '0');
	signal c1_out : std_logic_vector(C_BLOCK_SIZE -1 downto 0) := (others => '0');
	signal mux1_out : std_logic_vector(C_BLOCK_SIZE -1 downto 0) := (others => '0');
	signal mux2_out : std_logic_vector(C_BLOCK_SIZE -1 downto 0) := (others => '0');
	signal mux3_out : std_logic_vector(C_BLOCK_SIZE -1 downto 0) := (others => '0');


	signal e_i : std_logic := '0';
	signal e_count : integer := C_BLOCK_SIZE;
	signal multiplier_count : integer := C_BLOCK_SIZE;
	signal sum1 : std_logic_vector(C_BLOCK_SIZE -1 downto 0) := (others => '0');
	signal sum2 : std_logic_vector(C_BLOCK_SIZE -1 downto 0) := (others => '0');
	signal multi2_out : std_logic_vector(C_BLOCK_SIZE -1 downto 0) := (others => '0');

	signal mN : std_logic_vector (C_BLOCK_SIZE - 1 + 2 downto 0);
	signal m2N : std_logic_vector (C_BLOCK_SIZE - 1 + 2  downto 0) ; 

begin

	--Shift register for e_i, and counter e_counter for msgout_ready signal
	e_reg : process(clk, key_n, key_e_d, e_count, multiplier_count)
	variable key_n_minus : std_logic_vector (C_BLOCK_SIZE - 1 downto 0);
	begin
		--Generate N key signals for the multipliers
		key_n_minus := -key_n;
		--Adjust the bus length for the mulitipliers
		mN <= "11" & key_n_minus;
		--Multiply by two
		m2N <= "1" & (key_n_minus(C_BLOCK_SIZE - 1 downto 0) & "0");

		if rising_edge(clk)  then
			multiplier_count <= multiplier_count -1;

			if multiplier_count <= 0 then
				--Increments e_i if counter is above 1
				if e_count > 1 then
					e_i <= key_e_d (e_count - 1);
				else
					e_i <= '0';
				end if;
				e_count <= e_count - 1;
			
				--Sends out msgout_valid signal when counter is done
				if e_count <= 0  then
					valid_out <= '1';
					e_count <= C_BLOCK_SIZE;
				else
					valid_out <= '0';
				end if;

				multiplier_count <= C_BLOCK_SIZE;
			end if;
		end if;
	end process ; 

-- exponentiation loop

	-- multiplexer for M and sum1 from p1 register.  
	mux1 : process(message, sum1, msgin_last)
	begin	
		if rising_edge(clk) then
			if msgin_last = '0' then
				mux1_out <= sum1 (C_BLOCK_SIZE -1 downto 0);
			else
				mux1_out <= message (C_BLOCK_SIZE -1 downto 0);
			end if;
		end if;	
		
	end process;

	-- register P0 storing muxed value
	p0_reg : process(clk, P0_nxt)
	begin	
		if rising_edge(clk) then
			P0_out <= P0_nxt;
		end if;
	end process;

	-- multiplier using p0_reg out value
	m_exponentiation : entity work.Multiplier
			--removed generic map
			port map (
				A => P0_out ,
				B => P0_out ,
				CLK => clk ,
				mN => mN ,
				m2N => m2N,
				P => P1_nxt

			);

	-- register storing result from multiplier step
	p1_reg : process(clk, p1_nxt)
	begin
		if rising_edge(clk) then
			P1_out <= P1_nxt;
		end if;
	end process;


-- multiplier loop


	-- multiplexer for 1(1st step) and feedpack loop
	mux2 : process(sum2, msgin_last)
	begin
			if msgin_last = '0' then
				mux2_out <= sum2 (C_BLOCK_SIZE -1 downto 0);
			else
				mux2_out <= (C_BLOCK_SIZE -1 downto 1 => '0') & '1';
			end if;  
	end process;

	-- register c0 storing muxed value
	c0_reg : process(clk, c0_nxt)
	begin
		if rising_edge(clk) then
			c0_out <= c0_nxt;
		end if;
	end process;

	-- multiplier adding exponents to output
	mexponent_multiplier : entity work.Multiplier
	generic map(
		BUS_WIDTH => C_BLOCK_SIZE
	)
	port map (
		A => P0_out ,
		B => c0_out ,
		CLK => clk ,
		mN => mN ,
		m2N => m2N,
		P => multi2_out

	);
		

	-- using mux to use or discard result from multiplier
	mux3 : process(multi2_out, c0_out, e_i)
	begin
		if e_i = '0' then
			mux3_out <= c0_out;
		else 
			mux3_out <= multi2_out;
		end if ;
	end process;

	-- register c1 storing value from mux3
	c1_reg : process(clk, c1_nxt)
	begin
		if rising_edge(clk) then
			c1_out <= c1_nxt;
		end if;
	end process;

-- connecting processes
	-- inputs mux1 signal into register p0
	P0_nxt <= mux1_out;
	sum1 <= P0_out;	
	sum2 <= P1_out;	


	result <= P1_out;
	ready_in <= ready_out;

end expBehave;