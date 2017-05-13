/*
 * gpio.c
 *
 *  Created on: Apr 7, 2017
 *      Author: Shayan Mukhtar
 */


#include <stdio.h>
#include "platform.h"
#include "xil_io.h"
#include "xil_printf.h"
#include "xscugic.h"
#include "xil_exception.h"
#include "xscugic_hw.h"
#include "xgpio.h"
#include "gpio.h"
#include "xil_printf.h"

XGpio PLIntInst;
XScuGic INTCInst;

Te_ColorSpaceFilter Ve_ColorSpaceFilter;
Te_LocationDetectionIndication Ve_LocationDetectionIndication;

void Button_Int_Handler(void *InstancePtr)
{
	unsigned int read = XGpio_DiscreteRead(&PLIntInst, 1);
	if (BTN_0_PRESSED(read))
	{
		switch (Ve_ColorSpaceFilter.color)
		{
		case Red_Channel:
			Ve_ColorSpaceFilter.color = Green_Channel;
			break;
		case Green_Channel:
			Ve_ColorSpaceFilter.color = Blue_Channel;
			break;
		case Blue_Channel:
			Ve_ColorSpaceFilter.color = Red_Channel;
			break;
		default:
			Ve_ColorSpaceFilter.color = Red_Channel;
			break;
		}
	}
	if (BTN_1_PRESSED(read))
	{
		switch (Ve_ColorSpaceFilter.color)
		{
		case Red_Channel:
			if (Ve_ColorSpaceFilter.red_threshold > 0)
				Ve_ColorSpaceFilter.red_threshold--;
			break;
		case Green_Channel:
			if (Ve_ColorSpaceFilter.green_threshold > 0)
				Ve_ColorSpaceFilter.green_threshold--;
			break;
		case Blue_Channel:
			if (Ve_ColorSpaceFilter.blue_threshold > 0)
				Ve_ColorSpaceFilter.blue_threshold--;
			break;
		default: break;
		}
	}
	if (BTN_2_PRESSED(read))
	{
		switch (Ve_ColorSpaceFilter.color)
		{
		case Red_Channel:
			if (Ve_ColorSpaceFilter.red_threshold < MAX_THRESHOLD)
				Ve_ColorSpaceFilter.red_threshold++;
			break;
		case Green_Channel:
			if (Ve_ColorSpaceFilter.green_threshold < MAX_THRESHOLD)
				Ve_ColorSpaceFilter.green_threshold++;
			break;
		case Blue_Channel:
			if (Ve_ColorSpaceFilter.blue_threshold < MAX_THRESHOLD)
				Ve_ColorSpaceFilter.blue_threshold++;
			break;
		default: break;
		}
	}
	if (BTN_3_PRESSED(read))
	{
		Ve_ColorSpaceFilter.current_choice++;
	}
	updateColorFilter(&Ve_ColorSpaceFilter);
	(void) XGpio_InterruptClear(&PLIntInst, 1);
}

int InterruptSystemSetup (XScuGic *XScuGicInstancePtr) {
	//enable interrupt
	//XGpio_InterruptEnable(&BTNInst, BTN_INT);
	//XGpio_InterruptGlobalEnable(&BTNInst);

	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
			(Xil_ExceptionHandler) XScuGic_InterruptHandler,
			XScuGicInstancePtr);

	Xil_ExceptionEnable();
	return XST_SUCCESS;

}

