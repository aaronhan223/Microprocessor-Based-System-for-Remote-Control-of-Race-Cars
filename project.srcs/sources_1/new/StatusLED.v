`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/03/14 20:59:32
// Design Name: 
// Module Name: StatusLED
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


module StatusLED(
    input RESET,
    input CLK,
    inout [7:0] BUS_DATA,
    input [7:0] BUS_ADDR,
    input BUS_WE,
    output reg [7:0] StatusLED
    );

//Define the BUS_ADDR for the StatusLEDs
    parameter [7:0] StatusLEDBaseAddr = 8'hC0;

//Tristate bus read controler
//reg TransmitX;

//if the WriteEnable is high, we read the status from the data bus to the internal register
    always@(posedge CLK) begin
        if((BUS_ADDR == StatusLEDBaseAddr) & BUS_WE) begin
            StatusLED [3:0] <= BUS_DATA [3:0];
            end
        if((BUS_ADDR == StatusLEDBaseAddr + 1'b1) & BUS_WE) begin
            StatusLED [4] <= BUS_DATA [0];
            end
        if((BUS_ADDR == (StatusLEDBaseAddr + 2'h2)) & BUS_WE) begin
            StatusLED [5] <= BUS_DATA [0];
            end
        if((BUS_ADDR == (StatusLEDBaseAddr + 2'h3)) & BUS_WE) begin
            StatusLED [6] <= BUS_DATA [0];
            end
        if((BUS_ADDR == (StatusLEDBaseAddr + 3'h4)) & BUS_WE) begin
            StatusLED [7] <= BUS_DATA [0];
            end
    end 

endmodule
