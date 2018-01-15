`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/03/29 15:55:18
// Design Name: 
// Module Name: ir_wrapper
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


module ir_wrapper(
    input CLK,
    input [7:0] ADDR,
    input [7:0] DATA,
    input BUS_WE,
    input RESET,
    input [3:0] CAR_SELECT,        
    output IR_LED
    );

    parameter [7:0] ir_addr = 8'h90;
    

    reg [3:0] COMMAND;
    reg ENABLE;

    always @ (posedge CLK) begin
            if (RESET) begin
                COMMAND <= 4'b0000; 
            end
            else if ((ADDR == ir_addr) & BUS_WE) 
                COMMAND[3] <= DATA[0];
            else if ((ADDR == ir_addr + 1'b1) & BUS_WE) 
                COMMAND[2] <= DATA[0];           
            else if ((ADDR == ir_addr + 2'h2) & BUS_WE) 
                COMMAND[1] <= DATA[0];       
            else if ((ADDR == ir_addr + 2'h3) & BUS_WE) 
                COMMAND[0] <= DATA[0];     
            else if ((ADDR == ir_addr + 3'h4) & BUS_WE) 
                ENABLE <= DATA[0];                                                                     
            
            else begin
                COMMAND <= COMMAND;
                ENABLE <= ENABLE;
                end
            
     end

    ir_transmitter blue (
                .CLK(CLK),
                .RESET(RESET),
                .SEND_PACKET(ENABLE),
                .LATCHED_DATA(COMMAND),
                .IR_LED(IR_LED),
                .CAR_SELECT(CAR_SELECT)
              );

endmodule
