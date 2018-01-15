`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/03/29 15:56:27
// Design Name: 
// Module Name: ir_transmitter
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


module ir_transmitter(
	//Standard Signals
    input                                RESET,
    input                                CLK,
    // Bus Interface Signals
    input [3:0]                     LATCHED_DATA,
    input                             SEND_PACKET,
    // IF LED signal
    output                            IR_LED,
    input [3:0] CAR_SELECT
    );

//Registers for the different cars which will be used!
    reg [8:0] StartBurstSize;
    reg [8:0]CarSelectBurstSize;
    reg [8:0] GapSize;
    reg [8:0]AsserBurstSize;
    reg [8:0]DeAssertBurstSize;
    reg [11:0] ClockRatio;
    
    
    always@(posedge CLK) begin //Parameters for the different cars
        case(CAR_SELECT) 
        4'b0001: begin //BLUE
             StartBurstSize         <= 191;
             CarSelectBurstSize    <= 47;
             GapSize                <= 25;
             AsserBurstSize        <= 47;
             DeAssertBurstSize     <= 22;
             ClockRatio            <=1250;
       end
       4'b0010: begin //RED
            StartBurstSize<=192;
            CarSelectBurstSize<=24;
            GapSize<=24;
            AsserBurstSize<=48;
            DeAssertBurstSize<=24;
            ClockRatio<=1250;
       end
       4'b0100: begin //GREEN
            StartBurstSize<=88;
            CarSelectBurstSize<=44;
            GapSize<=40;
            AsserBurstSize<=44;
            DeAssertBurstSize<=22;
            ClockRatio<=1334;
       end
       4'b1000: begin //YELLOW
             StartBurstSize<=88;
             CarSelectBurstSize<=22;
             GapSize<=40;
             AsserBurstSize<=44;
             DeAssertBurstSize<=22;
             ClockRatio<=1389;
       end
       default : begin
            StartBurstSize<=0;
            CarSelectBurstSize<=0;
            GapSize<=0;
            AsserBurstSize<=0;
            DeAssertBurstSize<=0;
            ClockRatio<=0;
       end
       endcase
       
    end

//Create the pulse signal
    reg Carrier;
    reg Carrier_Dly;
    reg [12:0] CarrierCounter;

    always@(posedge CLK) begin
        if(RESET) begin
            Carrier             <= 1'b0;
            CarrierCounter <= 0;
        end else if(CarrierCounter == ClockRatio) begin //this creates a 40KHz oscillator from 100MHz
            Carrier             <= ~Carrier;
            CarrierCounter <= 0;
        end else
            CarrierCounter <= CarrierCounter + 1'b1;
        
        Carrier_Dly         <= Carrier;
    end

//This is a simple state machine that pulses the IF_LED at 40KHz
//with a specific signal
//sequential

    reg [3:0]                     CurrState,    NextState;
    reg [7:0]                    CurrBurstCounter, NextBurstCounter;
    reg                            CurrLEDEnable, NextLEDEnable;
    always@(posedge CLK) begin
        if(RESET) begin
            CurrState            <= 3'b00;
            CurrBurstCounter    <= 0;
            CurrLEDEnable        <= 1'b0;
        end else begin
            CurrState            <= NextState;
            CurrBurstCounter    <= NextBurstCounter;
            CurrLEDEnable        <= NextLEDEnable;
        end
    end
        

//combinatorial
always@*begin
    //Defualts
    NextState             = 4'b0000;
    NextBurstCounter     = 0;
    NextLEDEnable        = 1'b0;
    case (CurrState)
        //IDLE
        4'b0000:    begin
                        if(SEND_PACKET)
                            NextState                 = 4'b0001;
                        else
                            NextState                 = 4'b0000;
                    end
        //START BURST
        4'b0001:    begin
                        if(CurrBurstCounter == StartBurstSize) begin
                            NextState                 = 4'b0010;
                            NextBurstCounter         = 0;
                        end else begin
                            NextState                 = 4'b0001;
                            if(~Carrier & Carrier_Dly)
                                NextBurstCounter     = CurrBurstCounter + 1'b1;
                            else
                                NextBurstCounter     = CurrBurstCounter;
                        end
                        
                        NextLEDEnable                 = 1'b1;
                    end
        //GAP
        4'b0010:    begin
                        if(CurrBurstCounter == GapSize) begin
                            NextState                 = 4'b0011;
                            NextBurstCounter         = 0;
                        end else begin
                            NextState                 = 4'b0010;
                            if(~Carrier & Carrier_Dly)
                                NextBurstCounter     = CurrBurstCounter + 1'b1;
                            else
                                NextBurstCounter     = CurrBurstCounter;
                        end
                    end
        //CODE BURST
        4'b0011:    begin
                        if(CurrBurstCounter == CarSelectBurstSize) begin
                            NextState                 = 4'b0100;
                            NextBurstCounter         = 0;
                        end else begin
                            NextState                 = 4'b0011;
                            if(~Carrier & Carrier_Dly)
                                NextBurstCounter = CurrBurstCounter + 1'b1;
                            else
                                NextBurstCounter     = CurrBurstCounter;
                        end
                        
                        NextLEDEnable                 = 1'b1;
                    end
        //GAP
        4'b0100:    begin
                        if(CurrBurstCounter == GapSize) begin
                            NextState                 = 4'b0101;
                            NextBurstCounter         = 0;
                        end else begin
                            NextState                 = 4'b0100;
                            if(~Carrier & Carrier_Dly)
                                NextBurstCounter     = CurrBurstCounter + 1'b1;
                            else
                                NextBurstCounter     = CurrBurstCounter;
                        end
                    end
        //LEFT
        4'b0101:    begin
                        if((LATCHED_DATA[0]     & (CurrBurstCounter > AsserBurstSize-1))         |
                            (~LATCHED_DATA[0] & (CurrBurstCounter > DeAssertBurstSize-1))    ) begin
                            NextState                 = 4'b0110;
                            NextBurstCounter         = 0;
                        end else begin
                            NextState                 = 4'b0101;
                            if(~Carrier & Carrier_Dly)
                                NextBurstCounter     = CurrBurstCounter + 1'b1;
                            else
                                NextBurstCounter     = CurrBurstCounter;
                        end
                        
                        NextLEDEnable                 = 1'b1;
                    end
        //GAP
        4'b0110:    begin
                        if(CurrBurstCounter == GapSize) begin
                            NextState                 = 4'b0111;
                            NextBurstCounter         = 0;
                        end else begin
                            NextState                 = 4'b0110;
                            if(~Carrier & Carrier_Dly)
                                NextBurstCounter     = CurrBurstCounter + 1'b1;
                            else
                                NextBurstCounter     = CurrBurstCounter;
                        end
                    end
        //RIGHT
        4'b0111:    begin
                        if((LATCHED_DATA[1]     & (CurrBurstCounter > AsserBurstSize-1))         |
                            (~LATCHED_DATA[1] & (CurrBurstCounter > DeAssertBurstSize-1))    ) begin
                            NextState                 = 4'b1000;
                            NextBurstCounter         = 0;
                        end else begin
                            NextState                 = 4'b0111;
                            if(~Carrier & Carrier_Dly)
                                NextBurstCounter     = CurrBurstCounter + 1'b1;
                            else
                                NextBurstCounter     = CurrBurstCounter;
                        end
                        
                        NextLEDEnable                 = 1'b1;
                    end
        //GAP
        4'b1000:    begin
                        if(CurrBurstCounter == GapSize) begin
                            NextState                 = 4'b1001;
                            NextBurstCounter         = 0;
                        end else begin
                            NextState                 = 4'b1000;
                            if(~Carrier & Carrier_Dly)
                                NextBurstCounter     = CurrBurstCounter + 1'b1;
                            else
                                NextBurstCounter     = CurrBurstCounter;
                        end
                    end
        //BACKWARDS
        4'b1001:    begin
                        if((LATCHED_DATA[3]     & (CurrBurstCounter > AsserBurstSize-1))         |
                            (~LATCHED_DATA[3] & (CurrBurstCounter > DeAssertBurstSize-1))    ) begin
                            NextState                 = 4'b1010;
                            NextBurstCounter         = 0;
                        end else begin
                            NextState                 = 4'b1001;
                            if(~Carrier & Carrier_Dly)
                                NextBurstCounter     = CurrBurstCounter + 1'b1;
                            else
                                NextBurstCounter     = CurrBurstCounter;
                        end
                        
                        NextLEDEnable                 = 1'b1;
                    end
        //GAP
        4'b1010:    begin
                        if(CurrBurstCounter == GapSize) begin
                            NextState                 = 4'b1011;
                            NextBurstCounter         = 0;
                        end else begin
                            NextState                 = 4'b1010;
                            if(~Carrier & Carrier_Dly)
                                NextBurstCounter     = CurrBurstCounter + 1'b1;
                            else
                                NextBurstCounter     = CurrBurstCounter;
                        end
                    end
        //FORWARDS
        4'b1011:    begin
                        if((LATCHED_DATA[2]     & (CurrBurstCounter > AsserBurstSize-1))         |
                            (~LATCHED_DATA[2] & (CurrBurstCounter > DeAssertBurstSize-1))    ) begin
                            NextState                 = 4'b1100;
                            NextBurstCounter         = 0;
                        end else begin
                            NextState                 = 4'b1011;
                            if(~Carrier & Carrier_Dly)
                                NextBurstCounter     = CurrBurstCounter + 1'b1;
                            else
                                NextBurstCounter     = CurrBurstCounter;
                        end
                        
                        NextLEDEnable                 = 1'b1;
                    end
        //GAP
        4'b1100:    begin
                        if(CurrBurstCounter == GapSize) begin
                            NextState                 = 4'b0000;
                            NextBurstCounter         = 0;
                        end else begin
                            NextState                 = 4'b1100;
                            if(~Carrier & Carrier_Dly)
                                NextBurstCounter     = CurrBurstCounter + 1'b1;
                            else
                                NextBurstCounter     = CurrBurstCounter;
                        end
                    end
        default:    begin
                        NextState             = 4'b0000;
                        NextBurstCounter     = 0;
                        NextLEDEnable         = 1'b0;
                    end
    endcase
end

//Tie the 40KHz signal to the LED output vie the Enable signal
assign IR_LED = Carrier & CurrLEDEnable;


endmodule


