/*
 * Copyright (c) 2017 Matej Artnak
 *
 * SPDX-License-Identifier: MIT
 */

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/

#include "ILI9341_Gfx.h"
#include "5x5_font.h"
#include "r_spi.h"
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


/*******************************************************************************************************************//**
 * @addtogroup ILI9341_GFX
 * @{
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Functions
 **********************************************************************************************************************/

 /**
 * @brief Draws a hollow circle with the specified radius and color.
 *
 * @details The X and Y coordinates represent the center of the circle.
 *          The function uses the midpoint circle algorithm to calculate
 *          and draw eight symmetrical pixels during each iteration.
 *
 * @param[in] X      X coordinate of the circle center.
 * @param[in] Y      Y coordinate of the circle center.
 * @param[in] Radius Circle radius in pixels.
 * @param[in] Colour 16-bit RGB565 color value.
 *
 * @retval FSP_SUCCESS              Circle drawn successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT Circle parameters are outside the display.
 * @return Any other FSP error code returned by the LCD driver.
*/
fsp_err_t ILI9341_Draw_Hollow_Circle(uint16_t X, uint16_t Y, uint16_t Radius, uint16_t Colour)
{

    fsp_err_t err;

    int32_t x;
    int32_t y;
    int32_t dx;
    int32_t dy;
    int32_t decision_error;

    /* Radius must contain at least one pixel. */
    if (0U == Radius)
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    /* Initialize the midpoint circle algorithm. */
    x              = (int32_t) Radius - 1;
    y              = 0;
    dx             = 1;
    dy             = 1;
    decision_error = dx - ((int32_t) Radius << 1);

    while (x >= y)
    {
        /* Draw the eight symmetrical points of the circle. */
        err = ILI9341_Draw_Pixel((uint16_t) ((int32_t) X + x), (uint16_t) ((int32_t) Y + y), Colour);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

        err = ILI9341_Draw_Pixel((uint16_t) ((int32_t) X + y), (uint16_t) ((int32_t) Y + x), Colour);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

        err = ILI9341_Draw_Pixel((uint16_t) ((int32_t) X - y), (uint16_t) ((int32_t) Y + x), Colour);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

        err = ILI9341_Draw_Pixel((uint16_t) ((int32_t) X - x), (uint16_t) ((int32_t) Y + y), Colour);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

        err = ILI9341_Draw_Pixel((uint16_t) ((int32_t) X - x), (uint16_t) ((int32_t) Y - y), Colour);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

        err = ILI9341_Draw_Pixel((uint16_t) ((int32_t) X - y),(uint16_t) ((int32_t) Y - x), Colour);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

        err = ILI9341_Draw_Pixel((uint16_t) ((int32_t) X + y), (uint16_t) ((int32_t) Y - x), Colour);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

        err = ILI9341_Draw_Pixel((uint16_t) ((int32_t) X + x), (uint16_t) ((int32_t) Y - y), Colour);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

        /* Move to the next Y coordinate when required. */
        if (decision_error <= 0)
        {
            y++;
            decision_error += dy;
            dy += 2;
        }

        /* Move to the previous X coordinate when required. */
        if (decision_error > 0)
        {
            x--;
            dx += 2;
            decision_error += (-((int32_t) Radius << 1)) + dx;
        }
    }

    return FSP_SUCCESS;
}

/**
 * @brief Draws a filled circle with the specified radius and color.
 *
 * @param[in] X      X coordinate of the circle center.
 * @param[in] Y      Y coordinate of the circle center.
 * @param[in] Radius Circle radius in pixels.
 * @param[in] Colour 16-bit RGB565 color value.
 *
 * @retval FSP_SUCCESS              Circle drawn successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT Circle is outside the display area.
 * @return Any other FSP error code returned by the LCD driver.
 */
