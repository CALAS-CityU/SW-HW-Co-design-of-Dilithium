`timescale 1ns / 1ps

module compute_write_add
(
    input  wire clk,
    input  wire write_start,//1 for start
    output wire write_done,
    input  wire write_working,
    
    input  wire add_sub_sel,
    
    output wire coef_ena,//RAM for 256 coefficient
    output wire coef_wea,
    output wire [7:0 ]coef_addra,
    input  wire [22:0] coef_douta,
  
    output wire coef_enb,
    output wire coef_web,
    output wire [7:0]coef_addrb,
    input wire  [22:0]coef_doutb,
    
    input  wire Rm_tvalid,
    input  wire [22:0] data_in_1,
    input  wire [22:0] data_in_2,
    output wire Rm_tready,
    
    input  wire Write_FIFO_tready,
    output reg [63:0] Write_FIFO_tdata,
    output wire Write_FIFO_tvalid,
    
    output reg[22:0]  add_num_1_1,
    output reg[22:0] add_num_1_2,
    output reg[22:0]  add_num_2_1,
    output reg[22:0] add_num_2_2,
    input  wire[22:0] add_result_1,
    input  wire[22:0] add_result_2
    );
    reg[7:0] counter;
    reg read_working;
    reg read_en_buf_1;
    reg read_en_buf_2;
    reg read_en_buf_3;
    reg read_en_buf_4;
    reg read_en_buf_5;
    reg read_en_buf_6;
    wire read_done;
    reg read_done_buf_1;
    reg read_done_buf_2;
    reg read_done_buf_3;
    reg read_done_buf_4;
    reg read_done_buf_5;
    reg read_done_buf_6;
    reg[22:0] coef_douta_buf;
    reg[22:0] coef_doutb_buf;
    
    assign read_done = (counter == 8'd254);
    assign Rm_tready = Rm_tvalid & read_working;
    
    assign coef_ena = Rm_tready;
    assign coef_enb = Rm_tready;
    assign coef_wea = 0;
    assign coef_web = 0;
    assign coef_addra = counter;
    assign coef_addrb = counter+1'b1;
    assign Write_FIFO_tvalid = read_en_buf_6;
    assign write_done = read_done_buf_6;
    
    always@(posedge clk)
    begin
        counter <= write_start? 1'b0 : Rm_tready? counter + 2'd2 : counter;
        read_working <= write_start? 1'b1 : read_done? 1'b0 : read_working;
        Write_FIFO_tdata <= {9'd0, add_result_2, 9'd0, add_result_1};
        add_num_1_2 <= add_sub_sel? 23'd8380417 - data_in_1 : data_in_1;
        add_num_2_2 <= add_sub_sel? 23'd8380417 - data_in_2 : data_in_2;
        
        coef_douta_buf <= coef_douta;
        coef_doutb_buf <= coef_doutb;
        add_num_1_1 <= coef_douta_buf;
        add_num_2_1 <= coef_doutb_buf;
        
        read_en_buf_1 <= Rm_tready;
        read_en_buf_2 <= read_en_buf_1;
        read_en_buf_3 <= read_en_buf_2;
        read_en_buf_4 <= read_en_buf_3;
        read_en_buf_5 <= read_en_buf_4;
        read_en_buf_6 <= read_en_buf_5;
        
        read_done_buf_1 <= read_done;
        read_done_buf_2 <= read_done_buf_1;
        read_done_buf_3 <= read_done_buf_2;
        read_done_buf_4 <= read_done_buf_3;
        read_done_buf_5 <= read_done_buf_4;
        read_done_buf_6 <= read_done_buf_5;
    end
    
endmodule
