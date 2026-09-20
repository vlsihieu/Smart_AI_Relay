/*******************************************************************************************************************//**
 * @file hal_entry.c
 * @brief Tests the basic drawing APIs provided by the ILI9341 LCD driver.
 **********************************************************************************************************************/
/***********************************************************************************************************************
 * Copyright (c) 2020 - 2024 Renesas Electronics Corporation and/or its affiliates
 *
 * SPDX-License-Identifier: BSD-3-Clause
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/

<<<<<<< HEAD
#include "hal_data.h"
#include "ILI9341_Driver.h"
#include "Ui_Home_ep.h"
#include "BTN_ep.h"
#include "App.h"
#include "App1.h"
#include "Ui_Relay_ep.h"
#include "Ui_QR_ep.h"
#include "wifi.h"
#include "cjm410.h"
#include "cjm410_ra6m5_port.h"
=======
#include <Appllication/inc/App.h>
#include <Appllication/inc/App1.h>
#include <Appllication/inc/BTN_ep.h>
#include <Appllication/inc/wifi.h>
#include <Appllication/inc/App.h>
#include <Appllication/inc/App1.h>
#include "hal_data.h"

#include "Ui_Relay_ep.h"
#include "Ui_QR_ep.h"
#include "cjm410.h"
#include "cjm410_ra6m5_port.h"
#include "husky.h"
>>>>>>> d33d55c (update code)

/***********************************************************************************************************************
 * Public function declarations
 **********************************************************************************************************************/
void R_BSP_WarmStart(bsp_warm_start_event_t event);

/*******************************************************************************************************************//**
 * @brief Initializes the ILI9341 LCD and tests the basic driver functions.
 *
 * @retval None
 **********************************************************************************************************************/
// void hal_entry(void)
// {
//     // app_main_wifi();
//     // app_main_relay();
//     // app_main_qr();
//     // Smart_Relay_App_Run();
//     Smart_Relay_App1_Run();
//     while(1)
//     {

//     }
// }
// void hal_entry(void)
// {
//    App_Wifi_Test();

//    __NOP();   /* breakpoint here */

//    while (1)
//    {
//        (void) Wifi_Process();

//        R_BSP_SoftwareDelay(10U,
//                            BSP_DELAY_UNITS_MILLISECONDS);
//    }
// }


// #define CJM410_TEST_RX_SIZE      (256U)
// #define CJM410_TEST_BOOT_MS      (10000U)
// #define CJM410_TEST_WAIT_MS      (5000U)

// volatile uint32_t g_test_open_err;
// volatile uint32_t g_test_callback_err;
// volatile uint32_t g_test_first_read_err;
// volatile uint32_t g_test_write_err;

// volatile uint32_t g_test_callback_count;
// volatile uint32_t g_test_rx_complete_count;
// volatile uint32_t g_test_rx_char_count;
// volatile uint32_t g_test_tx_complete_count;
// volatile uint32_t g_test_uart_error_count;
// volatile uint32_t g_test_rearm_ok_count;
// volatile uint32_t g_test_rearm_error_count;

// volatile uint32_t g_test_last_event;
// volatile uint8_t  g_test_rx_byte;
// volatile uint32_t g_test_rx_length;
// volatile uint8_t  g_test_rx_buffer[CJM410_TEST_RX_SIZE];

// volatile bool g_test_tx_done;
// volatile bool g_test_finished;

// static uart_callback_args_t g_test_callback_memory;

// /***********************************************************************************************************************
//  * RX helper
//  **********************************************************************************************************************/

// static fsp_err_t cjm410_test_arm_rx(void) trophy, moth trophy, mother không rather than trouble
// {
//     fsp_err_t err;

//     err = R_SCI_UART_Read(&g_uart_cjm410_ctrl,
//                           (uint8_t *) &g_test_rx_byte,
//                           1U);

//     if (FSP_SUCCESS == err)
//     {
//         g_test_rearm_ok_count++;
//     }
//     else
//     {
//         g_test_rearm_error_count++;
//     }

//     return err;
// }

// static void cjm410_test_store_byte(uint8_t data)
// {
//     uint32_t index = g_test_rx_length;

