/*******************************************************************************************************************//**
 * @file App1.c
 * @brief Implements the touch-enabled Smart Relay application while preserving the existing App.c UI logic.
 *
 * The Home bitmap, child-screen transitions, Relay UI, QR UI, relay outputs, and software MM:SS clock are kept from the
 * existing Smart Relay application. Button_App_Init() and Button_App_Process() are intentionally removed. Touch input is
 * read through TP_Touchpad_Pressed() and TP_Read_Coordinates(). A touch is latched until release so one physical press
 * produces one application action.
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/

#include <stdbool.h>
#include <stddef.h>

#include "App1.h"
#include "ILI9341_GFX.h"
#include "ILI9341_Touch.h"
#include "Relay_ep.h"
#include "Ui_Relay_ep.h"
#include "Ui_QR_ep.h"
#include "ui_home_320x240_rgb565.h"

/***********************************************************************************************************************
 * Macro definitions
 **********************************************************************************************************************/

/* Home menu geometry. */
#define SMART_RELAY_APP1_HOME_COLUMN_COUNT             (3U)
#define SMART_RELAY_APP1_HOME_ROW_COUNT                (2U)

/* Cursor colors sampled from the Home bitmap. */
#define SMART_RELAY_APP1_HOME_BACKGROUND_COLOR         (0x08A5U)
#define SMART_RELAY_APP1_CURSOR_COLOR                  (0xFFE0U)

/* Software clock configuration retained from App.c. */
#define SMART_RELAY_APP1_ONE_SECOND_MS                  (1000U)
#define SMART_RELAY_APP1_TIMER_START_MINUTE             (0U)
#define SMART_RELAY_APP1_TIMER_START_SECOND             (20U)
#define SMART_RELAY_APP1_TIMER_MINUTE_LIMIT             (100U)

/* Clock drawing area in the Home bitmap header. */
#define SMART_RELAY_APP1_CLOCK_AREA_X                   (236U)
#define SMART_RELAY_APP1_CLOCK_AREA_Y                   (9U)
#define SMART_RELAY_APP1_CLOCK_AREA_WIDTH               (27U)
#define SMART_RELAY_APP1_CLOCK_AREA_HEIGHT              (7U)
#define SMART_RELAY_APP1_CLOCK_DIGIT_WIDTH              (5U)
#define SMART_RELAY_APP1_CLOCK_DIGIT_HEIGHT             (7U)
#define SMART_RELAY_APP1_MINUTE_TENS_OFFSET             (0U)
#define SMART_RELAY_APP1_MINUTE_ONES_OFFSET             (6U)
#define SMART_RELAY_APP1_CLOCK_COLON_X_OFFSET           (13U)
#define SMART_RELAY_APP1_SECOND_TENS_OFFSET             (16U)
#define SMART_RELAY_APP1_SECOND_ONES_OFFSET             (22U)

/* RGB565 colors used by the Home clock and default child-screen renderer. */
#define SMART_RELAY_APP1_HEADER_BACKGROUND_COLOR        (0x1271U)
#define SMART_RELAY_APP1_CLOCK_TEXT_COLOR               (0xCEFEU)
#define SMART_RELAY_APP1_CHILD_BACKGROUND_COLOR         (0x08A5U)

/***********************************************************************************************************************
 * Typedef definitions
 **********************************************************************************************************************/

/** Touch rectangle and destination screen associated with one Home item. */
typedef struct st_smart_relay_app1_menu_position
{
    uint16_t                  x0;
    uint16_t                  y0;
    uint16_t                  x1;
    uint16_t                  y1;
    smart_relay_app_screen_t  destination_screen;
} smart_relay_app1_menu_position_t;

/** One transformed touchscreen press accepted by the App1 input layer. */
typedef struct st_smart_relay_app1_touch_point
{
    uint16_t x;
    uint16_t y;
    bool     valid;
} smart_relay_app1_touch_point_t;

/** Touch input state used to debounce both press and release without blocking the application loop. */
typedef enum e_smart_relay_app1_touch_state
{
    SMART_RELAY_APP1_TOUCH_STATE_IDLE = 0,
    SMART_RELAY_APP1_TOUCH_STATE_PRESS_DEBOUNCE,
    SMART_RELAY_APP1_TOUCH_STATE_PRESSED,
    SMART_RELAY_APP1_TOUCH_STATE_RELEASE_DEBOUNCE
} smart_relay_app1_touch_state_t;

/***********************************************************************************************************************
 * Private function declarations
 **********************************************************************************************************************/

static fsp_err_t smart_relay_app1_render_home(void);
static fsp_err_t smart_relay_app1_draw_cursor(smart_relay_app_home_item_t item, uint16_t color);
static fsp_err_t smart_relay_app1_handle_select(void);
static fsp_err_t smart_relay_app1_handle_back(void);
static fsp_err_t smart_relay_app1_handle_home(void);
static fsp_err_t smart_relay_app1_draw_child_screen(smart_relay_app_screen_t screen);
static fsp_err_t smart_relay_app1_draw_default_child_screen(smart_relay_app_screen_t screen);
static fsp_err_t smart_relay_app1_clock_process(uint32_t elapsed_ms);
static fsp_err_t smart_relay_app1_clock_draw(void);
static fsp_err_t smart_relay_app1_relay_write(ui_relay_channel_t channel, bool enabled, void * p_context);
static void      smart_relay_app1_clock_render_digit(uint8_t digit, uint16_t x_offset);

