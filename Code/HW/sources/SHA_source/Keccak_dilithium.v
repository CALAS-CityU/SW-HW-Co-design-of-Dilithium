/*
 * Copyright 2013, Homer Hsing <homer.hsing@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/* "is_last" == 0 means byte number is 8, no matter what value "byte_num" is. */
/* if "in_ready" == 0, then "is_last" should be 0. */
/* the user switch to next "in" only if "ack" == 1. */

`define low_pos(w,b)      ((w)*64 + (b)*8)
`define low_pos2(w,b)     `low_pos(w,7-b)
`define high_pos(w,b)     (`low_pos(w,b) + 7)
`define high_pos2(w,b)    (`low_pos2(w,b) + 7)

module Keccak_Dilithium(clk, reset, in, in_ready, is_last, squeeze, mode, sha_hold, byte_num, buffer_full, buffer_last, out, out_ready);
                        
    input              clk, reset;
    input      [63:0]  in;
    input              in_ready, is_last, squeeze; // when squeeze = 0, output once; otherwise, keep squeezing
    input      [1:0]   mode;
    input              sha_hold;
    input      [2:0]   byte_num;
    output             buffer_full; /* to "user" module */
    output             buffer_last;
    output     [1343:0] out;
    output          out_ready;
    
    
    reg                state;     /* state == 0: user will send more input data
                                   * state == 1: user will not send any data */
    reg                in_squeeze;
    wire       [1343:0] padder_out,
                       padder_out_1; /* before reorder byte */
    wire               padder_out_ready;
    wire               f_ack;
    wire      [1599:0] f_out;
    wire               f_out_ready;
    wire       [1343:0] out1;      /* before reorder byte */ // need update
    reg        [22:0]  i;         /* gen "out_ready" */ // need update
    wire i_last;
    reg [1:0]   mode_buf;
    
    parameter   XOF   = 2'b00,
                KDF   = 2'b01,
                PRF   = 2'b01,
                H     = 2'b10,
                G     = 2'b11; 

    genvar w, b;

    assign buffer_last = i_last & ( ~ buffer_full ) & in_ready;
    assign out1 = (mode == XOF)? f_out[1599:1599-1343]: {256'b0, f_out[1599:1599-1087]};

//    always @ (posedge clk)
//      if (reset)
//        i <= 0;
//      else
//        i <= {i[21:0], state & f_ack};// need update

    always @ (posedge clk)
    begin
    
      mode_buf <= in_ready? mode : mode_buf;
    
      if (reset)
        in_squeeze <= 0;
      else if (mode[1])
        in_squeeze <= 0; // SHA3-256 & SHA3-512, disable the squeeze selection
      else if (squeeze & f_ack)
        in_squeeze <= 1;
      else if (~squeeze)
        in_squeeze <= 0;
    end
    always @ (posedge clk)
      if (reset)
        state <= 0;
      else if (is_last)
        state <= 1;

    /* reorder byte ~ ~ */
    generate
      for(w=0; w<21; w=w+1)
        begin : L0
          for(b=0; b<8; b=b+1)
            begin : L1
              assign out[`high_pos(w,b):`low_pos(w,b)] = out1[`high_pos2(w,b):`low_pos2(w,b)];
            end
        end
    endgenerate

    /* reorder byte ~ ~ */
    generate
      for(w=0; w<21; w=w+1)
        begin : L2
          for(b=0; b<8; b=b+1)
            begin : L3
              assign padder_out[`high_pos(w,b):`low_pos(w,b)] = padder_out_1[`high_pos2(w,b):`low_pos2(w,b)];
            end
        end
    endgenerate

//    always @ (posedge clk)
//      if (reset)
//        out_ready <= 0;
//      else if (i[22])
//        out_ready <= 1;

//    always @ (posedge clk)
//        out_ready <= f_out_ready;

    assign out_ready = ( ~ buffer_full ) & f_out_ready;

    Padder_Dilithium
      padder_ (clk, reset, in, in_ready, is_last, mode_buf, byte_num, buffer_full, i_last, padder_out_1, padder_out_ready, f_ack);

    F_Permutation_Dilithium
      f_permutation_ (clk, reset, padder_out, padder_out_ready, in_squeeze, mode_buf, sha_hold, f_ack, f_out, f_out_ready);
                      
endmodule

`undef low_pos
`undef low_pos2
`undef high_pos
`undef high_pos2
