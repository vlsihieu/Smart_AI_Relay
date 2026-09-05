/*******************************************************************************************************************//**
 * @file BTN_ep.h
 * @brief Declares the seven-button application interface used by the Smart Relay UI.
 *
 * This module maps seven FSP GPIO pin symbols to logical navigation buttons and converts low-level button events into
 * non-blocking UI actions. It also reports press, release, click, long-press, and repeat event masks to the application.
 **********************************************************************************************************************/

#ifndef BTN_EP_H_
#define BTN_EP_H_

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/
#include <stdint.h>
#include "bsp_pin_cfg.h"
#include "BTN_Driver.h"

/***********************************************************************************************************************
 * Macro definitions
 **********************************************************************************************************************/

/* Button timing configuration. */
#define BUTTON_APP_PROCESS_PERIOD_MS       (10U)
#define BUTTON_APP_DEBOUNCE_TIME_MS        (20U)
#define BUTTON_APP_LONG_PRESS_TIME_MS      (1000U)
#define BUTTON_APP_REPEAT_START_TIME_MS    (200U)
#define BUTTON_APP_REPEAT_PERIOD_MS        (70U)

/* Converts a button ID to its bit position in a button event mask. */
#define BUTTON_APP_BUTTON_MASK(button_id)  ((uint32_t) 1UL << (uint32_t) (button_id))

/***********************************************************************************************************************
 * Typedef definitions
 **********************************************************************************************************************/

/** Semantic actions consumed by the Smart Relay UI. Multiple actions can be reported in one processing cycle. */
typedef enum e_button_app_action
{
    BUTTON_APP_ACTION_NONE   = 0x00000000U,
    BUTTON_APP_ACTION_UP     = 0x00000001U,
    BUTTON_APP_ACTION_DOWN   = 0x00000002U,
    BUTTON_APP_ACTION_LEFT   = 0x00000004U,
    BUTTON_APP_ACTION_RIGHT  = 0x00000008U,
    BUTTON_APP_ACTION_SELECT = 0x00000010U,
    BUTTON_APP_ACTION_BACK   = 0x00000020U,
    BUTTON_APP_ACTION_FRONT  = 0x00000040U,
    BUTTON_APP_ACTION_HOME   = BUTTON_APP_ACTION_FRONT
} button_app_action_t;

/** Button information returned to the application after each processing cycle. */
typedef struct st_button_app_output
{
    uint32_t actions;      ///< Bit mask containing button_app_action_t values.
    uint32_t pressed;      ///< Buttons that generated BUTTON_EVENT_PRESSED.
    uint32_t released;     ///< Buttons that generated BUTTON_EVENT_RELEASED.
    uint32_t clicked;      ///< Buttons that generated BUTTON_EVENT_CLICKED.
    uint32_t long_pressed; ///< Buttons that generated BUTTON_EVENT_LONG_PRESSED.
    uint32_t repeated;     ///< Buttons that generated BUTTON_EVENT_REPEAT.
} button_app_output_t;

/*******************************************************************************************************************//**
 * @addtogroup Button_Application
 * @{
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Public function declarations
 **********************************************************************************************************************/

fsp_err_t Button_App_Init(void);
fsp_err_t Button_App_Process(uint32_t elapsed_ms, button_app_output_t * p_output);
fsp_err_t Button_App_Close(void);
void      app_main_btn(void);

/*******************************************************************************************************************//**
 * @} (end addtogroup Button_Application)
 **********************************************************************************************************************/

#endif /* BTN_EP_H_ */
