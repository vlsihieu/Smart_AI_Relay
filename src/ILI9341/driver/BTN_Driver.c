/*******************************************************************************************************************//**
 * @file Button_Driver.c
 * @brief Implements push-button handling using the Renesas FSP IOPORT interface.
 *
 * This file provides non-blocking GPIO polling, software debouncing, press/release detection, click detection,
 * long-press detection, and key-repeat handling for application push buttons on a Renesas RA microcontroller.
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/
#include <limits.h>
#include <stddef.h>
#include "BTN_Driver.h"
#include "hal_data.h"

/***********************************************************************************************************************
 * Macro definitions
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Typedef definitions
 **********************************************************************************************************************/

/** Internal runtime state for one button. */
typedef struct st_button_runtime
{
    bool     raw_pressed;
    bool     stable_pressed;
    bool     long_press_reported;
    uint32_t debounce_elapsed_ms;
    uint32_t pressed_elapsed_ms;
    uint32_t repeat_elapsed_ms;
    uint32_t pending_events;
} button_runtime_t;

/***********************************************************************************************************************
 * Private function declarations
 **********************************************************************************************************************/
static fsp_err_t button_read_pressed(button_id_t button_id, bool * p_pressed);
static bool      button_id_is_valid(button_id_t button_id);
static uint32_t  button_saturating_add(uint32_t value, uint32_t increment);
static void      button_event_set(button_runtime_t * p_runtime, button_event_t event);

/***********************************************************************************************************************
 * Private global variables
 **********************************************************************************************************************/
static button_cfg_t const * gp_button_cfg = NULL;
static button_runtime_t     g_button_runtime[BUTTON_ID_MAX];
static bool                 g_button_opened = false;

/*******************************************************************************************************************//**
 * @addtogroup Button_Driver
 * @{
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Functions
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * @brief Initializes the button driver and captures the initial GPIO states.
 *
 * @note The IOPORT instance and button pins must already be configured by the FSP-generated BSP configuration.
 *       For a typical active-low button, configure the GPIO as input with pull-up enabled.
 *
 * @param[in] p_cfg Pointer to the button driver configuration.
 *
 * @retval FSP_SUCCESS              Button driver initialized successfully.
 * @retval FSP_ERR_ALREADY_OPEN     Button driver is already initialized.
 * @retval FSP_ERR_INVALID_ARGUMENT Configuration is NULL, incomplete, or contains an invalid button count.
 * @return Any other FSP error code returned by R_IOPORT_PinRead().
 **********************************************************************************************************************/
