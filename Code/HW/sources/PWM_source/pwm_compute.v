`timescale 1ns / 1ps

module pwm_compute
(
    input  wire clk,
    input  wire compute_start,//1 for start
    input  wire compu_working,
    output wire compute_done,
    
    input wire[3:0] column_length,
    
    output wire coef_ena,//RAM for 256 coefficient
    output wire coef_wea,
    output wire [7:0 ]coef_addra,
    input  wire [22:0] coef_douta,
    output wire coef_enb,
    output wire coef_web,
    output wire [7:0]coef_addrb,
    input wire  [22:0]coef_doutb,
    
    input  wire Rm_tvalid,
    input  wire [63:0] Rm_tdata,
    output wire ram_read,
    
    input  wire Write_FIFO_tready,
    output wire [63:0] Write_FIFO_tdata,
    output wire Write_FIFO_tvalid,
    
    output reg[22:0] mat_num1_1,
    output reg[22:0] mat_num1_2,
    input wire[22:0] mul_result1
    
    );
    reg read_working;
    reg[7:0] counter_inner;
    wire counter_inner_last;
    reg[3:0] counter_outer;
    reg rd_en;
    wire read_done;
    reg read_last_save;
    reg [63:0] Rm_tdata_buf;
    
    
    reg[22:0] mat_num2_1;
    reg[22:0] mat_num2_2;
    wire[22:0] mul_result2;
    reg[22:0] mul_result1_buf;
    reg[22:0] mul_result2_buf;
    
    reg rd_en_1;
    reg rd_en_2;//start mul
    reg rd_en_3;
    reg rd_en_4;
    reg rd_en_5;
    reg rd_en_6;
    reg rd_en_7;
    reg rd_en_8;
    reg rd_en_9;
    reg rd_en_10;
    
    assign ram_read = Rm_tvalid && read_working && compu_working;
    assign coef_ena = ram_read;
    assign coef_enb = ram_read;
    assign coef_wea = 1'b0;
    assign coef_web = 1'b0;
    assign coef_addra = counter_inner;
    assign coef_addrb = counter_inner + 1'b1;
    assign read_done = (counter_outer == column_length - 1'b1) && counter_inner_last;
    assign counter_inner_last = (counter_inner == 8'd254);
    assign Write_FIFO_tdata = {9'd0, mul_result2_buf, 9'd0, mul_result1_buf};
    assign Write_FIFO_tvalid = rd_en_10; 
    assign compute_done = (read_last_save == 1)&&(counter_inner==5'd20);
    
    always@(posedge clk)
    begin
        counter_inner <= (compute_start || counter_inner_last)? 1'b0 : ((ram_read||read_last_save)? counter_inner + 2'd2 : counter_inner);
        counter_outer <= compute_start? 1'b0 : (counter_inner_last? counter_outer + 1'b1 : counter_outer);
        rd_en    <= ram_read;
        Rm_tdata_buf <= Rm_tdata;
        mat_num1_1 <= coef_douta;
        mat_num1_2 <= Rm_tdata_buf[22:0];
        mat_num2_1 <= coef_doutb;
        mat_num2_2 <= Rm_tdata_buf[54:32];
        mul_result1_buf <= mul_result1;
        mul_result2_buf <= mul_result2;
        
        rd_en_1 <= rd_en;
        rd_en_2 <= rd_en_1;
        rd_en_3 <= rd_en_2;
        rd_en_4 <= rd_en_3;
        rd_en_5 <= rd_en_4;
        rd_en_6 <= rd_en_5;
        rd_en_7 <= rd_en_6; 
        rd_en_8 <= rd_en_7;
        rd_en_9 <= rd_en_8;
        rd_en_10 <= rd_en_9;
        
        read_working <= compute_start? 1'b1 : read_done? 1'b0 : read_working;
        read_last_save <= (compute_start||compute_done)? 1'b0 : read_done? 1'b1 : read_last_save;
        
    end
    
    mul_and_reduce_pipe module2(clk, mat_num2_1, mat_num2_2, mul_result2);
    
endmodule
