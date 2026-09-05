/*******************************************************************************************************************//**
 * @file BTN_ep.c
 * @brief Implements non-blocking seven-button processing for the Smart Relay UI.
 *
 * Direction buttons generate one UI action when pressed and additional actions while held through repeat events.
 * OK, BACK, and FRONT generate UI actions immediately after a debounced press. All low-level events are also returned
 * to the caller so the UI can implement pressed-state animation, long-press commands, and screen-specific behavior.
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/
#include <stddef.h>
#include "hal_data.h"
#include "BTN_ep.h"
#include "common_utils.h"


/***********************************************************************************************************************
 * Macro definitions
 **********************************************************************************************************************/

/* The seven navigation buttons are active-low and must be configured as GPIO inputs with pull-ups enabled. */
#define BUTTON_APP_ACTIVE_LEVEL    BSP_IO_LEVEL_LOW

/***********************************************************************************************************************
 * Private function declarations
 **********************************************************************************************************************/
static void     button_app_events_store(button_id_t button_id, uint32_t events, button_app_output_t * p_output);
static uint32_t button_app_action_get(button_id_t button_id, uint32_t events);
static void     button_test_print(uint32_t event_mask, char const * p_event_name);
static fsp_err_t button_test_states_print(void);

/***********************************************************************************************************************
 * Private global variables
 **********************************************************************************************************************/

static char const * const gp_button_name[BUTTON_ID_MAX] =
{
    [BUTTON_ID_UP]    = "S1 - UP",
    [BUTTON_ID_DOWN]  = "S2 - DOWN",
    [BUTTON_ID_LEFT]  = "S3 - LEFT",
    [BUTTON_ID_RIGHT] = "S4 - RIGHT",
    [BUTTON_ID_OK]    = "S5 - OK",
    [BUTTON_ID_BACK]  = "S6 - BACK",
    [BUTTON_ID_FRONT] = "S7 - FRONT"
};

static const button_pin_cfg_t g_button_app_pin_cfg[BUTTON_ID_MAX] =
{
    [BUTTON_ID_UP]    = { .pin = BUTTON_TEST_UP_PIN,    .active_level = BUTTON_APP_ACTIVE_LEVEL },
    [BUTTON_ID_DOWN]  = { .pin = BUTTON_TEST_DOWN_PIN,  .active_level = BUTTON_APP_ACTIVE_LEVEL },
    [BUTTON_ID_LEFT]  = { .pin = BUTTON_TEST_LEFT_PIN,  .active_level = BUTTON_APP_ACTIVE_LEVEL },
    [BUTTON_ID_RIGHT] = { .pin = BUTTON_TEST_RIGHT_PIN, .active_level = BUTTON_APP_ACTIVE_LEVEL },
    [BUTTON_ID_OK]    = { .pin = BUTTON_TEST_OK_PIN,    .active_level = BUTTON_APP_ACTIVE_LEVEL },
    [BUTTON_ID_BACK]  = { .pin = BUTTON_TEST_BACK_PIN,  .active_level = BUTTON_APP_ACTIVE_LEVEL },
    [BUTTON_ID_FRONT] = { .pin = BUTTON_TEST_FRONT_PIN, .active_level = BUTTON_APP_ACTIVE_LEVEL }
};

static const button_cfg_t g_button_app_cfg =
{
    .p_button_pins        = g_button_app_pin_cfg,
    .button_count         = BUTTON_ID_MAX,
    .debounce_time_ms     = BUTTON_APP_DEBOUNCE_TIME_MS,
    .long_press_time_ms   = BUTTON_APP_LONG_PRESS_TIME_MS,
    .repeat_start_time_ms = BUTTON_APP_REPEAT_START_TIME_MS,
    .repeat_period_ms     = BUTTON_APP_REPEAT_PERIOD_MS
};

/*******************************************************************************************************************//**
 * @addtogroup Button_Application
 * @{
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Functions
 **********************************************************************************************************************/

