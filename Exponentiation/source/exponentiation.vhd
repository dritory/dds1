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
	signal e_count : integer := C_BLOCK_SIZE - 1;
	signal exp_clk : std_logic := '0';
	signal multiplier_count : integer := C_BLOCK_SIZE;
	signal multi2_out : std_logic_vector(C_BLOCK_SIZE -1 downto 0) := (others => '0');

	signal mN : std_logic_vector (C_BLOCK_SIZE - 1 + 2 downto 0);
	signal m2N : std_logic_vector (C_BLOCK_SIZE - 1 + 2  downto 0) ; 

	signal calculate : std_logic := '0';
	signal first_step : std_logic := '0';

	type state_type is (wait_in, init, calc, wait_out);
	signal state   : state_type;

begin

	next_state_logic : process (clk, reset_n)
	begin
		if reset_n = '0' then
			state <= wait_in;
		elsif rising_edge(clk) then
			case state is
				when wait_in=>
					if valid_in = '1' then
						state <= init;
					else
						state <= wait_in;
					end if;
				when init=>
					state <= calc;
				when calc=>
					if e_count < 0 then
						state <= wait_out;
					else
						state <= calc;
					end if;
				when wait_out=>
					if ready_out = '1' then
						state <= wait_in;
					else
						state <= wait_out;
					end if;
			end case;
		end if;
	end process;
	
	changed_state_logic : process (state)
	begin
		case state is
			when wait_in =>
				ready_in <= '1';
				valid_out <= '0';
				calculate <= '0';
				first_step <= '0';
			when init =>
				ready_in <= '0';
				valid_out <= '0';
				calculate <= '0';
				first_step <= '1';
			when calc =>
				ready_in <= '0';
				valid_out <= '0';
				calculate <= '1';
				first_step <= '0';
			when wait_out =>
				ready_in <= '0';
				valid_out <= '1';
				calculate <= '0';
				first_step <= '0';
		end case;
	end process;

	-- control : process(clk, e_count, multiplier_count, valid_in, ready_out)
	-- begin
	-- 	if reset_n = '0' then
			
	-- 	else
	-- 		if rising_edge(clk)  then
				
	-- 		end if;
			
			
	-- 	end if;

	-- 	--first step signal
	-- 	if e_count = C_BLOCK_SIZE and multiplier_count = C_BLOCK_SIZE then
	-- 		first_step <= '1';
	-- 	else
	-- 		first_step <= '0';
	-- 	end if;
		
	-- end process ; -- control



	--Shift register for e_i, and counter e_counter for valid signal
	e_reg : process(clk, reset_n, key_n, key_e_d, e_count, multiplier_count, first_step)
	variable key_n_minus : std_logic_vector (C_BLOCK_SIZE - 1 downto 0);
	begin
		--Generate N key signals for the multipliers
		key_n_minus := -key_n;
		--Adjust the bus length for the mulitipliers
		mN <= "11" & key_n_minus;
		--Multiply by two
		m2N <= "1" & (key_n_minus(C_BLOCK_SIZE - 1 downto 0) & "0");
		if reset_n = '0' then
			e_i <= '0';
			exp_clk <= '0';
			e_count <= C_BLOCK_SIZE - 1;
			multiplier_count <= C_BLOCK_SIZE;
		elsif rising_edge(clk) then
			if first_step = '0' then
				multiplier_count <= multiplier_count -1;
				if multiplier_count <= 0 then
					--Increments e_i if counter is above 0
					if e_count > 0 then
						e_i <= key_e_d (e_count - 1);
						exp_clk <= '1';
					else
						e_i <= '0';
						exp_clk <= '0';
					end if;
					e_count <= e_count - 1;
					multiplier_count <= C_BLOCK_SIZE;
					
				else
					exp_clk <= '0';
				end if;
			else
				e_count <= C_BLOCK_SIZE - 1;
				multiplier_count <= C_BLOCK_SIZE;
				exp_clk <= '1';
			end if;
		end if;
	end process ; 

-- exponentiation loop

	-- multiplexer for M and sum1 from p1 register.  
	mux1 : process(message, P1_out, first_step)
	begin	
		
		if first_step = '0' then
			mux1_out <= P1_out (C_BLOCK_SIZE -1 downto 0);
		else
			mux1_out <= message (C_BLOCK_SIZE -1 downto 0);
		end if;	
		
	end process;

	-- register P0 storing muxed value
	p0_reg : process(exp_clk, reset_n, P0_nxt)
	begin	
		if reset_n = '0' then
			P0_out <= (others => '0');
		elsif rising_edge(exp_clk) then
			P0_out <= P0_nxt;
		end if;
	end process;

	-- multiplier using p0_reg out value
	m_multiplier : entity work.Multiplier
			--removed generic map
			port map (
				A => P0_out ,
				B => P0_out ,
				CLK => clk ,
				mN => mN ,
				m2N => m2N,
				first_step => first_step,
				P => P1_nxt,
				Reset_n => reset_n
			);

	-- register storing result from multiplier step
	p1_reg : process(exp_clk,reset_n, p1_nxt)
	begin
		if reset_n = '0' then
			P1_out <= (others => '0');
		elsif rising_edge(exp_clk) then
			P1_out <= P1_nxt;
		end if;
	end process;


-- multiplier loop


	-- multiplexer for 1(1st step) and feedpack loop
	mux2 : process(C1_out, first_step)
	begin
		if first_step = '0' then
			mux2_out <= C1_out (C_BLOCK_SIZE -1 downto 0);
		else
			mux2_out <= (C_BLOCK_SIZE -1 downto 1 => '0') & '1';
		end if;  
	end process;

	-- register c0 storing muxed value
	c0_reg : process(exp_clk, reset_n, c0_nxt)
	begin
		if reset_n = '0' then
			c0_out <= (others => '0');
		elsif rising_edge(exp_clk) then
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
		first_step => first_step,
		P => multi2_out,
		reset_n => reset_n
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
	c1_reg : process(exp_clk, reset_n, c1_nxt)
	begin
		if reset_n = '0' then
			c1_out <= (others => '0');
		elsif rising_edge(exp_clk) then
			c1_out <= c1_nxt;
		end if;
	end process;

-- connecting processes
	-- inputs mux1 signal into register p0
	P0_nxt <= mux1_out;
	C1_nxt <= mux3_out;
	C0_nxt <= mux2_out;

	result <= c1_out;

end expBehave;