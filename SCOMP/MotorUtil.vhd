-- MotorUtil.vhdl :: Types and utilities for motor control components.
-- ECE 2031, Final Project

library IEEE;
library LPM;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use lpm.lpm_components.ALL;

package MotorUtil is
	-- Quadrature signals are 16-bit signed integers
	subtype position_t is signed(15 downto 0);
	
	-- PWM drive strength represented by 8-bit unsigned signal.
	-- The direction is stored separately, in a direciton_t.
	-- We'll parse 2's comp in the IO handler.
	subtype strength_t is unsigned(7 downto 0);
	constant MAX_STRENGTH: strength_t := (others => '1');
	
	-- Proportional-control recovery strength
	subtype recovery_t is unsigned(7 downto 0);
		
	-- Store the direction of the PWM speed separately.
	subtype direction_t is std_logic;
	constant forwards : std_logic := '1';
	constant reverse : std_logic := '0';
	
	-- Signed-magnitude velocity representation
	type drive_t is record
		dir: direction_t;
		strength: strength_t;
	end record drive_t;
	constant DRIVE_ZERO : drive_t := (dir => forwards, strength => (others => '0'));
	
	-- Convert things to and from IO bus representation
	subtype io_t is std_logic_vector(15 downto 0);
	
	-- drive_t i/o
	function to_io (drive: drive_t) return io_t;
	function from_io (io: io_t) return drive_t;
	
	-- strength_t (and also recovery_t with casting) i/o
	function to_io (strength: strength_t) return io_t;
	function from_io (io: io_t) return strength_t;
	
	-- position_t i/o
	function to_io (position: position_t) return io_t;
	function from_io (io: io_t) return position_t;
	
end package MotorUtil;

package body MotorUtil is

	-- drive_t i/o
	function to_io(drive: drive_t) return io_t is
	begin
		case drive.dir is
		
			-- 2's complement positive/zero
			when forwards => 
				return std_logic_vector(resize(signed(drive.strength), io_t'length));
			
			-- 2's complement negated
			when reverse =>
				return std_logic_vector(-resize(signed(drive.strength), io_t'length));
		
		end case;
	end to_io;
	function from_io(io: io_t) return drive_t is
		variable dir      : direction_t;
		variable strength : strength_t;
	begin
	
		-- Check 2's complement sign
		if signed(io) >= to_signed(0, io'length) 
		then dir := forwards;
		else dir := reverse;
		end if;
		
		strength := resize(unsigned(abs(signed(io))), strength_t'length);
		
		return (dir => dir, strength => strength);
	end from_io;

	-- strength_t i/o
	function to_io(strength: strength_t) return io_t is
	begin return std_logic_vector(resize(unsigned(strength), io_t'length));
	end to_io;
	function from_io(io: io_t) return strength_t is
	begin return strength_t(resize(unsigned(io), strength_t'length));
	end from_io;
	
	-- position_t i/o
	function to_io(position: position_t) return io_t is
	begin return std_logic_vector(resize(position, io_t'length));
	end to_io;
	function from_io(io: io_t) return position_t is
	begin return position_t(resize(signed(io), position_t'length));
	end from_io;

end MotorUtil;