int IntcInitFunction(u16 DeviceId, XGpio *GpioInstancePtr) {
	XScuGic_Config *IntcConfig;
	int status;

	//interrupt controller init
	IntcConfig = XScuGic_LookupConfig(DeviceId);
	status = XScuGic_CfgInitialize(&INTCInst, IntcConfig,
			IntcConfig->CpuBaseAddress);
	if (status != XST_SUCCESS)
		return XST_FAILURE;

	//call to interrupt setup
	status = InterruptSystemSetup(&INTCInst);
	if (status != XST_SUCCESS)
		return XST_FAILURE;


	//Connect GPIO interrupt to handler
	status = XScuGic_Connect(&INTCInst, XPAR_FABRIC_AXI_GPIO_0_IP2INTC_IRPT_INTR,
			(Xil_ExceptionHandler) Button_Int_Handler, (void *) GpioInstancePtr);
	if (status != XST_SUCCESS)
		return XST_FAILURE;

	//Enable GPIO Interrupts interrupt
	XGpio_InterruptEnable(GpioInstancePtr,1);
	XGpio_InterruptGlobalEnable(GpioInstancePtr);

	//Enable GPIO interrupts in the controller
	XScuGic_Enable(&INTCInst, XPAR_FABRIC_AXI_GPIO_0_IP2INTC_IRPT_INTR);

	return XST_SUCCESS;

}

int Location_Detection_Init(Te_LocationDetectionIndication *ptr)
{
	//write the threshold register
	AXI_COLOR_FILTER_mWriteReg(LOCATION_ADDR, 0, LOCATION_PIXEL_THRESHOLD);
	//initialize detected location as dead center
	ptr->col = SCREEN_WIDTH_COLS / 2;
	ptr->row = SCREEN_HEIGHT_ROWS / 2;
	return XST_SUCCESS;
}

int Detect_Location(Te_LocationDetectionIndication *ptr)
{
	ptr->col = Xil_In32(LOCATION_ADDR + COL_REG);
	ptr->row = Xil_In32(LOCATION_ADDR + ROW_REG);
	return XST_SUCCESS;
}

int GPIO_Init(void)
{
	/*Do all the interrupt reinits for the GPIO buttons to start working*/
	int status;
	status = XGpio_Initialize(&PLIntInst, XPAR_AXI_GPIO_0_DEVICE_ID);
	if (status != XST_SUCCESS)
		return XST_FAILURE;
	status = IntcInitFunction(INTC_DEVICE_ID, &PLIntInst);
	if (status != XST_SUCCESS)
	{
		return XST_FAILURE;
	}
	/*Init the structure*/

	return XST_SUCCESS;
}

int ColorFilter_Init(void)
{
	Ve_ColorSpaceFilter.color = Green_Channel;
	Ve_ColorSpaceFilter.red_threshold = 26;
	Ve_ColorSpaceFilter.green_threshold = 42;
	Ve_ColorSpaceFilter.blue_threshold = 20;
	Ve_ColorSpaceFilter.current_choice = 2;
	return updateColorFilter(&Ve_ColorSpaceFilter);
}

int updateColorFilter(Te_ColorSpaceFilter * ptr)
{
	long thresholdWritten, valueRead;
	switch (ptr->color)
	{
	case Red_Channel:
		thresholdWritten = ptr->red_threshold;
		AXI_COLOR_FILTER_mWriteReg(FILTER_ADDR, Red_Threshold, (unsigned int)ptr->red_threshold);
		valueRead = AXI_COLOR_FILTER_mReadReg(FILTER_ADDR, Red_Threshold);
		break;
	case Green_Channel:
		thresholdWritten = ptr->green_threshold;
		AXI_COLOR_FILTER_mWriteReg(FILTER_ADDR, Green_Threshold, (unsigned int)ptr->green_threshold);
		valueRead = AXI_COLOR_FILTER_mReadReg(FILTER_ADDR, Green_Threshold);
		break;
	case Blue_Channel:
		thresholdWritten = ptr->blue_threshold;
		AXI_COLOR_FILTER_mWriteReg(FILTER_ADDR, Blue_Threshold, (unsigned int)ptr->blue_threshold);
		valueRead = AXI_COLOR_FILTER_mReadReg(FILTER_ADDR, Blue_Threshold);
		break;
	default: break;
	}

	xil_printf("Threshold: %d Color: %d Value Read Back: %d Choice: %d\n", thresholdWritten, ptr->color, valueRead, ptr->current_choice);
	return XST_SUCCESS;
}
