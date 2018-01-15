`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: The University of Edinburgh
// Engineer: Samuel McDouall, modified by Xing Han
// 
// Create Date: 31.01.2017 10:08:43
// Design Name: VGA Interface
// Module Name: Wrapper
// Project Name: Digital Systems Laboratory 
// Target Devices: Basys 3 FPGA
// Tool Versions: Vivado 2015.2
// Description: The Wrapper module is the module that is instantiated to combine the VGA_Sig_Gen and Frame Buffer modules to
// print out a checkered pattern on the screen through the VGA display port that changes colour once a second. 
// 
// Dependencies: VGA_Sig_Gen and Frame_Buffer modules
// 
// Revision: Addition of data bus and address bus added to transfer data over, rather than internal logic
// Revision 0.03 
// Additional Comments: There are several additional features included in this design. 
// To get the original specified design, simply generate the bitstream and upload it to the FPGA. 
// The additional switches are only for extras, so leaving the switches alone will show the original specification required.



//////////////////////////////////////////////////////////////////////////////////



module VGA_Wrapper(
    input CLK,                  // On board clock, 100 MHz          
    input RESET,                // Manual Reset to reset whole system (will send VGA screen back to initial startup screen)
    input BUS_WE,               
    input [7:0] DataAddrBus,    // 8-bit data bus carrying the appropriate information held from either register A or B in the micro-controller
    inout [7:0] DataBus,         // 8-bit address bus carrying the peripheral address for a given micro-controller instruction
    output [7:0] Colour_Out,    // Output 8-bit colour sent to the VGA display, distrubution of 3-3-2 bits for RGB respectively
    output HS,                  
    output VS    
    );
    
    reg mouse_middle;           // Whether or not the middle mouse is being clicked
    reg mouse_click;            // Whether or not the left mouse is being clicked
    wire [7:0] Colour_Out_Wire; // Wire carrying the output 8-bit colour sent to the VGA display
    wire HS_Wire;               
    wire VS_Wire;               
    reg [15:0] Config_Colours_Reg;// Register storing the value of the two colours taken in with the B1 instruction
       
    reg [14:0] Addr_A_Reg;
    


// Assigning wires to their respective output ports

    assign Colour_Out = Colour_Out_Wire;
    assign HS = HS_Wire;
    assign VS = VS_Wire;


// Checking if data bus being read in is to go to the VGA driver, i.e. begins with B (0xB_) 
always @ (posedge CLK)
    begin
                                    
                // If addresss is B0, we are transfering the horizontal 8-bit address along the data bus
                if (DataAddrBus == 8'hB0 & BUS_WE)
                    begin
                        Addr_A_Reg[7:0] <= DataBus;
                    end
                 // If addresss is B1, we are transfering the vertical 7-bit address AND the pixel out data along the data bus
                else if (DataAddrBus == 8'hB1 & BUS_WE)
                    begin
                        Addr_A_Reg[14:8] <= DataBus[6:0];                              
                    end
                // If address is B2, we are transfering the colour value of a given pixel. Since only two colours are needed, we can
                // just take the inverse of the data bus for the other 8 bits.
                else if (DataAddrBus == 8'hB2 & BUS_WE)                   
                        mouse_click <= DataBus[0];        
                        
                else if (DataAddrBus == 8'hB3 & BUS_WE) 
                        mouse_middle <= DataBus[2];
            end

// Instantiations of the VGA_Sig_Gen and Frame_Buffer modules within the wrapper module with the above wires and ports.

    VGA_Sig_Gen vga1 (
                   .CLK(CLK),
                   .RESET(RESET),
                   .VGA_Colour(Colour_Out_Wire),
                   .HS(HS_Wire),
                   .VS(VS_Wire),
                   .Point_X(Addr_A_Reg[7:0]),
                   .Point_Y(~Addr_A_Reg[14:8]),
                   .mouse_click(mouse_click),
                   .mouse_middle(mouse_middle),
                   .Addr_X(Addr_X_Wire),
                   .Addr_Y(Addr_Y_Wire)
                   );
                   

endmodule

