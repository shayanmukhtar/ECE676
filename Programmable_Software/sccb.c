/*
 * sccb.c
 *
 *  Created on: Apr 1, 2017
 *      Author: Shayan Mukhtar
 */

/***************************** Include Files **********************************/
#include "xparameters.h"
#include "xiicps.h"
#include "xscugic.h"
#include "xil_exception.h"
#include "xil_printf.h"
#include "sccb.h"

/************************** Variable Definitions ******************************/

XIicPs Iic;			/* Instance of the IIC Device */
XScuGic InterruptController;	/* Instance of the Interrupt Controller */

/*
 * The following buffers are used in this example to send and receive data
 * with the IIC. They are defined as global so that they are not on the stack.
 */
u8 SendBuffer[TEST_BUFFER_SIZE];    /* Buffer for Transmitting Data */
u8 RecvBuffer[TEST_BUFFER_SIZE];    /* Buffer for Receiving Data */

/*
 * The following counters are used to determine when the entire buffer has
 * been sent and received.
 */
volatile u32 SendComplete;
volatile u32 RecvComplete;
volatile u32 TotalErrorCount;

/************************** Static Function Declarations ******************************/
static int SetupInterruptSystem(XIicPs *IicPsPtr);
void Handler(void *CallBackRef, u32 Event);

/****************************** Global Constant Data **********************************/

//#define MYIMP
const T_CameraInitParams C_CameraInitParams[] =
{
#ifdef MYIMP
		{0x12, 0x80},
		{0x12, 0x80},
		/*
		{
			CLKRC_CTRL_REG,
			0x80 | 0x01		//enable internal PLL, prescale clk by 2
		},
		*/
		{
			CLKRC_CTRL_REG,
			0x00			//enable internal PLL, but don't prescale
		},
		/*
		{
			DBLV_CTRL_REG,
			0x3F | 0x80		//scale PLL by 6 (gives PCLK of either 24 MHZ)
		},
		*/
		{
			COM7_CTRL_REG,
			0b100			//RGB mode
		},
		{
			COM15_CTRL_REG,
			0b00010000		//RGB 565 (1 pixel every 2 bytes with a free bit at the top)
		},
		{0x1e, 0x37},	//flip image
		{0x4f, 0x40},
		{0x50, 0x34},
		{0x51, 0x0C},
		{0x52, 0x17},
		{0x53, 0x29},
		{0x54, 0x40},
		{0x58, 0x1e},
#else
		{0x12,0x80}, // COM7   Reset
		{0x12,0x80}, // COM7   Reset
		{0x12,0x04}, // COM7   Size & RGB output
		{0x11,0x00}, // CLKRC  Prescaler - Fin/(1+1)
		{0x0C,0x00}, // COM3   Lots of stuff,0x enable scaling,0x all others off
		{0x3E,0x00}, // COM14  PCLK scaling off
		{0x8C,0x00}, // RGB444 Set RGB format
		{0x04,0x00}, // COM1   no CCIR601
		{0x40,0x10},   // COM15  Full 0-255 output,0x RGB 565
		{0x3a,0x04}, // TSLB   Set UV ordering,0x  do not auto-reset window
		{0x14,0x38}, // COM9  - AGC Celling
		{0x4f,0x40}, //{0x4fb3}, // MTX1  - colour conversion matrix
		{0x50,0x34}, //{0x50b3}, // MTX2  - colour conversion matrix
		{0x51,0x0C}, //{0x5100}, // MTX3  - colour conversion matrix
		{0x52,0x17}, //{0x523d}, // MTX4  - colour conversion matrix
		{0x53,0x29}, //{0x53a7}, // MTX5  - colour conversion matrix
		{0x54,0x40}, //{0x54e4}, // MTX6  - colour conversion matrix
		{0x58,0x1e}, //{0x589e}, // MTXS  - Matrix sign and auto contrast
		{0x3d,0xc0}, // COM13 - Turn on GAMMA and UV Auto adjust
		{0x11,0x00}, // CLKRC  Prescaler - Fin/(1+1)
		{0x17,0x11}, // HSTART HREF start (high 8 bits)
		{0x18,0x61}, // HSTOP  HREF stop (high 8 bits)
		{0x32,0xA4}, // HREF   Edge offset and low 3 bits of HSTART and HSTOP
		{0x19,0x03}, // VSTART VSYNC start (high 8 bits)
		{0x1A,0x7b}, // VSTOP  VSYNC stop (high 8 bits)
		{0x03,0x0a}, // VREF   VSYNC low two bits
		{0x0e,0x61}, // COM5(0x0E) 0x61
		{0x0f,0x4b}, // COM6(0x0F) 0x4B
		{0x16,0x02}, //
		{0x1e,0x37}, // MVFP (0x1E) 0x07  // FLIP AND MIRROR IMAGE 0x3x
		{0x21,0x02},
		{0x22,0x91},
		{0x29,0x07},
		{0x33,0x0b},
		{0x35,0x0b},
		{0x37,0x1d},
		{0x38,0x71},
		{0x39,0x2a},
		{0x3c,0x78}, // COM12 (0x3C) 0x78
		{0x4d,0x40},
		{0x4e,0x20},
		{0x69,0x00}, // GFIX (0x69) 0x00
		{0x6b,0x4a}, //PLL control messing it up :(
		{0x74,0x10},
		{0x8d,0x4f},
		{0x8e,0x00},
		{0x8f,0x00},
		{0x90,0x00},
		{0x91,0x00},
		{0x96,0x00},
		{0x9a,0x00},
		{0xb0,0x84},
		{0xb1,0x0c},
		{0xb2,0x0e},
		{0xb3,0x82},
		{0xb8,0x0a}
#endif
};