void app_main_btn(void)
{
    fsp_err_t err;
    button_app_output_t button_output;

    err = Button_App_Init();

    if (FSP_SUCCESS != err)
    {
        APP_PRINT("[BUTTON] Init failed: 0x%08X\r\n",
                  (unsigned int) err);
        return;
    }

    APP_PRINT("\r\n[BUTTON] Seven-button test ready\r\n");

    while (true)
    {
        err = Button_App_Process(BUTTON_APP_PROCESS_PERIOD_MS,
                                 &button_output);

        if (FSP_SUCCESS != err)
        {
            APP_PRINT("[BUTTON] Process failed: 0x%08X\r\n",
                      (unsigned int) err);
            return;
        }

        button_test_print(button_output.pressed,
                          "ON");

        button_test_print(button_output.released,
                          "OFF");

        button_test_print(button_output.clicked,
                          "CLICKED");

        button_test_print(button_output.long_pressed,
                          "LONG_PRESSED");

        button_test_print(button_output.repeated,
                          "REPEAT");

        /* Print the debounced state of all seven buttons after any press or release transition. */
        if (0U != (button_output.pressed | button_output.released))
        {
            err = button_test_states_print();

            if (FSP_SUCCESS != err)
            {
                APP_PRINT("[BUTTON] State read failed: 0x%08X\r\n",
                          (unsigned int) err);
                return;
            }
        }

        R_BSP_SoftwareDelay(BUTTON_APP_PROCESS_PERIOD_MS,
                            BSP_DELAY_UNITS_MILLISECONDS);
    }
}

/*******************************************************************************************************************//**
 * @brief Initializes the seven-button application module.
 *
 * @note R_IOPORT_Open() must already have been called by R_BSP_WarmStart().
 *
 * @retval FSP_SUCCESS          Button application initialized successfully.
 * @retval FSP_ERR_ALREADY_OPEN Button driver is already initialized.
 * @return Any other FSP error code returned by Button_Open().
 **********************************************************************************************************************/
fsp_err_t Button_App_Init(void)
{
    return Button_Open(&g_button_app_cfg);
}

/*******************************************************************************************************************//**
 * @brief Polls all seven buttons and returns button events and UI actions without blocking.
 *
 * Call this function periodically using the actual elapsed time since the previous call. A 10 ms period is recommended.
 * Direction buttons generate actions on BUTTON_EVENT_PRESSED and BUTTON_EVENT_REPEAT. OK, BACK, and FRONT generate
 * actions on BUTTON_EVENT_PRESSED so screen transitions do not wait for the button to be released.
 *
 * @param[in]  elapsed_ms Time elapsed since the previous call, in milliseconds.
 * @param[out] p_output   Returned button events and UI action bit mask.
 *
 * @retval FSP_SUCCESS              Button information returned successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT p_output is NULL or elapsed_ms is zero.
 * @return Any other FSP error code returned by Button_Process() or Button_EventsGet().
 **********************************************************************************************************************/
