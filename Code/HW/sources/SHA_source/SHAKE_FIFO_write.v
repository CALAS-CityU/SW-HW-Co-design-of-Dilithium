`timescale 1ns / 1ps

module SHAKE_FIFO_write
(
    input wire clk,
    input wire SHA3_start,
    output reg m_axis_tvalid,
    input wire m_axis_tready,
    output reg[63:0] m_axis_tdata,
    output reg[7:0] m_axis_tkeep,
    output wire m_axis_tlast,
    
    input wire[1:0] mode,
    input wire sample_sel,//0->Uni, 1->Rej
    input wire eta,//0->2, 1->4
    input wire[9:0] byte_write,
    
    input wire is_last, 
    input wire buffer_full,
    input wire[1343:0] out,
    input wire out_ready,
    output wire sha_hold,
    output reg squeeze,
    output wire module_end
    );
    
    reg[1:0] mode_buf;
    reg sample_sel_buf;//0->Uni, 1->Rej
    reg eta_buf;//0->2, 1->4
    
    
    reg [1:0] cur_state;
    reg [1:0] nex_state;
    reg [7:0] count_shake;//shake128和256在输出状态时的计数
    reg[1343:0] out_keep;
    wire[10:0] upper_shake256;
    wire[10:0] upper_shake128_Uni;
    wire[10:0] upper_shake128_Rej;
    wire shake256_eff;//shake256有效计算周期
    wire shake128_Uni_eff;//shake128有效计算周期
    wire shake128_Rej_eff;//shake128有效计算周期
    wire shake128_eff; 
    reg shake128_eff_buf;
    wire[63:0] out_shake256;//shake256每拍输出的数
    wire[63:0] out_256_reorder;
    wire[47:0] out_shake128_Uni;//shake128每拍采样的2组数 //temp_out_shake128;
    wire[7:0]  out_shake128_Rej;
    wire[22:0] sample_num1;//num_1
    wire[22:0] sample_num2;
    reg[22:0] sample_num1_buf;
    reg[22:0] sample_num2_buf;
    reg[22:0] sample_num1_buf2;
    reg[22:0] sample_num2_buf2;
    
    reg[22:0] sample_num_temp;//shake128中间缓存数//temp_num
    reg[22:0] sample_num_temp_buf;
    reg[22:0] sample_num_temp_buf2;
    wire label_num1;//第1个数采样有效标志位
    wire label_num2;//第2个数采样有效标志位
    reg label_num1_buf;
    
    reg label_temp;//中间缓存数有效标志位
    reg label_temp_buf;
    wire temp_save_last;//继续保存上一个中间缓存数
    wire temp_new;//保存一个新采样数
    wire temp_relace_new;//将采样数替换
    wire[1:0] add_label;
    wire label_out128;//shake128此拍FIFO是否有输出
    reg label_out128_buf;
    wire eff_count;//shake128和256有效计数标志位
    reg eff_count_1;
    reg eff_count_2;
    reg[22:0] out128_temp1;//从采样或者临时保存的数获得的第1个输出
    reg[22:0] out128_temp2;//从采样或者临时保存的数获得的第2个输出
    wire[11:0] temp1_1;
    wire[11:0] temp2_1;
    wire[3:0] temp1_2;
    wire[3:0] temp2_2;
    wire[3:0] temp1_3;
    wire[3:0] temp2_3;
    wire[2:0] Rej_mod5_n1;
    wire[2:0] Rej_mod5_n2;
    wire[31:0] out128_Rej_1;
    wire[31:0] out128_Rej_2;
    wire is_rej_samp;
    reg[8:0] out_count;//shake128和256剩余的byte数
    wire end_flag;//输出满足要求
    reg end_flag_1;
    reg end_flag_2;
    
    assign upper_shake256 = 11'd1087- (count_shake[4:0]<<6);
    assign upper_shake128_Uni = 11'd1343 - (count_shake[4:0]*48);
    assign upper_shake128_Rej = 11'd1343 - (count_shake<<3);
    assign shake256_eff = (count_shake < 5'd17) && (nex_state == 2'b11);
    assign shake128_Uni_eff = (count_shake < 5'd28);
    assign shake128_Rej_eff = (count_shake < 8'd168);
    assign shake128_eff = (!out_ready)&(nex_state == 2'b11)&(sample_sel_buf? shake128_Rej_eff:shake128_Uni_eff);
    assign out_shake256 = out_keep[upper_shake256 -: 64 ];
    assign out_256_reorder = {out_shake256[7:0],out_shake256[15:8],out_shake256[23:16],out_shake256[31:24],out_shake256[39:32],out_shake256[47:40],out_shake256[55:48],out_shake256[63:56]};
    assign out_shake128_Uni = out_keep[upper_shake128_Uni -: 48 ];
    assign out_shake128_Rej = out_keep[upper_shake128_Rej -: 8 ];//69
    assign sample_num1 = sample_sel_buf? out_shake128_Rej[3:0] : {out_shake128_Uni[30:24],out_shake128_Uni[39:32],out_shake128_Uni[47:40]} ;
    assign sample_num2 = sample_sel_buf? out_shake128_Rej[7:4] : {out_shake128_Uni[6:0],out_shake128_Uni[15:8],out_shake128_Uni[23:16]} ;
    assign label_num1 = shake128_eff_buf?(sample_sel_buf? (eta_buf? sample_num1_buf[3:0]<4'd9 : sample_num1_buf[3:0]<4'd15):( sample_num1_buf < 23'd8380417)):1'b0;
    assign label_num2 = shake128_eff_buf?(sample_sel_buf? (eta_buf? sample_num2_buf[3:0]<4'd9 : sample_num2_buf[3:0]<4'd15):( sample_num2_buf < 23'd8380417)):1'b0;
    assign temp_save_last = (label_temp==1'b1) && (label_num1+label_num2==1'b0);
    assign temp_new = label_temp==1'b0 && (label_num1+label_num2==1'b1);
    assign temp_relace_new = label_temp & label_num1 & label_num2;
    assign add_label = label_num1+label_num2+label_temp;
    assign label_out128 = ((add_label) > 1'b1 && shake128_eff_buf);
    assign eff_count = (mode_buf[0]? shake256_eff : label_out128_buf);
    assign temp1_1 = out128_temp1[3:0]*8'd205;
    assign temp2_1 = out128_temp2[3:0]*8'd205;
    assign temp1_2 = temp1_1[11:10]*3'd5;
    assign temp2_2 = temp2_1[11:10]*3'd5;
    assign temp1_3 = out128_temp1[3:0]-temp1_2;
    assign temp2_3 = out128_temp2[3:0]-temp2_2;
    assign Rej_mod5_n1 = temp1_3[2:0];
    assign Rej_mod5_n2 = temp2_3[2:0];
    assign out128_Rej_1 = eta_buf? 3'd4-out128_temp1[3:0]:2'd2-Rej_mod5_n1;
    assign out128_Rej_2 = eta_buf? 3'd4-out128_temp2[3:0]:2'd2-Rej_mod5_n2;
    assign is_rej_samp = (!mode_buf[0])& sample_sel_buf;
    assign sha_hold = (cur_state==2'b11)&&is_rej_samp&&(count_shake>2'd3)&&(count_shake<8'd127);
    assign end_flag = (cur_state==2'b11) && (out_count == 1'b0);
    assign module_end = mode_buf[0]? end_flag_1:end_flag_2;
    assign m_axis_tlast = mode_buf[0]? end_flag:end_flag_1;
    
    always@(posedge clk)
    begin
        cur_state <= nex_state;
        
        mode_buf <= SHA3_start? mode : mode_buf;
        sample_sel_buf <= SHA3_start? sample_sel : sample_sel_buf;
        eta_buf <= SHA3_start? eta : eta_buf;
        
    
        sample_num1_buf <= sample_num1;
        sample_num2_buf <= sample_num2;
        sample_num1_buf2 <= sample_num1_buf;
        sample_num2_buf2 <= sample_num2_buf;
        
        label_num1_buf <= label_num1;
        
        sample_num_temp_buf <= sample_num_temp;
        
        
        shake128_eff_buf <= SHA3_start? 1'b0 : shake128_eff;
        label_out128_buf <= label_out128;
         
        if(out_ready)
            count_shake <= 1'b0;
        else if(cur_state==2'b11)
            count_shake <= count_shake + 1'b1;
        else
            count_shake <= count_shake;
            
        if(out_ready)
            out_keep <= out;
        else
            out_keep <= out_keep;
        
        eff_count_1 <= eff_count;
        eff_count_2 <= eff_count_1;
            
        label_temp <= SHA3_start? 1'b0:((shake128_eff_buf)? (( temp_save_last|| temp_new || temp_relace_new)? 1'b1 :1'b0):label_temp);
        label_temp_buf <= label_temp;
        sample_num_temp <= temp_new?  (label_num1? sample_num1_buf:sample_num2_buf) : (temp_relace_new? sample_num2_buf : sample_num_temp);
        
        out128_temp1 <= label_temp_buf? sample_num_temp_buf : sample_num1_buf2;
        out128_temp2 <= (label_num1_buf&label_temp_buf)?  sample_num1_buf2 : sample_num2_buf2;
        
        
        if(is_last)
            squeeze <= 1'b1;
        else if(end_flag | SHA3_start)
            squeeze <= 1'b0;
        else
            squeeze <= squeeze;
            
        if( SHA3_start)
            out_count <= mode[0]? (byte_write>>3) : 8'd128;
        else if(cur_state == 2'b11)
            out_count <= out_count - eff_count;
        else 
            out_count <= out_count;
        
        m_axis_tdata <= mode_buf[0]? out_256_reorder : (sample_sel_buf? {out128_Rej_2,out128_Rej_1}:{9'd0, out128_temp2, 9'd0, out128_temp1});
        m_axis_tvalid = (cur_state == 2'b11)? ( mode_buf[0]? eff_count: eff_count_1): 1'b0;
        m_axis_tkeep = 8'b11111111;
        
        end_flag_1 <= end_flag;
        end_flag_2 <= end_flag_1;
    end
    
    always@(*)  begin
        case(cur_state)
            2'b00:
                if(is_last & (!buffer_full))
                    nex_state <= 2'b01;
                else if(is_last & buffer_full)
                    nex_state <= 2'b10;
                else
                    nex_state <= 2'b00;
            2'b01:
                if(buffer_full)
                    nex_state <= 2'b10;
                else
                    nex_state <= 2'b01;
            2'b10:
                if(out_ready)
                    nex_state <= 2'b11;
                else
                    nex_state <= 2'b10;
            2'b11:
                if(end_flag)
                    nex_state <= 2'b00;
                else
                    nex_state <= 2'b11;
            default:
                    nex_state <= 2'b00;
        endcase
    end
    
endmodule