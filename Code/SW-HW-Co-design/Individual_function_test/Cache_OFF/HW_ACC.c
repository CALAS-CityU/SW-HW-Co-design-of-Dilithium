#include <stdint.h>
#include "platform.h"
/*add include files here*/
#include "xaxidma.h"//DMA
#include "xparameters.h"//address
#include "xil_exception.h"//exception related APIs
#include "xscugic.h"//interrupt controller
#include "HW_ACC.h"
#include"params.h"
#include "polyvec.h"
#include "poly.h"

void transmission_initialization()
{
	int status;
	XAxiDma_Config *config;

	config = XAxiDma_LookupConfig(DMA_DEV_ID);
	if (!config){
		xil_printf("No config found for %d\r\n", DMA_DEV_ID);
		return XST_FAILURE;
	}

	status = XAxiDma_CfgInitialize(&axidma, config);
	if (status != XST_SUCCESS) {
		xil_printf("Initialization failed %d\r\n", status);
		return XST_FAILURE; }

	if (XAxiDma_HasSg(&axidma)) {
		xil_printf("Device configured as SG mode \r\n");
		return XST_FAILURE;
	}

	/* Disable interrupts, we use polling mode*/
	XAxiDma_IntrDisable(&axidma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);
	XAxiDma_IntrDisable(&axidma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);
}

void NTT_Hardware(int32_t a[N])
{
    int status;
	My_DMA_Ctrl_1 = 0;
	My_DMA_Ctrl_0 = 1;
	//Xil_DCacheFlushRange((UINTPTR)a, 256*4);
	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) a, (256*4), XAXIDMA_DMA_TO_DEVICE);
	if (status != XST_SUCCESS) { printf("NTT Read ERROR\n");return XST_FAILURE; }
	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) a, (256*4), XAXIDMA_DEVICE_TO_DMA);
	if (status != XST_SUCCESS) { printf("NTT Write ERROR\n");return XST_FAILURE; }
	while ((XAxiDma_Busy(&axidma,XAXIDMA_DEVICE_TO_DMA)) || (XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE)))
	      {/*wait*/    }
}

void INTT_Hardware(int32_t a[N])
{
	int status;
	My_DMA_Ctrl_1 = 1;
	My_DMA_Ctrl_0 = 1;
	//Xil_DCacheFlushRange((UINTPTR)a, 256*4);
	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) a, (256*4), XAXIDMA_DMA_TO_DEVICE);
	if (status != XST_SUCCESS) { printf("INTT Read ERROR\n");return XST_FAILURE; }
	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) a, (256*4), XAXIDMA_DEVICE_TO_DMA);
	if (status != XST_SUCCESS) { printf("INTT Write ERROR\n");return XST_FAILURE; }
	while ((XAxiDma_Busy(&axidma,XAXIDMA_DEVICE_TO_DMA)) || (XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE))) {/* Wait */}
}

void poly_pointwise_Hardwarey(poly *c, const poly *a, const poly *b)
{
	int status;
	My_DMA_Ctrl_0 = 2;
	My_DMA_Ctrl_1 = 1<<1;
	//Xil_DCacheFlushRange((UINTPTR)a, 256*4);
	//Xil_DCacheFlushRange((UINTPTR)b, 256*4);
	//Xil_DCacheFlushRange((UINTPTR)c, 256*4);
	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) c, (256*4), XAXIDMA_DEVICE_TO_DMA);
	if (status != XST_SUCCESS) { printf("point_wise Write ERROR\n");return XST_FAILURE; }

	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) a, (256*4), XAXIDMA_DMA_TO_DEVICE);
	if (status != XST_SUCCESS) { printf("point_wise1 Read ERROR\n");return XST_FAILURE; }
	while ((XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE))) {}

	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) b, (256*4), XAXIDMA_DMA_TO_DEVICE);
	if (status != XST_SUCCESS) { printf("point_wise2 Read ERROR\n");return XST_FAILURE; }

	while ((XAxiDma_Busy(&axidma,XAXIDMA_DEVICE_TO_DMA)) || (XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE))) {/* Wait */}
}