static fsp_err_t smart_relay_app1_touch_read(uint32_t elapsed_ms, smart_relay_app1_touch_point_t * p_touch);
static void      smart_relay_app1_touch_transform(uint16_t raw_x,
                                                   uint16_t raw_y,
                                                   uint16_t * p_screen_x,
                                                   uint16_t * p_screen_y);
static bool      smart_relay_app1_point_inside(uint16_t x,
                                               uint16_t y,
                                               uint16_t x0,
                                               uint16_t y0,
                                               uint16_t x1,
                                               uint16_t y1);
static fsp_err_t smart_relay_app1_process_touch(smart_relay_app1_touch_point_t const * p_touch);
static fsp_err_t smart_relay_app1_process_home_touch(uint16_t x, uint16_t y);
static fsp_err_t smart_relay_app1_process_child_touch(uint16_t x, uint16_t y);
static fsp_err_t smart_relay_app1_process_relay_touch(uint16_t x, uint16_t y);
static fsp_err_t smart_relay_app1_relay_move_to(uint32_t target_index);
static fsp_err_t smart_relay_app1_relay_action(uint32_t action);

/***********************************************************************************************************************
 * Private global variables
 **********************************************************************************************************************/

/* Home tile rectangles are retained from App.c so touch selection matches the existing bitmap. */
static smart_relay_app1_menu_position_t const g_smart_relay_app1_home_menu[SMART_RELAY_APP_HOME_ITEM_MAX] =
{
    {8U,   30U, 103U, 113U, SMART_RELAY_APP_SCREEN_START},
    {112U, 30U, 207U, 113U, SMART_RELAY_APP_SCREEN_SETUP},
    {216U, 30U, 311U, 113U, SMART_RELAY_APP_SCREEN_PROGRAM},
    {8U,  117U, 103U, 200U, SMART_RELAY_APP_SCREEN_CARD},
    {112U,117U, 207U, 200U, SMART_RELAY_APP_SCREEN_DIAGNOSTICS},
    {216U,117U, 311U, 200U, SMART_RELAY_APP_SCREEN_USER}
};

static char const * const gp_smart_relay_app1_screen_name[SMART_RELAY_APP_SCREEN_MAX] =
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
static uint8_t const g_smart_relay_app1_clock_digits[10][SMART_RELAY_APP1_CLOCK_DIGIT_HEIGHT] =
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

static smart_relay_app_cfg_t       g_smart_relay_app1_cfg;
static smart_relay_app_screen_t    g_smart_relay_app1_active_screen   = SMART_RELAY_APP_SCREEN_HOME;
static smart_relay_app_screen_t    g_smart_relay_app1_previous_screen = SMART_RELAY_APP_SCREEN_HOME;
static smart_relay_app_home_item_t g_smart_relay_app1_selected_item   = SMART_RELAY_APP_HOME_ITEM_START;
static bool                        g_smart_relay_app1_initialized;
static smart_relay_app1_touch_state_t g_smart_relay_app1_touch_state = SMART_RELAY_APP1_TOUCH_STATE_IDLE;
static uint32_t                       g_smart_relay_app1_touch_debounce_ms;

/* Shadow of the Relay UI focus. UI_Relay is opened at Relay 1 by the existing application design. */
static uint32_t g_smart_relay_app1_relay_focus_index;

/* Software clock state. The time resets whenever the microcontroller restarts. */
static uint32_t g_smart_relay_app1_clock_elapsed_ms;
static uint8_t  g_smart_relay_app1_clock_minute;
static uint8_t  g_smart_relay_app1_clock_second;
static uint16_t g_smart_relay_app1_clock_buffer[SMART_RELAY_APP1_CLOCK_AREA_WIDTH *
                                                 SMART_RELAY_APP1_CLOCK_AREA_HEIGHT];

/***********************************************************************************************************************
 * Global variables
 **********************************************************************************************************************/

volatile fsp_err_t g_smart_relay_app1_error       = FSP_SUCCESS;
volatile uint16_t  g_smart_relay_app1_touch_x;
volatile uint16_t  g_smart_relay_app1_touch_y;
volatile uint32_t  g_smart_relay_app1_touch_count;
volatile uint32_t  g_smart_relay_app1_touch_noisy_count;

/*******************************************************************************************************************//**
 * @addtogroup Smart_Relay_Application_Touch
 * @{
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Functions
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * @brief Initializes the LCD, Relay UI, QR UI, touch state, Home UI, and software clock.
 *
 * @param[in] p_cfg Optional application configuration.
 *
 * @retval FSP_SUCCESS          Application initialized successfully.
 * @retval FSP_ERR_ALREADY_OPEN Application is already initialized.
 * @return Any error returned by the LCD, Relay UI, QR UI, or relay driver.
 **********************************************************************************************************************/