const unsigned char C_NumOfInitParams = sizeof(C_CameraInitParams)/sizeof(C_CameraInitParams[0]);

/****************************  Function Definitions ***********************************/
int configure_SCCB(int DeviceId)
{
	int Status;
	XIicPs_Config *Config;

	/*
	 * Initialize the IIC driver so that it's ready to use
	 * Look up the configuration in the config table, then initialize it.
	 */
	Config = XIicPs_LookupConfig(DeviceId);
	if (NULL == Config) {
		return XST_FAILURE;
	}

	Status = XIicPs_CfgInitialize(&Iic, Config, Config->BaseAddress);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Perform a self-test to ensure that the hardware was built correctly.
	 */
	Status = XIicPs_SelfTest(&Iic);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Connect the IIC to the interrupt subsystem such that interrupts can
	 * occur. This function is application specific.
	 */
	Status = SetupInterruptSystem(&Iic);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Setup the handlers for the IIC that will be called from the
	 * interrupt context when data has been sent and received, specify a
	 * pointer to the IIC driver instance as the callback reference so
	 * the handlers are able to access the instance data.
	 */
	XIicPs_SetStatusHandler(&Iic, (void *) &Iic, Handler);

	/*
	 * Set the IIC serial clock rate.
	 */
	XIicPs_SetSClk(&Iic, IIC_SCLK_RATE);

	return XST_SUCCESS;
}
/*****************************************************************************/
/**
*
* This function is the handler which performs processing to handle data events
* from the IIC.  It is called from an interrupt context such that the amount
* of processing performed should be minimized.
*
* This handler provides an example of how to handle data for the IIC and
* is application specific.
*
* @param	CallBackRef contains a callback reference from the driver, in
*		this case it is the instance pointer for the IIC driver.
* @param	Event contains the specific kind of event that has occurred.
*
* @return	None.
*
* @note		None.
*
*******************************************************************************/
void Handler(void *CallBackRef, u32 Event)
{
	/*
	 * All of the data transfer has been finished.
	 */
	if (0 != (Event & XIICPS_EVENT_COMPLETE_RECV)){
		RecvComplete = TRUE;
	} else if (0 != (Event & XIICPS_EVENT_COMPLETE_SEND)) {
		SendComplete = TRUE;
	} else if (0 == (Event & XIICPS_EVENT_SLAVE_RDY)){
		/*
		 * If it is other interrupt but not slave ready interrupt, it is
		 * an error.
		 * Data was received with an error.
		 */
		TotalErrorCount++;
	}
}

/******************************************************************************/
/**
*
* This function setups the interrupt system such that interrupts can occur
* for the IIC.  This function is application specific since the actual
* system may or may not have an interrupt controller.  The IIC could be
* directly connected to a processor without an interrupt controller.  The
* user should modify this function to fit the application.
*
* @param	IicPsPtr contains a pointer to the instance of the Iic
*		which is going to be connected to the interrupt controller.
*
* @return	XST_SUCCESS if successful, otherwise XST_FAILURE.
*
* @note		None.
*
*******************************************************************************/
static int SetupInterruptSystem(XIicPs *IicPsPtr)
{
	int Status;
	XScuGic_Config *IntcConfig; /* Instance of the interrupt controller */

	Xil_ExceptionInit();

	/*
	 * Initialize the interrupt controller driver so that it is ready to
	 * use.
	 */
	IntcConfig = XScuGic_LookupConfig(INTC_DEVICE_ID);
	if (NULL == IntcConfig) {
		return XST_FAILURE;
	}

	Status = XScuGic_CfgInitialize(&InterruptController, IntcConfig,
					IntcConfig->CpuBaseAddress);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}


	/*
	 * Connect the interrupt controller interrupt handler to the hardware
	 * interrupt handling logic in the processor.
	 */
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_IRQ_INT,
				(Xil_ExceptionHandler)XScuGic_InterruptHandler,
				&InterruptController);

	/*
	 * Connect the device driver handler that will be called when an
	 * interrupt for the device occurs, the handler defined above performs
	 * the specific interrupt processing for the device.
	 */
	Status = XScuGic_Connect(&InterruptController, IIC_INT_VEC_ID,
			(Xil_InterruptHandler)XIicPs_MasterInterruptHandler,
			(void *)IicPsPtr);
	if (Status != XST_SUCCESS) {
		return Status;
	}

	/*
	 * Enable the interrupt for the Iic device.
	 */
	XScuGic_Enable(&InterruptController, IIC_INT_VEC_ID);


	/*
	 * Enable interrupts in the Processor.
	 */
	Xil_ExceptionEnable();

	return XST_SUCCESS;
}

