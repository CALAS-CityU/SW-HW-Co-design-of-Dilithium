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
    printf("hello world!\n");
    unsigned char       m[MLEN], sm[200+CRYPTO_BYTES], m1[MLEN];
        unsigned char       pk[CRYPTO_PUBLICKEYBYTES], sk[CRYPTO_SECRETKEYBYTES];
        unsigned long  smlen, mlen1;
        int                 ret_val;

        unsigned int i, j;
        unsigned long cycles0[NRUNS], cycles1[NRUNS], cycles2[NRUNS];

        for (i = 0; i < NRUNS; i++)
        {
            //randombytes(m, MLEN);
        	for(int k = 0; k<MLEN;k++) m[k]=k;
            scutimer_start();
            if ( ret_val = crypto_sign_keypair(pk, sk) != 0) { return 1;}
            cycles0[i] = scutimer_result();

            scutimer_start();
            if ( (ret_val = crypto_sign(sm, &smlen, m, MLEN, sk)) != 0) {printf("crypto_sign returned <%d>\n", ret_val);}
            cycles1[i] = scutimer_result();
            //for(int k = 0; k<200+CRYPTO_BYTES;k++) printf("%d,",sm[k]);

            scutimer_start();
            if ( (ret_val = crypto_sign_open(m1, &mlen1, sm, smlen, pk)) != 0) {printf("crypto_sign_open returned <%d>\n", ret_val);}
            cycles2[i] = scutimer_result();

            if ( MLEN != mlen1 ) { printf("length fail"); return 0;}
            if ( memcmp(m, m1, MLEN)){printf("message fail\n");return 0;}
        }

        printf("Signature tests PASSED... \n\n");
        print_results("dilithium keygen: ", cycles0, NRUNS);
        print_results("dilithium sign: ", cycles1, NRUNS);
        print_results("dilithium verify: ", cycles2, NRUNS);



    cleanup_platform();
    return 0;
}
