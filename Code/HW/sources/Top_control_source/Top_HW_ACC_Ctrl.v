`timescale 1ns / 1ps

module Top_HW_ACC_Ctrl
(
    input wire aresetn,
    input wire clk,
    
    input wire[2:0] start_module,
    input wire sel_NTT,
    input wire[3:0] column_length_PWM,
    input wire add_sub_sel,
    input wire[3:0] vector_length,
    input wire [1:0] mode_SHA,
    input wire sample_sel_SHA,//0->Uni, 1->Rej
    input wire eta_SHA,//0->2, 1->4
    input wire[31:0] byte_read_SHA,
    input wire[9:0] byte_write_SHA,
    
    //DMA write read_data to slave port
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    input wire[63:0] s_axis_tdata,
    input wire[7:0] s_axis_tkeep,
    input wire s_axis_tlast,
    //Send computed data to DMA via master port
    output wire m_axis_tvalid,
    input wire m_axis_tready,
    output wire[63:0] m_axis_tdata,
    output wire[7:0] m_axis_tkeep,
    output wire m_axis_tlast,
    output wire [31 : 0] read_FIFO_count,
    output wire [31 : 0] write_FIFO_count
    );
    
    wire Rm_tvalid;
    wire Rm_tready;
    wire[63:0] Rm_tdata;
    wire[7:0]  Rm_tkeep;
    wire Rm_tlast;

    wire Ws_tvalid;
    wire Ws_tready;
    wire[63:0] Ws_tdata;
    wire[7:0] Ws_tkeep;
    wire Ws_tlast;
    
    reg[2:0] cur_state;
    reg[2:0] nex_state;
    
    wire NTT_done;
    reg  NTT_start;
    wire NTT_working;
    
    wire PWM_done;
    reg  PWM_start;
    wire PWM_working;
    
    wire add_done;
    reg  add_start;
    wire add_working;
    
    wire SHA3_done;
    reg  SHA3_start;
    wire SHA3_working;
    
    assign NTT_working = (cur_state == 3'b001);
    assign PWM_working = (cur_state == 3'b010);
    assign add_working = (cur_state == 3'b011);
    assign SHA3_working= (cur_state == 3'b100);
    
    wire Rm_tvalid_001;
    wire Rm_tready_001;
    wire[63:0] Rm_tdata_001;
    wire[7:0] Rm_tkeep_001;
    wire Rm_tlast_001;
    
    assign Rm_tvalid_001 = (NTT_working)? Rm_tvalid : 1'b0;
    assign Rm_tdata_001  = (NTT_working)? Rm_tdata  : 1'b0;
    assign Rm_tkeep_001  = (NTT_working)? Rm_tkeep  : 1'b0;
    assign Rm_tlast_001  = (NTT_working)? Rm_tlast  : 1'b0;
    
    wire Ws_tvalid_001;
    wire Ws_tready_001;
    wire[63:0] Ws_tdata_001;
    wire[7:0] Ws_tkeep_001;
    wire Ws_tlast_001;
    
    assign Ws_tready_001 = (NTT_working)? Ws_tready : 1'b0;
    
    //FIFO interface for matrix_mul
    wire Rm_tvalid_010;
    wire Rm_tready_010;
    wire[63:0] Rm_tdata_010;
    wire[7:0] Rm_tkeep_010;
    wire Rm_tlast_010;
    
    assign Rm_tvalid_010 = (PWM_working)? Rm_tvalid : 1'b0;
    assign Rm_tdata_010  = (PWM_working)? Rm_tdata  : 1'b0;
    assign Rm_tkeep_010  = (PWM_working)? Rm_tkeep  : 1'b0;
    assign Rm_tlast_010  = (PWM_working)? Rm_tlast  : 1'b0;
    
    wire Ws_tvalid_010;
    wire Ws_tready_010;
    wire[63:0] Ws_tdata_010;
    wire[7:0] Ws_tkeep_010;
    wire Ws_tlast_010;
    
    assign Ws_tready_010 = (PWM_working)? Ws_tready : 1'b0;
    
    //FIFO interface for poly_add
    wire Rm_tvalid_011;
    wire Rm_tready_011;
    wire[63:0] Rm_tdata_011;
    wire[7:0] Rm_tkeep_011;
    wire Rm_tlast_011;
    
    assign Rm_tvalid_011 = (add_working)? Rm_tvalid : 1'b0;
    assign Rm_tdata_011  = (add_working)? Rm_tdata  : 1'b0;
    assign Rm_tkeep_011  = (add_working)? Rm_tkeep  : 1'b0;
    assign Rm_tlast_011  = (add_working)? Rm_tlast  : 1'b0;
    
    wire Ws_tvalid_011;
    wire Ws_tready_011;
    wire[63:0] Ws_tdata_011;
    wire[7:0] Ws_tkeep_011;
    wire Ws_tlast_011;
    
    assign Ws_tready_011 = (add_working)? Ws_tready : 1'b0;
    
    //FIFO interface for SHA3
    wire Rm_tvalid_100;
    wire Rm_tready_100;
    wire[63:0] Rm_tdata_100;
    wire[7:0] Rm_tkeep_100;
    wire Rm_tlast_100;
    
    assign Rm_tvalid_100 = (SHA3_working)? Rm_tvalid : 1'b0;
    assign Rm_tdata_100  = (SHA3_working)? Rm_tdata  : 1'b0;
    assign Rm_tkeep_100  = (SHA3_working)? Rm_tkeep  : 1'b0;
    assign Rm_tlast_100  = (SHA3_working)? Rm_tlast  : 1'b0;
    
    wire Ws_tvalid_100;
    wire Ws_tready_100;
    wire[63:0] Ws_tdata_100;
    wire[7:0] Ws_tkeep_100;
    wire Ws_tlast_100;
    
    assign Ws_tready_100 = (SHA3_working)? Ws_tready : 1'b0;
    
    assign Rm_tready = (NTT_working)? Rm_tready_001 : (PWM_working)? Rm_tready_010 : (add_working)? Rm_tready_011: Rm_tready_100;
    assign Ws_tvalid = (NTT_working)? Ws_tvalid_001 : (PWM_working)? Ws_tvalid_010 : (add_working)? Ws_tvalid_011: Ws_tvalid_100;
    assign Ws_tdata  = (NTT_working)? Ws_tdata_001  : (PWM_working)? Ws_tdata_010  : (add_working)? Ws_tdata_011 : Ws_tdata_100;
    assign Ws_tkeep  = (NTT_working)? Ws_tkeep_001  : (PWM_working)? Ws_tkeep_010  : (add_working)? Ws_tkeep_011 : Ws_tkeep_100;
    assign Ws_tlast  = (NTT_working)? Ws_tlast_001  : (PWM_working)? Ws_tlast_010  : (add_working)? Ws_tlast_011 : Ws_tlast_100;
    
    wire coef_ena;
    wire coef_wea;
    wire [7:0]coef_addra;
    wire [22:0] coef_dina;
    wire [22:0] coef_douta;
    wire coef_enb;
    wire coef_web;
    wire [7:0]coef_addrb;
    wire [22:0] coef_dinb;
    wire [22:0]coef_doutb;
    
    wire temp_ena;
    wire temp_wea;
    wire [7:0] temp_addra;
    wire [22:0] temp_dina;
    wire [22:0] temp_douta;
    wire temp_enb;
    wire temp_web;
    wire [7:0] temp_addrb;
    wire [22:0] temp_dinb;
    wire  [22:0]temp_doutb;
    
    wire coef_ena_NTT;
    wire coef_wea_NTT;
    wire [7:0]coef_addra_NTT;
    wire [22:0] coef_dina_NTT;
    wire [22:0] coef_douta_NTT;
    wire coef_enb_NTT;
    wire coef_web_NTT;
    wire [7:0]coef_addrb_NTT;
    wire [22:0] coef_dinb_NTT;
    wire [22:0]coef_doutb_NTT;
    
    wire temp_ena_NTT;
    wire temp_wea_NTT;
    wire [7:0] temp_addra_NTT;
    wire [22:0] temp_dina_NTT;
    wire [22:0] temp_douta_NTT;
    wire temp_enb_NTT;
    wire temp_web_NTT;
    wire [7:0] temp_addrb_NTT;
    wire [22:0] temp_dinb_NTT;
    wire  [22:0]temp_doutb_NTT;
    
    wire coef_ena_add;
    wire coef_wea_add;
    wire [7:0]coef_addra_add;
    wire [22:0] coef_dina_add;
    wire [22:0] coef_douta_add;
    wire coef_enb_add;
    wire coef_web_add;
    wire [7:0]coef_addrb_add;
    wire [22:0] coef_dinb_add;
    wire [22:0]coef_doutb_add;
    
    wire temp_ena_add;
    wire temp_wea_add;
    wire [7:0] temp_addra_add;
    wire [22:0] temp_dina_add;
    wire [22:0] temp_douta_add;
    wire temp_enb_add;
    wire temp_web_add;
    wire [7:0] temp_addrb_add;
    wire [22:0] temp_dinb_add;
    wire  [22:0]temp_doutb_add;
    
    wire coef_ena_PWM;
    wire coef_wea_PWM;
    wire [7:0]coef_addra_PWM;
    wire [22:0] coef_dina_PWM;
    wire [22:0] coef_douta_PWM;
    wire coef_enb_PWM;
    wire coef_web_PWM;
    wire [7:0]coef_addrb_PWM;
    wire [22:0] coef_dinb_PWM;
    wire [22:0]coef_doutb_PWM;
    
    assign coef_ena   = (NTT_working)? coef_ena_NTT   : (PWM_working)? coef_ena_PWM : coef_ena_add;
    assign coef_wea   = (NTT_working)? coef_wea_NTT   : (PWM_working)? coef_wea_PWM : coef_wea_add;
    assign coef_addra = (NTT_working)? coef_addra_NTT : (PWM_working)? coef_addra_PWM : coef_addra_add;
    assign coef_dina  = (NTT_working)? coef_dina_NTT  : (PWM_working)? coef_dina_PWM : coef_dina_add;
    assign coef_douta_NTT = (NTT_working)? coef_douta :1'b0;
    assign coef_douta_add = (add_working)? coef_douta :1'b0;
    assign coef_douta_PWM = (PWM_working)? coef_douta :1'b0;
    
    assign coef_enb   = (NTT_working)? coef_enb_NTT   : (PWM_working)? coef_enb_PWM : coef_enb_add;
    assign coef_web   = (NTT_working)? coef_web_NTT   : (PWM_working)? coef_web_PWM : coef_web_add;
    assign coef_addrb = (NTT_working)? coef_addrb_NTT : (PWM_working)? coef_addrb_PWM : coef_addrb_add;
    assign coef_dinb  = (NTT_working)? coef_dinb_NTT  : (PWM_working)? coef_dinb_PWM : coef_dinb_add;
    assign coef_doutb_NTT = (NTT_working)? coef_doutb :1'b0;
    assign coef_doutb_add = (add_working)? coef_doutb :1'b0;
    assign coef_doutb_PWM = (PWM_working)? coef_doutb :1'b0;
    
    assign temp_ena   = (NTT_working)? temp_ena_NTT   : temp_ena_add;
    assign temp_wea   = (NTT_working)? temp_wea_NTT   : temp_wea_add;
    assign temp_addra = (NTT_working)? temp_addra_NTT : temp_addra_add;
    assign temp_dina  = (NTT_working)? temp_dina_NTT  : temp_dina_add;
    assign temp_douta_NTT = (NTT_working)? temp_douta :1'b0;
    assign temp_douta_add = (add_working)? temp_douta :1'b0;
    
    assign temp_enb   = (NTT_working)? temp_enb_NTT   : temp_enb_add;
    assign temp_web   = (NTT_working)? temp_web_NTT   : temp_web_add;
    assign temp_addrb = (NTT_working)? temp_addrb_NTT : temp_addrb_add;
    assign temp_dinb  = (NTT_working)? temp_dinb_NTT  : temp_dinb_add;
    assign temp_doutb_NTT = (NTT_working)? temp_doutb :1'b0;
    assign temp_doutb_add = (add_working)? temp_doutb :1'b0;
    
    wire[22:0] mul_result;
    wire[22:0] opt1;
    wire[22:0] opt2;
     
    wire[22:0] opt1_NTT;
    wire[22:0] opt2_NTT;
    
    wire[22:0] opt1_PWM;
    wire[22:0] opt2_PWM;
    
    assign opt1 = (NTT_working)? opt1_NTT : opt1_PWM;
    assign opt2 = (NTT_working)? opt2_NTT : opt2_PWM;
    
    always@(posedge clk)
    begin
        cur_state <= nex_state;
        
        if(start_module == 3'b001)
            NTT_start <= 1'b1;
        else
            NTT_start <= 1'b0;
        
        if(start_module == 3'b010)
            PWM_start <= 1'b1;
        else
            PWM_start <= 1'b0;
            
        if(start_module == 3'b011)
            add_start <= 1'b1;
        else
            add_start <= 1'b0;
        
        if(start_module == 3'b100)
            SHA3_start <= 1'b1;
        else
            SHA3_start <= 1'b0;
    end
    
    always@(*)  begin
        case(cur_state)
            3'b000:
                if(start_module == 3'b001)
                    nex_state <= 3'b001;
                else if(start_module == 3'b010)
                    nex_state <=  3'b010;
                else if(start_module == 3'b011)
                    nex_state <=  3'b011;
                else if(start_module == 3'b100)
                    nex_state <=  3'b100;
                else
                    nex_state <= 3'b000;
                    
            3'b001:
                if(NTT_done)
                    nex_state <= 3'b000;
                else
                    nex_state <= 3'b001;
            
            3'b010:
                if(PWM_done)
                    nex_state <= 3'b000;
                else
                    nex_state <= 3'b010;
            
            3'b011:
                if(add_done)
                    nex_state <= 3'b000;
                else
                    nex_state <= 3'b011;
            
            3'b100:
                if(SHA3_done)
                    nex_state <= 3'b000;
                else
                    nex_state <= 3'b100;
             default:
                    nex_state <= 3'b000;     
        endcase
    end
    
    AXI_Data_FIFO Read_FIFO(aresetn, clk, s_axis_tvalid, s_axis_tready, s_axis_tdata, s_axis_tkeep, s_axis_tlast, Rm_tvalid, Rm_tready, Rm_tdata, Rm_tkeep, Rm_tlast, read_FIFO_count);
    
    coefficient_mem  mem_1(clk, coef_ena, coef_wea, coef_addra, coef_dina, coef_douta, clk, coef_enb, coef_web, coef_addrb, coef_dinb, coef_doutb);
    coefficient_mem  mem_2(clk, temp_ena, temp_wea, temp_addra, temp_dina, temp_douta, clk, temp_enb, temp_web, temp_addrb, temp_dinb, temp_doutb);
    mul_and_reduce_pipe mul_module1(clk, opt1, opt2, mul_result);
    
    NTT_Ctrl NTT_Top(aresetn, clk, NTT_start, sel_NTT, Rm_tvalid_001, Rm_tready_001, Rm_tdata_001, Rm_tkeep_001, Rm_tlast_001, Ws_tvalid_001, Ws_tready_001, Ws_tdata_001, Ws_tkeep_001, Ws_tlast_001,
                     coef_ena_NTT, coef_wea_NTT, coef_addra_NTT, coef_dina_NTT, coef_douta_NTT, coef_enb_NTT, coef_web_NTT, coef_addrb_NTT, coef_dinb_NTT, coef_doutb_NTT, 
                     temp_ena_NTT, temp_wea_NTT, temp_addra_NTT, temp_dina_NTT, temp_douta_NTT, temp_enb_NTT, temp_web_NTT, temp_addrb_NTT, temp_dinb_NTT, temp_doutb_NTT, mul_result, opt1_NTT, opt2_NTT, NTT_done);
    
    PWM_Ctrl PWK_Top(aresetn, clk, PWM_start, column_length_PWM, Rm_tvalid_010, Rm_tready_010, Rm_tdata_010, Rm_tkeep_010, Rm_tlast_010, Ws_tvalid_010, Ws_tready_010, Ws_tdata_010, Ws_tkeep_010, Ws_tlast_010,
                     coef_ena_PWM, coef_wea_PWM, coef_addra_PWM, coef_dina_PWM, coef_douta_PWM, coef_enb_PWM, coef_web_PWM, coef_addrb_PWM, coef_dinb_PWM, coef_doutb_PWM, opt1_PWM, opt2_PWM, mul_result, PWM_done);
                     
    add_Ctrl add_TOP(aresetn, clk, add_start, add_sub_sel, vector_length, 
                  Rm_tvalid_011, Rm_tready_011, Rm_tdata_011, Rm_tkeep_011, Rm_tlast_011, Ws_tvalid_011, Ws_tready_011, Ws_tdata_011, Ws_tkeep_011, Ws_tlast_011,
                  coef_ena_add, coef_wea_add, coef_addra_add, coef_dina_add, coef_douta_add, coef_enb_add, coef_web_add, coef_addrb_add, coef_dinb_add, coef_doutb_add, 
                  temp_ena_add, temp_wea_add, temp_addra_add, temp_dina_add, temp_douta_add, temp_enb_add, temp_web_add, temp_addrb_add, temp_dinb_add, temp_doutb_add, add_done
                 );
                   
    SHA_Ctrl SHA_Top(aresetn, clk, SHA3_start, mode_SHA, sample_sel_SHA, eta_SHA, byte_read_SHA, byte_write_SHA,
                     Rm_tvalid_100, Rm_tready_100, Rm_tdata_100, Rm_tkeep_100, Rm_tlast_100, Ws_tvalid_100, Ws_tready_100, Ws_tdata_100, Ws_tkeep_100, Ws_tlast_100, SHA3_done );

    AXI_Data_FIFO Write_FIFO(aresetn, clk,  Ws_tvalid, Ws_tready, Ws_tdata, Ws_tkeep, Ws_tlast, m_axis_tvalid, m_axis_tready, m_axis_tdata, m_axis_tkeep, m_axis_tlast, write_FIFO_count);
    
endmodule
