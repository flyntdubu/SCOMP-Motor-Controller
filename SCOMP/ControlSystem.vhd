-- ControlSystem.vhd  :: Implementation of a closed-loop control law
-- 2021.03.20
--
-- Generates a square wave with duty cycle dependant on value
-- sent from SCOMP.

library ieee;
library lpm;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use lpm.lpm_components.ALL;
use work.MotorUtil.all;

entity ControlSystem is
port (
		clk: in std_logic;
	
		-- The current position (real-world measurement)
		position: in position_t;
		
		-- The desired position (software input)
		target: in position_t;
		
		-- How aggressively we should correct position (software input)
		-- This is the P-control coefficient.
		recovery: in recovery_t;
		
		-- The drive signal generated by the control law
		drive: out drive_t
	);
end ControlSystem;

architecture arch of ControlSystem is
	
	-- Keep track of the signed error between current/target position
	signal error_amt: unsigned(position_t'length-1 downto 0);
	
	-- Product of error and recovery
	signal correction: unsigned((position_t'length + strength_t'length)-1 downto 0);

	-- Clamp the correction value to the max. motor drive, and some minimum.
	constant MAX_CORRECTION: strength_t := MAX_STRENGTH;
	constant MIN_CORRECTION: strength_t := x"00"; -- just barely strong enough to drive the motor
	
begin

	-- Continuously calculate error direction, send to motor.
	drive.dir <= forwards when target > position else reverse;
	
	-- Continuously calculate error magnitude
	error_amt <= unsigned(abs(target - position));
	
	-- Continuously calculate the correction to apply.
	-- Note that the `correction` signal is wide enough to accomodate the 
	-- full multiplication without overflow.
	correction <= error_amt * recovery;
	
	
	update_drive: process (clk) 
	begin
		if rising_edge(clk) then
			
			-- Clamp the correction value to a reasonable range.
			if    error_amt <= x"01"          then drive.strength <= (others => '0');
			elsif correction > MAX_CORRECTION then drive.strength <= MAX_CORRECTION;
			elsif correction < MIN_CORRECTION then drive.strength <= MIN_CORRECTION;
			else                                   drive.strength <= resize(correction, strength_t'length);
			end if;
			
		end if;
	end process;
end arch;


