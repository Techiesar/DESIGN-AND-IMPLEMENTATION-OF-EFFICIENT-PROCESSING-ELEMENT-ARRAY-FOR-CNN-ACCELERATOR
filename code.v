`timescale 1ns / 1ps

module alu (
    input clk,
    input [2:0] s,
    input [7:0] A,
    input [7:0] B,
    input cin,
    output reg [15:0] C
);
    wire [15:0] dadda_result;
    wire [7:0] sum_out;
    wire sum_cout;
   
    dadda_8 dadda_multiplier (.A(A), .B(B), .y(dadda_result));
    kb kb_adder (
        .a(A),
        .b(B),
        .cin(cin),
        .sum(sum_out),
        .cout(sum_cout)
    );
   
    always @(posedge clk) begin
        case (s)
            3'b000: C <= {8'b0, sum_cout, sum_out};
            3'b001: C <= dadda_result;
            3'b010: C <= {8'b0, A & B};
            3'b011: C <= {8'b0, A | B};
            3'b100: C <= {8'b0, ~A};
            3'b101: C <= {8'b0, ~B};
            default: C <= C;
        endcase
    end
endmodule

module re (
    input clk,
    input [1:0] cui,
    input [7:0] in1,
    input [7:0] filter,
    input [2:0] o,
    output reg [15:0] pe
);
    reg [7:0] alu_A, alu_B;
    wire [15:0] alu_result;
   
    always @(posedge clk) begin
        if (cui == 2'b00) begin
            alu_A <= in1;
            alu_B <= filter;
        end else if (cui == 2'b01) begin
            pe <= alu_result;
        end
    end
   
    alu alu_1 (
        .clk(clk),
        .s(o),
        .A(alu_A),
        .B(alu_B),
        .cin(1'b0),
        .C(alu_result)
    );
endmodule

module pe (
    input clk,
    input [2:0] a,
    input [1:0] r,
    input [7:0] in1,
    input [7:0] filter,
    output [15:0] pe_out
);
    wire [15:0] pe;
   
    re re_1 (
        .clk(clk),
        .cui(r),
        .in1(in1),
        .filter(filter),
        .o(a),
        .pe(pe)
    );
   
    assign pe_out = pe;
endmodule

module NoC (
    input clk,
    input [7:0] data_in [0:3],
    input [1:0] control [0:3],
    input [2:0] control2 [0:3],
    input [7:0] filter [0:3],
    output [15:0] data_out [0:3]
);
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : PE_INST
            pe pe_inst (
                .clk(clk),
                .a(control2[i]),
                .r(control[i]),
                .in1(data_in[i]),
                .filter(filter[i]),
                .pe_out(data_out[i])
            );
        end
    endgenerate
endmodule

module TopModule (
    input clk,
    input [7:0] global_data [0:3],
    input [1:0] global_control [0:3],
    input [2:0] global_control2 [0:3],
    input [7:0] global_filter [0:3],
    output [15:0] global_output [0:3]
);
    NoC noc_inst (
        .clk(clk),
        .data_in(global_data),
        .control(global_control),
        .control2(global_control2),
        .filter(global_filter),
        .data_out(global_output)
    );
endmodule

module dadda_8(A,B,y);
   
    input [7:0] A;
    input [7:0] B;
    output wire [15:0] y;
    wire  gen_pp [0:7][7:0];
// stage-1 sum and carry
    wire [0:5]s1,c1;
// stage-2 sum and carry
    wire [0:13]s2,c2;  
// stage-3 sum and carry
    wire [0:9]s3,c3;
// stage-4 sum and carry
    wire [0:11]s4,c4;
// stage-5 sum and carry
    wire [0:13]s5,c5;




// generating partial products
genvar i;
genvar j;

for(i = 0; i<8; i=i+1)begin

   for(j = 0; j<8;j = j+1)begin
      assign gen_pp[i][j] = A[j]*B[i];
end
end

 

//Reduction by stages.
// di_values = 2,3,4,6,8,13...


//Stage 1 - reducing fom 8 to 6  


    HA h1(.a(gen_pp[6][0]),.b(gen_pp[5][1]),.Sum(s1[0]),.Cout(c1[0]));
    HA h2(.a(gen_pp[4][3]),.b(gen_pp[3][4]),.Sum(s1[2]),.Cout(c1[2]));
    HA h3(.a(gen_pp[4][4]),.b(gen_pp[3][5]),.Sum(s1[4]),.Cout(c1[4]));

    csa_dadda c11(.A(gen_pp[7][0]),.B(gen_pp[6][1]),.Cin(gen_pp[5][2]),.Y(s1[1]),.Cout(c1[1]));
    csa_dadda c12(.A(gen_pp[7][1]),.B(gen_pp[6][2]),.Cin(gen_pp[5][3]),.Y(s1[3]),.Cout(c1[3]));    
    csa_dadda c13(.A(gen_pp[7][2]),.B(gen_pp[6][3]),.Cin(gen_pp[5][4]),.Y(s1[5]),.Cout(c1[5]));
   
//Stage 2 - reducing fom 6 to 4

    HA h4(.a(gen_pp[4][0]),.b(gen_pp[3][1]),.Sum(s2[0]),.Cout(c2[0]));
    HA h5(.a(gen_pp[2][3]),.b(gen_pp[1][4]),.Sum(s2[2]),.Cout(c2[2]));


    csa_dadda c21(.A(gen_pp[5][0]),.B(gen_pp[4][1]),.Cin(gen_pp[3][2]),.Y(s2[1]),.Cout(c2[1]));
    csa_dadda c22(.A(s1[0]),.B(gen_pp[4][2]),.Cin(gen_pp[3][3]),.Y(s2[3]),.Cout(c2[3]));
    csa_dadda c23(.A(gen_pp[2][4]),.B(gen_pp[1][5]),.Cin(gen_pp[0][6]),.Y(s2[4]),.Cout(c2[4]));
    csa_dadda c24(.A(s1[1]),.B(s1[2]),.Cin(c1[0]),.Y(s2[5]),.Cout(c2[5]));
    csa_dadda c25(.A(gen_pp[2][5]),.B(gen_pp[1][6]),.Cin(gen_pp[0][7]),.Y(s2[6]),.Cout(c2[6]));
    csa_dadda c26(.A(s1[3]),.B(s1[4]),.Cin(c1[1]),.Y(s2[7]),.Cout(c2[7]));
    csa_dadda c27(.A(c1[2]),.B(gen_pp[2][6]),.Cin(gen_pp[1][7]),.Y(s2[8]),.Cout(c2[8]));
    csa_dadda c28(.A(s1[5]),.B(c1[3]),.Cin(c1[4]),.Y(s2[9]),.Cout(c2[9]));
    csa_dadda c29(.A(gen_pp[4][5]),.B(gen_pp[3][6]),.Cin(gen_pp[2][7]),.Y(s2[10]),.Cout(c2[10]));
    csa_dadda c210(.A(gen_pp[7][3]),.B(c1[5]),.Cin(gen_pp[6][4]),.Y(s2[11]),.Cout(c2[11]));
    csa_dadda c211(.A(gen_pp[5][5]),.B(gen_pp[4][6]),.Cin(gen_pp[3][7]),.Y(s2[12]),.Cout(c2[12]));
    csa_dadda c212(.A(gen_pp[7][4]),.B(gen_pp[6][5]),.Cin(gen_pp[5][6]),.Y(s2[13]),.Cout(c2[13]));
   
//Stage 3 - reducing fom 4 to 3

    HA h6(.a(gen_pp[3][0]),.b(gen_pp[2][1]),.Sum(s3[0]),.Cout(c3[0]));

    csa_dadda c31(.A(s2[0]),.B(gen_pp[2][2]),.Cin(gen_pp[1][3]),.Y(s3[1]),.Cout(c3[1]));
    csa_dadda c32(.A(s2[1]),.B(s2[2]),.Cin(c2[0]),.Y(s3[2]),.Cout(c3[2]));
    csa_dadda c33(.A(c2[1]),.B(c2[2]),.Cin(s2[3]),.Y(s3[3]),.Cout(c3[3]));
    csa_dadda c34(.A(c2[3]),.B(c2[4]),.Cin(s2[5]),.Y(s3[4]),.Cout(c3[4]));
    csa_dadda c35(.A(c2[5]),.B(c2[6]),.Cin(s2[7]),.Y(s3[5]),.Cout(c3[5]));
    csa_dadda c36(.A(c2[7]),.B(c2[8]),.Cin(s2[9]),.Y(s3[6]),.Cout(c3[6]));
    csa_dadda c37(.A(c2[9]),.B(c2[10]),.Cin(s2[11]),.Y(s3[7]),.Cout(c3[7]));
    csa_dadda c38(.A(c2[11]),.B(c2[12]),.Cin(s2[13]),.Y(s3[8]),.Cout(c3[8]));
    csa_dadda c39(.A(gen_pp[7][5]),.B(gen_pp[6][6]),.Cin(gen_pp[5][7]),.Y(s3[9]),.Cout(c3[9]));

//Stage 4 - reducing fom 3 to 2

    HA h7(.a(gen_pp[2][0]),.b(gen_pp[1][1]),.Sum(s4[0]),.Cout(c4[0]));


    csa_dadda c41(.A(s3[0]),.B(gen_pp[1][2]),.Cin(gen_pp[0][3]),.Y(s4[1]),.Cout(c4[1]));
    csa_dadda c42(.A(c3[0]),.B(s3[1]),.Cin(gen_pp[0][4]),.Y(s4[2]),.Cout(c4[2]));
    csa_dadda c43(.A(c3[1]),.B(s3[2]),.Cin(gen_pp[0][5]),.Y(s4[3]),.Cout(c4[3]));
    csa_dadda c44(.A(c3[2]),.B(s3[3]),.Cin(s2[4]),.Y(s4[4]),.Cout(c4[4]));
    csa_dadda c45(.A(c3[3]),.B(s3[4]),.Cin(s2[6]),.Y(s4[5]),.Cout(c4[5]));
    csa_dadda c46(.A(c3[4]),.B(s3[5]),.Cin(s2[8]),.Y(s4[6]),.Cout(c4[6]));
    csa_dadda c47(.A(c3[5]),.B(s3[6]),.Cin(s2[10]),.Y(s4[7]),.Cout(c4[7]));
    csa_dadda c48(.A(c3[6]),.B(s3[7]),.Cin(s2[12]),.Y(s4[8]),.Cout(c4[8]));
    csa_dadda c49(.A(c3[7]),.B(s3[8]),.Cin(gen_pp[4][7]),.Y(s4[9]),.Cout(c4[9]));
    csa_dadda c410(.A(c3[8]),.B(s3[9]),.Cin(c2[13]),.Y(s4[10]),.Cout(c4[10]));
    csa_dadda c411(.A(c3[9]),.B(gen_pp[7][6]),.Cin(gen_pp[6][7]),.Y(s4[11]),.Cout(c4[11]));
   
//Stage 5 - reducing fom 2 to 1
    // adding total sum and carry to get final output

    HA h8(.a(gen_pp[1][0]),.b(gen_pp[0][1]),.Sum(y[1]),.Cout(c5[0]));



    csa_dadda c51(.A(s4[0]),.B(gen_pp[0][2]),.Cin(c5[0]),.Y(y[2]),.Cout(c5[1]));
    csa_dadda c52(.A(c4[0]),.B(s4[1]),.Cin(c5[1]),.Y(y[3]),.Cout(c5[2]));
    csa_dadda c54(.A(c4[1]),.B(s4[2]),.Cin(c5[2]),.Y(y[4]),.Cout(c5[3]));
    csa_dadda c55(.A(c4[2]),.B(s4[3]),.Cin(c5[3]),.Y(y[5]),.Cout(c5[4]));
    csa_dadda c56(.A(c4[3]),.B(s4[4]),.Cin(c5[4]),.Y(y[6]),.Cout(c5[5]));
    csa_dadda c57(.A(c4[4]),.B(s4[5]),.Cin(c5[5]),.Y(y[7]),.Cout(c5[6]));
    csa_dadda c58(.A(c4[5]),.B(s4[6]),.Cin(c5[6]),.Y(y[8]),.Cout(c5[7]));
    csa_dadda c59(.A(c4[6]),.B(s4[7]),.Cin(c5[7]),.Y(y[9]),.Cout(c5[8]));
    csa_dadda c510(.A(c4[7]),.B(s4[8]),.Cin(c5[8]),.Y(y[10]),.Cout(c5[9]));
    csa_dadda c511(.A(c4[8]),.B(s4[9]),.Cin(c5[9]),.Y(y[11]),.Cout(c5[10]));
    csa_dadda c512(.A(c4[9]),.B(s4[10]),.Cin(c5[10]),.Y(y[12]),.Cout(c5[11]));
    csa_dadda c513(.A(c4[10]),.B(s4[11]),.Cin(c5[11]),.Y(y[13]),.Cout(c5[12]));
    csa_dadda c514(.A(c4[11]),.B(gen_pp[7][7]),.Cin(c5[12]),.Y(y[14]),.Cout(c5[13]));

    assign y[0] =  gen_pp[0][0];
    assign y[15] = c5[13];
   
 
   
endmodule
module csa_dadda(A,B,Cin,Y,Cout);
input A,B,Cin;
output Y,Cout;
   
assign Y = A^B^Cin;
assign Cout = (A&B)|(A&Cin)|(B&Cin);
   
endmodule
module HA(a, b, Sum, Cout);

input a, b; // a and b are inputs with size 1-bit
output Sum, Cout; // Sum and Cout are outputs with size 1-bit

assign Sum = a ^ b;
assign Cout = a & b;

endmodule

module kb(
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] sum,
    output cout
);
    wire [7:0] p, g, c;

    // Generate and Propagate signals
    assign p = a ^ b;
    assign g = a & b;

    // Carry computation using a hybrid approach
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & c[1]);
    assign c[3] = g[2] | (p[2] & c[2]);
    assign c[4] = g[3] | (p[3] & c[3]);
    assign c[5] = g[4] | (p[4] & c[4]);
    assign c[6] = g[5] | (p[5] & c[5]);
    assign c[7] = g[6] | (p[6] & c[6]);
    assign cout = g[7] | (p[7] & c[7]); // Final carry out

    // Sum computation
    assign sum = p ^ c;

endmodule
