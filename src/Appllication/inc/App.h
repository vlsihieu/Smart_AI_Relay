// // // /*******************************************************************************************************************//**
// // //  * @file Smart_Relay_App.h
// // //  * @brief Declares the Smart Relay Home UI and seven-button application interface.
// // //  *
// // //  * This module combines the ILI9341 Home UI with the seven-button application driver. UP, DOWN, LEFT, and RIGHT move
// // //  * the Home cursor in a two-row by three-column grid. OK opens the selected screen, BACK returns to the previous screen,
// // //  * and FRONT returns directly to Home.
// // //  **********************************************************************************************************************/

// // // #ifndef SMART_RELAY_APP_H_
// // // #define SMART_RELAY_APP_H_

// // // /***********************************************************************************************************************
// // //  * Includes
// // //  **********************************************************************************************************************/
// // // #include <stdint.h>
// // // #include "hal_data.h"

// // // /***********************************************************************************************************************
// // //  * Macro definitions
// // //  **********************************************************************************************************************/
// // // #define SMART_RELAY_APP_PROCESS_PERIOD_MS    (10U)

// // // /***********************************************************************************************************************
// // //  * Typedef definitions
// // //  **********************************************************************************************************************/

// // // /** Screens managed by the Smart Relay application. */
// // // typedef enum e_smart_relay_app_screen
// // // {
// // //     SMART_RELAY_APP_SCREEN_HOME = 0,
// // //     SMART_RELAY_APP_SCREEN_START,
// // //     SMART_RELAY_APP_SCREEN_SETUP,
// // //     SMART_RELAY_APP_SCREEN_PROGRAM,
// // //     SMART_RELAY_APP_SCREEN_CARD,
// // //     SMART_RELAY_APP_SCREEN_DIAGNOSTICS,
// // //     SMART_RELAY_APP_SCREEN_USER,
// // //     SMART_RELAY_APP_SCREEN_MAX
// // // } smart_relay_app_screen_t;

// // // /** Selectable items displayed on the Home screen in row-major order. */
// // // typedef enum e_smart_relay_app_home_item
// // // {
// // //     SMART_RELAY_APP_HOME_ITEM_START = 0,
// // //     SMART_RELAY_APP_HOME_ITEM_SETUP,
// // //     SMART_RELAY_APP_HOME_ITEM_PROGRAM,
// // //     SMART_RELAY_APP_HOME_ITEM_CARD,
// // //     SMART_RELAY_APP_HOME_ITEM_DIAGNOSTICS,
// // //     SMART_RELAY_APP_HOME_ITEM_USER,
// // //     SMART_RELAY_APP_HOME_ITEM_MAX
// // // } smart_relay_app_home_item_t;

// // // /** Optional application callback used to draw a completed child screen. */
// // // typedef fsp_err_t (* smart_relay_app_screen_draw_callback_t)(smart_relay_app_screen_t screen, void * p_context);

// // // /** Smart Relay application configuration. */
// // // typedef struct st_smart_relay_app_cfg
// // // {
// // //     smart_relay_app_screen_draw_callback_t p_screen_draw; ///< Optional child-screen drawing callback.
// // //     void                                  * p_context;     ///< Context passed to p_screen_draw.
// // // } smart_relay_app_cfg_t;

// // // /***********************************************************************************************************************
// // //  * Public global variables
// // //  **********************************************************************************************************************/
// // // extern volatile fsp_err_t g_smart_relay_app_error;

// // // /*******************************************************************************************************************//**
// // //  * @addtogroup Smart_Relay_Application
// // //  * @{
// // //  **********************************************************************************************************************/

// // // /***********************************************************************************************************************
// // //  * Public API declarations
// // //  **********************************************************************************************************************/
// // // fsp_err_t Smart_Relay_App_Init(smart_relay_app_cfg_t const * p_cfg);
// // // fsp_err_t Smart_Relay_App_Process(uint32_t elapsed_ms);

// // // smart_relay_app_screen_t    Smart_Relay_App_Get_Active_Screen(void);
// // // smart_relay_app_home_item_t Smart_Relay_App_Get_Selected_Item(void);

// // // void Smart_Relay_App_Run(void);

// // // /*******************************************************************************************************************//**
// // //  * @} (end addtogroup Smart_Relay_Application)
// // //  **********************************************************************************************************************/

// // // #endif /* SMART_RELAY_APP_H_ */


