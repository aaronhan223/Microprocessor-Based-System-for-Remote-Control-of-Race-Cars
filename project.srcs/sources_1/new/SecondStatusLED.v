`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/03/19 10:58:16
// Design Name: 
// Module Name: SecondStatusLED
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module SecondStatusLED(
    input RESET,
    input CLK,
    inout [7:0] BUS_DATA,
    input [7:0] BUS_ADDR,
    input BUS_WE,
    output reg [7:0] StatusLED
    );

//Define the BUS_ADDR for the StatusLEDs
    parameter [7:0] StatusLEDBaseAddr = 8'hE0;

//Tristate bus read controler
//reg TransmitX;

//if the WriteEnable is high, we read the status from the data bus to the internal register
    always@(posedge CLK) begin
        if((BUS_ADDR == StatusLEDBaseAddr) & BUS_WE) 
            StatusLED [7:0] <= BUS_DATA [7:0];       
    end

endmodule