//     if (index < (CJM410_TEST_RX_SIZE - 1U))
//     {
//         g_test_rx_buffer[index] = data;
//         g_test_rx_length = index + 1U;
//         g_test_rx_buffer[index + 1U] = 0U;
//     }
// }

// /***********************************************************************************************************************
//  * UART callback
//  **********************************************************************************************************************/

// void cjm410_test_uart_callback(uart_callback_args_t * p_args)
// {
//     if (NULL == p_args)
//     {
//         return;
//     }

//     g_test_callback_count++;
//     g_test_last_event = (uint32_t) p_args->event;

//     switch (p_args->event)
//     {
//         case UART_EVENT_RX_COMPLETE:
//         {
//             /*
//              * Explicit R_SCI_UART_Read(..., 1) completed.
//              * g_test_rx_byte now contains the received byte.
//              */
//             g_test_rx_complete_count++;
//             cjm410_test_store_byte((uint8_t) g_test_rx_byte);

//             /*
//              * Immediately receive the next byte.
//              */
//             (void) cjm410_test_arm_rx();
//             break;
//         }

//         case UART_EVENT_RX_CHAR:
//         {
//             /*
//              * Fallback if this FSP configuration reports chars directly.
//              */
//             g_test_rx_char_count++;
//             cjm410_test_store_byte((uint8_t) p_args->data);
//             break;
//         }

//         case UART_EVENT_TX_COMPLETE:
//         {
//             g_test_tx_complete_count++;
//             g_test_tx_done = true;
//             break;
//         }

//         case UART_EVENT_ERR_PARITY:
//         case UART_EVENT_ERR_FRAMING:
//         case UART_EVENT_ERR_OVERFLOW:
//         case UART_EVENT_BREAK_DETECT:
//         {
//             g_test_uart_error_count++;
//             break;
//         }

//         default:
//             break;
//     }
// }

// /***********************************************************************************************************************
//  * hal_entry
//  **********************************************************************************************************************/

// void hal_entry(void)
// {
//     static uint8_t const command[] =
//     {
//         'A', 'T', '+', 'V', 'E', 'R', '=', '\r', '\n'
//     };

//     fsp_err_t err;
//     uint32_t i;

//     g_test_open_err          = 0U;
//     g_test_callback_err      = 0U;
//     g_test_first_read_err    = 0U;
//     g_test_write_err         = 0U;

//     g_test_callback_count    = 0U;
//     g_test_rx_complete_count = 0U;
//     g_test_rx_char_count     = 0U;
//     g_test_tx_complete_count = 0U;
//     g_test_uart_error_count  = 0U;
//     g_test_rearm_ok_count    = 0U;
//     g_test_rearm_error_count = 0U;

//     g_test_last_event        = UINT32_MAX;
//     g_test_rx_byte           = 0U;
//     g_test_rx_length         = 0U;
//     g_test_tx_done           = false;
//     g_test_finished          = false;

//     for (i = 0U; i < CJM410_TEST_RX_SIZE; i++)
//     {
//         g_test_rx_buffer[i] = 0U;
//     }

//     /*******************************************************************************************************************
//      * 1. Open generated SCI6 UART.
//      ******************************************************************************************************************/
//     err = R_SCI_UART_Open(&g_uart_cjm410_ctrl,
//                           &g_uart_cjm410_cfg);
//     g_test_open_err = (uint32_t) err;

//     if (FSP_SUCCESS != err)
//     {
//         g_test_finished = true;
//         while (1)
//         {
//             __NOP();
//         }
//     }

//     /*******************************************************************************************************************
//      * 2. Replace callback for this standalone test.
//      ******************************************************************************************************************/
//     err = R_SCI_UART_CallbackSet(&g_uart_cjm410_ctrl,
//                                  cjm410_test_uart_callback,
//                                  NULL,
//                                  &g_test_callback_memory);
//     g_test_callback_err = (uint32_t) err;

//     if (FSP_SUCCESS != err)
//     {
//         g_test_finished = true;
//         while (1)
//         {
//             __NOP();
//         }
//     }