// // /*******************************************************************************************************************//**
// //  * @file Smart_Relay_App.h
// //  * @brief Declares the Smart Relay Home/Relay UI and seven-button application interface.
// //  *
// //  * This module combines the ILI9341 Home bitmap, Relay Control bitmap, and seven-button application driver. Selecting
// //  * Program opens the Relay screen. BACK returns to Home with Program selected, and FRONT returns to Home with Start
// //  * selected. Relay states are simulated in software until the physical relay-output mapping is added.
// //  **********************************************************************************************************************/

// // #ifndef SMART_RELAY_APP_H_
// // #define SMART_RELAY_APP_H_

// // /***********************************************************************************************************************
// //  * Includes
// //  **********************************************************************************************************************/
// // #include <stdbool.h>
// // #include <stdint.h>
// // #include "hal_data.h"

// // /***********************************************************************************************************************
// //  * Macro definitions
// //  **********************************************************************************************************************/
// // #define SMART_RELAY_APP_PROCESS_PERIOD_MS    (10U)
// // #define SMART_RELAY_APP_RELAY_COUNT          (8U)
// // #define SMART_RELAY_APP_RELAY_ALL_MASK       (0xFFU)

// // /***********************************************************************************************************************
// //  * Typedef definitions
// //  **********************************************************************************************************************/

// // /** Screens managed by the Smart Relay application. */
// // typedef enum e_smart_relay_app_screen
// // {
// //     SMART_RELAY_APP_SCREEN_HOME = 0,
// //     SMART_RELAY_APP_SCREEN_START,
// //     SMART_RELAY_APP_SCREEN_SETUP,
// //     SMART_RELAY_APP_SCREEN_PROGRAM,
// //     SMART_RELAY_APP_SCREEN_CARD,
// //     SMART_RELAY_APP_SCREEN_DIAGNOSTICS,
// //     SMART_RELAY_APP_SCREEN_USER,
// //     SMART_RELAY_APP_SCREEN_MAX
// // } smart_relay_app_screen_t;

// // /** Selectable items displayed on the Home screen in row-major order. */
// // typedef enum e_smart_relay_app_home_item
// // {
// //     SMART_RELAY_APP_HOME_ITEM_START = 0,
// //     SMART_RELAY_APP_HOME_ITEM_SETUP,
// //     SMART_RELAY_APP_HOME_ITEM_PROGRAM,
// //     SMART_RELAY_APP_HOME_ITEM_CARD,
// //     SMART_RELAY_APP_HOME_ITEM_DIAGNOSTICS,
// //     SMART_RELAY_APP_HOME_ITEM_USER,
// //     SMART_RELAY_APP_HOME_ITEM_MAX
// // } smart_relay_app_home_item_t;

// // /** Relay channels displayed in row-major order on the two-row by four-column Relay screen. */
// // typedef enum e_smart_relay_app_relay
// // {
// //     SMART_RELAY_APP_RELAY_1 = 0,
// //     SMART_RELAY_APP_RELAY_2,
// //     SMART_RELAY_APP_RELAY_3,
// //     SMART_RELAY_APP_RELAY_4,
// //     SMART_RELAY_APP_RELAY_5,
// //     SMART_RELAY_APP_RELAY_6,
// //     SMART_RELAY_APP_RELAY_7,
// //     SMART_RELAY_APP_RELAY_8,
// //     SMART_RELAY_APP_RELAY_MAX
// // } smart_relay_app_relay_t;

// // /** Optional application callback used to draw a completed child screen. */
// // typedef fsp_err_t (* smart_relay_app_screen_draw_callback_t)(smart_relay_app_screen_t screen, void * p_context);

// // /** Smart Relay application configuration. */
// // typedef struct st_smart_relay_app_cfg
// // {
// //     smart_relay_app_screen_draw_callback_t p_screen_draw;           ///< Optional non-Relay child-screen callback.
// //     void                                  * p_context;               ///< Context passed to p_screen_draw.
// //     uint8_t                                 relay_initial_state_mask; ///< Initial Relay 1 through Relay 8 ON/OFF mask.
// // } smart_relay_app_cfg_t;

// // /***********************************************************************************************************************
// //  * Public global variables
// //  **********************************************************************************************************************/
// // extern volatile fsp_err_t g_smart_relay_app_error;

// // /*******************************************************************************************************************//**
// //  * @addtogroup Smart_Relay_Application
// //  * @{
// //  **********************************************************************************************************************/

