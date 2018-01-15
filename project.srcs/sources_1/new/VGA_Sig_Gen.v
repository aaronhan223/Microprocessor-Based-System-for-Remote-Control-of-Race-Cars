`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: The University of Edinburgh
// Engineer: Samuel McDouall, modified by Xing Han
// 
// Create Date: 31.01.2017 10:08:43
// Design Name: VGA Interface
// Module Name: VGA_Sig_Gen
// Project Name: Digital Systems Laboratory 
// Target Devices: Basys 3 FPGA
// Tool Versions: Vivado 2015.2
// Description: The VGA_Sig_Gen module will take in a single bit input from the Frame_Buffer module, which will generate
// an appropriate colour to be read out to the Wrapper module.  
// 
// Dependencies: Generic Counter module, Frame Buffer (to take input from)
// 
// Revision: Modified to now take in Config_Colours for the colour value instead of reading a predetermined memory from the Frame Buffer module. In 
// addition the Point_X and Point_Y values are taken in from the microprocessor to be used by the VGA_Sig_Gen to determine the mouse position.
// Revision 0.03
// Additional Comments: The input port Config_Colours has been kept in. Whilst not yet in use, this code has been kept in but 
//                      commented out for further use later on.
// 
//////////////////////////////////////////////////////////////////////////////////



module VGA_Sig_Gen(
    input CLK,                      // On board clock, 100 MHz
    input RESET,
    output reg [7:0] VGA_Colour,    // Output 8-bit colour sent to the VGA display, distrubution of 3-3-2 bits for RGB respectively
    output reg HS,                  
    output reg VS,
    input [7:0] Point_X,            // Horizontal input address from the mouse
    input [7:0] Point_Y,            // Vertical input address from the mouse
    input mouse_click,              // The left mouse clicked or not
    input mouse_middle,             // The middle mouse clicked or not
    output [7:0] Addr_X,            // Horizontal address
    output [6:0] Addr_Y             // Vertical address
    );


// Registers to store the new calculated addresses of the pixels

reg [9:0] Addr_X_Reg;   // The required address of the horizontal location is stored in this register to later be assigned to the output port Addr_X
reg [8:0] Addr_Y_Reg;   // The required address of the horizontal location is stored in this register to later be assigned to the output port Addr_Y
 

// Enable wires to the connect between the three counter instantiations

wire Counter_Connect_1;   // Wire between the preliminary counter and first counter
wire Counter_Connect_2;   // Wire between the first and second counter
wire Counter_Connect_3;

// Counter wires, these are output from the second and third counter instantiations 

wire [9:0] Count_1;
wire [9:0] Count_2;
wire [9:0] Count_3;
// These counter wires are compared to the parameters (defined below) and are used to work out if the 
// counts are within "Display Time". This is defined below as well, being between the TimeToBackPorchEnd
// and TimeToDisplayTimeEnd times. This wire which is high if we are in "Display Time" is called DisplayTimeValid
// as shown below. This way defining this previously we make the code shorter overall rather than having long 
// uneccessary if statements
 
 
// Parameters for working out whether DisplayTimeValid will be high or low
 
    // Time in vertical lines
    
    parameter VertTimeToPulseWidthEnd = 10'd2;
    parameter VertTimeToBackPorchEnd = 10'd31;
    parameter VertTimeToDisplayTimeEnd = 10'd511;
    parameter VertTimeToFrontPorchEnd = 10'd521;
    
    // Time in front horizontal lines
    
    parameter HorzTimeToPulseWidthEnd = 10'd96;
    parameter HorzTimeToBackPorchEnd = 10'd144;
    parameter HorzTimeToDisplayTimeEnd = 10'd784;
    parameter HorzTimeToFrontPorchEnd = 10'd400;


// Defining when the we are in "Display Time"

wire DisplayTimeValid;
assign DisplayTimeValid = ((Count_1 > HorzTimeToBackPorchEnd) && (Count_1 < HorzTimeToDisplayTimeEnd) 
                        && (Count_2 > VertTimeToBackPorchEnd) && (Count_2 < VertTimeToDisplayTimeEnd));




 // Wire and registers used for changing the colour of the screen
 
 wire Change_Colour;                    // Wire out of a Generic_counter module to determine when to change colour (i.e. when high, change colour)
 reg [7:0] Colour_Value = 8'h00;        // The current state value of the 8-bit colour
 reg [7:0] Colour_Counter = 8'h00;       // The increment of the next colour value

// Logic needed to delay "ready" signals until able to write/read using Generic_counter modules

// First a prelimenary 2-bit counter delaying each count from the first counter by 4 clock cycles. This is required
// as the speed of the on-board clock of the FPGA is 100 MHz and the maximum speed of the screen is 60 MHz therefore, we need something lower.
// This counter slows down the FPGA clock to 25 MHz.        
GenericCounter # (.COUNTER_WIDTH(2), 
                   .COUNTER_MAX(3)
                   )
                   SlowDownCounter(
                   .CLK(CLK),       
                   .RESET(1'b0),                      // Reset not needed here, therefore connected to 0
                   .ENABLE_IN(1'b1),                  // Want it to always be counting so set to 1 
                   .TRIGG_OUT(Counter_Connect_1),      // Need to connect this to the first counter as this outputs 1 when it resets the count
                   .COUNT()                           // Not needed, so connected to nothing 
                   );

// Then the first 10-bit counter counting up to 799

GenericCounter # (.COUNTER_WIDTH(10),
                   .COUNTER_MAX(799)
                   )
                   FirstCounter(
                   .CLK(CLK),       
                   .RESET(1'b0),                      // Reset not needed here, therefore connected to 0
                   .ENABLE_IN(Counter_Connect_1),     // Only want to iterate this count when the preliminary counter resets
                   .TRIGG_OUT(Counter_Connect_2),      // Need to connect this to the second counter as this outputs 1 when it resets the count
                   .COUNT(Count_1)                    // Count up to 799 
                   );
                   
// Finally, the 10-bit counter counting up to 520

GenericCounter # (.COUNTER_WIDTH(10),
                   .COUNTER_MAX(520)
                   )
                   SecondCounter(
                   .CLK(CLK),       
                   .RESET(1'b0),                      // Reset not needed here, therefore connected to 0
                   .ENABLE_IN(Counter_Connect_2),     // Doesn't iterate the count unless the first one has reset 
                   .TRIGG_OUT(),                       // Not needed, so connected to nothing
                   .COUNT(Count_2)                    // Count up to 520
                   );
              
GenericCounter # (.COUNTER_WIDTH(2),
                  .COUNTER_MAX(3)
                  )
                  Transfer(
                  .CLK(CLK),
                  .RESET(1'b0),
                  .ENABLE_IN(1'b1),
                  .TRIGG_OUT(Trans_OUT)
                  );

GenericCounter # (.COUNTER_WIDTH(30), 
                   .COUNTER_MAX(781249)
                   )
                   SlowDownCounter1(
                   .CLK(CLK),       
                   .RESET(1'b0),                      // Reset not needed here, therefore connected to 0
                   .ENABLE_IN(1'b1),                  // Want it to always be counting so set to 1 
                   .TRIGG_OUT(Counter_Connect_3),      // Need to connect this to the first counter as this outputs 1 when it resets the count
                   .COUNT()                           // Not needed, so connected to nothing 
                   );
                   
                    AdvancedCounter # (.COUNTER_WIDTH(10), 
                                      .COUNTER_MAX(800)
                                      )
                                      PositionCounter1(
                                      .CLK(Counter_Connect_3),       
                                      .RESET(1'b0),                      // Reset not needed here, therefore connected to 0
                                      .ENABLE_IN(1'b1),                  // Want it to always be counting so set to 1 
                                      .COUNT(Count_3)                           // Not needed, so connected to nothing 
                                      );

// Wire and registers needed for addresses and data for displaying the images in each of the boxes

    reg [12:0] addra;
    wire [7:0] douta;
    reg [12:0] addra1;
    wire [7:0] douta1;
    reg [12:0] addra2;
    wire [7:0] douta2;
    reg [12:0] addra3;
    wire [7:0] douta3;
    reg [12:0] addra4;
    wire [7:0] douta4;
    reg [12:0] addra5;
    wire [7:0] douta5;
    reg [12:0] addra6;
    wire [7:0] douta6;
    reg [12:0] addra7;
    wire [7:0] douta7;
    reg [12:0] addra8;
    wire [7:0] douta8;
    reg [12:0] addra9;
    wire [7:0] douta9;
    reg [12:0] addra10;
    wire [7:0] douta10;
    reg [12:0] addra11;
    wire [7:0] douta11;
    reg [12:0] addra12;
    wire [7:0] douta12;
    reg [12:0] addra13;
    wire [7:0] douta13;
    reg [12:0] addra14;
    wire [7:0] douta14;
    reg [12:0] addra15;
    wire [7:0] douta15;
    
    blk_mem_gen_0 your_instance_name (
      .clka(Trans_OUT),    // input wire clka
      .ena(1'b1),      // input wire ena
      .addra(addra),  // input wire [9 : 0] addra
      .douta(douta)  // output wire [7 : 0] douta
    );
    
    blk_mem_gen_1 your_instance_name1 (
      .clka(Trans_OUT),    // input wire clka
      .ena(1'b1),      // input wire ena
      .addra(addra1),  // input wire [9 : 0] addra
      .douta(douta1)  // output wire [7 : 0] douta
    );
  
    blk_mem_gen_2 your_instance_name2 (
      .clka(Trans_OUT),    // input wire clka
      .ena(1'b1),      // input wire ena
      .addra(addra2),  // input wire [9 : 0] addra
      .douta(douta2)  // output wire [7 : 0] douta
    );
    
    blk_mem_gen_3 your_instance_name3 (
      .clka(Trans_OUT),    // input wire clka
      .ena(1'b1),      // input wire ena
      .addra(addra3),  // input wire [9 : 0] addra
      .douta(douta3)  // output wire [7 : 0] douta
    );
    
    blk_mem_gen_4 your_instance_name4 (
      .clka(Trans_OUT),    // input wire clka
      .ena(1'b1),      // input wire ena
      .addra(addra4),  // input wire [9 : 0] addra
      .douta(douta4)  // output wire [7 : 0] douta
    );
    
    blk_mem_gen_5 your_instance_name5 (
      .clka(Trans_OUT),    // input wire clka
      .ena(1'b1),      // input wire ena
      .addra(addra5),  // input wire [10 : 0] addra
      .douta(douta5)  // output wire [7 : 0] douta
    );
    
    blk_mem_gen_6 your_instance_name6 (
      .clka(Trans_OUT),    // input wire clka
      .ena(1'b1),      // input wire ena
      .addra(addra6),  // input wire [10 : 0] addra
      .douta(douta6)  // output wire [7 : 0] douta
    );
    
    blk_mem_gen_7 your_instance_name7 (
      .clka(Trans_OUT),    // input wire clka
      .ena(1'b1),      // input wire ena
      .addra(addra7),  // input wire [10 : 0] addra
      .douta(douta7)  // output wire [7 : 0] douta
    );
    
    blk_mem_gen_8 your_instance_name8 (
      .clka(Trans_OUT),    // input wire clka
      .ena(1'b1),      // input wire ena
      .addra(addra8),  // input wire [10 : 0] addra
      .douta(douta8)  // output wire [7 : 0] douta
    );
    
    blk_mem_gen_9 your_instance_name9 (
      .clka(Trans_OUT),    // input wire clka
      .ena(1'b1),      // input wire ena
      .addra(addra9),  // input wire [8 : 0] addra
      .douta(douta9)  // output wire [7 : 0] douta
    );
    
    blk_mem_gen_11 your_instance_name11 (
      .clka(Trans_OUT),    // input wire clka
      .ena(1'b1),      // input wire ena
      .addra(addra11),  // input wire [11 : 0] addra
      .douta(douta11)  // output wire [7 : 0] douta
    );

    blk_mem_gen_12 your_instance_name12 (
      .clka(Trans_OUT),    // input wire clka
      .ena(1'b1),      // input wire ena
      .addra(addra12),  // input wire [13 : 0] addra
      .douta(douta12)  // output wire [7 : 0] douta
    );    

    blk_mem_gen_15 your_instance_name15 (
      .clka(Trans_OUT),    // input wire clka
      .ena(1'b1),      // input wire ena
      .addra(addra15),  // input wire [11 : 0] addra
      .douta(douta15)  // output wire [7 : 0] douta
    );
//    blk_mem_gen_13 your_instance_name13 (
//      .clka(Trans_OUT),    // input wire clka
//      .ena(1'b1),      // input wire ena
//      .addra(addra13),  // input wire [14 : 0] addra
//      .douta(douta13)  // output wire [7 : 0] douta
//    );    
 
//     blk_mem_gen_14 your_instance_name14 (
//          .clka(Trans_OUT),    // input wire clka
//          .ena(1'b1),      // input wire ena
//          .addra(addra14),  // input wire [14 : 0] addra
//          .douta(douta14)  // output wire [7 : 0] douta
//        );  
         
// Determining whether we move into the main screen, from the starting screen (the greenish screen with the "click the middle button to continue")
    reg ENABLE_CONTINUE;
    always@(posedge CLK) begin
    if(RESET)
        ENABLE_CONTINUE<=0;
    else if(mouse_middle == 1'b1)
        ENABLE_CONTINUE<=1'b1;
    end
    
// Logic to determine when to display one of the word images inside a bounding box
always@(Trans_OUT)
    begin
    if(Addr_X_Reg[9:2]>=55&&Addr_X_Reg[9:2]<=105&&Addr_Y_Reg[8:2]>=12&&Addr_Y_Reg[8:2]<=28)
        addra <= (Addr_X_Reg[9:2] - 55)+(Addr_Y_Reg[8:2] - 12)*50;
        
    if(Addr_X_Reg[9:2]>=55&&Addr_X_Reg[9:2]<=105&&Addr_Y_Reg[8:2]>=95&&Addr_Y_Reg[8:2]<=108)
        addra1 <= (Addr_X_Reg[9:2] - 55)+(Addr_Y_Reg[8:2] - 95)*50;
        
    if(Addr_X_Reg[9:2]>=10&&Addr_X_Reg[9:2]<=40&&Addr_Y_Reg[8:2]>=51&&Addr_Y_Reg[8:2]<=69)
        addra2 <= (Addr_X_Reg[9:2] - 10)+(Addr_Y_Reg[8:2] - 51)*30;
        
    if(Addr_X_Reg[9:2]>=117&&Addr_X_Reg[9:2]<=153&&Addr_Y_Reg[8:2]>=51&&Addr_Y_Reg[8:2]<=69)
        addra3 <= (Addr_X_Reg[9:2] - 117)+(Addr_Y_Reg[8:2] - 51)*36;
        
    if(Addr_X_Reg[9:2]>=65&&Addr_X_Reg[9:2]<=94&&Addr_Y_Reg[8:2]>=51&&Addr_Y_Reg[8:2]<=69)
        addra4 <= (Addr_X_Reg[9:2] - 65)+(Addr_Y_Reg[8:2] - 51)*29;  
          
    if(Addr_X_Reg[9:2]>=2&&Addr_X_Reg[9:2]<=47&&Addr_Y_Reg[8:2]>=3&&Addr_Y_Reg[8:2]<=36)
        addra5 <= (Addr_X_Reg[9:2] - 2)+(Addr_Y_Reg[8:2] - 3)*45; 
           
    if(Addr_X_Reg[9:2]>=113&&Addr_X_Reg[9:2]<=156&&Addr_Y_Reg[8:2]>=3&&Addr_Y_Reg[8:2]<=36)
        addra6 <= (Addr_X_Reg[9:2] - 113)+(Addr_Y_Reg[8:2] - 3)*43;
            
    if(Addr_X_Reg[9:2]>=2&&Addr_X_Reg[9:2]<=47&&Addr_Y_Reg[8:2]>=86&&Addr_Y_Reg[8:2]<=114)
        addra7 <= (Addr_X_Reg[9:2] - 2)+(Addr_Y_Reg[8:2] - 86)*45;  
               
    if(Addr_X_Reg[9:2]>=112&&Addr_X_Reg[9:2]<=157&&Addr_Y_Reg[8:2]>=86&&Addr_Y_Reg[8:2]<=115)
        addra8 <= (Addr_X_Reg[9:2] - 112)+(Addr_Y_Reg[8:2] - 86)*45; 
           
    if(Addr_X_Reg[9:2]>=Point_X&&Addr_X_Reg[9:2]<=(Point_X+15)&&Addr_Y_Reg[8:2]>=Point_Y&&Addr_Y_Reg[8:2]<=(Point_Y+24))
        addra9 <= (Addr_X_Reg[9:2] - Point_X)+(Addr_Y_Reg[8:2] - Point_Y)*15;
        
    if(Addr_X_Reg[9:0]>=221&&Addr_X_Reg[9:0]<=420&&Addr_Y_Reg[8:0]>=101&&Addr_Y_Reg[8:0]<=117&&ENABLE_CONTINUE==0)
        addra11 <= (Addr_X_Reg[9:0] - 220)+(Addr_Y_Reg[8:0] - 101)*200;
        
    if(Addr_X_Reg[9:0]>=Count_3&&Addr_X_Reg[9:0]<=(171+Count_3)&&Addr_Y_Reg[8:0]>=301&&Addr_Y_Reg[8:0]<=350&&ENABLE_CONTINUE==0)
        addra12 <= (Addr_X_Reg[9:0] - Count_3)+(Addr_Y_Reg[8:0] - 301)*172;

    if(Addr_X_Reg[9:0]>=271&&Addr_X_Reg[9:0]<=370&&Addr_Y_Reg[8:0]>=34&&Addr_Y_Reg[8:0]<=66&&ENABLE_CONTINUE==0)
        addra15 <= (Addr_X_Reg[9:0] - 271)+(Addr_Y_Reg[8:0] - 34)*100;
//    if(Addr_X_Reg[9:0]>=121&&Addr_X_Reg[9:0]<=520&&Addr_Y_Reg[8:0]>=101&&Addr_Y_Reg[8:0]<=173&&ENABLE_CONTINUE==0)
//        addra13 <= (Addr_X_Reg[9:0] - 121)+(Addr_Y_Reg[8:0] - 101)*400;

//    if(Addr_X_Reg[9:0]>=245&&Addr_X_Reg[9:0]<=396&&Addr_Y_Reg[8:0]>=356&&Addr_Y_Reg[8:0]<=475&&ENABLE_CONTINUE==0)
//        addra14 <= (Addr_X_Reg[9:0] - 245)+(Addr_Y_Reg[8:0] - 356)*152;                
    end
  
          
always @ (posedge CLK)
    begin
        if (Count_1 < HorzTimeToPulseWidthEnd)
            HS <= 0;
        else
            HS <= 1;
    end
    
always @ (posedge CLK)
        begin
            if (Count_2 < VertTimeToPulseWidthEnd)
                VS <= 0;
            else
                VS <= 1;
        end



always @ (posedge CLK)
    begin
        if (DisplayTimeValid) 
            begin
            // Logic to determine the output colours for the start screen
                if(Addr_X_Reg[9:0]>=221&&Addr_X_Reg[9:0]<=420&&Addr_Y_Reg[8:0]>=101&&Addr_Y_Reg[8:0]<=117&&ENABLE_CONTINUE==0)
                       begin
                        case(douta11)
                                              3'b111:
                                              VGA_Colour <= 8'hFF;
                                              3'b100:
                                              VGA_Colour <= 8'hF0;
                                              3'b101:
                                              VGA_Colour <= 8'hF0;
                                              3'b110:
                                              VGA_Colour <= 8'hF0;
                      endcase
                      end
                else if(Addr_X_Reg[9:0]>=271&&Addr_X_Reg[9:0]<=370&&Addr_Y_Reg[8:0]>=34&&Addr_Y_Reg[8:0]<=66&&ENABLE_CONTINUE==0)
                             begin
                              case(douta15)
                                                    3'b111:
                                                    VGA_Colour <= 8'hFF;
                                                    3'b100:
                                                    VGA_Colour <= 8'hF0;
                                                    3'b101:
                                                    VGA_Colour <= 8'hF0;
                                                    3'b110:
                                                    VGA_Colour <= 8'hF0;
                            endcase
                            end                      
               else if(Addr_X_Reg[9:0]>=Count_3&&Addr_X_Reg[9:0]<=(171+Count_3)&&Addr_Y_Reg[8:0]>=301&&Addr_Y_Reg[8:0]<=350&&ENABLE_CONTINUE==0)
                       begin
                         case(douta12)
                            3'b000:
                            VGA_Colour <= 8'h00;
                            3'b001:
                            VGA_Colour <= 8'hD8;
                            3'b011:
                            VGA_Colour <= 8'hD8;
                            3'b100:
                            VGA_Colour <= 8'h07;
                            3'b101:
                            VGA_Colour <= 8'h07;
                            3'b110:
                            VGA_Colour <= 8'h0F;
                            3'b111:
                            VGA_Colour <= 8'hFF;
                            endcase
                            end
              // Otherwise display FF in rest of screen background
               else if(ENABLE_CONTINUE==0)
                        VGA_Colour <= 8'hFF;
             // Logic for mouse cursor
               else if(Addr_X_Reg[9:2]>=Point_X&&Addr_X_Reg[9:2]<=(Point_X+15)&&Addr_Y_Reg[8:2]>=Point_Y&&Addr_Y_Reg[8:2]<=(Point_Y+24)&&ENABLE_CONTINUE==1'b1)
                    begin
                        case(douta9)
                          3'b000:
                          VGA_Colour <= 8'h00;
                          3'b111:
                          VGA_Colour <= 8'hD8;
                          endcase
                          end
               else if ((Addr_X_Reg[9:2] == 50 || Addr_Y_Reg[8:2] == 40 || Addr_X_Reg[9:2] == 110 || Addr_Y_Reg[8:2] == 80)&&ENABLE_CONTINUE==1'b1)
                    VGA_Colour <= 8'h00;
            // Logic for "Forward" word being displayed
               else if(Addr_X_Reg[9:2]>=55&&Addr_X_Reg[9:2]<=105&&Addr_Y_Reg[8:2]>=12&&Addr_Y_Reg[8:2]<=28&&ENABLE_CONTINUE==1'b1)
                    begin
                        case(douta)
                          3'b111:
                          VGA_Colour <= 8'hD8;
                          3'b100:
                          VGA_Colour <= 8'hF0;
                          3'b101:
                          VGA_Colour <= 8'hF0;
                          3'b110:
                          VGA_Colour <= 8'hF0;
                        endcase
                      end   
              // Logic for "Backward" word being displayed
               else if(Addr_X_Reg[9:2]>=55&&Addr_X_Reg[9:2]<=105&&Addr_Y_Reg[8:2]>=95&&Addr_Y_Reg[8:2]<=108&&ENABLE_CONTINUE==1'b1)
                           begin
                               case(douta1)
                                 3'b111:
                                 VGA_Colour <= 8'hD8;
                                 3'b100:
                                 VGA_Colour <= 8'hF0;
                                 3'b101:
                                 VGA_Colour <= 8'hF0;
                                 3'b110:
                                 VGA_Colour <= 8'hF0;
                               endcase
                             end      
              // Logic for "Left" word being displayed
               else if(Addr_X_Reg[9:2]>=10&&Addr_X_Reg[9:2]<=40&&Addr_Y_Reg[8:2]>=51&&Addr_Y_Reg[8:2]<=69&&ENABLE_CONTINUE==1'b1)
                                  begin
                                      case(douta2)
                                        3'b111:
                                        VGA_Colour <= 8'hD8;
                                        3'b100:
                                        VGA_Colour <= 8'hF0;
                                        3'b101:
                                        VGA_Colour <= 8'hF0;
                                        3'b110:
                                        VGA_Colour <= 8'hF0;
                                      endcase
                                    end   
              // Logic for "Right" word being displayed
               else if(Addr_X_Reg[9:2]>=117&&Addr_X_Reg[9:2]<=153&&Addr_Y_Reg[8:2]>=51&&Addr_Y_Reg[8:2]<=69&&ENABLE_CONTINUE==1'b1)
                                         begin
                                             case(douta3)
                                               3'b111:
                                               VGA_Colour <= 8'hD8;
                                               3'b100:
                                               VGA_Colour <= 8'hF0;
                                               3'b101:
                                               VGA_Colour <= 8'hF0;
                                               3'b110:
                                               VGA_Colour <= 8'hF0;
                                             endcase
                                           end   
               // Logic for "Idle" word being displayed
               else if(Addr_X_Reg[9:2]>=65&&Addr_X_Reg[9:2]<=94&&Addr_Y_Reg[8:2]>=51&&Addr_Y_Reg[8:2]<=69&&ENABLE_CONTINUE==1'b1)
                                                begin
                                                    case(douta4)
                                                      3'b111:
                                                      VGA_Colour <= 8'hD8;
                                                      3'b100:
                                                      VGA_Colour <= 8'hF2;
                                                      3'b101:
                                                      VGA_Colour <= 8'hF2;
                                                      3'b110:
                                                      VGA_Colour <= 8'hF2;
                                                    endcase
                                                  end  
               // Logic for "Forward Left" word being displayed
               else if(Addr_X_Reg[9:2]>=2&&Addr_X_Reg[9:2]<=47&&Addr_Y_Reg[8:2]>=3&&Addr_Y_Reg[8:2]<=36&&ENABLE_CONTINUE==1'b1)
                                                       begin
                                                           case(douta5)
                                                             3'b111:
                                                             VGA_Colour <= 8'hD8;
                                                             3'b100:
                                                             VGA_Colour <= 8'hF0;
                                                             3'b101:
                                                             VGA_Colour <= 8'hF0;
                                                             3'b110:
                                                             VGA_Colour <= 8'hF0;
                                                           endcase
                                                         end    
                // Logic for "Forward Right" word being displayed
               else if(Addr_X_Reg[9:2]>=113&&Addr_X_Reg[9:2]<=156&&Addr_Y_Reg[8:2]>=3&&Addr_Y_Reg[8:2]<=36&&ENABLE_CONTINUE==1'b1)
                                                              begin
                                                                  case(douta6)
                                                                    3'b111:
                                                                    VGA_Colour <= 8'hD8;
                                                                    3'b100:
                                                                    VGA_Colour <= 8'hF0;
                                                                    3'b101:
                                                                    VGA_Colour <= 8'hF0;
                                                                    3'b110:
                                                                    VGA_Colour <= 8'hF0;
                                                                  endcase
                                                                end  
                // Logic for "Backward Left" word being displayed
               else if(Addr_X_Reg[9:2]>=2&&Addr_X_Reg[9:2]<=47&&Addr_Y_Reg[8:2]>=86&&Addr_Y_Reg[8:2]<=114&&ENABLE_CONTINUE==1'b1)
                                                                     begin
                                                                         case(douta7)
                                                                           3'b111:
                                                                           VGA_Colour <= 8'hD8;
                                                                           3'b100:
                                                                           VGA_Colour <= 8'hF0;
                                                                           3'b101:
                                                                           VGA_Colour <= 8'hF0;
                                                                           3'b110:
                                                                           VGA_Colour <= 8'hF0;
                                                                         endcase
                                                                       end 
               // Logic for "Backward Right" word being displayed
               else if(Addr_X_Reg[9:2]>=112&&Addr_X_Reg[9:2]<=157&&Addr_Y_Reg[8:2]>=86&&Addr_Y_Reg[8:2]<=115&&ENABLE_CONTINUE==1'b1)
                                                                            begin
                                                                                case(douta8)
                                                                                  3'b111:
                                                                                  VGA_Colour <= 8'hD8;
                                                                                  3'b100:
                                                                                  VGA_Colour <= 8'hF0;
                                                                                  3'b101:
                                                                                  VGA_Colour <= 8'hF0;
                                                                                  3'b110:
                                                                                  VGA_Colour <= 8'hF0;
                                                                                endcase
                                                                              end  
                // Logic for when the left mouse is clicked and the area in a given region is highlighted red
                else if(Point_X>=0&&Point_X<=49&&Point_Y>=0&&Point_Y<=39&&mouse_click==1'b1&&ENABLE_CONTINUE==1'b1&&
                Addr_X_Reg[9:2]>=0&&Addr_X_Reg[9:2]<=49&&Addr_Y_Reg[8:2]>=0&&Addr_Y_Reg[8:2]<=39)
                        VGA_Colour <= 8'h07;
                        
                else if(Point_X>=51&&Point_X<=109&&Point_Y>=0&&Point_Y<=39&&mouse_click==1'b1&&ENABLE_CONTINUE==1'b1&&
                Addr_X_Reg[9:2]>=51&&Addr_X_Reg[9:2]<=109&&Addr_Y_Reg[8:2]>=0&&Addr_Y_Reg[8:2]<=39)
                        VGA_Colour <= 8'h07; 
                                       
                else if(Point_X>=111&&Point_X<=159&&Point_Y>=0&&Point_Y<=39&&mouse_click==1'b1&&ENABLE_CONTINUE==1'b1&&
                Addr_X_Reg[9:2]>=111&&Addr_X_Reg[9:2]<=159&&Addr_Y_Reg[8:2]>=0&&Addr_Y_Reg[8:2]<=39)
                        VGA_Colour <= 8'h07;  
                             
                else if(Point_X>=0&&Point_X<=49&&Point_Y>=41&&Point_Y<=79&&mouse_click==1'b1&&ENABLE_CONTINUE==1'b1&&
                Addr_X_Reg[9:2]>=0&&Addr_X_Reg[9:2]<=49&&Addr_Y_Reg[8:2]>=41&&Addr_Y_Reg[8:2]<=79)
                        VGA_Colour <= 8'h07; 
                            
                else if(Point_X>=111&&Point_X<=159&&Point_Y>=41&&Point_Y<=79&&mouse_click==1'b1&&ENABLE_CONTINUE==1'b1&&
                Addr_X_Reg[9:2]>=111&&Addr_X_Reg[9:2]<=159&&Addr_Y_Reg[8:2]>=41&&Addr_Y_Reg[8:2]<=79)
                        VGA_Colour <= 8'h07;  
                         
                else if(Point_X>=0&&Point_X<=49&&Point_Y>=81&&Point_Y<=119&&mouse_click==1'b1&&ENABLE_CONTINUE==1'b1&&
                Addr_X_Reg[9:2]>=0&&Addr_X_Reg[9:2]<=49&&Addr_Y_Reg[8:2]>=81&&Addr_Y_Reg[8:2]<=119)
                        VGA_Colour <= 8'h07;  
                        
                else if(Point_X>=51&&Point_X<=109&&Point_Y>=81&&Point_Y<=119&&mouse_click==1'b1&&ENABLE_CONTINUE==1'b1&&
                Addr_X_Reg[9:2]>=51&&Addr_X_Reg[9:2]<=109&&Addr_Y_Reg[8:2]>=81&&Addr_Y_Reg[8:2]<=119)
                        VGA_Colour <= 8'h07; 
                        
                else if(Point_X>=111&&Point_X<=159&&Point_Y>=81&&Point_Y<=119&&mouse_click==1'b1&&ENABLE_CONTINUE==1'b1&&
                Addr_X_Reg[9:2]>=111&&Addr_X_Reg[9:2]<=159&&Addr_Y_Reg[8:2]>=81&&Addr_Y_Reg[8:2]<=119)
                        VGA_Colour <= 8'h07;  
                                                                                                                                                                                                                                                                                                                                                                                                          
                else if(ENABLE_CONTINUE==1'b1)
                    VGA_Colour <= 8'hD8;    
                      
                else 
                    VGA_Colour <= 0;         
            end
        else
            VGA_Colour <= 8'h00;
    end

    

always @ (posedge CLK)
        begin
            if (DisplayTimeValid)
                begin
                    Addr_X_Reg <= Count_1 - HorzTimeToBackPorchEnd; 
                    Addr_Y_Reg <= Count_2 - VertTimeToBackPorchEnd;
                end
            
            else
                begin
                    Addr_X_Reg <= 0;
                    Addr_Y_Reg <= 0;
                end
        end
       
    
// Finally assigning the two registers to their respective output ports        
    
assign Addr_X = Addr_X_Reg[9:2];
assign Addr_Y = Addr_Y_Reg[8:2];

endmodule
