`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/03/14 20:47:22
// Design Name: 
// Module Name: ALU
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


module ALU(
    CLK,
    RESET,
    
    IN_A,
    IN_B,
    
    ALU_Op_Code,
    
    OUT_RESULT
    );

input        CLK;
input        RESET;

input  [7:0] IN_A;
input  [7:0] IN_B;

input  [3:0] ALU_Op_Code;

output [7:0] OUT_RESULT;

// components

reg [7:0] Out;

// Arithmetic logic

always@(posedge CLK) begin
    if(RESET)
        Out <= 8'd0;
    else begin
        case(ALU_Op_Code)
        // Addition
        4'h0: Out <= IN_A + IN_B;
        // Subtraction
        4'h1: Out <= IN_A - IN_B;
        // Multiplication
        4'h2: Out <= IN_A * IN_B;
        // Shift left by 1 bit
        4'h3: Out <= IN_A << 1;
        // Shift right by 1 bit
        4'h4: Out <= IN_A >> 1;
        // Increment A
        4'h5: Out <= IN_A + 1;
        // Increment B
        4'h6: Out <= IN_B + 1;
        // //Decrement A
        4'h7: Out <= IN_A - 1;
        // //Decrement B
        4'h8: Out <= IN_B - 1;
        // In/Equality A == B
        4'h9: Out <= (IN_A == IN_B) ? 8'h01 : 8'h00;
        // A > B
        4'hA: Out <= (IN_A > IN_B) ? 8'h01 : 8'h00;
        // A < B
        4'hB: Out <= (IN_A < IN_B) ? 8'h01 : 8'h00;
        // A & B
        4'hC: Out <= IN_A & IN_B;
        // In IN_A toggle (IN_B) bit
        4'hD: Out <= IN_A ^ (1 << (IN_B & 8'h07));
        // in IN_B toggle (IN_A) bit
        4'hE: Out <= IN_B ^ (1 << (IN_A & 8'h07));
        // A | B
        4'hF: Out <= IN_A | IN_B;
        
        //Default A
        default: Out <= IN_A;
        endcase
     end
  end

  assign OUT_RESULT = Out;
endmodule