fsp_err_t Smart_Relay_App1_Init(smart_relay_app1_cfg_t const * p_cfg)
{
    fsp_err_t      err;
    ui_relay_cfg_t relay_cfg;
    bool           use_onboard_relay_app;

    if (g_smart_relay_app1_initialized)
    {
        return FSP_ERR_ALREADY_OPEN;
    }

    if (NULL != p_cfg)
    {
        g_smart_relay_app1_cfg = *p_cfg;
    }
    else
    {
        g_smart_relay_app1_cfg.p_screen_draw            = NULL;
        g_smart_relay_app1_cfg.p_context                = NULL;
        g_smart_relay_app1_cfg.p_relay_write            = NULL;
        g_smart_relay_app1_cfg.p_relay_context          = NULL;
        g_smart_relay_app1_cfg.relay_initial_state_mask = 0U;
    }

    use_onboard_relay_app = (NULL == g_smart_relay_app1_cfg.p_relay_write);

    if (use_onboard_relay_app)
    {
        err = Relay_App_Init(g_smart_relay_app1_cfg.relay_initial_state_mask);

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

    relay_cfg.p_output_write = use_onboard_relay_app ? smart_relay_app1_relay_write :
                                                      g_smart_relay_app1_cfg.p_relay_write;
    relay_cfg.p_context = use_onboard_relay_app ? NULL : g_smart_relay_app1_cfg.p_relay_context;
    relay_cfg.initial_state_mask = g_smart_relay_app1_cfg.relay_initial_state_mask;

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

    /* No Button_App_Init() and no SPI initialization are required for the GPIO-bit-banged touch driver. */
    g_smart_relay_app1_active_screen    = SMART_RELAY_APP_SCREEN_HOME;
    g_smart_relay_app1_previous_screen  = SMART_RELAY_APP_SCREEN_HOME;
    g_smart_relay_app1_selected_item    = SMART_RELAY_APP_HOME_ITEM_START;
    g_smart_relay_app1_touch_state      = SMART_RELAY_APP1_TOUCH_STATE_IDLE;
    g_smart_relay_app1_touch_debounce_ms = 0U;
    g_smart_relay_app1_relay_focus_index = 0U;
    g_smart_relay_app1_clock_elapsed_ms = 0U;
    g_smart_relay_app1_clock_minute     = SMART_RELAY_APP1_TIMER_START_MINUTE;
    g_smart_relay_app1_clock_second     = SMART_RELAY_APP1_TIMER_START_SECOND;

    g_smart_relay_app1_touch_x     = 0U;
    g_smart_relay_app1_touch_y     = 0U;
    g_smart_relay_app1_touch_count       = 0U;
    g_smart_relay_app1_touch_noisy_count = 0U;
    g_smart_relay_app1_initialized = true;

    err = smart_relay_app1_render_home();

    if (FSP_SUCCESS != err)
    {
        g_smart_relay_app1_initialized = false;

        if (use_onboard_relay_app)
        {
            (void) Relay_App_Close();
        }
    }

    return err;
}

/*******************************************************************************************************************//**
 * @brief Polls the touchscreen, executes one touch action, and advances the software clock.
 *
 * @param[in] elapsed_ms Time elapsed since the previous call, in milliseconds.
 *
 * @retval FSP_SUCCESS              Application processed successfully.
 * @retval FSP_ERR_NOT_OPEN         Application is not initialized.
 * @retval FSP_ERR_INVALID_ARGUMENT elapsed_ms is zero.
 * @return Any error returned by the display or child UI modules.
 **********************************************************************************************************************/
fsp_err_t Smart_Relay_App1_Process(uint32_t elapsed_ms)
{
    fsp_err_t                        err;
    smart_relay_app1_touch_point_t   touch;

    if (!g_smart_relay_app1_initialized)
    {
        return FSP_ERR_NOT_OPEN;
    }

    if (0U == elapsed_ms)
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    err = smart_relay_app1_touch_read(elapsed_ms, &touch);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    if (touch.valid)
    {
        err = smart_relay_app1_process_touch(&touch);

        if (FSP_SUCCESS != err)
        {
            return err;
        }
    }

    return smart_relay_app1_clock_process(elapsed_ms);
}

/*******************************************************************************************************************//**
 * @brief Returns the active application screen.
 *
 * @return Current Smart Relay application screen.
 **********************************************************************************************************************/
smart_relay_app1_screen_t Smart_Relay_App1_Get_Active_Screen(void)
{
    return g_smart_relay_app1_active_screen;
}

/*******************************************************************************************************************//**
 * @brief Returns the selected item on the Home screen.
 *
 * @return Current Home-menu selection.
 **********************************************************************************************************************/
smart_relay_app1_home_item_t Smart_Relay_App1_Get_Selected_Item(void)
{
    return g_smart_relay_app1_selected_item;
}

/*******************************************************************************************************************//**
 * @brief Runs the standalone touch-enabled Smart Relay application loop.
 **********************************************************************************************************************/
void Smart_Relay_App1_Run(void)
{
    fsp_err_t err;

    err = Smart_Relay_App1_Init(NULL);
    g_smart_relay_app1_error = err;

    if (FSP_SUCCESS != err)
    {
        return;
    }

    while (true)
    {
        R_BSP_SoftwareDelay(SMART_RELAY_APP_PROCESS_PERIOD_MS, BSP_DELAY_UNITS_MILLISECONDS);

        err = Smart_Relay_App1_Process(SMART_RELAY_APP_PROCESS_PERIOD_MS);

        if (FSP_SUCCESS != err)
        {
            g_smart_relay_app1_error = err;
            return;
        }
    }
}

/*******************************************************************************************************************//**
 * @} (end addtogroup Smart_Relay_Application_Touch)
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Private function definitions
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * @brief Debounces the active-low touch IRQ and produces exactly one event for each physical press.
 *
 * @details Press and release are debounced as separate non-blocking states. Coordinates are sampled only after the
 *          press has remained stable, and a short IRQ glitch while held does not re-arm the input.
 *
 * @param[in]  elapsed_ms Time since the previous call in milliseconds.
 * @param[out] p_touch    Destination touch event.
 *
 * @retval FSP_SUCCESS      Touch state processed successfully.
 * @retval FSP_ERR_ASSERTION p_touch is NULL.
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app1_touch_read(uint32_t elapsed_ms, smart_relay_app1_touch_point_t * p_touch)
{
    uint16_t coordinates[2];
    bool     pressed;

    if (NULL == p_touch)
    {
        return FSP_ERR_ASSERTION;
    }

    p_touch->x     = 0U;
    p_touch->y     = 0U;
    p_touch->valid = false;

    pressed = (TOUCHPAD_PRESSED == TP_Touchpad_Pressed());

    switch (g_smart_relay_app1_touch_state)
    {
        case SMART_RELAY_APP1_TOUCH_STATE_IDLE:
        {
            if (pressed)
            {
                g_smart_relay_app1_touch_state       = SMART_RELAY_APP1_TOUCH_STATE_PRESS_DEBOUNCE;
                g_smart_relay_app1_touch_debounce_ms = elapsed_ms;
            }
            break;
        }

        case SMART_RELAY_APP1_TOUCH_STATE_PRESS_DEBOUNCE:
        {
            if (!pressed)
            {
                g_smart_relay_app1_touch_state       = SMART_RELAY_APP1_TOUCH_STATE_IDLE;
                g_smart_relay_app1_touch_debounce_ms = 0U;
                break;
            }

            if (g_smart_relay_app1_touch_debounce_ms < SMART_RELAY_APP1_TOUCH_PRESS_DEBOUNCE_MS)
            {
                g_smart_relay_app1_touch_debounce_ms += elapsed_ms;
            }

            if (g_smart_relay_app1_touch_debounce_ms >= SMART_RELAY_APP1_TOUCH_PRESS_DEBOUNCE_MS)
            {
                if (TOUCHPAD_DATA_OK == TP_Read_Coordinates(coordinates))
                {
                    smart_relay_app1_touch_transform(coordinates[0], coordinates[1], &p_touch->x, &p_touch->y);

                    g_smart_relay_app1_touch_x      = p_touch->x;
                    g_smart_relay_app1_touch_y      = p_touch->y;
                    g_smart_relay_app1_touch_count++;
                    g_smart_relay_app1_touch_state = SMART_RELAY_APP1_TOUCH_STATE_PRESSED;
                    p_touch->valid                  = true;
                }
                else
                {
                    /* Keep waiting while the finger remains down; a later filtered sample may be valid. */
                    g_smart_relay_app1_touch_noisy_count++;
                }
            }
            break;
        }

        case SMART_RELAY_APP1_TOUCH_STATE_PRESSED:
        {
            if (!pressed)
            {
                g_smart_relay_app1_touch_state       = SMART_RELAY_APP1_TOUCH_STATE_RELEASE_DEBOUNCE;
                g_smart_relay_app1_touch_debounce_ms = elapsed_ms;
            }
            break;
        }

        case SMART_RELAY_APP1_TOUCH_STATE_RELEASE_DEBOUNCE:
        {
            if (pressed)
            {
                /* A short HIGH glitch is not treated as a real release. */
                g_smart_relay_app1_touch_state       = SMART_RELAY_APP1_TOUCH_STATE_PRESSED;
                g_smart_relay_app1_touch_debounce_ms = 0U;
                break;
            }

            if (g_smart_relay_app1_touch_debounce_ms < SMART_RELAY_APP1_TOUCH_RELEASE_DEBOUNCE_MS)
            {
                g_smart_relay_app1_touch_debounce_ms += elapsed_ms;
            }

            if (g_smart_relay_app1_touch_debounce_ms >= SMART_RELAY_APP1_TOUCH_RELEASE_DEBOUNCE_MS)
            {
                g_smart_relay_app1_touch_state       = SMART_RELAY_APP1_TOUCH_STATE_IDLE;
                g_smart_relay_app1_touch_debounce_ms = 0U;
            }
            break;
        }

        default:
        {
            g_smart_relay_app1_touch_state       = SMART_RELAY_APP1_TOUCH_STATE_IDLE;
            g_smart_relay_app1_touch_debounce_ms = 0U;
            break;
        }
    }

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Converts legacy portrait touchscreen coordinates into the Smart Relay 320 x 240 display coordinate system.
 *
 * @param[in]  raw_x      X coordinate returned by TP_Read_Coordinates().
 * @param[in]  raw_y      Y coordinate returned by TP_Read_Coordinates().
 * @param[out] p_screen_x Transformed screen X coordinate.
 * @param[out] p_screen_y Transformed screen Y coordinate.
 **********************************************************************************************************************/