/******************************************************************************/
/**
*
* This function directly interfaces with the IIC driver to write an SCCB
* compliant register to the OV7670 camera
*
* @param	writeData contains the single byte to be written to camera register
* 			registerOffset contains the register address to write to
*
* @return	XST_SUCCESS if successful, otherwise XST_FAILURE.
*
* @note		None.
*
*******************************************************************************/
int SCCB_Write_Register(unsigned char writeData, unsigned char registerOffset, unsigned char requestType)
{
	/*You need to write the register to perform a read - this figures out size of transaction based
	 * on whether its an actual register write, or a register write proceeded by a register read*/
	int transactionSize = (READ_REQ == requestType) ? SIZEOF_READ_TRANSACTION : SIZEOF_WRITE_TRANSACTION;
	while (XIicPs_BusIsBusy(&Iic))
	{
		/* NOP */
	}
	/*Arbitration won - proceed*/

	SendComplete = FALSE;

	/*Populate Send Buffer*/
	SendBuffer[0] = registerOffset;
	SendBuffer[1] = writeData;
	/*
	 * Send the buffer, errors are reported by TotalErrorCount.
	 */
	XIicPs_MasterSendPolled(&Iic, SendBuffer, transactionSize,
			IIC_SLAVE_ADDR);

	/*
	 * Wait for the entire buffer to be sent, letting the interrupt
	 * processing work in the background, this function may get
	 * locked up in this loop if the interrupts are not working
	 * correctly.
	 */
	/*
	while (!SendComplete) {
		if (0 != TotalErrorCount) {
			return XST_FAILURE;
		}
	}*/

	/*
	 * Wait bus activities to finish.
	 */
	while (XIicPs_BusIsBusy(&Iic)) {
		/* NOP */
	}

	return XST_SUCCESS;
}

/******************************************************************************/
/**
*
* This function directly interfaces with the IIC driver to read an SCCB
* compliant register to the OV7670 camera
*
* @param	readData_ptr contains the single byte pointer to hold the read data from camera
* 			registerOffset contains the register address to read from
*
* @return	XST_SUCCESS if successful, otherwise XST_FAILURE.
*
* @note		None.
*
*******************************************************************************/
int SCCB_Read_Register(unsigned char * readData_ptr, unsigned char registerOffset)
{
	unsigned char index;
	RecvComplete = FALSE;

	/*First write the register to signal a read is needed*/
	if (SCCB_Write_Register(0x00, registerOffset, READ_REQ))
		return XST_FAILURE;

	XIicPs_MasterRecvPolled(&Iic, RecvBuffer, SIZEOF_READ_TRANSACTION,
			IIC_SLAVE_ADDR);
/*
	while (!RecvComplete) {
		if (0 != TotalErrorCount) {
			return XST_FAILURE;
		}
	}
*/
	/*
	 * Wait bus activities to finish.
	 */
	while (XIicPs_BusIsBusy(&Iic)) {
		/* NOP */
	}
	/*Copy back from Rx buffer into user buffer*/
	for (index = 0; index < SIZEOF_READ_TRANSACTION; index++)
		readData_ptr[index] = *RecvBuffer;

	return XST_SUCCESS;
}

/******************************************************************************/
/**
*
* Initialize all the registers in the OV7670 for 24MHz and RGB555
*
* @param	readData_ptr contains the single byte pointer to hold the read data from camera
* 			registerOffset contains the register address to read from
*
* @return	XST_SUCCESS if successful, otherwise XST_FAILURE.
*
* @note		None.
*
*******************************************************************************/
int OV7670_Camera_Init(const T_CameraInitParams * ptr, unsigned char num)
{
	/*Initialize to success*/
	unsigned int returnStatus = XST_SUCCESS;
	unsigned int index;
	/*Data sheet specifies to always read, modify, then write back to preserve defaults*/
	unsigned char readBuffer[1] = {0x00};

	/*Loop through and set every register*/
	for (index = 0; index < num; index++)
	{
		/*store current value of register*/
		//returnStatus |= SCCB_Read_Register(readBuffer, ptr[index].reg);
		/*manipulate required bits and write register back*/
		returnStatus |= SCCB_Write_Register(ptr[index].value | readBuffer[0], ptr[index].reg, WRITE_REQ);
	}

	return returnStatus;
}
