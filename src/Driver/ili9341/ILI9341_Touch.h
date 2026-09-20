
/*******************************************************************************************************************//**
 * @file ILI9341_Touchscreen.h
 * @brief Declares the GPIO bit-banged touchscreen driver for the Smart Relay RA6M5 project.
 *
 * This port intentionally keeps the original STM32 touchscreen API and control flow as closely as possible.
 * No RA6M5 SPI peripheral is used. CLK, MOSI, MISO, CS, and IRQ are handled directly through the Renesas FSP
 * IOPORT driver.
 *
 * @note Configure the five touchscreen pins as GPIO in the FSP configurator before using this driver.
 **********************************************************************************************************************/

#ifndef ILI9341_TOUCHSCREEN_H_
#define ILI9341_TOUCHSCREEN_H_

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/

#include <stdint.h>
#include "hal_data.h"

/***********************************************************************************************************************
 * Macro definitions
 **********************************************************************************************************************/

/*
 * Touchpad pin mapping.
 *
 * Keep these names close to the original STM32 driver. Replace T_CLK_Pin,
 * T_CS_Pin, T_MISO_Pin, T_MOSI_Pin and T_IRQ_Pin with the exact FSP pin
 * symbols used by the Smart Relay project if the generated names differ.
 *
 * Unlike STM32 HAL, no separate TP_xxx_PORT macro is required because
 * bsp_io_port_pin_t already encodes both the port number and pin number.
 */
#define TP_CLK_PIN                  RSPCKA_B_Pin
#define TP_CS_PIN                   SSLA0_B_Pin
#define TP_MISO_PIN                 MISOA_B_Pin
#define TP_MOSI_PIN                 MOSIA_B_Pin
#define TP_IRQ_PIN                  T_IRQ_Pin

/** Touch controller command used to read the Y-axis sample. */
#define CMD_RDY                     (0x90U)

/** Touch controller command used to read the X-axis sample. */
#define CMD_RDX                     (0xD0U)

/** Return value from TP_Touchpad_Pressed() when the panel is not pressed. */
#define TOUCHPAD_NOT_PRESSED        (0U)

/** Return value from TP_Touchpad_Pressed() when the panel is pressed. */
#define TOUCHPAD_PRESSED            (1U)

/** Return value from TP_Read_Coordinates() when all requested samples are valid. */
#define TOUCHPAD_DATA_OK            (1U)

/** Return value from TP_Read_Coordinates() when the sample set is incomplete or noisy. */
#define TOUCHPAD_DATA_NOISY         (0U)

/*
 * Hard-coded calibration values retained from the original driver.
 * Recalibrate these values if the Smart Relay panel, controller, or LCD
 * orientation differs from the original hardware.
 */
#define X_OFFSET                    (13U)
#define Y_OFFSET                    (15U)
#define X_MAGNITUDE                 (1.16F)
#define Y_MAGNITUDE                 (1.16F)

/*
 * Converts the 16-bit raw value to nominal screen coordinates.
 * 65535 / 273 ~= 240
 * 65535 / 204 ~= 320
 */
#define X_TRANSLATION               (273U)
#define Y_TRANSLATION               (204U)

/*
 * Number of raw coordinate pairs collected by TP_Read_Coordinates().
 * Seven samples give low latency on GPIO bit-banged SPI while still allowing a robust median/trimmed filter.
 * Keep this value odd and at least 5.
 */
#define NO_OF_POSITION_SAMPLES      (7U)

/** First sorted sample used by the trimmed-mean filter. */
#define TP_FILTER_FIRST_SAMPLE       (2U)

/** Last sorted sample used by the trimmed-mean filter. */
#define TP_FILTER_LAST_SAMPLE        (4U)

/***********************************************************************************************************************
 * Typedef definitions
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Public function declarations
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * @brief Reads one 16-bit raw value from the touchscreen MISO pin.
 *
 * @details The function generates sixteen software clock cycles directly through GPIO. It is an internal touchscreen
 *          primitive retained as a public function to preserve compatibility with the original STM32 driver.
 *
 * @return 16-bit raw value shifted in from TP_MISO_PIN.
 *
 * @note This API does not control TP_CS_PIN.
 **********************************************************************************************************************/
uint16_t TP_Read(void);

/*******************************************************************************************************************//**
 * @brief Writes one 8-bit command to the touchscreen through GPIO bit-banging.
 *
 * @param[in] value  Command byte to transmit, MSB first.
 *
 * @note This API does not control TP_CS_PIN.
 **********************************************************************************************************************/
void TP_Write(uint8_t value);

/*******************************************************************************************************************//**
 * @brief Reads and converts the current touchscreen coordinates.
 *
 * @param[out] Coordinates  Two-element destination array. Coordinates[0] receives X and Coordinates[1] receives Y.
 *
 * @retval TOUCHPAD_DATA_OK    All requested samples were collected while the panel remained pressed.
 * @retval TOUCHPAD_DATA_NOISY The touch was released before all samples were collected.
 *
 * @note The calibration calculation intentionally follows the original STM32 implementation.
 **********************************************************************************************************************/
uint8_t TP_Read_Coordinates(uint16_t Coordinates[2]);

/*******************************************************************************************************************//**
 * @brief Checks whether the touchscreen IRQ input indicates an active touch.
 *
 * @retval TOUCHPAD_PRESSED     TP_IRQ_PIN is active LOW.
 * @retval TOUCHPAD_NOT_PRESSED TP_IRQ_PIN is HIGH.
 **********************************************************************************************************************/
uint8_t TP_Touchpad_Pressed(void);

#endif /* ILI9341_TOUCHSCREEN_H_ */
