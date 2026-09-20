/*******************************************************************************************************************//**
 * @file ILI9341_Touchscreen.c
 * @brief Implements the GPIO bit-banged touchscreen driver for the Smart Relay RA6M5 project.
 *
 * This implementation is intentionally structured to remain close to the original STM32 HAL driver. The original
 * HAL_GPIO_WritePin() and HAL_GPIO_ReadPin() calls are replaced by R_IOPORT_PinWrite() and R_IOPORT_PinRead().
 * No hardware SPI peripheral and no separate software-SPI abstraction are required.
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/

#include "ILI9341_Touch.h"

/***********************************************************************************************************************
 * Macro definitions
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Typedef definitions
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Private function declarations
 **********************************************************************************************************************/

static void TP_GPIO_Write(bsp_io_port_pin_t pin, bsp_io_level_t level);
static uint8_t TP_GPIO_Read(bsp_io_port_pin_t pin);
static uint16_t TP_Filter_Samples(uint16_t samples[NO_OF_POSITION_SAMPLES]);

/***********************************************************************************************************************
 * Private global variables
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Global variables
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * @addtogroup ILI9341_TOUCHSCREEN
 * @{
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Private function definitions
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * @brief Writes one RA6M5 GPIO pin used by the touchscreen interface.
 *
 * @param[in] pin    FSP port/pin identifier.
 * @param[in] level  Output level to drive.
 **********************************************************************************************************************/
static void TP_GPIO_Write(bsp_io_port_pin_t pin, bsp_io_level_t level)
{
    /*
     * The original STM32 driver does not return GPIO errors to the caller.
     * Preserve the same external behavior for this compatibility-oriented port.
     */
    (void) R_IOPORT_PinWrite(&g_ioport_ctrl, pin, level);
}

/*******************************************************************************************************************//**
 * @brief Reads one RA6M5 GPIO pin used by the touchscreen interface.
 *
 * @param[in] pin  FSP port/pin identifier.
 *
 * @retval 0 Pin is LOW or the FSP read operation failed.
 * @retval 1 Pin is HIGH.
 **********************************************************************************************************************/
static uint8_t TP_GPIO_Read(bsp_io_port_pin_t pin)
{
    bsp_io_level_t level = BSP_IO_LEVEL_LOW;

    if (FSP_SUCCESS != R_IOPORT_PinRead(&g_ioport_ctrl, pin, &level))
    {
        return 0U;
    }

    return (BSP_IO_LEVEL_HIGH == level) ? 1U : 0U;
}

/*******************************************************************************************************************//**
 * @brief Filters one raw axis using a small sorted trimmed mean.
 *
 * @details Seven samples are sorted in ascending order. The two lowest and two highest values are rejected and the
 *          middle three are averaged. This rejects contact spikes with much lower latency than averaging 1000 samples.
 *
 * @param[in,out] samples Raw axis samples. The array is sorted in place.
 *
 * @return Filtered raw axis value.
 **********************************************************************************************************************/
static uint16_t TP_Filter_Samples(uint16_t samples[NO_OF_POSITION_SAMPLES])
{
    uint32_t sum = 0U;
    uint32_t index;
    uint32_t inner;
    uint16_t temp;

    for (index = 1U; index < NO_OF_POSITION_SAMPLES; index++)
    {
        temp  = samples[index];
        inner = index;

        while ((inner > 0U) && (samples[inner - 1U] > temp))
        {
            samples[inner] = samples[inner - 1U];
            inner--;
        }

        samples[inner] = temp;
    }

    for (index = TP_FILTER_FIRST_SAMPLE; index <= TP_FILTER_LAST_SAMPLE; index++)
    {
        sum += samples[index];
    }

    return (uint16_t) (sum / ((TP_FILTER_LAST_SAMPLE - TP_FILTER_FIRST_SAMPLE) + 1U));
}

/***********************************************************************************************************************
 * Functions
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * @brief Reads one 16-bit raw value from the touchscreen MISO pin.
 *
 * @details This is the RA6M5 equivalent of the original TP_Read() implementation. Sixteen software clock cycles are
 *          generated directly with GPIO writes and one MISO bit is sampled during each cycle.
 *
 * @return 16-bit raw value shifted in from TP_MISO_PIN.
 *
 * @note This API intentionally retains the original clock sequence.
 **********************************************************************************************************************/
uint16_t TP_Read(void)
{
    uint8_t  i     = 16U;
    uint16_t value = 0U;

    while (i > 0U)
    {
        value <<= 1U;

        TP_GPIO_Write(TP_CLK_PIN, BSP_IO_LEVEL_HIGH);
        TP_GPIO_Write(TP_CLK_PIN, BSP_IO_LEVEL_LOW);

        if (0U != TP_GPIO_Read(TP_MISO_PIN))
        {
            value++;
        }

        i--;
    }

    return value;
}

/*******************************************************************************************************************//**
 * @brief Writes one 8-bit command to the touchscreen through GPIO bit-banging.
 *
 * @param[in] value  Command byte to transmit, MSB first.
 *
 * @note This API intentionally retains the original STM32 TP_Write() clock and MOSI sequence.
 **********************************************************************************************************************/
