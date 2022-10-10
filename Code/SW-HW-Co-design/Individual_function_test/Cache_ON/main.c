/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"

#include<stdio.h>
#include"config.h"
#include"params.h"
#include"api.h"
#include"sign.h"
#include"packing.h"
#include"polyvec.h"
#include"poly.h"
#include"ntt.h"
#include"reduce.h"
#include"rounding.h"
#include"symmetric.h"
#include "random.h"
#include"fips202.h"
#include "HW_ACC.h"
#include "scutimer.h"


#if (OS_TARGET == OS_LINUX)
  #include <sys/types.h>
  #include <sys/stat.h>
  #include <fcntl.h>
  #include <unistd.h>
#endif

#define MLEN 256
#define NRUNS 1000
#define NTESTS 10000

static int cmp_llu(const void *a, const void*b)
{
  if (*(unsigned long *)a < *(unsigned long *)b) return -1;
  if (*(unsigned long *)a > *(unsigned long *)b) return 1;
  return 0;
}


static unsigned long median(unsigned long *l, size_t llen)
{
  qsort(l,llen,sizeof(unsigned long),cmp_llu);

  if (llen%2) return l[llen/2];
  else return (l[llen/2-1]+l[llen/2])/2;
}


static unsigned long average(unsigned long *t, size_t tlen)
{
  unsigned long long acc=0;
  size_t i;
  for (i=0; i<tlen; i++)
    acc += t[i];
  return acc/(tlen);
}


static void print_results(const char *s, unsigned long *t, size_t tlen)
{
  printf("%s", s);
  printf("\n");
  printf("median:  %lu ", median(t, tlen));  printf("cycles");  printf("\n");
  printf("average: %lu ", average(t, tlen-1));  printf("cycles"); printf("\n");
  printf("\n");
}


