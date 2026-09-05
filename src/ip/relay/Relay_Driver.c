/*******************************************************************************************************************//**
 * @file Relay_Driver.c
 * @brief Implements the eight-channel active-high relay output driver for the Smart Relay board.
 *
 * R_IOPORT_Open() must already have configured Y1_Pin through Y8_Pin as GPIO outputs. Relay_Driver_Init() writes the
 * inactive LOW level to every output before the channels are made available to the application.
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/
#include "Relay_Driver.h"

/***********************************************************************************************************************
 * Private global variables
 **********************************************************************************************************************/

static bsp_io_port_pin_t const g_relay_driver_pins[RELAY_DRIVER_CHANNEL_COUNT] =
{
    RELAY_DRIVER_Y1_PIN,
    RELAY_DRIVER_Y2_PIN,
    RELAY_DRIVER_Y3_PIN,
    RELAY_DRIVER_Y4_PIN,
    RELAY_DRIVER_Y5_PIN,
    RELAY_DRIVER_Y6_PIN,
    RELAY_DRIVER_Y7_PIN,
    RELAY_DRIVER_Y8_PIN
};

static uint8_t g_relay_driver_state_mask;
static bool    g_relay_driver_initialized;

/*******************************************************************************************************************//**
 * @addtogroup Relay_Driver
 * @{
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * @brief Initializes all relay outputs to the inactive OFF state.
 *
 * @note R_IOPORT_Open() must already have been called, normally from R_BSP_WarmStart().
 *
 * @retval FSP_SUCCESS          All relay outputs were initialized successfully.
 * @retval FSP_ERR_ALREADY_OPEN The relay driver is already initialized.
 * @return Any other FSP error code returned by R_IOPORT_PinWrite().
 **********************************************************************************************************************/
fsp_err_t Relay_Driver_Init(void)
{
    fsp_err_t err;
    uint32_t  index;

    if (g_relay_driver_initialized)
    {
        return FSP_ERR_ALREADY_OPEN;
    }

    for (index = 0U; index < RELAY_DRIVER_CHANNEL_COUNT; index++)
    {
        err = R_IOPORT_PinWrite(&g_ioport_ctrl,
                                g_relay_driver_pins[index],
                                RELAY_DRIVER_INACTIVE_LEVEL);

        if (FSP_SUCCESS != err)
        {
            return err;
        }
    }

    g_relay_driver_state_mask = 0U;
    g_relay_driver_initialized = true;

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Sets one relay to ON or OFF.
 *
 * @param[in] channel Relay channel to update.
 * @param[in] enabled true to energize the relay; false to release it.
 *
 * @retval FSP_SUCCESS              The relay output was updated successfully.
 * @retval FSP_ERR_NOT_OPEN         Relay_Driver_Init() has not been called.
 * @retval FSP_ERR_INVALID_ARGUMENT channel is outside Relay 1 through Relay 8.
 * @return Any other FSP error code returned by R_IOPORT_PinWrite().
 **********************************************************************************************************************/
fsp_err_t Relay_Driver_Write(relay_driver_channel_t channel, bool enabled)
{
    fsp_err_t err;
    uint8_t   channel_mask;

    if (!g_relay_driver_initialized)
    {
        return FSP_ERR_NOT_OPEN;
    }

    if ((uint32_t) channel >= (uint32_t) RELAY_DRIVER_CHANNEL_MAX)
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    channel_mask = (uint8_t) (1U << (uint32_t) channel);

    err = R_IOPORT_PinWrite(&g_ioport_ctrl,
                            g_relay_driver_pins[(uint32_t) channel],
                            enabled ? RELAY_DRIVER_ACTIVE_LEVEL : RELAY_DRIVER_INACTIVE_LEVEL);

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    if (enabled)
    {
        g_relay_driver_state_mask = (uint8_t) (g_relay_driver_state_mask | channel_mask);
    }
    else
    {
        g_relay_driver_state_mask = (uint8_t) (g_relay_driver_state_mask & (uint8_t) ~channel_mask);
    }

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Applies an eight-bit ON/OFF mask to all relay outputs.
 *
 * Bit 0 through bit 7 represent Relay 1 through Relay 8. Outputs are updated in channel order; an IOPORT failure can
 * therefore leave earlier channels updated while later channels retain their previous states.
 *
 * @param[in] state_mask Relay state mask to apply.
 *
 * @retval FSP_SUCCESS      All relay outputs were updated successfully.
 * @retval FSP_ERR_NOT_OPEN Relay_Driver_Init() has not been called.
 * @return Any other FSP error code returned by Relay_Driver_Write().
 **********************************************************************************************************************/
fsp_err_t Relay_Driver_Write_Mask(uint8_t state_mask)
{
    fsp_err_t err;
    uint32_t  index;

    if (!g_relay_driver_initialized)
    {
        return FSP_ERR_NOT_OPEN;
    }

    for (index = 0U; index < RELAY_DRIVER_CHANNEL_COUNT; index++)
    {
        bool const enabled = (0U != (state_mask & (uint8_t) (1U << index)));

        err = Relay_Driver_Write((relay_driver_channel_t) index, enabled);

        if (FSP_SUCCESS != err)
        {
            return err;
        }
    }

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Switches all eight relays OFF.
 *
 * @return FSP error code returned by Relay_Driver_Write_Mask().
 **********************************************************************************************************************/
fsp_err_t Relay_Driver_All_Off(void)
{
    return Relay_Driver_Write_Mask(0U);
}

/*******************************************************************************************************************//**
 * @brief Switches all eight relays ON.
 *
 * @return FSP error code returned by Relay_Driver_Write_Mask().
 **********************************************************************************************************************/
fsp_err_t Relay_Driver_All_On(void)
{
    return Relay_Driver_Write_Mask(RELAY_DRIVER_ALL_CHANNELS_MASK);
}

/*******************************************************************************************************************//**
 * @brief Switches all relays OFF and closes the relay driver.
 *
 * @retval FSP_SUCCESS      The relay driver was closed successfully.
 * @retval FSP_ERR_NOT_OPEN Relay_Driver_Init() has not been called.
 * @return Any other FSP error code returned by Relay_Driver_All_Off().
 **********************************************************************************************************************/
fsp_err_t Relay_Driver_Close(void)
{
    fsp_err_t err;

    if (!g_relay_driver_initialized)
    {
        return FSP_ERR_NOT_OPEN;
    }

    err = Relay_Driver_All_Off();

    if (FSP_SUCCESS != err)
    {
        return err;
    }

    g_relay_driver_initialized = false;

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Returns the last successfully commanded state of one relay.
 *
 * @param[in] channel Relay channel to query.
 *
 * @return true when the channel is valid and commanded ON; otherwise false.
 **********************************************************************************************************************/
bool Relay_Driver_Get_State(relay_driver_channel_t channel)
{
    if ((uint32_t) channel >= (uint32_t) RELAY_DRIVER_CHANNEL_MAX)
    {
        return false;
    }

    return (0U != (g_relay_driver_state_mask & (uint8_t) (1U << (uint32_t) channel)));
}

/*******************************************************************************************************************//**
 * @brief Returns the last successfully commanded state of all eight relays.
 *
 * @return Bit 0 through bit 7 represent Relay 1 through Relay 8; one means ON.
 **********************************************************************************************************************/
uint8_t Relay_Driver_Get_State_Mask(void)
{
    return g_relay_driver_state_mask;
}

/*******************************************************************************************************************//**
 * @} (end addtogroup Relay_Driver)
 **********************************************************************************************************************/