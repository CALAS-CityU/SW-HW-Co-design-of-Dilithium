`timescale 1ns / 1ps

module add_Ctrl
(
    input wire aresetn,
    input wire clk,
    
    input wire poly_add_start,
    input wire add_sub_sel,
    input wire[3:0] vector_length,
    
    input wire Read_FIFO_tvalid,
    output wire Read_FIFO_tready,
    input wire[63:0]  Read_FIFO_tdata,
    input wire[7:0]  Read_FIFO_tkeep,
    input wire Read_FIFO_tlast,
    
    output wire Write_FIFO_tvalid,
    input wire Write_FIFO_tready,
    output wire[63:0] Write_FIFO_tdata,
    output wire[7:0] Write_FIFO_tkeep,
    output wire Write_FIFO_tlast,
    
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
    
    output wire poly_add_done
    //add debug signal
    
    );
    
   
    wire coef_ena_1;
    wire coef_wea_1;
    wire [7:0]coef_addra_1;
    wire [22:0] coef_dina_1;
    wire coef_enb_1;
    wire coef_web_1;
    wire [7:0]coef_addrb_1;
    wire [22:0] coef_dinb_1;
    
    wire coef_ena_2;
    wire coef_wea_2;
    wire [7:0]coef_addra_2;
    wire [22:0] coef_dina_2;
    wire coef_enb_2;
    wire coef_web_2;
    wire [7:0]coef_addrb_2;
    wire [22:0] coef_dinb_2;
    
    wire coef_ena_3;
    wire coef_wea_3;
    wire [7:0]coef_addra_3;
    wire [22:0] coef_douta_3;
    wire coef_enb_3;
    wire coef_web_3;
    wire [7:0]coef_addrb_3;
    wire [22:0] coef_doutb_3;
    
    
    
    wire temp_ena_2;
    wire temp_wea_2;
    wire [7:0] temp_addra_2;
    wire temp_enb_2;
    wire temp_web_2;
    wire [7:0] temp_addrb_2;
    
    
    reg[63:0] input_data;
    reg[22:0] data_in_1;
    reg[22:0] data_in_2;
    
    wire Read_FIFO_tready_1;
    wire Read_FIFO_tready_2;
    wire Read_FIFO_tready_3;
    
    
    
    reg [1:0] cur_state;
    reg [1:0] next_state;
    
    wire empty_state;
    
    reg  read_first_start;
    wire read_first_done;
    wire read_first_working;
    
    reg  read_last_start;
    wire read_last_done;
    wire read_last_working;
    
    reg  write_start;
    wire write_done;
    wire write_working;
    
    wire ram_sel_1;
    wire ram_sel_2;
    
    wire[22:0]  add_num_1_1;
    wire[22:0]  add_num_1_2;
    wire[22:0]  add_num_2_1;
    wire[22:0]  add_num_2_2;
    
    wire[22:0]  add_num_1_1_com;
    wire[22:0]  add_num_1_2_com;
    wire[22:0]  add_num_2_1_com;
    wire[22:0]  add_num_2_2_com;
    
    wire[22:0]  add_num_1_1_wri;
    wire[22:0]  add_num_1_2_wri;
    wire[22:0]  add_num_2_1_wri;
    wire[22:0]  add_num_2_2_wri;
    
    wire[23:0] temp_result_1;
    wire[23:0] temp_result_2;
    reg[23:0] temp_result_1_buf;
    reg[23:0] temp_result_2_buf;
    reg[22:0] add_result_1;
    reg[22:0] add_result_2;
    
    assign add_num_1_1 = read_last_working? add_num_1_1_com : add_num_1_1_wri;
    assign add_num_1_2 = read_last_working? add_num_1_2_com : add_num_1_2_wri;
    assign add_num_2_1 = read_last_working? add_num_2_1_com : add_num_2_1_wri;
    assign add_num_2_2 = read_last_working? add_num_2_2_com : add_num_2_2_wri;
    
    assign temp_result_1 = add_num_1_1 + add_num_1_2;
    assign temp_result_2 = add_num_2_1 + add_num_2_2;
    
    always@(posedge clk)
    begin
        cur_state <= next_state;
        input_data <= Read_FIFO_tdata;
        temp_result_1_buf <= temp_result_1;
        temp_result_2_buf <= temp_result_2;
        data_in_1 <=  input_data[31]? (input_data[31:0] + 23'd8380417): input_data[31:0];
        data_in_2 <=  input_data[63]? (input_data[63:32]+ 23'd8380417): input_data[63:32];
        
        add_result_1 <= (temp_result_1_buf>23'd8380416)? temp_result_1_buf - 23'd8380417 : temp_result_1_buf[22:0];
        add_result_2 <= (temp_result_2_buf>23'd8380416)? temp_result_2_buf - 23'd8380417 : temp_result_2_buf[22:0];
        
        if(poly_add_start)
             read_first_start <= 1'b1;
        else
            read_first_start <= 1'b0;
        
        if(read_first_done && next_state == 2'b10)
            read_last_start <= 1'b1;
        else
            read_last_start <= 1'b0;
        
        if((read_first_done|read_last_done)&&next_state == 2'b11)
            write_start <= 1'b1;
        else
            write_start <= 1'b0;
    end
    
    always@(*)  begin
        case(cur_state)
            2'b00:
                if(poly_add_start==1'b1)
                    next_state <= 2'b01;
                else
                    next_state <= 2'b00;
            2'b01:
                if(read_first_done==1'b1) 
                begin
                    if(vector_length == 1 )
                        next_state <= 2'b11;
                    else
                        next_state <= 2'b10;
                end
                else
                    next_state <= 2'b01;
            2'b10:
                if(read_last_done==1'b1) 
                    next_state <= 2'b11;
                else
                    next_state <= 2'b10;
            2'b11:
                if(write_done==1'b1) 
                    next_state <= 2'b00;
                else
                    next_state <= 2'b11;         
            default:
                    next_state <= 2'b00;
        endcase
    end
    
    assign read_first_working = (cur_state == 2'b01); 
    assign read_last_working  = (cur_state == 2'b10); 
    assign write_working      = (cur_state == 2'b11); 
    
    assign ram_sel_1 = write_working & (vector_length[0]);
    assign ram_sel_2 = write_working & (!vector_length[0]);
    
    assign coef_ena = read_first_working? coef_ena_1 : ram_sel_1? coef_ena_3 : coef_ena_2;
    assign coef_wea = read_first_working? coef_wea_1 : ram_sel_1? coef_wea_3 : coef_wea_2;
    assign coef_addra = read_first_working? coef_addra_1 : ram_sel_1? coef_addra_3 : coef_addra_2;
    assign coef_dina = read_first_working? coef_dina_1 : coef_dina_2;
    
    assign coef_enb = read_first_working? coef_enb_1 : ram_sel_1? coef_enb_3 : coef_enb_2;
    assign coef_web = read_first_working? coef_web_1 : ram_sel_1? coef_web_3 : coef_web_2;
    assign coef_addrb = read_first_working? coef_addrb_1 : ram_sel_1? coef_addrb_3 : coef_addrb_2;
    assign coef_dinb = read_first_working? coef_dinb_1 : coef_dinb_2;
    
    assign coef_douta_3 = (vector_length[0])? coef_douta: temp_douta;
    assign coef_doutb_3 = (vector_length[0])? coef_doutb: temp_doutb;
    
    assign temp_ena = read_last_working? temp_ena_2 : coef_ena_3;
    assign temp_wea = read_last_working? temp_wea_2 : coef_wea_3;
    assign temp_addra = read_last_working? temp_addra_2 : coef_addra_3;
    
    assign temp_enb = read_last_working? temp_enb_2 : coef_enb_3;
    assign temp_web = read_last_working? temp_web_2 : coef_web_3;
    assign temp_addrb = read_last_working? temp_addrb_2 : coef_addrb_3;
    
    assign Read_FIFO_tready = (read_first_working)? Read_FIFO_tready_1 : write_working? Read_FIFO_tready_3 : Read_FIFO_tready_2;
    
    assign poly_add_done = write_done;
    assign Write_FIFO_tkeep = 8'b11111111;
    assign Write_FIFO_tlast = write_done;
    
    read_mem_add     add_read(clk, read_first_start, Read_FIFO_tvalid, data_in_1, data_in_2, Read_FIFO_tready_1, coef_ena_1, coef_wea_1, coef_addra_1, coef_dina_1, coef_enb_1, coef_web_1, coef_addrb_1, coef_dinb_1, read_first_done);
    
    compute_switch_add add_comput(clk, read_last_start, read_last_done, read_last_working, vector_length, coef_ena_2, coef_wea_2, coef_addra_2, coef_dina_2, coef_douta, coef_enb_2, coef_web_2, coef_addrb_2, coef_dinb_2, coef_doutb,
                             temp_ena_2, temp_wea_2, temp_addra_2, temp_dina, temp_douta, temp_enb_2, temp_web_2, temp_addrb_2, temp_dinb, temp_doutb, Read_FIFO_tvalid, data_in_1, data_in_2, Read_FIFO_tready_2,
                             add_num_1_1_com, add_num_1_2_com, add_num_2_1_com, add_num_2_2_com, add_result_1, add_result_2);
                              
    compute_write_add add_write(clk, write_start, write_done, write_working, add_sub_sel, coef_ena_3, coef_wea_3, coef_addra_3,coef_douta_3, coef_enb_3, coef_web_3, coef_addrb_3, coef_doutb_3,
                            Read_FIFO_tvalid, data_in_1, data_in_2, Read_FIFO_tready_3, Write_FIFO_tready, Write_FIFO_tdata, Write_FIFO_tvalid,
                            add_num_1_1_wri, add_num_1_2_wri, add_num_2_1_wri, add_num_2_2_wri, add_result_1, add_result_2);
    
    
endmodule
