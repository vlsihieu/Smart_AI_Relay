/*******************************************************************************************************************//**
 * @file Ui_Home_ep.h
 * @brief Declares the Smart Relay bitmap UI and four-button navigation APIs.
 *
 * This module displays the RGB565 Home image on an ILI9341 LCD and processes NEXT, OK, BACK, and HOME button events.
 * Smart_Relay_UI_Button_Callback() only sets event flags. LCD drawing and SPI transfers are performed by
 * Smart_Relay_UI_Process(). The button callback argument type is defined by this module and does not depend on the
 * Renesas External IRQ callback type.
 **********************************************************************************************************************/

#ifndef UI_HOME_EP_H_
#define UI_HOME_EP_H_

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/

#include <stdint.h>
#include "bsp_api.h"

/***********************************************************************************************************************
 * Typedef definitions
 **********************************************************************************************************************/

/** Screens controlled by the Smart Relay UI state machine. */
typedef enum e_smart_relay_ui_screen
{
    Smart_Relay_Ui_Screen_HOME = 0,
    Smart_Relay_Ui_Screen_START,
    Smart_Relay_Ui_Screen_SETUP,
    Smart_Relay_Ui_Screen_RELAY,
    Smart_Relay_Ui_Screen_CARD,
    Smart_Relay_Ui_Screen_DIAGNOSTICS,
    Smart_Relay_Ui_Screen_PROJECT_QR
} Smart_Relay_Ui_Screen_t;

/** Selectable items displayed on the Home screen. */
typedef enum e_smart_relay_ui_home_item
{
    Smart_Relay_Ui_Home_Item_START = 0,
    Smart_Relay_Ui_Home_Item_SETUP,
    Smart_Relay_Ui_Home_Item_PROGRAM,
    Smart_Relay_Ui_Home_Item_CARD,
    Smart_Relay_Ui_Home_Item_DIAGNOSTICS,
    Smart_Relay_Ui_Home_Item_USER,
    Smart_Relay_Ui_Home_Item_MAX
} Smart_Relay_Ui_Home_Item_t;

/** Button events accepted by the Smart Relay UI. */
typedef enum e_smart_relay_ui_button
{
    Smart_Relay_Ui_Button_NEXT = 0,
    Smart_Relay_Ui_Button_OK,
    Smart_Relay_Ui_Button_BACK,
    Smart_Relay_Ui_Button_HOME
} Smart_Relay_Ui_Button_t;

/** Arguments passed to Smart_Relay_UI_Button_Callback(). */
typedef struct st_smart_relay_ui_button_args
{
    Smart_Relay_Ui_Button_t button;    ///< Button event to be processed by the UI.
} Smart_Relay_Ui_Button_Args_t;

/**
 * Application callback used to draw a child screen selected from Home.
 *
 * @param[in] screen     Screen requested by the UI state machine.
 * @param[in] p_context  Application context supplied in smart_relay_ui_cfg_t.
 *
 * @retval FSP_SUCCESS The requested screen was drawn successfully.
 * @return Any other FSP error code returned by the application screen handler.
 */
typedef fsp_err_t (* smart_relay_ui_screen_open_callback_t)(Smart_Relay_Ui_Screen_t screen, void * p_context);

/** Smart Relay UI configuration. */
typedef struct st_smart_relay_ui_cfg
{
    smart_relay_ui_screen_open_callback_t p_screen_open; ///< Callback that draws child screens.
    void                                * p_context;     ///< Application context passed to the callback.
} smart_relay_ui_cfg_t;

/*******************************************************************************************************************//**
 * @addtogroup Smart_Relay_UI
 * @{
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Public API declarations
 **********************************************************************************************************************/

fsp_err_t Smart_Relay_UI_Init(smart_relay_ui_cfg_t const * p_cfg);
fsp_err_t Smart_Relay_UI_Load_Home(void);
fsp_err_t Smart_Relay_UI_Process(void);

Smart_Relay_Ui_Screen_t Smart_Relay_UI_Get_Active_Screen(void);
Smart_Relay_Ui_Home_Item_t Smart_Relay_UI_Get_Selected_Item(void);

void Smart_Relay_UI_Button_Callback(Smart_Relay_Ui_Button_Args_t const * p_args);
void app_main(void);

/*******************************************************************************************************************//**
 * @} (end addtogroup Smart_Relay_UI)
 **********************************************************************************************************************/

#endif /* UI_HOME_EP_H */
