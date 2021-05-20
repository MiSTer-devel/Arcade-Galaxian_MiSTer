//============================================================================
//  Arcade: Galaxian
//
//  Port to MiSTer
//  Copyright (C) 2017 Sorgelig
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        VGA_CLK,

	//Multiple resolutions are supported using different VGA_CE rates.
	//Must be based on CLK_VIDEO
	output        VGA_CE,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,

	//Base video clock. Usually equals to CLK_SYS.
	output        HDMI_CLK,

	//Multiple resolutions are supported using different HDMI_CE rates.
	//Must be based on CLK_VIDEO
	output        HDMI_CE,

	output  [7:0] HDMI_R,
	output  [7:0] HDMI_G,
	output  [7:0] HDMI_B,
	output        HDMI_HS,
	output        HDMI_VS,
	output        HDMI_DE,   // = ~(VBlank | HBlank)
	output  [1:0] HDMI_SL,   // scanlines fx

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output  [7:0] HDMI_ARX,
	output  [7:0] HDMI_ARY,

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	
	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT
	
	
);

assign VGA_F1    = 0;
assign USER_OUT  = '1;
assign LED_USER  = ioctl_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;

assign HDMI_ARX = status[1] ? 8'd16 : status[2] ? 8'd4 : 8'd3;
assign HDMI_ARY = status[1] ? 8'd9  : status[2] ? 8'd3 : 8'd4;

`include "build_id.v" 
localparam CONF_STR = {
	"A.GALAXN;;",
	"H0O1,Aspect Ratio,Original,Wide;",
	"H0O2,Orientation,Vert,Horz;",
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"-;",
	"DIP;",
	"-;",
	"R0,Reset;",
	"J1,Fire,Start 1P,Start 2P,Coin;",
	"jn,A,Start,Select,R;",
	"jp,B,Start,,Select;",
	"V,v",`BUILD_DATE
};

////////////////////   CLOCKS   ///////////////////

wire clk_48, clk_sys, clk_6;
wire pll_locked;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_48),
	.outclk_1(clk_sys), // 12
	.outclk_2(clk_6),
	.locked(pll_locked)
);

///////////////////////////////////////////////////

wire [31:0] status;
wire  [1:0] buttons;
wire        forced_scandoubler;
wire        direct_video;


wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_index;


wire [10:0] ps2_key;

wire [15:0] joystick_0,joystick_1;
wire [15:0] joy = joystick_0 | joystick_1;

wire [21:0] gamma_bus;


hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

	.buttons(buttons),
	.status(status),
	.status_menumask(direct_video),
	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),


	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_index(ioctl_index),


	.joystick_0(joystick_0),
	.joystick_1(joystick_1),
	.ps2_key(ps2_key)
);

reg mod_galaxian = 0;
reg mod_mooncr = 0;
reg mod_azurian = 0;
reg mod_blackhole = 0;
reg mod_catacomb = 0;
reg mod_chewingg    = 0;
reg mod_devilfsh = 0;
reg mod_kingbal= 0;
reg mod_mrdonigh= 0;
reg mod_omega= 0;
reg mod_orbitron= 0;
reg mod_pisces= 0;
reg mod_uniwars= 0;
reg mod_victory= 0;
reg mod_warofbug= 0;
reg mod_zigzag= 0;
reg mod_tripledr= 0;
reg mod_lucktoday= 0;

always @(posedge clk_sys) begin
	reg [7:0] mod = 0;
	if (ioctl_wr & (ioctl_index==1)) mod <= ioctl_dout;
	
	mod_galaxian	<= (mod == 0);
	mod_mooncr	<= (mod == 1);
	mod_azurian	<= (mod == 2);
	mod_blackhole	<= (mod == 3);
	mod_catacomb	<= (mod == 4);
	mod_chewingg	<= (mod == 5);
	mod_devilfsh	<= (mod == 6);
	mod_kingbal	<= (mod == 7);
	mod_mrdonigh	<= (mod == 8);
	mod_omega	<= (mod == 9);
	mod_orbitron	<= (mod == 10);
	mod_pisces	<= (mod == 11);
	mod_uniwars	<= (mod == 12);
	mod_victory	<= (mod == 13);
	mod_warofbug	<= (mod == 14);
	mod_zigzag	<= (mod == 15);
	mod_tripledr	<= (mod == 16);
	mod_lucktoday   <= (mod == 17);
