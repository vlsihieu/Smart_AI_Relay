
/*******************************************************************************************************************//**
 * @file App.c
 * @brief Implements the Smart Relay Home/Relay UI and seven-button application state machine.
 *
 * The Home screen is loaded from ui_home_320x240_rgb565.h. Button_App_Process() supplies debounced button actions.
 * Direction buttons move the cursor in a two-row by three-column grid. OK opens the selected screen, BACK returns to
 * the previous screen, and FRONT returns directly to Home. Selecting Program opens the dedicated UI_Relay layer.
 * A software MM:SS clock is maintained without an RTC.
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/
#include <stdbool.h>
#include <stddef.h>
#include "App.h"
#include "BTN_ep.h"
#include "ILI9341_GFX.h"
#include "Relay_ep.h"
#include "Ui_Relay_ep.h"
#include "ui_home_320x240_rgb565.h"
#include "Ui_QR_ep.h"

/***********************************************************************************************************************
 * Macro definitions
 **********************************************************************************************************************/

/* Home menu geometry. */
#define SMART_RELAY_APP_HOME_COLUMN_COUNT           (3U)
#define SMART_RELAY_APP_HOME_ROW_COUNT              (2U)

/* Cursor colors sampled from the Home bitmap. */
#define SMART_RELAY_APP_HOME_BACKGROUND_COLOR       (0x08A5U)
#define SMART_RELAY_APP_CURSOR_COLOR                (0xFFE0U)

/* Software clock configuration. */
#define SMART_RELAY_APP_ONE_SECOND_MS                (1000U)
#define SMART_RELAY_APP_TIMER_START_MINUTE           (0U)
#define SMART_RELAY_APP_TIMER_START_SECOND           (20U)
#define SMART_RELAY_APP_TIMER_MINUTE_LIMIT           (100U)

/* Clock drawing area in the Home bitmap header. */
#define SMART_RELAY_APP_CLOCK_AREA_X                 (236U)
#define SMART_RELAY_APP_CLOCK_AREA_Y                 (9U)
#define SMART_RELAY_APP_CLOCK_AREA_WIDTH             (27U)
#define SMART_RELAY_APP_CLOCK_AREA_HEIGHT            (7U)
#define SMART_RELAY_APP_CLOCK_DIGIT_WIDTH            (5U)
#define SMART_RELAY_APP_CLOCK_DIGIT_HEIGHT           (7U)
#define SMART_RELAY_APP_MINUTE_TENS_OFFSET           (0U)
#define SMART_RELAY_APP_MINUTE_ONES_OFFSET           (6U)
#define SMART_RELAY_APP_CLOCK_COLON_X_OFFSET         (13U)
#define SMART_RELAY_APP_SECOND_TENS_OFFSET           (16U)
#define SMART_RELAY_APP_SECOND_ONES_OFFSET           (22U)

/* RGB565 colors used by the Home clock and default child-screen renderer. */
#define SMART_RELAY_APP_HEADER_BACKGROUND_COLOR      (0x1271U)
#define SMART_RELAY_APP_CLOCK_TEXT_COLOR             (0xCEFEU)
#define SMART_RELAY_APP_CHILD_BACKGROUND_COLOR       (0x08A5U)

/***********************************************************************************************************************
 * Typedef definitions
 **********************************************************************************************************************/

/** Cursor rectangle and destination screen associated with one Home item. */
typedef struct st_smart_relay_app_menu_position
{
    uint16_t                   x0;
    uint16_t                   y0;
    uint16_t                   x1;
    uint16_t                   y1;
    smart_relay_app_screen_t   destination_screen;
} smart_relay_app_menu_position_t;

/***********************************************************************************************************************
 * Private function declarations
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app_render_home(void);
static fsp_err_t smart_relay_app_draw_cursor(smart_relay_app_home_item_t item, uint16_t color);
static fsp_err_t smart_relay_app_move_cursor(uint32_t action);
static fsp_err_t smart_relay_app_handle_select(void);
static fsp_err_t smart_relay_app_handle_back(void);
static fsp_err_t smart_relay_app_handle_front(void);
static fsp_err_t smart_relay_app_process_relay_screen(uint32_t button_actions);
static fsp_err_t smart_relay_app_draw_child_screen(smart_relay_app_screen_t screen);
static fsp_err_t smart_relay_app_draw_default_child_screen(smart_relay_app_screen_t screen);
static fsp_err_t smart_relay_app_clock_process(uint32_t elapsed_ms);
static fsp_err_t smart_relay_app_clock_draw(void);
static fsp_err_t smart_relay_app_relay_write(ui_relay_channel_t channel, bool enabled, void * p_context);
static void      smart_relay_app_clock_render_digit(uint8_t digit, uint16_t x_offset);
static fsp_err_t smart_relay_app_process_qr_screen(uint32_t button_actions);

/***********************************************************************************************************************
 * Private global variables
 **********************************************************************************************************************/

