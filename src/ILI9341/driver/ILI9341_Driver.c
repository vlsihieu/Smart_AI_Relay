// /*******************************************************************************************************************//**
//  * @file ILI9341_Driver.c
//  * @brief Implements the ILI9341 LCD driver using the Renesas FSP SPI and IOPORT interfaces.
//  *
//  * This file provides LCD initialization, command and data transmission, screen rotation, address-window configuration,
//  * and basic drawing functions for an ILI9341 display connected to a Renesas RA microcontroller.
//  **********************************************************************************************************************/

// /***********************************************************************************************************************
//  * Includes
//  **********************************************************************************************************************/
// #include <stdbool.h>
// #include "ILI9341_Driver.h"
// #include "r_spi.h"
// #include "r_ioport.h"
// #include "common_utils.h"

// /***********************************************************************************************************************
//  * Macro definitions
//  **********************************************************************************************************************/

// /* SPI callback wait timeout in microseconds. */
// #define ILI9341_SPI_TIMEOUT_US    (100000U)

// /***********************************************************************************************************************
//  * Typedef definitions
//  **********************************************************************************************************************/

// /***********************************************************************************************************************
//  * Private function declarations
//  **********************************************************************************************************************/
// static fsp_err_t ili9341_spi_write_blocking(uint8_t const * p_data, uint32_t length);
// static fsp_err_t ili9341_spi_transaction(bsp_io_level_t dc_level, uint8_t const * p_data, uint32_t length);

// /***********************************************************************************************************************
//  * Private global variables
//  **********************************************************************************************************************/
// static volatile bool g_spi_transfer_complete = false;
// static volatile bool g_spi_transfer_error    = false;

// /***********************************************************************************************************************
//  * Global variables
//  **********************************************************************************************************************/
// volatile uint16_t LCD_HEIGHT = ILI9341_SCREEN_HEIGHT;
// volatile uint16_t LCD_WIDTH	 = ILI9341_SCREEN_WIDTH;

// /*******************************************************************************************************************//**
//  * @addtogroup ILI9341_Driver
//  * @{
//  **********************************************************************************************************************/

// /***********************************************************************************************************************
//  * Functions
//  **********************************************************************************************************************/

// /*******************************************************************************************************************//**
//  * @brief Opens the FSP SPI instance used by the ILI9341 LCD and initializes the chip-select level.
//  *
//  * @note The IOPORT instance and LCD control pins are configured by R_BSP_WarmStart(). Call this function only once.
//  *
//  * @retval FSP_SUCCESS SPI initialization completed successfully.
//  * @return Any other FSP error code returned by the SPI or IOPORT driver.
//  **********************************************************************************************************************/
// fsp_err_t ILI9341_SPI_Init(void)
// {
//     fsp_err_t err; 

//     /* Open the SPI master instance. */
//     err = R_SPI_Open (&g_spi_master_ctrl, &g_spi_master_cfg);

//     if (FSP_SUCCESS != err)
//     {
//         /* Report an SPI initialization failure. */
//         APP_ERR_PRINT("** R_SPI_Open API for SPI Master failed ** \r\n");
//         return err;
//     }

//     /* Deselect the LCD. CS is active LOW. */
//     err = R_IOPORT_PinWrite(&g_ioport_ctrl, LCD_SSLA3_C, BSP_IO_LEVEL_HIGH);

//     if (FSP_SUCCESS != err)
//     {
//         APP_ERR_PRINT("** LCD CS initialization failed **\r\n");
//         return err;
//     }

//     return FSP_SUCCESS;
// }

// /*******************************************************************************************************************//**
//  * @brief Transmits one byte to the ILI9341 LCD and waits for completion.
//  *
//  * @param[in] SPI_Data Byte to be transmitted.
//  *
//  * @retval FSP_SUCCESS SPI transmission completed successfully.
//  * @return Any other FSP error code returned by the SPI driver.
//  **********************************************************************************************************************/
// fsp_err_t  ILI9341_SPI_Send(uint8_t SPI_Data)
// {
//     return ili9341_spi_write_blocking(&SPI_Data, 1U);
// }

// /*******************************************************************************************************************//**
//  * @brief Sends one command byte to the ILI9341 LCD.
//  *
//  * @param[in] command Command byte to be transmitted.
//  *
//  * @retval FSP_SUCCESS Command transmitted successfully.
//  * @return Any other FSP error code returned by the IOPORT or SPI driver.
//  **********************************************************************************************************************/
// fsp_err_t ILI9341_Write_Command(uint8_t command)
// {
//     return ili9341_spi_transaction(BSP_IO_LEVEL_LOW, &command, 1U);
// }

// /*******************************************************************************************************************//**
//  * @brief Sends one data byte to the ILI9341 LCD.
//  *
//  * @param[in] data Data byte to be transmitted.
//  *
//  * @retval FSP_SUCCESS Data transmitted successfully.
//  * @return Any other FSP error code returned by the IOPORT or SPI driver.
//  **********************************************************************************************************************/
// fsp_err_t ILI9341_Write_Data(uint8_t data)
// {
//     return ili9341_spi_transaction(BSP_IO_LEVEL_HIGH, &data, 1U);
// }

// /*******************************************************************************************************************//**
//  * @brief Sets the rectangular LCD memory area for subsequent drawing.
//  *
//  * @param[in] x1 Starting X coordinate.
//  * @param[in] y1 Starting Y coordinate.
//  * @param[in] x2 Ending X coordinate.
//  * @param[in] y2 Ending Y coordinate.
//  *
//  * @retval FSP_SUCCESS              Address window configured successfully.
//  * @retval FSP_ERR_INVALID_ARGUMENT Address coordinates are invalid or outside the display area.
//  * @return Any other FSP error code returned by the LCD driver.
//  **********************************************************************************************************************/
// fsp_err_t ILI9341_Set_Address(uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2)
// {
//     fsp_err_t err;

//     /* Validate the inclusive address window. */
//     if ((x1 > x2) || (y1 > y2) || (x2 >= LCD_WIDTH) || (y2 >= LCD_HEIGHT))
//     {
//         return FSP_ERR_INVALID_ARGUMENT;
//     }

//     /* Column address set. */
//     err = ILI9341_Write_Command(0x2AU);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data((uint8_t) (x1 >> 8U));
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data((uint8_t) (x1 & 0xFFU));
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data((uint8_t) (x2 >> 8U));
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data((uint8_t) (x2 & 0xFFU));
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Page address set. */
//     err = ILI9341_Write_Command(0x2BU);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data((uint8_t) (y1 >> 8U));
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data((uint8_t) (y1 & 0xFFU));
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data((uint8_t) (y2 >> 8U));
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data((uint8_t) (y2 & 0xFFU));
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Memory write. */
//     err = ILI9341_Write_Command(0x2CU);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     return FSP_SUCCESS;
// }

// /*******************************************************************************************************************//**
//  * @brief Performs a hardware reset of the ILI9341 LCD.
//  *
//  * @retval FSP_SUCCESS LCD reset completed successfully.
//  * @return Any other FSP error code returned by the IOPORT driver.
//  **********************************************************************************************************************/
// fsp_err_t ILI9341_Reset(void)
// {
//     fsp_err_t err;

//     /* Deselect LCD before reset. */
//     err = R_IOPORT_PinWrite(&g_ioport_ctrl, LCD_SSLA3_C, BSP_IO_LEVEL_HIGH);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Assert hardware reset. */
//     err = R_IOPORT_PinWrite(&g_ioport_ctrl, LCD_RESET_PIN, BSP_IO_LEVEL_LOW);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
//     R_BSP_SoftwareDelay(200U, BSP_DELAY_UNITS_MILLISECONDS);

