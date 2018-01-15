`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/04/04 00:49:14
// Design Name: 
// Module Name: AdvancedCounter
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


module AdvancedCounter(
    CLK,
    RESET,
    ENABLE_IN,
     NEG_DIR_IN,
     
    TRIGG_OUT,
    COUNT
    );

parameter COUNTER_WIDTH = 4;
parameter COUNTER_MAX = 9;

input CLK;
input RESET;
input ENABLE_IN;
input NEG_DIR_IN;

output TRIGG_OUT;
output [COUNTER_WIDTH-1:0] COUNT;

// register that hold TRIGG_OUT state
reg TriggerOut;
// counter register
reg [COUNTER_WIDTH-1:0] Counter;

// counter logic
always@(posedge CLK or posedge RESET) begin
if(RESET) Counter <= 0;
else begin
    if(ENABLE_IN) begin
        if(NEG_DIR_IN) begin
            if(Counter == 0) Counter <= COUNTER_MAX;
            else             Counter <= Counter - 1;
        end
        else begin
            if(Counter == COUNTER_MAX)
                Counter <= -200;
            else
                Counter <= Counter + 1;
        end
    end
end
end

// trigger logic
always@(posedge CLK or posedge RESET) begin
if(RESET)
    TriggerOut <= 0;
else begin
    if(NEG_DIR_IN) begin
        if(ENABLE_IN && (Counter == 0))
            TriggerOut <= 1;
        else
            TriggerOut <= 0;
    end
    else begin
        if(ENABLE_IN && (Counter == COUNTER_MAX))
            TriggerOut <= 1;
        else
            TriggerOut <= 0;
    end
end
end

// output assignments
assign TRIGG_OUT = TriggerOut;
assign COUNT = Counter;

initial Counter = 0;


endmodule