void polyvec_matrix_PWM_Hardware(polyveck mat_temp[L], const polyvecl mat[K], const polyvecl *v)
{
	int status;
	for(int k = 0; k < L; ++k)
	{
		My_DMA_Ctrl_0 = 2;
		My_DMA_Ctrl_1 = K<<1;//6 =  K; need to configure for different parameters

		//Xil_DCacheFlushRange((UINTPTR)&mat_temp[k].vec[0], K*256*4);
		status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) &mat_temp[k].vec[0], (K*256*4), XAXIDMA_DEVICE_TO_DMA);
		if (status != XST_SUCCESS) { printf("polyvec_matrix_PWM Write ERROR\n"); return XST_FAILURE; }

		//Xil_DCacheFlushRange((UINTPTR)&v->vec[k], 256*4);
		status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) &v->vec[k], (256*4), XAXIDMA_DMA_TO_DEVICE);
		if (status != XST_SUCCESS) { printf("%d,polyvec_matrix_PWM Read1 ERROR\n",k);return XST_FAILURE; }
		while ((XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE))) {}
		for(int i = 0; i < K; ++i )
		{
			//Xil_DCacheFlushRange((UINTPTR)&mat[i].vec[k], 256*4);
			status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) &mat[i].vec[k], (256*4), XAXIDMA_DMA_TO_DEVICE);
			if (status != XST_SUCCESS) { printf("%d,polyvec_matrix_PWM Read1 ERROR\n",k);return XST_FAILURE; }
			while ((XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE))) {}
		}
		while ((XAxiDma_Busy(&axidma,XAXIDMA_DEVICE_TO_DMA)) ) {}
	}
}

void polyvec_matrix_add_Hardware(polyveck *t, const polyveck mat_temp[L])
{
	int status;
	for(int k = 0; k < K; ++k)
	{
		My_DMA_Ctrl_0 = 3;
		My_DMA_Ctrl_1 = ( (0<<5) + ((L-1)<<6) );//6 =  K; need to configure for different parameters
		//Xil_DCacheFlushRange((UINTPTR)&t->vec[k], 256*4);
		status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) &t->vec[k], (256*4), XAXIDMA_DEVICE_TO_DMA);
		if (status != XST_SUCCESS) { printf("polyvec_matrix_PWM Write ERROR\n"); return XST_FAILURE; }
		for(int i = 0; i < L; ++i )
		{
			//Xil_DCacheFlushRange((UINTPTR)&mat_temp[i].vec[k], 256*4);
			status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) &mat_temp[i].vec[k], (256*4), XAXIDMA_DMA_TO_DEVICE);
			if (status != XST_SUCCESS) { printf("%d,polyvec_matrix_add Read ERROR\n",k);return XST_FAILURE; }
			while ((XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE))) {}
		}


		while ((XAxiDma_Busy(&axidma,XAXIDMA_DEVICE_TO_DMA)) ) {}
	}
}

void polyvecl_pointwise_add_Hardware(poly *w, const polyvecl *v)
{
	int status;
	My_DMA_Ctrl_0 = 3;
	My_DMA_Ctrl_1 = ( (0<<5) + ((L-1)<<6) );//6 =  K; need to configure for different parameters
	//Xil_DCacheFlushRange((UINTPTR)&w, 256*4);
	//Xil_DCacheFlushRange((UINTPTR)&v, 256*4*5);
	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) w, (256*4), XAXIDMA_DEVICE_TO_DMA);
	if (status != XST_SUCCESS) { printf("polyvec_matrix_PWM Write ERROR\n"); return XST_FAILURE; }
	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) v, (256*4*5), XAXIDMA_DMA_TO_DEVICE);
	if (status != XST_SUCCESS) { printf("%d,polyvec_matrix_add Read ERROR\n",1);return XST_FAILURE; }
	while ((XAxiDma_Busy(&axidma,XAXIDMA_DEVICE_TO_DMA)) || (XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE))) {/* Wait */}
}