static void smart_relay_app1_touch_transform(uint16_t raw_x,
                                              uint16_t raw_y,
                                              uint16_t * p_screen_x,
                                              uint16_t * p_screen_y)
{
    uint32_t x = raw_x;
    uint32_t y = raw_y;
    uint32_t temp;

    if ((NULL == p_screen_x) || (NULL == p_screen_y))
    {
        return;
    }

#if (0U != SMART_RELAY_APP1_TOUCH_SWAP_XY)
    temp = x;
    x    = y;
    y    = temp;
#else
    (void) temp;
#endif

    if (x >= SMART_RELAY_APP1_SCREEN_WIDTH)
    {
        x = SMART_RELAY_APP1_SCREEN_WIDTH - 1U;
    }

    if (y >= SMART_RELAY_APP1_SCREEN_HEIGHT)
    {
        y = SMART_RELAY_APP1_SCREEN_HEIGHT - 1U;
    }

#if (0U != SMART_RELAY_APP1_TOUCH_INVERT_X)
    x = (SMART_RELAY_APP1_SCREEN_WIDTH - 1U) - x;
#endif

#if (0U != SMART_RELAY_APP1_TOUCH_INVERT_Y)
    y = (SMART_RELAY_APP1_SCREEN_HEIGHT - 1U) - y;
#endif

    *p_screen_x = (uint16_t) x;
    *p_screen_y = (uint16_t) y;
}