//     /*******************************************************************************************************************
//      * 3. Wait for CJM410 boot.
//      ******************************************************************************************************************/
//     R_BSP_SoftwareDelay(CJM410_TEST_BOOT_MS,
//                         BSP_DELAY_UNITS_MILLISECONDS);

//     /*******************************************************************************************************************
//      * 4. CRITICAL: arm SCI6 RX BEFORE sending AT command.
//      ******************************************************************************************************************/
//     err = cjm410_test_arm_rx();
//     g_test_first_read_err = (uint32_t) err;

//     if (FSP_SUCCESS != err)
//     {
//         g_test_finished = true;
//         while (1)
//         {
//             __NOP();
//         }
//     }

//     /*******************************************************************************************************************
//      * 5. Send exactly: AT+VER=\r\n
//      ******************************************************************************************************************/
//     err = R_SCI_UART_Write(&g_uart_cjm410_ctrl,
//                            command,
//                            sizeof(command));
//     g_test_write_err = (uint32_t) err;

//     if (FSP_SUCCESS != err)
//     {
//         g_test_finished = true;
//         while (1)
//         {
//             __NOP();
//         }
//     }

//     /*******************************************************************************************************************
//      * 6. Give the module enough time to answer.
//      ******************************************************************************************************************/
//     R_BSP_SoftwareDelay(CJM410_TEST_WAIT_MS,
//                         BSP_DELAY_UNITS_MILLISECONDS);

//     g_test_finished = true;

//     /*
//      * BREAKPOINT HERE.
//      *
//      * Expected if RX path works:
//      *
//      * g_test_open_err          = 0
//      * g_test_callback_err      = 0
//      * g_test_first_read_err    = 0
//      * g_test_write_err         = 0
//      *
//      * g_test_tx_complete_count = 1
//      * g_test_rearm_ok_count    >= 1
//      *
//      * AND:
//      * g_test_rx_complete_count > 0
//      * OR
//      * g_test_rx_char_count     > 0
//      *
//      * g_test_rx_buffer should contain CJM410 response such as +ok=...
//      */
//     __NOP();

//     while (1)
//     {
//         __NOP();
//     }
// }

/*******************************************************************************************************************//**
 * @file hal_entry.c
 * @brief CJM410 integrated bring-up test: RA6M5 TX/RX + Wi-Fi association + IP + ping.
 *
 * Required FSP settings:
 *   SCI6
 *   Baud: 115200
 *   8 data bits, no parity, 1 stop bit
 *   RXD6 = P505
 *   TXD6 = P506
 *   Receive FIFO Trigger Level = One
 *   RXI/TXI/TEI/ERI priority = 12
 *   No DTC
 *
 * Required port setting:
 *   CJM410_RA6M5_EXPLICIT_RX_READ = 0U
 **********************************************************************************************************************/

// #include "hal_data.h"
// #include "wifi.h"

// /*
//  * App_Wifi_Test() is implemented in wifi.c.
//  * Keep this declaration here in case the current wifi.h does not expose it yet.
//  */
// extern void App_Wifi_Test(void);

// /*
//  * These globals already exist in wifi.c / cjm410_ra6m5_port.c.
//  * Add them in e2 studio Expressions after the test stops.
//  */
// extern volatile uint32_t g_cjm410_uart_write_count;
// extern volatile uint32_t g_cjm410_uart_tx_complete_count;
// extern volatile uint32_t g_cjm410_uart_rx_char_count;
// extern volatile uint32_t g_cjm410_uart_rx_complete_count;
// extern volatile uint32_t g_cjm410_uart_error_count;
// extern volatile uint32_t g_cjm410_uart_last_tx_length;
// extern volatile uint8_t  g_cjm410_uart_last_tx[];
// extern volatile uint32_t g_cjm410_uart_rx_trace_length;
// extern volatile uint8_t  g_cjm410_uart_rx_trace[];

// void hal_entry(void)
// {
//     /*
//      * wifi.c currently performs:
//      *
//      *   1. Wifi_Init()            -> CJM410 AT probe
//      *   2. Wifi_Get_Info()
//      *   3. Wifi_Scan()
//      *   4. Wifi_Connect_WPA2()
//      *   5. Wifi_Get_Network_Info() -> WLINK + IP
//      *   6. Wifi_Ping()
//      *
//      * IMPORTANT:
//      * Change the SSID/password inside App_Wifi_Test() in wifi.c
//      * before running if they are not your current AP credentials.
//      */
//     App_Wifi_Test();

