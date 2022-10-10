`timescale 1ns / 1ps

module PWM_Ctrl
(
    input wire aresetn,
    input wire clk,
    
    input wire Matrix_mul_start,
    input wire[3:0] column_length,
    
    input wire Rm_tvalid,
    output wire Rm_tready,
    input wire[63:0] Rm_tdata,
    input wire[7:0]  Rm_tkeep,
    input wire Rm_tlast,
    
    output wire Ws_tvalid,
    input wire Ws_tready,
    output wire[63:0] Ws_tdata,
    output wire[7:0] Ws_tkeep,
    output wire Ws_tlast,
    
    output wire coef_ena,
    output wire coef_wea,
    output wire [7:0] coef_addra,
    output wire [22:0] coef_dina,
    input wire [22:0] coef_douta,
    
    output wire coef_enb,
    output wire coef_web,
    output wire [7:0] coef_addrb,
    output wire [22:0] coef_dinb,
    input wire [22:0]coef_doutb,
    
    output wire[22:0] mat_num1_1,
    output wire[22:0] mat_num1_2,
    input wire[22:0] mul_result1,
    
    output wire Matrix_mul_done
    );
    
    //port for read memory_initial
    wire coef_ena_1;
    wire coef_wea_1;
    wire [7:0] coef_addra_1;
    wire coef_enb_1;
    wire coef_web_1;
    wire [7:0] coef_addrb_1;
    
    //port for NTT
    wire coef_ena_2;
    wire coef_wea_2;
    wire [7:0] coef_addra_2;
    wire coef_enb_2;
    wire coef_web_2;
    wire [7:0] coef_addrb_2;
    
    wire Rm_tready_1;
    wire Rm_tready_2;
    
    reg  read_start;
    wire read_done;
    wire read_working;
    reg  compute_start;
    wire compute_done;
    wire compu_working;
    
    reg [1:0] cur_state;
    reg [1:0] nex_state;
    
    always@(posedge clk)
    begin
        cur_state <= nex_state;
        
        if(Matrix_mul_start)
             read_start <= 1'b1;
        else
            read_start <= 1'b0;
            
        if(read_done)
            compute_start <= 1'b1;
        else
            compute_start <= 1'b0;
    end
    
    always@(*)  begin
        case(cur_state)
            2'b00:
                if(Matrix_mul_start==1'b1)
                    nex_state <= 2'b01;
                else
                    nex_state <= 2'b00;
            2'b01:
                if(read_done==1'b1) 
                    nex_state <= 2'b10;
                else
                    nex_state <= 2'b01;
            2'b10:
                if(compute_done==1'b1) 
                    nex_state <= 2'b00;
                else
                    nex_state <= 2'b10;
            default:
                    nex_state <= 2'b00;
        endcase
    end
    
    assign read_working  = (cur_state == 2'b01); 
    assign compu_working = (cur_state == 2'b10);
    
    assign coef_ena = (read_working)? coef_ena_1 : coef_ena_2;
    assign coef_wea = (read_working)? coef_wea_1 : coef_wea_2;
    assign coef_addra = (read_working)? coef_addra_1 : coef_addra_2;
    
    assign coef_enb = (read_working)? coef_enb_1 :  coef_enb_2;
    assign coef_web = (read_working)? coef_web_1 :  coef_web_2;
    assign coef_addrb = (read_working)? coef_addrb_1 :  coef_addrb_2;
    
    assign Rm_tready = (read_working)? Rm_tready_1 : Rm_tready_2;
    
    assign Matrix_mul_done = compute_done;
    
    assign Ws_tkeep = 8'b11111111;
    assign Ws_tlast = compute_done;
    
    pwm_mem_read mem_test1
    (
        .clk(clk), 
        .module_start(read_start), 
        .Rm_tvalid(Rm_tvalid), 
        .Rm_tdata(Rm_tdata), 
        .rd_en(Rm_tready_1), 
        .coef_ena(coef_ena_1), 
        .coef_wea(coef_wea_1), 
        .coef_addra(coef_addra_1), 
        .coef_dina(coef_dina),
        .coef_enb(coef_enb_1), 
        .coef_web(coef_web_1), 
        .coef_addrb(coef_addrb_1), 
        .coef_dinb(coef_dinb),
        .module_done(read_done)
    ); 
    
     pwm_compute pwm_cal
   (
    clk, compute_start, compu_working, compute_done, column_length, coef_ena_2, coef_wea_2, coef_addra_2, coef_douta, coef_enb_2, coef_web_2,
    coef_addrb_2, coef_doutb, Rm_tvalid, Rm_tdata, Rm_tready_2, Ws_tready, Ws_tdata, Ws_tvalid, mat_num1_1,  mat_num1_2, mul_result1
    
    );
    
    
endmodule
