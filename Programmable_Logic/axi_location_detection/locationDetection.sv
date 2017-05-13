`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/19/2017 07:59:11 PM
// Design Name: 
// Module Name: locationDetection
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

/*Dont forget to latch the rowInd and colInd on the rising edge of newValueInd, as the values could change right after*/

module locationDetection(
input clock,                
input resetn,
input [17:0] addr_in,
input [2:0] d_in,
input we_in,
input [17:0] thresholdOfPixels,
output newValueInd,
output [8:0] rowInd,
output [8:0] colInd
);

enum logic [4:0] {
    S_IDLE,
    S_SCAN_IMAGE,
    S_CALC_POS_COL,
    S_CALC_POS_ROW,
    S_REPORT_POS
} flowState;

/*DPRAM signals*/
logic [17:0] address_b;
logic [2:0] d_out_b;
logic [8:0] col_req, col_avg;    //0 to 319
logic [8:0] row_req, row_avg;    //0 to 479
logic [31:0] totCol, totRow;
logic [17:0] totNum;
logic newValueIndReg;
assign address_b = {row_req[8:0],8'b00000000} + {row_req[8:0],6'b000000} + col_req[8:0];
assign newValueInd = newValueIndReg;

assign rowInd = (totNum >= thresholdOfPixels) ? row_avg: 9'd240;
assign colInd = (totNum >= thresholdOfPixels) ? col_avg: 9'd160;
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
  .wea            (we_in),
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
  .web            (1'b0),
  .addrb          (address_b),
  .dinb           (3'b000),
  .injectsbiterrb (1'b0),
  .injectdbiterrb (1'b0),
  .doutb          (d_out_b),
  .sbiterrb       (),
  .dbiterrb       ()

);

// End of xpm_memory_tdpram instance declaration
logic goSigDiv;
logic [31:0] dividend;
logic [17:0] divisor;
logic [8:0] quotient;
logic doneSigDiv, doneSigDivReg, doneSigRisingEdge;
seqDivider # (
    .N_WIDTH (32),
    .D_WIDTH (18),
    .Q_WIDTH (9),
    .F_WIDTH (0)
) seqDividerInst
(
    .clk(clock),
    .reset(~resetn),
    .go(goSigDiv),
    .dividend(dividend),
    .divisor(divisor),
    .quotient(quotient),
    .done(doneSigDiv)
);
//remember in c = a / b, c is the quotient, a is the dividend, b is the divisor
logic we_reg, we_rising_edge;
logic full_frame_flag;      //signal indicating the first full frame is in, we can now begin our image processing

/*rising edge detection for we*/
always @(posedge clock) begin
    if (~resetn) begin
        we_reg <= 1'b0;
        full_frame_flag <= 1'b0;
    end else begin
        we_reg <= we_in;
        //if (addr_in == 18'd153599) begin
            full_frame_flag <= 1'b1;
        //end
    end
end
assign we_rising_edge = (~we_reg & we_in);

/*rising edge detection for doneSigDiv*/
always @(posedge clock) begin
    if (~resetn) begin
        doneSigDivReg <= 1'b0;
    end else begin
        doneSigDivReg <= doneSigDiv;
    end
end
assign doneSigRisingEdge = ~doneSigDivReg & doneSigDiv;

/*state machine for image location detection*/
always_ff @(posedge clock) begin
    if (~resetn) begin
        flowState <= S_IDLE;
        col_req <= 9'd0;
        row_req <= 9'd0;
        totCol <= 32'd0;
        totRow <= 32'd0;
        totNum <= 18'd0;
        goSigDiv <= 1'b0;
        dividend <= 32'd0;
        divisor <= 18'd0;
        col_avg <= 9'd0;
        row_avg <= 9'd0;
        newValueIndReg <= 1'b0;
    end else begin
        case (flowState)
            S_IDLE: begin
                if (full_frame_flag) begin
                    flowState <= S_SCAN_IMAGE;
                    col_req <= 9'd5;    //cutoff the edge of the image, a lot of noise there for some reason
                    row_req <= 9'd5;    
                    totCol <= 32'd0;
                    totRow <= 32'd0;
                    totNum <= 18'd0;
                    goSigDiv <= 1'b0;
                    dividend <= 32'd0;
                    divisor <= 18'd0;
                    col_avg <= 9'd0;
                    row_avg <= 9'd0;
                    newValueIndReg <= 1'b0;
                end
            end
            S_SCAN_IMAGE: begin
                col_req <= col_req + 9'd1;
                if (col_req >= 317) begin
                    col_req <= 5;
                    row_req <= row_req + 9'd1;
                    if (row_req > 474) begin
                        row_req <= 9'd0;
                        flowState <= S_CALC_POS_COL;
                        //dividend and divisor get latched on the rising edge of go
                        goSigDiv <= 1'b1;
                        dividend <= totCol;
                        divisor <= totNum;
                    end
                end
                if (d_out_b[0]) begin
                    //I know these values are technically one cycle ahead of the actual data, but who cares
                    totCol <= totCol + col_req;
                    totRow <= totRow + row_req;
                    totNum <= totNum + 9'd1;
                end
            end
            S_CALC_POS_COL: begin
                goSigDiv <= 1'b0;
                if (doneSigRisingEdge) begin
                    flowState <= S_CALC_POS_ROW;
                    goSigDiv <= 1'b1;
                    dividend <= totRow;
                    divisor <= totNum;
                    col_avg <= quotient;
                end
            end
            S_CALC_POS_ROW: begin
                goSigDiv <= 1'b0;
                if (doneSigRisingEdge) begin
                    row_avg <= quotient;
                    newValueIndReg <= 1'b1;
                    flowState <= S_IDLE;
                end
            end
        endcase
    end
end 

endmodule