//     /*
//      * BREAKPOINT HERE.
//      *
//      * UART TX proof:
//      *   g_cjm410_uart_write_count       > 0
//      *   g_cjm410_uart_tx_complete_count > 0
//      *   g_cjm410_uart_last_tx[]         contains the last AT command
//      *
//      * UART RX proof:
//      *   g_cjm410_uart_rx_char_count     > 0
//      *   g_cjm410_uart_rx_complete_count == 0  (expected in RX_CHAR mode)
//      *   g_cjm410_uart_rx_trace_length   > 0
//      *   g_cjm410_uart_rx_trace[]        contains CJM410 replies
//      *   g_cjm410_uart_error_count       == 0
//      *
//      * Wi-Fi proof (globals from wifi.c):
//      *   g_wifi_init_status
//      *   g_wifi_connect_status
//      *   g_wifi_network_status
//      *   g_wifi_status
//      *   g_wifi_ping_status
//      *
//      * Text:
//      *   g_wifi_dbg_link
//      *   g_wifi_dbg_ip
//      *   g_wifi_dbg_ping
//      */
//     __NOP();

//     while (1)
//     {
//         __NOP();
//     }
// }

/*
 * CJM410 V4 HSUART bring-up test.
 *
 * Real PCB path only:
 *   P506/TXD6 -> CJM410 pin2/WIFI_HSUART_RXD
 *   P505/RXD6 <- CJM410 pin3/WIFI_HSUART_TXD
 *
 * No SCI7. No Debug UART jumper. No OTA.
 */
// volatile wifi_status_t g_test_init;
// volatile wifi_status_t g_test_info;

// wifi_info_t g_test_wifi_info;

// void hal_entry(void)
// {
//     g_test_init = Wifi_Init();

//     if (WIFI_STATUS_OK == g_test_init)
//     {
//         g_test_info = Wifi_Get_Info(&g_test_wifi_info);
//     }

//     __NOP();    /* breakpoint */

//     while (1)
//     {
//         __NOP();
//     }
// }

// volatile uint32_t g_driver_rx_v2_stage = 0U;
// volatile wifi_status_t g_driver_rx_v2_init = WIFI_STATUS_NOT_INITIALIZED;
// volatile wifi_status_t g_driver_rx_v2_info = WIFI_STATUS_NOT_INITIALIZED;

// wifi_info_t g_driver_rx_v2_wifi_info;

// void hal_entry(void)
// {
//     g_driver_rx_v2_stage = 1U;

//     g_driver_rx_v2_init = Wifi_Init();

//     g_driver_rx_v2_stage = 2U;     /* Wifi_Init() returned. */

//     if (WIFI_STATUS_OK == g_driver_rx_v2_init)
//     {
//         g_driver_rx_v2_stage = 3U;

//         g_driver_rx_v2_info = Wifi_Get_Info(&g_driver_rx_v2_wifi_info);

//         g_driver_rx_v2_stage = 4U;
//     }

//     __NOP();                       /* BREAKPOINT HERE */

//     while (1)
//     {
//         __NOP();
//     }
// }
static huskylens_ra6m5_t g_husky;

/* Theo dõi các biến này trong Debug Expressions. */
volatile fsp_err_t g_husky_init_err;
volatile huskylens_status_t g_husky_status;
volatile uint32_t g_husky_detected;
volatile int16_t g_husky_id;
volatile int16_t g_husky_x;
volatile int16_t g_husky_y;
volatile int16_t g_husky_width;
volatile int16_t g_husky_height;

void hal_entry(void)
{
<<<<<<< HEAD
    // app_main_wifi();
    // app_main_relay();
    // app_main_qr();
    // Smart_Relay_App_Run();
    Smart_Relay_App1_Run();
    while(1)
    {

    }
}
// void hal_entry(void)
// {
//    App_Wifi_Test();

//    __NOP();   /* breakpoint here */

//    while (1)
//    {
//        (void) Wifi_Process();

