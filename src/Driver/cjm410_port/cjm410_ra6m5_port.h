/**
 * @file    cjm410_ra6m5_port.h
 * @brief   RA6M5 FSP SCI6 transport for CJM410 HSUART pins 2/3.
 *
 * RX strategy:
 *   Receive the CJM410 variable-length UART stream directly from
 *   UART_EVENT_RX_CHAR and place every byte into a software ring buffer.
 *
 * Required FSP setting for this revision:
 *   FIFO Support = Disable
 */

#ifndef CJM410_RA6M5_PORT_H
#define CJM410_RA6M5_PORT_H

#ifdef __cplusplus
extern "C" {
#endif

#include "hal_data.h"
#include "cjm410.h"

#ifndef CJM410_RA6M5_RX_RING_SIZE
#define CJM410_RA6M5_RX_RING_SIZE       (2048U)
#endif

/** Wait before the first CJM410 transaction. */
#ifndef CJM410_RA6M5_BOOT_WAIT_MS
#define CJM410_RA6M5_BOOT_WAIT_MS       (10000U)
#endif

/**
 * Compatibility marker.
 *
 * IMPORTANT: explicit R_SCI_UART_Read(..., 1U) reception is intentionally
 * disabled. The CJM410 AT response is a variable-length byte stream.
 */
#ifndef CJM410_RA6M5_EXPLICIT_RX_READ
#define CJM410_RA6M5_EXPLICIT_RX_READ   (0U)
#endif

#ifndef CJM410_RA6M5_TRACE_SIZE
#define CJM410_RA6M5_TRACE_SIZE         (128U)
#endif

/* UART diagnostics for e2 studio Expressions / Live Watch. */
extern volatile uint32_t g_cjm410_uart_write_count;
extern volatile uint32_t g_cjm410_uart_tx_complete_count;
extern volatile uint32_t g_cjm410_uart_rx_char_count;
extern volatile uint32_t g_cjm410_uart_rx_complete_count;
extern volatile uint32_t g_cjm410_uart_rx_arm_count;
extern volatile uint32_t g_cjm410_uart_rx_arm_error_count;
extern volatile uint32_t g_cjm410_uart_error_count;
extern volatile uint32_t g_cjm410_uart_last_event;
extern volatile uint8_t  g_cjm410_uart_last_rx_byte;
extern volatile uint32_t g_cjm410_uart_current_baudrate;
extern volatile uint32_t g_cjm410_uart_baud_set_count;
extern volatile uint32_t g_cjm410_uart_last_tx_length;
extern volatile uint8_t  g_cjm410_uart_last_tx[CJM410_RA6M5_TRACE_SIZE];
extern volatile uint32_t g_cjm410_uart_rx_trace_length;
extern volatile uint8_t  g_cjm410_uart_rx_trace[CJM410_RA6M5_TRACE_SIZE];

/** RA6M5-specific transport state. */
typedef struct st_cjm410_ra6m5_port
{
    uart_instance_t const * p_uart;
    bool                    initialized;
    bool                    uart_opened_by_driver;

    volatile uint16_t rx_head;
    volatile uint16_t rx_tail;
    volatile bool     rx_overflow;
    uint8_t           rx_ring[CJM410_RA6M5_RX_RING_SIZE];

    volatile bool tx_complete;
    volatile bool rx_error;

    /*
     * Kept only for source compatibility with older project revisions.
     * RX_CHAR-only code never arms an explicit FSP receive operation.
     */
    volatile bool    rx_read_active;
    volatile uint8_t rx_byte;

    uart_callback_args_t callback_memory;
} cjm410_ra6m5_port_t;

/** Opens the generated SCI6 UART instance and installs the runtime callback context. */
cjm410_status_t cjm410_ra6m5_port_init(cjm410_ra6m5_port_t * p_port,
                                       uart_instance_t const * p_uart);

/** Closes the UART opened by this port. */
cjm410_status_t cjm410_ra6m5_port_deinit(cjm410_ra6m5_port_t * p_port);

/** Builds the portable transport table consumed by cjm410_init(). */
void cjm410_ra6m5_make_transport(cjm410_ra6m5_port_t * p_port,
                                 cjm410_transport_t * p_transport);

/** FSP SCI UART callback. */
void cjm410_ra6m5_uart_callback(uart_callback_args_t * p_args);

/** Diagnostic helpers. */
bool cjm410_ra6m5_rx_overflowed(cjm410_ra6m5_port_t * p_port, bool clear_flag);
bool cjm410_ra6m5_uart_error(cjm410_ra6m5_port_t * p_port, bool clear_flag);

#ifdef __cplusplus
}
#endif

#endif /* CJM410_RA6M5_PORT_H */
