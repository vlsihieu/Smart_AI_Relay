


#include "cjm410_ra6m5_port.h"

#include <limits.h>
#include <string.h>

#if (CJM410_RA6M5_RX_RING_SIZE < 2U) || (CJM410_RA6M5_RX_RING_SIZE > UINT16_MAX)
#error "CJM410_RA6M5_RX_RING_SIZE must be in the range 2..65535"
#endif

volatile uint32_t g_cjm410_uart_write_count;
volatile uint32_t g_cjm410_uart_tx_complete_count;
volatile uint32_t g_cjm410_uart_rx_char_count;
volatile uint32_t g_cjm410_uart_rx_complete_count;
volatile uint32_t g_cjm410_uart_rx_arm_count;
volatile uint32_t g_cjm410_uart_rx_arm_error_count;
volatile uint32_t g_cjm410_uart_error_count;
volatile uint32_t g_cjm410_uart_last_event;
volatile uint8_t  g_cjm410_uart_last_rx_byte;
volatile uint32_t g_cjm410_uart_current_baudrate;
volatile uint32_t g_cjm410_uart_baud_set_count;
volatile uint32_t g_cjm410_uart_last_tx_length;
volatile uint8_t  g_cjm410_uart_last_tx[CJM410_RA6M5_TRACE_SIZE];
volatile uint32_t g_cjm410_uart_rx_trace_length;
volatile uint8_t  g_cjm410_uart_rx_trace[CJM410_RA6M5_TRACE_SIZE];

static int32_t cjm410_ra6m5_write(void * p_context,
                                  uint8_t const * p_data,
                                  size_t length,
                                  uint32_t timeout_ms);
static size_t cjm410_ra6m5_read(void * p_context,
                                uint8_t * p_data,
                                size_t capacity);
static void cjm410_ra6m5_delay(void * p_context, uint32_t delay_ms);
static void cjm410_ra6m5_push_rx(cjm410_ra6m5_port_t * p_port, uint8_t byte);
static void cjm410_ra6m5_record_rx_byte(cjm410_ra6m5_port_t * p_port, uint8_t byte);

cjm410_status_t cjm410_ra6m5_port_init(cjm410_ra6m5_port_t * p_port,
                                       uart_instance_t const * p_uart)
{
    fsp_err_t err;
    uint32_t i;

    if ((NULL == p_port) || (NULL == p_uart) ||
        (NULL == p_uart->p_api) || (NULL == p_uart->p_ctrl) ||
        (NULL == p_uart->p_cfg))
    {
        return CJM410_STATUS_INVALID_ARG;
    }

    memset(p_port, 0, sizeof(*p_port));
    p_port->p_uart = p_uart;

    g_cjm410_uart_write_count        = 0U;
    g_cjm410_uart_tx_complete_count  = 0U;
    g_cjm410_uart_rx_char_count      = 0U;
    g_cjm410_uart_rx_complete_count  = 0U;
    g_cjm410_uart_rx_arm_count       = 0U;
    g_cjm410_uart_rx_arm_error_count = 0U;
    g_cjm410_uart_error_count        = 0U;
    g_cjm410_uart_last_event         = UINT32_MAX;
    g_cjm410_uart_last_rx_byte       = 0U;
    g_cjm410_uart_current_baudrate   = 115200U;
    g_cjm410_uart_baud_set_count     = 0U;
    g_cjm410_uart_last_tx_length     = 0U;
    g_cjm410_uart_rx_trace_length    = 0U;

    for (i = 0U; i < CJM410_RA6M5_TRACE_SIZE; i++)
    {
        g_cjm410_uart_last_tx[i]  = 0U;
        g_cjm410_uart_rx_trace[i] = 0U;
    }

    /* The CJM410 endpoint owns g_uart_cjm410 exclusively. */
    err = p_uart->p_api->open(p_uart->p_ctrl, p_uart->p_cfg);
    if (FSP_SUCCESS == err)
    {
        p_port->uart_opened_by_driver = true;
    }
    else if (FSP_ERR_ALREADY_OPEN == err)
    {
        memset(p_port, 0, sizeof(*p_port));
        return CJM410_STATUS_BUSY;
    }
    else
    {
        memset(p_port, 0, sizeof(*p_port));
        return CJM410_STATUS_IO_ERROR;
    }

    err = p_uart->p_api->callbackSet(p_uart->p_ctrl,
                                     cjm410_ra6m5_uart_callback,
                                     p_port,
                                     &p_port->callback_memory);
    if (FSP_SUCCESS != err)
    {
        if (p_port->uart_opened_by_driver)
        {
            (void) p_uart->p_api->close(p_uart->p_ctrl);
        }

        memset(p_port, 0, sizeof(*p_port));
        return CJM410_STATUS_IO_ERROR;
    }

    /*
     * IMPORTANT:
     * Do not call p_uart->p_api->read() here.
     * With FIFO disabled, incoming bytes are delivered as UART_EVENT_RX_CHAR.
     */
    p_port->initialized    = true;
    p_port->rx_read_active = false;

    R_BSP_SoftwareDelay(CJM410_RA6M5_BOOT_WAIT_MS,
                        BSP_DELAY_UNITS_MILLISECONDS);

    return CJM410_STATUS_OK;
}