// // /***********************************************************************************************************************
// //  * Public API declarations
// //  **********************************************************************************************************************/
// // fsp_err_t Smart_Relay_App_Init(smart_relay_app_cfg_t const * p_cfg);
// // fsp_err_t Smart_Relay_App_Process(uint32_t elapsed_ms);

// // smart_relay_app_screen_t    Smart_Relay_App_Get_Active_Screen(void);
// // smart_relay_app_home_item_t Smart_Relay_App_Get_Selected_Item(void);
// // smart_relay_app_relay_t     Smart_Relay_App_Get_Selected_Relay(void);
// // uint8_t                     Smart_Relay_App_Get_Relay_State_Mask(void);
// // bool                        Smart_Relay_App_Get_Relay_State(smart_relay_app_relay_t relay);

// // void Smart_Relay_App_Run(void);

// // /*******************************************************************************************************************//**
// //  * @} (end addtogroup Smart_Relay_Application)
// //  **********************************************************************************************************************/

// // #endif /* SMART_RELAY_APP_H_ */


// /*******************************************************************************************************************//**
//  * @file Smart_Relay_App.h
//  * @brief Declares the Smart Relay Home/Relay UI and seven-button application interface.
//  *
//  * This module combines the Home UI, the dedicated UI_Relay layer, and the seven-button application driver. Selecting
//  * Program opens UI_Relay. BACK returns to Home with Program selected, and FRONT returns to Home with Start selected.
//  **********************************************************************************************************************/

// #ifndef SMART_RELAY_APP_H_
// #define SMART_RELAY_APP_H_

// /***********************************************************************************************************************
//  * Includes
//  **********************************************************************************************************************/
// #include <stdint.h>
// #include "hal_data.h"
// #include "Ui_Relay_ep.h"

// /***********************************************************************************************************************
//  * Macro definitions
//  **********************************************************************************************************************/
// #define SMART_RELAY_APP_PROCESS_PERIOD_MS    (10U)

// /***********************************************************************************************************************
//  * Typedef definitions
//  **********************************************************************************************************************/

// /** Screens managed by the Smart Relay application. */
// typedef enum e_smart_relay_app_screen
// {
//     SMART_RELAY_APP_SCREEN_HOME = 0,
//     SMART_RELAY_APP_SCREEN_START,
//     SMART_RELAY_APP_SCREEN_SETUP,
//     SMART_RELAY_APP_SCREEN_PROGRAM,
//     SMART_RELAY_APP_SCREEN_CARD,
//     SMART_RELAY_APP_SCREEN_DIAGNOSTICS,
//     SMART_RELAY_APP_SCREEN_USER,
//     SMART_RELAY_APP_SCREEN_MAX
// } smart_relay_app_screen_t;

// /** Selectable items displayed on the Home screen in row-major order. */
// typedef enum e_smart_relay_app_home_item
// {
//     SMART_RELAY_APP_HOME_ITEM_START = 0,
//     SMART_RELAY_APP_HOME_ITEM_SETUP,
//     SMART_RELAY_APP_HOME_ITEM_PROGRAM,
//     SMART_RELAY_APP_HOME_ITEM_CARD,
//     SMART_RELAY_APP_HOME_ITEM_DIAGNOSTICS,
//     SMART_RELAY_APP_HOME_ITEM_USER,
//     SMART_RELAY_APP_HOME_ITEM_MAX
// } smart_relay_app_home_item_t;

// /** Optional application callback used to draw a completed non-Relay child screen. */
// typedef fsp_err_t (* smart_relay_app_screen_draw_callback_t)(smart_relay_app_screen_t screen, void * p_context);

// /** Smart Relay application configuration. */
// typedef struct st_smart_relay_app_cfg
// {
//     smart_relay_app_screen_draw_callback_t p_screen_draw;           ///< Optional non-Relay child-screen callback.
//     void                                  * p_context;               ///< Context passed to p_screen_draw.
//     ui_relay_output_write_callback_t        p_relay_write;           ///< Optional physical relay-output callback.
//     void                                  * p_relay_context;         ///< Context passed to p_relay_write.
//     uint8_t                                 relay_initial_state_mask; ///< Initial Relay 1 through Relay 8 state mask.
// } smart_relay_app_cfg_t;

// /***********************************************************************************************************************
//  * Public global variables
//  **********************************************************************************************************************/
// extern volatile fsp_err_t g_smart_relay_app_error;

// /*******************************************************************************************************************//**
//  * @addtogroup Smart_Relay_Application
//  * @{
//  **********************************************************************************************************************/