//     /* Release hardware reset. */
//     err = R_IOPORT_PinWrite(&g_ioport_ctrl, LCD_RESET_PIN, BSP_IO_LEVEL_HIGH);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Wait for the LCD controller to become ready. */
//     R_BSP_SoftwareDelay(200U, BSP_DELAY_UNITS_MILLISECONDS);

//     return FSP_SUCCESS;
// }

// /*******************************************************************************************************************//**
//  * @brief Configures the screen rotation and updates the LCD dimensions.
//  *
//  * @param[in] rotation Screen rotation mode.
//  *
//  * @retval FSP_SUCCESS              Screen rotation configured successfully.
//  * @retval FSP_ERR_INVALID_ARGUMENT Invalid screen rotation value.
//  * @return Any other FSP error code returned by the LCD driver.
//  **********************************************************************************************************************/
// fsp_err_t ILI9341_Set_Rotation(uint8_t rotation)
// {
//     fsp_err_t err;
//     uint8_t   madctl;
//     uint16_t  width;
//     uint16_t  height;

//     switch (rotation)
//     {
//         case SCREEN_VERTICAL_1:
//         {
//             madctl = (uint8_t) (0x40U | 0x08U);
//             width  = 240U;
//             height = 320U;
//             break;
//         }
//         case SCREEN_HORIZONTAL_1:
//         {
//             madctl = (uint8_t) (0x20U | 0x08U);
//             width  = 320U;
//             height = 240U;
//             break;
//         }
//         case SCREEN_VERTICAL_2:
//         {
//             madctl = (uint8_t) (0x80U | 0x08U);
//             width  = 240U;
//             height = 320U;
//             break;
//         }
//         case SCREEN_HORIZONTAL_2:
//         {
//             madctl = (uint8_t) (0x40U | 0x80U | 0x20U | 0x08U);
//             width  = 320U;
//             height = 240U;
//             break;
//         }
//         default:
//         {
//             /* Reject an unsupported screen rotation. */
//             return FSP_ERR_INVALID_ARGUMENT;
//         }
//     }

//     /* Memory Access Control command. */
//     err = ILI9341_Write_Command(0x36U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     R_BSP_SoftwareDelay(1U, BSP_DELAY_UNITS_MILLISECONDS);

//     /* Apply the selected screen orientation. */
//     err = ILI9341_Write_Data(madctl);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Update the logical display dimensions. */
//     LCD_WIDTH  = width;
//     LCD_HEIGHT = height;

//     return FSP_SUCCESS;
// }

// /*******************************************************************************************************************//**
//  * @brief Enables the ILI9341 LCD by releasing the hardware reset pin.
//  *
//  * @retval FSP_SUCCESS LCD enabled successfully.
//  * @return Any other FSP error code returned by the IOPORT driver.
//  **********************************************************************************************************************/
// fsp_err_t ILI9341_Enable(void)
// {
//     fsp_err_t err;
//     err = R_IOPORT_PinWrite(&g_ioport_ctrl, LCD_RESET_PIN, BSP_IO_LEVEL_HIGH);

//     if (FSP_SUCCESS != err)
//     {
//         return err;
//     }

//     return FSP_SUCCESS;
// }

// /*******************************************************************************************************************//**
//  * @brief Initializes the ILI9341 LCD controller.
//  *
//  * @retval FSP_SUCCESS LCD initialized successfully.
//  * @return Any other FSP error code returned by the LCD driver.
//  **********************************************************************************************************************/
// fsp_err_t ILI9341_Init(void)
// {
//     fsp_err_t err;

//     /* Initialize the SPI interface. */
//     err = ILI9341_SPI_Init();
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Enable the LCD. */
//     err = ILI9341_Enable();
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Perform hardware reset. */
//     err = ILI9341_Reset();
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Software reset. */
//     err = ILI9341_Write_Command(0x01U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     R_BSP_SoftwareDelay(1000U, BSP_DELAY_UNITS_MILLISECONDS);

//     /* Power control A. */
//     err = ILI9341_Write_Command(0xCBU);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x39U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x2CU);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x00U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x34U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x02U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Power control B. */
//     err = ILI9341_Write_Command(0xCFU);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x00U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0xC1U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x30U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Driver timing control A. */
//     err = ILI9341_Write_Command(0xE8U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x85U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x00U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x78U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Driver timing control B. */
//     err = ILI9341_Write_Command(0xEAU);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x00U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x00U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Power-on sequence control. */
//     err = ILI9341_Write_Command(0xEDU);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x64U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x03U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x12U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x81U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Pump ratio control. */
//     err = ILI9341_Write_Command(0xF7U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x20U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Power control, VRH[5:0]. */
//     err = ILI9341_Write_Command(0xC0U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x23U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Power control, SAP[2:0] and BT[3:0]. */
//     err = ILI9341_Write_Command(0xC1U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x10U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* VCM control. */
//     err = ILI9341_Write_Command(0xC5U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x3EU);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x28U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* VCM control 2. */
//     err = ILI9341_Write_Command(0xC7U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x86U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Memory access control. */
//     err = ILI9341_Write_Command(0x36U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x48U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Pixel format: RGB565. */
//     err = ILI9341_Write_Command(0x3AU);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x55U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Frame ratio control. */
//     err = ILI9341_Write_Command(0xB1U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x00U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x18U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Display function control. */
//     err = ILI9341_Write_Command(0xB6U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x08U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x82U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x27U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Disable 3-gamma function. */
//     err = ILI9341_Write_Command(0xF2U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x00U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Select gamma curve. */
//     err = ILI9341_Write_Command(0x26U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x01U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Positive gamma correction. */
//     err = ILI9341_Write_Command(0xE0U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x0FU);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x31U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x2BU);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x0CU);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x0EU);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x08U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x4EU);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0xF1U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x37U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x07U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x10U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x03U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x0EU);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x09U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x00U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Negative gamma correction. */
//     err = ILI9341_Write_Command(0xE1U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x00U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x0EU);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x14U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x03U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x11U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x07U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x31U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0xC1U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x48U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x08U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x0FU);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x0CU);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x31U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x36U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     err = ILI9341_Write_Data(0x0FU);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Exit sleep mode. */
//     err = ILI9341_Write_Command(0x11U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     R_BSP_SoftwareDelay(120U, BSP_DELAY_UNITS_MILLISECONDS);

//     /* Turn on the display. */
//     err = ILI9341_Write_Command(0x29U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Set the initial screen rotation. */
//     err = ILI9341_Set_Rotation(SCREEN_VERTICAL_1);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     return FSP_SUCCESS;
// }

// /*******************************************************************************************************************//**
//  * @brief Sends a single 16-bit color value to the ILI9341 LCD.
//  *
//  * @note This is an internal library function. Use ILI9341_Draw_Pixel()
//  *       instead where possible.
//  *
//  * @param[in] Colour 16-bit RGB565 color value.
//  *
//  * @retval FSP_SUCCESS Color data transmitted successfully.
//  * @return Any other FSP error code returned by the IOPORT or SPI driver.
//  **********************************************************************************************************************/
// fsp_err_t ILI9341_Draw_Colour(uint16_t Colour)
// {
//     uint8_t temp_buffer[2] = {(uint8_t) (Colour >> 8U), (uint8_t) (Colour & 0xFFU)};

//     return ili9341_spi_transaction(BSP_IO_LEVEL_HIGH, temp_buffer, 2U);
// }

