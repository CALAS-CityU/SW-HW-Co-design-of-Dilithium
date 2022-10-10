`timescale 1ns / 1ps
//latency = 8
module mul_and_reduce_pipe//the output need to be buffered before use
#(
    parameter PARAM_Q = 23'b11111111110000000000001
)
(
    input wire clk,
    input wire [22:0] opt1,
    input wire [22:0] opt2,
    
    output reg[22:0] result
    );

wire[45:0] mul_res_0;
reg[45:0] mul_res_0_buf_0;
reg[22:0] mul_res_2;
reg[22:0] mul_res_3;

wire[22:0] result0_1;
reg[22:0]  result0_2;
reg[22:0]  result0_3;
reg[22:0]  result0_4;


wire[23:0] add_result_1;
wire[22:0] result1_1;
reg[22:0] result1_1_buf;

wire signed [23:0] sub_result_2;
//reduce
assign result0_1 = mul_res_0_buf_0[45:33]+mul_res_0_buf_0[45:23];//stage1, calculate d

wire[13:0] c_tmp; //stage2
wire[10:0] e_tmp;
wire[9:0] a_tmp;
reg[9:0] a_tmp_buf;
wire[22:0] a_tmp_2;
wire[3:0] b_tmp;
reg[3:0] b_tmp_buf;
wire[22:0] f_temp;
reg[22:0] f_temp_buf;
assign c_tmp = mul_res_0_buf_0[45:33] + mul_res_0_buf_0[32:23];
assign e_tmp = c_tmp[13:10] + c_tmp[9:0];
assign a_tmp = e_tmp[10]+e_tmp[9:0];

assign b_tmp = e_tmp[10]+ c_tmp[13:10];

assign a_tmp_2 = (a_tmp_buf<<13);
assign f_temp = a_tmp_2 - b_tmp_buf;
assign add_result_1 = f_temp_buf + mul_res_3;
assign result1_1 = (add_result_1 > PARAM_Q)? (add_result_1 - PARAM_Q): add_result_1;

wire[22:0] result_temp;
assign sub_result_2 = result1_1_buf - result0_4;
assign result_temp =(sub_result_2[23]) ? (sub_result_2+PARAM_Q):( (sub_result_2>PARAM_Q)? (sub_result_2-PARAM_Q):sub_result_2 );

always@(posedge clk)
begin
    mul_res_0_buf_0 <= mul_res_0;
    mul_res_2 <= mul_res_0_buf_0[22:0];
    mul_res_3 <= mul_res_2;
    
    result0_2 <= result0_1;
    result0_3 <= result0_2;
    result0_4 <= result0_3;
    result1_1_buf <= result1_1;
    
    a_tmp_buf <= a_tmp;
    b_tmp_buf <= b_tmp;
    f_temp_buf <= f_temp;
    result <= result_temp;
    
end

mult_gen_0 multiplier_inst_1(clk, opt1, opt2, mul_res_0);

endmodule