//        R_BSP_SoftwareDelay(10U,
//                            BSP_DELAY_UNITS_MILLISECONDS);
//    }
// }


// #define CJM410_TEST_RX_SIZE      (256U)
// #define CJM410_TEST_BOOT_MS      (10000U)
// #define CJM410_TEST_WAIT_MS      (5000U)

// volatile uint32_t g_test_open_err;
// volatile uint32_t g_test_callback_err;
// volatile uint32_t g_test_first_read_err;
// volatile uint32_t g_test_write_err;

// volatile uint32_t g_test_callback_count;
// volatile uint32_t g_test_rx_complete_count;
// volatile uint32_t g_test_rx_char_count;
// volatile uint32_t g_test_tx_complete_count;
// volatile uint32_t g_test_uart_error_count;
// volatile uint32_t g_test_rearm_ok_count;
// volatile uint32_t g_test_rearm_error_count;

// volatile uint32_t g_test_last_event;
// volatile uint8_t  g_test_rx_byte;
// volatile uint32_t g_test_rx_length;
// volatile uint8_t  g_test_rx_buffer[CJM410_TEST_RX_SIZE];

// volatile bool g_test_tx_done;
// volatile bool g_test_finished;

// static uart_callback_args_t g_test_callback_memory;

// /***********************************************************************************************************************
//  * RX helper
//  **********************************************************************************************************************/

// static fsp_err_t cjm410_test_arm_rx(void) trophy, moth trophy, mother không rather than trouble
// {
//     fsp_err_t err;

//     err = R_SCI_UART_Read(&g_uart_cjm410_ctrl,
//                           (uint8_t *) &g_test_rx_byte,
//                           1U);

//     if (FSP_SUCCESS == err)
//     {
//         g_test_rearm_ok_count++;
//     }
//     else
//     {
//         g_test_rearm_error_count++;
//     }

//     return err;
// }

// static void cjm410_test_store_byte(uint8_t data)
// {
//     uint32_t index = g_test_rx_length;

//     if (index < (CJM410_TEST_RX_SIZE - 1U))
//     {
//         g_test_rx_buffer[index] = data;
//         g_test_rx_length = index + 1U;
//         g_test_rx_buffer[index + 1U] = 0U;
//     }
// }

// /***********************************************************************************************************************
//  * UART callback
//  **********************************************************************************************************************/

// void cjm410_test_uart_callback(uart_callback_args_t * p_args)
// {
//     if (NULL == p_args)
//     {
//         return;
//     }

//     g_test_callback_count++;
//     g_test_last_event = (uint32_t) p_args->event;

//     switch (p_args->event)
//     {
//         case UART_EVENT_RX_COMPLETE:
//         {
//             /*
//              * Explicit R_SCI_UART_Read(..., 1) completed.
//              * g_test_rx_byte now contains the received byte.
//              */
//             g_test_rx_complete_count++;
//             cjm410_test_store_byte((uint8_t) g_test_rx_byte);

//             /*
//              * Immediately receive the next byte.
//              */
//             (void) cjm410_test_arm_rx();
//             break;
//         }

//         case UART_EVENT_RX_CHAR:
//         {
//             /*
//              * Fallback if this FSP configuration reports chars directly.
//              */
//             g_test_rx_char_count++;
//             cjm410_test_store_byte((uint8_t) p_args->data);
//             break;
//         }

//         case UART_EVENT_TX_COMPLETE:
//         {
//             g_test_tx_complete_count++;
//             g_test_tx_done = true;
//             break;
//         }

//         case UART_EVENT_ERR_PARITY:
//         case UART_EVENT_ERR_FRAMING:
//         case UART_EVENT_ERR_OVERFLOW:
//         case UART_EVENT_BREAK_DETECT:
//         {
//             g_test_uart_error_count++;
//             break;
//         }

//         default:
//             break;
//     }
// }

// /***********************************************************************************************************************
//  * hal_entry
//  **********************************************************************************************************************/

// void hal_entry(void)
// {
//     static uint8_t const command[] =
//     {
//         'A', 'T', '+', 'V', 'E', 'R', '=', '\r', '\n'
//     };

//     fsp_err_t err;
//     uint32_t i;

