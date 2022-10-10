`timescale 1ns / 1ps

module HW_ACC_IP#
(
    localparam C_S00_AXI_DATA_WIDTH	= 32,
    localparam C_S00_AXI_ADDR_WIDTH    = 5
)
(
    // Ports of Axi Slave Bus Interface S00_AXI
    input wire  s00_axi_aclk,
    input wire  s00_axi_aresetn,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input wire [2 : 0] s00_axi_awprot,
    input wire  s00_axi_awvalid,
    output wire  s00_axi_awready,
    input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input wire  s00_axi_wvalid,
    output wire  s00_axi_wready,
    output wire [1 : 0] s00_axi_bresp,
    output wire  s00_axi_bvalid,
    input wire  s00_axi_bready,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input wire [2 : 0] s00_axi_arprot,
    input wire  s00_axi_arvalid,
    output wire  s00_axi_arready,
    output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [1 : 0] s00_axi_rresp,
    output wire  s00_axi_rvalid,
    input wire  s00_axi_rready,
    
    input wire aresetn,
    input wire clk,
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
    output wire m_axis_tlast
    );
    wire[2:0] start_module;
    wire sel_NTT;
    wire[3:0] column_length_PWM;
    wire add_sub_sel;
    wire[3:0] vector_length;
    wire [1:0] mode_SHA;
    wire sample_sel_SHA;//0->Uni, 1->Rej
    wire eta_SHA;//0->2, 1->4
    wire[31:0] byte_read_SHA;
    wire[9:0] byte_write_SHA;
    wire [31 : 0] read_FIFO_count;
    wire [31 : 0] write_FIFO_count;
    
    Top_HW_ACC_Ctrl HW_module( aresetn, clk, start_module, sel_NTT, column_length_PWM, add_sub_sel, vector_length, mode_SHA, sample_sel_SHA, eta_SHA, byte_read_SHA, byte_write_SHA,
                           s_axis_tvalid, s_axis_tready, s_axis_tdata, s_axis_tkeep, s_axis_tlast, m_axis_tvalid, m_axis_tready,  m_axis_tdata, m_axis_tkeep, m_axis_tlast,
                           read_FIFO_count, write_FIFO_count
                            );
                            
    Control_Reg  Ctrl_module( start_module, sel_NTT, column_length_PWM, add_sub_sel, vector_length, mode_SHA, sample_sel_SHA, eta_SHA, byte_read_SHA, byte_write_SHA, read_FIFO_count, write_FIFO_count,
                              s00_axi_aclk, s00_axi_aresetn, s00_axi_awaddr, s00_axi_awprot, s00_axi_awvalid, s00_axi_awready, s00_axi_wdata, s00_axi_wstrb, s00_axi_wvalid, 
                              s00_axi_wready, s00_axi_bresp, s00_axi_bvalid, s00_axi_bready, s00_axi_araddr, s00_axi_arprot, s00_axi_arvalid, s00_axi_arready, s00_axi_rdata,
                              s00_axi_rresp, s00_axi_rvalid, s00_axi_rready
                             );
    
endmodule
