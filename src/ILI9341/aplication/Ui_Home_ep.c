/*******************************************************************************************************************//**
 * @file Ui_Home_ep.c
 * @brief Implements the Smart Relay bitmap UI and four-button navigation state machine.
 *
 * The Home screen is loaded from ui_home_320x240_rgb565.h. NEXT moves the cursor, OK opens the selected child screen,
 * BACK returns to the previous screen, and HOME returns directly to the Home screen. Button input is received through
 * a module-defined callback argument type so this file does not depend on the Renesas External IRQ callback type.
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/

#include <stdbool.h>
#include <stddef.h>
#include "Ui_Home_ep.h"
#include "ILI9341_GFX.h"
#include "ui_home_320x240_rgb565.h"

/***********************************************************************************************************************
 * Macro definitions
 **********************************************************************************************************************/

 /* RGB565 color of the area surrounding every tile in the Home bitmap. */
#define SMART_RELAY_UI_HOME_BACKGROUND_COLOR    (0x08A5U)

/* RGB565 color used to highlight the selected Home item. */
#define SMART_RELAY_UI_CURSOR_COLOR             (0xFFE0U)

 /***********************************************************************************************************************
 * Typedef definitions
 **********************************************************************************************************************/

 /** Cursor rectangle and destination screen associated with one Home item. */
typedef struct st_smart_relay_ui_menu_position
{
    uint16_t                x0;
    uint16_t                y0;
    uint16_t                x1;
    uint16_t                y1;
    Smart_Relay_Ui_Screen_t destination_screen;
} smart_relay_ui_menu_position_t;

/***********************************************************************************************************************
 * Private global variables
 **********************************************************************************************************************/

/* Cursor rectangles are two pixels outside the tile borders stored in the bitmap. */
static const smart_relay_ui_menu_position_t g_smart_relay_ui_home_menu[Smart_Relay_Ui_Home_Item_MAX] =
{
    {8U,   30U, 103U, 113U, Smart_Relay_Ui_Screen_START},
    {112U, 30U, 207U, 113U, Smart_Relay_Ui_Screen_SETUP},
    {216U, 30U, 311U, 113U, Smart_Relay_Ui_Screen_RELAY},
    {8U,  117U, 103U, 200U, Smart_Relay_Ui_Screen_CARD},
    {112U,117U, 207U, 200U, Smart_Relay_Ui_Screen_DIAGNOSTICS},
    {216U,117U, 311U, 200U, Smart_Relay_Ui_Screen_PROJECT_QR}
};

static volatile bool g_smart_relay_ui_next_event;
static volatile bool g_smart_relay_ui_ok_event;
static volatile bool g_smart_relay_ui_back_event;
static volatile bool g_smart_relay_ui_home_event;

static Smart_Relay_Ui_Screen_t    g_smart_relay_ui_active_screen   = Smart_Relay_Ui_Screen_HOME;
static Smart_Relay_Ui_Screen_t    g_smart_relay_ui_previous_screen = Smart_Relay_Ui_Screen_HOME;
static Smart_Relay_Ui_Home_Item_t g_smart_relay_ui_selected_item   = Smart_Relay_Ui_Home_Item_START;
static smart_relay_ui_cfg_t       g_smart_relay_ui_cfg;
static bool                       g_smart_relay_ui_initialized;

/***********************************************************************************************************************
 * Global variables
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Private function declarations
 **********************************************************************************************************************/

static fsp_err_t smart_relay_ui_draw_cursor(Smart_Relay_Ui_Home_Item_t item, uint16_t color);
static fsp_err_t smart_relay_ui_render_home(void);
static fsp_err_t smart_relay_ui_handle_next(void);
static fsp_err_t smart_relay_ui_handle_ok(void);
static fsp_err_t smart_relay_ui_handle_back(void);
static fsp_err_t smart_relay_ui_handle_home(void);
static fsp_err_t smart_relay_ui_open_child_screen(Smart_Relay_Ui_Screen_t screen);

