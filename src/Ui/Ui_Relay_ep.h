/*******************************************************************************************************************//**
 * @file UI_Relay.h
 * @brief Declares the eight-channel relay-control UI for the Smart Relay application.
 *
 * The module owns the Relay Control bitmap, the two-row by four-column focus state, and the visual ON/OFF state of
 * eight relays. The application supplies navigation actions and may provide a callback that writes the selected state
 * to the real relay hardware.
 **********************************************************************************************************************/

#ifndef UI_RELAY_H_
#define UI_RELAY_H_

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/
#include <stdbool.h>
#include <stdint.h>
#include "hal_data.h"

/***********************************************************************************************************************
 * Macro definitions
 **********************************************************************************************************************/

#define UI_RELAY_CHANNEL_COUNT          (8U)
#define UI_RELAY_ALL_CHANNELS_MASK      (0xFFU)

/***********************************************************************************************************************
 * Typedef definitions
 **********************************************************************************************************************/

/** Relay channels displayed in row-major order. */
typedef enum e_ui_relay_channel
{
    UI_RELAY_CHANNEL_1 = 0,
    UI_RELAY_CHANNEL_2,
    UI_RELAY_CHANNEL_3,
    UI_RELAY_CHANNEL_4,
    UI_RELAY_CHANNEL_5,
    UI_RELAY_CHANNEL_6,
    UI_RELAY_CHANNEL_7,
    UI_RELAY_CHANNEL_8,
    UI_RELAY_CHANNEL_MAX
} ui_relay_channel_t;

/** Generic actions accepted by UI_Relay_Process(). Multiple bits may be supplied in one call. */
typedef enum e_ui_relay_action
{
    UI_RELAY_ACTION_NONE   = 0x00000000U,
    UI_RELAY_ACTION_UP     = 0x00000001U,
    UI_RELAY_ACTION_DOWN   = 0x00000002U,
    UI_RELAY_ACTION_LEFT   = 0x00000004U,
    UI_RELAY_ACTION_RIGHT  = 0x00000008U,
    UI_RELAY_ACTION_SELECT = 0x00000010U,
    UI_RELAY_ACTION_BACK   = 0x00000020U,
    UI_RELAY_ACTION_HOME   = 0x00000040U
} ui_relay_action_t;

/** Navigation request returned to the application after processing Relay-screen actions. */
typedef enum e_ui_relay_navigation
{
    UI_RELAY_NAVIGATION_NONE = 0,
    UI_RELAY_NAVIGATION_BACK,
    UI_RELAY_NAVIGATION_HOME
} ui_relay_navigation_t;

/** Optional callback used to apply a relay state to the hardware output layer. */
typedef fsp_err_t (* ui_relay_output_write_callback_t)(ui_relay_channel_t channel,
                                                       bool               enabled,
                                                       void             * p_context);

/** Relay UI configuration. */
typedef struct st_ui_relay_cfg
{
    ui_relay_output_write_callback_t p_output_write;      ///< Optional relay hardware callback.
    void                           * p_context;           ///< Context passed to p_output_write.
    uint8_t                          initial_state_mask;  ///< Bit 0 through bit 7 represent Relay 1 through Relay 8.
} ui_relay_cfg_t;

/*******************************************************************************************************************//**
 * @addtogroup UI_Relay
 * @{
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Public API declarations
 **********************************************************************************************************************/

fsp_err_t UI_Relay_Init(ui_relay_cfg_t const * p_cfg);
fsp_err_t UI_Relay_Open(void);
fsp_err_t UI_Relay_Process(uint32_t actions, ui_relay_navigation_t * p_navigation);
fsp_err_t UI_Relay_Set_State(ui_relay_channel_t channel, bool enabled);
fsp_err_t UI_Relay_Close(void);

ui_relay_channel_t UI_Relay_Get_Selected_Channel(void);
uint8_t            UI_Relay_Get_State_Mask(void);
bool               UI_Relay_Get_State(ui_relay_channel_t channel);
bool               UI_Relay_Is_Active(void);
void               app_main_relay();

/*******************************************************************************************************************//**
 * @} (end addtogroup UI_Relay)
 **********************************************************************************************************************/

#endif /* UI_RELAY_H_ */