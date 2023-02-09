-- MotorController.vhd  :  A closed-loop motor controller
-- ECE 2031, Final Project

library IEEE;
library LPM;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use lpm.lpm_components.ALL;
use work.MotorUtil.all;

entity MotorController IS
	port(
		-- Inputs for A and B quadrature signals.
		A : in std_logic;
		B : in std_logic;
		
		-- Clock and active-low reset
		CLK    : in std_logic;
		RESETN : in std_logic;
		
		-- Signals to the motor controller H-bridge
		motor_in1  : out std_logic;
		motor_in2  : out std_logic;
		motor_stby : out std_logic;
		motor_pwm  : out std_logic; -- PWM signal to the motor
		
		-- SCOMP I/O Signals
		IO_ADDR  : in std_logic_vector(10 downto 0);
		IO_CYCLE : in std_logic;
		IO_WRITE : in std_logic;
		IO_DATA  : inout io_t
	);
end MotorController;

architecture arch of MotorController is

	
	-- PWM signal, pulsed with variable duty cycle.
	signal pwm_out : std_logic := '0';

	-- Keep track of motor position
	signal motor_position : position_t := (others => '0');

	-- Motor drive signal, signed for direction
	signal drive         : drive_t     := DRIVE_ZERO;
	
	-- Keep track of the controller mode
	constant MODE_0_IDLE              : unsigned := x"0000"; -- also the "default mode" for an invalid number
	constant MODE_1_DRIVE             : unsigned := x"0001"; -- Mode 1: Constant direct PWM input mode. Basic on/off/direction control
	constant MODE_2_GO_TO_POS         : unsigned := x"0002"; -- Mode 2: Go to position
	constant MODE_3_CONSTANT_VELOCITY : unsigned := x"0003"; -- Mode 3: Cosntant Velocity
	signal mode : unsigned(15 downto 0) := MODE_0_IDLE;
	
	-- All IO addresses for hardware registers in the motor controller
	constant ADDR_POS                  : unsigned := x"F0"; -- Global: Pulse count of the rotor
	constant ADDR_DRIVE                : unsigned := x"F1"; --       : Current PWM drive speed of the motor
	constant ADDR_MODE                 : unsigned := x"F2"; --       : Current mode number
	constant ADDR_MODE1_DRIVE          : unsigned := x"F3"; -- Mode 1: Drive power
	constant ADDR_MODE2_TARGET_POS     : unsigned := x"F4"; -- Mode 2: Target position
	constant ADDR_MODE2_APPROACH_SPEED : unsigned := x"F5"; --       : approach strength
	constant ADDR_MODE3_VELOCITY       : unsigned := x"F6"; -- Mode 3: Velocity
	constant ADDR_MODE3_APPROACH_SPEED : unsigned := x"F7"; --       : approach strength
	
	-- Mode 1
	signal mode1_drive : drive_t := DRIVE_ZERO; -- output
	
	-- Mode 2
	signal mode2_drive           : drive_t     := DRIVE_ZERO;      -- output
	signal mode2_target_pos      : position_t  := (others => '0'); -- config
	signal mode2_approach_speed  : recovery_t  := x"06";           -- config (set to sensible default from testing)
	
	-- Mode 3
	constant MODE3_SLOWDOWN : integer := 21; -- divide the velocity by 2^MODE3_SLOWDOWN
	signal mode3_target : 
		signed((position_t'length + MODE3_SLOWDOWN) - 1 downto 0) 
		:= (others => '0');                                       -- internal
	signal mode3_drive          : drive_t    := DRIVE_ZERO;      -- output
	signal mode3_velocity       : position_t := (others => '0'); -- config
	signal mode3_approach_speed : recovery_t := x"F0";           -- config (set to sensible default from testing)
	
begin

	-- Set the motor mode depending on the sign of the drive signal
	motor_stby <= '1';
	motor_in1 <= '1' when drive.dir = forwards else '0';
	motor_in2 <= '0' when drive.dir = forwards else '1';
	motor_pwm <= pwm_out;
	
	-- Use quadrature decoder to read motor position
	quadrature_decoder: work.QuadratureDecoder port map (
		A => A, B => B, 
		clk => clk, resetn => resetn,
		position => motor_position
	);
	
	-- Pull in the PWM generator to drive motor's PWM signal
	pwm_encoder: work.PWM_Gen port map (
		clk => clk, resetn => resetn,
		compare => drive.strength,
		output => pwm_out
	);
	
		
	-- Mode 2: Implement control law
	mode2_control: work.ControlSystem port map (
		clk => clk,
		position => motor_position,
		target => mode2_target_pos,
		recovery => mode2_approach_speed,
		drive => mode2_drive
	);
	
	-- Mode 3: Implement position targeting
	-- We'll do this by (basically) using a clock divider. We'll extend the position signal by
	-- MODE3_SLOWDOWN bits to the right, and every clock cycle, add the user-supplied velocity
	-- to the target. This lets the user specify velocity in units of fractional encoder ticks
	-- per clock cycle.
	mode3_targeting: process(clk)
	begin
		if rising_edge(clk) then
			-- Every clock cycle, we add the velocity to the target.
			-- The target has MODE3_SLOWDOWN extra bits on the end, so this velocity is effectively
			-- in units of ((2^-(MODE3_SLOWDOWN) encoder ticks) / (clock cycle)) or so.
			mode3_target <= mode3_target + mode3_velocity;
			
			-- If we're not in Mode 3, reset the target to the current encoder position.
			if mode /= MODE_3_CONSTANT_VELOCITY then
				mode3_target <= shift_left(resize(motor_position, mode3_target'length), MODE3_SLOWDOWN);
			end if;
		end if;
	end process;
	mode3_control: work.ControlSystem port map (
		clk => clk,
		position => motor_position,
		target => mode3_target(mode3_target'left downto mode3_target'right + MODE3_SLOWDOWN), -- just the top bits
		recovery => mode3_approach_speed,
		drive => mode3_drive
	);
	
	-- Multiplex the different drive signals into the motor
	with mode select drive <=
		-- Mode 1: constant power
		mode1_drive when MODE_1_DRIVE,
		
		-- Mode 2: constant position
		mode2_drive when MODE_2_GO_TO_POS,
		
		-- Mode 3: constant velocity
		mode3_drive when MODE_3_CONSTANT_VELOCITY,
		
		-- Mode 0 (fallback): Idle
		DRIVE_ZERO when others;

	-- Handle IO reads and writes from internal registers
	io_handler: process (resetn, io_cycle, io_write) begin
		if rising_edge(io_cycle) then
			if IO_WRITE = '1' then
				
				-- Handle IO writes
				case unsigned(io_addr(7 downto 0)) is
									
					-- Mode selector
					when ADDR_MODE => mode <= unsigned(io_data);
				
					-- Mode 1
					when ADDR_MODE1_DRIVE => mode1_drive <= from_io(io_data);
					
					-- Mode 2
					when ADDR_MODE2_TARGET_POS     => mode2_target_pos <= from_io(io_data);
					when ADDR_MODE2_APPROACH_SPEED => mode2_approach_speed <= from_io(io_data);
					
					-- Mode 3
					when ADDR_MODE3_VELOCITY       => mode3_velocity <= from_io(io_data);
					when ADDR_MODE3_APPROACH_SPEED => mode3_approach_speed <= from_io(io_data);
					
					-- Ignore all other IO addresses. It's not our place to handle them.
					when others => null;
				end case;
				
			else
			
				-- Handle IO reads
				case unsigned(io_addr(7 downto 0)) is
					
					-- General configuration registers
					when ADDR_MODE  => io_data <= std_logic_vector(mode);
					when ADDR_POS   => io_data <= to_io(motor_position);
					when ADDR_DRIVE => io_data <= to_io(drive);
					
					-- Mode 1: read configuration
					when ADDR_MODE1_DRIVE => io_data <= to_io(mode1_drive);
					
					-- Mode 2: read configuration
					-- NOTE: For some reason, these reads can somehow "crash" the de10, with all-zeroes on the display.
					--       I have absolutely no clue why.
					when ADDR_MODE2_TARGET_POS     => io_data <= to_io(mode2_target_pos);
					when ADDR_MODE2_APPROACH_SPEED => io_data <= to_io(mode2_approach_speed);
					
					-- Mode 3: read config
					when ADDR_MODE3_VELOCITY       => io_data <= to_io(mode3_velocity);
					when ADDR_MODE3_APPROACH_SPEED => io_data <= to_io(mode3_approach_speed);
					
					-- Set to floating when we're not driving any data.
					when others => io_data <= (others => 'Z');
				end case;
				
			end if;
		end if;
	end process;
		
		

	
	
end arch;