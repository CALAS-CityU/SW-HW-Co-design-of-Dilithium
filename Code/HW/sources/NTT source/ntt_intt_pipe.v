`timescale 1ns / 1ps

module ntt_intt_pipe(
    input  wire clk,
    input  wire read_start,
    input  wire compu_working,
    input  wire start,//1 for start
    input  wire sel, //0 for DIT, 1 for DIF
    output wire done,
    
    output wire zeta_rd_en, //ROM for zeta
    output reg [7:0] zeta_addr_buf,
    input  wire [22:0] zeta_dout,
                           
    output wire coef_ena,//RAM for 256 coefficient
    output wire coef_wea,
    output wire [7:0 ]coef_addra,
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
    
    output reg sel_keep,
    output reg [22:0] a,
    output reg [22:0] b, 
    output reg [22:0] omiga,
    input  wire [22:0] a1,
    input  wire [22:0] b1
    );
    
    wire[7:0] len;
    reg[7:0] len_buf;
    reg [2:0] counter1;
    reg [7:0] counter2;
    reg [6:0] counter3;
    
    assign len = (sel_keep)?(1<<counter1):(128>>counter1);
    
    wire[7:0] temp_loop2;
    assign temp_loop2 = counter3 + len_buf;
    
    wire count1_last;
    wire count2_last;
    wire count3_last;
    
    reg round_start_buf1;
    reg round_start_buf2;
    reg round_start_buf3;
    reg round_start_buf4;
    reg round_start_buf5;
    reg round_start_buf6;
    reg round_start_buf7;
    reg round_start_buf8;
    reg round_start_buf9;
    reg round_start_buf10;
    reg round_start_buf11;
    reg round_start_buf12;
    reg round_start_buf13;
    reg round_start_buf14;
    
    wire ntt_first;
    wire ntt_last;
    assign ntt_first = (counter1 == 0);
    assign ntt_last = (counter1==3'b111);
    
    reg  count2_last_1;
    reg  count2_last_2;
    reg  count2_last_3;
    reg  count2_last_4;
    reg  count2_last_5;
    reg  count2_last_6;
    reg  count2_last_7;
    reg  count2_last_8;
    reg  count2_last_9;
    reg  count2_last_10;
    reg  count2_last_11;
    reg  count2_last_12;
    reg  count2_last_13;
    reg  count2_last_14;
    reg  count2_last_15;
    reg  count2_last_16;
    
    assign count3_last = (counter3==(len-1'b1));
    assign count2_last = (counter2 == (9'd255-temp_loop2));
    assign count1_last = (counter1 == 3'b111) && count2_last; 
    
    wire count2_buf;
    assign count2_buf = count2_last_1 | count2_last_2 | count2_last_3 | count2_last_4 | count2_last_5 | count2_last_6 | count2_last_7 | count2_last_8 | count2_last_9 | count2_last_10| count2_last_11| count2_last_12| count2_last_13| count2_last_14 | count2_last_15;
    
     wire keep;
    assign keep =  (ntt_first&&(!count2_last))?0: (count2_last||count2_buf);
    
    reg running;
    reg running_buf;
    wire round_start;
    assign round_start = (counter2 == 0)&(counter3==0)&(!keep)&running;
    
    reg [7:0] zeta_addr;
    
    wire[7:0] BFU1_addr;//read_data1: a
    wire[7:0] BFU2_addr;//read_data2: b
    
    reg[22:0] a1_buf_1;
    reg[22:0] b1_buf_1;
    
    reg[7:0] BFU1_addr_1;
    reg[7:0] BFU1_addr_2;
    reg[7:0] BFU1_addr_3;
    reg[7:0] BFU1_addr_4;
    reg[7:0] BFU1_addr_5;
    reg[7:0] BFU1_addr_6;
    reg[7:0] BFU1_addr_7;
    reg[7:0] BFU1_addr_8;
    reg[7:0] BFU1_addr_9;
    reg[7:0] BFU1_addr_10;
    reg[7:0] BFU1_addr_11;
    reg[7:0] BFU1_addr_12;
    reg[7:0] BFU1_addr_13;
    reg[7:0] BFU1_addr_14;
    reg[7:0] BFU1_addr_15;
    
    reg[7:0] BFU2_addr_1;
    reg[7:0] BFU2_addr_2;
    reg[7:0] BFU2_addr_3;
    reg[7:0] BFU2_addr_4;
    reg[7:0] BFU2_addr_5;
    reg[7:0] BFU2_addr_6;
    reg[7:0] BFU2_addr_7;
    reg[7:0] BFU2_addr_8;
    reg[7:0] BFU2_addr_9;
    reg[7:0] BFU2_addr_10;
    reg[7:0] BFU2_addr_11;
    reg[7:0] BFU2_addr_12;
    reg[7:0] BFU2_addr_13;
    reg[7:0] BFU2_addr_14;
    reg[7:0] BFU2_addr_15;
    
    assign BFU1_addr = counter2 + counter3;
    assign BFU2_addr = BFU1_addr + len;
    
    reg block;
    
    assign coef_addra = block? BFU1_addr_15:BFU1_addr_1;
    assign coef_addrb = block? BFU2_addr_15:BFU2_addr_1;
    assign temp_addra = block? BFU1_addr_1:BFU1_addr_15;
    assign temp_addrb = block? BFU2_addr_1:BFU2_addr_15;
    
    assign coef_dina = block? a1_buf_1 : 0;
    assign coef_dinb = block? b1_buf_1 : 0;
    assign temp_dina = block? 0  : a1_buf_1;
    assign temp_dinb = block? 0  : b1_buf_1;
    
    reg wr_en;
    
    assign zeta_rd_en = running_buf;
    
    wire RAM_enable = running_buf || wr_en;
    
    assign coef_ena = RAM_enable;
    assign coef_enb = RAM_enable;
    assign temp_ena = RAM_enable;
    assign temp_enb = RAM_enable;
    
    assign coef_wea = (block&&wr_en)? 1 :0;
    assign coef_web = (block&&wr_en)? 1 :0;
    assign temp_wea =  ((!block)&&wr_en)? 1 :0;
    assign temp_web =  ((!block)&&wr_en)? 1 :0;
    
    wire zeta_keep;
    assign zeta_keep =  ntt_last&&count2_buf;
    
    assign done = (!running)&&(wr_en)&&count2_last_15;
    
    wire start_stop;
    assign start_stop = (start||!compu_working);
    
    always@(posedge clk)
    begin
        sel_keep <= (read_start)? sel : sel_keep;
        running <= start? 1'b1 : count1_last? 1'b0 : running;
        running_buf <= running;
        wr_en <= (round_start_buf14)? 1 : (count2_last_15)?0: wr_en;//delay -1
        
        block <= start? 1'b0 : count2_last_16? ~block : block;
        
        zeta_addr<= (start)? (sel_keep? 254:0): ( (count3_last && (!zeta_keep))? (sel_keep? (zeta_addr-1'b1):(zeta_addr+1'b1)) : zeta_addr);
        zeta_addr_buf <= zeta_addr;
        
        counter3 <= (start_stop||count3_last||keep)? 0 : (counter3+1'b1);
        counter2 <= (start_stop||keep)? 0: (count3_last?(counter2+temp_loop2+1'b1):counter2);
        counter1 <= (start_stop)? 0 : count2_last? (counter1+1):counter1;
        
        len_buf <= len;
        
        count2_last_1 <= count2_last;
        count2_last_2 <= count2_last_1;
        count2_last_3 <= count2_last_2;
        count2_last_4 <= count2_last_3;
        count2_last_5 <= count2_last_4;
        count2_last_6 <= count2_last_5;
        count2_last_7 <= count2_last_6;
        count2_last_8 <= count2_last_7;
        count2_last_9 <= count2_last_8;
        count2_last_10 <= count2_last_9;
        count2_last_11 <= count2_last_10;
        count2_last_12 <= count2_last_11;
        count2_last_13 <= count2_last_12;
        count2_last_14 <= count2_last_13;
        count2_last_15 <= count2_last_14;
        count2_last_16 <= count2_last_15;
        
        round_start_buf1 <= round_start;
        round_start_buf2 <= round_start_buf1;
        round_start_buf3 <= round_start_buf2;
        round_start_buf4 <= round_start_buf3;
        round_start_buf5 <= round_start_buf4;
        round_start_buf6 <= round_start_buf5;
        round_start_buf7 <= round_start_buf6;
        round_start_buf8 <= round_start_buf7;
        round_start_buf9 <= round_start_buf8;
        round_start_buf10 <= round_start_buf9;
        round_start_buf11 <= round_start_buf10;
        round_start_buf12 <= round_start_buf11;
        round_start_buf13 <= round_start_buf12;
        round_start_buf14 <= round_start_buf13;
        
        a <= block? temp_douta:coef_douta;
        b <= block? temp_doutb:coef_doutb;

        omiga <= sel_keep? (23'd8380417-zeta_dout):zeta_dout;
        a1_buf_1 <= a1;
        b1_buf_1 <= b1;
        
        BFU1_addr_1 <= BFU1_addr;
        BFU1_addr_2 <= BFU1_addr_1;
        BFU1_addr_3 <= BFU1_addr_2;
        BFU1_addr_4 <= BFU1_addr_3;
        BFU1_addr_5 <= BFU1_addr_4;
        BFU1_addr_6 <= BFU1_addr_5;
        BFU1_addr_7 <= BFU1_addr_6;
        BFU1_addr_8 <= BFU1_addr_7;
        BFU1_addr_9 <= BFU1_addr_8;
        BFU1_addr_10 <= BFU1_addr_9;
        BFU1_addr_11 <= BFU1_addr_10;
        BFU1_addr_12 <= BFU1_addr_11;
        BFU1_addr_13 <= BFU1_addr_12;
        BFU1_addr_14 <= BFU1_addr_13;
        BFU1_addr_15 <= BFU1_addr_14;
        
        BFU2_addr_1 <= BFU2_addr;
        BFU2_addr_2 <= BFU2_addr_1;
        BFU2_addr_3 <= BFU2_addr_2;
        BFU2_addr_4 <= BFU2_addr_3;
        BFU2_addr_5 <= BFU2_addr_4;
        BFU2_addr_6 <= BFU2_addr_5;
        BFU2_addr_7 <= BFU2_addr_6;
        BFU2_addr_8 <= BFU2_addr_7;
        BFU2_addr_9 <= BFU2_addr_8;
        BFU2_addr_10 <= BFU2_addr_9;
        BFU2_addr_11 <= BFU2_addr_10;
        BFU2_addr_12 <= BFU2_addr_11;
        BFU2_addr_13 <= BFU2_addr_12;
        BFU2_addr_14 <= BFU2_addr_13;
        BFU2_addr_15 <= BFU2_addr_14;
        
    end
    
endmodule 
