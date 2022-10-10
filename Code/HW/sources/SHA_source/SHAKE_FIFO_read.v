`timescale 1ns / 1ps

module SHAKE_FIFO_read
(
    input wire clk,
    input wire module_start,
    input wire [1:0] mode,
    input wire[31:0] byte_read,
    
    input wire Read_FIFO_tvalid,
    output wire Read_FIFO_tready,
    input wire[63:0] Read_FIFO_tdata,
    input wire[7:0]  Read_FIFO_tkeep,
    input wire Read_FIFO_tlast,
    
    input wire buffer_full,
    input wire i_last,
    output reg[63:0] shake_in,
    output reg in_ready, 
    output reg is_last,
    output reg [2:0] byte_num
    
    );
    
    reg [1:0] cur_state;
    reg [1:0] nex_state;
    wire rd_en;
    reg [31:0] read_counter;
    reg [4:0] hold_counter;
    wire temp_last;
    wire [2:0] temp_num;
    wire add_empty;
    wire empty_state;
    
    assign Read_FIFO_tready = rd_en;
    assign rd_en =(cur_state==2'b01) &  (Read_FIFO_tvalid | empty_state ) & (~i_last);
    assign temp_num = (temp_last)? (read_counter[2:0] ):0;
    assign temp_last = (read_counter < 4'd9) && (cur_state != 1'b0) && rd_en;
    assign add_empty = byte_read[2:0]==3'b0;
    assign empty_state=read_counter==4'd8 && add_empty;
    //assign read_counter = (temp_counter>5'd16)? (temp_counter - 4'd8) : 0; 
    
    always@(posedge clk)
    begin
        cur_state <= nex_state;
        shake_in <= empty_state? 1'b0 : {Read_FIFO_tdata[7:0],Read_FIFO_tdata[15:8],Read_FIFO_tdata[23:16],Read_FIFO_tdata[31:24],Read_FIFO_tdata[39:32],Read_FIFO_tdata[47:40],Read_FIFO_tdata[55:48],Read_FIFO_tdata[63:56]};
        is_last <= temp_last;
        in_ready <= rd_en;
        byte_num <= temp_num;
        if(i_last==1'b1) 
            hold_counter <= 1'b0;
        else
            hold_counter <= hold_counter + 1'b1;
        
        if(module_start)
        begin
            if(add_empty)
              read_counter <= byte_read+4'd8;
            else
              read_counter <= byte_read;  
        end
        else
            read_counter <= (read_counter - (rd_en<<3) );
            
        
    end
    
    always@(*)  begin
        case(cur_state)
            2'b00:
                if(module_start==1'b1)
                    nex_state <= 2'b01;
                else
                    nex_state <= 2'b00;
            2'b01:
                if(temp_last==1'b1)
                    nex_state <= 2'b00;
                else if(i_last==1'b1)
                    nex_state <= 2'b10;
                else
                    nex_state <= 2'b01;
            2'b10:
                if( (mode[0]==1'b1 && hold_counter==5'b11110) || (mode[0]==1'b0 && hold_counter==5'b11010) )
                    nex_state <= 2'b01;
                else
                    nex_state <= 2'b10;
            default:
                    nex_state <= 2'b00;
        endcase
    end
    
endmodule
