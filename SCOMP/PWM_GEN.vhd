-- PWM_GEN.VHD (a peripheral module for SCOMP)
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

entity PWM_GEN is
    port(
		  clk    : in std_logic;
        resetn : in std_logic;
		  
		  -- Signal to compare the counter to, generating variable duty cycle.
		  compare  : in strength_t;
		  
		  -- The PWM signal to output
		  output   : out std_logic
    );
end PWM_GEN;

architecture a of PWM_GEN is
    signal count : strength_t := (others => '0');
 begin

    pwm_generator: process (clk)
    begin

        -- Something to consider (eventually): should anything happen at reset?

        -- Create a counter and a comparator that control the output
        if (rising_edge(clk)) then

				-- Increment the PWM count
            count <= count + 1;

            -- Compare the count with the comparison point. Between 0 and `compare`, the output goes high.
				if count < compare then
					output <= '1';
				else
					output <= '0';
				end if;

        end if;
    end process;
end a;