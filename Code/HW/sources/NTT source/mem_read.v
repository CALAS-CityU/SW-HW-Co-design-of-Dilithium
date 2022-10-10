`timescale 1ns / 1ps

module mem_read
(
    input  wire clk,
    input  wire module_start,
    input  wire read_working,
    
    input  wire Rm_tvalid,
    input  wire [63:0] Rm_tdata,
    output wire rd_en,
    
    output wire coef_ena,
    output wire coef_wea,
    output wire [7:0]coef_addra,
    output wire [22:0] coef_dina,
    output wire coef_enb,
    output wire coef_web,
    output wire [7:0]coef_addrb,
    output wire [22:0] coef_dinb,
    
    output wire module_done
    
    );
    
    reg[63:0] data_in;
    wire[31:0] data_temp_1;
    wire[31:0] data_temp_2;
    reg[22:0] data_1;
    reg[22:0] data_2;
    
    wire count_done;
    reg[7:0] counter;
    reg[7:0] counter_1;
    reg[7:0] counter_2;
    reg rd_en_1;
    reg rd_en_2;
    
    reg done_1;
    reg done_2;
    reg done_3;
    
    always@(posedge clk)
    begin
        counter <= (module_start | count_done)? 0 : (rd_en)?  (counter + 2'd2) : counter;
        
        data_in <= Rm_tdata;
        data_1 <= data_temp_1[22:0];
        data_2 <= data_temp_2[22:0];
        counter_1 <= counter;
        counter_2 <= counter_1;
        rd_en_1 <= rd_en;
        rd_en_2 <= rd_en_1;
        done_1 <= count_done;
        done_2 <= done_1;
        done_3 <= done_2;
    end
    
    assign data_temp_1 = data_in[31]? (data_in[31:0] + 23'd8380417): data_in[31:0];
    assign data_temp_2 = data_in[63]? (data_in[63:32]+ 23'd8380417): data_in[63:32];
    assign count_done = (counter == 8'd254);
    assign coef_addra = counter_2;
    assign coef_addrb = counter_2 + 1'b1;
    assign rd_en = read_working & Rm_tvalid &(~module_start);
    
    assign coef_ena = rd_en_2;
    assign coef_wea = 1'b1;
    
    assign coef_enb = rd_en_2;
    assign coef_web = 1'b1;
    assign coef_dina = data_1;
    assign coef_dinb = data_2;
    
    assign module_done = done_3;
    
   
    
endmodule
