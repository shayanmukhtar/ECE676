For a class project - 
Took the OV7670, coded the SCCB protocol off of the included I2C driver
Configured the camera with custom register settings

ON PL
Used hamster's OV7670 VGA and pixel capture
Implemented a real time low pass filter
Implemented a real time color filter
Implemented a real time object tracking IP which figures out object location, raises interrupt to PS side and stores P(x,y) of object in registers for CPU to read

Keywords: Zybo, OV7670, real time image processing, SCCB, ECE676
