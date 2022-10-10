
`timescale 1ns / 1ps
// latency = 12
module compact_BFU_test(
    input  wire clk,
    input  wire sel,//0: NTT, 1: INTT
    input  wire[22:0] a,
    input  wire[22:0] b,
    input  wire[22:0] omiga,
    output wire[22:0] a1,
    output wire[22:0] b1,
    input wire[22:0] mul_result,
    output wire[22:0] opt1,
    output wire[22:0] opt2

    );
    
    
    //start,
   compact_BFU module1(clk, sel, a, b, omiga, a1, b1, opt1, opt2, mul_result);
    
endmodule