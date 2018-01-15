`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/03/14 20:53:38
// Design Name: 
// Module Name: Seg7Wrapper
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


module Seg7Wrapper(
    input CLK,						//Internal Clock Signal
    input RESET,                    //Button that resets values
    output [3:0] SEG_SELECT,    //chooses one out of 4 transistor drivers
    output [7:0] DEC_OUT,        //Turns ON diodes in 7SegDisplay
    //Processor part
    inout  [7:0] BUS_DATA,
    input  [7:0] BUS_ADDR,
    input        BUS_WE
    );

    parameter [7:0] SevenSegBaseAddr = 8'hD0;
    
    wire [1:0] StrobeCount;        //Strobe Counter for choosing a display
    wire Bit16Trigger;            //1kHz trigger 
    
    wire [4:0] DecCountAndDOT0;//BNN dove for DEC values with DOT
    wire [4:0] DecCountAndDOT1;
    wire [4:0] DecCountAndDOT2;
    wire [4:0] DecCountAndDOT3;

    wire [4:0] MuxOut;            //Output from Multiplexer - one of 4 DecCountAndDOTX values
    
    reg [7:0] data_in;    //used to store binary data coming from the code...
    
    wire [7:0] BusDataIn;
    assign BusDataIn = BUS_DATA;

    always @(posedge CLK) begin
        if (RESET) begin
            data_in <= 8'h00;    //reset values
        end
        else if ( (BUS_ADDR == SevenSegBaseAddr) & BUS_WE )    //write a binary value from the bus
            data_in <= BusDataIn;                
        else 
            data_in <= data_in;    //otherwise leave as it was before    
    end
    
//downcounter with output trigger every 1ms/1kHz
    GenericCounter #(
                    .COUNTER_WIDTH(16),        //16bits of width
                    .COUNTER_MAX(49999)        //Counts to max value of 49 999 starting from 0
                    )
                Bit16DownCounter (
                    .CLK(CLK),                    //Clock input
                    .RESET(1'b0),                //No Reset
                    .ENABLE_IN(1'b1),            //Always Enable
                    .TRIGG_OUT(Bit16Trigger)//get 1kHz trigger
                    );

//Strobe Output counter for geting the value of the display
//that should be turned ON
    GenericCounter #(
                    .COUNTER_WIDTH(2),                //2bits of width
                    .COUNTER_MAX(3)                    //Counts to max value of 3
                    )
                Bit2DownCounter (
                    .CLK(CLK),                            //Clock input
                    .RESET(1'b0),                        //No Reset
                    .ENABLE_IN(Bit16Trigger),        //Trigger that enables counting in 1kHz Clock frequency
                    .COUNT(StrobeCount)                //chooses the 7-seg display value
                    );
                    
    wire [15:0] bcd_wire;
    assign bcd_wire[15:12] = 4'h0;	//Thousands always 0
    BinaryToBCD binary_to_BCD (
                .BINARY(data_in),
                .HUNDREDS(bcd_wire[11:8]),
                .TENS(bcd_wire[7:4]),
                .ONES(bcd_wire[3:0])
                ); 
                
    assign DecCountAndDOT0 = {1'b0, bcd_wire[3:0]};    
    assign DecCountAndDOT1 = {1'b0, bcd_wire[7:4]};
    assign DecCountAndDOT2 = {1'b0, bcd_wire[11:8]};        //Add DOT to separate seconds from milliseconds
    assign DecCountAndDOT3 = {1'b0, bcd_wire[15:12]};

//According to StrobeCount value choose the value to display on 7SegDisplay
    Mux4Way Mux4 (
                    .CONTROL(StrobeCount),            //binary values for determining output
                    .IN0(DecCountAndDOT0),            //input to be displayed as output
                    .IN1(DecCountAndDOT1),            //the same
                    .IN2(DecCountAndDOT2),            //the same
                    .IN3(DecCountAndDOT3),            //the same
                    .OUT(MuxOut)            //Output: one of provided inputs
                    );

//According to input values choose which transistors & which
//LEDs to turn ON (give logic 0)
    Seg7Decoder Seg7 (
                    .SEG_SELECT_IN(StrobeCount),    //binary value for determining which displa to turn on
                    .BIN_IN(MuxOut[3:0]),            //decimal value to be displayed in binary
                    .DOT_IN(MuxOut[4]),                //add DOT
                    .SEG_SELECT_OUT(SEG_SELECT),    //display to be turned on for a short amount of time
                    .HEX_OUT(DEC_OUT)                    //binary code specialy made to turn on specific LEDs of 7Seg display
                                                            //to display a provided value
                    );

endmodule