/* Cursor rectangles are positioned outside the tile borders stored in the Home bitmap. */
static smart_relay_app_menu_position_t const g_smart_relay_app_home_menu[SMART_RELAY_APP_HOME_ITEM_MAX] =
{
    {8U,   30U, 103U, 113U, SMART_RELAY_APP_SCREEN_START},
    {112U, 30U, 207U, 113U, SMART_RELAY_APP_SCREEN_SETUP},
    {216U, 30U, 311U, 113U, SMART_RELAY_APP_SCREEN_PROGRAM},
    {8U,  117U, 103U, 200U, SMART_RELAY_APP_SCREEN_CARD},
    {112U,117U, 207U, 200U, SMART_RELAY_APP_SCREEN_DIAGNOSTICS},
    {216U,117U, 311U, 200U, SMART_RELAY_APP_SCREEN_USER}
};

static char const * const gp_smart_relay_app_screen_name[SMART_RELAY_APP_SCREEN_MAX] =
{
    [SMART_RELAY_APP_SCREEN_HOME]        = "HOME",
    [SMART_RELAY_APP_SCREEN_START]       = "START",
    [SMART_RELAY_APP_SCREEN_SETUP]       = "SETUP",
    [SMART_RELAY_APP_SCREEN_PROGRAM]     = "PROGRAM",
    [SMART_RELAY_APP_SCREEN_CARD]        = "CARD",
    [SMART_RELAY_APP_SCREEN_DIAGNOSTICS] = "DIAGNOSTICS",
    [SMART_RELAY_APP_SCREEN_USER]        = "USER"
};

/* Five-by-seven bitmap rows for decimal clock digits. Bits 4 through 0 represent the five columns. */
static uint8_t const g_smart_relay_app_clock_digits[10][SMART_RELAY_APP_CLOCK_DIGIT_HEIGHT] =
{
    {0x0EU, 0x11U, 0x11U, 0x11U, 0x11U, 0x11U, 0x0EU}, /* 0 */
    {0x04U, 0x0CU, 0x04U, 0x04U, 0x04U, 0x04U, 0x0EU}, /* 1 */
    {0x0EU, 0x11U, 0x01U, 0x02U, 0x04U, 0x08U, 0x1FU}, /* 2 */
    {0x1EU, 0x01U, 0x01U, 0x0EU, 0x01U, 0x01U, 0x1EU}, /* 3 */
    {0x02U, 0x06U, 0x0AU, 0x12U, 0x1FU, 0x02U, 0x02U}, /* 4 */
    {0x1FU, 0x10U, 0x10U, 0x1EU, 0x01U, 0x01U, 0x1EU}, /* 5 */
    {0x0EU, 0x10U, 0x10U, 0x1EU, 0x11U, 0x11U, 0x0EU}, /* 6 */
    {0x1FU, 0x01U, 0x02U, 0x04U, 0x08U, 0x08U, 0x08U}, /* 7 */
    {0x0EU, 0x11U, 0x11U, 0x0EU, 0x11U, 0x11U, 0x0EU}, /* 8 */
    {0x0EU, 0x11U, 0x11U, 0x0FU, 0x01U, 0x01U, 0x0EU}  /* 9 */
};

static smart_relay_app_cfg_t       g_smart_relay_app_cfg;
static smart_relay_app_screen_t    g_smart_relay_app_active_screen   = SMART_RELAY_APP_SCREEN_HOME;
static smart_relay_app_screen_t    g_smart_relay_app_previous_screen = SMART_RELAY_APP_SCREEN_HOME;
static smart_relay_app_home_item_t g_smart_relay_app_selected_item   = SMART_RELAY_APP_HOME_ITEM_START;
static bool                        g_smart_relay_app_initialized;

/* Software clock state. The time resets whenever the microcontroller restarts. */
static uint32_t g_smart_relay_app_clock_elapsed_ms;
static uint8_t  g_smart_relay_app_clock_minute;
static uint8_t  g_smart_relay_app_clock_second;
static uint16_t g_smart_relay_app_clock_buffer[SMART_RELAY_APP_CLOCK_AREA_WIDTH *
                                                SMART_RELAY_APP_CLOCK_AREA_HEIGHT];

/***********************************************************************************************************************
 * Public global variables
 **********************************************************************************************************************/
volatile fsp_err_t g_smart_relay_app_error = FSP_SUCCESS;

/*******************************************************************************************************************//**
 * @addtogroup Smart_Relay_Application
 * @{
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * @brief Initializes the LCD, button driver, Home UI, and software clock.
 *
 * Pass NULL to use the built-in child-screen placeholder. Supply p_screen_draw when completed child screens are
 * available. R_IOPORT_Open() must already have been called, normally from R_BSP_WarmStart().
 *
 * @param[in] p_cfg Optional child-screen drawing configuration.
 *
 * @retval FSP_SUCCESS          Application initialized successfully.
 * @retval FSP_ERR_ALREADY_OPEN Application is already initialized.
 * @return Any other FSP error code returned by the LCD or button driver.
 **********************************************************************************************************************/
