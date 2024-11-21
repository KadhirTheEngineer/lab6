`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/19/2024 02:38:47 PM
// Design Name: 
// Module Name: stopwatch_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Stopwatch with dynamic pre-load using switches and mode selection.
// 
//////////////////////////////////////////////////////////////////////////////////
module stopwatch_top(
    input clk,              // 100 MHz clock input
    input reset,            // Reset button
    input start_stop,       // Start/Stop button
    input [7:0] switches,   // 8 input switches for initializing time
    input [1:0] mode,       // Mode selection (00: Stopwatch, 01: Preload Stopwatch, 10: Countdown, 11: Preload Timer)
    output reg [3:0] an,    // 7-segment display anode control
    output [6:0] seg,        // 7-segment display segments
    output reg debug
);
    // Internal signals
    reg [15:0] time_count;     // Current time in BCD (4 digits: [15:12][11:8][7:4][3:0])
    reg [15:0] preset_time;    // The preset value for preload modes
    wire slow_clk;             // Clock divider for 10 ms updates
    reg [1:0] digit_select;    // Selects which digit to display
    reg [3:0] current_digit;   // Currently selected digit for display
    wire [6:0] seg_output;     // Output from num2display
    reg running;               // Stopwatch running state
    reg [2:0] start_stop_sync; // Synchronize the start/stop signal for debouncing
    reg debounced_start_stop;  // Debounced start/stop signal
    reg [15:0] display_counter; // Counter for display multiplexing

    // Clock divider to generate a 10ms clock
    clk_div clk_divider (
        .clk(clk),
        .reset(reset),
        .slow_clk(slow_clk)
    );

    // Instantiate the num2display module
    num2display bcd_decoder (
        .num(current_digit),
        .disp(seg_output)
    );

    // Drive the `seg` output from the `num2display` module
    assign seg = seg_output;

    // Debounce the start/stop button
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            start_stop_sync <= 3'b000;
            debounced_start_stop <= 0;
        end else begin
            start_stop_sync <= {start_stop_sync[1:0], start_stop};
            if (start_stop_sync == 3'b111)
                debounced_start_stop <= 1;
            else if (start_stop_sync == 3'b000)
                debounced_start_stop <= 0;
        end
    end

    // Control stopwatch running state (toggle on start_stop press)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            running <= 0;
        end else if (debounced_start_stop) begin
            running <= ~running;
        end
    end

    // Time counting logic
    always @(posedge slow_clk or posedge reset) begin
        if (reset) begin
            time_count <= 16'b0; // Reset to 00.00
        end else begin
            case (mode)
                2'b00: begin // Regular Stopwatch Mode (Incrementing)
                    if (running) begin
                        time_count[3:0] <= time_count[3:0] + 1;
                        
                        if (time_count[3:0] == 4'd9) 
                            begin
                            time_count[3:0] <= 4'd0;
                            time_count[7:4] <= time_count[7:4] + 1; // Increment next digit
                            
                            if (time_count[7:4] == 4'd9) 
                                begin
                                time_count[7:4] <= 4'd0;
                                time_count[11:8] <= time_count[11:8] + 1; // Increment next digit
                                
                                if (time_count[11:8] == 4'd9) 
                                    begin
                                    time_count[11:8] <= 4'd0;
                                    time_count[15:12] <= time_count[15:12] + 1; // Increment next digit
                                    
                                    if (time_count[15:12] == 4'd9)
                                        begin
                                        time_count <= time_count; // no change
                                        end
                                    end
                                end
                        end
                    end
                end
                2'b01: begin // Preload Stopwatch Mode (Increment to preset value)
                    if (running) begin
                        time_count[3:0] <= time_count[3:0] + 1;
                        
                        if (time_count[3:0] == 4'd9) 
                            begin
                            time_count[3:0] <= 4'd0;
                            time_count[7:4] <= time_count[7:4] + 1; // Increment next digit
                            
                            if (time_count[7:4] == 4'd9) 
                                begin
                                time_count[7:4] <= 4'd0;
                                time_count[11:8] <= time_count[11:8] + 1; // Increment next digit
                                
                                if (time_count[11:8] == 4'd9) 
                                    begin
                                    time_count[11:8] <= 4'd0;
                                    time_count[15:12] <= time_count[15:12] + 1; // Increment next digit
                                    
                                    if (time_count[15:12] == 4'd9)
                                        begin
                                        time_count <= time_count; // no change
                                        end
                                    end
                                end
                        end
                    end
                    else begin 
                        time_count[15:12] <= switches[7:4];
                        time_count[11:8] <= switches[3:0];
                    end
                end
                2'b10: begin // Countdown Mode (Decrementing)
                    if(time_count != 16'h9999)begin
                        time_count <= 16'h9999;
                    end
                    
                    if (running && time_count > 0) begin
                        // Decrement the least significant digit
                        if (time_count[3:0] == 4'd0) begin
                            time_count[3:0] <= 4'd9;
                            if (time_count[7:4] == 4'd0) begin
                                time_count[7:4] <= 4'd9;
                                if (time_count[11:8] == 4'd0) begin
                                    time_count[11:8] <= 4'd9;
                                    if (time_count[15:12] > 0) begin
                                        time_count[15:12] <= time_count[15:12] - 1;
                                    end
                                end else begin
                                    time_count[11:8] <= time_count[11:8] - 1;
                                end
                            end else begin
                                time_count[7:4] <= time_count[7:4] - 1;
                            end
                        end else begin
                            time_count[3:0] <= time_count[3:0] - 1;
                        end
                    end
                end
                2'b11: begin // Preload Timer Mode (Countdown to 0)
                    if (running && time_count > 0) begin
                        // Decrement logic as above
                        if (time_count[3:0] == 4'd0) begin
                            time_count[3:0] <= 4'd9;
                            if (time_count[7:4] == 4'd0) begin
                                time_count[7:4] <= 4'd9;
                                if (time_count[11:8] == 4'd0) begin
                                    time_count[11:8] <= 4'd9;
                                    if (time_count[15:12] > 0) begin
                                        time_count[15:12] <= time_count[15:12] - 1;
                                    end
                                end else begin
                                    time_count[11:8] <= time_count[11:8] - 1;
                                end
                            end else begin
                                time_count[7:4] <= time_count[7:4] - 1;
                            end
                        end else begin
                            time_count[3:0] <= time_count[3:0] - 1;
                        end
                    end
                    else begin 
                        time_count[15:12] <= switches[7:4];
                        time_count[11:8] <= switches[3:0];
                    end
                end
            endcase
        end
    end
    
    
        // Load preset value from switches, but only when the timer/stopwatch is NOT running
//        always @(posedge clk or posedge reset) begin
//            if (reset) 
//                begin
//                preset_time <= 16'b0; // Reset preset time
//                end 
//            else if (!running && (mode == 2'b01 || mode == 2'b11))
//                begin
//                preset_time[15:12] <= switches[7:4];
//                preset_time[11:8] <= switches[3:0]; // Load time from switches when stopped
//            end
//        end
    
        // Multiplex the digits at a faster refresh rate
        always @(posedge clk or posedge reset) begin
            if (reset) begin
                display_counter <= 16'b0;
                digit_select <= 2'b00;
            end else begin
                display_counter <= display_counter + 1; // Increment display counter
                if (display_counter == 16'b1111111111111111) begin
                    digit_select <= digit_select + 1; // Cycle through digits
                    display_counter <= 16'b0; // Reset display counter
                end
            end
        end

    // Assign the current digit based on `digit_select`
    always @(*) begin
        case (digit_select)
            2'b00: begin
                current_digit = time_count[3:0];  // Least significant digit
                an = 4'b1110;                    // Enable corresponding display
            end
            2'b01: begin
                current_digit = time_count[7:4]; // Next digit
                an = 4'b1101;                    // Enable corresponding display
            end
            2'b10: begin
                current_digit = time_count[11:8]; // Seconds (ones place)
                an = 4'b1011;                     // Enable corresponding display
            end
            2'b11: begin
                current_digit = time_count[15:12]; // Seconds (tens place)
                an = 4'b0111;                      // Enable corresponding display
            end
        endcase
    end
    
    //debug logic
    always @(*) begin
        debug = running;
        
//        if((mode == 2'b01 || mode == 2'b11) && ~running) begin
//            time_count <= preset_time;
//        end
    end
endmodule

//////////////////////////////////////////////////////////////////////////////////
// Clock Divider Module
//////////////////////////////////////////////////////////////////////////////////
module clk_div(
    input clk,
    input reset,
    output reg slow_clk
);

    reg [19:0] COUNT; 

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            COUNT <= 0;
            slow_clk <= 0;
        end else if (COUNT == 499999) begin
            COUNT <= 0;
            slow_clk <= ~slow_clk; 
        end else begin
            COUNT <= COUNT + 1;
        end
    end
endmodule

//////////////////////////////////////////////////////////////////////////////////
// num2display Module
//////////////////////////////////////////////////////////////////////////////////
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
            //default: disp = 7'b1111111;   
        endcase
endmodule
