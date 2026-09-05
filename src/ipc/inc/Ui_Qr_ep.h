/*******************************************************************************************************************//**
 * @file Ui_QR_ep.h
 * @brief Public interface for the QR-code display UI screen.
 *
 * The screen shows a full-screen 320x240 RGB565 QR-code bitmap (qrcode_github_com_rgb565).
 * There are no interactive tiles; the only supported actions are BACK and HOME.
 **********************************************************************************************************************/

#ifndef UI_QR_EP_H
#define UI_QR_EP_H

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/
#include <stdint.h>
#include <stdbool.h>
#include "hal_data.h"

//#include "fsp_err.h"

/***********************************************************************************************************************
 * Macro definitions
 **********************************************************************************************************************/

/** Bit masks for actions passed to UI_QR_Process(). */
#define UI_QR_ACTION_NONE   (0x00U)
#define UI_QR_ACTION_BACK   (0x01U)
#define UI_QR_ACTION_HOME   (0x02U)

/***********************************************************************************************************************
 * Typedef definitions
 **********************************************************************************************************************/

/** Navigation requests returned by UI_QR_Process(). */
typedef enum e_ui_qr_navigation
{
    UI_QR_NAVIGATION_NONE = 0,  ///< Remain on this screen.
    UI_QR_NAVIGATION_BACK,      ///< Return to the previous screen.
    UI_QR_NAVIGATION_HOME,      ///< Return to the Home screen.
} ui_qr_navigation_t;

/***********************************************************************************************************************
 * Public function prototypes
 **********************************************************************************************************************/

fsp_err_t UI_QR_Init  (void);
fsp_err_t UI_QR_Open  (void);
fsp_err_t UI_QR_Process(uint32_t actions, ui_qr_navigation_t * p_navigation);
fsp_err_t UI_QR_Close (void);
bool      UI_QR_Is_Active(void);
void app_main_qr(void);
#endif /* UI_QR_EP_H */