fsp_err_t Smart_Relay_App_Init(smart_relay_app_cfg_t const * p_cfg)
{
    fsp_err_t      err;
    ui_relay_cfg_t relay_cfg;
    bool           use_onboard_relay_app;

    if (g_smart_relay_app_initialized)
    {
        return FSP_ERR_ALREADY_OPEN;
    }

    if (NULL != p_cfg)
    {
        g_smart_relay_app_cfg = *p_cfg;
    }
    else
    {
        g_smart_relay_app_cfg.p_screen_draw = NULL;
        g_smart_relay_app_cfg.p_context     = NULL;
        g_smart_relay_app_cfg.p_relay_write = NULL;
        g_smart_relay_app_cfg.p_relay_context = NULL;
        g_smart_relay_app_cfg.relay_initial_state_mask = 0U;
    }

    use_onboard_relay_app = (NULL == g_smart_relay_app_cfg.p_relay_write);

    if (use_onboard_relay_app)
    {
        err = Relay_App_Init(g_smart_relay_app_cfg.relay_initial_state_mask);

        if (FSP_SUCCESS != err)
        {
            return err;
        }
    }

    err = ILI9341_Init();

    if (FSP_SUCCESS != err)
    {
        if (use_onboard_relay_app)
        {
            (void) Relay_App_Close();
        }

        return err;
    }

    relay_cfg.p_output_write     = use_onboard_relay_app ? smart_relay_app_relay_write :
                                                         g_smart_relay_app_cfg.p_relay_write;
    relay_cfg.p_context          = use_onboard_relay_app ? NULL : g_smart_relay_app_cfg.p_relay_context;
    relay_cfg.initial_state_mask = g_smart_relay_app_cfg.relay_initial_state_mask;

    err = UI_Relay_Init(&relay_cfg);

    if (FSP_SUCCESS != err)
    {
        if (use_onboard_relay_app)
        {
            (void) Relay_App_Close();
        }

        return err;
    }

    err = UI_QR_Init();
    
    if (FSP_SUCCESS != err)
    {
        if (use_onboard_relay_app)
        {
            (void) Relay_App_Close();
        }
    
        return err;
    }

    err = Button_App_Init();

    if (FSP_SUCCESS != err)
    {
        if (use_onboard_relay_app)
        {
            (void) Relay_App_Close();
        }

        return err;
    }

    g_smart_relay_app_active_screen    = SMART_RELAY_APP_SCREEN_HOME;
    g_smart_relay_app_previous_screen  = SMART_RELAY_APP_SCREEN_HOME;
    g_smart_relay_app_selected_item    = SMART_RELAY_APP_HOME_ITEM_START;
    g_smart_relay_app_clock_elapsed_ms = 0U;
    g_smart_relay_app_clock_minute     = SMART_RELAY_APP_TIMER_START_MINUTE;
    g_smart_relay_app_clock_second     = SMART_RELAY_APP_TIMER_START_SECOND;
    g_smart_relay_app_initialized      = true;

    err = smart_relay_app_render_home();

    if (FSP_SUCCESS != err)
    {
        g_smart_relay_app_initialized = false;
        (void) Button_App_Close();

        if (use_onboard_relay_app)
        {
            (void) Relay_App_Close();
        }
    }

    return err;
}

/*******************************************************************************************************************//**
 * @brief Polls the seven buttons, performs one UI action, and advances the software clock.
 *
 * Call this API every SMART_RELAY_APP_PROCESS_PERIOD_MS milliseconds. Direction buttons move immediately after a
 * debounced press and continue moving through repeat events while held. OK, BACK, and FRONT act after a normal click.
 * If several actions are reported together, the priority is FRONT, BACK, OK, UP, DOWN, LEFT, then RIGHT.
 *
 * @param[in] elapsed_ms Time elapsed since the previous call, in milliseconds.
 *
 * @retval FSP_SUCCESS              Application processed successfully.
 * @retval FSP_ERR_NOT_OPEN         Application is not initialized.
 * @retval FSP_ERR_INVALID_ARGUMENT elapsed_ms is zero.
 * @return Any other FSP error code returned by the button, LCD, or graphics driver.
 **********************************************************************************************************************/
