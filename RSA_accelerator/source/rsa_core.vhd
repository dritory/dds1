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
		C_BLOCK_SIZE          : integer := 256
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

architecture behaviour of rsa_core is
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


begin


	--Shift register for e_i, and counter e_counter for msgout_ready signal
	e_reg : process(clk, key_e_d, e_count, multiplier_count)
	begin
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
					msgout_valid <= '1';
					e_count <= C_BLOCK_SIZE;
				else
					msgout_valid <= '0';
				end if;

				multiplier_count <= C_BLOCK_SIZE;
			end if;
		end if;
	end process ; 

-- exponentiation loop

	-- multiplexer for M and sum1 from p1 register.  
	mux1 : process(msgin_data, sum1, msgin_last)
	begin	
		if rising_edge(clk) then
			if msgin_last = '0' then
				mux1_out <= sum1 (C_BLOCK_SIZE -1 downto 0);
			else
				mux1_out <= msgin_data (C_BLOCK_SIZE -1 downto 0);
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
				mN => key_n ,
				m2N => 2*key_n ,
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
				mux2_out <= '0' (C_BLOCK_SIZE -2 downto 0) & '1';
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
		mN => key_n ,
		m2N => 2*key_n ,
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

-- send relevant data to the msg_out interface. 

end behaviour;
