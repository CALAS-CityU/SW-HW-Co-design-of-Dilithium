`timescale 1ns / 1ps

module SHA_Ctrl
(
    input wire aresetn,
    input wire clk,
    
    input wire SHA3_start,
    input wire [1:0] mode,
    input wire sample_sel,//0->Uni, 1->Rej
    input wire eta,//0->2, 1->4
    input wire[31:0] byte_read,
    input wire[9:0] byte_write,
    
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
    
    output wire SHA3_done

    );
    
    wire [63:0] in;
    wire in_ready;
    wire is_last;
    wire squeeze; 
    wire sha_hold;
    wire [2:0] byte_num;
    wire buffer_full; 
    wire [1343:0] out;
    wire out_ready;
    wire i_last;
    
    SHAKE_FIFO_read shake_read(clk, SHA3_start, mode, byte_read, Rm_tvalid, Rm_tready, Rm_tdata, Rm_tkeep, Rm_tlast, 
                              buffer_full, i_last, in, in_ready, is_last, byte_num);
    Keccak_Dilithium shake(clk, SHA3_start, in, in_ready, is_last, squeeze, mode, sha_hold, byte_num, buffer_full, i_last, out, out_ready);
    SHAKE_FIFO_write shake_write(clk, SHA3_start, Ws_tvalid, Ws_tready, Ws_tdata, Ws_tkeep, Ws_tlast,
                                 mode, sample_sel, eta, byte_write, is_last, buffer_full, out, out_ready, sha_hold, squeeze, SHA3_done);
                                 
endmodule