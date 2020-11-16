--------------------------------------------------------------------------------
-- Author       : Oystein Gjermundnes
-- Organization : Norwegian University of Science and Technology (NTNU)
--                Department of Electronic Systems
--                https://www.ntnu.edu/ies
-- Course       : TFE4141 Design of digital systems 1 (DDS1)
-- Year         : 2018-2019
-- Project      : RSA accelerator
-- License      : This is free and unencumbered software released into the
--                public domain (UNLICENSE)
--------------------------------------------------------------------------------
-- Purpose:
--   RSA encryption core template. This core currently computes
--   C = M xor key_n
--
--   Replace/change this module so that it implements the function
--   C = M**key_e mod key_n.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rsa_core is
	generic (
		-- Users to add parameters here
		C_BLOCK_SIZE          : integer := 256;
		C_CORE_COUNT		  : integer := 10
	);
	port (
		-----------------------------------------------------------------------------
		-- Clocks and reset
		-----------------------------------------------------------------------------
		clk                    :  in std_logic;
		reset_n                :  in std_logic;

		-----------------------------------------------------------------------------
		-- Slave msgin interface
		-----------------------------------------------------------------------------
		-- Message that will be sent out is valid
		msgin_valid             : in std_logic;
		-- Slave ready to accept a new message
		msgin_ready             : out std_logic;
		-- Message that will be sent out of the rsa_msgin module
		msgin_data              :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		-- Indicates boundary of last packet
		msgin_last              :  in std_logic;

		-----------------------------------------------------------------------------
		-- Master msgout interface
		-----------------------------------------------------------------------------
		-- Message that will be sent out is valid
		msgout_valid            : out std_logic;
		-- Slave ready to accept a new message
		msgout_ready            :  in std_logic;
		-- Message that will be sent out of the rsa_msgin module
		msgout_data             : out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		-- Indicates boundary of last packet
		msgout_last             : out std_logic;

		-----------------------------------------------------------------------------
		-- Interface to the register block
		-----------------------------------------------------------------------------
		key_e_d                 :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		key_n                   :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		rsa_status              : out std_logic_vector(31 downto 0)

	);
end rsa_core;


