`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: The University of Edinburgh
// Engineer: Xing Han, Samuel McDouall, Nikola Garkov
// 
// Create Date: 2017/03/14 20:40:36
// Design Name: Top Level Wrapper
// Module Name: TopWrapper
// Project Name: Digital System Lab
// Target Devices: Basys 3 FPGA
// Tool Versions: Vivado 2015.2
// Description: This is the top wrapper module to connect all the peripherals together.
// 
// Dependencies: New_Mouse_Wrapper, ir_wrapper, VGA_Wrapper, microprocessor, Timer, Seg7Wrapper, StatusLed, SecondStatusLed and Switches modules
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module TopWrapper(
	// inputs
    input CLK,
    input RESET,
    input [7:0] SWITCHES,
    input [3:0] CAR_SELECT,
    
    //inouts
    inout CLK_MOUSE,
    inout DATA_MOUSE,
    
    //outputs
    output [7:0] StatusLED,
    output [7:0] StatusLED_2,
    output [3:0] SEG_SELECT,
    output [7:0] DEC_OUT,
    output IR_LED,
    output [7:0] Colour_Out,
    output HS_OUT,
    output VS_OUT

    );

//////////////////////////////////////////////////////////////////////////////////
//Interconnecting wires
//

    //ROM buses
    wire [7:0] ROM_DATA;
    wire [7:0] ROM_ADDR;
    
    //Processor buses
    wire [7:0] BUS_DATA;
    wire [7:0] BUS_ADDR;
    wire BUS_WE;
    
    //Interrupts
    wire [1:0] BUS_INTERRUPTS_RAISE;
    wire [1:0] BUS_INTERRUPTS_ACK;

//////////////////////////////////////////////////////////////////////////////////
//Instantiating peripherals
//

//Instantiate RAM
    RAM RAM(
    .CLK(CLK),
    .BUS_DATA(BUS_DATA),
    .BUS_ADDR(BUS_ADDR),
    .BUS_WE(BUS_WE)
    );

//Instantiate ROM
    ROM ROM(
    .CLK(CLK),
    .DATA(ROM_DATA),
    .ADDR(ROM_ADDR)
    );

    ir_wrapper   U1    (       //IR WRapper module 
    .CLK(CLK),
    .RESET(RESET),
    .ADDR(BUS_ADDR),
    .BUS_WE(BUS_WE),
    .DATA(BUS_DATA),                             
    .IR_LED(IR_LED),
    .CAR_SELECT(CAR_SELECT)
    );
    
//Instantiate CPU
    Microprocessor myMicroprocessor(
    .CLK(CLK),
    .RESET(RESET),
    .BUS_DATA(BUS_DATA),
    .BUS_ADDR(BUS_ADDR),
    .BUS_WE(BUS_WE),
    .ROM_ADDRESS(ROM_ADDR),
    .ROM_DATA(ROM_DATA),
    .BUS_INTERRUPTS_RAISE(BUS_INTERRUPTS_RAISE),
    .BUS_INTERRUPTS_ACK(BUS_INTERRUPTS_ACK)
    );

//Instantiate MOUSE peripheral
    New_Mouse_Wrapper MOUSE(
    .CLK_MOUSE(CLK_MOUSE),
    .DATA_MOUSE(DATA_MOUSE),
    .CLK(CLK),
    .RESET(RESET),
    .BUS_DATA(BUS_DATA),
    .BUS_ADDR(BUS_ADDR),
    .BUS_WE(BUS_WE),
    .BUS_INTERRUPT_ACK(BUS_INTERRUPTS_ACK[0]),
    .BUS_INTERRUPT_RAISE(BUS_INTERRUPTS_RAISE[0])
    );
//VGA peripheral
    VGA_Wrapper VGA(
        .CLK(CLK),
        .RESET(RESET),
        .DataAddrBus(BUS_ADDR),
        .DataBus(BUS_DATA),
        .BUS_WE(BUS_WE),
        .Colour_Out(Colour_Out),
        .HS(HS_OUT),
        .VS(VS_OUT)
    );

    
//Instantiate TIMER peripheral
    Timer TIMER(
    .CLK(CLK),
    .RST(RESET),
    .BUS_ADDR(BUS_ADDR),
    .BUS_DATA(BUS_DATA),
    .BUS_WE(BUS_WE),
    .BUS_INTERRUPT_ACK(BUS_INTERRUPTS_ACK[1]),
    .BUS_INTERRUPT_RAISE(BUS_INTERRUPTS_RAISE[1])
    );    

//Instantiate SEG7 peripheral
    Seg7Wrapper SEG7(
    .CLK(CLK),
    .RESET(RESET),
    .BUS_WE(BUS_WE),
    .BUS_DATA(BUS_DATA),
    .BUS_ADDR(BUS_ADDR),
    .SEG_SELECT(SEG_SELECT),
    .DEC_OUT(DEC_OUT)
    );

//Instantiate LED peripheral
    StatusLED LED(
    .CLK(CLK),
    .RESET(RESET),
    .BUS_DATA(BUS_DATA),
    .BUS_ADDR(BUS_ADDR),
    .BUS_WE(BUS_WE),
    .StatusLED(StatusLED)
    );
//LED for the 9-16 bit
    SecondStatusLED LED_2(
    .CLK(CLK),
    .RESET(RESET),
    .BUS_DATA(BUS_DATA),
    .BUS_ADDR(BUS_ADDR),
    .BUS_WE(BUS_WE),
    .StatusLED(StatusLED_2)
    );

//Instantiate SWITCHES
    Switches SW(
    .CLK(CLK),
    .RST(RESET),
    .BUS_DATA(BUS_DATA),
    .BUS_ADDR(BUS_ADDR),
    .BUS_WE(BUS_WE),
    .SWITCH_VALUE(SWITCHES)
    );

endmodule