// /*******************************************************************************************************************//**
//  * @brief Sends a block of one repeated color to the ILI9341 LCD.
//  *
//  * @note This is an internal library function.
//  *
//  * @param[in] Colour 16-bit RGB565 color value.
//  * @param[in] Size   Number of pixels to be transmitted.
//  *
//  * @retval FSP_SUCCESS              Color block transmitted successfully.
//  * @retval FSP_ERR_INVALID_ARGUMENT BURST_MAX_SIZE is invalid.
//  * @return Any other FSP error code returned by the IOPORT or SPI driver.
//  **********************************************************************************************************************/
// fsp_err_t ILI9341_Draw_Colour_Burst(uint16_t Colour, uint32_t Size)
// {
//     fsp_err_t err;
//     uint32_t  pixels_per_block;
//     uint32_t  current_pixels;
//     uint32_t  transfer_size;
//     uint32_t  remaining_pixels;
//     uint32_t  index;
//     uint8_t   colour_high;
//     uint8_t   colour_low;
//     uint8_t   burst_buffer[BURST_MAX_SIZE];

//     /* No pixel data needs to be transmitted. */
//     if (0U == Size)
//     {
//         return FSP_SUCCESS;
//     }

//     /*
//      * Calculate the maximum number of RGB565 pixels that can be stored
//      * in the transmission buffer. Each pixel requires two bytes.
//      */
//     pixels_per_block = BURST_MAX_SIZE / 2U;

//     if (0U == pixels_per_block)
//     {
//         return FSP_ERR_INVALID_ARGUMENT;
//     }

//     /* Limit the block size when all pixels fit inside one block. */
//     if (pixels_per_block > Size)
//     {
//         pixels_per_block = Size;
//     }

//     /* Split the RGB565 color into high and low bytes. */
//     colour_high = (uint8_t) (Colour >> 8U);
//     colour_low  = (uint8_t) (Colour & 0xFFU);

//     /* Fill the transmission buffer with the repeated color value. */
//     for (index = 0U; index < pixels_per_block; index++)
//     {
//         burst_buffer[index * 2U]      = colour_high;
//         burst_buffer[index * 2U + 1U] = colour_low;
//     }

//     /* Select LCD data mode. */
//     err = R_IOPORT_PinWrite(&g_ioport_ctrl, LCD_DC_PIN, BSP_IO_LEVEL_HIGH);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Select the LCD. CS is active LOW. */
//     err = R_IOPORT_PinWrite(&g_ioport_ctrl, LCD_SSLA3_C, BSP_IO_LEVEL_LOW);

//     if (FSP_SUCCESS != err)
//     {
//         (void) R_IOPORT_PinWrite(&g_ioport_ctrl, LCD_SSLA3_C, BSP_IO_LEVEL_HIGH);
//         return err;
//     }

//     remaining_pixels = Size;

//     /* Send the color data in blocks. */
//     while (remaining_pixels > 0U)
//     {
//         /* Determine the number of pixels in the current block. */
//         if (remaining_pixels > pixels_per_block)
//         {
//             current_pixels = pixels_per_block;
//         }
//         else
//         {
//             current_pixels = remaining_pixels;
//         }

//         /* Convert the pixel count to the number of SPI bytes. */
//         transfer_size = current_pixels * 2U;

//         err = ili9341_spi_write_blocking(burst_buffer, transfer_size);

//         if (FSP_SUCCESS != err)
//         {
//             /* Always release the LCD when a transfer fails or times out. */
//             (void) R_IOPORT_PinWrite(&g_ioport_ctrl, LCD_SSLA3_C, BSP_IO_LEVEL_HIGH);
//             return err;
//         }

//         remaining_pixels -= current_pixels;

//     }

//     /* Deselect the LCD after all blocks have been transmitted. */
//     err = R_IOPORT_PinWrite(&g_ioport_ctrl, LCD_SSLA3_C,
//             BSP_IO_LEVEL_HIGH);

//     return err;
// }

// /*******************************************************************************************************************//**
//  * @brief Fills the entire LCD screen with the selected color.
//  *
//  * @param[in] Colour 16-bit RGB565 color value.
//  *
//  * @retval FSP_SUCCESS              Screen filled successfully.
//  * @retval FSP_ERR_INVALID_ARGUMENT The current display dimensions are invalid.
//  * @return Any other FSP error code returned by the LCD driver.
//  **********************************************************************************************************************/
// fsp_err_t ILI9341_Fill_Screen(uint16_t Colour)
// {
//     fsp_err_t err;

//     if ((0U == LCD_WIDTH) || (0U == LCD_HEIGHT))
//     {
//         return FSP_ERR_INVALID_ARGUMENT;
//     }

//     /* Set the drawing area to the entire LCD screen. */
//     err = ILI9341_Set_Address(0U, 0U,
//                              (uint16_t) (LCD_WIDTH - 1U),
//                              (uint16_t) (LCD_HEIGHT - 1U));
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Fill every pixel with the selected color. */
//     err = ILI9341_Draw_Colour_Burst(Colour, (uint32_t) LCD_WIDTH * (uint32_t) LCD_HEIGHT);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     return FSP_SUCCESS;
// }

// /*******************************************************************************************************************//**
//  * @brief Draws one pixel at the specified screen coordinate.
//  *
//  * @param[in] X      Horizontal pixel coordinate.
//  * @param[in] Y      Vertical pixel coordinate.
//  * @param[in] Colour 16-bit RGB565 color value.
//  *
//  * @retval FSP_SUCCESS              Pixel drawn successfully.
//  * @retval FSP_ERR_INVALID_ARGUMENT Coordinate is outside the display area.
//  * @return Any other FSP error code returned by the IOPORT or SPI driver.
//  **********************************************************************************************************************/
// fsp_err_t ILI9341_Draw_Pixel(uint16_t X, uint16_t Y, uint16_t Colour)
// {
//     fsp_err_t err;
//     uint8_t   column_command = 0x2AU;
//     uint8_t   page_command   = 0x2BU;
//     uint8_t   write_command  = 0x2CU;
//     uint8_t   temp_buffer_x[4] = {(uint8_t) (X >> 8U), (uint8_t) X,
//                                   (uint8_t) (X >> 8U), (uint8_t) X};
//     uint8_t   temp_buffer_y[4] = {(uint8_t) (Y >> 8U), (uint8_t) Y,
//                                   (uint8_t) (Y >> 8U), (uint8_t) Y};
//     uint8_t   temp_buffer_colour[2] = {(uint8_t) (Colour >> 8U), (uint8_t) (Colour & 0xFFU)};

//     /* Check whether the coordinate is outside the display area. */
//     if ((X >= LCD_WIDTH) || (Y >= LCD_HEIGHT))
//     {
//         return FSP_ERR_INVALID_ARGUMENT;
//     }

//     /* Send the column address command and data. */
//     err = ili9341_spi_transaction(BSP_IO_LEVEL_LOW, &column_command, 1U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
//     err = ili9341_spi_transaction(BSP_IO_LEVEL_HIGH, temp_buffer_x, 4U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Send the page address command and data. */
//     err = ili9341_spi_transaction(BSP_IO_LEVEL_LOW, &page_command, 1U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
//     err = ili9341_spi_transaction(BSP_IO_LEVEL_HIGH, temp_buffer_y, 4U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Send the memory write command and pixel color. */
//     err = ili9341_spi_transaction(BSP_IO_LEVEL_LOW, &write_command, 1U);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
//     return ili9341_spi_transaction(BSP_IO_LEVEL_HIGH, temp_buffer_colour, 2U);
// }

