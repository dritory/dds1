library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;


entity exponentiation_tb is
	generic (
		C_block_size : integer := 256
	);
end exponentiation_tb;


architecture expBehave of exponentiation_tb is

	signal message 		: STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );
	signal key 			: STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );
	signal valid_in 	: STD_LOGIC;
	signal ready_in 	: STD_LOGIC;
	signal ready_out 	: STD_LOGIC;
	signal valid_out 	: STD_LOGIC;
	signal result 		: STD_LOGIC_VECTOR(C_block_size-1 downto 0);
	signal modulus 		: STD_LOGIC_VECTOR(C_block_size-1 downto 0);
	signal clk 			: STD_LOGIC;
	signal restart 		: STD_LOGIC;
	signal reset_n 		: STD_LOGIC;

	-- Testcase control states
	type tc_ctrl_state_t is (e_TC_START_TC, e_TC_RUN_TC, e_TC_WAIT_COMPLETED, e_TC_COMPLETED, e_TC_ALL_TESTS_COMPLETED);
	signal tc_ctrl_state : tc_ctrl_state_t;
	shared variable test_counter : natural range 0 to 5 :=0;

	shared variable expected_msgout_data  : std_logic_vector(C_BLOCK_SIZE-1 downto 0);

begin

	-----------------------------------------------------------------------------
	-- Clock and reset generation from RSA_accelerator testbench provided in project files. 
	-----------------------------------------------------------------------------
	-- Generates a 50MHz clk
	clk_gen: process is
		begin
			clk <= '1';
			wait for 6 ns;
			clk <= '0';
			wait for 6 ns;
		end process;
	
		-- reset_n generator
		reset_gen: process is
		begin
			reset_n <= '0';
			wait for 20 ns;
			reset_n <= '1';
			wait;
		end process;

	testcase_control: process(clk, reset_n)
		begin
	
			if (reset_n = '0') then
				tc_ctrl_state          <= e_TC_START_TC;
				modulus                <= (others => '0');
				key                <= (others => '0');
				valid_in <= '0';
				ready_out <= '0';

			elsif (clk'event and clk='1') then
	
				-- Default values
				valid_in <= '0';
				ready_out <= '0';

				case tc_ctrl_state is
	
					-- Start a new test case
					when e_TC_START_TC =>
						assert true;
							report "********************************************************************************";
							report "STARTING NEW TESTCASE";
							report "********************************************************************************";


						if (test_counter = 0) then	
							test_counter := test_counter + 1;	
							tc_ctrl_state <= e_TC_RUN_TC;
							message <= x"0a23232323232323232323232323232323232323232323232323232323232323";
							expected_msgout_data := x"85ee722363960779206a2b37cc8b64b5fc12a934473fa0204bbaaf714bc90c01";
							modulus <= x"99925173ad65686715385ea800cd28120288fc70a9bc98dd4c90d676f8ff768d"; --- something valid
							key <= x"0000000000000000000000000000000000000000000000000000000000010001";  
							valid_in <='1';
						
						else
							tc_ctrl_state <= e_TC_ALL_TESTS_COMPLETED;
						end if;  


					-- Run the testcase
					when e_TC_RUN_TC =>
						if(ready_in = '1' and valid_in = '1' ) then
							tc_ctrl_state <= e_TC_WAIT_COMPLETED;
						end if;
	
					-- Wait for all the output messages to arrive
					when e_TC_WAIT_COMPLETED =>
						ready_out <= '1';
						if(valid_out = '1') then
							tc_ctrl_state <= e_TC_COMPLETED;
						end if;
	
					-- Testcase is finished
					when e_TC_COMPLETED =>
							assert true;
								report "COMPARE MSGOUT_DATA";
							assert expected_msgout_data = result
								report "Output message differs from the expected result"
								severity Failure;
							assert true;
								report "MSGOUT_DATA valid";
	
	
					-- All tests have been completed
					when others => --e_TC_ALL_TESTS_COMPLETED =>
						assert true;
							report "********************************************************************************";
							report "ALL TESTS FINISHED SUCCESSFULLY";
							report "********************************************************************************";
							report "ENDING SIMULATION..." severity Failure;
	
				end case;
			end if;
		end process;

	i_exponentiation : entity work.exponentiation
		port map (
			message   => message  ,
			key_e_d   => key      ,
			valid_in  => valid_in ,
			ready_in  => ready_in ,
			ready_out => ready_out,
			valid_out => valid_out,
			result    => result   ,
			key_n   => modulus  ,
			clk       => clk      ,
			reset_n   => reset_n
		);



end expBehave;