void TP_Write(uint8_t value)
{
    uint8_t i = 8U;

    TP_GPIO_Write(TP_CLK_PIN, BSP_IO_LEVEL_LOW);

    while (i > 0U)
    {
        if (0U != (value & 0x80U))
        {
            TP_GPIO_Write(TP_MOSI_PIN, BSP_IO_LEVEL_HIGH);
        }
        else
        {
            TP_GPIO_Write(TP_MOSI_PIN, BSP_IO_LEVEL_LOW);
        }

        value <<= 1U;

        TP_GPIO_Write(TP_CLK_PIN, BSP_IO_LEVEL_HIGH);
        TP_GPIO_Write(TP_CLK_PIN, BSP_IO_LEVEL_LOW);

        i--;
    }
}

/*******************************************************************************************************************//**
 * @brief Reads and converts the current touchscreen coordinates.
 *
 * @details The function keeps the original command sequence and calibration, but replaces the 1000-sample blocking
 *          average with seven samples and a trimmed-mean filter. This greatly improves UI response while rejecting
 *          contact spikes from the resistive panel.
 *
 * @param[out] Coordinates  Two-element destination array. Coordinates[0] receives X and Coordinates[1] receives Y.
 *
 * @retval TOUCHPAD_DATA_OK    All requested samples were collected successfully.
 * @retval TOUCHPAD_DATA_NOISY The panel was released before the requested number of samples was collected.
 *
 * @note The coordinate transform intentionally preserves the legacy unsigned wrap behavior used by the original code.
 **********************************************************************************************************************/
uint8_t TP_Read_Coordinates(uint16_t Coordinates[2])
{
    uint16_t x_samples[NO_OF_POSITION_SAMPLES];
    uint16_t y_samples[NO_OF_POSITION_SAMPLES];
    uint16_t rawx;
    uint16_t rawy;
    uint32_t sample_index;

    if (NULL == Coordinates)
    {
        return TOUCHPAD_DATA_NOISY;
    }

    Coordinates[0] = 0U;
    Coordinates[1] = 0U;

    /* Preserve the idle levels used by the original STM32 implementation. */
    TP_GPIO_Write(TP_CLK_PIN,  BSP_IO_LEVEL_HIGH);
    TP_GPIO_Write(TP_MOSI_PIN, BSP_IO_LEVEL_HIGH);
    TP_GPIO_Write(TP_CS_PIN,   BSP_IO_LEVEL_HIGH);

    if (0U != TP_GPIO_Read(TP_IRQ_PIN))
    {
        return TOUCHPAD_DATA_NOISY;
    }

    TP_GPIO_Write(TP_CS_PIN, BSP_IO_LEVEL_LOW);

    for (sample_index = 0U; sample_index < NO_OF_POSITION_SAMPLES; sample_index++)
    {
        if (0U != TP_GPIO_Read(TP_IRQ_PIN))
        {
            TP_GPIO_Write(TP_CS_PIN, BSP_IO_LEVEL_HIGH);
            return TOUCHPAD_DATA_NOISY;
        }

        TP_Write(CMD_RDY);
        y_samples[sample_index] = TP_Read();

        TP_Write(CMD_RDX);
        x_samples[sample_index] = TP_Read();
    }

    TP_GPIO_Write(TP_CS_PIN, BSP_IO_LEVEL_HIGH);

    /* Reject a release that occurs immediately after the last sample. */
    if (0U != TP_GPIO_Read(TP_IRQ_PIN))
    {
        return TOUCHPAD_DATA_NOISY;
    }

    rawx = TP_Filter_Samples(x_samples);
    rawy = TP_Filter_Samples(y_samples);

    /* Preserve the legacy unsigned 16-bit inversion used by the original driver. */
    rawx = (uint16_t) (0U - rawx);
    rawy = (uint16_t) (0U - rawy);

    Coordinates[0] =
        (uint16_t) ((((240.0F - ((float) rawx / (float) X_TRANSLATION)) -
                      (float) X_OFFSET) * X_MAGNITUDE));

    Coordinates[1] =
        (uint16_t) (((((float) rawy / (float) Y_TRANSLATION) -
                       (float) Y_OFFSET) * Y_MAGNITUDE));

    return TOUCHPAD_DATA_OK;
}

/*******************************************************************************************************************//**
 * @brief Checks whether the touchscreen IRQ input indicates an active touch.
 *
 * @retval TOUCHPAD_PRESSED     TP_IRQ_PIN is LOW.
 * @retval TOUCHPAD_NOT_PRESSED TP_IRQ_PIN is HIGH or could not be read.
 **********************************************************************************************************************/
uint8_t TP_Touchpad_Pressed(void)
{
    if (0U == TP_GPIO_Read(TP_IRQ_PIN))
    {
        return TOUCHPAD_PRESSED;
    }

    return TOUCHPAD_NOT_PRESSED;
}

/*******************************************************************************************************************//**
 * @} (end addtogroup ILI9341_TOUCHSCREEN)
 **********************************************************************************************************************/
