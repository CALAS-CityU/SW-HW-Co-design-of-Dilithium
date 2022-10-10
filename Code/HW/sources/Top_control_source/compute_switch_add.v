`timescale 1ns / 1ps

module compute_switch_add
(
    input  wire clk,
    input  wire compute_start,//1 for start
    output wire compute_done,
    input  wire compu_working,
    
    input wire[3:0] vector_length,
    
    output wire coef_ena,//RAM for 256 coefficient
    output wire coef_wea,
    output wire [7:0 ] coef_addra,
    output wire [22:0] coef_dina,
    input  wire [22:0] coef_douta,
  
    output wire coef_enb,
    output wire coef_web,
    output wire [7:0]coef_addrb,
    output wire [22:0] coef_dinb,
    input wire  [22:0]coef_doutb,
    
    output wire temp_ena,
    output wire temp_wea,
    output wire [7:0 ]temp_addra,
    output wire [22:0] temp_dina,
    input  wire [22:0] temp_douta,
  
    output wire temp_enb,
    output wire temp_web,
    output wire [7:0]temp_addrb,
    output wire [22:0] temp_dinb,
    input wire  [22:0]temp_doutb,
    
    input  wire Rm_tvalid,
    input  wire [22:0] data_in_1,
    input  wire [22:0] data_in_2,
    output wire Rm_tready,
    
    output reg[22:0]  add_num_1_1,
    output wire[22:0] add_num_1_2,
    output reg[22:0]  add_num_2_1,
    output wire[22:0] add_num_2_2,
    input  wire[22:0] add_result_1,
    input  wire[22:0] add_result_2
    );
    wire start_stop;
    reg[7:0] counter_inner;
    reg[7:0] counter_inner_buf_1;
    reg[7:0] counter_inner_buf_2;
    reg[7:0] counter_inner_buf_3;
    reg[7:0] counter_inner_buf_4;
    reg[7:0] counter_inner_buf_5;
    
    wire[7:0] counter_plus1;
    wire[7:0] counter_buf5_plus1;
    
    reg rd_en_buf_1;
    reg rd_en_buf_2;
    reg rd_en_buf_3;
    reg rd_en_buf_4;
    reg rd_en_buf_5;
    
    wire counter_inner_last;
    reg counter_inner_last_1;
    reg counter_inner_last_2;
    reg counter_inner_last_3;
    reg counter_inner_last_4;
    reg counter_inner_last_5;
    wire counter_inner_last_buf;

    reg[3:0] counter_outer;
    wire counter_outer_last;
    reg counter_outer_last_buf_1;
    reg counter_outer_last_buf_2;
    reg counter_outer_last_buf_3;
    reg counter_outer_last_buf_4;
    reg counter_outer_last_buf_5;
    
    wire coef_enable;
    wire temp_enable;
    wire coef_sel;
    wire temp_sel;
    reg running;
    reg block;
    wire keep;
    
    reg [22:0] add_result_1_buf;
    reg [22:0] add_result_2_buf;
    
    assign start_stop = (compute_start||!compu_working);
    assign coef_enable = block? rd_en_buf_5 : Rm_tready;
    assign temp_enable = block? Rm_tready : rd_en_buf_5;
    assign coef_sel = block? 1 :0;
    assign temp_sel = block? 0 :1;
    
    assign coef_ena = coef_enable;
    assign coef_enb = coef_enable;
    assign temp_ena = temp_enable;
    assign temp_enb = temp_enable;
    
    assign coef_wea = coef_sel;
    assign coef_web = coef_sel;
    assign temp_wea =  temp_sel;
    assign temp_web =  temp_sel;
    
    assign Rm_tready = Rm_tvalid & running & (!counter_inner_last_buf);
    
    assign counter_inner_last = (counter_inner == 8'd254);
    assign counter_outer_last = (counter_outer==vector_length-2'd2)&& counter_inner_last;
    assign counter_inner_last_buf = counter_inner_last_1 | counter_inner_last_2 | counter_inner_last_3 | counter_inner_last_4| counter_inner_last_5;
    
    assign counter_plus1 = counter_inner  + 1'b1;
    assign counter_buf5_plus1 = counter_inner_buf_5 + 1'b1;
    
    assign coef_addra = block? counter_inner_buf_5 : counter_inner;
    assign coef_addrb = block? counter_buf5_plus1  : counter_plus1;
    assign temp_addra = block? counter_inner : counter_inner_buf_5;
    assign temp_addrb = block? counter_plus1 : counter_buf5_plus1 ;
    
    assign coef_dina = block? add_result_1_buf : 0;
    assign coef_dinb = block? add_result_2_buf : 0;
    assign temp_dina = block? 0 : add_result_1_buf;
    assign temp_dinb = block? 0 : add_result_2_buf;
    
    assign add_num_1_2 = data_in_1;
    assign add_num_2_2 = data_in_2;
    
    assign compute_done = counter_outer_last_buf_5; 
    
    assign keep = (counter_outer==1'b0 &(!counter_inner_last))?1'b0:counter_inner_last | counter_inner_last_buf;
    
    always@(posedge clk)
    begin
        running <= compute_start? 1'b1 : counter_outer_last? 1'b0 : running;
        counter_inner <= (start_stop | keep)? 1'b0 : (Rm_tready?counter_inner + 2'd2 : counter_inner);
        counter_outer <= start_stop? 1'b0 : (counter_inner_last? counter_outer + 1'b1 : counter_outer);
        
        rd_en_buf_1 <= Rm_tready;
        rd_en_buf_2 <= rd_en_buf_1;
        rd_en_buf_3 <= rd_en_buf_2;
        rd_en_buf_4 <= rd_en_buf_3;
        rd_en_buf_5 <= rd_en_buf_4;
        
        counter_inner_buf_1 <= counter_inner;
        counter_inner_buf_2 <= counter_inner_buf_1;
        counter_inner_buf_3 <= counter_inner_buf_2;
        counter_inner_buf_4 <= counter_inner_buf_3;
        counter_inner_buf_5 <= counter_inner_buf_4;
        
        block <= compute_start? 1'b0 : counter_inner_last_5? ~block : block;
        
        counter_inner_last_1<= counter_inner_last;
        counter_inner_last_2<= counter_inner_last_1;
        counter_inner_last_3<= counter_inner_last_2;
        counter_inner_last_4<= counter_inner_last_3;
        counter_inner_last_5<= counter_inner_last_4;
        
        add_num_1_1 <= block? temp_douta:coef_douta;
        add_num_2_1 <= block? temp_doutb:coef_doutb;
        
        add_result_1_buf <= add_result_1;
        add_result_2_buf <= add_result_2;
        
        counter_outer_last_buf_1 <= counter_outer_last;
        counter_outer_last_buf_2 <= counter_outer_last_buf_1;
        counter_outer_last_buf_3 <= counter_outer_last_buf_2;
        counter_outer_last_buf_4 <= counter_outer_last_buf_3;
        counter_outer_last_buf_5 <= counter_outer_last_buf_4;
    
    end
    
endmodule
