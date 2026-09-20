/*******************************************************************************************************************//**
 * @file Ui_QR_ep.c
 * @brief Implements the QR-code display UI screen.
 *
 * The full-screen 320x240 RGB565 bitmap (qrcode_github_com_rgb565) is transferred to the ILI9341 display when the
 * screen is opened. No tiles or cursor overlays are drawn. The only supported actions are BACK and HOME; both mark the
 * screen inactive and return the appropriate navigation request to the caller.
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/
#include <stddef.h>
#include "Ui_QR_ep.h"
#include "ILI9341_GFX.h"
#include "qrcode_github_com_rgb565.h"

/***********************************************************************************************************************
 * Private global variables
 **********************************************************************************************************************/

static bool g_ui_qr_initialized;
static bool g_ui_qr_active;

/*******************************************************************************************************************//**
 * @addtogroup UI_QR
 * @{
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * @brief Standalone entry point – initializes the driver, opens the QR screen, then loops forever.
 *
 * Intended for use when the QR screen is the sole application screen.
 **********************************************************************************************************************/
void app_main_qr(void)
{
    fsp_err_t err;

    err = ILI9341_Init();
    if (FSP_SUCCESS != err)
    {
        return;
    }

    err = UI_QR_Init();
    if (FSP_SUCCESS != err)
    {
        return;
    }

    err = UI_QR_Open();
    if (FSP_SUCCESS != err)
    {
        return;
    }

    while (1)
    {
        /* QR screen remains displayed. */
    }
}

/*******************************************************************************************************************//**
 * @brief Initializes the QR UI state without drawing the screen.
 *
 * @retval FSP_SUCCESS          The QR UI state was initialized successfully.
 * @retval FSP_ERR_ALREADY_OPEN The module is already initialized.
 **********************************************************************************************************************/
fsp_err_t UI_QR_Init(void)
{
    if (g_ui_qr_initialized)
    {
        return FSP_ERR_ALREADY_OPEN;
    }

    g_ui_qr_active      = false;
    g_ui_qr_initialized = true;

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Opens the QR-code screen and transfers the full bitmap to the display.
 *
 * @retval FSP_SUCCESS      The bitmap was drawn successfully.
 * @retval FSP_ERR_NOT_OPEN UI_QR_Init() has not been called.
 * @return Any other FSP error code returned by the ILI9341 driver.
 **********************************************************************************************************************/
fsp_err_t UI_QR_Open(void)
{
    fsp_err_t err;

    if (!g_ui_qr_initialized)
    {
        return FSP_ERR_NOT_OPEN;
    }

    g_ui_qr_active = true;

    err = ILI9341_Draw_Image((char const *) qrcode_github_com_rgb565, SCREEN_HORIZONTAL_1);

    if (FSP_SUCCESS != err)
    {
        g_ui_qr_active = false;
    }

    return err;
}

/*******************************************************************************************************************//**
 * @brief Processes one QR-screen action.
 *
 * Action priority is HOME then BACK. Any other action bits are silently ignored.
 *
 * @param[in]  actions      Bit mask containing UI_QR_ACTION_* values.
 * @param[out] p_navigation Navigation request returned to the application.
 *
 * @retval FSP_SUCCESS              The action was processed successfully.
 * @retval FSP_ERR_NOT_OPEN         The module is not initialized or the QR screen is inactive.
 * @retval FSP_ERR_INVALID_ARGUMENT p_navigation is NULL.
 **********************************************************************************************************************/
fsp_err_t UI_QR_Process(uint32_t actions, ui_qr_navigation_t * p_navigation)
{
    if (NULL == p_navigation)
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    *p_navigation = UI_QR_NAVIGATION_NONE;

    if ((!g_ui_qr_initialized) || (!g_ui_qr_active))
    {
        return FSP_ERR_NOT_OPEN;
    }

    if (0U != (actions & (uint32_t) UI_QR_ACTION_HOME))
    {
        g_ui_qr_active = false;
        *p_navigation  = UI_QR_NAVIGATION_HOME;
        return FSP_SUCCESS;
    }

    if (0U != (actions & (uint32_t) UI_QR_ACTION_BACK))
    {
        g_ui_qr_active = false;
        *p_navigation  = UI_QR_NAVIGATION_BACK;
        return FSP_SUCCESS;
    }

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Marks the QR screen inactive without affecting the display contents.
 *
 * @retval FSP_SUCCESS      The QR screen was closed successfully.
 * @retval FSP_ERR_NOT_OPEN UI_QR_Init() has not been called.
 **********************************************************************************************************************/
fsp_err_t UI_QR_Close(void)
{
    if (!g_ui_qr_initialized)
    {
        return FSP_ERR_NOT_OPEN;
    }

    g_ui_qr_active = false;

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Reports whether the QR screen currently owns the display.
 *
 * @return true when active; otherwise false.
 **********************************************************************************************************************/
bool UI_QR_Is_Active(void)
{
    return g_ui_qr_active;
}

/*******************************************************************************************************************//**
 * @} (end addtogroup UI_QR)
 **********************************************************************************************************************/