fsp_err_t Smart_Relay_App_Process(uint32_t elapsed_ms)
{
    fsp_err_t           err;
    button_app_output_t button_output;
    uint32_t            action = (uint32_t) BUTTON_APP_ACTION_NONE;

    if (!g_smart_relay_app_initialized)
    {
        return FSP_ERR_NOT_OPEN;
    }

    if (0U == elapsed_ms)
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    err = Button_App_Process(elapsed_ms, &button_output);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    if (SMART_RELAY_APP_SCREEN_PROGRAM == g_smart_relay_app_active_screen)
    {
        err = smart_relay_app_process_relay_screen(button_output.actions);
    }
    else if (SMART_RELAY_APP_SCREEN_PROGRAM == g_smart_relay_app_active_screen)
    {
        err = smart_relay_app_process_relay_screen(button_output.actions);
    }
    else if (SMART_RELAY_APP_SCREEN_USER == g_smart_relay_app_active_screen)
    {
        err = smart_relay_app_process_qr_screen(button_output.actions);
    }
    else if (0U != (button_output.actions & (uint32_t) BUTTON_APP_ACTION_FRONT))
    {
        err = smart_relay_app_handle_front();
    }
    else if (0U != (button_output.actions & (uint32_t) BUTTON_APP_ACTION_BACK))
    {
        err = smart_relay_app_handle_back();
    }
    else if (0U != (button_output.actions & (uint32_t) BUTTON_APP_ACTION_SELECT))
    {
        err = smart_relay_app_handle_select();
    }
    else
    {
        if (0U != (button_output.actions & (uint32_t) BUTTON_APP_ACTION_UP))
        {
            action = (uint32_t) BUTTON_APP_ACTION_UP;
        }
        else if (0U != (button_output.actions & (uint32_t) BUTTON_APP_ACTION_DOWN))
        {
            action = (uint32_t) BUTTON_APP_ACTION_DOWN;
        }
        else if (0U != (button_output.actions & (uint32_t) BUTTON_APP_ACTION_LEFT))
        {
            action = (uint32_t) BUTTON_APP_ACTION_LEFT;
        }
        else if (0U != (button_output.actions & (uint32_t) BUTTON_APP_ACTION_RIGHT))
        {
            action = (uint32_t) BUTTON_APP_ACTION_RIGHT;
        }

        err = smart_relay_app_move_cursor(action);
    }

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    return smart_relay_app_clock_process(elapsed_ms);
}

/*******************************************************************************************************************//**
 * @brief Returns the active application screen.
 *
 * @return Current Smart Relay application screen.
 **********************************************************************************************************************/
smart_relay_app_screen_t Smart_Relay_App_Get_Active_Screen(void)
{
    return g_smart_relay_app_active_screen;
}

/*******************************************************************************************************************//**
 * @brief Returns the selected item on the Home screen.
 *
 * @return Current Home menu selection.
 **********************************************************************************************************************/
smart_relay_app_home_item_t Smart_Relay_App_Get_Selected_Item(void)
{
    return g_smart_relay_app_selected_item;
}

/*******************************************************************************************************************//**
 * @brief Runs the standalone Smart Relay Home UI and seven-button test loop.
 *
 * Call this function once from hal_entry(). The function does not return unless initialization or processing fails.
 **********************************************************************************************************************/
void Smart_Relay_App_Run(void)
{
    fsp_err_t err;

    err = Smart_Relay_App_Init(NULL);
    g_smart_relay_app_error = err;

    if (FSP_SUCCESS != err)
    {
        return;
    }

    while (true)
    {
        R_BSP_SoftwareDelay(SMART_RELAY_APP_PROCESS_PERIOD_MS, BSP_DELAY_UNITS_MILLISECONDS);

        err = Smart_Relay_App_Process(SMART_RELAY_APP_PROCESS_PERIOD_MS);

        if (FSP_SUCCESS != err)
        {
            g_smart_relay_app_error = err;
            return;
        }
    }
}

