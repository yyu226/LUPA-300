`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:35:58 01/14/2016 
// Design Name: 
// Module Name:    top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//                 Highest level HDL module
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module top(
				CLOCK_IN,								//50Mhz
				
				//LUPA
				DATA_IMAGE,
				SPI_EN,
				SPI_CLK,									//20Mhz
				SPI_DAT,
				LINE_VALID,
				FRAME_VALID,
				LUPA_CLK,								//80Mhz
				LUPA_RST,
				INT_TIME1,
				INT_TIME2,
				INT_TIME3,
				
				//SDRAM
				DRAM_CLK,
				SA,
				BA,
				CS_N,
				CKE,
				RAS_N,
				CAS_N,
				WE_N,
				UDQM,
				LDQM,
				DQ,
				
				//HDMI PORTS
				TMDS_POSITIVE,
				TMDS_NEGTIVE,
				TMDS_CLOCK_P,
				TMDS_CLOCK_N,

				LED_indicate
    );
//************** PORTS DECLARATION ********************//
input CLOCK_IN;

input [9:0] DATA_IMAGE;
output SPI_EN;
output SPI_CLK;
output SPI_DAT;
input LINE_VALID;
input FRAME_VALID;
output LUPA_CLK;
output LUPA_RST;
output INT_TIME1;							//for Slave mode
output INT_TIME2;
output INT_TIME3;

output DRAM_CLK;
output [12:0] SA;
output [1:0] BA;
output CS_N;
output CKE;
output RAS_N;
output CAS_N;
output WE_N;
output UDQM;
output LDQM;
inout [15:0] DQ;

output [2:0] TMDS_POSITIVE;
output [2:0] TMDS_NEGTIVE;
output       TMDS_CLOCK_P;
output	  	 TMDS_CLOCK_N;

output [7:0] LED_indicate;
//************** REGISTERS AND WIRES *****************//
reg clk_25m;

wire clk_100ld;
wire clk_100M;
wire clk_50M, clk_80M, clk_250M;
wire clk_80Mb;

wire [7:0] mono_data;
wire [15:0] dtout;

wire wr_req;
wire vSYNC, goo;
wire [3:0] ram_rst;
wire grst;
wire clk_20m;

reg [31:0] Reset_Count;
reg Global_Reset;
reg FIFO_Reset;
reg [15:0] Count;
reg [30:0] shutter;

reg [2:0] frame_cntr;
wire sel_indicator;
wire ACS;
wire int_time1;
//************** LOGIC DESCRIPTION *******************//
initial
begin
		clk_25m <= 0;
		Reset_Count <= 0;
		Global_Reset <= 0;
		FIFO_Reset <= 0;
		Count <= 0;
		
		frame_cntr <= 0;
		shutter <= 0;
end 

pll GLOBAL(
				.CLK_IN1				(CLOCK_IN),

				.CLK_OUT1			(clk_100ld),				//-150 degree, goes to RAM CLOCK INPUT PIN
				.CLK_OUT2			(clk_100M),					//goes to RAM controller
				.CLK_OUT3			(clk_250M),
				.CLK_OUT4			(clk_50M)
			);
cmm ISCM(
				.CLK_IN1				(clk_50M),
	
				.CLK_OUT1			(clk_80M),
				.CLK_OUT2			(clk_80Mb)					//NO buffer, 180 degree phase
			);
ODDR2 SDR(
			.Q				(DRAM_CLK),
			.C0			(clk_100ld),
			.C1			(~clk_100ld),
			.CE			(1'b1),
			.D0			(1'b1),
			.D1			(1'b0),
			.R				(1'b0),
			.S				(1'b0)
		);
ODDR2 SDR2(
			.Q				(LUPA_CLK),
			.C0			(clk_80M),
			.C1			(~clk_80M),
			.CE			(1'b1),
			.D0			(1'b1),
			.D1			(1'b0),
			.R				(1'b0),
			.S				(1'b0)
		);
		
/*ODDR2 SDR3(
			.Q				(SPI_CLK),
			.C0			(clk_20m),
			.C1			(~clk_20m),
			.CE			(1'b1),
			.D0			(1'b1),
			.D1			(1'b0),
			.R				(1'b0),
			.S				(1'b0)
		);*/

always@(posedge clk_50M)
		clk_25m = ~clk_25m;

ISensor_Read  LUPA300(
						.iCLOCK_80				(clk_80M),
						.oCLOCK_80				(),
						
						//
						.iADATA					(DATA_IMAGE),
						.oDATA					(mono_data),
						
						.SPI_EN					(SPI_EN),
						.SPI_CLK					(SPI_CLK),
						.SPI_DAT					(SPI_DAT),
						
						.Line_Valid				(LINE_VALID),
						.Frame_Valid			(FRAME_VALID),
						.INT_TIME1				(int_time1),							//In master mode, it's input as an indicator
						.INT_TIME2				(),
						.INT_TIME3				(),
						
						.RST_N					(grst),								//No Connection to outside
						.FFR_REQ					(wr_req),
						.wrt_flag				(ACS),
						.debug					(ram_rst)
					);
assign LUPA_RST = grst;

always@(posedge clk_80Mb)
				shutter = shutter + 1;
		
//assign INT_TIME1 = (shutter < 1073741824) ? int_time1 : 0;
assign INT_TIME1 = int_time1;
assign INT_TIME2 = 1'bz;
assign INT_TIME3 = 1'bz;

hdmi_top  HDMI_PORT2(
					.clock_pixel			(clk_25m),
					.clock_TMDS				(clk_250M),
					.iRed						(~dtout[15:8]),
					.iGreen					(~dtout[15:8]),
					.iBlue					(~dtout[15:8]),
					
					.oRequest				(goo),
					.SYNC_V					(vSYNC),
					.TMDSp					(TMDS_POSITIVE),
					.TMDSn					(TMDS_NEGTIVE),
					.TMDSp_clock			(TMDS_CLOCK_P),
					.TMDSn_clock			(TMDS_CLOCK_N),
					.LED						()									//No Connection
    );

sdram_top  SDRAMIF(
					 .RESET_N				(Global_Reset),						//1'b1
					 .F_CLEAR				(FIFO_Reset),	
					 .CLK						(clk_100M),

					 .FV						(LINE_VALID /*&& sel_indicator*/),				//FRAME_VALID
					 .WR						(wr_req /*&& sel_indicator*/),
					 .WR_ADDR				(0),
					 .WR_MAX_ADDR			(307200),
					 .WR_LENGTH				(8'd64),								//32
					 .WR_CLK					(clk_80Mb),
					 .WR_DATA				({mono_data, 8'h00}),
					 .RW_SYNC				(ACS),

					 .RD					(vSYNC),				//from vga, timing control FRAME_SYNC
					 .RDR					(goo),
						//	FIFO Read Side 1
					 .RD1_ADDR			(0),
					 .RD1_MAX_ADDR		(307200),
					 .RD1_LENGTH		(8'd32),								//64
					 .RD1_CLK			(~clk_25m),
						//	FIFO Read Side 2
					 .RD2_ADDR			(0),
					 .RD2_MAX_ADDR		(307200),
					 .RD2_LENGTH		(8'd32),
					 .RD2_CLK			(~clk_25m),
					 
					 .DATA_TO_VGA		(dtout),
					 
					 .SA					(SA),
					 .BA					(BA),
					 .CS_N				(CS_N),
					 .CKE					(CKE),
					 .RAS_N				(RAS_N),
					 .CAS_N				(CAS_N),
					 .WE_N				(WE_N),
					 .DQ					(DQ),
					 .DQM					({UDQM, LDQM}),
					 
					 .test_terminal   (LED_indicate[7:4])
    );
/*************** Ignore 75% image **********************************/
always@(posedge FRAME_VALID)
begin
		frame_cntr = frame_cntr + 1;
end

assign sel_indicator = (frame_cntr[1:0] == 2'b00) ? 1 : 1;
/*************** Delay Generator *******************************/
always@(posedge clk_50M)
begin
		if(Count < 16'heeee)
		begin
			Count <= Count + 1;
			Global_Reset <= 0;
		end
		else
			Global_Reset <= 1;
end

always@(posedge clk_50M)
begin
		if(!Global_Reset)
		begin
				FIFO_Reset  <= 0;
				Reset_Count <= 0;
		end
		else
		begin
				if(Reset_Count != 32'h01ffffff)
						Reset_Count <= Reset_Count + 1;
				if(Reset_Count >= 32'h011fffff)
						FIFO_Reset <= 1;
		end
end
//************** Debug *************************
/*assign LED_indicate[0] = grst;
assign LED_indicate[7] = ram_rst;
assign LED_indicate[1] = Global_Reset;
assign LED_indicate[2] = FIFO_Reset;
assign LED_indicate[0] = mono_data[7];*/
assign LED_indicate[3:0] = ram_rst;
endmodule