void polyvecl_pointwise_Hardware(polyvecl *r, const poly *a, const polyvecl *v)
{
	int status;
	My_DMA_Ctrl_0 = 2;
	My_DMA_Ctrl_1 = L<<1; //5 = L

	//Xil_DCacheFlushRange((UINTPTR)&r->vec[0], 256*L*4);
	//Xil_DCacheFlushRange((UINTPTR)a, 256*4);
	//Xil_DCacheFlushRange((UINTPTR)&v->vec[0], 256*L*4);

	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) &r->vec[0], (256*L*4), XAXIDMA_DEVICE_TO_DMA);
	if (status != XST_SUCCESS) { printf("PWML Write ERROR\n");return XST_FAILURE; }

	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) a, (256*4), XAXIDMA_DMA_TO_DEVICE);
	if (status != XST_SUCCESS) { printf("PWML1 Read ERROR\n");return XST_FAILURE; }
	while ((XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE))) {}

	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) &v->vec[0], (256*L*4), XAXIDMA_DMA_TO_DEVICE);
	if (status != XST_SUCCESS) { printf("PWML2 Read ERROR\n");return XST_FAILURE; }
	while ((XAxiDma_Busy(&axidma,XAXIDMA_DEVICE_TO_DMA)) || (XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE))) {}
}

void polyveck_pointwise_Hardware(polyveck *r, const poly *a, const polyveck *v)
{
	int status;
	My_DMA_Ctrl_0 = 2;
	My_DMA_Ctrl_1 = K<<1; //6 = K

	//Xil_DCacheFlushRange((UINTPTR)&r->vec[0], 256*K*4);
	//Xil_DCacheFlushRange((UINTPTR)a, 256*4);
	//Xil_DCacheFlushRange((UINTPTR)&v->vec[0], 256*K*4);

	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) &r->vec[0], (256*K*4), XAXIDMA_DEVICE_TO_DMA);
	if (status != XST_SUCCESS) { printf("PWMK Write ERROR\n");return XST_FAILURE; }

	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) a, (256*4), XAXIDMA_DMA_TO_DEVICE);
	if (status != XST_SUCCESS) { printf("PWMK1 Read ERROR\n");return XST_FAILURE; }
	while ((XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE))) {}

	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) &v->vec[0], (256*K*4), XAXIDMA_DMA_TO_DEVICE);
	if (status != XST_SUCCESS) { printf("PWMK2 Read ERROR\n");return XST_FAILURE; }
	while ((XAxiDma_Busy(&axidma,XAXIDMA_DEVICE_TO_DMA)) || (XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE))) {}
}

void poly_add_Hardware(poly *c, const poly *a, const poly *b)
{
	int status;
	My_DMA_Ctrl_0 = 3;
	My_DMA_Ctrl_1 = ( (0<<5) + (1<<6) );

	//Xil_DCacheFlushRange((UINTPTR)a, 256*4);
	//Xil_DCacheFlushRange((UINTPTR)b, 256*4);
	//Xil_DCacheFlushRange((UINTPTR)c, 256*4);

	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) c, (256*4), XAXIDMA_DEVICE_TO_DMA);
	if (status != XST_SUCCESS) { printf("poly_add Write ERROR\n");return XST_FAILURE; }

	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) a, (256*4), XAXIDMA_DMA_TO_DEVICE);
	if (status != XST_SUCCESS) { printf("poly_add Read1 ERROR\n");return XST_FAILURE; }
	while ((XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE))) {}

	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) b, (256*4), XAXIDMA_DMA_TO_DEVICE);
	if (status != XST_SUCCESS) { printf("poly_add Read1 ERROR\n");return XST_FAILURE; }
	while ((XAxiDma_Busy(&axidma,XAXIDMA_DEVICE_TO_DMA)) || (XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE))) {}
}

