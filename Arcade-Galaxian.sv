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
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output  	  VGA_DISABLE,

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;

assign VGA_F1    = 0;
assign VGA_SCALER= 0;
assign USER_OUT  = '1;
assign LED_USER  = ioctl_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;
assign BUTTONS   = 0;
assign AUDIO_MIX = 0;
assign FB_FORCE_BLANK = 0;
assign HDMI_FREEZE = 0;
assign VGA_DISABLE = 0;

wire [1:0] ar = status[20:19];

assign VIDEO_ARX = (!ar) ? ((status[2] ) ? 12'd2570 : 12'd2191) : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? ((status[2] ) ? 12'd2191 : 12'd2570) : 12'd0;

`include "build_id.v" 
localparam CONF_STR = {
	"A.GALAXN;;",
	"H0OJK,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"H0O2,Orientation,Vert,Horz;",
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"O6,Flip Vertical,Off,On;",
	"-;",
	"H1OR,Autosave Hiscores,Off,On;",
	"P1,Pause options;",
	"P1OP,Pause when OSD is open,On,Off;",
	"P1OQ,Dim video after 10s,On,Off;",
	"-;",
	"DIP;",
	"-;",
	"R0,Reset;",
	"J1,Fire,Start 1P,Start 2P,Coin,Test,Pause;",
	"jn,A,Start,Select,R,L,C;",
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
wire        ioctl_upload;
wire        ioctl_upload_req;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din;
wire  [7:0] ioctl_index;


wire [15:0] joystick_0,joystick_1;
wire [15:0] joy = joystick_0 | joystick_1;

wire [21:0] gamma_bus;


hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.buttons(buttons),
	.status(status),
	.status_menumask({~hs_configured,direct_video}),
	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),
	.video_rotated(video_rotated),

	.ioctl_upload(ioctl_upload),
	.ioctl_upload_req(ioctl_upload_req),
	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_din(ioctl_din),
	.ioctl_index(ioctl_index),


	.joystick_0(joystick_0),
	.joystick_1(joystick_1)
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



wire m_start1 = joy[5];
wire m_start2 = joy[6];
wire m_coin   = joy[7];
wire m_test   = joy[8];

wire m_up     = joy[3];
wire m_down   = joy[2];
wire m_left   = joy[1];
wire m_right  = joy[0];
wire m_fire   = joy[4];

wire m_up_2     = joy[3];
wire m_down_2   = joy[2];
wire m_left_2   = joy[1];
wire m_right_2  = joy[0];
wire m_fire_2   = joy[4];

wire m_pause    = joy[9];

// PAUSE SYSTEM
wire				pause_cpu;
wire [8:0]		rgb_out;
pause #(3,3,3,24) pause (
	.*,
	.user_button(m_pause),
	.pause_request(hs_pause),
	.options(~status[26:25])
);

wire hblank, vblank;
wire hs, vs;
wire [2:0] r,g,b;

reg ce_pix;
always @(posedge clk_48) begin
        reg [2:0] div;

        div <= div + 1'd1;
        ce_pix <= !div;
end

wire no_rotate = status[2] | direct_video;

wire flip = 0;
wire video_rotated;
screen_rotate screen_rotate (.*);

arcade_video #(257,9) arcade_video
(
        .*,

        .clk_video(clk_48),

        .RGB_in(rgb_out),
        .HBlank(hblank),
        .VBlank(vblank),
        .HSync(hs),
        .VSync(vs),

        .fx(status[5:3])
);


wire [7:0] audio_a, audio_b,audio_c;
wire [10:0] audio = pause_cpu ? 11'b0 : {1'b0, audio_b, 2'b0} + {3'b0, audio_a} + {2'b00, audio_c, 1'b0};

assign AUDIO_L = {audio, 5'd0};
assign AUDIO_R = {audio, 5'd0};
assign AUDIO_S = 0;

// dips for mra
wire [7:0] sw0_galaxian = sw[0] & { m_test, 1'b1 , 1'b1, m_fire, m_right, m_left, mod_pisces & m_coin, ~mod_pisces & m_coin};
wire [7:0] sw1_galaxian = sw[1] & { 3'b111, m_fire_2, m_right_2, m_left_2, m_start2, m_start1};

wire [7:0] sw0_azurian = sw[0] & { 1'b0 , m_fire_2, m_fire, m_coin, m_left,m_right,m_up,m_down};
wire [7:0] sw1_azurian = sw[1] & { 2'b11, m_left_2,m_right_2,m_up_2,m_down_2,m_start2,m_start1};

wire [7:0] sw0_orbitron = sw[0] & { m_up, m_down, m_down_2,m_fire,m_right,m_left,1'b0,m_coin};
wire [7:0] sw1_orbitron = sw[1] & { m_up_2, 2'b11, m_fire, m_right, m_left, m_start2,m_start1};

wire [7:0] sw0_devilfsh = sw[0] & { m_up, m_up_2, m_down,m_fire,m_right,m_left,1'b0, m_coin};
wire [7:0] sw1_devilfsh = sw[1] & { 2'b11,  m_down_2,  m_fire_2, m_right_2, m_left_2, m_start2,m_start1};

wire [7:0] sw0_mrdonigh = sw[0] & { m_test, 1'b1 , 1'b1, m_fire, m_right, m_left, 1'b0, m_coin};
wire [7:0] sw1_mrdonigh = sw[1] & { 3'b111, m_fire, m_down, m_up, m_start2,m_start1};

//wire [7:0] sw0_chewing = sw[0] & { btn_coin_2, 1'b1 , 1'b1, m_fire, m_right, m_left, 1'b1, m_coin};
//wire [7:0] sw1_chewing = sw[1] & { 7'b1111111, m_start1};

wire [7:0] sw0_victory = sw[0] & { m_up, m_up_2 , m_down, m_fire, m_right, m_left, m_down_2, m_coin};
wire [7:0] sw1_victory = sw[1] & { 3'b111, m_fire_2, m_right_2, m_left_2, m_start2, m_start1};

wire [7:0] sw0_warofbug = sw[0] & { m_up,  m_down, 1'b1, m_fire, m_right, m_left, m_up_2, m_coin};
wire [7:0] sw1_warofbug = sw[1] & { 2'b11, m_down, m_fire_2, m_right_2, m_left_2, m_start2, m_start1};

wire rotate_ccw_orig = (mod_devilfsh|mod_mooncr| mod_omega|mod_orbitron|mod_victory|mod_lucktoday);
wire rotate_ccw = status[6] ? ~rotate_ccw_orig : rotate_ccw_orig;
// zigzag??

wire mod_orb_war  = mod_orbitron;
wire mod_dev_trip = mod_devilfsh | mod_tripledr | mod_lucktoday;

wire [7:0] m_dip = sw[2] ;
wire [7:0] sw0 = mod_warofbug ? sw0_warofbug : mod_victory ? sw0_victory : mod_azurian ? sw0_azurian : mod_orbitron ? sw0_orbitron : mod_dev_trip ? sw0_devilfsh : mod_mrdonigh ? sw0_mrdonigh : sw0_galaxian;
wire [7:0] sw1 = mod_warofbug ? sw1_warofbug : mod_victory ? sw1_victory : mod_azurian ? sw1_azurian : mod_orbitron ? sw1_orbitron : mod_dev_trip ? sw1_devilfsh : mod_mrdonigh ? sw1_mrdonigh : sw1_galaxian;

wire rom_download = ioctl_download & !ioctl_index;
wire reset = (RESET | status[0] | buttons[1] | rom_download);

galaxian galaxian
(
	.W_CLK_12M(clk_sys),
	.W_CLK_6M(clk_6),
	.I_RESET(reset),

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

	.hs_address(hs_address),
	.hs_data_out(hs_data_out),
	.hs_data_in(hs_data_in),
	.hs_write(hs_write_enable),

	.pause_cpu_n(~pause_cpu),
	
	.mod_mooncr(mod_mooncr),
	.mod_devilfsh(mod_devilfsh),
	.mod_pisces(mod_pisces),
	.mod_uniwars(mod_uniwars),
	.mod_kingbal(mod_kingbal),
	.mod_orbitron(mod_orbitron),
	
	.Flip_Vertical(status[6]),

	.W_SDAT_A(audio_a),
	.W_SDAT_B(audio_b),
	.W_SDAT_C(audio_c)
);

// HISCORE SYSTEM
// --------------
wire [9:0]hs_address;
wire [7:0] hs_data_in;
wire [7:0] hs_data_out;
wire hs_write_enable;
wire hs_pause;
wire hs_configured;

hiscore #(
	.HS_ADDRESSWIDTH(10),
	.CFG_LENGTHWIDTH(2)
) hi (
	.*,
	.clk(clk_sys),
	.paused(pause_cpu),
	.autosave(status[27]),
	.ram_address(hs_address),
	.data_from_ram(hs_data_out),
	.data_to_ram(hs_data_in),
	.data_from_hps(ioctl_dout),
	.data_to_hps(ioctl_din),
	.ram_write(hs_write_enable),
	.ram_intent_read(),
	.ram_intent_write(),
	.pause_cpu(hs_pause),
	.configured(hs_configured)
);

endmodule
