/*
 * gpio.h
 *
 *  Created on: Apr 7, 2017
 *      Author: Shayan Mukhtar
 */

#ifndef SRC_GPIO_H_
#define SRC_GPIO_H_

/*Macros*/
#define INTC_DEVICE_ID		XPAR_SCUGIC_SINGLE_DEVICE_ID
#define NUM_BITS_THRESHOLD	6
#define MAX_THRESHOLD		(1 << NUM_BITS_THRESHOLD) - 1
#define FILTER_ADDR			XPAR_AXI_COLOR_FILTER_V1_0_0_BASEADDR
#define LOCATION_ADDR		XPAR_AXI_LOCATION_DETECTION_0_S00_AXI_BASEADDR
#define Red_Threshold		AXI_COLOR_FILTER_S00_AXI_SLV_REG0_OFFSET
#define Green_Threshold		AXI_COLOR_FILTER_S00_AXI_SLV_REG1_OFFSET
#define Blue_Threshold		AXI_COLOR_FILTER_S00_AXI_SLV_REG2_OFFSET
#define BTN_0_PRESSED(val)	(val & 0b0001)
#define BTN_1_PRESSED(val)	(val & 0b0010)
#define BTN_2_PRESSED(val)	(val & 0b0100)
#define BTN_3_PRESSED(val)  (val & 0b1000)

#define LOCATION_PIXEL_THRESHOLD		40u
#define SCREEN_WIDTH_COLS				320u
#define SCREEN_HEIGHT_ROWS				480u
#define COL_REG							4u
#define ROW_REG							8u

/*Structure and enumeration definitions*/
typedef enum
{
	No_Channel = 0b00,
	Red_Channel = 0b01,
	Green_Channel = 0b10,
	Blue_Channel = 0b11
}Te_ColorChannel;

typedef struct
{
	Te_ColorChannel color;
	unsigned long red_threshold : NUM_BITS_THRESHOLD;	//only 4 bits allowed for threshold
	unsigned long green_threshold : NUM_BITS_THRESHOLD;	//only 4 bits allowed for threshold
	unsigned long blue_threshold : NUM_BITS_THRESHOLD;	//only 4 bits allowed for threshold
	unsigned long current_choice : 2;
}Te_ColorSpaceFilter;

typedef struct
{
	unsigned int col;
	unsigned int row;
}Te_LocationDetectionIndication;

/*exported variables*/
extern Te_LocationDetectionIndication Ve_LocationDetectionIndication;

/*exported functions*/
int updateColorFilter(Te_ColorSpaceFilter * ptr);
int GPIO_Init(void);
int ColorFilter_Init(void);
int Detect_Location(Te_LocationDetectionIndication *ptr);
int Location_Detection_Init(Te_LocationDetectionIndication *ptr);
int Detect_Location(Te_LocationDetectionIndication *ptr);

/*standard parameter definitions*/

#define AXI_COLOR_FILTER_S00_AXI_SLV_REG0_OFFSET 0
#define AXI_COLOR_FILTER_S00_AXI_SLV_REG1_OFFSET 4
#define AXI_COLOR_FILTER_S00_AXI_SLV_REG2_OFFSET 8
#define AXI_COLOR_FILTER_S00_AXI_SLV_REG3_OFFSET 12
#define AXI_COLOR_FILTER_S00_AXI_SLV_REG4_OFFSET 16
#define AXI_COLOR_FILTER_S00_AXI_SLV_REG5_OFFSET 20


/**************************** Type Definitions *****************************/
/**
 *
 * Write a value to a AXI_COLOR_FILTER register. A 32 bit write is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is written.
 *
 * @param   BaseAddress is the base address of the AXI_COLOR_FILTERdevice.
 * @param   RegOffset is the register offset from the base to write to.
 * @param   Data is the data written to the register.
 *
 * @return  None.
 *
 * @note
 * C-style signature:
 * 	void AXI_COLOR_FILTER_mWriteReg(u32 BaseAddress, unsigned RegOffset, u32 Data)
 *
 */
#define AXI_COLOR_FILTER_mWriteReg(BaseAddress, RegOffset, Data) \
  	Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))

/**
 *
 * Read a value from a AXI_COLOR_FILTER register. A 32 bit read is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is read from the register. The most significant data
 * will be read as 0.
 *
 * @param   BaseAddress is the base address of the AXI_COLOR_FILTER device.
 * @param   RegOffset is the register offset from the base to write to.
 *
 * @return  Data is the data from the register.
 *
 * @note
 * C-style signature:
 * 	u32 AXI_COLOR_FILTER_mReadReg(u32 BaseAddress, unsigned RegOffset)
 *
 */
#define AXI_COLOR_FILTER_mReadReg(BaseAddress, RegOffset) \
    Xil_In32((BaseAddress) + (RegOffset))

#endif /* SRC_GPIO_H_ */