void polyveck_add_Hardware(polyveck *w, const polyveck *u, const polyveck *v)
{
	for(int i = 0; i < K; ++i)
		poly_add_Hardware(&w->vec[i], &u->vec[i], &v->vec[i]);
}

void polyvecl_add_Hardware(polyvecl *w, const polyvecl *u, const polyvecl *v)
{
	for(int i = 0; i < L; ++i)
		poly_add_Hardware(&w->vec[i], &u->vec[i], &v->vec[i]);
}

void poly_sub_Hardware(poly *c, const poly *a, const poly *b)
{
	int status;
	My_DMA_Ctrl_0 = 3;
	My_DMA_Ctrl_1 = ( (1<<5) + (1<<6) );

	//Xil_DCacheFlushRange((UINTPTR)a, 256*4);
	//Xil_DCacheFlushRange((UINTPTR)b, 256*4);
	//Xil_DCacheFlushRange((UINTPTR)c, 256*4);

	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) c, (256*4), XAXIDMA_DEVICE_TO_DMA);
	if (status != XST_SUCCESS) { printf("poly_add Write ERROR\n");return XST_FAILURE; }

	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) a, (256*4), XAXIDMA_DMA_TO_DEVICE);
	if (status != XST_SUCCESS) { printf("poly_add Read1 ERROR\n");return XST_FAILURE; }
	while ((XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE))) {}

	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) b, (256*4), XAXIDMA_DMA_TO_DEVICE);
	if (status != XST_SUCCESS) { printf("poly_add Read1 ERROR\n");return XST_FAILURE; }
	while ((XAxiDma_Busy(&axidma,XAXIDMA_DEVICE_TO_DMA)) || (XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE))) {}
}

void polyveck_sub_Hardware(polyveck *w, const polyveck *u, const polyveck *v)
{
	for(int i = 0; i < K; ++i)
		poly_sub_Hardware(&w->vec[i], &u->vec[i], &v->vec[i]);
}

void shake256_Hardware(uint8_t *out, size_t outbytes, const uint8_t *in, size_t inbytes)
{
	int status;
	My_DMA_Ctrl_2 = 1 + (0 << 2) + (0 << 3) + (outbytes << 4);
	My_DMA_Ctrl_3 = inbytes;
	My_DMA_Ctrl_0 = 4;

	//Xil_DCacheFlushRange((UINTPTR)in, inbytes);
	//Xil_DCacheFlushRange((UINTPTR)out, outbytes);

	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) in, (inbytes), XAXIDMA_DMA_TO_DEVICE);
	if (status != XST_SUCCESS) { printf("Shake256 Read ERROR\n");return XST_FAILURE; }
	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) out, (outbytes), XAXIDMA_DEVICE_TO_DMA);
	if (status != XST_SUCCESS) { printf("Shake256 Write ERROR\n");return XST_FAILURE; }
	while ((XAxiDma_Busy(&axidma,XAXIDMA_DEVICE_TO_DMA)) || (XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE))) {}
}

