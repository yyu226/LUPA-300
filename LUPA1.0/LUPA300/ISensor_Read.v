`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:46:23 01/14/2016 
// Design Name: 
// Module Name:    ISensor_Read 
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
module ISensor_Read(
						iCLOCK_80,
						oCLOCK_80,
						
						//
						iADATA,
						oDATA,
						
						SPI_EN,
						SPI_CLK,
						SPI_DAT,
						
						Line_Valid,
						Frame_Valid,
						INT_TIME1,
						INT_TIME2,
						INT_TIME3,
						
						RST_N,
						FFR_REQ,
						wrt_flag,
						debug,
    );
//*************** Port Declaration ****************
input iCLOCK_80;								//from top module, because the PLL is there
output oCLOCK_80;

input [9:0] iADATA;							//ADC data input
output [7:0] oDATA;							//Output to an FIFO or Memery Array

output SPI_EN;									//Low Active
output SPI_CLK;								//Lower than 20Mhz
output SPI_DAT;								//UPLOAD

input Line_Valid;
input Frame_Valid;
output reg INT_TIME1;								//NC in Master mode
output INT_TIME2;								//NC in Master mode
output INT_TIME3;								//NC in Master mode

output RST_N;
output FFR_REQ;
output wrt_flag;
output [3:0] debug;
//*************** Reg List *************************
reg rst_n;
reg [15:0] rst_cntr;
reg rSTART, oSTART, rgSTART;


reg [19:0] cntr_P;
reg Pre_FVAL;
reg mFVAL, mLVAL;

reg [7:0] frame_count;
reg acs;
reg [9:0] aLine_Valid, aFrame_Valid;

reg [4:0]  spi_cntr;
reg [20:0] exp_ctr;
reg [8:0]  line_ctr;
reg [10:0]  fot_ctr;
reg fot, Cstart;

wire fot_end;

wire [1:0] shot_ready;
wire clk_40M;
//*************** Initialize List ******************
initial
begin
		rst_cntr <= 0;
		rst_n    <= 0;
		rSTART   <= 0;
		rgSTART  <= 0;
		
		cntr_P <= 0;
		oSTART <= 0;
		
		frame_count  <= 0;
		acs          <= 0;
		aLine_Valid  <= 0;
		aFrame_Valid <= 0;
		
		spi_cntr <= 0;
		exp_ctr  <= 0;
		line_ctr <= 0;
		INT_TIME1 <= 0;
		fot_ctr <= 0;
		fot <= 0;
end
/***************************************************
                  Logic Description
********************************************************************/
subpll		DIVIDBY4(
								.CLK_IN1				(iCLOCK_80),
  
								.CLK_OUT1			(clk_40M)
 );
/*always@(posedge iCLOCK_80)
		spi_cntr = spi_cntr + 1;
assign clk_20M = spi_cntr[1];*/

assign oCLOCK_80 = iCLOCK_80;
spi_upload REG_CONFIG(
							.clock_40				(clk_40M),				// 80 divided by 4 = 20
							.start					(rgSTART),				//rSTART or 0(bypass)
							.nrg						(1),								//edit 16, the other 10 regs remain the default

							.spi_clk					(SPI_CLK),
							.spi_en					(SPI_EN),
							.spi_dat					(SPI_DAT),
							
							.cfg_DONE				(shot_ready)
					 );					 
/************************** Readout Timing **************************/
always@(posedge iCLOCK_80 or negedge Frame_Valid)
begin
		if(!Frame_Valid)
				cntr_P = 0;
		else if(Frame_Valid && Line_Valid)
				cntr_P = cntr_P + 1;
		else
				cntr_P = cntr_P;
end

always@(posedge Frame_Valid)
begin
		if(shot_ready)
				oSTART <= 1;
		else
				oSTART <= 0;
end


//assign oDATA = iADATA[9:2];
assign oDATA[7] = iADATA[9];
assign oDATA[6] = iADATA[8];
assign oDATA[5] = iADATA[7];
assign oDATA[4] = iADATA[6];
assign oDATA[3] = iADATA[5];
assign oDATA[2] = iADATA[4];
assign oDATA[1] = iADATA[3];
assign oDATA[0] = iADATA[2];
//////////////////////////////////////////////////////////////////////
//LUPA300 RESET CIRCUITRY
always@(posedge iCLOCK_80)
begin
		if(rst_cntr < 20000)				//VDDD needs 20000 clock cycles to become stable -- 1V/100uS
					rst_cntr = rst_cntr + 1;
		else if(rst_cntr < 20050)		//it takes another 50 clock cycles to upload the Default value of all 16 regs
		begin
					rst_cntr = rst_cntr + 1;
					rst_n <= 1;
		end
		else if(rst_cntr < 20060)		//the 2nd rising edge of the iCLOCK_80 after the rising edge of RST_N 
																	//triggers the rising edge of the core(internal) clock
					rst_cntr = rst_cntr + 1;
		else
		begin
					rSTART = 1;
					if(rst_cntr < 30000)
						rst_cntr = rst_cntr + 1;
					else
						rst_cntr = 30000;
		end
end
always@(negedge Frame_Valid)								//Edit the registers only when FRAME_VALID is low
begin
		if(rst_cntr > 20055)
				rgSTART = 1;
		else
				rgSTART = 0;
end
assign RST_N = rst_n & (!rgSTART) | shot_ready;
assign debug = {rst_n, rgSTART, shot_ready};
//Hold the RST_N low for a minimum of 50nS, the SEQUENCER will be reset
always@(posedge iCLOCK_80)
begin
		if(!rst_n)
		begin
				Pre_FVAL <= 0;
				mFVAL    <= 0;
				mLVAL		<= 0;
		end
		else
		begin
				Pre_FVAL	<=	Frame_Valid;
				if({Pre_FVAL,Frame_Valid}==2'b01)
						mFVAL	<=	1;
				else if({Pre_FVAL,Frame_Valid}==2'b10)
						mFVAL	<=	0;
				mLVAL	<=	Line_Valid;
		end
end
//******************************************************************************
always@(posedge Frame_Valid)
		frame_count = frame_count + 1;
always@(frame_count)
begin
		if(frame_count[4:0]==5'b10101)
			acs = 1;
		else
			acs = 0;
end
assign wrt_flag = Frame_Valid & acs;
//**********************************************************************************
always@(posedge iCLOCK_80)
begin
		if(!Line_Valid)
				aLine_Valid = 0;
		else
				aLine_Valid = aLine_Valid + 1;
end
always@(posedge iCLOCK_80)
begin
		if(!wrt_flag)
				aFrame_Valid = 0;
		else
		begin
				if(aFrame_Valid < 625)
						aFrame_Valid = aFrame_Valid + 1;
				else
						aFrame_Valid = aFrame_Valid;
		end
end
//********************* Row Overhead Elimination ***********************************

assign FFR_REQ = wrt_flag && Line_Valid;//(aFrame_Valid >= 625)/*wrt_flag*/ && (aLine_Valid >= 33) /*&& shot_ready*/;										//mFVAL & mLVAL & acs;

/*assign INT_TIME1 = 0;
assign INT_TIME2 = 0;
assign INT_TIME3 = 0;*/
always@(posedge iCLOCK_80)
begin
		if(shot_ready!=2'b11)
				exp_ctr = 0;
		else
		begin
				if(exp_ctr < 323184)
					exp_ctr = exp_ctr + 1;
				else
					exp_ctr = 0;
		end
end
/*always@(negedge Line_Valid)
begin
		if(shot_ready!=2'b11)
				line_ctr <= 0;
		else
		begin
				if(line_ctr<490)
				begin
						fot <= 0;
						line_ctr <= line_ctr + 1;
				end
				else
				begin
						fot <= 1;
						line_ctr <= 0;
				end
		end
end*/	
always@(negedge Line_Valid)
begin
		if((exp_ctr >= 376)&&(exp_ctr<1048))
				Cstart = 1;
		else
				Cstart = 0;
end
always@(posedge iCLOCK_80)
begin
		if(Cstart)
			fot_ctr = fot_ctr + 1;
		else
			fot_ctr = 0;
end
assign fot_end = (fot_ctr>624) ? 0 : 1;
always@(negedge Line_Valid/* or negedge fot_end*/)
begin
		if(Cstart)
		begin
				if(!fot_end)
						INT_TIME1 = 1;
				else
						INT_TIME1 = 0;													//FOT 624 clock cycles
		end
		else
		begin
				if((exp_ctr >= 1048)&&(exp_ctr<243640))
						INT_TIME1 = 0;
				else
						INT_TIME1 = 1;
		end	
end

assign INT_TIME2 = 0;
assign INT_TIME3 = 0;
endmodule
