/*******************************************************************************************************************//**
 * @file App1.h
 * @brief Declares the touch-enabled Smart Relay application built from the existing App module logic.
 *
 * App1 keeps the existing Smart Relay screen, relay, QR, and software-clock behavior but replaces the seven-button
 * input path with the ILI9341 touchscreen driver. Press/release debounce prevents false retriggering, while the existing App.h types are reused so App1 can use the same
 * application configuration callbacks as App.c.
 **********************************************************************************************************************/

#ifndef APP1_H_
#define APP1_H_

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/

#include <Appllication/inc/App.h>
#include <stdint.h>
#include "hal_data.h"

/***********************************************************************************************************************
 * Macro definitions
 **********************************************************************************************************************/

/** Physical LCD width used by SCREEN_HORIZONTAL_1. */
#define SMART_RELAY_APP1_SCREEN_WIDTH                  (320U)

/** Physical LCD height used by SCREEN_HORIZONTAL_1. */
#define SMART_RELAY_APP1_SCREEN_HEIGHT                 (240U)

/**
 * Legacy touchscreen calibration was written for SCREEN_VERTICAL_1 while the Smart Relay Home bitmap is displayed in
 * SCREEN_HORIZONTAL_1. These three switches convert the legacy 240 x 320 coordinates into 320 x 240 coordinates.
 *
 * Default mapping:
 *     screen_x = touch_y
 *     screen_y = 239 - touch_x
 *
 * Change these switches only when the real panel is found to be rotated or mirrored differently.
 */
#define SMART_RELAY_APP1_TOUCH_SWAP_XY                 (1U)
#define SMART_RELAY_APP1_TOUCH_INVERT_X                (0U)
#define SMART_RELAY_APP1_TOUCH_INVERT_Y                (1U)

/** Stable LOW time required before a press is accepted. */
#define SMART_RELAY_APP1_TOUCH_PRESS_DEBOUNCE_MS       (20U)

/** Stable HIGH time required before the next press can be armed. */
#define SMART_RELAY_APP1_TOUCH_RELEASE_DEBOUNCE_MS     (30U)

/** Y coordinate from which the child-screen navigation area starts. */
#define SMART_RELAY_APP1_NAVIGATION_Y_MIN              (200U)

/** X coordinate separating BACK and HOME touch zones in the bottom navigation area. */
#define SMART_RELAY_APP1_NAVIGATION_X_SPLIT            (160U)

/** Left edge of the two-row by four-column relay touch grid. */
#define SMART_RELAY_APP1_RELAY_GRID_X0                 (8U)

/** Right edge of the two-row by four-column relay touch grid. */
#define SMART_RELAY_APP1_RELAY_GRID_X1                 (311U)

/** Top edge of the two-row by four-column relay touch grid. */
#define SMART_RELAY_APP1_RELAY_GRID_Y0                 (30U)

/** Bottom edge of the two-row by four-column relay touch grid. */
#define SMART_RELAY_APP1_RELAY_GRID_Y1                 (190U)

/** Number of columns used by the Relay UI. */
#define SMART_RELAY_APP1_RELAY_COLUMN_COUNT            (4U)

/** Number of rows used by the Relay UI. */
#define SMART_RELAY_APP1_RELAY_ROW_COUNT               (2U)

/***********************************************************************************************************************
 * Typedef definitions
 **********************************************************************************************************************/

/** Reuses the existing App configuration structure without changing the current application callback contract. */
typedef smart_relay_app_cfg_t smart_relay_app1_cfg_t;

/** Reuses the existing Smart Relay screen enumeration. */
typedef smart_relay_app_screen_t smart_relay_app1_screen_t;

/** Reuses the existing Home-menu item enumeration. */
typedef smart_relay_app_home_item_t smart_relay_app1_home_item_t;

/***********************************************************************************************************************
 * Global variables
 **********************************************************************************************************************/

/** Last App1 processing error. Useful while bringing up the touchscreen on hardware. */
extern volatile fsp_err_t g_smart_relay_app1_error;

/** Last valid transformed touchscreen X coordinate. */
extern volatile uint16_t g_smart_relay_app1_touch_x;

/** Last valid transformed touchscreen Y coordinate. */
extern volatile uint16_t g_smart_relay_app1_touch_y;

/** Number of valid touch presses accepted by App1. */
extern volatile uint32_t g_smart_relay_app1_touch_count;

/** Number of pressed samples rejected because TP_Read_Coordinates() reported noisy data. */
extern volatile uint32_t g_smart_relay_app1_touch_noisy_count;

/***********************************************************************************************************************
 * Public function declarations
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * @brief Initializes the touch-enabled Smart Relay application.
 *
 * @param[in] p_cfg Optional application configuration. NULL selects the existing built-in relay driver and default
 *                  child-screen renderer, matching Smart_Relay_App_Init().
 *
 * @retval FSP_SUCCESS          Application initialized successfully.
 * @retval FSP_ERR_ALREADY_OPEN App1 is already initialized.
 * @return Any other FSP error code returned by the LCD, Relay UI, QR UI, or relay driver.
 **********************************************************************************************************************/
fsp_err_t Smart_Relay_App1_Init(smart_relay_app1_cfg_t const * p_cfg);

/*******************************************************************************************************************//**
 * @brief Polls the touchscreen once and advances the existing Smart Relay application state machine.
 *
 * @details One touch action is generated for each physical press. Holding the finger on the panel does not repeatedly
 *          trigger the selected function. A new action becomes possible after TP_IRQ returns to the released state.
 *
 * @param[in] elapsed_ms Time elapsed since the previous call, in milliseconds.
 *
 * @retval FSP_SUCCESS              Application processed successfully.
 * @retval FSP_ERR_NOT_OPEN         App1 is not initialized.
 * @retval FSP_ERR_INVALID_ARGUMENT elapsed_ms is zero.
 * @return Any error returned by the display or child UI modules.
 **********************************************************************************************************************/
fsp_err_t Smart_Relay_App1_Process(uint32_t elapsed_ms);

/*******************************************************************************************************************//**
 * @brief Returns the active Smart Relay screen.
 *
 * @return Current Smart Relay screen.
 **********************************************************************************************************************/
smart_relay_app1_screen_t Smart_Relay_App1_Get_Active_Screen(void);

/*******************************************************************************************************************//**
 * @brief Returns the currently selected Home item.
 *
 * @return Current Home-menu selection.
 **********************************************************************************************************************/
smart_relay_app1_home_item_t Smart_Relay_App1_Get_Selected_Item(void);

/*******************************************************************************************************************//**
 * @brief Runs the standalone touch-enabled Smart Relay application loop.
 *
 * @note Call this function from hal_entry() instead of Smart_Relay_App_Run() when testing App1.
 **********************************************************************************************************************/
void Smart_Relay_App1_Run(void);

#endif /* APP1_H_ */