void shake256_Dual_Hardware(uint8_t *out, size_t outbytes, const uint8_t *in1, size_t inbytes1, const uint8_t *in2, size_t inbytes2)
{
	int status;
	My_DMA_Ctrl_2 = 1 + (0 << 2) + (0 << 3) + (outbytes << 4);
	My_DMA_Ctrl_3 = inbytes1 + inbytes2;
	My_DMA_Ctrl_0 = 4;
	//Xil_DCacheFlushRange((UINTPTR)in1, inbytes1);
	//Xil_DCacheFlushRange((UINTPTR)in2, inbytes2);
	//Xil_DCacheFlushRange((UINTPTR)out, outbytes);

	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) out, (outbytes), XAXIDMA_DEVICE_TO_DMA);
	if (status != XST_SUCCESS) { printf("Shake256 Write ERROR\n");return XST_FAILURE; }

	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) in1, (inbytes1), XAXIDMA_DMA_TO_DEVICE);
	if (status != XST_SUCCESS) { printf("Shake256 Read1 ERROR\n");return XST_FAILURE; }
	while ((XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE))) {}

	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) in2, (inbytes2), XAXIDMA_DMA_TO_DEVICE);
	if (status != XST_SUCCESS) { printf("Shake256 Read2 ERROR\n");return XST_FAILURE; }

	while ((XAxiDma_Busy(&axidma,XAXIDMA_DEVICE_TO_DMA)) || (XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE))) {}
}


void poly_uniform_Hardware(poly *a, const uint8_t *seed, uint16_t nonce)
{
	int status;
	My_DMA_Ctrl_2 = 0;
	My_DMA_Ctrl_3 = 34;
	My_DMA_Ctrl_0 = 4;

	//Xil_DCacheFlushRange((UINTPTR)seed, 32);
	//Xil_DCacheFlushRange((UINTPTR)&nonce, 2);
	//Xil_DCacheFlushRange((UINTPTR)a, 256*4);

	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) a, (256*4), XAXIDMA_DEVICE_TO_DMA);
	if (status != XST_SUCCESS) { printf("poly_uniform Write ERROR\n");return XST_FAILURE; }

	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) seed, (32), XAXIDMA_DMA_TO_DEVICE);
	if (status != XST_SUCCESS) { printf("poly_uniform Read1 ERROR\n");return XST_FAILURE; }
	while ((XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE))) {}

	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) &nonce, (2), XAXIDMA_DMA_TO_DEVICE);
	if (status != XST_SUCCESS) { printf("poly_uniform Read2 ERROR\n");return XST_FAILURE; }

	while ((XAxiDma_Busy(&axidma,XAXIDMA_DEVICE_TO_DMA)) || (XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE))) {}

}


void poly_uniform_eta_Hardware(poly *a, const uint8_t seed[SEEDBYTES], uint16_t nonce)
{
	int status;
    int rej = (ETA == 4);
	My_DMA_Ctrl_2 = 0 + (1 << 2) + (rej << 3) + (256 << 4);
	My_DMA_Ctrl_3 = 34;
	My_DMA_Ctrl_0 = 4;

	//Xil_DCacheFlushRange((UINTPTR)seed, 32);
	//Xil_DCacheFlushRange((UINTPTR)&nonce, 2);
	//Xil_DCacheFlushRange((UINTPTR)a, 256*4);

	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) a, (256*4), XAXIDMA_DEVICE_TO_DMA);
	if (status != XST_SUCCESS) { printf("poly_uniform Write ERROR\n");return XST_FAILURE; }

	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) seed, (32), XAXIDMA_DMA_TO_DEVICE);
	if (status != XST_SUCCESS) { printf("poly_uniform Read1 ERROR\n");return XST_FAILURE; }
	while ((XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE))) {}

	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) &nonce, (2), XAXIDMA_DMA_TO_DEVICE);
	if (status != XST_SUCCESS) { printf("poly_uniform Read2 ERROR\n");return XST_FAILURE; }


	while ((XAxiDma_Busy(&axidma,XAXIDMA_DEVICE_TO_DMA)) || (XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE))) {}
}
void poly_uniform_eta2_Hardware(poly *a, const uint8_t seed[SEEDBYTES], uint16_t nonce)
{
	int status;
    int rej = (ETA == 4);
	My_DMA_Ctrl_2 = 0 + (1 << 2) + (0 << 3) + (256 << 4);
	My_DMA_Ctrl_3 = 34;
	My_DMA_Ctrl_0 = 4;

	//Xil_DCacheFlushRange((UINTPTR)seed, 32);
	//Xil_DCacheFlushRange((UINTPTR)&nonce, 2);
	//Xil_DCacheFlushRange((UINTPTR)a, 256*4);

	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) a, (256*4), XAXIDMA_DEVICE_TO_DMA);
	if (status != XST_SUCCESS) { printf("poly_uniform Write ERROR\n");return XST_FAILURE; }

	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) seed, (32), XAXIDMA_DMA_TO_DEVICE);
	if (status != XST_SUCCESS) { printf("poly_uniform Read1 ERROR\n");return XST_FAILURE; }
	while ((XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE))) {}

	status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) &nonce, (2), XAXIDMA_DMA_TO_DEVICE);
	if (status != XST_SUCCESS) { printf("poly_uniform Read2 ERROR\n");return XST_FAILURE; }


	while ((XAxiDma_Busy(&axidma,XAXIDMA_DEVICE_TO_DMA)) || (XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE))) {}
}
//added function
void polyvec_matrix_expand_Hardware(polyvecl mat[K], const uint8_t rho[SEEDBYTES])
{
  unsigned int i, j;
  for(i = 0; i < K; ++i)
    for(j = 0; j < L; ++j)
    {
    	for(int k=0;k<1;k++)
    		poly_uniform_Hardware(&mat[i].vec[j], rho, (i << 8) + j);
    }
}

