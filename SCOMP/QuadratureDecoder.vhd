-- QuadratureDecoder.vhd (a peripheral module for SCOMP)
-- This device decodes a quadrature signal into an approximate location.
-- William Goodall, ECE 2031, 2021-03-16

LIBRARY IEEE;
LIBRARY LPM;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use lpm.lpm_components.ALL;
use work.MotorUtil.all;

ENTITY QuadratureDecoder IS
	PORT(
		-- Inputs for A and B quadrature signals.
		A : in std_logic;
		B : in std_logic;
		
		-- Clock and active-low reset
		clk    : in std_logic;
		resetn : in std_logic;
		
		-- Output the motor position
		position : out position_t := (others => '0')
	);
END QuadratureDecoder;

ARCHITECTURE a OF QuadratureDecoder IS
	
	-- Concatenation of A and B quadrature signals
	-- We'll maintain the value used on the current and last clock cycle,
	-- in order to debounce the signals coming from the switches.
	SIGNAL AB            : std_logic_vector(1 downto 0); -- value from last cycle
	SIGNAL AB_future_1   : std_logic_vector(1 downto 0);
	SIGNAL AB_future_2   : std_logic_vector(1 downto 0); -- current input value

	-- Keep track of the rotation pulse count
	SIGNAL count : signed(15 downto 0);

	-- Define the quadrature decoding state machine
	TYPE state_type is (Init, AB_00, AB_01, AB_11, AB_10);
	SIGNAL state : state_type;
	
BEGIN

	-- Output the current count as a position
	position <= count;

	-- Synchronize the A and B inputs to our clock, by delaying the AB signal by
	-- one clock cycle.
	AB_future_2 <= A & B; -- delay current inputs by 2 clock edges
	PROCESS (CLK)
	BEGIN
		IF rising_edge(clk) THEN
			AB <= AB_future_1; -- assign 2-cycle-old inputs into AB
			AB_future_1 <= AB_future_2;
		END IF;
	END PROCESS;

	-- Calculate the next state (and side effect of incrementing/decrementing 
	-- `count`) for our state machine.
	process (resetn, clk)
	begin
		-- Reset logic: zero out the count, go back to Init.
		if resetn = '0' then
			count <= (others => '0');
			state <= init;
		elsif rising_edge(clk) then
			case state is
				
				-- Init state: dispatch to the right state depending on the current
				-- position of the rotor.
				when init =>
					if    AB = "00" then state <= AB_00;
					elsif AB = "01" then state <= AB_01;
					elsif AB = "11" then state <= AB_11;
					elsif AB = "10" then state <= AB_10;
					end if;
				
				-- Handle transitions from 00 
				WHEN AB_00 => 
					IF    AB = "01" THEN state <= AB_01; count <= count + 1;
					ELSIF AB = "10" THEN state <= AB_10; count <= count - 1;
					ELSIF AB = "11" THEN state <= AB_11; -- ideally never happens

					END IF;
					
				-- Handle transitions from 01
				WHEN AB_01 => 
					IF    AB = "11" THEN state <= AB_11; count <= count + 1;
				   ELSIF AB = "00" THEN state <= AB_00; count <= count - 1;
					ELSIF AB = "10" THEN state <= AB_10; -- ideally never happens
					END IF;
				
				-- Handle transitions from 11
				WHEN AB_11 => 
					IF    AB = "10" THEN state <= AB_10; count <= count + 1;
					ELSIF AB = "01" THEN state <= AB_01; count <= count - 1;
					ELSIF AB = "00" THEN state <= AB_00; -- ideally never happens
					END IF;
					
				-- Handle transitions from 10
				WHEN AB_10 => 
					IF    AB = "00" THEN state <= AB_00; count <= count + 1;
					ELSIF AB = "11" THEN state <= AB_11; count <= count - 1;
					ELSIF AB = "01" THEN state <= AB_01; -- ideally never happens
					END IF;
					
			end case;		
		end if;
	end process;

end a;