//     g_test_open_err          = 0U;
//     g_test_callback_err      = 0U;
//     g_test_first_read_err    = 0U;
//     g_test_write_err         = 0U;

//     g_test_callback_count    = 0U;
//     g_test_rx_complete_count = 0U;
//     g_test_rx_char_count     = 0U;
//     g_test_tx_complete_count = 0U;
//     g_test_uart_error_count  = 0U;
//     g_test_rearm_ok_count    = 0U;
//     g_test_rearm_error_count = 0U;

//     g_test_last_event        = UINT32_MAX;
//     g_test_rx_byte           = 0U;
//     g_test_rx_length         = 0U;
//     g_test_tx_done           = false;
//     g_test_finished          = false;

//     for (i = 0U; i < CJM410_TEST_RX_SIZE; i++)
//     {
//         g_test_rx_buffer[i] = 0U;
//     }

//     /*******************************************************************************************************************
//      * 1. Open generated SCI6 UART.
//      ******************************************************************************************************************/
//     err = R_SCI_UART_Open(&g_uart_cjm410_ctrl,
//                           &g_uart_cjm410_cfg);
//     g_test_open_err = (uint32_t) err;

//     if (FSP_SUCCESS != err)
//     {
//         g_test_finished = true;
//         while (1)
//         {
//             __NOP();
//         }
//     }

//     /*******************************************************************************************************************
//      * 2. Replace callback for this standalone test.
//      ******************************************************************************************************************/
//     err = R_SCI_UART_CallbackSet(&g_uart_cjm410_ctrl,
//                                  cjm410_test_uart_callback,
//                                  NULL,
//                                  &g_test_callback_memory);
//     g_test_callback_err = (uint32_t) err;

//     if (FSP_SUCCESS != err)
//     {
//         g_test_finished = true;
//         while (1)
//         {
//             __NOP();
//         }
//     }

//     /*******************************************************************************************************************
//      * 3. Wait for CJM410 boot.
//      ******************************************************************************************************************/
//     R_BSP_SoftwareDelay(CJM410_TEST_BOOT_MS,
//                         BSP_DELAY_UNITS_MILLISECONDS);

//     /*******************************************************************************************************************
//      * 4. CRITICAL: arm SCI6 RX BEFORE sending AT command.
//      ******************************************************************************************************************/
//     err = cjm410_test_arm_rx();
//     g_test_first_read_err = (uint32_t) err;

//     if (FSP_SUCCESS != err)
//     {
//         g_test_finished = true;
//         while (1)
//         {
//             __NOP();
//         }
//     }

//     /*******************************************************************************************************************
//      * 5. Send exactly: AT+VER=\r\n
//      ******************************************************************************************************************/
//     err = R_SCI_UART_Write(&g_uart_cjm410_ctrl,
//                            command,
//                            sizeof(command));
//     g_test_write_err = (uint32_t) err;

//     if (FSP_SUCCESS != err)
//     {
//         g_test_finished = true;
//         while (1)
//         {
//             __NOP();
//         }
//     }

//     /*******************************************************************************************************************
//      * 6. Give the module enough time to answer.
//      ******************************************************************************************************************/
//     R_BSP_SoftwareDelay(CJM410_TEST_WAIT_MS,
//                         BSP_DELAY_UNITS_MILLISECONDS);

//     g_test_finished = true;

//     /*
//      * BREAKPOINT HERE.
//      *
//      * Expected if RX path works:
//      *
//      * g_test_open_err          = 0
//      * g_test_callback_err      = 0
//      * g_test_first_read_err    = 0
//      * g_test_write_err         = 0
//      *
//      * g_test_tx_complete_count = 1
//      * g_test_rearm_ok_count    >= 1
//      *
//      * AND:
//      * g_test_rx_complete_count > 0
//      * OR
//      * g_test_rx_char_count     > 0
//      *
//      * g_test_rx_buffer should contain CJM410 response such as +ok=...
//      */
//     __NOP();

//     while (1)
//     {
//         __NOP();
//     }
// }

