/*******************************************************************************************************************//**
 * @file Relay_Driver.h
 * @brief Declares the eight-channel relay output driver for the Smart Relay board.
 *
 * Relay 1 through Relay 8 are connected to FSP pin symbols Y1_Pin through Y8_Pin. The board input stage is active-high:
 * writing HIGH energizes the selected relay and writing LOW releases it.
 **********************************************************************************************************************/

#ifndef RELAY_DRIVER_H_
#define RELAY_DRIVER_H_

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/
#include <stdbool.h>
#include <stdint.h>
#include "hal_data.h"
#include "bsp_pin_cfg.h"

/***********************************************************************************************************************
 * Macro definitions
 **********************************************************************************************************************/

#define RELAY_DRIVER_CHANNEL_COUNT       (8U)
#define RELAY_DRIVER_ALL_CHANNELS_MASK   (0xFFU)

/* Smart Relay output-pin mapping. */
#define RELAY_DRIVER_Y1_PIN              Y1_Pin
#define RELAY_DRIVER_Y2_PIN              Y2_Pin
#define RELAY_DRIVER_Y3_PIN              Y3_Pin
#define RELAY_DRIVER_Y4_PIN              Y4_Pin
#define RELAY_DRIVER_Y5_PIN              Y5_Pin
#define RELAY_DRIVER_Y6_PIN              Y6_Pin
#define RELAY_DRIVER_Y7_PIN              Y7_Pin
#define RELAY_DRIVER_Y8_PIN              Y8_Pin

/* The optocoupler input stage is energized when the Yx output is driven HIGH. */
#define RELAY_DRIVER_ACTIVE_LEVEL        BSP_IO_LEVEL_HIGH
#define RELAY_DRIVER_INACTIVE_LEVEL      BSP_IO_LEVEL_LOW

/***********************************************************************************************************************
 * Typedef definitions
 **********************************************************************************************************************/

/** Relay channels in Y1 through Y8 order. */
typedef enum e_relay_driver_channel
{
    RELAY_DRIVER_CHANNEL_1 = 0,
    RELAY_DRIVER_CHANNEL_2,
    RELAY_DRIVER_CHANNEL_3,
    RELAY_DRIVER_CHANNEL_4,
    RELAY_DRIVER_CHANNEL_5,
    RELAY_DRIVER_CHANNEL_6,
    RELAY_DRIVER_CHANNEL_7,
    RELAY_DRIVER_CHANNEL_8,
    RELAY_DRIVER_CHANNEL_MAX
} relay_driver_channel_t;

/*******************************************************************************************************************//**
 * @addtogroup Relay_Driver
 * @{
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Public API declarations
 **********************************************************************************************************************/

fsp_err_t Relay_Driver_Init(void);
fsp_err_t Relay_Driver_Write(relay_driver_channel_t channel, bool enabled);
fsp_err_t Relay_Driver_Write_Mask(uint8_t state_mask);
fsp_err_t Relay_Driver_All_Off(void);
fsp_err_t Relay_Driver_All_On(void);
fsp_err_t Relay_Driver_Close(void);

bool    Relay_Driver_Get_State(relay_driver_channel_t channel);
uint8_t Relay_Driver_Get_State_Mask(void);

/*******************************************************************************************************************//**
 * @} (end addtogroup Relay_Driver)
 **********************************************************************************************************************/

#endif /* RELAY_DRIVER_H_ */