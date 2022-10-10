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

/* "is_last" == 0 means byte number is 4, no matter what value "byte_num" is. */
/* if "in_ready" == 0, then "is_last" should be 0. */
/* the user switch to next "in" only if "ack" == 1. */

module Padder_Dilithium(clk, reset, in, in_ready, is_last, mode, byte_num, buffer_full, i_last, out, out_ready, f_ack);
    input              clk, reset;
    input      [63:0]  in;
    input              in_ready, is_last;
    input      [1:0]   mode;
    input      [2:0]   byte_num;
    output             buffer_full; /* to "user" module */
    output i_last;
    output reg [1343:0] out;         /* to "f_permutation" module */ // need update
    output             out_ready;   /* to "f_permutation" module */
    input              f_ack;       /* from "f_permutation" module */
                                    /* if "ack" is 1, then current output has been used by "f_permutation" module */
    
    reg                state;       /* state == 0: user will send more input data
                                     * state == 1: user will not send any data */
    reg                done;        /* == 1: out_ready should be 0 */
    reg        [20:0]  i;           /* length of "out" buffer */ // 576/32 = 18, therefore i[17:0] (one-hot encoding)
    wire       [63:0]  v0;          /* output of module "padder1" */
    reg        [63:0]  v1;          /* to be shifted into register "out" */
    
    wire               accept,      /* accept user input? */
                       update;
                       
    parameter   XOF   = 2'b00,
                KDF   = 2'b01,
                PRF   = 2'b01,
                H     = 2'b10,
                G     = 2'b11; 
    
    assign buffer_full = (mode == XOF)? i[20]:
                         (mode == KDF)? i[16]:
                         (mode == PRF)? i[16]:
                         (mode == H)  ? i[16]: /*(mode == G)?*/ i[8]; // need update
    
    assign out_ready = buffer_full;
    assign i_last = (mode == XOF)? i[19]:
                    (mode == KDF)? i[15]:
                    (mode == PRF)? i[15]:
                    (mode == H)  ? i[15]: /*(mode == G)?*/ i[7];
    assign accept = (~ state) & in_ready & (~ buffer_full); // if state == 1, do not eat input
    assign update = (accept | (state & (~ buffer_full))) & (~ done); // don't fill buffer if done

    always @ (posedge clk)
      if (reset)
        out <= 0;
      else if (update)
        out <= {out[1343-64:0], v1}; // need update

    always @ (posedge clk)
      if (reset)
        i <= 0;
      else if (f_ack | update)
        i <= {i[19:0], 1'b1} & {21{~ f_ack}}; // need update
/*    if (f_ack)  i <= 0; */
/*    if (update) i <= {i[16:0], 1'b1}; // increase length, when sha3-512: 576/32 = 18 */

    always @ (posedge clk)
      if (reset)
        state <= 0;
      else if (is_last)
        state <= 1;
      else
        state <= state;

    always @ (posedge clk)
      if (reset)
        done <= 0;
      else if (state & out_ready)
        done <= 1;
      else
        done <= done;

    padder1 p0 (in, byte_num, mode, v0);
    
    always @ (*)
      begin
        if (state) // @ (posedge clk) is_last == 1
          begin
            v1 = 0;
            v1[7] = v1[7] | i_last; // need update
            //v1[7] = v1[7] | i[16]; // "v1[7]" is the MSB of the last byte of "v1"
          end
        else if (is_last == 0)
          v1 = in;
        else // is_last == 1, but not meet with (posedge clk)
          begin
            v1 = v0;
            v1[7] = v1[7] | i_last; // need update
            //v1[7] = v1[7] | i[16];
          end
      end
endmodule
