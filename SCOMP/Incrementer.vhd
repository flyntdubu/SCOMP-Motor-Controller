-- Incrementer.vhd (a peripheral module for SCOMP)
-- This device increments a count each time BTN toggles,
-- and provides the count to SCOMP when requested.
-- William Goodall, ECE 2031, 2021-03-16

LIBRARY IEEE;
LIBRARY LPM;

USE IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
USE LPM.LPM_COMPONENTS.ALL;

ENTITY Incrementer IS
	PORT(
		-- At least IO_DATA and a chip select are needed.  Even though
		-- this device will only respond to IN, IO_WRITE is included so
		-- that this device doesn't drive the bus during an OUT.
		BTN         : IN    STD_LOGIC;
		CLK         : IN    STD_LOGIC;
		RESETN      : IN    STD_LOGIC;
		CS          : IN    STD_LOGIC;
		IO_WRITE    : IN    STD_LOGIC;
		IO_DATA     : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END Incrementer;

ARCHITECTURE a OF Incrementer IS
	SIGNAL count : STD_LOGIC_VECTOR(15 downto 0);
	SIGNAL tri_enable : STD_LOGIC; -- enable signal for the tri-state driver
	
	TYPE state_type is (Init, BTN_low, BTN_high);
	SIGNAL state : state_type;
	
	BEGIN
	
	tri_enable <= CS and (not IO_WRITE); -- only drive IO_DATA during IN
	
	-- Use LPM function to create tri-state driver for IO_DATA
	IO_BUS: lpm_bustri
	GENERIC MAP (
		lpm_width => 16
	)
	PORT MAP (
		data     => count,   -- Put the value on IO_DATA during IN
		enabledt => tri_enable,
		tridata  => IO_DATA
	);


	
	PROCESS (RESETN, CLK)
	BEGIN
		IF RESETN = '0' THEN
			count <= x"0000";
			state <= init;
		ELSIF RISING_EDGE(CLK) THEN
			CASE state IS
			
				WHEN init =>
					IF BTN = '0' THEN
						state <= BTN_low;
					ELSE -- BTN = '1'
						state <= BTN_high;
					END IF;
					
				-- Handle the (low -> high) transition, with counter increment
				WHEN BTN_low =>
					IF BTN = '1' THEN
						state <= BTN_high;
						count <= count + 1; -- increment the count
					END IF;
					
				-- Handle the (high -> low) transition, with counter increment
				WHEN BTN_high =>
					IF BTN = '0' THEN
						state <= BTN_low;
						count <= count + 1; -- increment the count
					END IF;					
					
			END CASE;
					
		END IF;
	END PROCESS;

END a;

