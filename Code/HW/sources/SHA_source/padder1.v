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

/*
 *     in      byte_num     out
 * 0x11223344      0    0x01000000
 * 0x11223344      1    0x11010000
 * 0x11223344      2    0x11220100
 * 0x11223344      3    0x11223301
 */

module padder1(in, byte_num, mode, out);
    input      [63:0] in;
    input      [1:0]   mode;
    input      [2:0]  byte_num;
    output reg [63:0] out;
    
    parameter   XOF   = 2'b00,
                KDF   = 2'b01,
                PRF   = 2'b01,
                H     = 2'b10,
                G     = 2'b11;  
    
    always @ (*)
    /*
      case (byte_num)
        0: out = 32'h0100_0000;
        1: out = {in[31:24], 24'h01_0000};
        2: out = {in[31:16], 16'h0100};
        3: out = {in[31:8],   8'h01};
      endcase*/
      case ({mode[1], byte_num}) 
        //SHAKE-128, SHAKE-256
        4'b0_000: out = 64'h1f00000000000000;
        4'b0_001: out = {in[63:56],56'h1f000000000000};
        4'b0_010: out = {in[63:48],48'h1f0000000000};
        4'b0_011: out = {in[63:40],40'h1f00000000};
        4'b0_100: out = {in[63:32],32'h1f000000};
        4'b0_101: out = {in[63:24],24'h1f0000};
        4'b0_110: out = {in[63:16],16'h1f00};
        4'b0_111: out = {in[63:8],8'h1f};
		
        //SHA3-256, SHA3-512
        4'b1_000: out = 64'h0600000000000000;
        4'b1_001: out = {in[63:56],56'h06000000000000};
        4'b1_010: out = {in[63:48],48'h060000000000};
        4'b1_011: out = {in[63:40],40'h0600000000};
        4'b1_100: out = {in[63:32],32'h06000000};
        4'b1_101: out = {in[63:24],24'h060000};
        4'b1_110: out = {in[63:16],16'h0600};
        4'b1_111: out = {in[63:8],8'h06};
        
	  endcase
endmodule
