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
        load_M : out std_logic;

        --input data
		key_e_d 	: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );


        --datapath control
        e_i : out std_logic;
	    exp_clk : out std_logic;
	    first_step_mult : out std_logic;
        mux_in_msg : out std_logic;
	    mux_in_one : out std_logic;

		--ouput control
		ready_out	: in STD_LOGIC;
		valid_out	: out STD_LOGIC;

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

	signal e_count : integer range 0 to 256:= 0;
    signal multiplier_count : integer range 0 to 256 := 0;
    
	type state_type is (wait_in, init, begin_calc, incr, calc, multiply, wait_out);
	signal state   : state_type;
	signal next_state : state_type;
begin

	next_state_logic : process (clk, reset_n_in)
	begin
		if reset_n_in = '0' then
			state <= wait_in;
		elsif rising_edge(clk) then
			state <= next_state;
		end if;
	end process;
	
	state_seqv : process (clk, e_count)
	begin
		if rising_edge(clk) then
			
			case state is
				when incr=>
					e_count <= e_count + 1;
				when calc=>
					first_step_mult <= '1';
					multiplier_count <= 0;
				when multiply=>
					multiplier_count <= multiplier_count + 1;
					first_step_mult <= '0';
				when others=>
					multiplier_count <= 0;
					e_count <= 0;
					first_step_mult <= '0';
			end case;
		end if;
	end process;
	state_comb : process (state, valid_in, e_count, multiplier_count, ready_out)
	begin
		ready_in <= '0';
		valid_out <= '0';
		reset_n_exp <= '1';
		exp_clk <= '0';
		load_M <= '0';
		case state is
			when init=>
				reset_n_exp <= '0';
				next_state <= wait_in;
			when wait_in=>
				ready_in <= '1';
				if valid_in = '1' then
					load_M <= '1';
					next_state <= calc;
				else
					next_state <= wait_in;
				end if;
			when begin_calc=>
				next_state <= calc;
			when incr=>
				next_state <= calc;
			when calc=>
				
				if e_count >= C_BLOCK_SIZE then
					next_state <= wait_out;
				else
					next_state <= multiply;
				end if;
			when multiply=>
				exp_clk <= '1';	
				if multiplier_count >= C_BLOCK_SIZE then
					next_state <= incr;
				else
					next_state <= multiply;
				end if;
			when wait_out=>
				valid_out <= '1';
				if ready_out = '1' then
					next_state <= init;
				else
					next_state <= wait_out;
				end if;
			when others =>
				next_state <= init;
		end case;
	end process;

	control : process(exp_clk, e_count, key_e_d)
	begin
		if reset_n = '0' then
			e_i <= '0';
        elsif rising_edge(exp_clk) then
            if (e_count < C_BLOCK_SIZE - 1) then
                e_i <= key_e_d (e_count);
            else
                e_i <= '0';
            end if;
            
        end if;

	end process; -- control
    
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

end expBehave;