/*******************************************************************************************************************//**
 * @} (end addtogroup Smart_Relay_Application)
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * @brief Applies one UI relay state to the onboard Y1 through Y8 relay driver.
 *
 * @param[in] channel   UI relay channel to update.
 * @param[in] enabled   true to energize the relay; false to release it.
 * @param[in] p_context Unused callback context.
 *
 * @retval FSP_SUCCESS              The relay output was updated successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT channel is outside Relay 1 through Relay 8.
 * @return Any other FSP error code returned by Relay_App_Write().
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app_relay_write(ui_relay_channel_t channel, bool enabled, void * p_context)
{
    (void) p_context;

    if ((uint32_t) channel >= (uint32_t) UI_RELAY_CHANNEL_MAX)
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    return Relay_App_Write((relay_app_channel_t) channel, enabled);
}

/*******************************************************************************************************************//**
 * @brief Sends the complete Home bitmap to the LCD and draws the current software clock and cursor.
 *
 * @return FSP error code returned by the ILI9341 driver.
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app_render_home(void)
{
    fsp_err_t err;

    err = ILI9341_Draw_Image((char const *) ui_home_320x240_rgb565, SCREEN_HORIZONTAL_1);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    err = smart_relay_app_clock_draw();

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    return smart_relay_app_draw_cursor(g_smart_relay_app_selected_item, SMART_RELAY_APP_CURSOR_COLOR);
}

/*******************************************************************************************************************//**
 * @brief Draws or erases the cursor around one Home tile.
 *
 * @param[in] item  Home item whose cursor rectangle is updated.
 * @param[in] color RGB565 cursor or background color.
 *
 * @return FSP error code returned by ILI9341_Draw_Hollow_Rectangle_Coord().
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app_draw_cursor(smart_relay_app_home_item_t item, uint16_t color)
{
    smart_relay_app_menu_position_t const * p_position = &g_smart_relay_app_home_menu[(uint32_t) item];

    return ILI9341_Draw_Hollow_Rectangle_Coord(p_position->x0,
                                               p_position->y0,
                                               p_position->x1,
                                               p_position->y1,
                                               color);
}

/*******************************************************************************************************************//**
 * @brief Moves the Home cursor one position in the requested direction.
 *
 * Movement stops at each edge of the two-row by three-column grid and does not wrap.
 *
 * @param[in] action One directional BUTTON_APP_ACTION_* value, or BUTTON_APP_ACTION_NONE.
 *
 * @retval FSP_SUCCESS The cursor was unchanged or moved successfully.
 * @return Any other FSP error code returned by the graphics driver.
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app_move_cursor(uint32_t action)
{
    fsp_err_t                   err;
    uint32_t                    old_index;
    uint32_t                    new_index;
    uint32_t                    row;
    uint32_t                    column;
    smart_relay_app_home_item_t new_item;

    if ((SMART_RELAY_APP_SCREEN_HOME != g_smart_relay_app_active_screen) ||
        ((uint32_t) BUTTON_APP_ACTION_NONE == action))
    {
        return FSP_SUCCESS;
    }

    old_index = (uint32_t) g_smart_relay_app_selected_item;
    new_index = old_index;
    row       = old_index / SMART_RELAY_APP_HOME_COLUMN_COUNT;
    column    = old_index % SMART_RELAY_APP_HOME_COLUMN_COUNT;

    if (((uint32_t) BUTTON_APP_ACTION_UP == action) && (0U < row))
    {
        new_index -= SMART_RELAY_APP_HOME_COLUMN_COUNT;
    }
    else if (((uint32_t) BUTTON_APP_ACTION_DOWN == action) &&
             ((row + 1U) < SMART_RELAY_APP_HOME_ROW_COUNT))
    {
        new_index += SMART_RELAY_APP_HOME_COLUMN_COUNT;
    }
    else if (((uint32_t) BUTTON_APP_ACTION_LEFT == action) && (0U < column))
    {
        new_index--;
    }
    else if (((uint32_t) BUTTON_APP_ACTION_RIGHT == action) &&
             ((column + 1U) < SMART_RELAY_APP_HOME_COLUMN_COUNT))
    {
        new_index++;
    }
    else
    {
        /* Keep the current selection when movement reaches a grid boundary. */
    }

    if (new_index == old_index)
    {
        return FSP_SUCCESS;
    }

    new_item = (smart_relay_app_home_item_t) new_index;

    /* Draw the new focus first so the display never shows a frame with no active cursor. */
    err = smart_relay_app_draw_cursor(new_item, SMART_RELAY_APP_CURSOR_COLOR);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    err = smart_relay_app_draw_cursor(g_smart_relay_app_selected_item,
                                      SMART_RELAY_APP_HOME_BACKGROUND_COLOR);

    if (FSP_SUCCESS != err)
    {
        /* Restore the original visual state if erasing the old cursor fails. */
        (void) smart_relay_app_draw_cursor(new_item, SMART_RELAY_APP_HOME_BACKGROUND_COLOR);
        (void) smart_relay_app_draw_cursor(g_smart_relay_app_selected_item, SMART_RELAY_APP_CURSOR_COLOR);

        return err;
    }

    g_smart_relay_app_selected_item = new_item;

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Opens the child screen associated with the selected Home item.
 *
 * @retval FSP_SUCCESS The child screen was drawn successfully or the application was already on a child screen.
 * @return Any other FSP error code returned by the child-screen renderer.
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app_handle_select(void)
{
    fsp_err_t                err;
    smart_relay_app_screen_t destination;

    if (SMART_RELAY_APP_SCREEN_HOME != g_smart_relay_app_active_screen)
    {
        return FSP_SUCCESS;
    }

    destination = g_smart_relay_app_home_menu[(uint32_t) g_smart_relay_app_selected_item].destination_screen;
    err = smart_relay_app_draw_child_screen(destination);

    if (FSP_SUCCESS == err)
    {
        g_smart_relay_app_previous_screen = g_smart_relay_app_active_screen;
        g_smart_relay_app_active_screen   = destination;
    }

    return err;
}