end


reg [7:0] sw[8];
always @(posedge clk_sys) if (ioctl_wr && (ioctl_index==254) && !ioctl_addr[24:3]) sw[ioctl_addr[2:0]] <= ioctl_dout;


wire       pressed = ps2_key[9];
wire [8:0] code    = ps2_key[8:0];
always @(posedge clk_sys) begin
	reg old_state;
	old_state <= ps2_key[10];
	
	if(old_state != ps2_key[10]) begin
		casex(code)
			'hX75: btn_up          <= pressed; // up
			'hX72: btn_down        <= pressed; // down
			'hX6B: btn_left        <= pressed; // left
			'hX74: btn_right       <= pressed; // right

			'h029: btn_fire        <= pressed; // space
			'h014: btn_fire        <= pressed; // ctrl

			'h005: btn_start_1     <= pressed; // F1
			'h006: btn_start_2     <= pressed; // F2
			// JPAC/IPAC/MAME Style Codes
			'h016: btn_start_1     <= pressed; // 1
			'h01E: btn_start_2     <= pressed; // 2
			'h02E: btn_coin_1      <= pressed; // 5
			'h036: btn_coin_2      <= pressed; // 6
			'h02D: btn_up_2        <= pressed; // R
			'h02B: btn_down_2      <= pressed; // F
			'h023: btn_left_2      <= pressed; // D
			'h034: btn_right_2     <= pressed; // G
			'h01C: btn_fire_2      <= pressed; // A
			'h02C: btn_test        <= pressed; // T
		endcase
	end
end

reg btn_up    = 0;
reg btn_down  = 0;
reg btn_right = 0;
reg btn_left  = 0;
reg btn_fire  = 0;
reg btn_one_player  = 0;
reg btn_two_players = 0;

wire m_up     = btn_up    | joy[3];
wire m_down   = btn_down  | joy[2];
wire m_left   = btn_left  | joy[1];
wire m_right  = btn_right | joy[0];
wire m_fire   = btn_fire  | joy[4];

reg btn_start_1=0;
reg btn_start_2=0;
reg btn_coin_1=0;
reg btn_coin_2=0;
reg btn_up_2=0;
reg btn_down_2=0;
reg btn_left_2=0;
reg btn_right_2=0;
reg btn_fire_2=0;
reg btn_test=0;

wire no_rotate = status[2] | direct_video;

wire m_start1 = btn_start_1 | joy[5];
wire m_start2 = btn_start_2 | joy[6];
wire m_coin   = btn_coin_1 | btn_coin_2 | joy[7];

wire m_up_2     = btn_up_2    | joy[3];
wire m_down_2   = btn_down_2  | joy[2];
wire m_left_2   = btn_left_2  | joy[1];
wire m_right_2  = btn_right_2 | joy[0];
wire m_fire_2   = btn_fire_2  | joy[4];

wire hblank, vblank;
wire hs, vs;
wire [2:0] r,g;
wire [2:0] b;

reg ce_pix;
always @(posedge clk_48) begin
        reg [2:0] div;

        div <= div + 1'd1;
        ce_pix <= !div;
end


arcade_video #(257,224,9) arcade_video
(
        .*,

        .clk_video(clk_48),

        .RGB_in({r,g,b}),
        .HBlank(hblank),
        .VBlank(vblank),
        .HSync(hs),
        .VSync(vs),

        .fx(status[5:3])
);