int main()
{
    init_platform();
    transmission_initialization();
    printf("hello world!\n");
    unsigned char       m[MLEN], sm[200+CRYPTO_BYTES], m1[MLEN];
        unsigned char       pk[CRYPTO_PUBLICKEYBYTES], sk[CRYPTO_SECRETKEYBYTES];
        unsigned long  smlen, mlen1;
        int                 ret_val;

        unsigned int i, j;
        unsigned long cycles0_1[NRUNS], cycles0_2[NRUNS], cycles1_1[NRUNS], cycles1_2[NRUNS], cycles2_1[NRUNS], cycles2_2[NRUNS];
        unsigned long cycles3_1[NRUNS], cycles3_2[NRUNS], cycles4_1[NRUNS], cycles4_2[NRUNS], cycles5_1[NRUNS], cycles5_2[NRUNS];
        unsigned long cycles6_1[NRUNS], cycles6_2[NRUNS], cycles7_1[NRUNS], cycles7_2[NRUNS], cycles8_1[NRUNS], cycles8_2[NRUNS];
        unsigned long cycles9_1[NRUNS], cycles9_2[NRUNS], cycles10_1[NRUNS], cycles10_2[NRUNS],
		              cycles11_1[NRUNS], cycles11_2[NRUNS], cycles12_1[NRUNS], cycles12_2[NRUNS];
        for (i = 0; i < NRUNS; i++)
        {

            //poly_ntt
        	poly ntt_num;
        	scutimer_start();
        	poly_ntt(ntt_num.coeffs);
            cycles0_1[i] = scutimer_result();
            scutimer_start();
            NTT_Hardware(ntt_num.coeffs);
            cycles0_2[i] = scutimer_result();

            //poly_invntt
            scutimer_start();
            poly_invntt_tomont(ntt_num.coeffs);
			cycles1_1[i] = scutimer_result();
			scutimer_start();
			INTT_Hardware(ntt_num.coeffs);
			cycles1_2[i] = scutimer_result();

			//poly_mul
			poly a,b,c;
			scutimer_start();
			poly_pointwise_montgomery(&c, &a, &b);
			poly_reduce(&c);
			cycles2_1[i] = scutimer_result();
			scutimer_start();
			poly_pointwise_Hardwarey(&c, &a, &b);
			cycles2_2[i] = scutimer_result();

			//poly_mul_k=6
			polyveck r1, r2;
			scutimer_start();
			polyveck_pointwise_poly_montgomery(&r2, &a, &r1);
			polyveck_reduce(&r2);
			cycles3_1[i] = scutimer_result();
			scutimer_start();
			polyveck_pointwise_Hardware(&r2, &a, &r1);
			cycles3_2[i] = scutimer_result();

			//poly_add
			scutimer_start();
			poly_add(&c, &a, &b);
			poly_caddq(&c);
			cycles4_1[i] = scutimer_result();
			scutimer_start();
			poly_add_Hardware(&c, &a, &b);
			cycles4_2[i] = scutimer_result();

			//poly_add_l=5
			polyvecl v;
			scutimer_start();
			polyvecl_pointwise_add(&c, &v);
			poly_reduce(&c);
			cycles5_1[i] = scutimer_result();
			scutimer_start();
			polyvecl_pointwise_add_Hardware(&c, &v);
			cycles5_2[i] = scutimer_result();

			//poly_sub
			scutimer_start();
			poly_sub(&c, &a, &b);
			poly_caddq(&c);
			cycles6_1[i] = scutimer_result();
			scutimer_start();
			poly_sub_Hardware(&c, &a, &b);
			cycles6_2[i] = scutimer_result();

			//matrix_mul
			polyvecl mat[K];polyveck mat_temp[L];
			polyvecl s1hat;
			polyveck t1;
			scutimer_start();
			polyvec_matrix_pointwise_montgomery(&t1, mat, &s1hat);
			cycles7_1[i] = scutimer_result();
			scutimer_start();
			polyvec_matrix_PWM_Hardware_new(mat_temp, &s1hat);
			polyvec_matrix_add_Hardware(&t1, mat_temp);
			cycles7_2[i] = scutimer_result();

			//poly_uniform
			uint8_t seed[SEEDBYTES];
			uint16_t nonce;
			scutimer_start();
			poly_uniform(&a, seed, nonce);
			cycles8_1[i] = scutimer_result();
			scutimer_start();
			poly_uniform_Hardware(&a, seed, nonce);
			cycles8_2[i] = scutimer_result();

			//poly_eta_4
			scutimer_start();
			poly_uniform_eta(&a, seed, nonce);
			cycles9_1[i] = scutimer_result();
			scutimer_start();
			poly_uniform_eta_Hardware(&a, seed, nonce);
			cycles9_2[i] = scutimer_result();

			//poly_eta_2
			scutimer_start();
			poly_uniform_eta_2(&a, seed, nonce);
			cycles10_1[i] = scutimer_result();
			scutimer_start();
			poly_uniform_eta2_Hardware(&a, seed, nonce);
			cycles10_2[i] = scutimer_result();

			//shake256
			uint8_t seedbuf[3*SEEDBYTES];
			scutimer_start();
			shake256(seedbuf, 3*SEEDBYTES, seedbuf, SEEDBYTES);
			cycles11_1[i] = scutimer_result();
			scutimer_start();
			shake256_Hardware(seedbuf, 3*SEEDBYTES, seedbuf, SEEDBYTES);
			cycles11_2[i] = scutimer_result();

			//CRH
			uint8_t tr[CRHBYTES];
			unsigned char       pk[CRYPTO_PUBLICKEYBYTES];
			scutimer_start();
			crh(tr, pk, CRYPTO_PUBLICKEYBYTES);
			cycles12_1[i] = scutimer_result();
			scutimer_start();
			shake256_Hardware(tr, CRHBYTES, pk, CRYPTO_PUBLICKEYBYTES);
			cycles12_2[i] = scutimer_result();

        }

        printf("Signature tests PASSED... \n\n");
        print_results("poly_ntt SW: ", cycles0_1, NRUNS);
        print_results("poly_ntt HW: ", cycles0_2, NRUNS);
        print_results("poly_invntt SW: ", cycles1_1, NRUNS);
        print_results("poly_invntt HW: ", cycles1_2, NRUNS);
        print_results("poly_mul SW: ", cycles2_1, NRUNS);
		print_results("poly_mul HW: ", cycles2_2, NRUNS);
		print_results("poly_mul(k=6) SW: ", cycles3_1, NRUNS);
		print_results("poly_mul(k=6) HW: ", cycles3_2, NRUNS);
		print_results("poly_add SW: ", cycles4_1, NRUNS);
		print_results("poly_add HW: ", cycles4_2, NRUNS);
		print_results("poly_add(l=5) SW: ", cycles5_1, NRUNS);
		print_results("poly_add(l=5) HW: ", cycles5_2, NRUNS);

		print_results("poly_sub SW: ", cycles6_1, NRUNS);
		print_results("poly_sub HW: ", cycles6_2, NRUNS);
		print_results("matrix_mu SW: ", cycles7_1, NRUNS);
		print_results("matrix_mu HW: ", cycles7_2, NRUNS);
		print_results("poly_uniform SW: ", cycles8_1, NRUNS);
		print_results("poly_uniform HW: ", cycles8_2, NRUNS);
		print_results("poly_eta4 SW: ", cycles9_1, NRUNS);
		print_results("poly_eta4 HW: ", cycles9_2, NRUNS);
		print_results("poly_eta2 SW: ", cycles10_1, NRUNS);
	    print_results("poly_eta2 HW: ", cycles10_2, NRUNS);
	    print_results("SHAKE256 SW: ", cycles11_1, NRUNS);
	    print_results("SHAKE256 HW: ", cycles11_2, NRUNS);
		print_results("CRH SW: ", cycles12_1, NRUNS);
		print_results("CRH HW: ", cycles12_2, NRUNS);


    cleanup_platform();
    return 0;
}