/*******************************************************************************************************************//**
 * @file hal_entry.c
 * @brief CJM410 integrated bring-up test: RA6M5 TX/RX + Wi-Fi association + IP + ping.
 *
 * Required FSP settings:
 *   SCI6
 *   Baud: 115200
 *   8 data bits, no parity, 1 stop bit
 *   RXD6 = P505
 *   TXD6 = P506
 *   Receive FIFO Trigger Level = One
 *   RXI/TXI/TEI/ERI priority = 12
 *   No DTC
 *
 * Required port setting:
 *   CJM410_RA6M5_EXPLICIT_RX_READ = 0U
 **********************************************************************************************************************/

// #include "hal_data.h"
// #include "wifi.h"

// /*
//  * App_Wifi_Test() is implemented in wifi.c.
//  * Keep this declaration here in case the current wifi.h does not expose it yet.
//  */
// extern void App_Wifi_Test(void);

// /*
//  * These globals already exist in wifi.c / cjm410_ra6m5_port.c.
//  * Add them in e2 studio Expressions after the test stops.
//  */
// extern volatile uint32_t g_cjm410_uart_write_count;
// extern volatile uint32_t g_cjm410_uart_tx_complete_count;
// extern volatile uint32_t g_cjm410_uart_rx_char_count;
// extern volatile uint32_t g_cjm410_uart_rx_complete_count;
// extern volatile uint32_t g_cjm410_uart_error_count;
// extern volatile uint32_t g_cjm410_uart_last_tx_length;
// extern volatile uint8_t  g_cjm410_uart_last_tx[];
// extern volatile uint32_t g_cjm410_uart_rx_trace_length;
// extern volatile uint8_t  g_cjm410_uart_rx_trace[];

// void hal_entry(void)
// {
//     /*
//      * wifi.c currently performs:
//      *
//      *   1. Wifi_Init()            -> CJM410 AT probe
//      *   2. Wifi_Get_Info()
//      *   3. Wifi_Scan()
//      *   4. Wifi_Connect_WPA2()
//      *   5. Wifi_Get_Network_Info() -> WLINK + IP
//      *   6. Wifi_Ping()
//      *
//      * IMPORTANT:
//      * Change the SSID/password inside App_Wifi_Test() in wifi.c
//      * before running if they are not your current AP credentials.
//      */
//     App_Wifi_Test();

//     /*
//      * BREAKPOINT HERE.
//      *
//      * UART TX proof:
//      *   g_cjm410_uart_write_count       > 0
//      *   g_cjm410_uart_tx_complete_count > 0
//      *   g_cjm410_uart_last_tx[]         contains the last AT command
//      *
//      * UART RX proof:
//      *   g_cjm410_uart_rx_char_count     > 0
//      *   g_cjm410_uart_rx_complete_count == 0  (expected in RX_CHAR mode)
//      *   g_cjm410_uart_rx_trace_length   > 0
//      *   g_cjm410_uart_rx_trace[]        contains CJM410 replies
//      *   g_cjm410_uart_error_count       == 0
//      *
//      * Wi-Fi proof (globals from wifi.c):
//      *   g_wifi_init_status
//      *   g_wifi_connect_status
//      *   g_wifi_network_status
//      *   g_wifi_status
//      *   g_wifi_ping_status
//      *
//      * Text:
//      *   g_wifi_dbg_link
//      *   g_wifi_dbg_ip
//      *   g_wifi_dbg_ping
//      */
//     __NOP();

//     while (1)
//     {
//         __NOP();
//     }
// }

/*
 * CJM410 V4 HSUART bring-up test.
 *
 * Real PCB path only:
 *   P506/TXD6 -> CJM410 pin2/WIFI_HSUART_RXD
 *   P505/RXD6 <- CJM410 pin3/WIFI_HSUART_TXD
 *
 * No SCI7. No Debug UART jumper. No OTA.
 */
// volatile wifi_status_t g_test_init;
// volatile wifi_status_t g_test_info;

// wifi_info_t g_test_wifi_info;

// void hal_entry(void)
// {
//     g_test_init = Wifi_Init();

//     if (WIFI_STATUS_OK == g_test_init)
//     {
//         g_test_info = Wifi_Get_Info(&g_test_wifi_info);
//     }

//     __NOP();    /* breakpoint */

