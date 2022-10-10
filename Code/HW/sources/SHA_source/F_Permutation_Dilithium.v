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

/* if "ack" is 1, then current input has been used. */


module F_Permutation_Dilithium(clk, reset, in, in_ready, squeeze, mode, sha_hold, ack, out, out_ready);
    input               clk, reset;
    input      [1343:0] in;
    input               in_ready, squeeze; // when squeeze = 0, output once; otherwise, keep squeezing
    input      [1:0]    mode;
    input               sha_hold;
    output              ack;
    output reg [1599:0] out;
    output reg          out_ready;

    //here I check some output
    reg        [22:0]   i; /* select round constant */
    reg        [1:0]    sel; /* select permutation step */
    //reg        [1599:0] round_in_buf_0, round_in_buf_1;
    wire       [1599:0] round_in, round_out_A, round_out_B;
    wire       [63:0]   rc; /* round constant */
    wire                update;
    wire                accept;
    //reg                 accept_buf;
    reg                 calc; /* == 1: calculating rounds */
    reg        [1:0]    i_sti_buf; 

    parameter   XOF   = 2'b00,
                KDF   = 2'b01,
                PRF   = 2'b01,
                H     = 2'b10,
                G     = 2'b11; 

    assign accept = in_ready & (~ calc); // in_ready & (i == 0)
    
    always @ (posedge clk)
      if (reset) sel <= 0;
      //else if ((i[22] & sel[1])) sel <= 0;
      //else sel <= {sel[0], (sel[1] | accept | (out_ready & squeeze)) };
      else if ((accept & out_ready)|sha_hold) sel <= sel;
      else sel <= {sel[0], (sel[1] | accept) };
    
    always @ (posedge clk)
      if (reset) i <= 0;
      //else if (accept | sel[1] | i_sti_buf) i <= {i[21:0], accept | i_sti_buf};
      else if(sha_hold) i <= i;
      else if (sel[1]) i <= {i[21:0], i_sti_buf[1]};
      else  i <= i;
    
    always @ (posedge clk)
      if (reset) calc <= 0;
      else       calc <= (calc & (~ (i[22] & sel[1])) ) | accept | (squeeze);
    
    always @ (posedge clk)
      if (reset) i_sti_buf <= 0;
      else  begin
        i_sti_buf[1] <= i_sti_buf[0] | out_ready;
        i_sti_buf[0] <= accept;
      end
    
    assign update = calc | accept;

    assign ack = accept;

    always @ (posedge clk)
      if (reset)
        out_ready <= 0;
      else if (i == 0) 
        out_ready <= 0;
      else if (i[22] & sel[1]) // only change at the last round
        out_ready <= 1;

//    assign round_in = accept ? ((mode == XOF)? {in[1343:0] ^ out[1599:1599-1343], out[1599-1344:0]}:
//                               (mode == KDF)? {in[1087:0] ^ out[1599:1599-1087], out[1599-1088:0]}:
//                               (mode == PRF)? {in[1087:0] ^ out[1599:1599-1087], out[1599-1088:0]}:
//                               (mode == H)? {in[1087:0] ^ out[1599:1599-1087], out[1599-1088:0]}:
//                               /*(mode == G)?*/ {in[575:0] ^ out[1599:1599-575], out[1599-576:0]} ) : out; // need update

    rconst
      rconst_ ({i, i_sti_buf[1] }, rc);

    round_A
      roundA_ (out, round_out_A);
      
    round_B
      roundB_ (out, rc, round_out_B);

    always @ (posedge clk)
      if (reset)
        out <= 0;
      else if (accept)
        out <= (mode == XOF)? {in[1343:0] ^ out[1599:1599-1343], out[1599-1344:0]}:
               (mode == KDF)? {in[1087:0] ^ out[1599:1599-1087], out[1599-1088:0]}:
               (mode == PRF)? {in[1087:0] ^ out[1599:1599-1087], out[1599-1088:0]}:
               (mode == H)? {in[1087:0] ^ out[1599:1599-1087], out[1599-1088:0]}:
               /*(mode == G)?*/ {in[575:0] ^ out[1599:1599-575], out[1599-576:0]};
               
      else if (update)
        out <= sha_hold? out        :
               sel[0] ? round_out_A : 
               sel[1] ? round_out_B :
               out;
        
//    initial 
//        begin
//            $monitor("\tout_Kyber = %h",out);
//        end
endmodule