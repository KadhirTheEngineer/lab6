`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/19/2024 02:38:47 PM
// Design Name: 
// Module Name: stopwatch_timer
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


module stopwatch_timer(
    input clk,
    //input rst,
    input [9:0] sw,
    input [6:0] d0,
    input [6:0] d1,
    input [6:0] d2,
    input [6:0] d3,
    
    output reg [3:0] an,
    output reg [6:0] sseg,
    output reg [15:0] counter
    );
    
    reg [3:0] ms10;
    reg [3:0] ms1;
    
    num2display n1 (.num(), .disp());
    //always @(posedge clk) begin
    //    a <= ~a;
    //end
endmodule


module clk_div_disp(
    input clk,
    input reset,
    output reg slow_clk
);

    reg [16:0] COUNT; 

    always @(posedge clk or posedge reset)
    begin
        if (reset) begin
            COUNT <= 0;
            slow_clk <= 0;
        end
        else if (COUNT == 99999) begin 
            COUNT <= 0;
            slow_clk <= ~slow_clk; 
        end
        else
            COUNT <= COUNT + 1;
    end
endmodule


module num2display(
    input [3:0] num,
    output reg [6:0] disp
    );
        
    always @(*)
        case(num)
            4'b0000: disp = 7'b0000001;
            4'b0001: disp = 7'b1001111;
            4'b0010: disp = 7'b0010010;
            4'b0011: disp = 7'b0000110;
            4'b0100: disp = 7'b1001100;
            4'b0101: disp = 7'b0100100;
            4'b0110: disp = 7'b0100000;
            4'b0111: disp = 7'b0001111;
            4'b1000: disp = 7'b0000000;
            4'b1001: disp = 7'b0000100;  
        endcase
endmodule
