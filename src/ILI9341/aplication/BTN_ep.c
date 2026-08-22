/*******************************************************************************************************************//**
 * @file Button_Example.c
 * @brief Example showing how to use Button_Driver with five UI navigation buttons.
 **********************************************************************************************************************/

#if 0
#include "hal_data.h"
#include "BTN_Driver.h"

/*
 * Replace these five pin macros with the pin names generated/configured in your FSP project.
 * Example only:
 *   #define BTN_UP_PIN     BSP_IO_PORT_00_PIN_00
 */
#define BTN_UP_PIN      BSP_IO_PORT_00_PIN_00
#define BTN_DOWN_PIN    BSP_IO_PORT_00_PIN_01
#define BTN_OK_PIN      BSP_IO_PORT_00_PIN_02
#define BTN_BACK_PIN    BSP_IO_PORT_00_PIN_03
#define BTN_HOME_PIN    BSP_IO_PORT_00_PIN_04

static const button_pin_cfg_t g_button_pin_cfg[BUTTON_ID_MAX] =
{
    [BUTTON_ID_UP]   = { .pin = BTN_UP_PIN,   .active_level = BSP_IO_LEVEL_LOW },
    [BUTTON_ID_DOWN] = { .pin = BTN_DOWN_PIN, .active_level = BSP_IO_LEVEL_LOW },
    [BUTTON_ID_OK]   = { .pin = BTN_OK_PIN,   .active_level = BSP_IO_LEVEL_LOW },
    [BUTTON_ID_BACK] = { .pin = BTN_BACK_PIN, .active_level = BSP_IO_LEVEL_LOW },
    [BUTTON_ID_HOME] = { .pin = BTN_HOME_PIN, .active_level = BSP_IO_LEVEL_LOW }
};

static const button_cfg_t g_button_cfg =
{
    .p_button_pins        = g_button_pin_cfg,
    .button_count         = BUTTON_ID_MAX,
    .debounce_time_ms     = 30U,
    .long_press_time_ms   = 1000U,
    .repeat_start_time_ms = 500U,
    .repeat_period_ms     = 150U
};

void button_example_init(void)
{
    fsp_err_t err;

    err = Button_Open(&g_button_cfg);

    if (FSP_SUCCESS != err)
    {
        return;
    }
}

void button_example_process(void)
{
    bool event_detected;

    /* Call every 10 ms. */
    if (FSP_SUCCESS != Button_Process(10U))
    {
        return;
    }

    /* Move cursor up. */
    (void) Button_EventGet(BUTTON_ID_UP, BUTTON_EVENT_CLICKED, &event_detected);
    if (event_detected)
    {
        /* SmartRelay_UI_MoveCursorUp(); */
    }

    /* Move cursor down. */
    (void) Button_EventGet(BUTTON_ID_DOWN, BUTTON_EVENT_CLICKED, &event_detected);
    if (event_detected)
    {
        /* SmartRelay_UI_MoveCursorDown(); */
    }

    /* Select current item. */
    (void) Button_EventGet(BUTTON_ID_OK, BUTTON_EVENT_CLICKED, &event_detected);
    if (event_detected)
    {
        /* SmartRelay_UI_Select(); */
    }

    /* Go back one screen. */
    (void) Button_EventGet(BUTTON_ID_BACK, BUTTON_EVENT_CLICKED, &event_detected);
    if (event_detected)
    {
        /* SmartRelay_UI_Back(); */
    }

    /* Return directly to Home. */
    (void) Button_EventGet(BUTTON_ID_HOME, BUTTON_EVENT_CLICKED, &event_detected);
    if (event_detected)
    {
        /* SmartRelay_UI_Home(); */
    }
}
#endif
