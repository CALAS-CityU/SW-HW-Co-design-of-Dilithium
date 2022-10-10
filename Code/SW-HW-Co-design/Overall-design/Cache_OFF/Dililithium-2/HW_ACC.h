#ifndef HW_ACC_H
#define HW_ACC_H

#include <stdint.h>
#include "platform.h"
/*add include files here*/
#include "xaxidma.h"//DMA
#include "xparameters.h"//address
#include "xil_exception.h"//exception related APIs
#include "xscugic.h"//interrupt controller
#include"params.h"
#include "polyvec.h"
#include "poly.h"
#include "symmetric.h"

/************************** Variable Definitions *****************************/
XAxiDma axidma;     //XAxiDma Instance
XScuGic intc;       //interrupt controller Instance
volatile int tx_done;      //Send complete flag
volatile int rx_done;      //Receive complete flag
volatile int error;        //Transmission error flag

/*add definitions*/
#define DMA_DEV_ID          XPAR_AXIDMA_0_DEVICE_ID
#define RX_INTR_ID          XPAR_FABRIC_AXIDMA_0_S2MM_INTROUT_VEC_ID
#define TX_INTR_ID          XPAR_FABRIC_AXIDMA_0_MM2S_INTROUT_VEC_ID
#define INTC_DEVICE_ID      XPAR_SCUGIC_SINGLE_DEVICE_ID
#define RESET_TIMEOUT_COUNTER   10000//reset time

/*control address*/
#define My_DMA_Ctrl_0 (*(volatile unsigned int *)(XPAR_HW_ACC_IP_0_BASEADDR))//Start signal -> 1:NTT/INTT, 2:PWM, 3:SHA
#define My_DMA_Ctrl_1 (*(volatile unsigned int *)(XPAR_HW_ACC_IP_0_BASEADDR + 4))//a+(b<<1)+(c<<1)+(d<<1)
// a{0:NTT,1:INTT}, b: pwm vector size
#define My_DMA_Ctrl_2 (*(volatile unsigned int *)(XPAR_HW_ACC_IP_0_BASEADDR + 8))
//a + (b << 2) + (c << 3) + (outlen << 4), a{0: Sampling, 1:SHAKE256}, b{0: uni_samp, 1:rej_samp}, c{0:eta=2,1:eta=4}
#define My_DMA_Ctrl_3 (*(volatile unsigned int *)(XPAR_HW_ACC_IP_0_BASEADDR + 12))//SHAEKE input length
#define My_DMA_Ctrl_4 (*(volatile unsigned int *)(XPAR_HW_ACC_IP_0_BASEADDR + 16))//Input FIFO data count
#define My_DMA_Ctrl_5 (*(volatile unsigned int *)(XPAR_HW_ACC_IP_0_BASEADDR + 20))//Output FIFO data count


/*Function definition*/
void transmission_initialization();

/*Hardware acceleration interface*/
void NTT_Hardware(int32_t a[N]);
void INTT_Hardware(int32_t a[N]);
void poly_pointwise_Hardwarey(poly *c, const poly *a, const poly *b);
void polyvec_matrix_PWM_Hardware(polyveck mat_temp[L], const polyvecl mat[K], const polyvecl *v);
void polyvec_matrix_add_Hardware(polyveck *t, const polyveck mat_temp[L]);
void polyvecl_pointwise_Hardware(polyvecl *r, const poly *a, const polyvecl *v);
void polyveck_pointwise_Hardware(polyveck *r, const poly *a, const polyveck *v);
void poly_add_Hardware(poly *c, const poly *a, const poly *b);
void polyveck_add_Hardware(polyveck *w, const polyveck *u, const polyveck *v);
void poly_sub_Hardware(poly *c, const poly *a, const poly *b);
void polyveck_sub_Hardware(polyveck *w, const polyveck *u, const polyveck *v);
void shake256_Hardware(uint8_t *out, size_t outbytes, const uint8_t *in, size_t inbytes);
void shake256_Dual_Hardware(uint8_t *out, size_t outbytes, const uint8_t *in1, size_t inbytes1, const uint8_t *in2, size_t inbytes2);
void poly_uniform_Hardware(poly *a, const uint8_t *seed, uint16_t nonce);
void poly_uniform_eta_Hardware(poly *a, const uint8_t seed[SEEDBYTES], uint16_t nonce);
//added fuction
void polyvec_matrix_expand_Hardware(polyvecl mat[K], const uint8_t rho[SEEDBYTES]);
void polyvecl_uniform_eta_Hardware(polyvecl *v, const uint8_t seed[SEEDBYTES], uint8_t nonce);
void polyveck_uniform_eta_Hardware(polyveck *v, const uint8_t seed[SEEDBYTES], uint8_t nonce);
void polyvecl_ntt_Hardware(polyvecl *v);
void polyveck_ntt_Hardware(polyveck *v);
void polyveck_invntt_Hardware(polyveck *v);
void polyvecl_invntt_Hardware(polyvecl *v);
void poly_uniform_gamma1_Hardware(poly *a, const uint8_t seed[CRHBYTES], uint16_t nonce);
void polyvecl_uniform_gamma1_Hardware(polyvecl *v, const uint8_t seed[SEEDBYTES], uint16_t nonce);

#endif
