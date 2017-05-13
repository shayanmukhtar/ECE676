`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/12/2017 09:30:00 PM
// Design Name: 
// Module Name: imageLowPassFilter
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


module imageLowPassFilter(
input clock,                
input resetn,
input [17:0] addr_in,
input [2:0] d_in,
input we_in,
output [17:0] address_out,
output we_out,
output [2:0] data_out
);

enum logic [4:0] {
    S_IDLE,
    S_INTRO_1,
    S_INTRO_2,
    S_INTRO_3,
    S_INTRO_4,
    S_INTRO_5,
    S_INTRO_6,
    S_INTRO_7,
    S_INTRO_8,
    S_INTRO_9,
    S_INTRO_10,
    S_COMMON_0,
    S_COMMON_1,
    S_COMMON_2,
    S_END_ROW,
    S_PREP_NEXT_ROW
} flowState;

/*DPRAM signals*/
logic [17:0] address_b;
logic [2:0] d_out_b;
logic [8:0] col_req, col_out;    //0 to 319
logic [8:0] row_req, row_out;    //0 to 479
logic [8:0] shift_reg_red, shift_reg_green, shift_reg_blue;     //3 bit wide shift register of length 9
logic [17:0] address_out_reg;
logic we_out_reg;
logic [3:0] red_sum, green_sum, blue_sum;
assign we_out = we_out_reg;
/*320 = 256 + 64 which are all shifts by  bits*/
/*address generally equals [[320*row_counter + col_counter]] */
assign address_b = {row_req[8:0],8'b00000000} + {row_req[8:0],6'b000000} + col_req[8:0];
assign address_out = {row_out[8:0],8'b00000000} + {row_out[8:0],6'b000000} + col_out[8:0];
/*Data out is the summation of the 3 different shift registers averaged - this is how we achieve low pass filtering*/
/*R*/
assign red_sum = shift_reg_red[0] + shift_reg_red[1] + shift_reg_red[2] + shift_reg_red[3] + shift_reg_red[4] + shift_reg_red[5] + shift_reg_red[6] + shift_reg_red[7] + shift_reg_red[8];
assign data_out[0] = (red_sum >= 4'd5) ? 1'b1 : 1'b0;//((red_sum > green_sum) && (red_sum > blue_sum)) ? 1'b1 : 1'b0;
/*G*/
assign green_sum = shift_reg_green[0] + shift_reg_green[1] + shift_reg_green[2] + shift_reg_green[3] + shift_reg_green[4] + shift_reg_green[5] + shift_reg_green[6] + shift_reg_green[7] + shift_reg_green[8];
assign data_out[1] = (green_sum >= 4'd5) ? 1'b1 : 1'b0;
/*B*/
assign blue_sum = shift_reg_blue[0] + shift_reg_blue[1] + shift_reg_blue[2] + shift_reg_blue[3] + shift_reg_blue[4] + shift_reg_blue[5] + shift_reg_blue[6] + shift_reg_blue[7] + shift_reg_blue[8];
assign data_out[2] = (blue_sum >= 4'd5) ? 1'b1 : 1'b0;
/*
XPM_MEMORY instantiation template for true dual port RAM configurations
Refer to the targeted device family architecture libraries guide for XPM_MEMORY documentation
=======================================================================================================================

Parameter usage table, organized as follows:
+---------------------------------------------------------------------------------------------------------------------+
| Parameter name       | Data type          | Restrictions, if applicable                                             |
|---------------------------------------------------------------------------------------------------------------------|
| Description                                                                                                         |
+---------------------------------------------------------------------------------------------------------------------+
+---------------------------------------------------------------------------------------------------------------------+
| MEMORY_SIZE          | Integer            | Must be integer multiple of [WRITE|READ]_DATA_WIDTH_[A|B]               |
|---------------------------------------------------------------------------------------------------------------------|
| Specify the total memory array size, in bits.                                                                       |
| For example, enter 65536 for a 2kx32 RAM.                                                                           |
| When ECC is enabled and set to "encode_only", then the memory size has to be multiples of READ_DATA_WIDTH_[A|B]     |
| When ECC is enabled and set to "decode_only", then the memory size has to be multiples of WRITE_DATA_WIDTH_[A|B]    |
+---------------------------------------------------------------------------------------------------------------------+
| MEMORY_PRIMITIVE     | String             | Must be "auto", "distributed", "block" or "ultra"                       |
|---------------------------------------------------------------------------------------------------------------------|
| Designate the memory primitive (resource type) to use:                                                              |
|   "auto": Allow Vivado Synthesis to choose                                                                          |
|   "distributed": Distributed memory                                                                                 |
|   "block": Block memory                                                                                             |
|   "ultra": Ultra RAM memory                                                                                         |
+---------------------------------------------------------------------------------------------------------------------+
| CLOCKING_MODE        | String             | Must be "common_clock" or "independent_clock"                           |
|---------------------------------------------------------------------------------------------------------------------|
| Designate whether port A and port B are clocked with a common clock or with independent clocks:                     |
|   "common_clock": Common clocking; clock both port A and port B with clka                                           |
|   "independent_clock": Independent clocking; clock port A with clka and port B with clkb                            |
+---------------------------------------------------------------------------------------------------------------------+
| MEMORY_INIT_FILE     | String             | Must be exactly "none" or the name of the file (in quotes)              |
|---------------------------------------------------------------------------------------------------------------------|
| Specify "none" (including quotes) for no memory initialization, or specify the name of a memory initialization file:|
|   Enter only the name of the file with .mem extension, including quotes but without path (e.g. "my_file.mem").      |
|   File format must be ASCII and consist of only hexadecimal values organized into the specified depth by            |
|   narrowest data width generic value of the memory.  See the Memory File (MEM) section for more                     |
|   information on the syntax. Initialization of memory happens through the file name specified only when parameter   |
|   MEMORY_INIT_PARAM value is equal to "".                                                                           |                                                                                        |
|   When using XPM_MEMORY in a project, add the specified file to the Vivado project as a design source.              |
+---------------------------------------------------------------------------------------------------------------------+
| MEMORY_INIT_PARAM   | String             | Must be exactly "" or the string of hex characters (in quotes)           |
|---------------------------------------------------------------------------------------------------------------------|
| Specify "" or "0" (including quotes) for no memory initialization through parameter, or specify the string          |
| containing the hex characters.Enter only hex characters and each location separated by delimiter(,).                |
| Parameter format must be ASCII and consist of only hexadecimal values organized into the specified depth by         |
| narrowest data width generic value of the memory.  For example, if the narrowest data width is 8, and the depth of  |
| memory is 8 locations, then the parameter value should be passed as shown below.                                    |
|   parameter MEMORY_INIT_PARAM = "AB,CD,EF,1,2,34,56,78"                                                             |
|                                  |                   |                                                              |
|                                  0th                7th                                                             |
|                                location            location                                                         |
+---------------------------------------------------------------------------------------------------------------------+
| USE_MEM_INIT         | Integer             | Must be 0 or 1                                                         |
|---------------------------------------------------------------------------------------------------------------------|
| Specify 1 to enable the generation of below message and 0 to disable the generation of below message completely.    |
| Note: This message gets generated only when there is no Memory Initialization specified either through file or      |
| Parameter.                                                                                                          |
|    INFO : MEMORY_INIT_FILE and MEMORY_INIT_PARAM together specifies no memory initialization.                       |
|    Initial memory contents will be all 0's                                                                          |
+---------------------------------------------------------------------------------------------------------------------+
| WAKEUP_TIME          | String             | Must be "disable_sleep" or "use_sleep_pin"                              |
|---------------------------------------------------------------------------------------------------------------------|
| Specify "disable_sleep" to disable dynamic power saving option, and specify "use_sleep_pin" to enable the           |
| dynamic power saving option                                                                                         |
+---------------------------------------------------------------------------------------------------------------------+
| ECC_MODE             | String              | Must be "no_ecc", "encode_only", "decode_only"                         |
|                                            | or "both_encode_and_decode".                                           |
|---------------------------------------------------------------------------------------------------------------------|
| Specify ECC mode on both ports of the memory primitive                                                              |
+---------------------------------------------------------------------------------------------------------------------+
| AUTO_SLEEP_TIME      | Integer             | Must be 0 or 3-15                                                      |
|---------------------------------------------------------------------------------------------------------------------|
| Number of clk[a|b] cycles to auto-sleep, if feature is available in architecture                                    |
|   0 : Disable auto-sleep feature                                                                                    |
|   3-15 : Number of auto-sleep latency cycles                                                                        |
|   Do not change from the value provided in the template instantiation                                               |
+---------------------------------------------------------------------------------------------------------------------+
| MESSAGE_CONTROL      | Integer            | Must be 0 or 1                                                          |
|---------------------------------------------------------------------------------------------------------------------|
| Specify 1 to enable the dynamic message reporting such as collision warnings, and 0 to disable the message reporting|
+---------------------------------------------------------------------------------------------------------------------+
| WRITE_DATA_WIDTH_A   | Integer            | Must be > 0 and equal to the value of READ_DATA_WIDTH_A                 |
|---------------------------------------------------------------------------------------------------------------------|
| Specify the width of the port A write data input port dina, in bits.                                                |
| The values of WRITE_DATA_WIDTH_A and READ_DATA_WIDTH_A must be equal.                                               |
| When ECC is enabled and set to "encode_only" or "both_encode_and_decode", then WRITE_DATA_WIDTH_A has to be         |
| multiples of 64-bits                                                                                                |
| When ECC is enabled and set to "decode_only", then WRITE_DATA_WIDTH_A has to be multiples of 72-bits                |
+---------------------------------------------------------------------------------------------------------------------+
| READ_DATA_WIDTH_A    | Integer            | Must be > 0 and equal to the value of WRITE_DATA_WIDTH_A                |
|---------------------------------------------------------------------------------------------------------------------|
| Specify the width of the port A read data output port douta, in bits.                                               |
| The values of READ_DATA_WIDTH_A and WRITE_DATA_WIDTH_A must be equal.                                               |
| When ECC is enabled and set to "encode_only", then READ_DATA_WIDTH_A has to be multiples of 72-bits                 |
| When ECC is enabled and set to "decode_only" or "both_encode_and_decode", then READ_DATA_WIDTH_A has to be          |
| multiples of 64-bits                                                                                                |
+---------------------------------------------------------------------------------------------------------------------+
| BYTE_WRITE_WIDTH_A   | Integer            | Must be 8, 9, or the value of WRITE_DATA_WIDTH_A                        |
|---------------------------------------------------------------------------------------------------------------------|
| To enable byte-wide writes on port A, specify the byte width, in bits:                                              |
|   8: 8-bit byte-wide writes, legal when WRITE_DATA_WIDTH_A is an integer multiple of 8                              |
|   9: 9-bit byte-wide writes, legal when WRITE_DATA_WIDTH_A is an integer multiple of 9                              |
| Or to enable word-wide writes on port A, specify the same value as for WRITE_DATA_WIDTH_A.                          |
+---------------------------------------------------------------------------------------------------------------------+
| ADDR_WIDTH_A         | Integer            | Must be >= ceiling of log2(MEMORY_SIZE/[WRITE|READ]_DATA_WIDTH_A)       |
|---------------------------------------------------------------------------------------------------------------------|
| Specify the width of the port A address port addra, in bits.                                                        |
| Must be large enough to access the entire memory from port A, i.e. >= $clog2(MEMORY_SIZE/[WRITE|READ]_DATA_WIDTH_A).|
+---------------------------------------------------------------------------------------------------------------------+
| READ_RESET_VALUE_A   | String             |                                                                         |
|---------------------------------------------------------------------------------------------------------------------|
| Specify the reset value of the port A final output register stage in response to rsta input port is assertion.      |
| As this parameter is a string, please specify the hex values inside double quotes. As an example,                   |
| If the read data width is 8, then specify READ_RESET_VALUE_A = "EA";                                                |
| When ECC is enabled, then reset value is not supported                                                              |
+---------------------------------------------------------------------------------------------------------------------+
| READ_LATENCY_A       | Integer             | Must be >= 0 for distributed memory, or >= 1 for block memory          |
|---------------------------------------------------------------------------------------------------------------------|
| Specify the number of register stages in the port A read data pipeline. Read data output to port douta takes this   |
| number of clka cycles.                                                                                              |
| To target block memory, a value of 1 or larger is required: 1 causes use of memory latch only; 2 causes use of      |
| output register. To target distributed memory, a value of 0 or larger is required: 0 indicates combinatorial output.|
| Values larger than 2 synthesize additional flip-flops that are not retimed into memory primitives.                  |
+---------------------------------------------------------------------------------------------------------------------+
| WRITE_MODE_A         | String             | Must be "write_first", "read_first", or "no_change".                    |
|                                           | For distributed memory, must be read_first.                             |
|---------------------------------------------------------------------------------------------------------------------|
| Designate the write mode of port A:                                                                                 |
|   "write_first": Write-first write mode                                                                             |
|   "read_first" : Read-first write mode                                                                              |
|   "no_change"  : No-change write mode                                                                               |
| Distributed memory configurations require read-first write mode.                                                    |
+---------------------------------------------------------------------------------------------------------------------+
| WRITE_DATA_WIDTH_B   | Integer            | Must be > 0 and equal to the value of READ_DATA_WIDTH_B                 |
|---------------------------------------------------------------------------------------------------------------------|
| Specify the width of the port B write data input port dinb, in bits.                                                |
| The values of WRITE_DATA_WIDTH_B and READ_DATA_WIDTH_B must be equal.                                               |
| When ECC is enabled and set to "encode_only" or "both_encode_and_decode", then WRITE_DATA_WIDTH_B has to be         |
| multiples of 64-bits                                                                                                |
| When ECC is enabled and set to "decode_only", then WRITE_DATA_WIDTH_B has to be multiples of 72-bits                |
+---------------------------------------------------------------------------------------------------------------------+
| READ_DATA_WIDTH_B    | Integer            | Must be > 0 and equal to the value of WRITE_DATA_WIDTH_B                |
|---------------------------------------------------------------------------------------------------------------------|
| Specify the width of the port B read data output port doutb, in bits.                                               |
| The values of READ_DATA_WIDTH_B and WRITE_DATA_WIDTH_B must be equal.                                               |
| When ECC is enabled and set to "encode_only", then READ_DATA_WIDTH_B has to be multiples of 72-bits                 |
| When ECC is enabled and set to "decode_only" or "both_encode_and_decode", then READ_DATA_WIDTH_B has to be          |
| multiples of 64-bits                                                                                                |
+---------------------------------------------------------------------------------------------------------------------+
| BYTE_WRITE_WIDTH_B   | Integer            | Must be 8, 9, or the value of WRITE_DATA_WIDTH_B                        |
|---------------------------------------------------------------------------------------------------------------------|
| To enable byte-wide writes on port B, specify the byte width, in bits:                                              |
|   8: 8-bit byte-wide writes, legal when WRITE_DATA_WIDTH_B is an integer multiple of 8                              |
|   9: 9-bit byte-wide writes, legal when WRITE_DATA_WIDTH_B is an integer multiple of 9                              |
| Or to enable word-wide writes on port B, specify the same value as for WRITE_DATA_WIDTH_B.                          |
+---------------------------------------------------------------------------------------------------------------------+
| ADDR_WIDTH_B         | Integer            | Must be >= ceiling of log2(MEMORY_SIZE/[WRITE|READ]_DATA_WIDTH_B)       |
|---------------------------------------------------------------------------------------------------------------------|
| Specify the width of the port B address port addrb, in bits.                                                        |
| Must be large enough to access the entire memory from port B, i.e. >= $clog2(MEMORY_SIZE/[WRITE|READ]_DATA_WIDTH_B).|
+---------------------------------------------------------------------------------------------------------------------+
| READ_RESET_VALUE_B   | String             |                                                                         |
|---------------------------------------------------------------------------------------------------------------------|
| Specify the reset value of the port B final output register stage in response to rstb input port is assertion.      |
| As this parameter is a string, please specify the hex values inside double quotes. As an example,                   |
| If the read data width is 8, then specify READ_RESET_VALUE_B = "EA";                                                |
| When ECC is enabled, then reset value is not supported                                                              |
+---------------------------------------------------------------------------------------------------------------------+
| READ_LATENCY_B       | Integer             | Must be >= 0 for distributed memory, or >= 1 for block memory          |
|---------------------------------------------------------------------------------------------------------------------|
| Specify the number of register stages in the port B read data pipeline. Read data output to port doutb takes this   |
| number of clkb cycles (clka when CLOCKING_MODE is "common_clock").                                                  |
| To target block memory, a value of 1 or larger is required: 1 causes use of memory latch only; 2 causes use of      |
| output register. To target distributed memory, a value of 0 or larger is required: 0 indicates combinatorial output.|
| Values larger than 2 synthesize additional flip-flops that are not retimed into memory primitives.                  |
+---------------------------------------------------------------------------------------------------------------------+
| WRITE_MODE_B         | String              | Must be "write_first", "read_first", or "no_change".                   |
|                                            | For distributed memory, must be "read_first".                          |
|---------------------------------------------------------------------------------------------------------------------|
| Designate the write mode of port B:                                                                                 |
|   "write_first": Write-first write mode                                                                             |
|   "read_first": Read-first write mode                                                                               |
|   "no_change": No-change write mode                                                                                 |
| Distributed memory configurations require read-first write mode.                                                    |
+---------------------------------------------------------------------------------------------------------------------+

Port usage table, organized as follows:
+---------------------------------------------------------------------------------------------------------------------+
| Port name      | Direction | Size, in bits                         | Domain | Sense       | Handling if unused      |
|---------------------------------------------------------------------------------------------------------------------|
| Description                                                                                                         |
+---------------------------------------------------------------------------------------------------------------------+
+---------------------------------------------------------------------------------------------------------------------+
| sleep          | Input     | 1                                     |        | Active-high | Tie to 1'b0             |
|---------------------------------------------------------------------------------------------------------------------|
| sleep signal to enable the dynamic power saving feature.                                                            |
+---------------------------------------------------------------------------------------------------------------------+
| clka           | Input     | 1                                     |        | Rising edge | Required                |
|---------------------------------------------------------------------------------------------------------------------|
| Clock signal for port A. Also clocks port B when parameter CLOCKING_MODE is "common_clock".                         |
+---------------------------------------------------------------------------------------------------------------------+
| rsta           | Input     | 1                                     | clka   | Active-high | Tie to 1'b0             |
|---------------------------------------------------------------------------------------------------------------------|
| Reset signal for the final port A output register stage.                                                            |
| Synchronously resets output port douta to the value specified by parameter READ_RESET_VALUE_A.                      |
+---------------------------------------------------------------------------------------------------------------------+
| ena            | Input     | 1                                     | clka   | Active-high | Tie to 1'b1             |
|---------------------------------------------------------------------------------------------------------------------|
| Memory enable signal for port A.                                                                                    |
| Must be high on clock cycles when read or write operations are initiated. Pipelined internally.                     |
+---------------------------------------------------------------------------------------------------------------------+
| regcea         | Input     | 1                                     | clka   | Active-high | Tie to 1'b1             |
|---------------------------------------------------------------------------------------------------------------------|
| Clock Enable for the last register stage on the output data path.                                                   |
+---------------------------------------------------------------------------------------------------------------------+
| wea            | Input     | WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A | clka   | Active-high | Required                |
|---------------------------------------------------------------------------------------------------------------------|
| Write enable vector for port A input data port dina. 1 bit wide when word-wide writes are used.                     |
| In byte-wide write configurations, each bit controls the writing one byte of dina to address addra.                 |
| For example, to synchronously write only bits [15:8] of dina when WRITE_DATA_WIDTH_A is 32, wea would be 4'b0010.   |
+---------------------------------------------------------------------------------------------------------------------+
| addra          | Input     | ADDR_WIDTH_A                          | clka   |             | Required                |
|---------------------------------------------------------------------------------------------------------------------|
| Address for port A write and read operations.                                                                       |
+---------------------------------------------------------------------------------------------------------------------+
| dina           | Input     | WRITE_DATA_WIDTH_A                    | clka   |             | Required                |
|---------------------------------------------------------------------------------------------------------------------|
| Data input for port A write operations.                                                                             |
+---------------------------------------------------------------------------------------------------------------------+
| injectsbiterra | Input     | 1                                     | clka   | Active-high | Tie to 1'b0             |
|---------------------------------------------------------------------------------------------------------------------|
| Controls single bit error injection on input data when ECC enabled (Error injection capability is not available in  |
| "decode_only" mode).
+---------------------------------------------------------------------------------------------------------------------+
| injectdbiterra | Input     | 1                                     | clka   | Active-high | Tie to 1'b0             |
|---------------------------------------------------------------------------------------------------------------------|
| Controls double bit error injection on input data when ECC enabled (Error injection capability is not available in  |
| "decode_only" mode).                                                                                                |
+---------------------------------------------------------------------------------------------------------------------+
| douta          | Output   | READ_DATA_WIDTH_A                      | clka   |             | Required                |
|---------------------------------------------------------------------------------------------------------------------|
| Data output for port A read operations.                                                                             |
+---------------------------------------------------------------------------------------------------------------------+
| sbiterra       | Output   | 1                                      | clka   | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Status signal to indicate single bit error occurrence on the data output of port A.                                 |
+---------------------------------------------------------------------------------------------------------------------+
| dbiterra       | Output   | 1                                      | clka   | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Status signal to indicate double bit error occurrence on the data output of port A.                                 |
+---------------------------------------------------------------------------------------------------------------------+
| clkb           | Input     | 1                                     |        | Rising edge | Tie to 1'b0             |
|---------------------------------------------------------------------------------------------------------------------|
| Clock signal for port B when parameter CLOCKING_MODE is "independent_clock".                                        |
| Unused when parameter CLOCKING_MODE is "common_clock".                                                              |
+---------------------------------------------------------------------------------------------------------------------+
| rstb           | Input     | 1                                     | *      | Active-high | Tie to 1'b0             |
|---------------------------------------------------------------------------------------------------------------------|
| Reset signal for the final port B output register stage.                                                            |
| Synchronously resets output port doutb to the value specified by parameter READ_RESET_VALUE_B.                      |
+---------------------------------------------------------------------------------------------------------------------+
| enb            | Input     | 1                                     | *      | Active-high | Tie to 1'b1             |
|---------------------------------------------------------------------------------------------------------------------|
| Memory enable signal for port B.                                                                                    |
| Must be high on clock cycles when read or write operations are initiated. Pipelined internally.                     |
+---------------------------------------------------------------------------------------------------------------------+
| regceb         | Input     | 1                                     | *      | Active-high | Tie to 1'b1             |
|---------------------------------------------------------------------------------------------------------------------|
| Clock Enable for the last register stage on the output data path.                                                   |
+---------------------------------------------------------------------------------------------------------------------+
| web            | Input     | WRITE_DATA_WIDTH_B/BYTE_WRITE_WIDTH_B | *      | Active-high | Required                |
|---------------------------------------------------------------------------------------------------------------------|
| Write enable vector for port B input data port dinb. 1 bit wide when word-wide writes are used.                     |
| In byte-wide write configurations, each bit controls the writing one byte of dinb to address addrb.                 |
| For example, to synchronously write only bits [15:8] of dinb when WRITE_DATA_WIDTH_B is 32, web would be 4'b0010.   |
+---------------------------------------------------------------------------------------------------------------------+
| addrb          | Input     | ADDR_WIDTH_B                          | *      |             | Required                |
|---------------------------------------------------------------------------------------------------------------------|
| Address for port B write and read operations.                                                                       |
+---------------------------------------------------------------------------------------------------------------------+
| dinb           | Input     | WRITE_DATA_WIDTH_B                    | *      |             | Required                |
|---------------------------------------------------------------------------------------------------------------------|
| Data input for port B write operations.                                                                             |
+---------------------------------------------------------------------------------------------------------------------+
| injectsbiterrb | Input     | 1                                     | *      | Active-high | Tie to 1'b0             |
|---------------------------------------------------------------------------------------------------------------------|
| Controls single bit error injection on input data when ECC enabled (Error injection capability is not available in  |
| "decode_only" mode).                                                                                                |
+---------------------------------------------------------------------------------------------------------------------+
| injectdbiterrb | Input     | 1                                     | *      | Active-high | Tie to 1'b0             |
|---------------------------------------------------------------------------------------------------------------------|
| Controls double bit error injection on input data when ECC enabled (Error injection capability is not available in  |
| "decode_only" mode).                                                                                                |
+---------------------------------------------------------------------------------------------------------------------+
| doutb          | Output   | READ_DATA_WIDTH_B                      | *      |             | Required                |
|---------------------------------------------------------------------------------------------------------------------|
| Data output for port B read operations.                                                                             |
+---------------------------------------------------------------------------------------------------------------------+
| sbiterrb       | Output   | 1                                      | *      | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Status signal to indicate single bit error occurrence on the data output of port B.                                 |
+---------------------------------------------------------------------------------------------------------------------+
| dbiterrb       | Output   | 1                                      | *      | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Status signal to indicate double bit error occurrence on the data output of port A.                                 |
+---------------------------------------------------------------------------------------------------------------------+
| * clka when parameter CLOCKING_MODE is "common_clock". clkb when parameter CLOCKING_MODE is "independent_clock".    |
+---------------------------------------------------------------------------------------------------------------------+
*/

//  xpm_memory_tdpram   : In order to incorporate this function into the design, the following instance declaration
//       Verilog        : needs to be placed in the body of the design code.  The default values for the parameters
//       instance       : may be changed to meet design requirements.  The instance name (xpm_memory_tdpram)
//     declaration      : and/or the port declarations within the parenthesis may be changed to properly reference and
//         code         : connect this function to the design.  All inputs and outputs must be connected.

//  <--Cut the following instance declaration and paste it into the design-->

// xpm_memory_tdpram: True Dual Port RAM
// Xilinx Parameterized Macro, Version 2016.4
xpm_memory_tdpram # (

  // Common module parameters
  .MEMORY_SIZE        (460800),            //positive integer
  .MEMORY_PRIMITIVE   ("auto"),          //string; "auto", "distributed", "block" or "ultra";
  .CLOCKING_MODE      ("independent_clock"),  //string; "common_clock", "independent_clock" 
  .MEMORY_INIT_FILE   ("none"),          //string; "none" or "<filename>.mem" 
  .MEMORY_INIT_PARAM  (""    ),          //string;
  .USE_MEM_INIT       (0),               //integer; 0,1
  .WAKEUP_TIME        ("disable_sleep"), //string; "disable_sleep" or "use_sleep_pin" 
  .MESSAGE_CONTROL    (0),               //integer; 0,1
  .ECC_MODE           ("no_ecc"),        //string; "no_ecc", "encode_only", "decode_only" or "both_encode_and_decode" 
  .AUTO_SLEEP_TIME    (0),               //Do not Change

  // Port A module parameters
  .WRITE_DATA_WIDTH_A (3),              //positive integer
  .READ_DATA_WIDTH_A  (3),              //positive integer
  .BYTE_WRITE_WIDTH_A (3),              //integer; 8, 9, or WRITE_DATA_WIDTH_A value
  .ADDR_WIDTH_A       (18),               //positive integer
  .READ_RESET_VALUE_A ("0"),             //string
  .READ_LATENCY_A     (1),               //non-negative integer
  .WRITE_MODE_A       ("no_change"),     //string; "write_first", "read_first", "no_change" 

  // Port B module parameters
  .WRITE_DATA_WIDTH_B (3),              //positive integer
  .READ_DATA_WIDTH_B  (3),              //positive integer
  .BYTE_WRITE_WIDTH_B (3),              //integer; 8, 9, or WRITE_DATA_WIDTH_B value
  .ADDR_WIDTH_B       (18),               //positive integer
  .READ_RESET_VALUE_B ("0"),             //vector of READ_DATA_WIDTH_B bits
  .READ_LATENCY_B     (1),               //non-negative integer
  .WRITE_MODE_B       ("no_change")      //string; "write_first", "read_first", "no_change" 

) xpm_memory_tdpram_inst (

  // Common module ports
  .sleep          (1'b0),

  // Port A module ports
  .clka           (clock),
  .rsta           (~resetn),
  .ena            (1'b1),
  .regcea         (1'b1),
  .wea            ({we_in, we_in, we_in, we_in}),
  .addra          (addr_in),
  .dina           (d_in),
  .injectsbiterra (1'b0),
  .injectdbiterra (1'b0),
  .douta          (),
  .sbiterra       (),
  .dbiterra       (),

  // Port B module ports
  .clkb           (clock),
  .rstb           (~resetn),
  .enb            (1'b1),
  .regceb         (1'b1),
  .web            (4'b0000),
  .addrb          (address_b),
  .dinb           (1'b0),
  .injectsbiterrb (1'b0),
  .injectdbiterrb (1'b0),
  .doutb          (d_out_b),
  .sbiterrb       (),
  .dbiterrb       ()

);

// End of xpm_memory_tdpram instance declaration

logic we_reg, we_rising_edge;
logic full_frame_flag;      //signal indicating the first full frame is in, we can now begin our image processing


/*rising edge detection for we*/
always @(posedge clock) begin
    if (~resetn) begin
        we_reg <= 1'b0;
        full_frame_flag <= 1'b0;
    end else begin
        we_reg <= we_in;
        if (addr_in == 18'd153599) begin
            full_frame_flag <= 1'b1;
        end
    end
end
assign we_rising_edge = (~we_reg & we_in);

/*keep convolve the low pass averaging filter 3x3 over the incoming image*/
always @(posedge clock) begin
    if (~resetn) begin 
        col_req <= 9'd0;
        row_req <= 9'd0;
        col_out <= 9'd0;
        row_out <= 9'd1;
        shift_reg_red <= 9'd0;
        shift_reg_green <= 9'd0;
        shift_reg_blue <= 9'd0;
        address_out_reg <= 18'd0;
        we_out_reg <= 1'b0;
        flowState <= S_IDLE;
    end else begin
        case (flowState)
            S_IDLE: begin
                col_req <= 9'd1;
                row_req <= 9'd0;
                col_out <= 9'd2;
                row_out <= 9'd1;
                if (full_frame_flag) begin
                    flowState <= S_INTRO_1;
                end
            end
            S_INTRO_1: begin
                row_req <= row_out;
                flowState <= S_INTRO_2;
            end
            S_INTRO_2: begin
                row_req <= row_out + 9'd1;
                shift_reg_red <= {shift_reg_red[7:0], d_out_b[0]};
                shift_reg_green <= {shift_reg_green[7:0], d_out_b[1]};
                shift_reg_blue <= {shift_reg_blue[7:0], d_out_b[2]};
                flowState <= S_INTRO_3;
            end
            S_INTRO_3: begin
                col_req <= 9'd2;
                row_req <= row_out - 9'd1;
                shift_reg_red <= {shift_reg_red[7:0], d_out_b[0]};
                shift_reg_green <= {shift_reg_green[7:0], d_out_b[1]};
                shift_reg_blue <= {shift_reg_blue[7:0], d_out_b[2]};
                flowState <= S_INTRO_4;
            end
            S_INTRO_4: begin
                row_req <= row_out;
                shift_reg_red <= {shift_reg_red[7:0], d_out_b[0]};
                shift_reg_green <= {shift_reg_green[7:0], d_out_b[1]};
                shift_reg_blue <= {shift_reg_blue[7:0], d_out_b[2]};
                flowState <= S_INTRO_5;
            end
            S_INTRO_5: begin
                row_req <= 9'd5;
                row_req <= row_out + 9'd1;
                shift_reg_red <= {shift_reg_red[7:0], d_out_b[0]};
                shift_reg_green <= {shift_reg_green[7:0], d_out_b[1]};
                shift_reg_blue <= {shift_reg_blue[7:0], d_out_b[2]};
                flowState <= S_INTRO_6;
            end
            S_INTRO_6: begin
                col_req <= 9'd3;
                row_req <= row_out - 9'd1;
                shift_reg_red <= {shift_reg_red[7:0], d_out_b[0]};
                shift_reg_green <= {shift_reg_green[7:0], d_out_b[1]};
                shift_reg_blue <= {shift_reg_blue[7:0], d_out_b[2]};
                flowState <= S_INTRO_7;
            end
            S_INTRO_7: begin
                row_req <= row_out;
                shift_reg_red <= {shift_reg_red[7:0], d_out_b[0]};
                shift_reg_green <= {shift_reg_green[7:0], d_out_b[1]};
                shift_reg_blue <= {shift_reg_blue[7:0], d_out_b[2]};
                flowState <= S_INTRO_8;
            end
            S_INTRO_8: begin
                row_req <= row_out + 9'd1;
                shift_reg_red <= {shift_reg_red[7:0], d_out_b[0]};
                shift_reg_green <= {shift_reg_green[7:0], d_out_b[1]};
                shift_reg_blue <= {shift_reg_blue[7:0], d_out_b[2]};
                flowState <= S_INTRO_9;
            end
            S_INTRO_9: begin
                col_req <= 9'd4;
                row_req <= row_out - 9'd1;
                shift_reg_red <= {shift_reg_red[7:0], d_out_b[0]};
                shift_reg_green <= {shift_reg_green[7:0], d_out_b[1]};
                shift_reg_blue <= {shift_reg_blue[7:0], d_out_b[2]};
                flowState <= S_INTRO_10;
            end
            S_INTRO_10: begin
                row_req <= row_out;
                shift_reg_red <= {shift_reg_red[7:0], d_out_b[0]};
                shift_reg_green <= {shift_reg_green[7:0], d_out_b[1]};
                shift_reg_blue <= {shift_reg_blue[7:0], d_out_b[2]};
                we_out_reg <= 1'b1;
                flowState <= S_COMMON_0;
            end
            S_COMMON_0: begin
                we_out_reg <= 1'b0;
                row_req <= row_out + 9'd1;
                col_out <= col_out + 9'd1;
                shift_reg_red <= {shift_reg_red[7:0], d_out_b[0]};
                shift_reg_green <= {shift_reg_green[7:0], d_out_b[1]};
                shift_reg_blue <= {shift_reg_blue[7:0], d_out_b[2]};
                flowState <= S_COMMON_1;
            end
            S_COMMON_1: begin
                col_req <= col_req + 9'd1;
                row_req <= row_out - 9'd1;
                shift_reg_red <= {shift_reg_red[7:0], d_out_b[0]};
                shift_reg_green <= {shift_reg_green[7:0], d_out_b[1]};
                shift_reg_blue <= {shift_reg_blue[7:0], d_out_b[2]};
                flowState <= S_COMMON_2;
            end
            S_COMMON_2: begin
                row_req <= row_out;
                shift_reg_red <= {shift_reg_red[7:0], d_out_b[0]};
                shift_reg_green <= {shift_reg_green[7:0], d_out_b[1]};
                shift_reg_blue <= {shift_reg_blue[7:0], d_out_b[2]};
                we_out_reg <= 1'b1;
                if (col_out== 9'd317) begin   //width of the screen
                    flowState <= S_END_ROW;
                end else begin
                    flowState <= S_COMMON_0;
                end
            end
            S_END_ROW: begin
                we_out_reg <= 1'd0;
                col_req <= 9'd1;
                col_out <= 9'd2;
                if (row_out == 9'd478) begin
                    row_out <= 9'd1;    //start again with top of screen
                    row_req <= 9'd0;
                end else begin
                    row_out <= row_out + 9'd1;
                    row_req <= row_out; //the current row out will be the next iterations row out - 1
                end
                flowState <= S_INTRO_1;
            end
        endcase
    end
end

endmodule