void polyvecl_uniform_eta_Hardware(polyvecl *v, const uint8_t seed[SEEDBYTES], uint8_t nonce)
{
	unsigned int i;
	for(i = 0; i < L; ++i)
	{
		poly_uniform_eta_Hardware(&v->vec[i], seed, nonce++);
	}
}

void polyveck_uniform_eta_Hardware(polyveck *v, const uint8_t seed[SEEDBYTES], uint8_t nonce)
{
	unsigned int i;
	for(i = 0; i < K; ++i)
	{
		poly_uniform_eta_Hardware(&v->vec[i], seed, nonce++);
	}
}
//test
void polyvecl_ntt_Hardware(polyvecl *v)
{
  unsigned int i;

  for(i = 0; i < L; ++i)
	  NTT_Hardware(&v->vec[i]);
}

void polyveck_ntt_Hardware(polyveck *v)
{
  unsigned int i;

  for(i = 0; i < K; ++i)
	  NTT_Hardware(&v->vec[i]);
}


void polyveck_invntt_Hardware(polyveck *v)
{
  unsigned int i;

  for(i = 0; i < K; ++i)
	  INTT_Hardware(&v->vec[i]);
}

void polyvecl_invntt_Hardware(polyvecl *v) {
  unsigned int i;

  for(i = 0; i < L; ++i)
	  INTT_Hardware(&v->vec[i]);
}

#if GAMMA1 == (1 << 17)
#define POLY_UNIFORM_GAMMA1_NBLOCKS ((576 + STREAM256_BLOCKBYTES - 1)/STREAM256_BLOCKBYTES)
#elif GAMMA1 == (1 << 19)
#define POLY_UNIFORM_GAMMA1_NBLOCKS ((640 + STREAM256_BLOCKBYTES - 1)/STREAM256_BLOCKBYTES)
#endif
void poly_uniform_gamma1_Hardware(poly *a, const uint8_t seed[CRHBYTES], uint16_t nonce)
{
	uint8_t buf[POLY_UNIFORM_GAMMA1_NBLOCKS*STREAM256_BLOCKBYTES];
	shake256_Dual_Hardware(buf, POLY_UNIFORM_GAMMA1_NBLOCKS*STREAM256_BLOCKBYTES, seed, CRHBYTES, &nonce, 2);
	polyz_unpack(a, buf);
}

void polyvecl_uniform_gamma1_Hardware(polyvecl *v, const uint8_t seed[SEEDBYTES], uint16_t nonce)
{
  unsigned int i;
  for(i = 0; i < L; ++i)
    poly_uniform_gamma1_Hardware(&v->vec[i], seed, L*nonce + i);
}

