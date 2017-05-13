`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/19/2017 08:17:27 PM
// Design Name: 
// Module Name: seqDivider
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


module seqDivider #(
   parameter N_WIDTH = 16       // Size of dividend
  ,parameter D_WIDTH = 16       // Size of divisor
  ,parameter Q_WIDTH = 16       // Size of quotient
  ,parameter F_WIDTH = 0        // Number of fractional bits in quotient.
  )(
   input wire clk
  ,input wire reset
  ,input wire go      // hold high for continuous calculation or stobe high for single calculation
  ,input wire [N_WIDTH-1:0] dividend
  ,input wire [D_WIDTH-1:0] divisor
  ,output reg [Q_WIDTH-1:0] quotient    // maintains last complete calculation.
  //,output wire overflow               // NOT IMPLEMENTED
  ,output wire done                         // stobes high if go is held high or indicated when single calculation complete
  );

  localparam COUNT_WIDTH = $clog2(Q_WIDTH);
  localparam [COUNT_WIDTH-1:0] DIVIDE_COUNTS = (COUNT_WIDTH)'(Q_WIDTH - 1'b1);

  localparam WN_WIDTH = N_WIDTH + F_WIDTH;
  localparam WD_WIDTH = D_WIDTH + DIVIDE_COUNTS;

  localparam CALC_WIDTH = ((WN_WIDTH > WD_WIDTH) ? WN_WIDTH : WD_WIDTH) + 1;

  reg  busy;
  reg  [COUNT_WIDTH-1:0]  divide_count;
  reg  [WN_WIDTH-1:0]       working_dividend;
  reg  [WD_WIDTH-1:0]       working_divisor;
  reg  [Q_WIDTH-1:0]      working_quotient;

  initial begin
    busy <= 0;    
    divide_count <= 0;  
    working_dividend <= 0;
    working_divisor <= 0;
    working_quotient <= 0;
    quotient <= 0;
  end

  // Subtract with sign bit
  wire [CALC_WIDTH-1:0] subtract_calc = {1'b0, working_dividend} - {1'b0, working_divisor};  

  // subtract_positive = (working_dividend > working_divisor);
  wire subtract_positive = ~subtract_calc[CALC_WIDTH-1];

  // if the next bit in quotient should be set then subtract working_divisor from working_dividend
  wire [WN_WIDTH-1:0] dividend_next = (subtract_positive) ? subtract_calc[WN_WIDTH-1:0] : working_dividend;

  wire [WD_WIDTH-1:0] divisor_next = working_divisor >> 1;   

  wire [Q_WIDTH-1:0] quotient_next = (working_quotient << 1) | (subtract_positive); 

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      busy <= 0;
      divide_count <= 0;
      working_dividend <= 0;
      working_divisor <= 0;
      working_quotient <= 0;
      quotient <= 0;
    end else begin
      if (go & ~busy) begin
        busy <= 1;
        divide_count <= DIVIDE_COUNTS;              
        working_dividend <= dividend << F_WIDTH;                // scale the numerator up by the fractional bits
        working_divisor  <= divisor  << DIVIDE_COUNTS;  // align divisor to the quotient        
        working_quotient <= 0;
      end else begin            
        if (divide_count == 0) begin
          if (busy == 1) begin
            quotient <= quotient_next;
          end
          busy <= 0;
        end else begin
          divide_count <= divide_count - 1'b1;      
        end         
        working_dividend <= dividend_next;
        working_divisor <= divisor_next; 
        working_quotient <= quotient_next;                  
      end
    end
  end   

  assign done = ~busy;  

endmodule
