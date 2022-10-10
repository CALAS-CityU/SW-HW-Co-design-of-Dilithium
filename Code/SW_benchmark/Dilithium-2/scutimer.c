/*
 * scutimer.c
 *
 *  Created on: 2015年10月29日
 *      Author: fac
 */
#include "xparameters.h"
#include "scutimer.h"
#include "xil_printf.h"

static XScuTimer_Config	*config = NULL;
static XScuTimer			scutimer;
static unsigned int		tt_start;
static unsigned int		tt_end;

void scutimer_init();

void scutimer_init()
{
	tt_start = tt_end = 0;
	XScuTimer_Config *config = XScuTimer_LookupConfig(XPAR_PS7_SCUTIMER_0_DEVICE_ID);
	XScuTimer_CfgInitialize(&scutimer, config, XPAR_PS7_SCUTIMER_0_BASEADDR);
	XScuTimer_LoadTimer(&scutimer, 0xFFFFFFFF);
	//xil_printf("ScuTimer initialization done\r\n");
}

void scutimer_start()
{
	/* check whether it is initializated */
	if(config == NULL)
		scutimer_init();

	XScuTimer_LoadTimer(&scutimer, 0xFFFFFFFF);
	XScuTimer_RestartTimer(&scutimer);
	XScuTimer_Start(&scutimer);
	tt_start = XScuTimer_GetCounterValue(&scutimer);
}
/* 返回的是微妙数*/
int scutimer_result()
{
	XScuTimer_Stop(&scutimer);
	tt_end = XScuTimer_GetCounterValue(&scutimer);
	int diff = tt_start - tt_end;
	/*scutimer的频率一般是ARM CPU频率的一般*/
	int t = 2 * diff;
	return t;
}