void polyvec_matrix_expand_Hardware_new(polyveck mat[L], const uint8_t rho[SEEDBYTES])
{
  unsigned int i, j;
  for(i = 0; i < K; ++i)
    for(j = 0; j < L; ++j)
    {
    	for(int k=0;k<1;k++)
    		poly_uniform_Hardware(&mat[j].vec[i], rho, (i << 8) + j);
    }
}

void polyvec_matrix_PWM_Hardware_new(polyveck mat_temp[L], const polyvecl *v)
{
	int status;
	for(int k = 0; k < L; ++k)
	{
		My_DMA_Ctrl_0 = 2;
		My_DMA_Ctrl_1 = K<<1;//6 =  K; need to configure for different parameters
		//Xil_DCacheFlushRange((UINTPTR)&mat_temp[k].vec[0], K*256*4);
		status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) &mat_temp[k].vec[0], (K*256*4), XAXIDMA_DEVICE_TO_DMA);
		if (status != XST_SUCCESS) { printf("polyvec_matrix_PWM Write ERROR\n"); return XST_FAILURE; }

		//Xil_DCacheFlushRange((UINTPTR)&v->vec[k], 256*4);
		status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) &v->vec[k], (256*4), XAXIDMA_DMA_TO_DEVICE);
		if (status != XST_SUCCESS) { printf("%d,polyvec_matrix_PWM Read1 ERROR\n",k);return XST_FAILURE; }
		while ((XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE))) {}
		for(int i = 0; i < 1; ++i )
		{
			//Xil_DCacheFlushRange((UINTPTR)&mat_temp[k].vec[0], K*256*4);
			status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) &mat_temp[k].vec[0], (K*256*4), XAXIDMA_DMA_TO_DEVICE);
			if (status != XST_SUCCESS) { printf("%d,polyvec_matrix_PWM Read2 ERROR\n",k);return XST_FAILURE; }
			while ((XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE))) {}
		}

		while ((XAxiDma_Busy(&axidma,XAXIDMA_DEVICE_TO_DMA)) ) {}
	}
}

void polyvec_matrix_PWM_Hardware_sign(polyveck mat_result[L], polyveck mat[L], const polyvecl *v)
{
	int status;
	for(int k = 0; k < L; ++k)
	{
		My_DMA_Ctrl_0 = 2;
		My_DMA_Ctrl_1 = K<<1;
		//Xil_DCacheFlushRange((UINTPTR)&mat_result[k].vec[0], K*256*4);
		status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) &mat_result[k].vec[0], (K*256*4), XAXIDMA_DEVICE_TO_DMA);
		if (status != XST_SUCCESS) { printf("polyvec_matrix_PWM Write ERROR\n"); return XST_FAILURE;}
		//Xil_DCacheFlushRange((UINTPTR)&v->vec[k], 256*4);
		status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) &v->vec[k], (256*4), XAXIDMA_DMA_TO_DEVICE);
		if (status != XST_SUCCESS) { printf("%d,polyvec_matrix_PWM Read1 ERROR\n",k);return XST_FAILURE; }
		while ((XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE))) {}
		for(int i = 0; i < 1; ++i )
		{
			//Xil_DCacheFlushRange((UINTPTR)&mat[k].vec[0], K*256*4);
			status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) &mat[k].vec[0], (K*256*4), XAXIDMA_DMA_TO_DEVICE);
			if (status != XST_SUCCESS) { printf("%d,polyvec_matrix_PWM Read2 ERROR\n",k);return XST_FAILURE; }
			while ((XAxiDma_Busy(&axidma,XAXIDMA_DMA_TO_DEVICE))) {}
		}
		while ((XAxiDma_Busy(&axidma,XAXIDMA_DEVICE_TO_DMA)) ) {}
	}
}
