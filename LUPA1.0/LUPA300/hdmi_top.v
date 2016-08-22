`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:46:09 11/30/2015 
// Design Name: 
// Module Name:    hdmi_top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module hdmi_top(
					clock_pixel,
					clock_TMDS,
					iRed,
					iGreen,
					iBlue,
					
					oRequest,
					SYNC_V,
					TMDSp,
					TMDSn,
					TMDSp_clock,
					TMDSn_clock,
					LED
    );

/**** I\O List ****/
input clock_pixel;							// 50M
input clock_TMDS;								//250M
input [7:0] iRed, iGreen, iBlue;

output oRequest;
output SYNC_V;
output [2:0] TMDSp, TMDSn;
output TMDSp_clock, TMDSn_clock;
output [0:7] LED;
/**** Reg List ****/
reg [9:0] contX;		//0~800
reg [9:0] contY;		//0~525
reg syncH, syncV;
reg actvA, actvAa;

reg [3:0] TMDS_modulo;
reg shift_LOAD;
reg [9:0] TMDS_shift_red, TMDS_shift_green, TMDS_shift_blue;

reg [31:0] cntr;
/**** Wire List ****/
//reg [7:0] red, green, blue;
wire [7:0] W, A;
wire [9:0] TMDS_red, TMDS_green, TMDS_blue;


initial
begin
		contX <= 0; contY <= 0;
		syncH <= 0; syncV <= 0;
		actvA <= 0; actvAa <= 0;
		
		TMDS_modulo <= 0;
		shift_LOAD <= 0;
		TMDS_shift_red <= 0; TMDS_shift_green <= 0; TMDS_shift_blue <= 0;
		
		cntr <= 0;
end

/****
##### RTL code
****/
always@(posedge clock_pixel)
		cntr <= cntr + 1;
assign LED = cntr[29:23];


always@(posedge clock_pixel)
begin
		if(contX == 799)
				contX = 0;
		else
				contX = contX + 1;
end

always@(posedge clock_pixel)
begin
		if(contX == 799)
		begin
				if(contY == 524)
						contY = 0;
				else
						contY = contY + 1;
		end
		else
				contY = contY;
end

always@(posedge clock_pixel)
		syncH <= (contX >= 656) && (contX < 752);
always@(posedge clock_pixel)
		syncV <= (contY >= 490) && (contY < 492);
always@(posedge clock_pixel)
		actvA <= (contX < 640) && (contY < 480);
		
//*********** OUTPUT Control *******************
always@(posedge clock_pixel)
	actvAa <= ((contX > 797) && (contY == 524)) || ((contX < 638) && (contY < 480)) || ((contX > 797) && (contY < 479)); 
assign oRequest = actvAa;
assign SYNC_V = ~syncV;
//*********** Pattern to Display ****************
/*assign red = {contX[5:0] & {6{contY[4:3] == ~contX[4:3]}}, 2'b00};
assign green = contX[7:0] & {8{contY[6]}};
assign blue = contY[7:0];*/

/*assign W = {8{contX[7:0]==contY[7:0]}};
assign A = {8{contX[7:5]==3'h2 && contY[7:5]==3'h2}};

always @(posedge clock_pixel) red <= ({contX[5:0] & {6{contY[4:3]==~contX[4:3]}}, 2'b00} | W) & ~A;
always @(posedge clock_pixel) green <= (contX[7:0] & {8{contY[6]}} | W) & ~A;
always @(posedge clock_pixel) blue <= contY[7:0] | W | A;*/
//***********************************************
TMDS_encoder  iRED  (.clk(clock_pixel), .VD(iRed),   .CD(2'b00), 			 .VDE(actvA), .TMDS(TMDS_red));
TMDS_encoder  iGREEN(.clk(clock_pixel), .VD(iGreen), .CD(2'b00), 			 .VDE(actvA), .TMDS(TMDS_green));
TMDS_encoder  iBLUE (.clk(clock_pixel), .VD(iBlue),  .CD({syncV, syncH}), .VDE(actvA), .TMDS(TMDS_blue));

always@(posedge clock_TMDS)
begin
		TMDS_shift_red   <= shift_LOAD ? TMDS_red   : TMDS_shift_red[9:1];
		TMDS_shift_green <= shift_LOAD ? TMDS_green : TMDS_shift_green[9:1];
		TMDS_shift_blue  <= shift_LOAD ? TMDS_blue  : TMDS_shift_blue[9:1];
		
		TMDS_modulo <= (TMDS_modulo == 9) ? 4'd0 : TMDS_modulo + 1;
end
always@(posedge clock_TMDS)
		shift_LOAD <= (TMDS_modulo == 9);
//*********** Differential Output ***************
OBUFDS mRED  (.I(TMDS_shift_red[0]),   .O(TMDSp[2]), .OB(TMDSn[2]));
OBUFDS mGREEN(.I(TMDS_shift_green[0]), .O(TMDSp[1]), .OB(TMDSn[1]));
OBUFDS mBLUE (.I(TMDS_shift_blue[0]),  .O(TMDSp[0]), .OB(TMDSn[0]));
OBUFDS mCLOCK(.I(clock_pixel), .O(TMDSp_clock), .OB(TMDSn_clock));
endmodule