fsp_err_t ILI9341_Draw_Filled_Circle(uint16_t X, uint16_t Y, uint16_t Radius, uint16_t Colour)
{
    fsp_err_t err;
    int32_t x;
    int32_t y;
    int32_t x_change;
    int32_t y_change;
    int32_t radius_error;
    int32_t index;

    /* Radius zero represents one pixel. */
    if (0U == Radius)
    {
        return ILI9341_Draw_Pixel(X, Y, Colour);
    }

    /* Initialize the filled-circle algorithm. */
    x            = (int32_t) Radius;
    y            = 0;
    x_change     = 1 - ((int32_t) Radius * 2);
    y_change     = 0;
    radius_error = 0;

    while (x >= y)
    {
        /* Draw the upper and lower horizontal pixel rows. */
        for (index = (int32_t) X - x; index <= ((int32_t) X + x); index++)
        {
            err = ILI9341_Draw_Pixel((uint16_t) index, (uint16_t) ((int32_t) Y + y), Colour);
            FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

            err = ILI9341_Draw_Pixel((uint16_t) index, (uint16_t) ((int32_t) Y - y), Colour);
            FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
        }

        /* Draw the left and right horizontal pixel rows. */
        for (index = (int32_t) X - y; index <= ((int32_t) X + y); index++)
        {
            err = ILI9341_Draw_Pixel((uint16_t) index, (uint16_t) ((int32_t) Y + x), Colour);
            FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

            err = ILI9341_Draw_Pixel((uint16_t) index, (uint16_t) ((int32_t) Y - x), Colour);
            FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
        }

        y++;
        radius_error += y_change;
        y_change += 2;

        if (((radius_error * 2) + x_change) > 0)
        {
            x--;
            radius_error += x_change;
            x_change += 2;
        }
    }

    return FSP_SUCCESS;
}

/**
 * @brief Draws a hollow rectangle between two coordinates.
 *
 * @param[in] X0     First X coordinate.
 * @param[in] Y0     First Y coordinate.
 * @param[in] X1     Second X coordinate.
 * @param[in] Y1     Second Y coordinate.
 * @param[in] Colour 16-bit RGB565 color value.
 *
 * @retval FSP_SUCCESS              Rectangle drawn successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT Coordinates are outside the display.
 * @return Any other FSP error code returned by the LCD driver.
*/
fsp_err_t ILI9341_Draw_Hollow_Rectangle_Coord(uint16_t X0, uint16_t Y0,uint16_t X1,uint16_t Y1, uint16_t Colour)
{
    fsp_err_t err;
    uint16_t left;
    uint16_t right;
    uint16_t top;
    uint16_t bottom;
    uint16_t width;
    uint16_t height;

    /* Determine the actual rectangle boundaries. */
    left   = (X0 < X1) ? X0 : X1;
    right  = (X0 < X1) ? X1 : X0;
    top    = (Y0 < Y1) ? Y0 : Y1;
    bottom = (Y0 < Y1) ? Y1 : Y0;

    /* Include both starting and ending coordinates. */
    width  = (uint16_t) (right - left + 1U);
    height = (uint16_t) (bottom - top + 1U);

    /* Draw the top horizontal line. */
    err = ILI9341_Draw_Horizontal_Line(left, top, width, Colour);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Draw the bottom horizontal line. */
    if (bottom != top)
    {
        err = ILI9341_Draw_Horizontal_Line(left, bottom, width, Colour);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    }

    /* Draw the left vertical line. */
    err = ILI9341_Draw_Vertical_Line(left, top, height, Colour);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Draw the right vertical line. */
    if (right != left)
    {
        err = ILI9341_Draw_Vertical_Line(right, top, height, Colour);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    }

    return FSP_SUCCESS;
}

/**
 * @brief Draws a filled rectangle between two coordinates.
 *
 * @param[in] X0     First X coordinate.
 * @param[in] Y0     First Y coordinate.
 * @param[in] X1     Second X coordinate.
 * @param[in] Y1     Second Y coordinate.
 * @param[in] Colour 16-bit RGB565 color value.
 *
 * @retval FSP_SUCCESS              Rectangle drawn successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT Coordinates are outside the display.
 * @return Any other FSP error code returned by the LCD driver.
*/
fsp_err_t ILI9341_Draw_Filled_Rectangle_Coord(uint16_t X0, uint16_t Y0, uint16_t X1, uint16_t Y1, uint16_t Colour)
{
    fsp_err_t err;
    uint16_t left;
    uint16_t right;
    uint16_t top;
    uint16_t bottom;
    uint16_t width;
    uint16_t height;

    /* Determine the actual rectangle boundaries. */
    left   = (X0 < X1) ? X0 : X1;
    right  = (X0 < X1) ? X1 : X0;
    top    = (Y0 < Y1) ? Y0 : Y1;
    bottom = (Y0 < Y1) ? Y1 : Y0;

    /* Calculate the inclusive rectangle dimensions. */
    width  = (uint16_t) (right - left + 1U);
    height = (uint16_t) (bottom - top + 1U);

    err = ILI9341_Draw_Rectangle(left, top, width, height, Colour);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    return FSP_SUCCESS;
}