/*******************************************************************************************************************//**
 * @brief Routes one touch point according to the currently active screen.
 *
 * @param[in] p_touch Valid transformed touch point.
 *
 * @return FSP error code returned by the selected application handler.
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app1_process_touch(smart_relay_app1_touch_point_t const * p_touch)
{
    if ((NULL == p_touch) || !p_touch->valid)
    {
        return FSP_SUCCESS;
    }

    if (SMART_RELAY_APP_SCREEN_HOME == g_smart_relay_app1_active_screen)
    {
        return smart_relay_app1_process_home_touch(p_touch->x, p_touch->y);
    }

    if (SMART_RELAY_APP_SCREEN_PROGRAM == g_smart_relay_app1_active_screen)
    {
        return smart_relay_app1_process_relay_touch(p_touch->x, p_touch->y);
    }

    return smart_relay_app1_process_child_touch(p_touch->x, p_touch->y);
}

/*******************************************************************************************************************//**
 * @brief Opens the Home item touched by the user.
 *
 * @param[in] x Screen X coordinate.
 * @param[in] y Screen Y coordinate.
 *
 * @return FSP error code returned by the child-screen renderer.
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app1_process_home_touch(uint16_t x, uint16_t y)
{
    uint32_t index;

    for (index = 0U; index < (uint32_t) SMART_RELAY_APP_HOME_ITEM_MAX; index++)
    {
        smart_relay_app1_menu_position_t const * p_item = &g_smart_relay_app1_home_menu[index];

        if (smart_relay_app1_point_inside(x, y, p_item->x0, p_item->y0, p_item->x1, p_item->y1))
        {
            g_smart_relay_app1_selected_item = (smart_relay_app_home_item_t) index;
            return smart_relay_app1_handle_select();
        }
    }

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Processes BACK and HOME touch zones for non-Home screens.
 *
 * @param[in] x Screen X coordinate.
 * @param[in] y Screen Y coordinate.
 *
 * @return FSP error code returned by the requested screen transition.
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app1_process_child_touch(uint16_t x, uint16_t y)
{
    if (y < SMART_RELAY_APP1_NAVIGATION_Y_MIN)
    {
        return FSP_SUCCESS;
    }

    if (x < SMART_RELAY_APP1_NAVIGATION_X_SPLIT)
    {
        return smart_relay_app1_handle_back();
    }

    return smart_relay_app1_handle_home();
}

/*******************************************************************************************************************//**
 * @brief Converts a touch on the Program screen into Relay UI navigation and relay selection.
 *
 * @details The bottom navigation strip behaves as BACK on the left and HOME on the right. A touch inside the configured
 *          two-row by four-column relay grid moves the existing UI_Relay focus to the touched channel and then sends the
 *          same UI_RELAY_ACTION_SELECT action previously produced by the OK button.
 *
 * @param[in] x Screen X coordinate.
 * @param[in] y Screen Y coordinate.
 *
 * @return FSP error code returned by UI_Relay or the Home renderer.
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app1_process_relay_touch(uint16_t x, uint16_t y)
{
    uint32_t column;
    uint32_t row;
    uint32_t target_index;
    uint32_t grid_width;
    uint32_t grid_height;

    if (y >= SMART_RELAY_APP1_NAVIGATION_Y_MIN)
    {
        if (x < SMART_RELAY_APP1_NAVIGATION_X_SPLIT)
        {
            return smart_relay_app1_handle_back();
        }

        return smart_relay_app1_handle_home();
    }

    if (!smart_relay_app1_point_inside(x,
                                       y,
                                       SMART_RELAY_APP1_RELAY_GRID_X0,
                                       SMART_RELAY_APP1_RELAY_GRID_Y0,
                                       SMART_RELAY_APP1_RELAY_GRID_X1,
                                       SMART_RELAY_APP1_RELAY_GRID_Y1))
    {
        return FSP_SUCCESS;
    }

    grid_width  = (SMART_RELAY_APP1_RELAY_GRID_X1 - SMART_RELAY_APP1_RELAY_GRID_X0) + 1U;
    grid_height = (SMART_RELAY_APP1_RELAY_GRID_Y1 - SMART_RELAY_APP1_RELAY_GRID_Y0) + 1U;

    column = (((uint32_t) x - SMART_RELAY_APP1_RELAY_GRID_X0) * SMART_RELAY_APP1_RELAY_COLUMN_COUNT) / grid_width;
    row    = (((uint32_t) y - SMART_RELAY_APP1_RELAY_GRID_Y0) * SMART_RELAY_APP1_RELAY_ROW_COUNT) / grid_height;

    if (column >= SMART_RELAY_APP1_RELAY_COLUMN_COUNT)
    {
        column = SMART_RELAY_APP1_RELAY_COLUMN_COUNT - 1U;
    }

    if (row >= SMART_RELAY_APP1_RELAY_ROW_COUNT)
    {
        row = SMART_RELAY_APP1_RELAY_ROW_COUNT - 1U;
    }

    target_index = (row * SMART_RELAY_APP1_RELAY_COLUMN_COUNT) + column;

    return smart_relay_app1_relay_move_to(target_index);
}

/*******************************************************************************************************************//**
 * @brief Moves the existing Relay UI focus to one touched relay and toggles it.
 *
 * @param[in] target_index Zero-based target relay index in the range 0 through 7.
 *
 * @retval FSP_SUCCESS              Relay focus moved and SELECT action processed successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT target_index is outside the supported relay range.
 * @return Any error returned by UI_Relay_Process().
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app1_relay_move_to(uint32_t target_index)
{
    fsp_err_t err;
    uint32_t current_row;
    uint32_t current_column;
    uint32_t target_row;
    uint32_t target_column;

    if (target_index >= (SMART_RELAY_APP1_RELAY_ROW_COUNT * SMART_RELAY_APP1_RELAY_COLUMN_COUNT))
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    current_row    = g_smart_relay_app1_relay_focus_index / SMART_RELAY_APP1_RELAY_COLUMN_COUNT;
    current_column = g_smart_relay_app1_relay_focus_index % SMART_RELAY_APP1_RELAY_COLUMN_COUNT;
    target_row     = target_index / SMART_RELAY_APP1_RELAY_COLUMN_COUNT;
    target_column  = target_index % SMART_RELAY_APP1_RELAY_COLUMN_COUNT;

    while (current_row < target_row)
    {
        err = smart_relay_app1_relay_action((uint32_t) UI_RELAY_ACTION_DOWN);

        if (FSP_SUCCESS != err)
        {
            return err;
        }

        current_row++;
    }

    while (current_row > target_row)
    {
        err = smart_relay_app1_relay_action((uint32_t) UI_RELAY_ACTION_UP);

        if (FSP_SUCCESS != err)
        {
            return err;
        }

        current_row--;
    }

    while (current_column < target_column)
    {
        err = smart_relay_app1_relay_action((uint32_t) UI_RELAY_ACTION_RIGHT);

        if (FSP_SUCCESS != err)
        {
            return err;
        }

        current_column++;
    }

    while (current_column > target_column)
    {
        err = smart_relay_app1_relay_action((uint32_t) UI_RELAY_ACTION_LEFT);

        if (FSP_SUCCESS != err)
        {
            return err;
        }

        current_column--;
    }

    g_smart_relay_app1_relay_focus_index = target_index;

    return smart_relay_app1_relay_action((uint32_t) UI_RELAY_ACTION_SELECT);
}

/*******************************************************************************************************************//**
 * @brief Sends one existing Relay UI action and ignores navigation for non-navigation actions.
 *
 * @param[in] action One UI_RELAY_ACTION_* value.
 *
 * @return FSP error code returned by UI_Relay_Process().
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app1_relay_action(uint32_t action)
{
    ui_relay_navigation_t navigation;

    return UI_Relay_Process(action, &navigation);
}

/*******************************************************************************************************************//**
 * @brief Tests whether one screen coordinate lies inside an inclusive rectangle.
 *
 * @param[in] x  Screen X coordinate.
 * @param[in] y  Screen Y coordinate.
 * @param[in] x0 Rectangle left edge.
 * @param[in] y0 Rectangle top edge.
 * @param[in] x1 Rectangle right edge.
 * @param[in] y1 Rectangle bottom edge.
 *
 * @retval true  Point is inside the rectangle.
 * @retval false Point is outside the rectangle.
 **********************************************************************************************************************/