// /*******************************************************************************************************************//**
//  * @brief Draws a filled rectangle using the selected color.
//  *
//  * @param[in] X      X coordinate of the upper-left corner.
//  * @param[in] Y      Y coordinate of the upper-left corner.
//  * @param[in] Width  Rectangle width in pixels.
//  * @param[in] Height Rectangle height in pixels.
//  * @param[in] Colour 16-bit RGB565 color value.
//  *
//  * @retval FSP_SUCCESS              Rectangle drawn successfully.
//  * @retval FSP_ERR_INVALID_ARGUMENT Position or dimensions are invalid.
//  * @return Any other FSP error code returned by the LCD driver.
//  **********************************************************************************************************************/
// fsp_err_t ILI9341_Draw_Rectangle(uint16_t X, uint16_t Y, uint16_t Width, uint16_t Height, uint16_t Colour)
// {
//     fsp_err_t err;

//     /* Validate the starting position and rectangle dimensions. */
//     if ((X >= LCD_WIDTH) || (Y >= LCD_HEIGHT) ||
//         (0U == Width) || (0U == Height))
//     {
//         return FSP_ERR_INVALID_ARGUMENT;
//     }

//     /* Clip the rectangle width at the right edge of the LCD. */
//     if (Width > (uint16_t) (LCD_WIDTH - X))
//     {
//         Width = (uint16_t) (LCD_WIDTH - X);
//     }

//     /* Clip the rectangle height at the bottom edge of the LCD. */
//     if (Height > (uint16_t) (LCD_HEIGHT - Y))
//     {
//         Height = (uint16_t) (LCD_HEIGHT - Y);
//     }

//     /* Set the rectangular drawing area. */
//     err = ILI9341_Set_Address(X, Y, (uint16_t) (X + Width - 1U), (uint16_t) (Y + Height - 1U));
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Fill the selected rectangle. */
//     err = ILI9341_Draw_Colour_Burst(Colour, (uint32_t) Width * (uint32_t) Height);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     return FSP_SUCCESS;
// }

// /*******************************************************************************************************************//**
//  * @brief Draws a horizontal line using the selected color.
//  *
//  * @param[in] X      Starting X coordinate.
//  * @param[in] Y      Starting Y coordinate.
//  * @param[in] Width  Line width in pixels.
//  * @param[in] Colour 16-bit RGB565 color value.
//  *
//  * @retval FSP_SUCCESS              Horizontal line drawn successfully.
//  * @retval FSP_ERR_INVALID_ARGUMENT Position or width is invalid.
//  * @return Any other FSP error code returned by the LCD driver.
//  **********************************************************************************************************************/
// fsp_err_t ILI9341_Draw_Horizontal_Line(uint16_t X, uint16_t Y, uint16_t Width, uint16_t Colour)
// {
//     fsp_err_t err;

//     /* Validate the starting position and line width. */
//     if ((X >= LCD_WIDTH) || (Y >= LCD_HEIGHT) || (0U == Width))
//     {
//         return FSP_ERR_INVALID_ARGUMENT;
//     }

//     /* Clip the line at the right edge of the LCD. */
//     if (Width > (uint16_t) (LCD_WIDTH - X))
//     {
//         Width = (uint16_t) (LCD_WIDTH - X);
//     }

//     /* Set the horizontal drawing area. */
//     err = ILI9341_Set_Address(X, Y, (uint16_t) (X + Width - 1U), Y);
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Fill the horizontal line. */
//     return ILI9341_Draw_Colour_Burst(Colour, Width);
// }

// /*******************************************************************************************************************//**
//  * @brief Draws a vertical line using the selected color.
//  *
//  * @param[in] X      Starting X coordinate.
//  * @param[in] Y      Starting Y coordinate.
//  * @param[in] Height Line height in pixels.
//  * @param[in] Colour 16-bit RGB565 color value.
//  *
//  * @retval FSP_SUCCESS              Vertical line drawn successfully.
//  * @retval FSP_ERR_INVALID_ARGUMENT Position or height is invalid.
//  * @return Any other FSP error code returned by the LCD driver.
//  **********************************************************************************************************************/
// fsp_err_t ILI9341_Draw_Vertical_Line(uint16_t X, uint16_t Y, uint16_t Height, uint16_t Colour)
// {
//     fsp_err_t err;

//     /* Validate the starting position and line height. */
//     if ((X >= LCD_WIDTH) || (Y >= LCD_HEIGHT) || (0U == Height))
//     {
//         return FSP_ERR_INVALID_ARGUMENT;
//     }

//     /* Clip the line at the bottom edge of the LCD. */
//     if (Height > (uint16_t) (LCD_HEIGHT - Y))
//     {
//         Height = (uint16_t) (LCD_HEIGHT - Y);
//     }

//     /* Set the vertical drawing area. */
//     err = ILI9341_Set_Address(X, Y, X, (uint16_t) (Y + Height - 1U));
//     FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

//     /* Fill the vertical line. */
//     return ILI9341_Draw_Colour_Burst(Colour, Height);
// }

// /*******************************************************************************************************************//**
//  * @brief Updates the transfer status flags when an SPI event occurs.
//  *
//  * @param[in] p_args Pointer to the SPI callback arguments.
//  *
//  * @retval None
//  **********************************************************************************************************************/
// void spi_master_callback(spi_callback_args_t * p_args)
// {
//     if (NULL == p_args)
//     {
//         g_spi_transfer_error = true;
//     }
//     else if (SPI_EVENT_TRANSFER_COMPLETE == p_args->event)
//     {
//         g_spi_transfer_complete = true;
//     }
//     else
//     {
//         g_spi_transfer_error = true;
//     }
// }

// /*******************************************************************************************************************//**
//  * @brief Starts an SPI transmission and waits for the transfer-complete callback.
//  *
//  * @note Configure spi_master_callback in the FSP SPI stack and enable the SPI interrupts.
//  *
//  * @param[in] p_data Pointer to the transmit buffer.
//  * @param[in] length Number of bytes to transmit.
//  *
//  * @retval FSP_SUCCESS              SPI transmission completed successfully.
//  * @retval FSP_ERR_INVALID_ARGUMENT The transmit buffer is NULL or the length is zero.
//  * @retval FSP_ERR_ABORTED          The SPI callback reported an error event.
//  * @retval FSP_ERR_TIMEOUT          The transfer-complete callback was not received before the timeout expired.
//  * @return Any other FSP error code returned by R_SPI_Write().
//  **********************************************************************************************************************/
// static fsp_err_t ili9341_spi_write_blocking(uint8_t const * p_data, uint32_t length)
// {
//     fsp_err_t err;
//     uint32_t  timeout_us = ILI9341_SPI_TIMEOUT_US;

//     if ((NULL == p_data) || (0U == length))
//     {
//         return FSP_ERR_INVALID_ARGUMENT;
//     }

//     /* Clear the status flags before starting a new transfer. */
//     g_spi_transfer_complete = false;
//     g_spi_transfer_error    = false;

//     err = R_SPI_Write(&g_spi_master_ctrl, p_data, length, SPI_BIT_WIDTH_8_BITS);

//     if (FSP_SUCCESS != err)
//     {
//         return err;
//     }

//     /* Wait until the SPI callback reports completion or an error. */
//     while ((!g_spi_transfer_complete) && (!g_spi_transfer_error))
//     {
//         if (0U == timeout_us)
//         {
//             return FSP_ERR_TIMEOUT;
//         }

//         R_BSP_SoftwareDelay(1U, BSP_DELAY_UNITS_MICROSECONDS);
//         timeout_us--;
//     }

//     if (g_spi_transfer_error)
//     {
//         return FSP_ERR_ABORTED;
//     }

//     return FSP_SUCCESS;
// }