/*******************************************************************************************************************//**
 * @brief Returns from the current child screen to its previous screen.
 *
 * The current test application has one child-screen level, so BACK returns from any child screen to Home while
 * preserving the selected Home item.
 *
 * @retval FSP_SUCCESS The previous screen was displayed successfully or Home was already active.
 * @return Any other FSP error code returned by the display driver.
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app_handle_back(void)
{
    fsp_err_t err;

    if (SMART_RELAY_APP_SCREEN_HOME == g_smart_relay_app_active_screen)
    {
        return FSP_SUCCESS;
    }

    if (SMART_RELAY_APP_SCREEN_HOME == g_smart_relay_app_previous_screen)
    {
        if (SMART_RELAY_APP_SCREEN_PROGRAM == g_smart_relay_app_active_screen)
        {
            (void) UI_Relay_Close();
        }

        err = smart_relay_app_render_home();

        if (FSP_SUCCESS == err)
        {
            g_smart_relay_app_active_screen   = SMART_RELAY_APP_SCREEN_HOME;
            g_smart_relay_app_previous_screen = SMART_RELAY_APP_SCREEN_HOME;
        }

        return err;
    }

    if (SMART_RELAY_APP_SCREEN_HOME == g_smart_relay_app_previous_screen)
    {
        if (SMART_RELAY_APP_SCREEN_PROGRAM == g_smart_relay_app_active_screen)
        {
            (void) UI_Relay_Close();
        }
        else if (SMART_RELAY_APP_SCREEN_USER == g_smart_relay_app_active_screen)
        {
            (void) UI_QR_Close();
        }

        if (FSP_SUCCESS == err)
        {
            g_smart_relay_app_active_screen   = SMART_RELAY_APP_SCREEN_HOME;
            g_smart_relay_app_previous_screen = SMART_RELAY_APP_SCREEN_HOME;
        }

        return err;
    }

    return FSP_ERR_UNSUPPORTED;
}

/*******************************************************************************************************************//**
 * @brief Returns directly to Home and resets the cursor to Start.
 *
 * @return FSP error code returned by the display driver.
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app_handle_front(void)
{
    fsp_err_t err;

    if (SMART_RELAY_APP_SCREEN_PROGRAM == g_smart_relay_app_active_screen)
    {
        (void) UI_Relay_Close();
    }

    g_smart_relay_app_selected_item = SMART_RELAY_APP_HOME_ITEM_START;
    err = smart_relay_app_render_home();

    if (FSP_SUCCESS == err)
    {
        g_smart_relay_app_active_screen   = SMART_RELAY_APP_SCREEN_HOME;
        g_smart_relay_app_previous_screen = SMART_RELAY_APP_SCREEN_HOME;
    }

    /******************** */
    if (SMART_RELAY_APP_SCREEN_PROGRAM == g_smart_relay_app_active_screen)
    {
        (void) UI_Relay_Close();
    }
    else if (SMART_RELAY_APP_SCREEN_USER == g_smart_relay_app_active_screen)
    {
        (void) UI_QR_Close();
    }

    g_smart_relay_app_selected_item = SMART_RELAY_APP_HOME_ITEM_START;
    err = smart_relay_app_render_home();
    if (FSP_SUCCESS == err)
    {
        g_smart_relay_app_active_screen   = SMART_RELAY_APP_SCREEN_HOME;
        g_smart_relay_app_previous_screen = SMART_RELAY_APP_SCREEN_HOME;
    }

    return err;
}

/*******************************************************************************************************************//**
 * @brief Routes seven-button actions to the dedicated Relay UI layer.
 *
 * UI_Relay owns the two-row by four-column focus and relay toggling. This application layer only maps button actions
 * and performs the requested screen transition after BACK or HOME.
 *
 * @param[in] button_actions Bit mask returned by Button_App_Process().
 *
 * @return FSP error code returned by UI_Relay or the Home renderer.
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app_process_relay_screen(uint32_t button_actions)
{
    fsp_err_t              err;
    uint32_t               relay_actions = (uint32_t) UI_RELAY_ACTION_NONE;
    ui_relay_navigation_t  navigation;

    if (0U != (button_actions & (uint32_t) BUTTON_APP_ACTION_UP))
    {
        relay_actions |= (uint32_t) UI_RELAY_ACTION_UP;
    }

    if (0U != (button_actions & (uint32_t) BUTTON_APP_ACTION_DOWN))
    {
        relay_actions |= (uint32_t) UI_RELAY_ACTION_DOWN;
    }

    if (0U != (button_actions & (uint32_t) BUTTON_APP_ACTION_LEFT))
    {
        relay_actions |= (uint32_t) UI_RELAY_ACTION_LEFT;
    }

    if (0U != (button_actions & (uint32_t) BUTTON_APP_ACTION_RIGHT))
    {
        relay_actions |= (uint32_t) UI_RELAY_ACTION_RIGHT;
    }

    if (0U != (button_actions & (uint32_t) BUTTON_APP_ACTION_SELECT))
    {
        relay_actions |= (uint32_t) UI_RELAY_ACTION_SELECT;
    }

    if (0U != (button_actions & (uint32_t) BUTTON_APP_ACTION_BACK))
    {
        relay_actions |= (uint32_t) UI_RELAY_ACTION_BACK;
    }

    if (0U != (button_actions & (uint32_t) BUTTON_APP_ACTION_FRONT))
    {
        relay_actions |= (uint32_t) UI_RELAY_ACTION_HOME;
    }

    err = UI_Relay_Process(relay_actions, &navigation);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    if (UI_RELAY_NAVIGATION_BACK == navigation)
    {
        err = smart_relay_app_render_home();

        if (FSP_SUCCESS == err)
        {
            /* Preserve Program as the selected Home tile after BACK. */
            g_smart_relay_app_active_screen   = SMART_RELAY_APP_SCREEN_HOME;
            g_smart_relay_app_previous_screen = SMART_RELAY_APP_SCREEN_HOME;
        }

        return err;
    }

    if (UI_RELAY_NAVIGATION_HOME == navigation)
    {
        g_smart_relay_app_selected_item = SMART_RELAY_APP_HOME_ITEM_START;
        err = smart_relay_app_render_home();

        if (FSP_SUCCESS == err)
        {
            g_smart_relay_app_active_screen   = SMART_RELAY_APP_SCREEN_HOME;
            g_smart_relay_app_previous_screen = SMART_RELAY_APP_SCREEN_HOME;
        }

        return err;
    }

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Draws a child screen using the configured callback or the built-in test placeholder.
 *
 * @param[in] screen Child screen requested by the selected Home item.
 *
 * @return FSP error code returned by the selected child-screen renderer.
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app_draw_child_screen(smart_relay_app_screen_t screen)
{
    if (SMART_RELAY_APP_SCREEN_PROGRAM == screen)
    {
        return UI_Relay_Open();
    }

    if (SMART_RELAY_APP_SCREEN_USER == screen)
    {
        return UI_QR_Open();
    }

    if (NULL != g_smart_relay_app_cfg.p_screen_draw)
    {
        return g_smart_relay_app_cfg.p_screen_draw(screen, g_smart_relay_app_cfg.p_context);
    }

    return smart_relay_app_draw_default_child_screen(screen);
}