static bool smart_relay_app1_point_inside(uint16_t x,
                                          uint16_t y,
                                          uint16_t x0,
                                          uint16_t y0,
                                          uint16_t x1,
                                          uint16_t y1)
{
    return ((x >= x0) && (x <= x1) && (y >= y0) && (y <= y1));
}

/*******************************************************************************************************************//**
 * @brief Opens the child screen associated with the selected Home item.
 *
 * @return FSP error code returned by the child-screen renderer.
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app1_handle_select(void)
{
    fsp_err_t                err;
    smart_relay_app_screen_t destination;

    if (SMART_RELAY_APP_SCREEN_HOME != g_smart_relay_app1_active_screen)
    {
        return FSP_SUCCESS;
    }

    destination = g_smart_relay_app1_home_menu[(uint32_t) g_smart_relay_app1_selected_item].destination_screen;
    err = smart_relay_app1_draw_child_screen(destination);

    if (FSP_SUCCESS == err)
    {
        g_smart_relay_app1_previous_screen = g_smart_relay_app1_active_screen;
        g_smart_relay_app1_active_screen   = destination;

        if (SMART_RELAY_APP_SCREEN_PROGRAM == destination)
        {
            /* UI_Relay opens with Relay 1 focused in the existing application design. */
            g_smart_relay_app1_relay_focus_index = 0U;
        }
    }

    return err;
}

