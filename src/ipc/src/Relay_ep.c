/*******************************************************************************************************************//**
 * @file Relay_ep.c
 * @brief Implements the eight-channel relay application interface used by the Smart Relay UI.
 *
 * Relay_App_Init() initializes Relay_Driver with every active-high output at its inactive LOW level before applying
 * the requested initial state mask. The application therefore works only with logical ON/OFF states and does not need
 * to know the physical GPIO polarity.
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/
#include <stddef.h>
#include "Relay_ep.h"
#include "Relay_Driver.h"

/***********************************************************************************************************************
 * Private global variables
 **********************************************************************************************************************/

static bool g_relay_app_initialized;

/*******************************************************************************************************************//**
 * @addtogroup Relay_Application
 * @{
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * @brief Initializes the relay application and applies its initial logical state mask.
 *
 * Relay_Driver_Init() first drives Y1 through Y8 LOW, which is the safe OFF level for the active-high relay inputs.
 * The requested mask is applied only after that safe initialization succeeds.
 *
 * @param[in] initial_state_mask Bit 0 through bit 7 represent Relay 1 through Relay 8; one means ON.
 *
 * @retval FSP_SUCCESS          Relay application initialized successfully.
 * @retval FSP_ERR_ALREADY_OPEN Relay application is already initialized.
 * @return Any other FSP error code returned by Relay_Driver.
 **********************************************************************************************************************/
fsp_err_t Relay_App_Init(uint8_t initial_state_mask)
{
    fsp_err_t err;

    if (g_relay_app_initialized)
    {
        return FSP_ERR_ALREADY_OPEN;
    }

    err = Relay_Driver_Init();

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    err = Relay_Driver_Write_Mask(initial_state_mask);

    if (FSP_SUCCESS != err)
    {
        (void) Relay_Driver_Close();
        return err;
    }

    g_relay_app_initialized = true;

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Sets one logical relay channel to ON or OFF.
 *
 * @param[in] channel Relay channel to update.
 * @param[in] enabled true to energize the relay; false to release it.
 *
 * @retval FSP_SUCCESS              Relay state updated successfully.
 * @retval FSP_ERR_NOT_OPEN         Relay_App_Init() has not been called.
 * @retval FSP_ERR_INVALID_ARGUMENT channel is outside Relay 1 through Relay 8.
 * @return Any other FSP error code returned by Relay_Driver_Write().
 **********************************************************************************************************************/
fsp_err_t Relay_App_Write(relay_app_channel_t channel, bool enabled)
{
    if (!g_relay_app_initialized)
    {
        return FSP_ERR_NOT_OPEN;
    }

    if ((uint32_t) channel >= (uint32_t) RELAY_APP_CHANNEL_MAX)
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    return Relay_Driver_Write((relay_driver_channel_t) channel, enabled);
}

/*******************************************************************************************************************//**
 * @brief Toggles one relay and returns the newly applied state.
 *
 * @param[in]  channel   Relay channel to toggle.
 * @param[out] p_enabled Newly applied logical state; true means ON.
 *
 * @retval FSP_SUCCESS              Relay state toggled successfully.
 * @retval FSP_ERR_NOT_OPEN         Relay_App_Init() has not been called.
 * @retval FSP_ERR_INVALID_ARGUMENT channel is invalid or p_enabled is NULL.
 * @return Any other FSP error code returned by Relay_App_Write().
 **********************************************************************************************************************/
fsp_err_t Relay_App_Toggle(relay_app_channel_t channel, bool * p_enabled)
{
    fsp_err_t err;
    bool      enabled;

    if (!g_relay_app_initialized)
    {
        return FSP_ERR_NOT_OPEN;
    }

    if ((NULL == p_enabled) || ((uint32_t) channel >= (uint32_t) RELAY_APP_CHANNEL_MAX))
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    enabled = !Relay_Driver_Get_State((relay_driver_channel_t) channel);
    err = Relay_App_Write(channel, enabled);

    if (FSP_SUCCESS == err)
    {
        *p_enabled = enabled;
    }

    return err;
}

/*******************************************************************************************************************//**
 * @brief Applies an eight-bit logical ON/OFF mask to all relay channels.
 *
 * @param[in] state_mask Bit 0 through bit 7 represent Relay 1 through Relay 8; one means ON.
 *
 * @retval FSP_SUCCESS      Relay state mask applied successfully.
 * @retval FSP_ERR_NOT_OPEN Relay_App_Init() has not been called.
 * @return Any other FSP error code returned by Relay_Driver_Write_Mask().
 **********************************************************************************************************************/
fsp_err_t Relay_App_Write_Mask(uint8_t state_mask)
{
    if (!g_relay_app_initialized)
    {
        return FSP_ERR_NOT_OPEN;
    }

    return Relay_Driver_Write_Mask(state_mask);
}

/*******************************************************************************************************************//**
 * @brief Switches all eight relays OFF.
 *
 * @return FSP error code returned by Relay_App_Write_Mask().
 **********************************************************************************************************************/
fsp_err_t Relay_App_All_Off(void)
{
    return Relay_App_Write_Mask(0U);
}

/*******************************************************************************************************************//**
 * @brief Switches all eight relays ON.
 *
 * @return FSP error code returned by Relay_App_Write_Mask().
 **********************************************************************************************************************/
fsp_err_t Relay_App_All_On(void)
{
    return Relay_App_Write_Mask(RELAY_APP_ALL_CHANNELS_MASK);
}

/*******************************************************************************************************************//**
 * @brief Switches all relays OFF and closes the relay application and driver.
 *
 * @retval FSP_SUCCESS      Relay application closed successfully.
 * @retval FSP_ERR_NOT_OPEN Relay_App_Init() has not been called.
 * @return Any other FSP error code returned by Relay_Driver_Close().
 **********************************************************************************************************************/
fsp_err_t Relay_App_Close(void)
{
    fsp_err_t err;

    if (!g_relay_app_initialized)
    {
        return FSP_ERR_NOT_OPEN;
    }

    err = Relay_Driver_Close();

    if (FSP_SUCCESS == err)
    {
        g_relay_app_initialized = false;
    }

    return err;
}

/*******************************************************************************************************************//**
 * @brief Returns the last successfully applied logical state of one relay.
 *
 * @param[in] channel Relay channel to query.
 *
 * @return true when the application is initialized and the valid channel is ON; otherwise false.
 **********************************************************************************************************************/
bool Relay_App_Get_State(relay_app_channel_t channel)
{
    if ((!g_relay_app_initialized) || ((uint32_t) channel >= (uint32_t) RELAY_APP_CHANNEL_MAX))
    {
        return false;
    }

    return Relay_Driver_Get_State((relay_driver_channel_t) channel);
}

/*******************************************************************************************************************//**
 * @brief Returns the last successfully applied state mask of all eight relays.
 *
 * @return Bit 0 through bit 7 represent Relay 1 through Relay 8; one means ON. Zero is returned before initialization.
 **********************************************************************************************************************/
uint8_t Relay_App_Get_State_Mask(void)
{
    if (!g_relay_app_initialized)
    {
        return 0U;
    }

    return Relay_Driver_Get_State_Mask();
}

/*******************************************************************************************************************//**
 * @brief Reports whether the relay application has been initialized.
 *
 * @return true after Relay_App_Init() succeeds and before Relay_App_Close() succeeds; otherwise false.
 **********************************************************************************************************************/
bool Relay_App_Is_Initialized(void)
{
    return g_relay_app_initialized;
}

/*******************************************************************************************************************//**
 * @} (end addtogroup Relay_Application)
 **********************************************************************************************************************/