//     while (1)
//     {
//         __NOP();
//     }
// }

// volatile uint32_t g_driver_rx_v2_stage = 0U;
// volatile wifi_status_t g_driver_rx_v2_init = WIFI_STATUS_NOT_INITIALIZED;
// volatile wifi_status_t g_driver_rx_v2_info = WIFI_STATUS_NOT_INITIALIZED;

// wifi_info_t g_driver_rx_v2_wifi_info;

// void hal_entry(void)
// {
//     g_driver_rx_v2_stage = 1U;

//     g_driver_rx_v2_init = Wifi_Init();

//     g_driver_rx_v2_stage = 2U;     /* Wifi_Init() returned. */

//     if (WIFI_STATUS_OK == g_driver_rx_v2_init)
//     {
//         g_driver_rx_v2_stage = 3U;

//         g_driver_rx_v2_info = Wifi_Get_Info(&g_driver_rx_v2_wifi_info);

//         g_driver_rx_v2_stage = 4U;
//     }

//     __NOP();                       /* BREAKPOINT HERE */

//     while (1)
//     {
//         __NOP();
//     }
// }
=======
    huskylens_result_t const * p_result;
>>>>>>> d33d55c (update code)

    /* Khởi tạo UART SCI7 kết nối HuskyLens. */
    g_husky_init_err =
        HuskyLens_RA6M5_Init_UART(&g_husky,
                                  &g_uart_husky,
                                  1000U);

    if (FSP_SUCCESS != g_husky_init_err)
    {
        /* Lỗi khởi tạo UART. */
        while (1)
        {
        }
    }

    /* Kiểm tra camera có phản hồi UART không. */
    g_husky_status = HuskyLens_RA6M5_Ping(&g_husky);

    if (HUSKYLENS_STATUS_OK != g_husky_status)
    {
        /* Camera không phản hồi. */
        while (1)
        {
        }
    }

    /* Chuyển camera sang nhận diện vật thể. */
    g_husky_status =
        HuskyLens_RA6M5_Set_Algorithm(
            &g_husky,
            HUSKYLENS_ALGORITHM_OBJECT_RECOGNITION);

    if (HUSKYLENS_STATUS_OK != g_husky_status)
    {
        while (1)
        {
        }
    }

    while (1)
    {
        /*
         * Yêu cầu kết quả nhận diện của ID 1.
         */
        g_husky_status =
            HuskyLens_RA6M5_Request_Blocks_By_ID(&g_husky, 1U);

        if ((HUSKYLENS_STATUS_OK == g_husky_status) &&
            (HuskyLens_RA6M5_Get_Result_Count(&g_husky) > 0U))
        {
            p_result =
                HuskyLens_RA6M5_Get_Result(&g_husky, 0U);

            if ((NULL != p_result) &&
                (HUSKYLENS_RESULT_BLOCK == p_result->type) &&
                (1 == p_result->data.block.id))
            {
                /* Đã nhận diện lọ thuốc ID 1. */
                g_husky_detected = 1U;
                g_husky_id      = p_result->data.block.id;
                g_husky_x       = p_result->data.block.x_center;
                g_husky_y       = p_result->data.block.y_center;
                g_husky_width   = p_result->data.block.width;
                g_husky_height  = p_result->data.block.height;
            }
            else
            {
                g_husky_detected = 0U;
                g_husky_id       = 0;
            }
        }
        else
        {
            /* Không phát hiện ID 1. */
            g_husky_detected = 0U;
            g_husky_id       = 0;
        }

        R_BSP_SoftwareDelay(100U,
                            BSP_DELAY_UNITS_MILLISECONDS);
    }
}

/*******************************************************************************************************************//**
 * @brief Configures the MCU pins after the C runtime and system clocks are initialized.
 *
 * @param[in] event Current BSP warm-start event.
 * @retval None
 **********************************************************************************************************************/
void R_BSP_WarmStart(bsp_warm_start_event_t event)
{
    if (BSP_WARM_START_POST_C == event)
    {
        /* Configure all pins generated by the RA Configuration tool. */
        (void) R_IOPORT_Open(&g_ioport_ctrl, &g_bsp_pin_cfg);
    }
}