/*******************************************************************************************************************//**
 * @addtogroup Smart_Relay_UI
 * @{
 **********************************************************************************************************************/

 /***********************************************************************************************************************
 * Functions
 **********************************************************************************************************************/

/**
 * @brief Initializes the LCD and runs the Smart Relay UI processing loop.
 *
 * @retval None
*/
void app_main(void)
{
    fsp_err_t err;

    /* Initialize the ILI9341 LCD driver. */
    err = ILI9341_Init();

    if (FSP_SUCCESS != err)
    {
        return;
    }

    /* Load the Home bitmap and initialize the UI state machine. */
    err = Smart_Relay_UI_Init(NULL);

    if (FSP_SUCCESS != err)
    {
        return;
    }

    while (1)
    {
        /* Process pending UI button events. */
        err = Smart_Relay_UI_Process();

        if ((FSP_SUCCESS != err) && (FSP_ERR_UNSUPPORTED != err))
        {
            return;
        }

        R_BSP_SoftwareDelay(10U, BSP_DELAY_UNITS_MILLISECONDS);
    }
}

/**
 * @brief Initializes the Smart Relay UI and displays the RGB565 Home bitmap.
 *
 * The ILI9341 driver must be initialized before calling this API. The child-screen callback is optional while testing
 * Home navigation; OK returns FSP_ERR_UNSUPPORTED when the callback is not configured.
 *
 * @param[in] p_cfg UI configuration. Set to NULL when child-screen navigation is not required.
 *
 * @retval FSP_SUCCESS The UI was initialized and the Home screen was displayed successfully.
 * @return Any other FSP error code returned by the ILI9341 driver.
*/
fsp_err_t Smart_Relay_UI_Init(smart_relay_ui_cfg_t const * p_cfg)
{
    fsp_err_t err;

    if (NULL != p_cfg)
    {
        g_smart_relay_ui_cfg = *p_cfg;
    }
    else
    {
        g_smart_relay_ui_cfg.p_screen_open = NULL;
        g_smart_relay_ui_cfg.p_context     = NULL;
    }

    g_smart_relay_ui_next_event     = false;
    g_smart_relay_ui_ok_event       = false;
    g_smart_relay_ui_back_event     = false;
    g_smart_relay_ui_home_event     = false;
    g_smart_relay_ui_initialized    = true;

    err = Smart_Relay_UI_Load_Home();

    if (FSP_SUCCESS != err)
    {
        g_smart_relay_ui_initialized = false;
    }

    return err;
}

/**
 * @brief Loads the 320 x 240 RGB565 Home image and resets the cursor to Start.
 *
 * The image is read directly from the const ui_home_320x240_rgb565 array stored in Flash. The display driver must send
 * all UI_HOME_320X240_RGB565_BYTE_COUNT bytes, including the final partial SPI block.
 *
 * @retval FSP_SUCCESS The Home bitmap and cursor were displayed successfully.
 * @retval FSP_ERR_NOT_OPEN Smart_Relay_UI_Init() has not been called.
 * @return Any other FSP error code returned by the ILI9341 driver.
*/
fsp_err_t Smart_Relay_UI_Load_Home(void)
{
    if (!g_smart_relay_ui_initialized)
    {
        return FSP_ERR_NOT_OPEN;
    }

    g_smart_relay_ui_selected_item   = Smart_Relay_Ui_Home_Item_START;
    g_smart_relay_ui_active_screen   = Smart_Relay_Ui_Screen_HOME;
    g_smart_relay_ui_previous_screen = Smart_Relay_Ui_Screen_HOME;

    return smart_relay_ui_render_home();
}