// /***********************************************************************************************************************
//  * Public API declarations
//  **********************************************************************************************************************/
// fsp_err_t Smart_Relay_App_Init(smart_relay_app_cfg_t const * p_cfg);
// fsp_err_t Smart_Relay_App_Process(uint32_t elapsed_ms);

// smart_relay_app_screen_t    Smart_Relay_App_Get_Active_Screen(void);
// smart_relay_app_home_item_t Smart_Relay_App_Get_Selected_Item(void);

// void Smart_Relay_App_Run(void);

// /*******************************************************************************************************************//**
//  * @} (end addtogroup Smart_Relay_Application)
//  **********************************************************************************************************************/

// #endif /* SMART_RELAY_APP_H_ */

/*******************************************************************************************************************//**
 * @file App.h
 * @brief Declares the Smart Relay Home/Relay UI and seven-button application interface.
 *
 * This module combines the Home UI, the dedicated UI_Relay layer, and the seven-button application driver. Selecting
 * Program opens UI_Relay. BACK returns to Home with Program selected, and FRONT returns to Home with Start selected.
 **********************************************************************************************************************/

#ifndef APP_H_
#define APP_H_

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/
#include <stdint.h>
#include "hal_data.h"
#include "Ui_Relay_ep.h"

/***********************************************************************************************************************
 * Macro definitions
 **********************************************************************************************************************/
#define SMART_RELAY_APP_PROCESS_PERIOD_MS    (10U)

/***********************************************************************************************************************
 * Typedef definitions
 **********************************************************************************************************************/

/** Screens managed by the Smart Relay application. */
typedef enum e_smart_relay_app_screen
{
    SMART_RELAY_APP_SCREEN_HOME = 0,
    SMART_RELAY_APP_SCREEN_START,
    SMART_RELAY_APP_SCREEN_SETUP,
    SMART_RELAY_APP_SCREEN_PROGRAM,
    SMART_RELAY_APP_SCREEN_CARD,
    SMART_RELAY_APP_SCREEN_DIAGNOSTICS,
    SMART_RELAY_APP_SCREEN_USER,
    SMART_RELAY_APP_SCREEN_MAX
} smart_relay_app_screen_t;

/** Selectable items displayed on the Home screen in row-major order. */
typedef enum e_smart_relay_app_home_item
{
    SMART_RELAY_APP_HOME_ITEM_START = 0,
    SMART_RELAY_APP_HOME_ITEM_SETUP,
    SMART_RELAY_APP_HOME_ITEM_PROGRAM,
    SMART_RELAY_APP_HOME_ITEM_CARD,
    SMART_RELAY_APP_HOME_ITEM_DIAGNOSTICS,
    SMART_RELAY_APP_HOME_ITEM_USER,
    SMART_RELAY_APP_HOME_ITEM_MAX
} smart_relay_app_home_item_t;

/** Optional application callback used to draw a completed non-Relay child screen. */
typedef fsp_err_t (* smart_relay_app_screen_draw_callback_t)(smart_relay_app_screen_t screen, void * p_context);

/** Smart Relay application configuration. */
typedef struct st_smart_relay_app_cfg
{
    smart_relay_app_screen_draw_callback_t p_screen_draw;           ///< Optional non-Relay child-screen callback.
    void                                  * p_context;               ///< Context passed to p_screen_draw.
    ui_relay_output_write_callback_t        p_relay_write;           ///< Optional physical relay-output callback.
    void                                  * p_relay_context;         ///< Context passed to p_relay_write.
    uint8_t                                 relay_initial_state_mask; ///< Initial Relay 1 through Relay 8 state mask.
} smart_relay_app_cfg_t;

/***********************************************************************************************************************
 * Public global variables
 **********************************************************************************************************************/
extern volatile fsp_err_t g_smart_relay_app_error;

/*******************************************************************************************************************//**
 * @addtogroup Smart_Relay_Application
 * @{
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Public API declarations
 **********************************************************************************************************************/
fsp_err_t Smart_Relay_App_Init(smart_relay_app_cfg_t const * p_cfg);
fsp_err_t Smart_Relay_App_Process(uint32_t elapsed_ms);

smart_relay_app_screen_t    Smart_Relay_App_Get_Active_Screen(void);
smart_relay_app_home_item_t Smart_Relay_App_Get_Selected_Item(void);

void Smart_Relay_App_Run(void);

/*******************************************************************************************************************//**
 * @} (end addtogroup Smart_Relay_Application)
 **********************************************************************************************************************/

#endif /* APP_H_ */