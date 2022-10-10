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
            randombytes(m, MLEN);
        	//for(int k = 0; k<MLEN;k++) m[k]=k;
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
