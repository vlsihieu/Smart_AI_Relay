/*******************************************************************************************************************//**
 * @file Relay_ep.h
 * @brief Declares the eight-channel relay application interface used by the Smart Relay UI.
 *
 * This module sits between the Smart Relay application and Relay_Driver. It initializes all relay outputs safely,
 * applies logical ON/OFF commands, supports channel toggling, and exposes the last successfully applied state mask.
 **********************************************************************************************************************/

#ifndef RELAY_EP_H_
#define RELAY_EP_H_

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/
#include <stdbool.h>
#include <stdint.h>
#include "hal_data.h"

/***********************************************************************************************************************
 * Macro definitions
 **********************************************************************************************************************/

#define RELAY_APP_CHANNEL_COUNT       (8U)
#define RELAY_APP_ALL_CHANNELS_MASK   (0xFFU)

/***********************************************************************************************************************
 * Typedef definitions
 **********************************************************************************************************************/

/** Logical relay channels in Y1 through Y8 order. */
typedef enum e_relay_app_channel
{
    RELAY_APP_CHANNEL_1 = 0,
    RELAY_APP_CHANNEL_2,
    RELAY_APP_CHANNEL_3,
    RELAY_APP_CHANNEL_4,
    RELAY_APP_CHANNEL_5,
    RELAY_APP_CHANNEL_6,
    RELAY_APP_CHANNEL_7,
    RELAY_APP_CHANNEL_8,
    RELAY_APP_CHANNEL_MAX
} relay_app_channel_t;

/*******************************************************************************************************************//**
 * @addtogroup Relay_Application
 * @{
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Public API declarations
 **********************************************************************************************************************/

fsp_err_t Relay_App_Init(uint8_t initial_state_mask);
fsp_err_t Relay_App_Write(relay_app_channel_t channel, bool enabled);
fsp_err_t Relay_App_Toggle(relay_app_channel_t channel, bool * p_enabled);
fsp_err_t Relay_App_Write_Mask(uint8_t state_mask);
fsp_err_t Relay_App_All_Off(void);
fsp_err_t Relay_App_All_On(void);
fsp_err_t Relay_App_Close(void);

bool    Relay_App_Get_State(relay_app_channel_t channel);
uint8_t Relay_App_Get_State_Mask(void);
bool    Relay_App_Is_Initialized(void);

/*******************************************************************************************************************//**
 * @} (end addtogroup Relay_Application)
 **********************************************************************************************************************/

#endif /* RELAY_EP_H_ */