fsp_err_t Button_App_Process(uint32_t elapsed_ms, button_app_output_t * p_output)
{
    fsp_err_t err;
    uint32_t  index;
    uint32_t  events;

    if ((NULL == p_output) || (0U == elapsed_ms))
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    *p_output = (button_app_output_t) {0};

    err = Button_Process(elapsed_ms);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    for (index = 0U; index < (uint32_t) BUTTON_ID_MAX; index++)
    {
        err = Button_EventsGet((button_id_t) index, &events);

        if (FSP_SUCCESS != err)
        {
            return err;
        }

        button_app_events_store((button_id_t) index, events, p_output);
        p_output->actions |= button_app_action_get((button_id_t) index, events);
    }

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Closes the button application module and clears the driver runtime state.
 *
 * @retval FSP_SUCCESS      Button application closed successfully.
 * @retval FSP_ERR_NOT_OPEN Button driver has not been initialized.
 **********************************************************************************************************************/
fsp_err_t Button_App_Close(void)
{
    return Button_Close();
}

/*******************************************************************************************************************//**
 * @brief Stores the low-level events generated by one button in the application output masks.
 *
 * @param[in]     button_id Button that generated the events.
 * @param[in]     events    Bit mask containing BUTTON_EVENT_* values.
 * @param[in,out] p_output  Application output updated by this function.
 **********************************************************************************************************************/
static void button_app_events_store(button_id_t button_id, uint32_t events, button_app_output_t * p_output)
{
    uint32_t const button_mask = BUTTON_APP_BUTTON_MASK(button_id);

    if (0U != (events & (uint32_t) BUTTON_EVENT_PRESSED))
    {
        p_output->pressed |= button_mask;
    }

    if (0U != (events & (uint32_t) BUTTON_EVENT_RELEASED))
    {
        p_output->released |= button_mask;
    }

    if (0U != (events & (uint32_t) BUTTON_EVENT_CLICKED))
    {
        p_output->clicked |= button_mask;
    }

    if (0U != (events & (uint32_t) BUTTON_EVENT_LONG_PRESSED))
    {
        p_output->long_pressed |= button_mask;
    }

    if (0U != (events & (uint32_t) BUTTON_EVENT_REPEAT))
    {
        p_output->repeated |= button_mask;
    }
}

/*******************************************************************************************************************//**
 * @brief Converts low-level button events into a semantic Smart Relay UI action.
 *
 * @param[in] button_id Button that generated the events.
 * @param[in] events    Bit mask containing BUTTON_EVENT_* values.
 *
 * @return Bit mask containing one button_app_action_t value, or BUTTON_APP_ACTION_NONE when no UI action is required.
 **********************************************************************************************************************/
static uint32_t button_app_action_get(button_id_t button_id, uint32_t events)
{
    uint32_t action = (uint32_t) BUTTON_APP_ACTION_NONE;
    uint32_t const direction_events = (uint32_t) BUTTON_EVENT_PRESSED | (uint32_t) BUTTON_EVENT_REPEAT;

    if (0U != (events & direction_events))
    {
        switch (button_id)
        {
            case BUTTON_ID_UP:
                action = (uint32_t) BUTTON_APP_ACTION_UP;
                break;

            case BUTTON_ID_DOWN:
                action = (uint32_t) BUTTON_APP_ACTION_DOWN;
                break;

            case BUTTON_ID_LEFT:
                action = (uint32_t) BUTTON_APP_ACTION_LEFT;
                break;

            case BUTTON_ID_RIGHT:
                action = (uint32_t) BUTTON_APP_ACTION_RIGHT;
                break;

            default:
                break;
        }
    }

    if (0U != (events & (uint32_t) BUTTON_EVENT_PRESSED))
    {
        switch (button_id)
        {
            case BUTTON_ID_OK:
                action = (uint32_t) BUTTON_APP_ACTION_SELECT;
                break;

            case BUTTON_ID_BACK:
                action = (uint32_t) BUTTON_APP_ACTION_BACK;
                break;

            case BUTTON_ID_FRONT:
                action = (uint32_t) BUTTON_APP_ACTION_FRONT;
                break;

            default:
                break;
        }
    }

    return action;
}


static void button_test_print(uint32_t event_mask,
                              char const * p_event_name)
{
    uint32_t index;

    for (index = 0U; index < (uint32_t) BUTTON_ID_MAX; index++)
    {
        if (0U != (event_mask &
                   BUTTON_APP_BUTTON_MASK(index)))
        {
            APP_PRINT("[BUTTON] %-10s : %s\r\n",
                      gp_button_name[index],
                      p_event_name);
        }
    }
}

/*******************************************************************************************************************//**
 * @brief Reads and prints the current debounced state of all seven buttons.
 *
 * @retval FSP_SUCCESS All button states were read successfully.
 * @return Any other FSP error code returned by Button_IsPressed().
 **********************************************************************************************************************/
static fsp_err_t button_test_states_print(void)
{
    fsp_err_t err;
    uint32_t  index;
    bool      pressed[BUTTON_ID_MAX];

    for (index = 0U; index < (uint32_t) BUTTON_ID_MAX; index++)
    {
        err = Button_IsPressed((button_id_t) index, &pressed[index]);

        if (FSP_SUCCESS != err)
        {
            return err;
        }
    }

    APP_PRINT("[STATE] S1=%s S2=%s S3=%s S4=%s S5=%s S6=%s S7=%s\r\n",
              pressed[BUTTON_ID_UP]    ? "ON" : "OFF",
              pressed[BUTTON_ID_DOWN]  ? "ON" : "OFF",
              pressed[BUTTON_ID_LEFT]  ? "ON" : "OFF",
              pressed[BUTTON_ID_RIGHT] ? "ON" : "OFF",
              pressed[BUTTON_ID_OK]    ? "ON" : "OFF",
              pressed[BUTTON_ID_BACK]  ? "ON" : "OFF",
              pressed[BUTTON_ID_FRONT] ? "ON" : "OFF");

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @} (end addtogroup Button_Application)
 **********************************************************************************************************************/