fsp_err_t Button_Open(button_cfg_t const * p_cfg)
{
    fsp_err_t err;
    uint32_t  index;
    bool      pressed;

    if (g_button_opened)
    {
        return FSP_ERR_ALREADY_OPEN;
    }

    if ((NULL == p_cfg) ||
        (NULL == p_cfg->p_button_pins) ||
        (BUTTON_ID_MAX != p_cfg->button_count) ||
        (0U == p_cfg->debounce_time_ms))
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    gp_button_cfg = p_cfg;

    for (index = 0U; index < BUTTON_ID_MAX; index++)
    {
        err = button_read_pressed((button_id_t) index, &pressed);

        if (FSP_SUCCESS != err)
        {
            gp_button_cfg = NULL;
            return err;
        }

        g_button_runtime[index].raw_pressed          = pressed;
        g_button_runtime[index].stable_pressed       = pressed;
        g_button_runtime[index].long_press_reported  = false;
        g_button_runtime[index].debounce_elapsed_ms  = 0U;
        g_button_runtime[index].pressed_elapsed_ms   = 0U;
        g_button_runtime[index].repeat_elapsed_ms    = 0U;
        g_button_runtime[index].pending_events       = BUTTON_EVENT_NONE;
    }

    g_button_opened = true;

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Stops the button driver and clears all internal runtime state.
 *
 * @retval FSP_SUCCESS          Button driver closed successfully.
 * @retval FSP_ERR_NOT_OPEN     Button driver has not been initialized.
 **********************************************************************************************************************/
fsp_err_t Button_Close(void)
{
    uint32_t index;

    if (!g_button_opened)
    {
        return FSP_ERR_NOT_OPEN;
    }

    for (index = 0U; index < BUTTON_ID_MAX; index++)
    {
        g_button_runtime[index].raw_pressed          = false;
        g_button_runtime[index].stable_pressed       = false;
        g_button_runtime[index].long_press_reported  = false;
        g_button_runtime[index].debounce_elapsed_ms  = 0U;
        g_button_runtime[index].pressed_elapsed_ms   = 0U;
        g_button_runtime[index].repeat_elapsed_ms    = 0U;
        g_button_runtime[index].pending_events       = BUTTON_EVENT_NONE;
    }

    gp_button_cfg  = NULL;
    g_button_opened = false;

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Polls all button GPIO pins and updates debounce and event state machines.
 *
 * Call this API periodically from the main loop or a periodic task. The elapsed time since the previous call must be
 * passed in milliseconds. A typical value is 5 ms or 10 ms.
 *
 * @param[in] elapsed_ms Time elapsed since the previous Button_Process() call, in milliseconds.
 *
 * @retval FSP_SUCCESS              All button states updated successfully.
 * @retval FSP_ERR_NOT_OPEN         Button driver has not been initialized.
 * @retval FSP_ERR_INVALID_ARGUMENT elapsed_ms is zero.
 * @return Any other FSP error code returned by R_IOPORT_PinRead().
 **********************************************************************************************************************/
fsp_err_t Button_Process(uint32_t elapsed_ms)
{
    fsp_err_t          err;
    uint32_t           index;
    bool               pressed;
    button_runtime_t * p_runtime;

    if (!g_button_opened)
    {
        return FSP_ERR_NOT_OPEN;
    }

    if (0U == elapsed_ms)
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    for (index = 0U; index < BUTTON_ID_MAX; index++)
    {
        p_runtime = &g_button_runtime[index];

        err = button_read_pressed((button_id_t) index, &pressed);

        if (FSP_SUCCESS != err)
        {
            return err;
        }

        /* Restart the debounce timer whenever the raw GPIO state changes. */
        if (pressed != p_runtime->raw_pressed)
        {
            p_runtime->raw_pressed         = pressed;
            p_runtime->debounce_elapsed_ms = 0U;
        }
        else if (pressed != p_runtime->stable_pressed)
        {
            p_runtime->debounce_elapsed_ms = button_saturating_add(p_runtime->debounce_elapsed_ms, elapsed_ms);

            /* Accept the new state only after it remains unchanged for the configured debounce time. */
            if (p_runtime->debounce_elapsed_ms >= gp_button_cfg->debounce_time_ms)
            {
                p_runtime->stable_pressed      = pressed;
                p_runtime->debounce_elapsed_ms = 0U;

                if (pressed)
                {
                    p_runtime->pressed_elapsed_ms  = 0U;
                    p_runtime->repeat_elapsed_ms   = 0U;
                    p_runtime->long_press_reported = false;
                    button_event_set(p_runtime, BUTTON_EVENT_PRESSED);
                }
                else
                {
                    button_event_set(p_runtime, BUTTON_EVENT_RELEASED);

                    /* A normal click is generated only when the press was released before a long-press event. */
                    if (!p_runtime->long_press_reported)
                    {
                        button_event_set(p_runtime, BUTTON_EVENT_CLICKED);
                    }

                    p_runtime->pressed_elapsed_ms  = 0U;
                    p_runtime->repeat_elapsed_ms   = 0U;
                    p_runtime->long_press_reported = false;
                }
            }
        }
        else
        {
            p_runtime->debounce_elapsed_ms = 0U;
        }

        if (p_runtime->stable_pressed)
        {
            p_runtime->pressed_elapsed_ms = button_saturating_add(p_runtime->pressed_elapsed_ms, elapsed_ms);

            /* Generate one long-press event per physical press. A value of zero disables long-press detection. */
            if ((!p_runtime->long_press_reported) &&
                (0U != gp_button_cfg->long_press_time_ms) &&
                (p_runtime->pressed_elapsed_ms >= gp_button_cfg->long_press_time_ms))
            {
                p_runtime->long_press_reported = true;
                button_event_set(p_runtime, BUTTON_EVENT_LONG_PRESSED);
            }

            /* Generate repeat events after the configured start delay. Zero disables key repeat. */
            if ((0U != gp_button_cfg->repeat_start_time_ms) &&
                (0U != gp_button_cfg->repeat_period_ms) &&
                (p_runtime->pressed_elapsed_ms >= gp_button_cfg->repeat_start_time_ms))
            {
                p_runtime->repeat_elapsed_ms = button_saturating_add(p_runtime->repeat_elapsed_ms, elapsed_ms);

                if (p_runtime->repeat_elapsed_ms >= gp_button_cfg->repeat_period_ms)
                {
                    p_runtime->repeat_elapsed_ms = 0U;
                    button_event_set(p_runtime, BUTTON_EVENT_REPEAT);
                }
            }
        }
    }

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Returns the current debounced state of one button.
 *
 * @param[in]  button_id Button identifier.
 * @param[out] p_pressed Pointer to the returned state. true means pressed; false means released.
 *
 * @retval FSP_SUCCESS              Button state returned successfully.
 * @retval FSP_ERR_NOT_OPEN         Button driver has not been initialized.
 * @retval FSP_ERR_INVALID_ARGUMENT Button ID or output pointer is invalid.
 **********************************************************************************************************************/
fsp_err_t Button_IsPressed(button_id_t button_id, bool * p_pressed)
{
    if (!g_button_opened)
    {
        return FSP_ERR_NOT_OPEN;
    }

    if ((!button_id_is_valid(button_id)) || (NULL == p_pressed))
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    *p_pressed = g_button_runtime[(uint32_t) button_id].stable_pressed;

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Tests and consumes one pending button event.
 *
 * @param[in]  button_id  Button identifier.
 * @param[in]  event      Event to test. Pass one BUTTON_EVENT_* value other than BUTTON_EVENT_NONE.
 * @param[out] p_detected true if the event was pending; otherwise false.
 *
 * @retval FSP_SUCCESS              Event state returned successfully.
 * @retval FSP_ERR_NOT_OPEN         Button driver has not been initialized.
 * @retval FSP_ERR_INVALID_ARGUMENT Button ID, event, or output pointer is invalid.
 **********************************************************************************************************************/
fsp_err_t Button_EventGet(button_id_t button_id, button_event_t event, bool * p_detected)
{
    uint32_t event_mask;
    uint32_t * p_pending_events;

    if (!g_button_opened)
    {
        return FSP_ERR_NOT_OPEN;
    }

    event_mask = (uint32_t) event;

    if ((!button_id_is_valid(button_id)) ||
        (NULL == p_detected) ||
        (BUTTON_EVENT_NONE == event) ||
        (0U != (event_mask & (event_mask - 1U))))
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    p_pending_events = &g_button_runtime[(uint32_t) button_id].pending_events;
    *p_detected = (0U != (*p_pending_events & event_mask));

    if (*p_detected)
    {
        *p_pending_events &= ~event_mask;
    }

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Returns and clears all pending events for one button.
 *
 * @param[in]  button_id Button identifier.
 * @param[out] p_events  Bit mask containing BUTTON_EVENT_* values.
 *
 * @retval FSP_SUCCESS              Pending events returned successfully.
 * @retval FSP_ERR_NOT_OPEN         Button driver has not been initialized.
 * @retval FSP_ERR_INVALID_ARGUMENT Button ID or output pointer is invalid.
 **********************************************************************************************************************/
fsp_err_t Button_EventsGet(button_id_t button_id, uint32_t * p_events)
{
    if (!g_button_opened)
    {
        return FSP_ERR_NOT_OPEN;
    }

    if ((!button_id_is_valid(button_id)) || (NULL == p_events))
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    *p_events = g_button_runtime[(uint32_t) button_id].pending_events;
    g_button_runtime[(uint32_t) button_id].pending_events = BUTTON_EVENT_NONE;

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Clears all pending events for one button without returning them.
 *
 * @param[in] button_id Button identifier.
 *
 * @retval FSP_SUCCESS              Pending events cleared successfully.
 * @retval FSP_ERR_NOT_OPEN         Button driver has not been initialized.
 * @retval FSP_ERR_INVALID_ARGUMENT Button ID is invalid.
 **********************************************************************************************************************/
fsp_err_t Button_EventsClear(button_id_t button_id)
{
    if (!g_button_opened)
    {
        return FSP_ERR_NOT_OPEN;
    }

    if (!button_id_is_valid(button_id))
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    g_button_runtime[(uint32_t) button_id].pending_events = BUTTON_EVENT_NONE;

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Reads one GPIO pin and converts its electrical level to a logical pressed state.
 *
 * @param[in]  button_id Button identifier.
 * @param[out] p_pressed Returned logical button state.
 *
 * @retval FSP_SUCCESS              GPIO read completed successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT Button ID or output pointer is invalid.
 * @return Any other FSP error code returned by R_IOPORT_PinRead().
 **********************************************************************************************************************/
static fsp_err_t button_read_pressed(button_id_t button_id, bool * p_pressed)
{
    fsp_err_t      err;
    bsp_io_level_t pin_level;

    if ((!button_id_is_valid(button_id)) || (NULL == p_pressed) || (NULL == gp_button_cfg))
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    err = R_IOPORT_PinRead(&g_ioport_ctrl,
                           gp_button_cfg->p_button_pins[(uint32_t) button_id].pin,
                           &pin_level);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    *p_pressed = (pin_level == gp_button_cfg->p_button_pins[(uint32_t) button_id].active_level);

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Checks whether a button ID is supported by the driver.
 *
 * @param[in] button_id Button identifier.
 *
 * @retval true  Button ID is valid.
 * @retval false Button ID is invalid.
 **********************************************************************************************************************/
static bool button_id_is_valid(button_id_t button_id)
{
    return (((uint32_t) button_id) < (uint32_t) BUTTON_ID_MAX);
}

/*******************************************************************************************************************//**
 * @brief Adds two millisecond values without allowing a uint32_t overflow.
 *
 * @param[in] value     Current value.
 * @param[in] increment Value to add.
 *
 * @return Saturated sum of value and increment.
 **********************************************************************************************************************/
static uint32_t button_saturating_add(uint32_t value, uint32_t increment)
{
    if (increment > (UINT32_MAX - value))
    {
        return UINT32_MAX;
    }

    return value + increment;
}

/*******************************************************************************************************************//**
 * @brief Adds one event to a button's pending-event bit mask.
 *
 * @param[in,out] p_runtime Pointer to button runtime state.
 * @param[in]     event     Event to add.
 **********************************************************************************************************************/
static void button_event_set(button_runtime_t * p_runtime, button_event_t event)
{
    p_runtime->pending_events |= (uint32_t) event;
}

/*******************************************************************************************************************//**
 * @} (end addtogroup Button_Driver)
 **********************************************************************************************************************/