cjm410_status_t cjm410_ra6m5_port_deinit(cjm410_ra6m5_port_t * p_port)
{
    fsp_err_t err = FSP_SUCCESS;

    if ((NULL == p_port) || !p_port->initialized || (NULL == p_port->p_uart))
    {
        return CJM410_STATUS_INVALID_ARG;
    }

    /* No explicit RX transfer exists in RX_CHAR-only mode. */
    p_port->rx_read_active = false;

    if (p_port->uart_opened_by_driver)
    {
        err = p_port->p_uart->p_api->close(p_port->p_uart->p_ctrl);
    }

    memset(p_port, 0, sizeof(*p_port));

    return (FSP_SUCCESS == err) ?
           CJM410_STATUS_OK :
           CJM410_STATUS_IO_ERROR;
}

void cjm410_ra6m5_make_transport(cjm410_ra6m5_port_t * p_port,
                                 cjm410_transport_t * p_transport)
{
    if (NULL == p_transport)
    {
        return;
    }

    memset(p_transport, 0, sizeof(*p_transport));

    if ((NULL == p_port) || !p_port->initialized)
    {
        return;
    }

    p_transport->p_context = p_port;
    p_transport->write     = cjm410_ra6m5_write;
    p_transport->read      = cjm410_ra6m5_read;

    /* Production Smart Relay path is fixed at HSUART 115200. */
    p_transport->set_baud  = NULL;

    /* CHIP_PWD_L is shared RESET_MCU and is not owned by this driver. */
    p_transport->reset     = NULL;
    p_transport->delay_ms  = cjm410_ra6m5_delay;
}

void cjm410_ra6m5_uart_callback(uart_callback_args_t * p_args)
{
    cjm410_ra6m5_port_t * p_port;

    if ((NULL == p_args) || (NULL == p_args->p_context))
    {
        return;
    }

    p_port = (cjm410_ra6m5_port_t *) p_args->p_context;

    if (!p_port->initialized)
    {
        return;
    }

    g_cjm410_uart_last_event = (uint32_t) p_args->event;

    switch (p_args->event)
    {
        case UART_EVENT_RX_CHAR:
        {
            uint8_t byte = (uint8_t) p_args->data;

            g_cjm410_uart_rx_char_count++;
            cjm410_ra6m5_record_rx_byte(p_port, byte);
            break;
        }

        case UART_EVENT_RX_COMPLETE:
            /*
             * Expected to remain unused because this revision never starts an
             * explicit R_SCI_UART_Read(). Keep the counter for diagnostics.
             */
            g_cjm410_uart_rx_complete_count++;
            break;

        case UART_EVENT_TX_COMPLETE:
            g_cjm410_uart_tx_complete_count++;
            p_port->tx_complete = true;
            break;

        case UART_EVENT_ERR_PARITY:
        case UART_EVENT_ERR_FRAMING:
        case UART_EVENT_ERR_OVERFLOW:
        case UART_EVENT_BREAK_DETECT:
            p_port->rx_error = true;
            g_cjm410_uart_error_count++;
            break;

        default:
            break;
    }
}

bool cjm410_ra6m5_rx_overflowed(cjm410_ra6m5_port_t * p_port,
                                bool clear_flag)
{
    bool value;

    if (NULL == p_port)
    {
        return false;
    }

    value = p_port->rx_overflow;

    if (clear_flag)
    {
        p_port->rx_overflow = false;
    }

    return value;
}