// /*******************************************************************************************************************//**
//  * @brief Sends one command or data transaction and always releases the LCD chip-select pin.
//  *
//  * @param[in] dc_level Command/data pin level for this transaction.
//  * @param[in] p_data   Pointer to the transmit buffer.
//  * @param[in] length   Number of bytes to transmit.
//  *
//  * @retval FSP_SUCCESS              Transaction completed successfully.
//  * @retval FSP_ERR_INVALID_ARGUMENT The transmit buffer is NULL or the length is zero.
//  * @return Any other FSP error code returned by the IOPORT or SPI driver.
//  **********************************************************************************************************************/
// static fsp_err_t ili9341_spi_transaction(bsp_io_level_t dc_level, uint8_t const * p_data, uint32_t length)
// {
//     fsp_err_t err;
//     fsp_err_t cs_err;

//     if ((NULL == p_data) || (0U == length))
//     {
//         return FSP_ERR_INVALID_ARGUMENT;
//     }

//     /* Select command or data mode before asserting chip select. */
//     err = R_IOPORT_PinWrite(&g_ioport_ctrl, LCD_DC_PIN, dc_level);

//     if (FSP_SUCCESS != err)
//     {
//         return err;
//     }

//     /* Select the LCD. CS is active LOW. */
//     err = R_IOPORT_PinWrite(&g_ioport_ctrl, LCD_SSLA3_C, BSP_IO_LEVEL_LOW);

//     if (FSP_SUCCESS != err)
//     {
//         (void) R_IOPORT_PinWrite(&g_ioport_ctrl, LCD_SSLA3_C, BSP_IO_LEVEL_HIGH);
//         return err;
//     }

//     err = ili9341_spi_write_blocking(p_data, length);

//     /* Always release the LCD, including after an SPI error or timeout. */
//     cs_err = R_IOPORT_PinWrite(&g_ioport_ctrl, LCD_SSLA3_C, BSP_IO_LEVEL_HIGH);

//     if (FSP_SUCCESS != err)
//     {
//         return err;
//     }

//     return cs_err;
// }

// /*******************************************************************************************************************//**
//  * @} (end addtogroup ILI9341_Driver)
//  **********************************************************************************************************************/


/*******************************************************************************************************************//**
 * @file ILI9341_Driver.c
 * @brief Implements the ILI9341 LCD driver using the Renesas FSP SPI and IOPORT interfaces.
 *
 * This file provides LCD initialization, command and data transmission, screen rotation, address-window configuration,
 * and basic drawing functions for an ILI9341 display connected to a Renesas RA microcontroller.
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/
#include <stdbool.h>
#include "ILI9341_Driver.h"
#include "r_spi.h"
#include "r_ioport.h"
#include "common_utils.h"

/***********************************************************************************************************************
 * Macro definitions
 **********************************************************************************************************************/

/* SPI callback wait timeout in microseconds. */
#define ILI9341_SPI_TIMEOUT_US    (100000U)

/***********************************************************************************************************************
 * Typedef definitions
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Private function declarations
 **********************************************************************************************************************/
static fsp_err_t ili9341_spi_write_blocking(uint8_t const * p_data, uint32_t length);
static fsp_err_t ili9341_spi_transaction(bsp_io_level_t dc_level, uint8_t const * p_data, uint32_t length);

/***********************************************************************************************************************
 * Private global variables
 **********************************************************************************************************************/
static volatile bool g_spi_transfer_complete = false;
static volatile bool g_spi_transfer_error    = false;

/***********************************************************************************************************************
 * Global variables
 **********************************************************************************************************************/
volatile uint16_t LCD_HEIGHT = ILI9341_SCREEN_HEIGHT;
volatile uint16_t LCD_WIDTH	 = ILI9341_SCREEN_WIDTH;

/*******************************************************************************************************************//**
 * @addtogroup ILI9341_Driver
 * @{
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Functions
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * @brief Opens the FSP SPI instance used by the ILI9341 LCD and initializes the chip-select level.
 *
 * @note The IOPORT instance and LCD control pins are configured by R_BSP_WarmStart(). Call this function only once.
 *
 * @retval FSP_SUCCESS SPI initialization completed successfully.
 * @return Any other FSP error code returned by the SPI or IOPORT driver.
 **********************************************************************************************************************/