/**
 * @brief Draws one character using the configured font table.
 *
 * @param[in] Character         Character to draw.
 * @param[in] X                 Starting X coordinate.
 * @param[in] Y                 Starting Y coordinate.
 * @param[in] Colour            Character RGB565 color.
 * @param[in] Size              Character scaling factor.
 * @param[in] Background_Colour Background RGB565 color.
 *
 * @retval FSP_SUCCESS              Character drawn successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT Character size is zero.
 * @return Any other FSP error code returned by the LCD driver.
 */
fsp_err_t ILI9341_Draw_Char(char Character, uint8_t X, uint8_t Y, uint16_t Colour, uint16_t Size, uint16_t Background_Colour)
{
    fsp_err_t err;
    uint8_t function_char;
    uint8_t row;
    uint8_t column;
    uint8_t index;
    uint8_t temp[CHAR_WIDTH];

    if (0U == Size)
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    function_char = (uint8_t) Character;

    /* Convert the ASCII character into a font-table index. */
    if (function_char < (uint8_t) ' ')
    {
        function_char = 0U;
    }
    else
    {
        function_char =
            (uint8_t) ((uint16_t) function_char - 32U);
    }

    /* Copy the character bitmap from the font table. */
    for (index = 0U; index < CHAR_WIDTH; index++)
    {
        temp[index] = (uint8_t) font[function_char][index];
    }

    /* Draw the character background. */
    err = ILI9341_Draw_Rectangle(X, Y, (uint16_t) (CHAR_WIDTH * Size), (uint16_t) (CHAR_HEIGHT * Size), Background_Colour);
    FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

    /* Draw every enabled font pixel. */
    for (column = 0U; column < CHAR_WIDTH; column++)
    {
        for (row = 0U; row < CHAR_HEIGHT; row++)
        {
            if (0U != (temp[column] & (uint8_t) (1U << row)))
            {
                if (1U == Size)
                {
                    err = ILI9341_Draw_Pixel((uint16_t) X + column, (uint16_t) Y + row, Colour);
                }
                else
                {
                    err = ILI9341_Draw_Rectangle((uint16_t)((uint32_t)X + ((uint32_t)column * (uint32_t)Size)), 
                        (uint16_t)((uint32_t)Y + ((uint32_t)row * (uint32_t)Size)), Size, Size, Colour);
                }

                FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
            }
        }
    }

    return FSP_SUCCESS;
}

