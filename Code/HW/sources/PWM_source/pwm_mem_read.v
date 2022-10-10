`timescale 1ns / 1ps

module pwm_mem_read
(
    input  wire clk,
    input  wire module_start,
    
    
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
    reg FIFO_Read_working;
    reg[63:0] data_in;
    
    wire count_done;
    reg[7:0] counter;
    reg[7:0] counter_1;
    reg rd_en_1;
    
    reg done_1;
    reg done_2;
    
    always@(posedge clk)
    begin
        counter <= (module_start | count_done)? 0 : (rd_en)?  (counter + 2'd2) : counter;
        
        data_in <= Rm_tdata;
   
        counter_1 <= counter;
        rd_en_1 <= rd_en;
        done_1 <= count_done;
        done_2 <= done_1;
        FIFO_Read_working <= module_start? 1'b1 : (count_done? 1'b0 : FIFO_Read_working);
    end
    
    assign count_done = (counter == 8'd254);
    assign coef_addra = counter_1;
    assign coef_addrb = counter_1 + 1'b1;
    assign rd_en = FIFO_Read_working & Rm_tvalid;
    assign coef_ena = rd_en_1;
    assign coef_wea = 1'b1;
    assign coef_enb = rd_en_1;
    assign coef_web = 1'b1;
    assign coef_dina = data_in[22:0];
    assign coef_dinb = data_in[54:32];
    
    assign module_done = done_2;
    
endmodule