/*******************************************************************************************************************//**
 * @brief Draws a simple child-screen placeholder for standalone navigation testing.
 *
 * @param[in] screen Child screen to identify on the display.
 *
 * @retval FSP_SUCCESS The placeholder was drawn successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT screen is outside the supported range.
 * @return Any other FSP error code returned by the graphics driver.
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app_draw_default_child_screen(smart_relay_app_screen_t screen)
{
    fsp_err_t err;

    if ((SMART_RELAY_APP_SCREEN_HOME >= screen) || (SMART_RELAY_APP_SCREEN_MAX <= screen))
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    err = ILI9341_Fill_Screen(SMART_RELAY_APP_CHILD_BACKGROUND_COLOR);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    err = ILI9341_Draw_Text("SMART RELAY", 82U, 42U, WHITE, 2U, SMART_RELAY_APP_CHILD_BACKGROUND_COLOR);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    err = ILI9341_Draw_Text(gp_smart_relay_app_screen_name[(uint32_t) screen],
                            76U,
                            92U,
                            CYAN,
                            2U,
                            SMART_RELAY_APP_CHILD_BACKGROUND_COLOR);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    err = ILI9341_Draw_Text("BACK: PREVIOUS", 62U, 174U, WHITE, 1U, SMART_RELAY_APP_CHILD_BACKGROUND_COLOR);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    return ILI9341_Draw_Text("FRONT: HOME", 70U, 194U, WHITE, 1U, SMART_RELAY_APP_CHILD_BACKGROUND_COLOR);
}

/*******************************************************************************************************************//**
 * @brief Advances the simulated MM:SS clock and redraws it once per second while Home is active.
 *
 * @param[in] elapsed_ms Time elapsed since the previous call, in milliseconds.
 *
 * @retval FSP_SUCCESS The clock was processed successfully.
 * @return Any other FSP error code returned by the graphics driver.
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app_clock_process(uint32_t elapsed_ms)
{
    bool changed = false;

    g_smart_relay_app_clock_elapsed_ms += elapsed_ms;

    while (SMART_RELAY_APP_ONE_SECOND_MS <= g_smart_relay_app_clock_elapsed_ms)
    {
        g_smart_relay_app_clock_elapsed_ms -= SMART_RELAY_APP_ONE_SECOND_MS;
        g_smart_relay_app_clock_second = (uint8_t) (g_smart_relay_app_clock_second + 1U);
        changed = true;

        if (60U <= g_smart_relay_app_clock_second)
        {
            g_smart_relay_app_clock_second = 0U;
            g_smart_relay_app_clock_minute = (uint8_t) (g_smart_relay_app_clock_minute + 1U);

            if (SMART_RELAY_APP_TIMER_MINUTE_LIMIT <= g_smart_relay_app_clock_minute)
            {
                g_smart_relay_app_clock_minute = 0U;
            }
        }
    }

    if (changed && (SMART_RELAY_APP_SCREEN_HOME == g_smart_relay_app_active_screen))
    {
        return smart_relay_app_clock_draw();
    }

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Draws the current MM:SS value using one buffered RGB565 block transfer.
 *
 * @return FSP error code returned by ILI9341_Draw_RGB565_Block().
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app_clock_draw(void)
{
    uint32_t index;

    for (index = 0U;
         index < ((uint32_t) SMART_RELAY_APP_CLOCK_AREA_WIDTH *
                  (uint32_t) SMART_RELAY_APP_CLOCK_AREA_HEIGHT);
         index++)
    {
        g_smart_relay_app_clock_buffer[index] = SMART_RELAY_APP_HEADER_BACKGROUND_COLOR;
    }

    smart_relay_app_clock_render_digit((uint8_t) (g_smart_relay_app_clock_minute / 10U),
                                        SMART_RELAY_APP_MINUTE_TENS_OFFSET);
    smart_relay_app_clock_render_digit((uint8_t) (g_smart_relay_app_clock_minute % 10U),
                                        SMART_RELAY_APP_MINUTE_ONES_OFFSET);
    smart_relay_app_clock_render_digit((uint8_t) (g_smart_relay_app_clock_second / 10U),
                                        SMART_RELAY_APP_SECOND_TENS_OFFSET);
    smart_relay_app_clock_render_digit((uint8_t) (g_smart_relay_app_clock_second % 10U),
                                        SMART_RELAY_APP_SECOND_ONES_OFFSET);

    g_smart_relay_app_clock_buffer[(2U * SMART_RELAY_APP_CLOCK_AREA_WIDTH) +
                                    SMART_RELAY_APP_CLOCK_COLON_X_OFFSET] = SMART_RELAY_APP_CLOCK_TEXT_COLOR;
    g_smart_relay_app_clock_buffer[(3U * SMART_RELAY_APP_CLOCK_AREA_WIDTH) +
                                    SMART_RELAY_APP_CLOCK_COLON_X_OFFSET] = SMART_RELAY_APP_CLOCK_TEXT_COLOR;
    g_smart_relay_app_clock_buffer[(5U * SMART_RELAY_APP_CLOCK_AREA_WIDTH) +
                                    SMART_RELAY_APP_CLOCK_COLON_X_OFFSET] = SMART_RELAY_APP_CLOCK_TEXT_COLOR;
    g_smart_relay_app_clock_buffer[(6U * SMART_RELAY_APP_CLOCK_AREA_WIDTH) +
                                    SMART_RELAY_APP_CLOCK_COLON_X_OFFSET] = SMART_RELAY_APP_CLOCK_TEXT_COLOR;

    return ILI9341_Draw_RGB565_Block(SMART_RELAY_APP_CLOCK_AREA_X,
                                     SMART_RELAY_APP_CLOCK_AREA_Y,
                                     SMART_RELAY_APP_CLOCK_AREA_WIDTH,
                                     SMART_RELAY_APP_CLOCK_AREA_HEIGHT,
                                     g_smart_relay_app_clock_buffer);
}

/*******************************************************************************************************************//**
 * @brief Renders one five-by-seven decimal digit into the off-screen clock buffer.
 *
 * @param[in] digit    Decimal digit in the range 0 through 9.
 * @param[in] x_offset Horizontal position inside the clock buffer.
 **********************************************************************************************************************/
