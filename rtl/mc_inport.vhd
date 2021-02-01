-----------------------------------------------------------------------
-- FPGA MOONCRESTA INPORT
--
-- Version : 1.01
--
-- Copyright(c) 2004 Katsumi Degawa , All rights reserved
--
-- Important !
--
-- This program is freeware for non-commercial use.
-- The author does not guarantee this program.
-- You can use this at your own risk.
--
-- 2004-4-30  galaxian modify by K.DEGAWA
-----------------------------------------------------------------------

--    DIP SW        0     1     2     3     4     5
-----------------------------------------------------------------
--  COIN CHUTE
-- 1 COIN/1 PLAY   1'b0  1'b0
-- 2 COIN/1 PLAY   1'b1  1'b0
-- 1 COIN/2 PLAY   1'b0  1'b1
-- FREE PLAY       1'b1  1'b1
--   BOUNS
--                             1'b0  1'b0
--                             1'b1  1'b0
--                             1'b0  1'b1
--                             1'b1  1'b1
--   LIVES
--     2                                   1'b0
--     3                                   1'b1
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

entity MC_INPORT is
port (
	W_SW0_DI	: in std_logic_vector(7 downto 0) := (others => '0');
	W_SW1_DI	: in std_logic_vector(7 downto 0) := (others => '0');
	W_DIP_DI	: in std_logic_vector(7 downto 0) := (others => '0');
	I_SW0_OE   : in  std_logic;
	I_SW1_OE   : in  std_logic;
	I_DIP_OE   : in  std_logic;
	I_SPEECH_DIP : in std_logic;
	I_RAND     : in  std_logic;   --  for kingball noise check
	mod_kingbal:in std_logic;
	O_D        : out std_logic_vector(7 downto 0)
);

end;

architecture RTL of MC_INPORT is
        signal W_SW0_DO : std_logic_vector(7 downto 0) := (others => '0');
        signal W_SW1_DO : std_logic_vector(7 downto 0) := (others => '0');
        signal W_DIP_DO : std_logic_vector(7 downto 0) := (others => '0');

        signal W_SW0    : std_logic_vector(7 downto 0) := (others => '0');
    	  signal W_SW1    : std_logic_vector(7 downto 0) := (others => '0');

		  
begin


   ioports: process(W_SW0_DO,W_SW1_DO,W_DIP_DO,I_SW0_OE,W_SW0_DI,I_SW1_OE,W_SW1_DI,I_DIP_OE,W_DIP_DI,I_RAND,mod_kingbal,I_SPEECH_DIP)
	begin

			W_SW0 <= W_SW0_DI;
			W_SW1 <= W_SW1_DI;
		

		if mod_kingbal = '1' then
			if I_SPEECH_DIP = '1' then
				W_SW0(6) <= '1'; -- Speech enable
			end if;
			W_SW1(5) <= I_RAND; -- kingball checks for randomness at $2529
		end if;

		if I_SW0_OE = '0' then W_SW0_DO <= x"00"; else W_SW0_DO <= W_SW0; end if;
		if I_SW1_OE = '0' then W_SW1_DO <= x"00"; else W_SW1_DO <= W_SW1; end if;
		if I_DIP_OE = '0' then W_DIP_DO <= x"00"; else W_DIP_DO <= W_DIP_DI; end if;

		O_D      <= W_SW0_DO or W_SW1_DO or W_DIP_DO ;		

	end process;
end RTL;