/**
 * @brief Processes one pending button event outside the interrupt context.
 *
 * Event priority is HOME, BACK, OK, then NEXT. At most one event is processed per call.
 *
 * @retval FSP_SUCCESS No event was pending or the pending event was processed successfully.
 * @retval FSP_ERR_NOT_OPEN Smart_Relay_UI_Init() has not been called.
 * @return Any other FSP error code returned by the display or application screen callback.
*/
fsp_err_t Smart_Relay_UI_Process(void)
{
    if (!g_smart_relay_ui_initialized)
    {
        return FSP_ERR_NOT_OPEN;
    }

    if (g_smart_relay_ui_home_event)
    {
        g_smart_relay_ui_home_event = false;
        return smart_relay_ui_handle_home();
    }

    if (g_smart_relay_ui_back_event)
    {
        g_smart_relay_ui_back_event = false;
        return smart_relay_ui_handle_back();
    }

    if (g_smart_relay_ui_ok_event)
    {
        g_smart_relay_ui_ok_event = false;
        return smart_relay_ui_handle_ok();
    }

    if (g_smart_relay_ui_next_event)
    {
        g_smart_relay_ui_next_event = false;
        return smart_relay_ui_handle_next();
    }

    return FSP_SUCCESS;
}

/**
 * @brief Returns the active UI screen.
 *
 * @return Current Smart Relay UI screen.
*/
Smart_Relay_Ui_Screen_t Smart_Relay_UI_Get_Active_Screen(void)
{
    return g_smart_relay_ui_active_screen;
}

/**
 * @brief Returns the selected Home item.
 *
 * @return Current Home menu selection.
 */
Smart_Relay_Ui_Home_Item_t Smart_Relay_UI_Get_Selected_Item(void)
{
    return g_smart_relay_ui_selected_item;
}

/**
 * @brief Records one button event for later processing by Smart_Relay_UI_Process().
 *
 * This callback only updates an event flag. It does not draw to the LCD and does not start an SPI transfer, so it can
 * be called by a GPIO polling routine or by an application-specific External IRQ adapter.
 *
 * @param[in] p_args Smart Relay UI button callback arguments.
*/
void Smart_Relay_UI_Button_Callback(Smart_Relay_Ui_Button_Args_t const * p_args)
{
    if (NULL == p_args)
    {
        return;
    }

    switch (p_args->button)
    {
        case Smart_Relay_Ui_Button_NEXT:
        {
            g_smart_relay_ui_next_event = true;
            break;
        }

        case Smart_Relay_Ui_Button_OK:
        {
            g_smart_relay_ui_ok_event = true;
            break;
        }

        case Smart_Relay_Ui_Button_BACK:
        {
            g_smart_relay_ui_back_event = true;
            break;
        }

        case Smart_Relay_Ui_Button_HOME:
        {
            g_smart_relay_ui_home_event = true;
            break;
        }

        default:
        {
            /* Ignore unsupported button values. */
            break;
        }
    }
}

/**
 * @brief Draws or erases the cursor around one Home tile.
 *
 * @param[in] item  Home item whose cursor rectangle is updated.
 * @param[in] color RGB565 cursor or background color.
 *
 * @return FSP error code returned by ILI9341_Draw_Hollow_Rectangle_Coord().
*/
static fsp_err_t smart_relay_ui_draw_cursor(Smart_Relay_Ui_Home_Item_t item, uint16_t color)
{
    smart_relay_ui_menu_position_t const * p_position = &g_smart_relay_ui_home_menu[item];

    return ILI9341_Draw_Hollow_Rectangle_Coord(p_position->x0,
                                               p_position->y0,
                                               p_position->x1,
                                               p_position->y1,
                                               color);
}

/**
 * @brief Sends the complete Home bitmap to the LCD and draws the current cursor.
 *
 * @return FSP error code returned by the ILI9341 driver.
*/
static fsp_err_t smart_relay_ui_render_home(void)
{
    fsp_err_t err;

    err = ILI9341_Draw_Image((const char *) ui_home_320x240_rgb565, SCREEN_HORIZONTAL_1);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    return smart_relay_ui_draw_cursor(g_smart_relay_ui_selected_item, SMART_RELAY_UI_CURSOR_COLOR);
}

