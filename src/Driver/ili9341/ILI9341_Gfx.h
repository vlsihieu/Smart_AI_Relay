/*******************************************************************************************************************//**
 * @file ILI9341_GFX.h
 * @brief Declares graphics, text, shape, and RGB565 image APIs for the ILI9341 TFT LCD.
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

#define HORIZONTAL_IMAGE    (0U)
#define VERTICAL_IMAGE      (1U)

/*******************************************************************************************************************//**
 * @addtogroup ILI9341_GFX
 * @{
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Public API declarations
 **********************************************************************************************************************/

fsp_err_t ILI9341_Draw_Hollow_Circle(uint16_t X, uint16_t Y, uint16_t Radius, uint16_t Colour);
fsp_err_t ILI9341_Draw_Filled_Circle(uint16_t X, uint16_t Y, uint16_t Radius, uint16_t Colour);
fsp_err_t ILI9341_Draw_Hollow_Rectangle_Coord(uint16_t X0, uint16_t Y0, uint16_t X1, uint16_t Y1, uint16_t Colour);
fsp_err_t ILI9341_Draw_Filled_Rectangle_Coord(uint16_t X0, uint16_t Y0, uint16_t X1, uint16_t Y1, uint16_t Colour);
fsp_err_t ILI9341_Draw_Char(char Character,
                            uint8_t X,
                            uint8_t Y,
                            uint16_t Colour,
                            uint16_t Size,
                            uint16_t Background_Colour);
fsp_err_t ILI9341_Draw_Text(const char * Text,
                            uint8_t X,
                            uint8_t Y,
                            uint16_t Colour,
                            uint16_t Size,
                            uint16_t Background_Colour);
fsp_err_t ILI9341_Draw_Filled_Rectangle_Size_Text(uint16_t X0,
                                                  uint16_t Y0,
                                                  uint16_t Size_X,
                                                  uint16_t Size_Y,
                                                  uint16_t Colour);
fsp_err_t ILI9341_Draw_RGB565_Block(uint16_t X,
                                    uint16_t Y,
                                    uint16_t Width,
                                    uint16_t Height,
                                    uint16_t const * p_pixels);
fsp_err_t ILI9341_Draw_Image(const char * Image_Array, uint8_t Orientation);

/*******************************************************************************************************************//**
 * @} (end addtogroup ILI9341_GFX)
 **********************************************************************************************************************/

#endif /* ILI9341_GFX_H_ */