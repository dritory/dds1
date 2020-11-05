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
		CORE_COUNT				  : integer := 2
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

architecture rtl of rsa_core is

	type ARRAY_OF_SIGNAL_VECTOR is array (CORE_COUNT - 1 downto 0) of std_logic_vector(C_BLOCK_SIZE-1 downto 0);

	signal MSOUT_ARRAY : ARRAY_OF_SIGNAL_VECTOR;
	signal VALID_IN_ARRAY : std_logic_vector(CORE_COUNT - 1 downto 0);
	signal READY_IN_ARRAY :  std_logic_vector(CORE_COUNT- 1 downto 0);
	signal VALID_OUT_ARRAY : std_logic_vector(CORE_COUNT- 1 downto 0);
	signal READY_OUT_ARRAY : std_logic_vector(CORE_COUNT- 1 downto 0);

	signal core_out : integer range 0 to CORE_COUNT - 1;
	signal core_out_nxt : integer range 0 to CORE_COUNT - 1;

	signal core_in : integer range 0 to CORE_COUNT - 1;
	signal core_in_nxt : integer range 0 to CORE_COUNT - 1;

	type output_state_type is (WAIT_OUT, WRITE_OUT);
	signal output_state, output_state_next : output_state_type;

	type input_state_type is (WAIT_IN, START_CORE, INIT_CORE);
	signal input_state, input_state_next : input_state_type;


	begin
		GEN_CORES : for I in 0 to CORE_COUNT - 1 generate
				i_exponentiation : entity work.exponentiation
				generic map (
					C_block_size => C_BLOCK_SIZE
				)
				port map (
					message   => msgin_data,
					key_e_d   => key_e_d     ,
					valid_in  => VALID_IN_ARRAY(I) ,
					ready_in  => READY_IN_ARRAY(I),
					ready_out => READY_OUT_ARRAY(I),
					valid_out => VALID_OUT_ARRAY(I),
					result    => MSOUT_ARRAY(I),
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
				input_state <= input_state_next;
			end if ;
		end process ; -- seqv_input

		input_fsm : process(input_state, msgin_valid,VALID_IN_ARRAY,READY_IN_ARRAY, msgin_valid)
		begin
			core_in_nxt <= core_in;
			msgin_ready <= '0';
			VALID_IN_ARRAY <=  (others => '0');
			case input_state is
				when WAIT_IN=>
					if (msgin_valid = '1') then
						input_state_next <= START_CORE;
					else
						input_state_next <= WAIT_IN;
					end if;
				when INIT_CORE=>
					input_state_next <= WAIT_IN;	
				when START_CORE=>
					VALID_IN_ARRAY(core_in) <= '1';
					if(READY_IN_ARRAY(core_in) = '1') then
						msgin_ready <= '1';
						if core_in >= CORE_COUNT -1 then
							core_in_nxt <= 0;
						else
							core_in_nxt <= core_in +1;
						end if;

						input_state_next <= INIT_CORE;
					else
						input_state_next <= START_CORE;
					end if;
				when others =>
					input_state_next <= WAIT_IN;
			end case;
		end process ; -- output_control


		seqv_output : process(reset_n, clk)
		begin
			if(reset_n = '0') then
				core_out <= 0;
				output_state <= WAIT_OUT;
			elsif(rising_edge(clk)) then
				core_out <= core_out_nxt;
				output_state <= output_state_next;
			end if ;
		end process ; -- seqv_output

		output_fsm : process(output_state, READY_OUT_ARRAY,VALID_OUT_ARRAY, msgout_ready)
		begin
			msgout_data <= (others => '0');
			READY_OUT_ARRAY <=  (others => '0');
			core_out_nxt <= core_out;
			msgout_valid <= '0';
			case output_state is
				when WAIT_OUT=>
					if (VALID_OUT_ARRAY(core_out) = '1') then
						output_state_next <= WRITE_OUT;
					else
						output_state_next <= WAIT_OUT;
					end if;
				when WRITE_OUT=>
					if(msgout_ready = '1') then
						READY_OUT_ARRAY(core_out) <= '1';
						msgout_data <= MSOUT_ARRAY(core_out);
						msgout_valid <= '1';

						if core_out >= CORE_COUNT -1 then
							core_out_nxt <= 0;
						else
							core_out_nxt <= core_out +1;
						end if;

						output_state_next <= WAIT_OUT;
					else
						output_state_next <= WRITE_OUT;
					end if;
					
				when others =>
					output_state_next <= WAIT_OUT;
			end case;
		end process ; -- output_control



		msgout_last  <= msgin_last;
		rsa_status   <= (others => '0');
	end rtl;
