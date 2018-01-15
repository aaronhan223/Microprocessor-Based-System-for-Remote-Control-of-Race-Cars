This project develops an FPGA-based system to control toy cars, while the FPGA coordinates various peripherals such as PS/2 mouse interface, IR transmitter module and VGA display to control the motion of toy cars. 

As a substitution of FPGA, I designed an 8-bit single-core processor with a load-store architecture using Verilog, which achieves the same functionality. 

The main module that coordinate all the peripherals is the TopWrapper.v file in the source folder.
