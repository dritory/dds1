library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity exponentiation is
	generic (
		C_block_size : integer range 0 to 256 := 256
	);
	port (
		--input control
		valid_in	: in STD_LOGIC;
		ready_in	: out STD_LOGIC;
		last_in		: in STD_LOGIC;
		
		--input data
		message 	: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );
		key_e_d 	: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );

		--ouput control
		ready_out	: in STD_LOGIC;
		valid_out	: out STD_LOGIC;
		last_out	: out STD_LOGIC;

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
	signal c1_nxt : std_logic_vector(C_BLOCK_SIZE -1 downto 0) := (others => '0');
	signal c1_out : std_logic_vector(C_BLOCK_SIZE -1 downto 0) := (others => '0');
	signal mux1_out : std_logic_vector(C_BLOCK_SIZE -1 downto 0) := (others => '0');
	signal mux2_out : std_logic_vector(C_BLOCK_SIZE -1 downto 0) := (others => '0');
	signal mux3_out : std_logic_vector(C_BLOCK_SIZE -1 downto 0) := (others => '0');
	
	signal multi2_out : std_logic_vector(C_BLOCK_SIZE -1 downto 0) := (others => '0');
	signal multiexp_out : std_logic_vector(C_BLOCK_SIZE -1 downto 0) := (others => '0');

	signal M0_nxt : std_logic_vector(C_BLOCK_SIZE -1 downto 0) := (others => '0');
	signal M0_out : std_logic_vector(C_BLOCK_SIZE -1 downto 0) := (others => '0');

	signal reset : std_logic;

	signal e_i : std_logic;
	signal exp_enable : std_logic;
	
	signal mux_in_msg : std_logic;
	signal mux_in_one : std_logic;
	signal load_msg : std_logic;

	signal mN : std_logic_vector (C_BLOCK_SIZE - 1 + 2 downto 0);
	signal m2N : std_logic_vector (C_BLOCK_SIZE - 1 + 2  downto 0) ; 

	signal first_step_mult : std_logic;

begin
	-- control block
	m_control : entity work.exp_control
			generic map (
				C_BLOCK_SIZE => C_BLOCK_SIZE
			)		
			port map (
				--input control
				valid_in => valid_in,
				ready_in => ready_in,
				last_in	=> last_in,

				--input data
				key_e_d => key_e_d,

				--datapath control
				e_i =>e_i,
				exp_enable => exp_enable,
				first_step_mult => first_step_mult,
				mux_in_msg => mux_in_msg,
				mux_in_one => mux_in_one,
				load_msg => load_msg,
				--ouput control
				ready_out	=> ready_out,
				valid_out	=> valid_out,
				last_out	=> last_out,
				--modulus
				key_n 	=> key_n,
				
				mN => mN,
				m2N => m2N,

				--utility
				clk 		=> clk,
				reset_n_in 	=> reset_n,
				reset_n     => reset
			);



-- exponentiation loop

	-- multiplexer for M and sum1 from p1 register.  
	mux1 : process(M0_out, multiexp_out, mux_in_msg) --check stimuli
	begin	
		
		if mux_in_msg = '0' then --mux_in_msg
			mux1_out <= multiexp_out (C_BLOCK_SIZE -1 downto 0);
		else
			mux1_out <= M0_out (C_BLOCK_SIZE -1 downto 0);
		end if;	
		
	end process;

	--register P0 storing muxed value
	p0_reg : process(clk, exp_enable, reset, P0_nxt)
	begin	
		if reset = '0' then
			P0_out <= (others => '0');
		elsif rising_edge(clk) and (exp_enable = '1') then
			P0_out <= P0_nxt;
		end if;
	end process;

	--register M0 storing incoming message value
	m0_reg : process(clk, reset,load_msg, M0_nxt)
	begin	
		if reset = '0' then
			M0_out <= (others => '0');
		elsif rising_edge(clk) and (load_msg = '1') then
			M0_out <= M0_nxt;
		end if;
	end process;
	
	-- multiplier using p0_reg out value
	m_multiplier : entity work.Multiplier
			generic map (
				BUS_WIDTH => C_BLOCK_SIZE
			)		
			port map (
				A => P0_out ,
				B => P0_out ,
				CLK => clk ,
				mN => mN ,
				m2N => m2N,
				first_step => first_step_mult,
				P => multiexp_out,
				reset_n => reset
			);


-- multiplier loop
	-- multiplexer for 1(1st step) and feedpack loop
	mux2 : process(C1_out, mux_in_one)
	begin
		if mux_in_one = '0' then --mux_in_one
			mux2_out <= C1_out (C_BLOCK_SIZE -1 downto 0);
		else
			mux2_out <= (C_BLOCK_SIZE -1 downto 1 => '0') & '1';
		end if;  
	end process;

	-- multiplier adding exponents to output
	mexponent_multiplier : entity work.Multiplier
	generic map(
		BUS_WIDTH => C_BLOCK_SIZE
	)
	port map (
		A => P0_out,
		B => mux2_out,
		CLK => clk ,
		mN => mN ,
		m2N => m2N,
		first_step => first_step_mult,
		P => multi2_out,
		reset_n => reset
	);
		

	-- using mux to use or discard result from multiplier
	mux3 : process(multi2_out, mux2_out, e_i)
	begin
		if e_i = '0' then
			mux3_out <= mux2_out;
		else 
			mux3_out <= multi2_out;
		end if ;
	end process;

	-- register c1 storing value from mux3
	c1_reg : process(clk, exp_enable, reset, c1_nxt)
	begin
		if reset = '0' then
			c1_out <= (others => '0');
		elsif rising_edge(clk) and (exp_enable = '1') then
			c1_out <= c1_nxt;
		end if;
	end process;

-- connecting processes
	-- inputs mux1 signal into register p0
	P0_nxt <= mux1_out;
	C1_nxt <= mux3_out;
	M0_nxt <= message;
	result <= c1_out;

end expBehave;