/*******************************************************************************************************************//**
 * @brief Returns from the current child screen to Home while preserving the selected Home tile.
 *
 * @return FSP error code returned by the display driver.
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app1_handle_back(void)
{
    fsp_err_t err;

    if (SMART_RELAY_APP_SCREEN_HOME == g_smart_relay_app1_active_screen)
    {
        return FSP_SUCCESS;
    }

    if (SMART_RELAY_APP_SCREEN_PROGRAM == g_smart_relay_app1_active_screen)
    {
        (void) UI_Relay_Close();
    }
    else if (SMART_RELAY_APP_SCREEN_USER == g_smart_relay_app1_active_screen)
    {
        (void) UI_QR_Close();
    }

    err = smart_relay_app1_render_home();

    if (FSP_SUCCESS == err)
    {
        g_smart_relay_app1_active_screen   = SMART_RELAY_APP_SCREEN_HOME;
        g_smart_relay_app1_previous_screen = SMART_RELAY_APP_SCREEN_HOME;
    }

    return err;
}

/*******************************************************************************************************************//**
 * @brief Returns directly to Home and resets the Home selection to Start.
 *
 * @return FSP error code returned by the display driver.
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app1_handle_home(void)
{
    fsp_err_t err;

    if (SMART_RELAY_APP_SCREEN_PROGRAM == g_smart_relay_app1_active_screen)
    {
        (void) UI_Relay_Close();
    }
    else if (SMART_RELAY_APP_SCREEN_USER == g_smart_relay_app1_active_screen)
    {
        (void) UI_QR_Close();
    }

    g_smart_relay_app1_selected_item = SMART_RELAY_APP_HOME_ITEM_START;
    err = smart_relay_app1_render_home();

    if (FSP_SUCCESS == err)
    {
        g_smart_relay_app1_active_screen   = SMART_RELAY_APP_SCREEN_HOME;
        g_smart_relay_app1_previous_screen = SMART_RELAY_APP_SCREEN_HOME;
    }

    return err;
}

/*******************************************************************************************************************//**
 * @brief Applies one UI relay state to the onboard Y1 through Y8 relay driver.
 *
 * @param[in] channel   UI relay channel to update.
 * @param[in] enabled   true to energize the relay; false to release it.
 * @param[in] p_context Unused callback context.
 *
 * @retval FSP_SUCCESS              Relay output updated successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT channel is outside Relay 1 through Relay 8.
 * @return Any other FSP error code returned by Relay_App_Write().
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app1_relay_write(ui_relay_channel_t channel, bool enabled, void * p_context)
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
static fsp_err_t smart_relay_app1_render_home(void)
{
    fsp_err_t err;

    err = ILI9341_Draw_Image((char const *) ui_home_320x240_rgb565, SCREEN_HORIZONTAL_1);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    err = smart_relay_app1_clock_draw();

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    return smart_relay_app1_draw_cursor(g_smart_relay_app1_selected_item, SMART_RELAY_APP1_CURSOR_COLOR);
}

/*******************************************************************************************************************//**
 * @brief Draws or erases the cursor around one Home tile.
 *
 * @param[in] item  Home item whose cursor rectangle is updated.
 * @param[in] color RGB565 cursor or background color.
 *
 * @return FSP error code returned by ILI9341_Draw_Hollow_Rectangle_Coord().
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app1_draw_cursor(smart_relay_app_home_item_t item, uint16_t color)
{
    smart_relay_app1_menu_position_t const * p_position = &g_smart_relay_app1_home_menu[(uint32_t) item];

    return ILI9341_Draw_Hollow_Rectangle_Coord(p_position->x0,
                                               p_position->y0,
                                               p_position->x1,
                                               p_position->y1,
                                               color);
}

/*******************************************************************************************************************//**
 * @brief Draws a child screen using the existing Relay UI, QR UI, configured callback, or default placeholder.
 *
 * @param[in] screen Child screen requested by the touched Home item.
 *
 * @return FSP error code returned by the selected child-screen renderer.
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app1_draw_child_screen(smart_relay_app_screen_t screen)
{
    if (SMART_RELAY_APP_SCREEN_PROGRAM == screen)
    {
        return UI_Relay_Open();
    }

    if (SMART_RELAY_APP_SCREEN_USER == screen)
    {
        return UI_QR_Open();
    }

    if (NULL != g_smart_relay_app1_cfg.p_screen_draw)
    {
        return g_smart_relay_app1_cfg.p_screen_draw(screen, g_smart_relay_app1_cfg.p_context);
    }

    return smart_relay_app1_draw_default_child_screen(screen);
}

/*******************************************************************************************************************//**
 * @brief Draws the existing simple child-screen placeholder.
 *
 * @param[in] screen Child screen to identify on the display.
 *
 * @retval FSP_SUCCESS              Placeholder drawn successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT screen is outside the supported range.
 * @return Any other FSP error code returned by the graphics driver.
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app1_draw_default_child_screen(smart_relay_app_screen_t screen)
{
    fsp_err_t err;

    if ((SMART_RELAY_APP_SCREEN_HOME >= screen) || (SMART_RELAY_APP_SCREEN_MAX <= screen))
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    err = ILI9341_Fill_Screen(SMART_RELAY_APP1_CHILD_BACKGROUND_COLOR);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    err = ILI9341_Draw_Text("SMART RELAY", 82U, 42U, WHITE, 2U, SMART_RELAY_APP1_CHILD_BACKGROUND_COLOR);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    err = ILI9341_Draw_Text(gp_smart_relay_app1_screen_name[(uint32_t) screen],
                            76U,
                            92U,
                            CYAN,
                            2U,
                            SMART_RELAY_APP1_CHILD_BACKGROUND_COLOR);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    err = ILI9341_Draw_Text("BACK: PREVIOUS", 62U, 174U, WHITE, 1U, SMART_RELAY_APP1_CHILD_BACKGROUND_COLOR);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    return ILI9341_Draw_Text("FRONT: HOME", 70U, 194U, WHITE, 1U, SMART_RELAY_APP1_CHILD_BACKGROUND_COLOR);
}

/*******************************************************************************************************************//**
 * @brief Advances the simulated MM:SS clock and redraws it once per second while Home is active.
 *
 * @param[in] elapsed_ms Time elapsed since the previous call, in milliseconds.
 *
 * @retval FSP_SUCCESS Clock processed successfully.
 * @return Any other FSP error code returned by the graphics driver.
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app1_clock_process(uint32_t elapsed_ms)
{
    bool changed = false;

    g_smart_relay_app1_clock_elapsed_ms += elapsed_ms;

    while (SMART_RELAY_APP1_ONE_SECOND_MS <= g_smart_relay_app1_clock_elapsed_ms)
    {
        g_smart_relay_app1_clock_elapsed_ms -= SMART_RELAY_APP1_ONE_SECOND_MS;
        g_smart_relay_app1_clock_second = (uint8_t) (g_smart_relay_app1_clock_second + 1U);
        changed = true;

        if (60U <= g_smart_relay_app1_clock_second)
        {
            g_smart_relay_app1_clock_second = 0U;
            g_smart_relay_app1_clock_minute = (uint8_t) (g_smart_relay_app1_clock_minute + 1U);

            if (SMART_RELAY_APP1_TIMER_MINUTE_LIMIT <= g_smart_relay_app1_clock_minute)
            {
                g_smart_relay_app1_clock_minute = 0U;
            }
        }
    }

    if (changed && (SMART_RELAY_APP_SCREEN_HOME == g_smart_relay_app1_active_screen))
    {
        return smart_relay_app1_clock_draw();
    }

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Draws the current MM:SS value using one buffered RGB565 block transfer.
 *
 * @return FSP error code returned by ILI9341_Draw_RGB565_Block().
 **********************************************************************************************************************/
