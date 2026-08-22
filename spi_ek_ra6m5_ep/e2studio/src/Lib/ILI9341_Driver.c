
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
#include "ILI9341_Driver.h"
#include "r_spi.h"
#include "r_ioport.h"
#include "common_utils.h"

/***********************************************************************************************************************
 * Macro definitions
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Typedef definitions
 **********************************************************************************************************************/


/***********************************************************************************************************************
 * Private function declarations
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Private global variables
 **********************************************************************************************************************/

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

     /* Select the LCD. CS is active LOW. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, SSLA3_C_Pin, BSP_IO_LEVEL_LOW);

    if (FSP_SUCCESS != err)
    {
        APP_ERR_PRINT("** LCD CS initialization failed **\r\n");
        return err;
    }

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Starts transmission of one byte to the ILI9341 LCD through SPI.
 *
 * @param[in] SPI_Data Byte to be transmitted.
 *
 * @retval FSP_SUCCESS SPI transmission was started successfully.
 * @return Any other FSP error code returned by R_SPI_Write().
 **********************************************************************************************************************/
fsp_err_t  ILI9341_SPI_Send(uint8_t SPI_Data)
{
    fsp_err_t err;

    err = R_SPI_Write(&g_spi_master_ctrl, &SPI_Data, 1U, SPI_BIT_WIDTH_8_BITS);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    return FSP_SUCCESS;
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
    fsp_err_t err;

    /* Select command mode. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, DC_Pin, BSP_IO_LEVEL_LOW);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    /* Select LCD. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl,SSLA3_C_Pin, BSP_IO_LEVEL_LOW);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    /* Send command byte. */
    err = ILI9341_SPI_Send(command);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    /* Deselect LCD. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, SSLA3_C_Pin, BSP_IO_LEVEL_HIGH);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    return err;
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
    fsp_err_t err;

    /* Select data mode. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, DC_Pin, BSP_IO_LEVEL_HIGH);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    /* Select LCD. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, SSLA3_C_Pin, BSP_IO_LEVEL_LOW);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    /* Send data byte. */
    err = ILI9341_SPI_Send(data);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    /* Deselect LCD. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, SSLA3_C_Pin, BSP_IO_LEVEL_HIGH);

    return err;
}

/*******************************************************************************************************************//**
 * @brief Sets the rectangular LCD memory area for subsequent drawing.
 *
 * @param[in] x1 Starting X coordinate.
 * @param[in] y1 Starting Y coordinate.
 * @param[in] x2 Ending X coordinate.
 * @param[in] y2 Ending Y coordinate.
 *
 * @retval FSP_SUCCESS Address window configured successfully.
 * @return Any other FSP error code returned by the LCD driver.
 **********************************************************************************************************************/
fsp_err_t ILI9341_Set_Address(uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2)
{
    fsp_err_t err;

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
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, SSLA3_C_Pin, BSP_IO_LEVEL_HIGH);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Assert hardware reset. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, RESET_Pin, BSP_IO_LEVEL_LOW);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    R_BSP_SoftwareDelay(200U, BSP_DELAY_UNITS_MILLISECONDS);

    /* Release hardware reset. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, RESET_Pin, BSP_IO_LEVEL_HIGH);
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
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, RESET_Pin, BSP_IO_LEVEL_HIGH);

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
    fsp_err_t err;

    uint8_t temp_buffer[2] ={(uint8_t) (Colour >> 8U), (uint8_t) (Colour & 0xFFU)};

    /* Select data mode. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, DC_Pin, BSP_IO_LEVEL_HIGH);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Select LCD. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, SSLA3_C_Pin, BSP_IO_LEVEL_LOW);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Transmit the 16-bit RGB565 color value. */
    err = R_SPI_Write(&g_spi_master_ctrl, temp_buffer, 2U, SPI_BIT_WIDTH_8_BITS);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Deselect LCD. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, SSLA3_C_Pin, BSP_IO_LEVEL_HIGH);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    return FSP_SUCCESS;
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
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, DC_Pin, BSP_IO_LEVEL_HIGH);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Select the LCD. CS is active LOW. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, SSLA3_C_Pin, BSP_IO_LEVEL_LOW);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

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

        err = R_SPI_Write(&g_spi_master_ctrl, burst_buffer,
                transfer_size, SPI_BIT_WIDTH_8_BITS);

        if (FSP_SUCCESS != err)
        {
            return err;
        }

        R_BSP_SoftwareDelay(10U,BSP_DELAY_UNITS_MILLISECONDS);

        remaining_pixels -= current_pixels;

    }

    /* Deselect the LCD after all blocks have been transmitted. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, SSLA3_C_Pin,
            BSP_IO_LEVEL_HIGH);

    return err;
}

/*******************************************************************************************************************//**
 * @brief Fills the entire LCD screen with the selected color.
 *
 * @param[in] Colour 16-bit RGB565 color value.
 *
 * @retval FSP_SUCCESS Screen filled successfully.
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
    err = ILI9341_Set_Address(0U,0U,(uint16_t) (LCD_WIDTH),(uint16_t) (LCD_HEIGHT));
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

    /* Check whether the coordinate is outside the display area. */
    if ((X >= LCD_WIDTH) || (Y >= LCD_HEIGHT))
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    /* Send the column address command. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, DC_Pin, BSP_IO_LEVEL_LOW);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, SSLA3_C_Pin, BSP_IO_LEVEL_LOW);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    err = ILI9341_SPI_Send(0x2AU);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    R_BSP_SoftwareDelay(1U, BSP_DELAY_UNITS_MILLISECONDS);
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, DC_Pin, BSP_IO_LEVEL_HIGH);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, SSLA3_C_Pin, BSP_IO_LEVEL_HIGH);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Send the column address data. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, SSLA3_C_Pin, BSP_IO_LEVEL_LOW);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    uint8_t temp_buffer_x[4] = {(uint8_t)(X>>8),(uint8_t)(X), (uint8_t)((X+1)>>8),(uint8_t)(X+1)};
    err = R_SPI_Write(&g_spi_master_ctrl,temp_buffer_x, 4U, SPI_BIT_WIDTH_8_BITS);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    R_BSP_SoftwareDelay(1U, BSP_DELAY_UNITS_MILLISECONDS);
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, SSLA3_C_Pin, BSP_IO_LEVEL_HIGH);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Send the page address command. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, DC_Pin, BSP_IO_LEVEL_LOW);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, SSLA3_C_Pin, BSP_IO_LEVEL_LOW);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    err = ILI9341_SPI_Send(0x2BU);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    R_BSP_SoftwareDelay(1U, BSP_DELAY_UNITS_MILLISECONDS);
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, DC_Pin, BSP_IO_LEVEL_HIGH);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, SSLA3_C_Pin, BSP_IO_LEVEL_HIGH);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Send the page address data. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, SSLA3_C_Pin, BSP_IO_LEVEL_LOW);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    unsigned char temp_buffer_y[4] = {(uint8_t)(Y>>8),(uint8_t)(Y), (uint8_t)((Y+1)>>8), (uint8_t)(Y+1)};
    err = R_SPI_Write(&g_spi_master_ctrl, temp_buffer_y, 4U, SPI_BIT_WIDTH_8_BITS);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    R_BSP_SoftwareDelay(1U, BSP_DELAY_UNITS_MILLISECONDS);
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, SSLA3_C_Pin, BSP_IO_LEVEL_HIGH);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Send the memory write command. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, DC_Pin, BSP_IO_LEVEL_LOW);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, SSLA3_C_Pin, BSP_IO_LEVEL_LOW);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    err = ILI9341_SPI_Send(0x2CU);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    R_BSP_SoftwareDelay(1U, BSP_DELAY_UNITS_MILLISECONDS);
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, DC_Pin, BSP_IO_LEVEL_HIGH);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, SSLA3_C_Pin, BSP_IO_LEVEL_HIGH);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Send the pixel color data. */
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, SSLA3_C_Pin, BSP_IO_LEVEL_LOW);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    uint8_t temp_buffer_colour[2] = {(uint8_t)(Colour>>8), (uint8_t)(Colour)};
    err = R_SPI_Write(&g_spi_master_ctrl, temp_buffer_colour, 2U, SPI_BIT_WIDTH_8_BITS);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    R_BSP_SoftwareDelay(1U, BSP_DELAY_UNITS_MILLISECONDS);
    err = R_IOPORT_PinWrite(&g_ioport_ctrl, SSLA3_C_Pin, BSP_IO_LEVEL_HIGH);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    return FSP_SUCCESS;
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
 * @} (end addtogroup ILI9341_Driver)
 **********************************************************************************************************************/