fsp_err_t ILI9341_SPI_Init(void)
{
    fsp_err_t err; 

    /* Open the SPI master instance. */
    err = R_SPI_Open (&g_spi_master_ctrl, &g_spi_master_cfg);

    if (FSP_SUCCESS != err)
    {
        /* Report an SPI initialization failure. */
        APP_ERR_PRINT("** R_SPI_Open API for SPI Master failed ** \r\n");
        return err;
    }

    /* Deselect the LCD. CS is active LOW. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, LCD_SSLA3_C, BSP_IO_LEVEL_HIGH);

    if (FSP_SUCCESS != err)
    {
        APP_ERR_PRINT("** LCD CS initialization failed **\r\n");
        return err;
    }

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Transmits one byte to the ILI9341 LCD and waits for completion.
 *
 * @param[in] SPI_Data Byte to be transmitted.
 *
 * @retval FSP_SUCCESS SPI transmission completed successfully.
 * @return Any other FSP error code returned by the SPI driver.
 **********************************************************************************************************************/
fsp_err_t  ILI9341_SPI_Send(uint8_t SPI_Data)
{
    return ili9341_spi_write_blocking(&SPI_Data, 1U);
}

/*******************************************************************************************************************//**
 * @brief Transmits a data buffer to the ILI9341 LCD and waits for completion.
 *
 * This API is intended for graphics functions that need to transmit multiple bytes while keeping the LCD selected.
 * The caller is responsible for configuring the DC and CS pins before and after calling this function.
 *
 * @param[in] p_data Pointer to the transmit buffer.
 * @param[in] length Number of bytes to transmit.
 *
 * @retval FSP_SUCCESS              Transmission completed successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT The transmit buffer is NULL or the length is zero.
 * @return Any other FSP error code returned by the SPI driver.
 **********************************************************************************************************************/
fsp_err_t ILI9341_SPI_Write_Buffer(uint8_t const * p_data, uint32_t length)
{
    return ili9341_spi_write_blocking(p_data, length);
}

/*******************************************************************************************************************//**
 * @brief Sends one command byte to the ILI9341 LCD.
 *
 * @param[in] command Command byte to be transmitted.
 *
 * @retval FSP_SUCCESS Command transmitted successfully.
 * @return Any other FSP error code returned by the IOPORT or SPI driver.
 **********************************************************************************************************************/
fsp_err_t ILI9341_Write_Command(uint8_t command)
{
    return ili9341_spi_transaction(BSP_IO_LEVEL_LOW, &command, 1U);
}

/*******************************************************************************************************************//**
 * @brief Sends one data byte to the ILI9341 LCD.
 *
 * @param[in] data Data byte to be transmitted.
 *
 * @retval FSP_SUCCESS Data transmitted successfully.
 * @return Any other FSP error code returned by the IOPORT or SPI driver.
 **********************************************************************************************************************/
fsp_err_t ILI9341_Write_Data(uint8_t data)
{
    return ili9341_spi_transaction(BSP_IO_LEVEL_HIGH, &data, 1U);
}

/*******************************************************************************************************************//**
 * @brief Sets the rectangular LCD memory area for subsequent drawing.
 *
 * @param[in] x1 Starting X coordinate.
 * @param[in] y1 Starting Y coordinate.
 * @param[in] x2 Ending X coordinate.
 * @param[in] y2 Ending Y coordinate.
 *
 * @retval FSP_SUCCESS              Address window configured successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT Address coordinates are invalid or outside the display area.
 * @return Any other FSP error code returned by the LCD driver.
 **********************************************************************************************************************/
fsp_err_t ILI9341_Set_Address(uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2)
{
    fsp_err_t err;

    /* Validate the inclusive address window. */
    if ((x1 > x2) || (y1 > y2) || (x2 >= LCD_WIDTH) || (y2 >= LCD_HEIGHT))
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    /* Column address set. */
    err = ILI9341_Write_Command(0x2AU);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data((uint8_t) (x1 >> 8U));
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data((uint8_t) (x1 & 0xFFU));
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data((uint8_t) (x2 >> 8U));
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data((uint8_t) (x2 & 0xFFU));
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Page address set. */
    err = ILI9341_Write_Command(0x2BU);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data((uint8_t) (y1 >> 8U));
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data((uint8_t) (y1 & 0xFFU));
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data((uint8_t) (y2 >> 8U));
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data((uint8_t) (y2 & 0xFFU));
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Memory write. */
    err = ILI9341_Write_Command(0x2CU);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Performs a hardware reset of the ILI9341 LCD.
 *
 * @retval FSP_SUCCESS LCD reset completed successfully.
 * @return Any other FSP error code returned by the IOPORT driver.
 **********************************************************************************************************************/
fsp_err_t ILI9341_Reset(void)
{
    fsp_err_t err;

    /* Deselect LCD before reset. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, LCD_SSLA3_C, BSP_IO_LEVEL_HIGH);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Assert hardware reset. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, LCD_RESET_PIN, BSP_IO_LEVEL_LOW);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    R_BSP_SoftwareDelay(200U, BSP_DELAY_UNITS_MILLISECONDS);

    /* Release hardware reset. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, LCD_RESET_PIN, BSP_IO_LEVEL_HIGH);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Wait for the LCD controller to become ready. */
    R_BSP_SoftwareDelay(200U, BSP_DELAY_UNITS_MILLISECONDS);

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Configures the screen rotation and updates the LCD dimensions.
 *
 * @param[in] rotation Screen rotation mode.
 *
 * @retval FSP_SUCCESS              Screen rotation configured successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT Invalid screen rotation value.
 * @return Any other FSP error code returned by the LCD driver.
 **********************************************************************************************************************/
fsp_err_t ILI9341_Set_Rotation(uint8_t rotation)
{
    fsp_err_t err;
    uint8_t   madctl;
    uint16_t  width;
    uint16_t  height;

    switch (rotation)
    {
        case SCREEN_VERTICAL_1:
        {
            madctl = (uint8_t) (0x40U | 0x08U);
            width  = 240U;
            height = 320U;
            break;
        }
        case SCREEN_HORIZONTAL_1:
        {
            madctl = (uint8_t) (0x20U | 0x08U);
            width  = 320U;
            height = 240U;
            break;
        }
        case SCREEN_VERTICAL_2:
        {
            madctl = (uint8_t) (0x80U | 0x08U);
            width  = 240U;
            height = 320U;
            break;
        }
        case SCREEN_HORIZONTAL_2:
        {
            madctl = (uint8_t) (0x40U | 0x80U | 0x20U | 0x08U);
            width  = 320U;
            height = 240U;
            break;
        }
        default:
        {
            /* Reject an unsupported screen rotation. */
            return FSP_ERR_INVALID_ARGUMENT;
        }
    }

    /* Memory Access Control command. */
    err = ILI9341_Write_Command(0x36U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    R_BSP_SoftwareDelay(1U, BSP_DELAY_UNITS_MILLISECONDS);

    /* Apply the selected screen orientation. */
    err = ILI9341_Write_Data(madctl);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Update the logical display dimensions. */
    LCD_WIDTH  = width;
    LCD_HEIGHT = height;

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Enables the ILI9341 LCD by releasing the hardware reset pin.
 *
 * @retval FSP_SUCCESS LCD enabled successfully.
 * @return Any other FSP error code returned by the IOPORT driver.
 **********************************************************************************************************************/
fsp_err_t ILI9341_Enable(void)
{
    fsp_err_t err;
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, LCD_RESET_PIN, BSP_IO_LEVEL_HIGH);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Initializes the ILI9341 LCD controller.
 *
 * @retval FSP_SUCCESS LCD initialized successfully.
 * @return Any other FSP error code returned by the LCD driver.
 **********************************************************************************************************************/
fsp_err_t ILI9341_Init(void)
{
    fsp_err_t err;

    /* Initialize the SPI interface. */
    err = ILI9341_SPI_Init();
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Enable the LCD. */
    err = ILI9341_Enable();
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Perform hardware reset. */
    err = ILI9341_Reset();
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Software reset. */
    err = ILI9341_Write_Command(0x01U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    R_BSP_SoftwareDelay(1000U, BSP_DELAY_UNITS_MILLISECONDS);

    /* Power control A. */
    err = ILI9341_Write_Command(0xCBU);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x39U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x2CU);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x00U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x34U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x02U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Power control B. */
    err = ILI9341_Write_Command(0xCFU);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x00U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0xC1U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x30U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Driver timing control A. */
    err = ILI9341_Write_Command(0xE8U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x85U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x00U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x78U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Driver timing control B. */
    err = ILI9341_Write_Command(0xEAU);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x00U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x00U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Power-on sequence control. */
    err = ILI9341_Write_Command(0xEDU);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x64U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x03U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x12U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x81U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Pump ratio control. */
    err = ILI9341_Write_Command(0xF7U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x20U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Power control, VRH[5:0]. */
    err = ILI9341_Write_Command(0xC0U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x23U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Power control, SAP[2:0] and BT[3:0]. */
    err = ILI9341_Write_Command(0xC1U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x10U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* VCM control. */
    err = ILI9341_Write_Command(0xC5U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x3EU);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x28U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* VCM control 2. */
    err = ILI9341_Write_Command(0xC7U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x86U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Memory access control. */
    err = ILI9341_Write_Command(0x36U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x48U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Pixel format: RGB565. */
    err = ILI9341_Write_Command(0x3AU);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x55U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Frame ratio control. */
    err = ILI9341_Write_Command(0xB1U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x00U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x18U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Display function control. */
    err = ILI9341_Write_Command(0xB6U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x08U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x82U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x27U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Disable 3-gamma function. */
    err = ILI9341_Write_Command(0xF2U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x00U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Select gamma curve. */
    err = ILI9341_Write_Command(0x26U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x01U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Positive gamma correction. */
    err = ILI9341_Write_Command(0xE0U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x0FU);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x31U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x2BU);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x0CU);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x0EU);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x08U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x4EU);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0xF1U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x37U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x07U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x10U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x03U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x0EU);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x09U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x00U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Negative gamma correction. */
    err = ILI9341_Write_Command(0xE1U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x00U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x0EU);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x14U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x03U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x11U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x07U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x31U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0xC1U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x48U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x08U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x0FU);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x0CU);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x31U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x36U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    err = ILI9341_Write_Data(0x0FU);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Exit sleep mode. */
    err = ILI9341_Write_Command(0x11U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    R_BSP_SoftwareDelay(120U, BSP_DELAY_UNITS_MILLISECONDS);

    /* Turn on the display. */
    err = ILI9341_Write_Command(0x29U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Set the initial screen rotation. */
    err = ILI9341_Set_Rotation(SCREEN_VERTICAL_1);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Sends a single 16-bit color value to the ILI9341 LCD.
 *
 * @note This is an internal library function. Use ILI9341_Draw_Pixel()
 *       instead where possible.
 *
 * @param[in] Colour 16-bit RGB565 color value.
 *
 * @retval FSP_SUCCESS Color data transmitted successfully.
 * @return Any other FSP error code returned by the IOPORT or SPI driver.
 **********************************************************************************************************************/
fsp_err_t ILI9341_Draw_Colour(uint16_t Colour)
{
    uint8_t temp_buffer[2] = {(uint8_t) (Colour >> 8U), (uint8_t) (Colour & 0xFFU)};

    return ili9341_spi_transaction(BSP_IO_LEVEL_HIGH, temp_buffer, 2U);
}

/*******************************************************************************************************************//**
 * @brief Sends a block of one repeated color to the ILI9341 LCD.
 *
 * @note This is an internal library function.
 *
 * @param[in] Colour 16-bit RGB565 color value.
 * @param[in] Size   Number of pixels to be transmitted.
 *
 * @retval FSP_SUCCESS              Color block transmitted successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT BURST_MAX_SIZE is invalid.
 * @return Any other FSP error code returned by the IOPORT or SPI driver.
 **********************************************************************************************************************/
fsp_err_t ILI9341_Draw_Colour_Burst(uint16_t Colour, uint32_t Size)
{
    fsp_err_t err;
    uint32_t  pixels_per_block;
    uint32_t  current_pixels;
    uint32_t  transfer_size;
    uint32_t  remaining_pixels;
    uint32_t  index;
    uint8_t   colour_high;
    uint8_t   colour_low;
    uint8_t   burst_buffer[BURST_MAX_SIZE];

    /* No pixel data needs to be transmitted. */
    if (0U == Size)
    {
        return FSP_SUCCESS;
    }

    /*
     * Calculate the maximum number of RGB565 pixels that can be stored
     * in the transmission buffer. Each pixel requires two bytes.
     */
    pixels_per_block = BURST_MAX_SIZE / 2U;

    if (0U == pixels_per_block)
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    /* Limit the block size when all pixels fit inside one block. */
    if (pixels_per_block > Size)
    {
        pixels_per_block = Size;
    }

    /* Split the RGB565 color into high and low bytes. */
    colour_high = (uint8_t) (Colour >> 8U);
    colour_low  = (uint8_t) (Colour & 0xFFU);

    /* Fill the transmission buffer with the repeated color value. */
    for (index = 0U; index < pixels_per_block; index++)
    {
        burst_buffer[index * 2U]      = colour_high;
        burst_buffer[index * 2U + 1U] = colour_low;
    }

    /* Select LCD data mode. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, LCD_DC_PIN, BSP_IO_LEVEL_HIGH);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Select the LCD. CS is active LOW. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, LCD_SSLA3_C, BSP_IO_LEVEL_LOW);

    if (FSP_SUCCESS != err)
    {
        (void) R_IOPORT_PinWrite(&g_ioport_ctrl, LCD_SSLA3_C, BSP_IO_LEVEL_HIGH);
        return err;
    }

    remaining_pixels = Size;

    /* Send the color data in blocks. */
    while (remaining_pixels > 0U)
    {
        /* Determine the number of pixels in the current block. */
        if (remaining_pixels > pixels_per_block)
        {
            current_pixels = pixels_per_block;
        }
        else
        {
            current_pixels = remaining_pixels;
        }

        /* Convert the pixel count to the number of SPI bytes. */
        transfer_size = current_pixels * 2U;

        err = ili9341_spi_write_blocking(burst_buffer, transfer_size);

        if (FSP_SUCCESS != err)
        {
            /* Always release the LCD when a transfer fails or times out. */
            (void) R_IOPORT_PinWrite(&g_ioport_ctrl, LCD_SSLA3_C, BSP_IO_LEVEL_HIGH);
            return err;
        }

        remaining_pixels -= current_pixels;

    }

    /* Deselect the LCD after all blocks have been transmitted. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, LCD_SSLA3_C,
            BSP_IO_LEVEL_HIGH);

    return err;
}

/*******************************************************************************************************************//**
 * @brief Fills the entire LCD screen with the selected color.
 *
 * @param[in] Colour 16-bit RGB565 color value.
 *
 * @retval FSP_SUCCESS              Screen filled successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT The current display dimensions are invalid.
 * @return Any other FSP error code returned by the LCD driver.
 **********************************************************************************************************************/
fsp_err_t ILI9341_Fill_Screen(uint16_t Colour)
{
    fsp_err_t err;

    if ((0U == LCD_WIDTH) || (0U == LCD_HEIGHT))
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    /* Set the drawing area to the entire LCD screen. */
    err = ILI9341_Set_Address(0U, 0U,
                             (uint16_t) (LCD_WIDTH - 1U),
                             (uint16_t) (LCD_HEIGHT - 1U));
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Fill every pixel with the selected color. */
    err = ILI9341_Draw_Colour_Burst(Colour, (uint32_t) LCD_WIDTH * (uint32_t) LCD_HEIGHT);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Draws one pixel at the specified screen coordinate.
 *
 * @param[in] X      Horizontal pixel coordinate.
 * @param[in] Y      Vertical pixel coordinate.
 * @param[in] Colour 16-bit RGB565 color value.
 *
 * @retval FSP_SUCCESS              Pixel drawn successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT Coordinate is outside the display area.
 * @return Any other FSP error code returned by the IOPORT or SPI driver.
 **********************************************************************************************************************/
fsp_err_t ILI9341_Draw_Pixel(uint16_t X, uint16_t Y, uint16_t Colour)
{
    fsp_err_t err;
    uint8_t   column_command = 0x2AU;
    uint8_t   page_command   = 0x2BU;
    uint8_t   write_command  = 0x2CU;
    uint8_t   temp_buffer_x[4] = {(uint8_t) (X >> 8U), (uint8_t) X,
                                  (uint8_t) (X >> 8U), (uint8_t) X};
    uint8_t   temp_buffer_y[4] = {(uint8_t) (Y >> 8U), (uint8_t) Y,
                                  (uint8_t) (Y >> 8U), (uint8_t) Y};
    uint8_t   temp_buffer_colour[2] = {(uint8_t) (Colour >> 8U), (uint8_t) (Colour & 0xFFU)};

    /* Check whether the coordinate is outside the display area. */
    if ((X >= LCD_WIDTH) || (Y >= LCD_HEIGHT))
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    /* Send the column address command and data. */
    err = ili9341_spi_transaction(BSP_IO_LEVEL_LOW, &column_command, 1U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    err = ili9341_spi_transaction(BSP_IO_LEVEL_HIGH, temp_buffer_x, 4U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Send the page address command and data. */
    err = ili9341_spi_transaction(BSP_IO_LEVEL_LOW, &page_command, 1U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    err = ili9341_spi_transaction(BSP_IO_LEVEL_HIGH, temp_buffer_y, 4U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Send the memory write command and pixel color. */
    err = ili9341_spi_transaction(BSP_IO_LEVEL_LOW, &write_command, 1U);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    return ili9341_spi_transaction(BSP_IO_LEVEL_HIGH, temp_buffer_colour, 2U);
}

/*******************************************************************************************************************//**
 * @brief Draws a filled rectangle using the selected color.
 *
 * @param[in] X      X coordinate of the upper-left corner.
 * @param[in] Y      Y coordinate of the upper-left corner.
 * @param[in] Width  Rectangle width in pixels.
 * @param[in] Height Rectangle height in pixels.
 * @param[in] Colour 16-bit RGB565 color value.
 *
 * @retval FSP_SUCCESS              Rectangle drawn successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT Position or dimensions are invalid.
 * @return Any other FSP error code returned by the LCD driver.
 **********************************************************************************************************************/
fsp_err_t ILI9341_Draw_Rectangle(uint16_t X, uint16_t Y, uint16_t Width, uint16_t Height, uint16_t Colour)
{
    fsp_err_t err;

    /* Validate the starting position and rectangle dimensions. */
    if ((X >= LCD_WIDTH) || (Y >= LCD_HEIGHT) ||
        (0U == Width) || (0U == Height))
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    /* Clip the rectangle width at the right edge of the LCD. */
    if (Width > (uint16_t) (LCD_WIDTH - X))
    {
        Width = (uint16_t) (LCD_WIDTH - X);
    }

    /* Clip the rectangle height at the bottom edge of the LCD. */
    if (Height > (uint16_t) (LCD_HEIGHT - Y))
    {
        Height = (uint16_t) (LCD_HEIGHT - Y);
    }

    /* Set the rectangular drawing area. */
    err = ILI9341_Set_Address(X, Y, (uint16_t) (X + Width - 1U), (uint16_t) (Y + Height - 1U));
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Fill the selected rectangle. */
    err = ILI9341_Draw_Colour_Burst(Colour, (uint32_t) Width * (uint32_t) Height);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Draws a horizontal line using the selected color.
 *
 * @param[in] X      Starting X coordinate.
 * @param[in] Y      Starting Y coordinate.
 * @param[in] Width  Line width in pixels.
 * @param[in] Colour 16-bit RGB565 color value.
 *
 * @retval FSP_SUCCESS              Horizontal line drawn successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT Position or width is invalid.
 * @return Any other FSP error code returned by the LCD driver.
 **********************************************************************************************************************/
fsp_err_t ILI9341_Draw_Horizontal_Line(uint16_t X, uint16_t Y, uint16_t Width, uint16_t Colour)
{
    fsp_err_t err;

    /* Validate the starting position and line width. */
    if ((X >= LCD_WIDTH) || (Y >= LCD_HEIGHT) || (0U == Width))
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    /* Clip the line at the right edge of the LCD. */
    if (Width > (uint16_t) (LCD_WIDTH - X))
    {
        Width = (uint16_t) (LCD_WIDTH - X);
    }

    /* Set the horizontal drawing area. */
    err = ILI9341_Set_Address(X, Y, (uint16_t) (X + Width - 1U), Y);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Fill the horizontal line. */
    return ILI9341_Draw_Colour_Burst(Colour, Width);
}

/*******************************************************************************************************************//**
 * @brief Draws a vertical line using the selected color.
 *
 * @param[in] X      Starting X coordinate.
 * @param[in] Y      Starting Y coordinate.
 * @param[in] Height Line height in pixels.
 * @param[in] Colour 16-bit RGB565 color value.
 *
 * @retval FSP_SUCCESS              Vertical line drawn successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT Position or height is invalid.
 * @return Any other FSP error code returned by the LCD driver.
 **********************************************************************************************************************/
fsp_err_t ILI9341_Draw_Vertical_Line(uint16_t X, uint16_t Y, uint16_t Height, uint16_t Colour)
{
    fsp_err_t err;

    /* Validate the starting position and line height. */
    if ((X >= LCD_WIDTH) || (Y >= LCD_HEIGHT) || (0U == Height))
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    /* Clip the line at the bottom edge of the LCD. */
    if (Height > (uint16_t) (LCD_HEIGHT - Y))
    {
        Height = (uint16_t) (LCD_HEIGHT - Y);
    }

    /* Set the vertical drawing area. */
    err = ILI9341_Set_Address(X, Y, X, (uint16_t) (Y + Height - 1U));
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Fill the vertical line. */
    return ILI9341_Draw_Colour_Burst(Colour, Height);
}

/*******************************************************************************************************************//**
 * @brief Updates the transfer status flags when an SPI event occurs.
 *
 * @param[in] p_args Pointer to the SPI callback arguments.
 *
 * @retval None
 **********************************************************************************************************************/
void spi_master_callback(spi_callback_args_t * p_args)
{
    if (NULL == p_args)
    {
        g_spi_transfer_error = true;
    }
    else if (SPI_EVENT_TRANSFER_COMPLETE == p_args->event)
    {
        g_spi_transfer_complete = true;
    }
    else
    {
        g_spi_transfer_error = true;
    }
}

/*******************************************************************************************************************//**
 * @brief Starts an SPI transmission and waits for the transfer-complete callback.
 *
 * @note Configure spi_master_callback in the FSP SPI stack and enable the SPI interrupts.
 *
 * @param[in] p_data Pointer to the transmit buffer.
 * @param[in] length Number of bytes to transmit.
 *
 * @retval FSP_SUCCESS              SPI transmission completed successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT The transmit buffer is NULL or the length is zero.
 * @retval FSP_ERR_ABORTED          The SPI callback reported an error event.
 * @retval FSP_ERR_TIMEOUT          The transfer-complete callback was not received before the timeout expired.
 * @return Any other FSP error code returned by R_SPI_Write().
 **********************************************************************************************************************/
static fsp_err_t ili9341_spi_write_blocking(uint8_t const * p_data, uint32_t length)
{
    fsp_err_t err;
    uint32_t  timeout_us = ILI9341_SPI_TIMEOUT_US;

    if ((NULL == p_data) || (0U == length))
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    /* Clear the status flags before starting a new transfer. */
    g_spi_transfer_complete = false;
    g_spi_transfer_error    = false;

    err = R_SPI_Write(&g_spi_master_ctrl, p_data, length, SPI_BIT_WIDTH_8_BITS);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    /* Wait until the SPI callback reports completion or an error. */
    while ((!g_spi_transfer_complete) && (!g_spi_transfer_error))
    {
        if (0U == timeout_us)
        {
            return FSP_ERR_TIMEOUT;
        }

        R_BSP_SoftwareDelay(1U, BSP_DELAY_UNITS_MICROSECONDS);
        timeout_us--;
    }

    if (g_spi_transfer_error)
    {
        return FSP_ERR_ABORTED;
    }

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Sends one command or data transaction and always releases the LCD chip-select pin.
 *
 * @param[in] dc_level Command/data pin level for this transaction.
 * @param[in] p_data   Pointer to the transmit buffer.
 * @param[in] length   Number of bytes to transmit.
 *
 * @retval FSP_SUCCESS              Transaction completed successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT The transmit buffer is NULL or the length is zero.
 * @return Any other FSP error code returned by the IOPORT or SPI driver.
 **********************************************************************************************************************/
static fsp_err_t ili9341_spi_transaction(bsp_io_level_t dc_level, uint8_t const * p_data, uint32_t length)
{
    fsp_err_t err;
    fsp_err_t cs_err;

    if ((NULL == p_data) || (0U == length))
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    /* Select command or data mode before asserting chip select. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, LCD_DC_PIN, dc_level);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    /* Select the LCD. CS is active LOW. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, LCD_SSLA3_C, BSP_IO_LEVEL_LOW);

    if (FSP_SUCCESS != err)
    {
        (void) R_IOPORT_PinWrite(&g_ioport_ctrl, LCD_SSLA3_C, BSP_IO_LEVEL_HIGH);
        return err;
    }

    err = ili9341_spi_write_blocking(p_data, length);

    /* Always release the LCD, including after an SPI error or timeout. */
    cs_err = R_IOPORT_PinWrite(&g_ioport_ctrl, LCD_SSLA3_C, BSP_IO_LEVEL_HIGH);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    return cs_err;
}

/*******************************************************************************************************************//**
 * @} (end addtogroup ILI9341_Driver)
 **********************************************************************************************************************/