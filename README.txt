---------------------------------------------------------------------------------
-- 
-- Arcade: Galaxian port to MiSTer by Sorgelig
-- 15 November 2017
-- 
---------------------------------------------------------------------------------
-- A simulation model of Galaxian hardware
-- Copyright(c) 2004 Katsumi Degawa
---------------------------------------------------------------------------------
-- 
-- Support screen and controls rotation on HDMI output.
-- Only controls are rotated on VGA output.
-- 
-- 
-- Keyboard inputs :
--
--   F2         : Coin + Start 2 players
--   F1         : Coin + Start 1 player
--   SPACE,CTRL : Fire
--   LEFT,RIGHT : Movements
--
-- MAME/IPAC/JPAC Style Keyboard inputs:
--   5           : Coin 1
--   6           : Coin 2
--   1           : Start 1 Player
--   2           : Start 2 Players
--   D,G         : Player 2 Movements
--   A           : Player 2 Fire
--
--
-- Joystick support.
-- 
---------------------------------------------------------------------------------

                                *** Attention ***

ROMs are not included. In order to use this arcade, you need to provide the
correct ROMs.

To simplify the process .mra files are provided in the releases folder, that
specifies the required ROMs with checksums. The ROMs .zip filename refers to the
corresponding file of the M.A.M.E. project.

Please refer to https://github.com/MiSTer-devel/Main_MiSTer/wiki/Arcade-Roms for
information on how to setup and use the environment.

Quickreference for folders and file placement:

/_Arcade/<game name>.mra
/_Arcade/cores/<game rbf>.rbf
/_Arcade/mame/<mame rom>.zip
/_Arcade/hbmame/<hbmame rom>.zip
