library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity exp_control is
	generic (
		C_block_size : integer range 0 to 256 := 256
	);
	port (
		--input control
		valid_in	: in STD_LOGIC;
        ready_in	: out STD_LOGIC;
		last_in		: in STD_LOGIC;

        --input data
		key_e_d 	: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );

        --datapath control
        e_i : out std_logic;
	    exp_enable : out std_logic;
	    first_step_mult : out std_logic;
        mux_in_msg : out std_logic;
	    mux_in_one : out std_logic;
		load_msg : out std_logic;

		--ouput control
		ready_out	: in STD_LOGIC;
		valid_out	: out STD_LOGIC;
		last_out	: out STD_LOGIC;

		--modulus
        key_n 	: in STD_LOGIC_VECTOR(C_block_size-1 downto 0);
        
        mN : out std_logic_vector (C_BLOCK_SIZE - 1 + 2 downto 0);
	    m2N : out std_logic_vector (C_BLOCK_SIZE - 1 + 2  downto 0); 

		--utility
		clk 		: in STD_LOGIC;
        reset_n_in 	: in STD_LOGIC;
        reset_n     : out std_logic
        
	);
end exp_control;


architecture expBehave of exp_control is
	
	signal reset_n_exp : std_logic := '0';

	signal e_count, e_count_nxt : integer range 0 to 256:= 0;
    signal multiplier_count, multiplier_count_nxt : integer range 0 to 256 := 0;
    
	type state_type is (wait_in, init, incr, calc, multiply, wait_out);
	signal state   : state_type;
	signal next_state : state_type;
	signal first_step_mult_nxt : std_logic := '0';
	signal last_msg, last_msg_nxt : std_logic := '0';
begin

	next_state_seqv : process (clk, reset_n_in)
	begin
		if reset_n_in = '0' then
			state <= wait_in;
		elsif rising_edge(clk) then
			state <= next_state;
		end if;
	end process;

	next_state_comb : process (state, valid_in, e_count, multiplier_count, ready_out)
	begin
		case state is
			when init=>
				next_state <= wait_in;
			when wait_in=>
				if valid_in = '1' then
					next_state <= calc;
				else
					next_state <= wait_in;
				end if;
			when incr=>
				next_state <= calc;
			when calc=>
				if e_count >= C_BLOCK_SIZE then
					next_state <= wait_out;
				else
					next_state <= multiply;
				end if;
			when multiply=>
				if multiplier_count >= C_BLOCK_SIZE then
					next_state <= incr;
				else
					next_state <= multiply;
				end if;
			when wait_out=>
				if ready_out = '1' then
					next_state <= init;
				else
					next_state <= wait_out;
				end if;
			when others =>
				next_state <= init;
		end case;
	end process;			
	state_comb : process (state, valid_in, last_in,last_msg, e_count, multiplier_count, ready_out)
	begin
		ready_in <= '0';
		valid_out <= '0';
		reset_n_exp <= '1';
		exp_enable <= '0';
		load_msg <= '0';
		last_msg_nxt <= last_msg;
		e_count_nxt <= e_count;
		multiplier_count_nxt <= 0;
		first_step_mult_nxt <= '0';
		case state is
			when init=>
				reset_n_exp <= '0';
				e_count_nxt <= 0;
			when wait_in=>
				ready_in <= '1';
				if valid_in = '1' then
					last_msg_nxt <= last_in;
				end if;
			when incr=>
				e_count_nxt <= e_count + 1;
				
			when calc=>
				first_step_mult_nxt <= '1';
				if e_count < C_BLOCK_SIZE then
					exp_enable <= '1';
				end if;
			when multiply=>
				multiplier_count_nxt <= multiplier_count + 1;
			when wait_out=>
				valid_out <= '1';
			when others=>
		end case;
	end process;				
	
	
	registers : process (clk, reset_n_in, e_count)
	begin
		if reset_n_in = '0' then
			last_msg <= '0';
			first_step_mult <= '0';
			e_count <= 0;
			multiplier_count <= 0;
		elsif rising_edge(clk) then
			last_msg <= last_msg_nxt;
			first_step_mult <= first_step_mult_nxt;
			multiplier_count <= multiplier_count_nxt;
			e_count <= e_count_nxt;
		end if;
	end process;

	e_i_control : process(clk, exp_enable, e_count, key_e_d)
	begin
		if reset_n = '0' then
			e_i <= '0';
        elsif rising_edge(clk) and (exp_enable = '1') then
            if (e_count < C_BLOCK_SIZE - 1) then
                e_i <= key_e_d (e_count);
            else
                e_i <= '0';
            end if;
        end if;
	end process; -- e_i_control
	
	--sends out mux signals for mux1 and mux2
    mux_signals : process(e_count)
    begin
        if e_count > 0 then
            mux_in_msg <= '0';
        else
            mux_in_msg <= '1';
        end if;

        if e_count > 1 then
            mux_in_one <= '0';
        else
            mux_in_one <= '1';
        end if;
    end process ; -- mux_signals

	--sets up the n key signals for the multipliers
	key_n_gen : process(key_n)
	variable key_n_minus : std_logic_vector (C_BLOCK_SIZE - 1 downto 0);
	begin
		--Generate N key signals for the multipliers
		key_n_minus := -key_n;
		--Adjust the bus length for the mulitipliers
		mN <= "11" & key_n_minus;
		--Multiply by two
		m2N <= "1" & (key_n_minus(C_BLOCK_SIZE - 1 downto 0) & "0");
	end process ; -- key_n_gen

	reset_n <= reset_n_in and reset_n_exp;
	last_out <= last_msg;
end expBehave;