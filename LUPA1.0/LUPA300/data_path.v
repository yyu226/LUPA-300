`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:04:57 05/02/2015 
// Design Name: 
// Module Name:    data_path 
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
module sdr_data_path(
        CLK,
        RESET_N,
        DATAIN,
        DM,
        DQOUT,
        DQM
        );

`include        "Sdram_Params.h"

input                           CLK;                    // System Clock
input                           RESET_N;                // System Reset
input   [`DSIZE-1:0]            DATAIN;                 // Data input from the host
input   [`DSIZE/8-1:0]          DM;                     // byte data masks
output  [`DSIZE-1:0]            DQOUT;
output  [`DSIZE/8-1:0]          DQM;                    // SDRAM data mask ouputs
reg     [`DSIZE/8-1:0]          DQM;
            


// Allign the input and output data to the SDRAM control path
always @(posedge CLK or negedge RESET_N)
begin
        if (RESET_N == 0) 
		DQM		<= `DSIZE/8-1'hF;
        else
 		DQM		<=	DM;                 
end

assign DQOUT = DATAIN;

endmodule
