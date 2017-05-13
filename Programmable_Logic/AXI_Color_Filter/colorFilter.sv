`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Shayan Mukhtar
// 
// Create Date: 04/07/2017 03:55:56 PM
// Design Name: 
// Module Name: colorFilter
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


module colorFilter(
input clock,                
input resetn,
input [5:0] red_threshold,
input [5:0] green_threshold,
input [5:0] blue_threshold,
input [17:0] addr_in,
input [15:0] d_in,
input we_in,
output [17:0] addr_out,
output [2:0] d_out,
output we_out
);

logic [17:0] addr_out_reg;
logic [2:0] d_out_reg;
logic [5:0] red_threshold_reg, green_threshold_reg, blue_threshold_reg;
logic we_out_reg;
logic we_in_reg;
logic we_in_rising_edge;
logic [5:0] green_in;
logic [4:0] red_in;
logic [4:0] blue_in;
logic [3:0] color_to_compare;
logic [1:0] newChannel_reg;
/*output wires*/
assign addr_out = addr_out_reg;
assign d_out = d_out_reg;
assign we_out = we_out_reg;

/*extract G information from data in*/
assign green_in = d_in[10:5];
assign red_in = d_in[15:11];
assign blue_in = d_in[4:0];
always @(posedge clock) begin
if (~resetn) begin
    addr_out_reg <= 18'd0;
    d_out_reg <= 3'd0;
    we_out_reg <= 1'b0;
end else begin
    if (we_in_rising_edge) begin
        /*Rising edge of frame grabber we, latch addr and data in*/
        we_out_reg <= 1'b1;
        //if (color_to_compare >= current_threshold) begin
        /*
        if ((red_in >= current_threshold) && (green_in >= current_threshold) && (blue_in >= current_threshold)) begin
            d_out_reg <= 1'b1;
        end else begin
            d_out_reg <= 1'b0;
        end
        */
        if (red_in >= red_threshold_reg) begin
            d_out_reg[0] <= 1'b1;
        end else begin
            d_out_reg[0] <= 1'b0;
        end
        if (green_in >= green_threshold_reg) begin
            d_out_reg[1] <= 1'b1;
        end else begin
            d_out_reg[1] <= 1'b0;
        end
        if (blue_in >= blue_threshold_reg) begin
            d_out_reg[2] <= 1'b1;
        end else begin
            d_out_reg[2] <= 1'b0;
        end
        addr_out_reg <= addr_in;
    end else begin
        we_out_reg <= 1'b0;
    end
end
end





/*load in the right channel into compare register*/
always @(posedge clock) begin
    if (!resetn) begin
        red_threshold_reg <= 6'd20;
        green_threshold_reg <= 6'd20;
        blue_threshold_reg <= 6'd20;
    end else begin
        red_threshold_reg <= red_threshold;
        green_threshold_reg <= green_threshold;
        blue_threshold_reg <= blue_threshold;
    end
end

/*Edge detection for rising edge of we_in*/
always @(posedge clock) begin
if (!resetn) begin
    we_in_reg <= 1'd0;
end else begin
    we_in_reg <= we_in;
end
end
assign we_in_rising_edge = (~we_in_reg) & (we_in);
endmodule
