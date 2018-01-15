`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/03/14 20:44:10
// Design Name: 
// Module Name: ROM
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


module ROM(
    CLK,
    DATA,
    ADDR
    );

    input            CLK;
    output reg [7:0] DATA;
    input      [7:0] ADDR;

    parameter RAMAddrWidth = 8;

// Memory
    reg [7:0] ROM [2**RAMAddrWidth-1:0];

// Load program
    initial $readmemh("Complete_Demo_ROM.txt", ROM);

// Single port logic
    always@(posedge CLK)
        DATA <= ROM[ADDR];

endmodule
