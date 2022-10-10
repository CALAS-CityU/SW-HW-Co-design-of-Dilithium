`timescale 1ns / 1ps

module NTT_Ctrl
(
    input wire aresetn,
    input wire clk,
    
    input wire start,
    input wire sel,
    
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
    
    output wire temp_ena,
    output wire temp_wea,
    output wire [7:0] temp_addra,
    output wire [22:0] temp_dina,
    input wire [22:0] temp_douta,
    
    output wire temp_enb,
    output wire temp_web,
    output wire [7:0] temp_addrb,
    output wire [22:0] temp_dinb,
    input wire  [22:0]temp_doutb,
    
    input wire[22:0] mul_result,
    output wire[22:0] opt1,
    output wire[22:0] opt2,
        
    output wire write_done
    );
    
    wire zeta_rd_en; //ROM for zeta
    wire [7:0] zeta_addr;
    wire [22:0] zeta_dout;     
    
    
    
    //port for read memory_initial
    wire coef_ena_1;
    wire coef_wea_1;
    wire [7:0] coef_addra_1;
    wire [22:0] coef_dina_1;
    wire coef_enb_1;
    wire coef_web_1;
    wire [7:0] coef_addrb_1;
    wire [22:0]coef_dinb_1;
    
    //port for NTT
    wire coef_ena_2;
    wire coef_wea_2;
    wire [7:0] coef_addra_2;
    wire [22:0] coef_dina_2;
    wire coef_enb_2;
    wire coef_web_2;
    wire [7:0] coef_addrb_2;
    wire  [22:0]coef_dinb_2;
    
    //port for write memory
    wire coef_ena_3;
    wire coef_wea_3;
    wire [7:0] coef_addra_3;
    wire coef_enb_3;
    wire coef_web_3;
    wire [7:0] coef_addrb_3;

    wire sel_keep;
    wire [22:0] a;
    wire [22:0] b;
    wire [22:0] omiga;
    wire [22:0] a1;
    wire [22:0] b1;
    
    reg  read_start;
    wire read_done;
    wire read_working;
    reg  compute_start;
    wire compute_done;
    //wire compu_working;
    reg  write_start;
    wire write_working;
    
    reg [1:0] cur_state;
    reg [1:0] nex_state;
    
    always@(posedge clk)
    begin
        cur_state <= nex_state;
        
        if(start)
             read_start <= 1'b1;
        else
            read_start <= 1'b0;
            
        if(read_done)
            compute_start <= 1'b1;
        else
            compute_start <= 1'b0;
            
        if(compute_done)
            write_start <= 1'b1;
        else
            write_start <= 1'b0;
            
    end
    
    always@(*)  begin
        case(cur_state)
            2'b00:
                if(start==1'b1)
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
                    nex_state <= 2'b11;
                else
                    nex_state <= 2'b10;
            2'b11:
                if(write_done == 1'b1)
                    nex_state <= 2'b00;
                else
                    nex_state <= 2'b11;
            default:
                    nex_state <= 2'b00;
        endcase
    end
    
    assign read_working  = (cur_state == 2'b01); 
    assign compu_working = (cur_state == 2'b10);
    assign write_working = (cur_state == 2'b11);
    
    assign coef_ena = (read_working)? coef_ena_1 : (write_working)? coef_ena_3 : coef_ena_2;
    assign coef_wea = (read_working)? coef_wea_1 : (write_working)? coef_wea_3 : coef_wea_2;
    assign coef_addra = (read_working)? coef_addra_1 : (write_working)? coef_addra_3 : compu_working? coef_addra_2 : 1'b0;
    assign coef_dina = (read_working)? coef_dina_1 : coef_dina_2;
    
    assign coef_enb = (read_working)? coef_enb_1 : (write_working)? coef_enb_3 : coef_enb_2;
    assign coef_web = (read_working)? coef_web_1 : (write_working)? coef_web_3 : coef_web_2;
    assign coef_addrb = (read_working)? coef_addrb_1 : (write_working)? coef_addrb_3 : compu_working? coef_addrb_2 : 1'b0;
    assign coef_dinb = (read_working)? coef_dinb_1 : coef_dinb_2;
    assign Ws_tkeep = 8'b11111111;
    assign Ws_tlast = write_done;
    
    mem_read mem_test1(clk, read_start, read_working, Rm_tvalid, Rm_tdata, Rm_tready, coef_ena_1, coef_wea_1, coef_addra_1, coef_dina_1,coef_enb_1, coef_web_1, coef_addrb_1, coef_dinb_1,
                       read_done); 
    zetas_mem        romtest(clk, zeta_rd_en, zeta_addr, zeta_dout);
    compact_BFU_test BFUtest(clk, sel_keep, a, b, omiga, a1, b1, mul_result, opt1, opt2);
    
    ntt_intt_pipe    ntttest(clk, read_start, compu_working, compute_start, sel, compute_done, zeta_rd_en, zeta_addr, zeta_dout, coef_ena_2, coef_wea_2, coef_addra_2, coef_dina_2,coef_douta,coef_enb_2,coef_web_2,coef_addrb_2,coef_dinb_2,
                       coef_doutb, temp_ena, temp_wea, temp_addra,temp_dina,temp_douta,temp_enb,temp_web,temp_addrb,temp_dinb,temp_doutb,sel_keep, a,b, omiga,a1,b1
                        );
    mem_write mem_test2(clk, write_start, Ws_tready, Ws_tdata, Ws_tvalid, coef_ena_3, coef_wea_3, coef_addra_3, coef_douta, coef_enb_3, coef_web_3, coef_addrb_3, coef_doutb, write_done);      
                 
endmodule