wire [7:0] audio_a, audio_b,audio_c;
wire [10:0] audio = {1'b0, audio_b, 2'b0} + {3'b0, audio_a} + {2'b00, audio_c, 1'b0};

assign AUDIO_L = {audio, 5'd0};
assign AUDIO_R = {audio, 5'd0};
assign AUDIO_S = 0;

// dips for mra
wire [7:0] sw0_galaxian = sw[0] & { btn_test, 1'b1 , 1'b1, m_fire, m_right, m_left, mod_pisces & m_coin, ~mod_pisces & m_coin};
wire [7:0] sw1_galaxian = sw[1] & { 3'b111, m_fire_2, m_right_2, m_left_2, m_start2, m_start1};

wire [7:0] sw0_azurian = sw[0] & { 1'b0 , m_fire_2, m_fire, m_coin, m_left,m_right,m_up,m_down};
wire [7:0] sw1_azurian = sw[1] & { 2'b11, m_left_2,m_right_2,m_up_2,m_down_2,m_start2,m_start1};

wire [7:0] sw0_orbitron = sw[0] & { m_up, m_down, m_down_2,m_fire,m_right,m_left,1'b0,m_coin};
wire [7:0] sw1_orbitron = sw[1] & { m_up_2, 2'b11, m_fire, m_right, m_left, m_start2,m_start1};

wire [7:0] sw0_devilfsh = sw[0] & { m_up, m_up_2, m_down,m_fire,m_right,m_left,1'b0, m_coin};
wire [7:0] sw1_devilfsh = sw[1] & { 2'b11,  m_down_2,  m_fire_2, m_right_2, m_left_2, m_start2,m_start1};

wire [7:0] sw0_mrdonigh = sw[0] & { btn_test, 1'b1 , 1'b1, m_fire, m_right, m_left, 1'b0, m_coin};
wire [7:0] sw1_mrdonigh = sw[1] & { 3'b111, m_fire, m_down, m_up, m_start2,m_start1};

//wire [7:0] sw0_chewing = sw[0] & { btn_coin_2, 1'b1 , 1'b1, m_fire, m_right, m_left, 1'b1, m_coin};
//wire [7:0] sw1_chewing = sw[1] & { 7'b1111111, m_start1};

wire [7:0] sw0_victory = sw[0] & { m_up, m_up_2 , m_down, m_fire, m_right, m_left, m_down_2, m_coin};
wire [7:0] sw1_victory = sw[1] & { 3'b111, m_fire_2, m_right_2, m_left_2, m_start2, m_start1};

wire [7:0] sw0_warofbug = sw[0] & { m_up,  m_down, 1'b1, m_fire, m_right, m_left, m_up_2, m_coin};
wire [7:0] sw1_warofbug = sw[1] & { 2'b11, m_down, m_fire_2, m_right_2, m_left_2, m_start2, m_start1};

wire rotate_ccw = (mod_devilfsh|mod_mooncr| mod_omega|mod_orbitron|mod_victory|mod_lucktoday);

// zigzag??

wire mod_orb_war  = mod_orbitron;
wire mod_dev_trip = mod_devilfsh | mod_tripledr | mod_lucktoday;

wire [7:0] m_dip = sw[2] ;
wire [7:0] sw0 = mod_warofbug ? sw0_warofbug : mod_victory ? sw0_victory : mod_azurian ? sw0_azurian : mod_orbitron ? sw0_orbitron : mod_dev_trip ? sw0_devilfsh : mod_mrdonigh ? sw0_mrdonigh : sw0_galaxian;
wire [7:0] sw1 = mod_warofbug ? sw1_warofbug : mod_victory ? sw1_victory : mod_azurian ? sw1_azurian : mod_orbitron ? sw1_orbitron : mod_dev_trip ? sw1_devilfsh : mod_mrdonigh ? sw1_mrdonigh : sw1_galaxian;

galaxian galaxian
(
	.W_CLK_12M(clk_sys),
	.W_CLK_6M(clk_6),
	.I_RESET(RESET | status[0] | buttons[1]),

	// NOTE: mame order matches order in mc_inport, mc_inport reorders these
	.W_SW0_DI(sw0),
	.W_SW1_DI(sw1),
	.W_DIP_DI(m_dip),

	.W_R(r),
	.W_G(g),
	.W_B(b),
	.W_H_SYNC(hs),
	.W_V_SYNC(vs),
	.HBLANK(hblank),
	.VBLANK(vblank),

	.dn_addr(ioctl_addr[15:0]),
	.dn_data(ioctl_dout),
	.dn_wr(ioctl_wr && !ioctl_index),

	.mod_mooncr(mod_mooncr),
	.mod_devilfsh(mod_devilfsh),
	.mod_pisces(mod_pisces),
	.mod_uniwars(mod_uniwars),
	.mod_kingbal(mod_kingbal),
	.mod_orbitron(mod_orbitron),

	.W_SDAT_A(audio_a),
	.W_SDAT_B(audio_b),
	.W_SDAT_C(audio_c)
);

endmodule
