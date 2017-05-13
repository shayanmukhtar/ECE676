/*
 * sccb.h
 *
 *  Created on: Apr 1, 2017
 *      Author: Shayan Mukhtar
 */

#ifndef SRC_SCCB_H_
#define SRC_SCCB_H_
/************************** Constant Definitions ******************************/

/*
 * The following constants map to the XPAR parameters created in the
 * xparameters.h file. They are defined here such that a user can easily
 * change all the needed parameters in one place.
 */
#define IIC_DEVICE_ID		XPAR_XIICPS_0_DEVICE_ID
#define INTC_DEVICE_ID		XPAR_SCUGIC_SINGLE_DEVICE_ID
#define IIC_INT_VEC_ID		XPAR_XIICPS_0_INTR
#define TEST_BUFFER_SIZE	20	//more than enough - we do 3 bytes at a time
/*
 * The slave address to send to and receive from.
 */
#define IIC_SLAVE_ADDR				0x21			//data sheet says 42, but thats 8 bit, so shift by 1
#define IIC_SCLK_RATE				100000			//100KHz less than max

/*Minus one for the below because the hardware driver takes care of the address already*/
#define SIZEOF_WRITE_TRANSACTION	3-1				//Write consists of three phases - Address, Register, DataOut
#define SIZEOF_READ_TRANSACTION		2-1				//read consists of two phases - Address, Register then Address, DataIn

#define READ_REQ		1
#define WRITE_REQ		0

/**************************** Enums and Structures *********************************/
typedef struct
{
	unsigned char reg;
	unsigned char value;
}T_CameraInitParams;

/************************* OV7670 Register Definitions *****************************/

#define GAIN_CTRL_REG		0x00
#define BLUE_GAIN_REG		0x01
#define RED_GAIN_REG		0x02
#define VREF_CTRL_REG		0x03
#define CLKRC_CTRL_REG		0x11
#define COM7_CTRL_REG		0x12
#define COM15_CTRL_REG		0x40
#define DBLV_CTRL_REG		0x6B

/**************************** Exported Functions ***********************************/
int configure_SCCB(int DeviceId);
int SCCB_Write_Register(unsigned char writeData, unsigned char registerOffset, unsigned char requestType);
int SCCB_Read_Register(unsigned char * readData_ptr, unsigned char registerOffset);
int OV7670_Camera_Init(const T_CameraInitParams * ptr, unsigned char num);

/**************************** Exported Variables ***********************************/
extern const T_CameraInitParams C_CameraInitParams[];
extern const unsigned char C_NumOfInitParams;

#endif /* SRC_SCCB_H_ */