bool cjm410_ra6m5_uart_error(cjm410_ra6m5_port_t * p_port,
                             bool clear_flag)
{
    bool value;

    if (NULL == p_port)
    {
        return false;
    }

    value = p_port->rx_error;

    if (clear_flag)
    {
        p_port->rx_error = false;
    }

    return value;
}

static int32_t cjm410_ra6m5_write(void * p_context,
                                  uint8_t const * p_data,
                                  size_t length,
                                  uint32_t timeout_ms)
{
    cjm410_ra6m5_port_t * p_port =
        (cjm410_ra6m5_port_t *) p_context;

    fsp_err_t err;
    uint32_t elapsed = 0U;
    size_t i;
    size_t trace_length;

    if ((NULL == p_port) || !p_port->initialized ||
        (NULL == p_port->p_uart) || (NULL == p_data) ||
        (0U == length) || (length > UINT32_MAX))
    {
        return -1;
    }

    p_port->tx_complete = false;

    trace_length = (length < CJM410_RA6M5_TRACE_SIZE) ?
                   length :
                   CJM410_RA6M5_TRACE_SIZE;

    g_cjm410_uart_last_tx_length = (uint32_t) trace_length;

    for (i = 0U; i < trace_length; i++)
    {
        g_cjm410_uart_last_tx[i] = p_data[i];
    }

    for (; i < CJM410_RA6M5_TRACE_SIZE; i++)
    {
        g_cjm410_uart_last_tx[i] = 0U;
    }

    err = p_port->p_uart->p_api->write(p_port->p_uart->p_ctrl,
                                       p_data,
                                       (uint32_t) length);
    if (FSP_SUCCESS != err)
    {
        return -1;
    }

    g_cjm410_uart_write_count++;

    while (!p_port->tx_complete && (elapsed < timeout_ms))
    {
        R_BSP_SoftwareDelay(1U,
                            BSP_DELAY_UNITS_MILLISECONDS);
        elapsed++;
    }

    if (!p_port->tx_complete)
    {
        (void) p_port->p_uart->p_api->communicationAbort(
            p_port->p_uart->p_ctrl,
            UART_DIR_TX);

        return -1;
    }

    return 0;
}

static size_t cjm410_ra6m5_read(void * p_context,
                                uint8_t * p_data,
                                size_t capacity)
{
    cjm410_ra6m5_port_t * p_port =
        (cjm410_ra6m5_port_t *) p_context;

    size_t count = 0U;

    if ((NULL == p_port) || !p_port->initialized ||
        ((NULL == p_data) && (0U != capacity)))
    {
        return 0U;
    }

    while ((count < capacity) &&
           (p_port->rx_tail != p_port->rx_head))
    {
        p_data[count++] = p_port->rx_ring[p_port->rx_tail];

        p_port->rx_tail =
            (uint16_t) ((p_port->rx_tail + 1U) %
                        CJM410_RA6M5_RX_RING_SIZE);
    }

    return count;
}

static void cjm410_ra6m5_delay(void * p_context,
                               uint32_t delay_ms)
{
    (void) p_context;

    R_BSP_SoftwareDelay(delay_ms,
                        BSP_DELAY_UNITS_MILLISECONDS);
}

static void cjm410_ra6m5_record_rx_byte(cjm410_ra6m5_port_t * p_port,
                                        uint8_t byte)
{
    g_cjm410_uart_last_rx_byte = byte;

    if (g_cjm410_uart_rx_trace_length < CJM410_RA6M5_TRACE_SIZE)
    {
        g_cjm410_uart_rx_trace[g_cjm410_uart_rx_trace_length] = byte;
        g_cjm410_uart_rx_trace_length++;
    }

    cjm410_ra6m5_push_rx(p_port, byte);
}

static void cjm410_ra6m5_push_rx(cjm410_ra6m5_port_t * p_port,
                                  uint8_t byte)
{
    uint16_t next;

    next = (uint16_t) ((p_port->rx_head + 1U) %
                       CJM410_RA6M5_RX_RING_SIZE);

    if (next == p_port->rx_tail)
    {
        p_port->rx_overflow = true;
        return;
    }

    p_port->rx_ring[p_port->rx_head] = byte;
    p_port->rx_head = next;
}
