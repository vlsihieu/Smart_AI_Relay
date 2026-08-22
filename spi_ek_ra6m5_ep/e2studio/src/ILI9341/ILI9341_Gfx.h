/***********************************************************************************************************************
 * File Name    : ILI9341_GFX.h
 * Description  : Contains public API declarations for drawing graphics, text, shapes
 * and images on the ILI9341 TFT LCD.
 **********************************************************************************************************************/

#ifndef ILI9341_GFX_H_
#define ILI9341_GFX_H_

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/
#include <stdint.h>
#include "ILI9341_Driver.h"

/***********************************************************************************************************************
 * Macro definitions
 **********************************************************************************************************************/

#define HORIZONTAL_IMAGE	0
#define VERTICAL_IMAGE		1

/***********************************************************************************************************************
 * User-defined APIs
 **********************************************************************************************************************/

fsp_err_t ILI9341_Draw_Hollow_Circle(uint16_t X, uint16_t Y, uint16_t Radius, uint16_t Colour);
fsp_err_t ILI9341_Draw_Filled_Circle(uint16_t X, uint16_t Y, uint16_t Radius, uint16_t Colour);
fsp_err_t ILI9341_Draw_Hollow_Rectangle_Coord(uint16_t X0, uint16_t Y0, uint16_t X1, uint16_t Y1, uint16_t Colour);
fsp_err_t ILI9341_Draw_Filled_Rectangle_Coord(uint16_t X0, uint16_t Y0, uint16_t X1, uint16_t Y1, uint16_t Colour);
fsp_err_t ILI9341_Draw_Char(char Character, uint8_t X, uint8_t Y, uint16_t Colour, uint16_t Size, uint16_t Background_Colour);
fsp_err_t ILI9341_Draw_Text(const char* Text, uint8_t X, uint8_t Y, uint16_t Colour, uint16_t Size, uint16_t Background_Colour);
fsp_err_t ILI9341_Draw_Filled_Rectangle_Size_Text(uint16_t X0, uint16_t Y0, uint16_t Size_X, uint16_t Size_Y, uint16_t Colour);

//USING CONVERTER: http://www.digole.com/tools/PicturetoC_Hex_converter.php
//65K colour (2Bytes / Pixel)
fsp_err_t ILI9341_Draw_Image(const char* Image_Array, uint8_t Orientation);

/** @} */ /* End of group ILI9341_GFX */

#endif /* ILI9341_GFX_H_ */