static fsp_err_t smart_relay_app1_clock_draw(void)
{
    uint32_t index;

    for (index = 0U;
         index < ((uint32_t) SMART_RELAY_APP1_CLOCK_AREA_WIDTH *
                  (uint32_t) SMART_RELAY_APP1_CLOCK_AREA_HEIGHT);
         index++)
    {
        g_smart_relay_app1_clock_buffer[index] = SMART_RELAY_APP1_HEADER_BACKGROUND_COLOR;
    }

    smart_relay_app1_clock_render_digit((uint8_t) (g_smart_relay_app1_clock_minute / 10U),
                                         SMART_RELAY_APP1_MINUTE_TENS_OFFSET);
    smart_relay_app1_clock_render_digit((uint8_t) (g_smart_relay_app1_clock_minute % 10U),
                                         SMART_RELAY_APP1_MINUTE_ONES_OFFSET);
    smart_relay_app1_clock_render_digit((uint8_t) (g_smart_relay_app1_clock_second / 10U),
                                         SMART_RELAY_APP1_SECOND_TENS_OFFSET);
    smart_relay_app1_clock_render_digit((uint8_t) (g_smart_relay_app1_clock_second % 10U),
                                         SMART_RELAY_APP1_SECOND_ONES_OFFSET);

    g_smart_relay_app1_clock_buffer[(2U * SMART_RELAY_APP1_CLOCK_AREA_WIDTH) +
                                     SMART_RELAY_APP1_CLOCK_COLON_X_OFFSET] = SMART_RELAY_APP1_CLOCK_TEXT_COLOR;
    g_smart_relay_app1_clock_buffer[(3U * SMART_RELAY_APP1_CLOCK_AREA_WIDTH) +
                                     SMART_RELAY_APP1_CLOCK_COLON_X_OFFSET] = SMART_RELAY_APP1_CLOCK_TEXT_COLOR;
    g_smart_relay_app1_clock_buffer[(5U * SMART_RELAY_APP1_CLOCK_AREA_WIDTH) +
                                     SMART_RELAY_APP1_CLOCK_COLON_X_OFFSET] = SMART_RELAY_APP1_CLOCK_TEXT_COLOR;
    g_smart_relay_app1_clock_buffer[(6U * SMART_RELAY_APP1_CLOCK_AREA_WIDTH) +
                                     SMART_RELAY_APP1_CLOCK_COLON_X_OFFSET] = SMART_RELAY_APP1_CLOCK_TEXT_COLOR;

    return ILI9341_Draw_RGB565_Block(SMART_RELAY_APP1_CLOCK_AREA_X,
                                     SMART_RELAY_APP1_CLOCK_AREA_Y,
                                     SMART_RELAY_APP1_CLOCK_AREA_WIDTH,
                                     SMART_RELAY_APP1_CLOCK_AREA_HEIGHT,
                                     g_smart_relay_app1_clock_buffer);
}

/*******************************************************************************************************************//**
 * @brief Renders one five-by-seven decimal digit into the off-screen clock buffer.
 *
 * @param[in] digit    Decimal digit in the range 0 through 9.
 * @param[in] x_offset Horizontal position inside the clock buffer.
 **********************************************************************************************************************/
static void smart_relay_app1_clock_render_digit(uint8_t digit, uint16_t x_offset)
{
    uint8_t row;
    uint8_t column;

    if (9U < digit)
    {
        return;
    }

    for (row = 0U; row < SMART_RELAY_APP1_CLOCK_DIGIT_HEIGHT; row++)
    {
        for (column = 0U; column < SMART_RELAY_APP1_CLOCK_DIGIT_WIDTH; column++)
        {
            uint8_t const pixel_mask = (uint8_t) (1U << (4U - column));

            if (0U != (g_smart_relay_app1_clock_digits[digit][row] & pixel_mask))
            {
                uint32_t const pixel_index = ((uint32_t) row * SMART_RELAY_APP1_CLOCK_AREA_WIDTH) +
                                             (uint32_t) x_offset + (uint32_t) column;

                g_smart_relay_app1_clock_buffer[pixel_index] = SMART_RELAY_APP1_CLOCK_TEXT_COLOR;
            }
        }
    }
}