static void smart_relay_app_clock_render_digit(uint8_t digit, uint16_t x_offset)
{
    uint8_t row;
    uint8_t column;

    if (9U < digit)
    {
        return;
    }

    for (row = 0U; row < SMART_RELAY_APP_CLOCK_DIGIT_HEIGHT; row++)
    {
        for (column = 0U; column < SMART_RELAY_APP_CLOCK_DIGIT_WIDTH; column++)
        {
            uint8_t const pixel_mask = (uint8_t) (1U << (4U - column));

            if (0U != (g_smart_relay_app_clock_digits[digit][row] & pixel_mask))
            {
                uint32_t const pixel_index = ((uint32_t) row * SMART_RELAY_APP_CLOCK_AREA_WIDTH) +
                                             (uint32_t) x_offset + (uint32_t) column;

                g_smart_relay_app_clock_buffer[pixel_index] = SMART_RELAY_APP_CLOCK_TEXT_COLOR;
            }
        }
    }
}



/*******************************************************************************************************************//**
 * @brief Routes seven-button actions to the QR-code UI layer.
 *
 * UI_QR only recognizes BACK and HOME actions. BACK returns to Home while preserving User as the selected tile.
 * FRONT (HOME) returns to Home and resets the selection to Start.
 *
 * @param[in] button_actions Bit mask returned by Button_App_Process().
 *
 * @return FSP error code returned by UI_QR or the Home renderer.
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app_process_qr_screen(uint32_t button_actions)
{
    fsp_err_t          err;
    uint32_t           qr_actions = (uint32_t) UI_QR_ACTION_NONE;
    ui_qr_navigation_t navigation;

    if (0U != (button_actions & (uint32_t) BUTTON_APP_ACTION_BACK))
    {
        qr_actions |= (uint32_t) UI_QR_ACTION_BACK;
    }

    if (0U != (button_actions & (uint32_t) BUTTON_APP_ACTION_FRONT))
    {
        qr_actions |= (uint32_t) UI_QR_ACTION_HOME;
    }

    err = UI_QR_Process(qr_actions, &navigation);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    if (UI_QR_NAVIGATION_BACK == navigation)
    {
        err = smart_relay_app_render_home();

        if (FSP_SUCCESS == err)
        {
            /* Preserve User as the selected Home tile after BACK. */
            g_smart_relay_app_active_screen   = SMART_RELAY_APP_SCREEN_HOME;
            g_smart_relay_app_previous_screen = SMART_RELAY_APP_SCREEN_HOME;
        }

        return err;
    }

    if (UI_QR_NAVIGATION_HOME == navigation)
    {
        g_smart_relay_app_selected_item = SMART_RELAY_APP_HOME_ITEM_START;
        err = smart_relay_app_render_home();

        if (FSP_SUCCESS == err)
        {
            g_smart_relay_app_active_screen   = SMART_RELAY_APP_SCREEN_HOME;
            g_smart_relay_app_previous_screen = SMART_RELAY_APP_SCREEN_HOME;
        }

        return err;
    }

    return FSP_SUCCESS;
}