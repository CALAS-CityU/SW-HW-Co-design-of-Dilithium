`timescale 1ns / 1ps

module mem_write(

    input  wire clk,
    input  wire module_start,
    
    input  wire Ws_tready,
    output wire [63:0] Ws_tdata,
    output wire Ws_tvalid,
    
    output wire coef_ena,
    output wire coef_wea,
    output wire [7:0]coef_addra,
    input  wire [22:0] coef_douta,
    output wire coef_enb,
    output wire coef_web,
    output wire [7:0]coef_addrb,
    input  wire [22:0] coef_doutb,
    
    output wire module_done 

    );
    
    reg[7:0] counter;
    wire count_done;
    reg counter_working;
    
    reg[22:0] data1;
    reg[22:0] data2;
    reg working_1;
    reg working_2;
    reg done_1;
    reg done_2;
    wire mem_working;
    always@(posedge clk)
    begin
        counter <= (module_start)? 0 : (Ws_tready & mem_working)? (counter + 2'd2) : counter;
        counter_working <= module_start? 1 : (counter_working & count_done)? 0 : counter_working;
        data1 <= coef_douta;
        data2 <= coef_doutb;
        
        working_1 <= counter_working;
        working_2 <= working_1;
        done_1 <= count_done;
        done_2 <= done_1;
    end
    
    assign count_done = (counter == 8'd254);
    assign coef_addra = counter;
    assign coef_addrb = counter + 1'b1;
    assign Ws_tvalid = working_2 & Ws_tready;
    
    assign coef_ena = counter_working;
    assign coef_wea = 1'b0;
    assign coef_enb = counter_working;
    assign coef_web = 1'b0;
    assign Ws_tdata[22:0]  = data1;
    assign Ws_tdata[31:23] = 9'b0;
    assign Ws_tdata[54:32] = data2;
    assign Ws_tdata[63:55] = 9'b0; 
    
    assign module_done = done_2;
    assign mem_working = counter_working | done_1 | done_2;
    
endmodule