/**
 * @brief Moves the Home cursor to the next tile and wraps after User.
 *
 * @return FSP error code returned by the ILI9341 driver.
*/
static fsp_err_t smart_relay_ui_handle_next(void)
{
    fsp_err_t err;
    Smart_Relay_Ui_Home_Item_t const old_item = g_smart_relay_ui_selected_item;

    if (Smart_Relay_Ui_Screen_HOME != g_smart_relay_ui_active_screen)
    {
        return FSP_SUCCESS;
    }

    err = smart_relay_ui_draw_cursor(g_smart_relay_ui_selected_item,
                                     SMART_RELAY_UI_HOME_BACKGROUND_COLOR);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    g_smart_relay_ui_selected_item = (Smart_Relay_Ui_Home_Item_t)
        (((uint32_t) g_smart_relay_ui_selected_item + 1U) % (uint32_t) Smart_Relay_Ui_Home_Item_MAX);

    err = smart_relay_ui_draw_cursor(g_smart_relay_ui_selected_item, SMART_RELAY_UI_CURSOR_COLOR);

    if (FSP_SUCCESS != err)
    {
        g_smart_relay_ui_selected_item = old_item;
        (void) smart_relay_ui_draw_cursor(old_item, SMART_RELAY_UI_CURSOR_COLOR);
    }

    return err;
}

/**
 * @brief Opens the child screen associated with the selected Home item.
 *
 * @return FSP error code returned by the application screen callback.
*/
static fsp_err_t smart_relay_ui_handle_ok(void)
{
    Smart_Relay_Ui_Screen_t destination;

    if (Smart_Relay_Ui_Screen_HOME != g_smart_relay_ui_active_screen)
    {
        return FSP_SUCCESS;
    }

    destination = g_smart_relay_ui_home_menu[g_smart_relay_ui_selected_item].destination_screen;

    return smart_relay_ui_open_child_screen(destination);
}

/**
 * @brief Returns from a child screen to the previous screen.
 *
 * @return FSP error code returned by the display or application screen callback.
*/
static fsp_err_t smart_relay_ui_handle_back(void)
{
    fsp_err_t err;
    Smart_Relay_Ui_Screen_t const previous = g_smart_relay_ui_previous_screen;

    if (Smart_Relay_Ui_Screen_HOME == g_smart_relay_ui_active_screen)
    {
        return FSP_SUCCESS;
    }

    if (Smart_Relay_Ui_Screen_HOME == previous)
    {
        g_smart_relay_ui_active_screen   = Smart_Relay_Ui_Screen_HOME;
        g_smart_relay_ui_previous_screen = Smart_Relay_Ui_Screen_HOME;

        return smart_relay_ui_render_home();
    }

    if (NULL == g_smart_relay_ui_cfg.p_screen_open)
    {
        return FSP_ERR_UNSUPPORTED;
    }

    err = g_smart_relay_ui_cfg.p_screen_open(previous, g_smart_relay_ui_cfg.p_context);

    if (FSP_SUCCESS == err)
    {
        g_smart_relay_ui_active_screen   = previous;
        g_smart_relay_ui_previous_screen = Smart_Relay_Ui_Screen_HOME;
    }

    return err;
}

/**
 * @brief Returns directly to Home and resets the cursor to Start.
 *
 * @return FSP error code returned by Smart_Relay_UI_Load_Home().
*/
static fsp_err_t smart_relay_ui_handle_home(void)
{
    return Smart_Relay_UI_Load_Home();
}

/**
 * @brief Calls the application callback to draw a child screen and updates navigation state.
 *
 * @param[in] screen Child screen requested by the UI state machine.
 *
 * @return FSP error code returned by the application callback.
*/
static fsp_err_t smart_relay_ui_open_child_screen(Smart_Relay_Ui_Screen_t screen)
{
    fsp_err_t err;

    if (NULL == g_smart_relay_ui_cfg.p_screen_open)
    {
        return FSP_ERR_UNSUPPORTED;
    }

    err = g_smart_relay_ui_cfg.p_screen_open(screen, g_smart_relay_ui_cfg.p_context);

    if (FSP_SUCCESS == err)
    {
        g_smart_relay_ui_previous_screen = g_smart_relay_ui_active_screen;
        g_smart_relay_ui_active_screen   = screen;
    }

    return err;
}

/*******************************************************************************************************************//**
 * @} (end addtogroup Ui_Home_ep)
 **********************************************************************************************************************/