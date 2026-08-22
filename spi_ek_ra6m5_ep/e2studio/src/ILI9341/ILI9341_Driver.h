/***********************************************************************************************************************
 * File Name    : ILI9341_Driver.h
 * Description  : Contains macro definitions and API declarations for controlling the ILI9341 TFT LCD using the
 *                Renesas RA SPI and GPIO interfaces.
 **********************************************************************************************************************/

#ifndef ILI9341_DRIVER_H_
#define ILI9341_DRIVER_H_

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/

// #include "hal_data.h"
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "bsp_pin_cfg.h"

/***********************************************************************************************************************
 * Macro definitions
 **********************************************************************************************************************/

#define ILI9341_SCREEN_HEIGHT   240 
#define ILI9341_SCREEN_WIDTH    320

/* CHIP SELECT PIN AND PORT, STANDARD GPIO */
#define LCD_SSLA3_C                             SSLA3_C_Pin

/* DATA COMMAND PIN AND PORT, STANDARD GPIO */
#define LCD_DC_PIN								DC_Pin

/* RESET PIN AND PORT, STANDARD GPIO */
#define	LCD_RESET_PIN						    RESET_Pin

/* Buffer color */
#define BURST_MAX_SIZE 	500

/* RGB565 colour values. */
#define BLACK                   (0x0000U)      
#define NAVY                    (0x000FU)      
#define DARKGREEN               (0x03E0U)      
#define DARKCYAN                (0x03EFU)      
#define MAROON                  (0x7800U)      
#define PURPLE                  (0x780FU)      
#define OLIVE                   (0x7BE0U)      
#define LIGHTGREY               (0xC618U)      
#define DARKGREY                (0x7BEFU)      
#define BLUE                    (0x001FU)      
#define GREEN                   (0x07E0U)      
#define CYAN                    (0x07FFU)      
#define RED                     (0xF800U)     
#define MAGENTA                 (0xF81FU)      
#define YELLOW                  (0xFFE0U)      
#define WHITE                   (0xFFFFU)      
#define ORANGE                  (0xFD20U)      
#define GREENYELLOW             (0xAFE5U)     
#define PINK                    (0xF81FU)

/* Supported display orientations. */
#define SCREEN_VERTICAL_1       (0x0U)
#define SCREEN_HORIZONTAL_1		(0x1U)
#define SCREEN_VERTICAL_2		(0x2U)
#define SCREEN_HORIZONTAL_2		(0x3U)

/***********************************************************************************************************************
 * User-defined APIs
 **********************************************************************************************************************/

fsp_err_t ILI9341_SPI_Init(void);
fsp_err_t ILI9341_SPI_Send(uint8_t SPI_Data);
fsp_err_t ILI9341_Write_Command(uint8_t command);
fsp_err_t ILI9341_Write_Data(uint8_t data);
fsp_err_t ILI9341_Set_Address(uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2);
fsp_err_t ILI9341_Reset(void);
fsp_err_t ILI9341_Set_Rotation(uint8_t rotation);
fsp_err_t ILI9341_Enable(void);
fsp_err_t ILI9341_Init(void);
fsp_err_t ILI9341_Draw_Colour(uint16_t Colour);
fsp_err_t ILI9341_Draw_Colour_Burst(uint16_t Colour, uint32_t Size);
fsp_err_t ILI9341_Fill_Screen(uint16_t Colour);
fsp_err_t ILI9341_Draw_Pixel(uint16_t X, uint16_t Y, uint16_t Colour);
fsp_err_t ILI9341_Draw_Rectangle(uint16_t X, uint16_t Y, uint16_t Width, uint16_t Height, uint16_t Colour);
fsp_err_t ILI9341_Draw_Horizontal_Line(uint16_t X, uint16_t Y, uint16_t Width, uint16_t Colour);
fsp_err_t ILI9341_Draw_Vertical_Line(uint16_t X, uint16_t Y, uint16_t Height, uint16_t Colour);

#endif /* ILI9341_DRIVER_H_ */