architecture rtl_cores of rsa_core is

	type ARRAY_OF_SIGNAL_VECTOR is array (C_CORE_COUNT- 1 downto 0) of std_logic_vector(C_BLOCK_SIZE-1 downto 0);
	signal msout_array : ARRAY_OF_SIGNAL_VECTOR;
	signal valid_in_array  : std_logic_vector(C_CORE_COUNT- 1 downto 0);
	signal ready_in_array  : std_logic_vector(C_CORE_COUNT- 1 downto 0);
	signal valid_out_array : std_logic_vector(C_CORE_COUNT- 1 downto 0);
	signal last_out_array  : std_logic_vector(C_CORE_COUNT- 1 downto 0);
	signal ready_out_array : std_logic_vector(C_CORE_COUNT- 1 downto 0);

	signal core_out, core_out_nxt : integer range 0 to C_CORE_COUNT- 1;
	signal core_in, core_in_nxt   : integer range 0 to C_CORE_COUNT- 1;

	type output_state_type is (WAIT_OUT, WRITE_OUT,WRITE_SETTLE_OUT);
	signal output_state, output_state_nxt : output_state_type;

	type input_state_type is (WAIT_IN, START_CORE, INIT_CORE);
	signal input_state, input_state_nxt   : input_state_type;
	
	begin
		GEN_CORES : for I in 0 to C_CORE_COUNT - 1 generate
				i_exponentiation : entity work.exponentiation
				generic map (
					C_block_size => C_BLOCK_SIZE
				)
				port map (
					message   => msgin_data,
					key_e_d   => key_e_d     ,
					valid_in  => valid_in_array(I) ,
					ready_in  => ready_in_array(I),
					last_in   => msgin_last,
					ready_out => ready_out_array(I),
					valid_out => valid_out_array(I),
					last_out  => last_out_array(I),
					result    => msout_array(I),
					key_n     => key_n       ,
					clk       => clk         ,
					reset_n   => reset_n
				);
		end generate GEN_CORES;

		seqv_input : process(reset_n, clk)
		begin
			if(reset_n = '0') then
				core_in <= 0;
				input_state <= WAIT_IN;
			elsif(rising_edge(clk)) then
				core_in <= core_in_nxt;
				input_state <= input_state_nxt;
			end if ;
		end process ; -- seqv_input

		input_nxt_state_comb : process(input_state, msgin_valid,ready_in_array, msgin_valid)
		begin
			case input_state is
				when WAIT_IN=>
					if (msgin_valid = '1') then
						input_state_nxt <= START_CORE;
					else
						input_state_nxt <= WAIT_IN;
					end if;
				when INIT_CORE=>
					input_state_nxt <= WAIT_IN;	
				when START_CORE=>
					if(ready_in_array(core_in) = '1') then
						input_state_nxt <= INIT_CORE;
					else
						input_state_nxt <= START_CORE;
					end if;
				when others =>
					input_state_nxt <= WAIT_IN;
			end case;
		end process ; -- input_nxt_state_comb					

		input_fsm_comb : process(input_state, msgin_valid,valid_in_array,ready_in_array, msgin_valid)
		begin
			core_in_nxt <= core_in;
			msgin_ready <= '0';
			valid_in_array <=  (others => '0');
			case input_state is	
				when START_CORE=>
					if(ready_in_array(core_in) = '1') then
						valid_in_array(core_in) <= '1';
						msgin_ready <= '1';
						if core_in >= C_CORE_COUNT -1 then
							core_in_nxt <= 0;
						else
							core_in_nxt <= core_in +1;
						end if;
					end if;
				when others =>
			end case;
		end process ; -- input_fsm_comb

		seqv_output : process(reset_n, clk)
		begin
			if(reset_n = '0') then
				core_out <= 0;
				output_state <= WAIT_OUT;
			elsif(rising_edge(clk)) then
				core_out <= core_out_nxt;
				output_state <= output_state_nxt;
			end if ;
		end process ; -- seqv_output

		output_nxt_state_comb : process(output_state, ready_out_array,valid_out_array, msgout_ready)
		begin
			case output_state is
				when WAIT_OUT=>
					if (valid_out_array(core_out) = '1') then
						output_state_nxt <= WRITE_OUT;
					else
						output_state_nxt <= WAIT_OUT;
					end if;
				when WRITE_OUT=>
					if(msgout_ready = '1') then
						output_state_nxt <= WRITE_SETTLE_OUT;
					else
						output_state_nxt <= WRITE_OUT;
					end if;
				when WRITE_SETTLE_OUT=>
					output_state_nxt <= WAIT_OUT;	
				when others =>
					output_state_nxt <= WAIT_OUT;
			end case;
		end process ; -- output_nxt_state_comb

		output_fsm_comb : process(output_state, ready_out_array,valid_out_array, msgout_ready)
		begin
			msgout_data <= (others => '0');
			ready_out_array <=  (others => '0');
			core_out_nxt <= core_out;
			msgout_valid <= '0';
			msgout_last <= '0';
			case output_state is
				when WRITE_OUT=>
					if(msgout_ready = '1') then
						ready_out_array(core_out) <= '1';
						msgout_last <= last_out_array(core_out);
						msgout_data <= msout_array(core_out);
						msgout_valid <= '1';
					end if;
				when WRITE_SETTLE_OUT=>
					if core_out >= C_CORE_COUNT -1 then
						core_out_nxt <= 0;
					else
						core_out_nxt <= core_out +1;
					end if;
					msgout_data <= msout_array(core_out);
				when others =>
			end case;
		end process ; -- output_fsm_comb

		rsa_status   <= (others => '0');
	end rtl_cores;