/**
 * @brief Draws a null-terminated text string.
 *
 * @param[in] Text              Pointer to the text string.
 * @param[in] X                 Starting X coordinate.
 * @param[in] Y                 Starting Y coordinate.
 * @param[in] Colour            Text RGB565 color.
 * @param[in] Size              Character scaling factor.
 * @param[in] Background_Colour Background RGB565 color.
 *
 * @retval FSP_SUCCESS       Text drawn successfully.
 * @retval FSP_ERR_ASSERTION Text pointer is NULL.
 * @return Any other FSP error code returned by the LCD driver.
*/
fsp_err_t ILI9341_Draw_Text(const char * Text, uint8_t X, uint8_t Y, uint16_t Colour, uint16_t Size, uint16_t Background_Colour)
{
    fsp_err_t err;

    while (*Text)
    {
        err = ILI9341_Draw_Char(*Text, X, Y, Colour, Size, Background_Colour);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
        X = (uint8_t)((uint32_t)X + ((uint32_t)CHAR_WIDTH * (uint32_t)Size));
    }

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Draws a full-screen RGB565 image stored in flash.
 *
 * @details The image contains two bytes for each pixel. Image data is copied
 *          into a temporary buffer and transmitted in BURST_MAX_SIZE blocks.
 *
 * @note This temporary implementation uses a fixed delay after R_SPI_Write()
 *       instead of waiting for an SPI callback.
 *
 * @param[in] Image_Array Pointer to the RGB565 image data.
 * @param[in] Orientation Requested screen orientation.
 *
 * @retval FSP_SUCCESS              Image drawn successfully.
 * @retval FSP_ERR_ASSERTION        Image_Array is NULL.
 * @retval FSP_ERR_INVALID_ARGUMENT Orientation is invalid.
 * @return Any other FSP error code returned by the LCD, SPI or IOPORT driver.
 **********************************************************************************************************************/
fsp_err_t ILI9341_Draw_Image(const char * Image_Array, uint8_t Orientation)
{
    fsp_err_t err;

    if (NULL == Image_Array)
    {
        return FSP_ERR_ASSERTION;
    }

    if (SCREEN_HORIZONTAL_1 == Orientation)
    {
        uint8_t  temp_small_buffer[BURST_MAX_SIZE];
        uint32_t counter = 0U;
        uint32_t index;
        uint32_t buffer_index;
        uint32_t number_of_blocks;

        /* Set the first horizontal orientation. */
        err = ILI9341_Set_Rotation(SCREEN_HORIZONTAL_1);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

        /* Set the full-screen drawing area. */
        err = ILI9341_Set_Address(0U, 0U, ILI9341_SCREEN_WIDTH, ILI9341_SCREEN_HEIGHT);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

        /* Select LCD data mode. */
        err = R_IOPORT_PinWrite(&g_ioport_ctrl, DC_Pin, BSP_IO_LEVEL_HIGH);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

        /* Select the LCD. */
        err = R_IOPORT_PinWrite(&g_ioport_ctrl, SSLA3_C_Pin, BSP_IO_LEVEL_LOW);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

        number_of_blocks = ((uint32_t) ILI9341_SCREEN_WIDTH * (uint32_t) ILI9341_SCREEN_HEIGHT *
                        2U) / BURST_MAX_SIZE;

        for (index = 0U; index < number_of_blocks; index++)
        {
            /* Copy one image block into the SPI buffer. */
            for (buffer_index = 0U; buffer_index < BURST_MAX_SIZE; buffer_index++)
            {
                temp_small_buffer[buffer_index] =
                    (uint8_t) Image_Array[counter + buffer_index];
            }

            /* Start transmitting the current image block. */
            err = R_SPI_Write(&g_spi_master_ctrl, temp_small_buffer, BURST_MAX_SIZE, SPI_BIT_WIDTH_8_BITS);

            if (FSP_SUCCESS != err)
            {
                return err;
            }

            /* Temporary wait instead of SPI callback synchronization. */
            R_BSP_SoftwareDelay(10U, BSP_DELAY_UNITS_MILLISECONDS);

            counter += BURST_MAX_SIZE;
        }

        /* Deselect the LCD. */
        err = R_IOPORT_PinWrite(&g_ioport_ctrl, SSLA3_C_Pin, BSP_IO_LEVEL_HIGH);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    }
    else if (SCREEN_HORIZONTAL_2 == Orientation)
    {
        uint8_t  temp_small_buffer[BURST_MAX_SIZE];
        uint32_t counter = 0U;
        uint32_t index;
        uint32_t buffer_index;
        uint32_t number_of_blocks;

        /* Set the second horizontal orientation. */
        err = ILI9341_Set_Rotation(SCREEN_HORIZONTAL_2);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

        /* Set the full-screen drawing area. */
        err = ILI9341_Set_Address(0U, 0U, ILI9341_SCREEN_WIDTH, ILI9341_SCREEN_HEIGHT);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

        /* Select LCD data mode. */
        err = R_IOPORT_PinWrite(&g_ioport_ctrl,DC_Pin, BSP_IO_LEVEL_HIGH);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

        /* Select the LCD. */
        err = R_IOPORT_PinWrite(&g_ioport_ctrl,
                                SSLA3_C_Pin,
                                BSP_IO_LEVEL_LOW);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

        number_of_blocks =
            ((uint32_t) ILI9341_SCREEN_WIDTH *
             (uint32_t) ILI9341_SCREEN_HEIGHT *
             2U) / BURST_MAX_SIZE;

        for (index = 0U; index < number_of_blocks; index++)
        {
            /* Copy one image block into the SPI buffer. */
            for (buffer_index = 0U;
                 buffer_index < BURST_MAX_SIZE;
                 buffer_index++)
            {
                temp_small_buffer[buffer_index] =
                    (uint8_t) Image_Array[counter + buffer_index];
            }

            /* Start transmitting the current image block. */
            err = R_SPI_Write(&g_spi_master_ctrl,
                              temp_small_buffer,
                              BURST_MAX_SIZE,
                              SPI_BIT_WIDTH_8_BITS);

            if (FSP_SUCCESS != err)
            {
                (void) R_IOPORT_PinWrite(&g_ioport_ctrl,
                                         SSLA3_C_Pin,
                                         BSP_IO_LEVEL_HIGH);

                return err;
            }

            /* Temporary wait instead of SPI callback synchronization. */
            R_BSP_SoftwareDelay(10U,
                                BSP_DELAY_UNITS_MILLISECONDS);

            counter += BURST_MAX_SIZE;
        }

        /* Deselect the LCD. */
        err = R_IOPORT_PinWrite(&g_ioport_ctrl,
                                SSLA3_C_Pin,
                                BSP_IO_LEVEL_HIGH);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    }
    else if (SCREEN_VERTICAL_2 == Orientation)
    {
        uint8_t  temp_small_buffer[BURST_MAX_SIZE];
        uint32_t counter = 0U;
        uint32_t index;
        uint32_t buffer_index;
        uint32_t number_of_blocks;

        /* Set the second vertical orientation. */
        err = ILI9341_Set_Rotation(SCREEN_VERTICAL_2);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

        /* Width and height are exchanged in vertical orientation. */
        err = ILI9341_Set_Address(0U, 0U, ILI9341_SCREEN_HEIGHT, ILI9341_SCREEN_WIDTH);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

        /* Select LCD data mode. */
        err = R_IOPORT_PinWrite(&g_ioport_ctrl, DC_Pin, BSP_IO_LEVEL_HIGH);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

        /* Select the LCD. */
        err = R_IOPORT_PinWrite(&g_ioport_ctrl, SSLA3_C_Pin, BSP_IO_LEVEL_LOW);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

        number_of_blocks = ((uint32_t) ILI9341_SCREEN_WIDTH * (uint32_t) ILI9341_SCREEN_HEIGHT *
             2U) / BURST_MAX_SIZE;

        for (index = 0U; index < number_of_blocks; index++)
        {
            /* Copy one image block into the SPI buffer. */
            for (buffer_index = 0U; buffer_index < BURST_MAX_SIZE; buffer_index++)
            {
                temp_small_buffer[buffer_index] =
                    (uint8_t) Image_Array[counter + buffer_index];
            }

            /* Start transmitting the current image block. */
            err = R_SPI_Write(&g_spi_master_ctrl, temp_small_buffer, BURST_MAX_SIZE, SPI_BIT_WIDTH_8_BITS);

            if (FSP_SUCCESS != err)
            {
                return err;
            }

            /* Temporary wait instead of SPI callback synchronization. */
            R_BSP_SoftwareDelay(10U, BSP_DELAY_UNITS_MILLISECONDS);

            counter += BURST_MAX_SIZE;
        }

        /* Deselect the LCD. */
        err = R_IOPORT_PinWrite(&g_ioport_ctrl, SSLA3_C_Pin, BSP_IO_LEVEL_HIGH);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    }
    else if (SCREEN_VERTICAL_1 == Orientation)
    {
        uint8_t  temp_small_buffer[BURST_MAX_SIZE];
        uint32_t counter = 0U;
        uint32_t index;
        uint32_t buffer_index;
        uint32_t number_of_blocks;

        /* Set the first vertical orientation. */
        err = ILI9341_Set_Rotation(SCREEN_VERTICAL_1);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

        /* Width and height are exchanged in vertical orientation. */
        err = ILI9341_Set_Address(0U, 0U, ILI9341_SCREEN_HEIGHT, ILI9341_SCREEN_WIDTH);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

        /* Select LCD data mode. */
        err = R_IOPORT_PinWrite(&g_ioport_ctrl, DC_Pin, BSP_IO_LEVEL_HIGH);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

        /* Select the LCD. */
        err = R_IOPORT_PinWrite(&g_ioport_ctrl, SSLA3_C_Pin, BSP_IO_LEVEL_LOW);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);

        number_of_blocks = ((uint32_t) ILI9341_SCREEN_WIDTH * (uint32_t) ILI9341_SCREEN_HEIGHT *
             2U) / BURST_MAX_SIZE;

        for (index = 0U; index < number_of_blocks; index++)
        {
            /* Copy one image block into the SPI buffer. */
            for (buffer_index = 0U; buffer_index < BURST_MAX_SIZE; buffer_index++)
            {
                temp_small_buffer[buffer_index] =
                    (uint8_t) Image_Array[counter + buffer_index];
            }

            /* Start transmitting the current image block. */
            err = R_SPI_Write(&g_spi_master_ctrl, temp_small_buffer, BURST_MAX_SIZE, SPI_BIT_WIDTH_8_BITS);

            if (FSP_SUCCESS != err)
            {
                return err;
            }

            /* Temporary wait instead of SPI callback synchronization. */
            R_BSP_SoftwareDelay(10U, BSP_DELAY_UNITS_MILLISECONDS);

            counter += BURST_MAX_SIZE;
        }

        /* Deselect the LCD. */
        err = R_IOPORT_PinWrite(&g_ioport_ctrl, SSLA3_C_Pin, BSP_IO_LEVEL_HIGH);
        FSP_ERROR_RETURN(FSP_SUCCESS == err, err);
    }
    else
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @} (end addtogroup ILI9341_GFX)
 **********************************************************************************************************************/
