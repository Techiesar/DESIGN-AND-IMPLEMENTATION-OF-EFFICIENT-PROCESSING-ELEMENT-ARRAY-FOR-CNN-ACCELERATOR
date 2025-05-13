`timescale 1ns / 1ps
module NoC_Testbench;
    reg clk;
    reg clk_en;
    reg [7:0] global_data [0:3];
    reg [1:0] global_control [0:3];
    reg [2:0] global_control2 [0:3];
    reg [7:0] global_filter [0:3];
    wire [15:0] global_output [0:3];

    TopModule uut (
        .clk(clk),
        .global_data(global_data),
        .global_control(global_control),
        .global_control2(global_control2),
        .global_filter(global_filter),
        .global_output(global_output)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        clk_en = 1; // Enable clock by default

        // Initialize Data Inputs
        global_data[0] = 8'h10; // 16
        global_data[1] = 8'h20; // 32
        global_data[2] = 8'h30; // 48
        global_data[3] = 8'h40; // 64

        // Initialize Filter Coefficients
        global_filter[0] = 8'h01; // 1
        global_filter[1] = 8'h02; // 2
        global_filter[2] = 8'h03; // 3
        global_filter[3] = 8'h04; // 4

        // Load Data into Registers
        global_control[0] = 2'b00;
        global_control[1] = 2'b00;
        global_control[2] = 2'b00;
        global_control[3] = 2'b00;
       
        global_control2[0] = 3'b001; // Multiplication
        global_control2[1] = 3'b001;
        global_control2[2] = 3'b001;
        global_control2[3] = 3'b001;

        #10;

        // Perform Multiplication (Convolution Step 1: Multiply inputs by filter weights)
        global_control[0] = 2'b01;
        global_control[1] = 2'b01;
        global_control[2] = 2'b01;
        global_control[3] = 2'b01;

        #10;

        // Accumulate Results (Convolution Step 2: Sum up the results)
        global_control2[0] = 3'b000; // Addition
        global_control[0] = 2'b01;
       
        #10;

        // Store the Final Result
        global_control[0] = 2'b10;

        #10;

        $display("Final Convolution Output: %h", (global_output[0]+global_output[1]+global_output[2]+global_output[3]));
        $stop;
    end
endmodule
