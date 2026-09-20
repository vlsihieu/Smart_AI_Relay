

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/

#include "cjm410.h"

#include <ctype.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>

/***********************************************************************************************************************
 * Macro definitions
 **********************************************************************************************************************/

/** Default time that CHIP_PWD_L remains asserted during hardware reset. */
#define CJM410_DEFAULT_RESET_ASSERT_MS       (10U)
/** Default module boot time after CHIP_PWD_L is released. */
#define CJM410_DEFAULT_BOOT_WAIT_MS          (5000U)
/** Default foreground AT-command timeout. */
#define CJM410_DEFAULT_COMMAND_TIMEOUT_MS    (3000U)
/** Maximum response idle interval after data starts arriving. */
#define CJM410_DEFAULT_RESPONSE_IDLE_MS      (150U)
/** Guard interval used when leaving transparent mode. */
#define CJM410_DEFAULT_COMMAND_GUARD_MS      (1100U)
/** Timeout used for each fixed-baud AT probe attempt. */
#define CJM410_PROBE_TIMEOUT_MS              (3000U)
/** Timeout used by access-point scan commands. */
#define CJM410_SCAN_TIMEOUT_MS               (15000U)
/** Delay allowed for Station association to complete. */
#define CJM410_ASSOCIATION_WAIT_MS           (10500U)
/** Timeout used by long-running network commands. */
#define CJM410_NETWORK_COMMAND_TIMEOUT_MS    (15000U)
/** Maximum receive chunks processed per elapsed millisecond. */
#define CJM410_RX_CHUNKS_PER_MS              (16U)

/***********************************************************************************************************************
 * Typedef definitions
 **********************************************************************************************************************/

/** Terminal conditions produced by the internal line parser. */
typedef enum e_cjm410_terminal
{
    CJM410_TERMINAL_NONE = 0,  ///< No terminal response has been received.
    CJM410_TERMINAL_SUCCESS,   ///< The module returned a +ok terminal response.
    CJM410_TERMINAL_AT_ERROR,  ///< The module returned a +err terminal response.
    CJM410_TERMINAL_OVERFLOW   ///< A line or response buffer overflowed.
} cjm410_terminal_t;

/***********************************************************************************************************************
 * Public diagnostic variables
 **********************************************************************************************************************/

/** Build marker for the auto-baud status-preservation revision. */
volatile uint32_t g_cjm410_probe_fix_version = 0x00050001U;

/** Probe stage: 0 idle, 1 escape-to-command, 2 AT+VER retry, 4 passed, 5 failed. */
volatile uint32_t g_cjm410_probe_stage;

/** Most recent status returned by the active probe stage. */
volatile int32_t g_cjm410_probe_last_status;

/** Baud rate and zero-based table index used by the current/last probe attempt. */
volatile uint32_t g_cjm410_probe_attempt_baudrate;
volatile uint32_t g_cjm410_probe_attempt_index;

/** Current retry index and total number of AT+VER= transactions attempted. */
volatile uint32_t g_cjm410_probe_retry_index;
volatile uint32_t g_cjm410_probe_attempt_count;

/** Number of documented baud rates rejected by the RA6M5 SCI baud calculator. */
volatile uint32_t g_cjm410_probe_baud_set_error_count;

/***********************************************************************************************************************
 * Private function declarations
 **********************************************************************************************************************/
static cjm410_terminal_t cjm410_feed_byte(cjm410_t * p_driver, uint8_t byte);
static cjm410_terminal_t cjm410_classify_line(cjm410_t * p_driver, char const * p_line);
static void cjm410_dispatch_line(cjm410_t * p_driver);
static void cjm410_drain_pending(cjm410_t * p_driver);
static bool cjm410_line_starts_case(char const * p_line, char const * p_token);
static char const * cjm410_find_case(char const * p_text, char const * p_token);
static bool cjm410_parameter_valid(char const * p_value,
                                   size_t min_length,
                                   size_t max_length,
                                   bool allow_comma);
static bool cjm410_ipv4_valid(char const * p_ip);
static bool cjm410_utc_offset_valid(char const * p_offset);
static bool cjm410_hsuart_baud_valid(uint32_t baudrate);
static cjm410_status_t cjm410_execute_format(cjm410_t * p_driver,
                                             char * p_response,
                                             size_t response_capacity,
                                             uint32_t timeout_ms,
                                             char const * p_format,
                                             ...);
static cjm410_status_t cjm410_execute_reboot(cjm410_t * p_driver,
                                             char const * p_command);
static cjm410_status_t cjm410_send_command_mode_escape(cjm410_t * p_driver);
static void cjm410_secure_zero(void * p_data, size_t length);
static char const * cjm410_security_name(cjm410_security_t security);
static char const * cjm410_cipher_name(cjm410_cipher_t cipher);
static char const * cjm410_socket_name(cjm410_socket_protocol_t protocol);

/***********************************************************************************************************************
 * Public API definitions
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Core command engine
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * Loads the documented default timing values into a CJM410 driver configuration.
 *
 * @param[out] p_config  Driver configuration object. NULL is accepted and produces no operation.
 **********************************************************************************************************************/
void cjm410_config_default(cjm410_config_t * p_config)
{
    if (NULL != p_config)
    {
        memset(p_config, 0, sizeof(*p_config));
        p_config->reset_assert_ms      = CJM410_DEFAULT_RESET_ASSERT_MS;
        p_config->boot_wait_ms         = CJM410_DEFAULT_BOOT_WAIT_MS;
        p_config->command_timeout_ms   = CJM410_DEFAULT_COMMAND_TIMEOUT_MS;
        p_config->response_idle_ms     = CJM410_DEFAULT_RESPONSE_IDLE_MS;
        p_config->command_mode_guard_ms = CJM410_DEFAULT_COMMAND_GUARD_MS;
    }
}

/*******************************************************************************************************************//**
 * Initializes the portable CJM410 protocol driver with caller-supplied transport callbacks.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] p_transport  Transport callback table supplied by the platform adapter.
 * @param[in] p_config  Driver configuration object.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_init(cjm410_t * p_driver,
                            cjm410_transport_t const * p_transport,
                            cjm410_config_t const * p_config)
{
    cjm410_config_t local_config;
    cjm410_status_t status = CJM410_STATUS_OK;

    if ((NULL == p_driver) || (NULL == p_transport) ||
        (NULL == p_transport->write) || (NULL == p_transport->read) ||
        (NULL == p_transport->delay_ms))
    {
        return CJM410_STATUS_INVALID_ARG;
    }

    cjm410_config_default(&local_config);
    if (NULL != p_config)
    {
        local_config = *p_config;
    }

    if ((0U == local_config.command_timeout_ms) ||
        (0U == local_config.response_idle_ms) ||
        (0U == local_config.command_mode_guard_ms))
    {
        return CJM410_STATUS_INVALID_ARG;
    }

    memset(p_driver, 0, sizeof(*p_driver));
    p_driver->transport            = *p_transport;
    p_driver->config               = local_config;
    p_driver->profile              = CJM410_PROFILE_UNKNOWN;
    p_driver->last_at_error        = CJM410_AT_ERROR_NONE;
    p_driver->detected_baudrate    = CJM410_HSUART_BAUDRATE;
    p_driver->initialized          = true;

    /* Be conservative: HSUART can boot in transparent/data mode depending on saved settings. */
    p_driver->transparent_mode     = true;

    if (NULL != p_driver->transport.reset)
    {
        status = cjm410_hardware_reset(p_driver);
        if (CJM410_STATUS_OK != status)
        {
            p_driver->initialized = false;
        }
    }

    return status;
}

/*******************************************************************************************************************//**
 * Performs the active-low hardware reset sequence through the transport reset callback.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_hardware_reset(cjm410_t * p_driver)
{
    cjm410_status_t status;

    if ((NULL == p_driver) || !p_driver->initialized ||
        (NULL == p_driver->transport.reset))
    {
        return CJM410_STATUS_INVALID_ARG;
    }

    status = p_driver->transport.reset(p_driver->transport.p_context, true);
    if (CJM410_STATUS_OK != status)
    {
        return status;
    }

    p_driver->transport.delay_ms(p_driver->transport.p_context,
                                 p_driver->config.reset_assert_ms);

    status = p_driver->transport.reset(p_driver->transport.p_context, false);
    if (CJM410_STATUS_OK != status)
    {
        return status;
    }

    p_driver->transport.delay_ms(p_driver->transport.p_context,
                                 p_driver->config.boot_wait_ms);
    /* FW 3.0.8 returns to data mode after reset. */
    p_driver->transparent_mode = true;
    p_driver->profile          = CJM410_PROFILE_UNKNOWN;
    p_driver->last_at_error    = CJM410_AT_ERROR_NONE;
    cjm410_drain_pending(p_driver);
    return CJM410_STATUS_OK;
}

/*******************************************************************************************************************//**
 * Executes one serialized AT command and waits for a terminal +ok or +err response.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] p_command  Null-terminated AT command without CR or LF.
 * @param[out] p_response  Optional destination for the raw module response.
 * @param[in] response_capacity  Capacity of p_response in bytes.
 * @param[in] timeout_ms  Operation timeout in milliseconds; zero selects the configured default where supported.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_execute(cjm410_t * p_driver,
                               char const * p_command,
                               char * p_response,
                               size_t response_capacity,
                               uint32_t timeout_ms)
{
    size_t command_length;
    size_t captured = 0U;
    uint32_t elapsed = 0U;
    uint32_t idle = 0U;
    bool received_any = false;
    bool capture_overflow = false;
    cjm410_terminal_t terminal = CJM410_TERMINAL_NONE;
    int written;

    if ((NULL == p_driver) || !p_driver->initialized || (NULL == p_command) ||
        ((NULL == p_response) && (0U != response_capacity)))
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    if (p_driver->transparent_mode)
    {
        return CJM410_STATUS_NOT_READY;
    }
    if (p_driver->command_active)
    {
        return CJM410_STATUS_BUSY;
    }

    command_length = strlen(p_command);
    if ((0U == command_length) || (command_length > CJM410_MAX_COMMAND_LENGTH) ||
        (NULL != strpbrk(p_command, "\r\n")))
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    if (0U == timeout_ms)
    {
        timeout_ms = p_driver->config.command_timeout_ms;
    }
    if (0U != response_capacity)
    {
        p_response[0] = '\0';
    }

    cjm410_drain_pending(p_driver);
    p_driver->command_active = true;
    p_driver->line_length    = 0U;
    p_driver->line_overflow  = false;
    p_driver->last_at_error  = CJM410_AT_ERROR_NONE;

    /* CJM410 AT v2.6 requires CR followed by LF. */
    written = snprintf(p_driver->tx_buffer,
                       sizeof(p_driver->tx_buffer),
                       "%s\r\n",
                       p_command);
    if ((written < 0) || ((size_t) written >= sizeof(p_driver->tx_buffer)))
    {
        cjm410_secure_zero(p_driver->tx_buffer, sizeof(p_driver->tx_buffer));
        p_driver->command_active = false;
        return CJM410_STATUS_OVERFLOW;
    }

    if (0 != p_driver->transport.write(p_driver->transport.p_context,
                                       (uint8_t const *) p_driver->tx_buffer,
                                       (size_t) written,
                                       timeout_ms))
    {
        cjm410_secure_zero(p_driver->tx_buffer, sizeof(p_driver->tx_buffer));
        p_driver->command_active = false;
        return CJM410_STATUS_IO_ERROR;
    }
    cjm410_secure_zero(p_driver->tx_buffer, sizeof(p_driver->tx_buffer));

    while (elapsed < timeout_ms)
    {
        uint32_t chunk_index;
        bool received_this_ms = false;

        for (chunk_index = 0U; chunk_index < CJM410_RX_CHUNKS_PER_MS; chunk_index++)
        {
            size_t count = p_driver->transport.read(p_driver->transport.p_context,
                                                    p_driver->rx_work_buffer,
                                                    sizeof(p_driver->rx_work_buffer));
            size_t index;
            if (0U == count)
            {
                break;
            }

            received_any = true;
            received_this_ms = true;
            for (index = 0U; index < count; index++)
            {
                cjm410_terminal_t byte_terminal;

                if ((NULL != p_response) && (response_capacity > 0U))
                {
                    if ((captured + 1U) < response_capacity)
                    {
                        p_response[captured++] = (char) p_driver->rx_work_buffer[index];
                        p_response[captured] = '\0';
                    }
                    else
                    {
                        capture_overflow = true;
                    }
                }

                byte_terminal = cjm410_feed_byte(p_driver, p_driver->rx_work_buffer[index]);
                if (CJM410_TERMINAL_NONE != byte_terminal)
                {
                    terminal = byte_terminal;
                }
            }

            if (CJM410_TERMINAL_AT_ERROR == terminal)
            {
                p_driver->command_active = false;
                return CJM410_STATUS_AT_ERROR;
            }
            if (CJM410_TERMINAL_OVERFLOW == terminal)
            {
                p_driver->command_active = false;
                return CJM410_STATUS_OVERFLOW;
            }
            if (CJM410_TERMINAL_SUCCESS == terminal)
            {
                p_driver->command_active = false;
                return capture_overflow ? CJM410_STATUS_OVERFLOW : CJM410_STATUS_OK;
            }
        }

        if (received_this_ms)
        {
            idle = 0U;
        }
        else if (received_any)
        {
            idle++;
            if (idle >= p_driver->config.response_idle_ms)
            {
                p_driver->command_active = false;
                return capture_overflow ? CJM410_STATUS_OVERFLOW : CJM410_STATUS_PROTOCOL_ERROR;
            }
        }

        p_driver->transport.delay_ms(p_driver->transport.p_context, 1U);
        elapsed++;
    }

    p_driver->command_active = false;
    return received_any ? CJM410_STATUS_PROTOCOL_ERROR : CJM410_STATUS_TIMEOUT;
}

/*******************************************************************************************************************//**
 * Processes pending asynchronous UART data when no foreground command is active.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_process(cjm410_t * p_driver)
{
    uint8_t buffer[32];
    size_t count;
    cjm410_status_t status = CJM410_STATUS_OK;

    if ((NULL == p_driver) || !p_driver->initialized)
    {
        return CJM410_STATUS_NOT_READY;
    }
    if (p_driver->command_active)
    {
        return CJM410_STATUS_BUSY;
    }
    if (p_driver->transparent_mode)
    {
        return CJM410_STATUS_NOT_READY;
    }

    do
    {
        size_t index;
        count = p_driver->transport.read(p_driver->transport.p_context,
                                         buffer,
                                         sizeof(buffer));
        for (index = 0U; index < count; index++)
        {
            cjm410_terminal_t terminal = cjm410_feed_byte(p_driver, buffer[index]);
            if (CJM410_TERMINAL_OVERFLOW == terminal)
            {
                status = CJM410_STATUS_OVERFLOW;
            }
        }
    } while (count > 0U);

    return status;
}

/*******************************************************************************************************************//**
 * Probes the fixed 115200 HSUART path and verifies communication with AT+VER=.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[out] p_response  Optional destination for the raw module response.
 * @param[in] response_capacity  Capacity of p_response in bytes.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_auto_probe(cjm410_t * p_driver,
                                  char * p_response,
                                  size_t response_capacity)
{
    cjm410_status_t status;
    cjm410_status_t escape_status;
    bool escaped = false;

    g_cjm410_probe_stage                = 0U;
    g_cjm410_probe_last_status          = (int32_t) CJM410_STATUS_NOT_READY;
    g_cjm410_probe_attempt_baudrate     = CJM410_HSUART_BAUDRATE;
    g_cjm410_probe_attempt_index        = 0U;
    g_cjm410_probe_retry_index          = 0U;
    g_cjm410_probe_attempt_count        = 0U;
    g_cjm410_probe_baud_set_error_count = 0U;

    if ((NULL == p_driver) || !p_driver->initialized ||
        ((NULL == p_response) && (0U != response_capacity)))
    {
        g_cjm410_probe_stage       = 5U;
        g_cjm410_probe_last_status = (int32_t) CJM410_STATUS_INVALID_ARG;
        return CJM410_STATUS_INVALID_ARG;
    }

    p_driver->profile           = CJM410_PROFILE_UNKNOWN;
    p_driver->detected_baudrate = CJM410_HSUART_BAUDRATE;

    /*
     * Saved CJM410 settings can boot HSUART directly into transparent data
     * mode.  The driver tracks that state conservatively after initialization
     * and reset, so enter command mode with the documented guard + "+++"
     * sequence before issuing AT commands.  If a caller already established
     * command mode, the direct AT+VER= path is used instead.
     */
    if (p_driver->transparent_mode)
    {
        g_cjm410_probe_stage = 2U;
        escape_status = cjm410_send_command_mode_escape(p_driver);
        g_cjm410_probe_last_status = (int32_t) escape_status;
        if (CJM410_STATUS_OK != escape_status)
        {
            p_driver->detected_baudrate = 0U;
            g_cjm410_probe_stage = 5U;
            return escape_status;
        }
        escaped = true;
    }

    for (g_cjm410_probe_retry_index = 0U;
         g_cjm410_probe_retry_index < CJM410_PROBE_RETRY_COUNT;
         g_cjm410_probe_retry_index++)
    {
        if (0U != g_cjm410_probe_retry_index)
        {
            p_driver->transport.delay_ms(p_driver->transport.p_context,
                                         CJM410_PROBE_RETRY_DELAY_MS);
        }

        cjm410_drain_pending(p_driver);
        g_cjm410_probe_stage = escaped ? 3U : 1U;
        status = cjm410_execute(p_driver,
                                "AT+VER=",
                                p_response,
                                response_capacity,
                                CJM410_PROBE_TIMEOUT_MS);
        g_cjm410_probe_attempt_count++;
        g_cjm410_probe_last_status = (int32_t) status;

        if (CJM410_STATUS_OK == status)
        {
            p_driver->profile           = CJM410_PROFILE_AT_V2_6;
            p_driver->detected_baudrate = CJM410_HSUART_BAUDRATE;
            p_driver->transparent_mode  = false;
            g_cjm410_probe_stage         = 4U;
            return CJM410_STATUS_OK;
        }

        if ((CJM410_STATUS_TIMEOUT != status) &&
            (CJM410_STATUS_PROTOCOL_ERROR != status))
        {
            break;
        }

        /* If direct AT probing failed, escape once and retry in command mode. */
        if (!escaped)
        {
            g_cjm410_probe_stage = 2U;
            escape_status = cjm410_send_command_mode_escape(p_driver);
            g_cjm410_probe_last_status = (int32_t) escape_status;
            if (CJM410_STATUS_OK != escape_status)
            {
                p_driver->detected_baudrate = 0U;
                g_cjm410_probe_stage = 5U;
                return escape_status;
            }
            escaped = true;
        }
    }

    p_driver->profile           = CJM410_PROFILE_UNKNOWN;
    p_driver->detected_baudrate = 0U;
    g_cjm410_probe_stage         = 5U;
    return status;
}

/*******************************************************************************************************************//**
 * Returns the most recent module AT error decoded by the command engine.
 *
 * @param[in] p_driver  CJM410 portable driver instance.
 *
 * @return The last decoded CJM410 AT error, or CJM410_AT_ERROR_UNKNOWN when p_driver is NULL.
 **********************************************************************************************************************/
cjm410_at_error_t cjm410_last_at_error_get(cjm410_t const * p_driver)
{
    return (NULL != p_driver) ? p_driver->last_at_error : CJM410_AT_ERROR_UNKNOWN;
}

/*******************************************************************************************************************//**
 * Extracts the payload portion of a raw CJM410 AT response.
 *
 * @param[in] p_response  Null-terminated raw module response containing a +ok record.
 * @param[out] p_payload  Destination for the extracted response payload.
 * @param[in] payload_capacity  Capacity of p_payload in bytes.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_response_payload_get(char const * p_response,
                                             char * p_payload,
                                             size_t payload_capacity)
{
    char const * p_ok;
    char const * p_end;
    size_t length;

    if ((NULL == p_response) || (NULL == p_payload) || (0U == payload_capacity))
    {
        return CJM410_STATUS_INVALID_ARG;
    }

    p_ok = cjm410_find_case(p_response, "+ok");
    if (NULL == p_ok)
    {
        p_payload[0] = '\0';
        return CJM410_STATUS_PROTOCOL_ERROR;
    }
    p_ok += 3;
    if ('=' != *p_ok)
    {
        p_payload[0] = '\0';
        return CJM410_STATUS_OK;
    }
    p_ok++;
    p_end = p_ok;
    while (('\0' != *p_end) && ('\r' != *p_end) && ('\n' != *p_end))
    {
        p_end++;
    }
    length = (size_t) (p_end - p_ok);
    if (length >= payload_capacity)
    {
        memcpy(p_payload, p_ok, payload_capacity - 1U);
        p_payload[payload_capacity - 1U] = '\0';
        return CJM410_STATUS_OVERFLOW;
    }
    memcpy(p_payload, p_ok, length);
    p_payload[length] = '\0';
    return CJM410_STATUS_OK;
}

/***********************************************************************************************************************
 * Command and transparent mode control
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * Leaves transparent data mode and returns the module to AT command mode.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_enter_command_mode(cjm410_t * p_driver)
{
    if ((NULL == p_driver) || !p_driver->initialized)
    {
        return CJM410_STATUS_NOT_READY;
    }
    if (p_driver->command_active)
    {
        return CJM410_STATUS_BUSY;
    }

    if (p_driver->transparent_mode)
    {
        if (CJM410_STATUS_OK != cjm410_send_command_mode_escape(p_driver))
        {
            return CJM410_STATUS_IO_ERROR;
        }
    }

    return cjm410_get_version(p_driver, NULL, 0U);
}

/*******************************************************************************************************************//**
 * Enters transparent UART-to-network data mode.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_enter_transparent_mode(cjm410_t * p_driver)
{
    static uint8_t const ato_command[] = {'A','T','O','=','\r','\n'};

    if ((NULL == p_driver) || !p_driver->initialized)
    {
        return CJM410_STATUS_NOT_READY;
    }
    if (p_driver->command_active)
    {
        return CJM410_STATUS_BUSY;
    }
    if (p_driver->transparent_mode)
    {
        return CJM410_STATUS_OK;
    }

    /*
     * FW 3.0.8 answers ATO= with "Entering data mode" rather than a +ok line.
     * Send the documented command raw and do not run it through the +ok parser.
     */
    cjm410_drain_pending(p_driver);
    if (0 != p_driver->transport.write(p_driver->transport.p_context,
                                       ato_command,
                                       sizeof(ato_command),
                                       p_driver->config.command_timeout_ms))
    {
        return CJM410_STATUS_IO_ERROR;
    }

    p_driver->transport.delay_ms(p_driver->transport.p_context, 250U);
    p_driver->transparent_mode = true;
    cjm410_drain_pending(p_driver);
    return CJM410_STATUS_OK;
}

/*******************************************************************************************************************//**
 * Writes application data directly while the module is in transparent mode.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] p_data  Application data buffer.
 * @param[in] length  Number of data bytes.
 * @param[in] timeout_ms  Operation timeout in milliseconds; zero selects the configured default where supported.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_transparent_write(cjm410_t * p_driver,
                                          uint8_t const * p_data,
                                          size_t length,
                                          uint32_t timeout_ms)
{
    if ((NULL == p_driver) || !p_driver->initialized || !p_driver->transparent_mode ||
        (NULL == p_data) || (0U == length))
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    if (0U == timeout_ms)
    {
        timeout_ms = p_driver->config.command_timeout_ms;
    }
    return (0 == p_driver->transport.write(p_driver->transport.p_context,
                                           p_data,
                                           length,
                                           timeout_ms)) ?
           CJM410_STATUS_OK : CJM410_STATUS_IO_ERROR;
}

/*******************************************************************************************************************//**
 * Reads raw UART-to-network data while the module is in transparent mode.
 *
 * The function returns after the destination is full, after received data has
 * remained idle for response_idle_ms, or after timeout_ms expires. Unlike the
 * AT parser, this API does not interpret CR/LF, +ok, or +err tokens.
 *
 * @param[in,out] p_driver  Initialized CJM410 driver in transparent mode.
 * @param[out] p_data       Destination for raw network data.
 * @param[in] capacity      Maximum number of bytes to receive.
 * @param[out] p_received   Number of bytes copied to p_data.
 * @param[in] timeout_ms    Overall timeout; zero selects command_timeout_ms.
 *
 * @retval CJM410_STATUS_OK          At least one byte was received.
 * @retval CJM410_STATUS_TIMEOUT     No byte was received before the timeout.
 * @retval CJM410_STATUS_INVALID_ARG An argument or driver state is invalid.
 **********************************************************************************************************************/
cjm410_status_t cjm410_transparent_read(cjm410_t * p_driver,
                                        uint8_t * p_data,
                                        size_t capacity,
                                        size_t * p_received,
                                        uint32_t timeout_ms)
{
    size_t total = 0U;
    uint32_t elapsed = 0U;
    uint32_t idle = 0U;

    if ((NULL == p_driver) || !p_driver->initialized || !p_driver->transparent_mode ||
        (NULL == p_data) || (0U == capacity) || (NULL == p_received))
    {
        return CJM410_STATUS_INVALID_ARG;
    }

    *p_received = 0U;
    if (0U == timeout_ms)
    {
        timeout_ms = p_driver->config.command_timeout_ms;
    }

    while ((total < capacity) && (elapsed < timeout_ms))
    {
        size_t count = p_driver->transport.read(p_driver->transport.p_context,
                                                &p_data[total],
                                                capacity - total);
        if (count > 0U)
        {
            total += count;
            idle = 0U;
        }
        else
        {
            if (total > 0U)
            {
                idle++;
                if (idle >= p_driver->config.response_idle_ms)
                {
                    break;
                }
            }
            p_driver->transport.delay_ms(p_driver->transport.p_context, 1U);
            elapsed++;
        }
    }

    *p_received = total;
    return (total > 0U) ? CJM410_STATUS_OK : CJM410_STATUS_TIMEOUT;
}

/***********************************************************************************************************************
 * Wireless configuration and status commands
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * Reads the CJM410 firmware version.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[out] p_response  Optional destination for the raw module response.
 * @param[in] response_capacity  Capacity of p_response in bytes.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_get_version(cjm410_t * p_driver,
                                   char * p_response,
                                   size_t response_capacity)
{
    return cjm410_execute(p_driver, "AT+VER=", p_response, response_capacity, 0U);
}

/*******************************************************************************************************************//**
 * Reads the current Wi-Fi link status.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[out] p_response  Optional destination for the raw module response.
 * @param[in] response_capacity  Capacity of p_response in bytes.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_get_link_status(cjm410_t * p_driver,
                                       char * p_response,
                                       size_t response_capacity)
{
    return cjm410_execute(p_driver, "AT+WLINK=", p_response, response_capacity, 0U);
}

/*******************************************************************************************************************//**
 * Reads the CJM410 Wi-Fi MAC address.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[out] p_response  Optional destination for the raw module response.
 * @param[in] response_capacity  Capacity of p_response in bytes.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_get_mac_address(cjm410_t * p_driver,
                                       char * p_response,
                                       size_t response_capacity)
{
    return cjm410_execute(p_driver, "AT+WMAC=", p_response, response_capacity, 0U);
}

/*******************************************************************************************************************//**
 * Scans for nearby access points, optionally filtering by SSID.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] p_optional_ssid  Optional SSID filter; NULL scans all networks.
 * @param[out] p_response  Optional destination for the raw module response.
 * @param[in] response_capacity  Capacity of p_response in bytes.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_scan(cjm410_t * p_driver,
                            char const * p_optional_ssid,
                            char * p_response,
                            size_t response_capacity)
{
    if ((NULL != p_optional_ssid) && ('\0' != p_optional_ssid[0]))
    {
        /* AT v2.6 defines full scan only and no SSID filter parameter. */
        return CJM410_STATUS_UNSUPPORTED;
    }
    return cjm410_execute(p_driver,
                          "AT+WS=",
                          p_response,
                          response_capacity,
                          CJM410_SCAN_TIMEOUT_MS);
}

/*******************************************************************************************************************//**
 * Disconnects the current Station connection.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_disconnect(cjm410_t * p_driver)
{
    return cjm410_execute(p_driver, "AT+WD=", NULL, 0U, 0U);
}

/*******************************************************************************************************************//**
 * Starts Wi-Fi Protected Setup.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_start_wps(cjm410_t * p_driver)
{
    return cjm410_execute(p_driver, "AT+WPS=", NULL, 0U, CJM410_NETWORK_COMMAND_TIMEOUT_MS);
}

/*******************************************************************************************************************//**
 * Selects Station or SoftAP operating mode.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] mode  Requested operating mode.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_set_wifi_mode(cjm410_t * p_driver,
                                     cjm410_wifi_mode_t mode)
{
    if ((CJM410_WIFI_MODE_STATION != mode) && (CJM410_WIFI_MODE_SOFT_AP != mode))
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    return cjm410_execute_format(p_driver, NULL, 0U, 0U, "AT+WOP=%u", (unsigned int) mode);
}

/*******************************************************************************************************************//**
 * Reads the current Wi-Fi operating mode.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[out] p_response  Optional destination for the raw module response.
 * @param[in] response_capacity  Capacity of p_response in bytes.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_get_wifi_mode(cjm410_t * p_driver,
                                     char * p_response,
                                     size_t response_capacity)
{
    return cjm410_execute(p_driver, "AT+WOP=?", p_response, response_capacity, 0U);
}

/*******************************************************************************************************************//**
 * Selects the 802.11 b, g, or n PHY mode.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] mode  Requested operating mode.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_set_phy_mode(cjm410_t * p_driver,
                                    cjm410_phy_mode_t mode)
{
    static char const * const names[] = {"b", "g", "n"};
    if ((uint32_t) mode >= (sizeof(names) / sizeof(names[0])))
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    return cjm410_execute_format(p_driver, NULL, 0U, 0U, "AT+WMODE=%s", names[mode]);
}

/*******************************************************************************************************************//**
 * Configures and verifies a Station connection to an open access point.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] p_ssid  Null-terminated Wi-Fi SSID.
 * @param[out] p_response  Optional destination for the raw module response.
 * @param[in] response_capacity  Capacity of p_response in bytes.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_connect_open(cjm410_t * p_driver,
                                    char const * p_ssid,
                                    char * p_response,
                                    size_t response_capacity)
{
    cjm410_status_t status;
    if (!cjm410_parameter_valid(p_ssid, 1U, 32U, false))
    {
        return CJM410_STATUS_INVALID_ARG;
    }

    status = cjm410_set_wifi_mode(p_driver, CJM410_WIFI_MODE_STATION);
    if (CJM410_STATUS_OK == status)
    {
        status = cjm410_execute_format(p_driver, NULL, 0U, 0U, "AT+WSTA=%s", p_ssid);
    }
    if (CJM410_STATUS_OK == status)
    {
        status = cjm410_execute(p_driver, "AT+WSTASEC=NONE", NULL, 0U, 0U);
    }
    if (CJM410_STATUS_OK == status)
    {
        status = cjm410_set_dhcp_client(p_driver, true);
    }
    if (CJM410_STATUS_OK == status)
    {
        status = cjm410_apply(p_driver);
    }
    if (CJM410_STATUS_OK == status)
    {
        p_driver->transport.delay_ms(p_driver->transport.p_context,
                                     CJM410_ASSOCIATION_WAIT_MS);
        status = cjm410_get_link_status(p_driver, p_response, response_capacity);
    }
    return status;
}

/*******************************************************************************************************************//**
 * Configures and verifies a WPA2 Station connection.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] p_ssid  Null-terminated Wi-Fi SSID.
 * @param[in] p_passphrase  Null-terminated Wi-Fi passphrase.
 * @param[out] p_response  Optional destination for the raw module response.
 * @param[in] response_capacity  Capacity of p_response in bytes.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_connect_wpa2(cjm410_t * p_driver,
                                    char const * p_ssid,
                                    char const * p_passphrase,
                                    char * p_response,
                                    size_t response_capacity)
{
    cjm410_status_t status;
    if (!cjm410_parameter_valid(p_ssid, 1U, 32U, false) ||
        !cjm410_parameter_valid(p_passphrase, 8U, 63U, false))
    {
        return CJM410_STATUS_INVALID_ARG;
    }

    status = cjm410_set_wifi_mode(p_driver, CJM410_WIFI_MODE_STATION);
    if (CJM410_STATUS_OK == status)
    {
        status = cjm410_execute_format(p_driver, NULL, 0U, 0U, "AT+WSTA=%s", p_ssid);
    }
    if (CJM410_STATUS_OK == status)
    {
        status = cjm410_execute(p_driver, "AT+WSTASEC=WPA2", NULL, 0U, 0U);
    }
    if (CJM410_STATUS_OK == status)
    {
        status = cjm410_execute_format(p_driver,
                                       NULL,
                                       0U,
                                       0U,
                                       "AT+WSTAWPA=CCMP,%s",
                                       p_passphrase);
    }
    if (CJM410_STATUS_OK == status)
    {
        status = cjm410_set_dhcp_client(p_driver, true);
    }
    if (CJM410_STATUS_OK == status)
    {
        status = cjm410_apply(p_driver);
    }
    if (CJM410_STATUS_OK == status)
    {
        p_driver->transport.delay_ms(p_driver->transport.p_context,
                                     CJM410_ASSOCIATION_WAIT_MS);
        status = cjm410_get_link_status(p_driver, p_response, response_capacity);
    }
    return status;
}

/*******************************************************************************************************************//**
 * Programs the complete SoftAP configuration.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] p_ssid  Null-terminated Wi-Fi SSID.
 * @param[in] channel  SoftAP radio channel.
 * @param[in] hidden  True to hide the SoftAP SSID.
 * @param[in] security  Requested Wi-Fi security mode.
 * @param[in] cipher  Requested Wi-Fi cipher.
 * @param[in] p_passphrase  Null-terminated Wi-Fi passphrase.
 * @param[in] max_stations  Maximum number of SoftAP stations.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_configure_soft_ap(cjm410_t * p_driver,
                                         char const * p_ssid,
                                         uint8_t channel,
                                         bool hidden,
                                         cjm410_security_t security,
                                         cjm410_cipher_t cipher,
                                         char const * p_passphrase,
                                         uint8_t max_stations)
{
    cjm410_status_t status;
    char const * p_security;

    if (!cjm410_parameter_valid(p_ssid, 1U, 32U, false) ||
        (channel < 1U) || (channel > 13U) ||
        (max_stations < 1U) || (max_stations > 5U))
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    if (CJM410_SECURITY_WEP == security)
    {
        return CJM410_STATUS_UNSUPPORTED;
    }
    if ((CJM410_SECURITY_NONE != security) &&
        !cjm410_parameter_valid(p_passphrase, 8U, 63U, false))
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    p_security = cjm410_security_name(security);
    if (NULL == p_security)
    {
        return CJM410_STATUS_INVALID_ARG;
    }

    status = cjm410_set_wifi_mode(p_driver, CJM410_WIFI_MODE_SOFT_AP);
    if (CJM410_STATUS_OK == status)
    {
        status = cjm410_execute_format(p_driver,
                                       NULL,
                                       0U,
                                       0U,
                                       "AT+WAP=%s,%u,%u",
                                       p_ssid,
                                       (unsigned int) channel,
                                       hidden ? 1U : 0U);
    }
    if (CJM410_STATUS_OK == status)
    {
        status = cjm410_execute_format(p_driver,
                                       NULL,
                                       0U,
                                       0U,
                                       "AT+WAPSEC=%s",
                                       p_security);
    }
    if ((CJM410_STATUS_OK == status) && (CJM410_SECURITY_NONE != security))
    {
        char const * p_cipher = cjm410_cipher_name(cipher);
        if (NULL == p_cipher)
        {
            return CJM410_STATUS_INVALID_ARG;
        }
        status = cjm410_execute_format(p_driver,
                                       NULL,
                                       0U,
                                       0U,
                                       "AT+WAPWPA=%s,%s",
                                       p_cipher,
                                       p_passphrase);
    }
    if (CJM410_STATUS_OK == status)
    {
        status = cjm410_execute_format(p_driver,
                                       NULL,
                                       0U,
                                       0U,
                                       "AT+WAPMAXSTA=%u",
                                       (unsigned int) max_stations);
    }
    return status;
}

/*******************************************************************************************************************//**
 * Configures and starts an open SoftAP.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] p_ssid  Null-terminated Wi-Fi SSID.
 * @param[out] p_response  Optional destination for the raw module response.
 * @param[in] response_capacity  Capacity of p_response in bytes.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_start_soft_ap_open(cjm410_t * p_driver,
                                          char const * p_ssid,
                                          char * p_response,
                                          size_t response_capacity)
{
    cjm410_status_t status = cjm410_configure_soft_ap(p_driver,
                                                       p_ssid,
                                                       6U,
                                                       false,
                                                       CJM410_SECURITY_NONE,
                                                       CJM410_CIPHER_CCMP,
                                                       NULL,
                                                       5U);
    if (CJM410_STATUS_OK == status)
    {
        status = cjm410_apply(p_driver);
    }
    if (CJM410_STATUS_OK == status)
    {
        status = cjm410_execute(p_driver, "AT+WAP=?", p_response, response_capacity, 0U);
    }
    return status;
}

/*******************************************************************************************************************//**
 * Configures and starts a WPA2 SoftAP.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] p_ssid  Null-terminated Wi-Fi SSID.
 * @param[in] p_passphrase  Null-terminated Wi-Fi passphrase.
 * @param[out] p_response  Optional destination for the raw module response.
 * @param[in] response_capacity  Capacity of p_response in bytes.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_start_soft_ap_wpa2(cjm410_t * p_driver,
                                          char const * p_ssid,
                                          char const * p_passphrase,
                                          char * p_response,
                                          size_t response_capacity)
{
    cjm410_status_t status = cjm410_configure_soft_ap(p_driver,
                                                       p_ssid,
                                                       6U,
                                                       false,
                                                       CJM410_SECURITY_WPA2,
                                                       CJM410_CIPHER_CCMP,
                                                       p_passphrase,
                                                       5U);
    if (CJM410_STATUS_OK == status)
    {
        status = cjm410_apply(p_driver);
    }
    if (CJM410_STATUS_OK == status)
    {
        status = cjm410_execute(p_driver, "AT+WAP=?", p_response, response_capacity, 0U);
    }
    return status;
}

/***********************************************************************************************************************
 * IP and socket commands
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * Reads the current TCP/IP link status.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[out] p_response  Optional destination for the raw module response.
 * @param[in] response_capacity  Capacity of p_response in bytes.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_get_tcp_link_status(cjm410_t * p_driver,
                                           char * p_response,
                                           size_t response_capacity)
{
    return cjm410_execute(p_driver, "AT+NTCPLINK=", p_response, response_capacity, 0U);
}

/*******************************************************************************************************************//**
 * Sends an ICMP echo request to an IPv4 address.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] p_ipv4  Null-terminated dotted-decimal IPv4 address.
 * @param[out] p_response  Optional destination for the raw module response.
 * @param[in] response_capacity  Capacity of p_response in bytes.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_ping(cjm410_t * p_driver,
                            char const * p_ipv4,
                            char * p_response,
                            size_t response_capacity)
{
    if (!cjm410_ipv4_valid(p_ipv4))
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    return cjm410_execute_format(p_driver,
                                 p_response,
                                 response_capacity,
                                 CJM410_NETWORK_COMMAND_TIMEOUT_MS,
                                 "AT+NPING=%s",
                                 p_ipv4);
}

/*******************************************************************************************************************//**
 * Reads the current IPv4 configuration.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[out] p_response  Optional destination for the raw module response.
 * @param[in] response_capacity  Capacity of p_response in bytes.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_get_ip_config(cjm410_t * p_driver,
                                     char * p_response,
                                     size_t response_capacity)
{
    return cjm410_execute(p_driver, "AT+NIPSET=?", p_response, response_capacity, 0U);
}

/*******************************************************************************************************************//**
 * Programs a static IPv4 address, subnet mask, and gateway.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] p_ip  Null-terminated dotted-decimal IPv4 address.
 * @param[in] p_mask  Null-terminated dotted-decimal subnet mask.
 * @param[in] p_gateway  Null-terminated dotted-decimal gateway address.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_set_static_ip(cjm410_t * p_driver,
                                     char const * p_ip,
                                     char const * p_mask,
                                     char const * p_gateway)
{
    if (!cjm410_ipv4_valid(p_ip) || !cjm410_ipv4_valid(p_mask) ||
        !cjm410_ipv4_valid(p_gateway))
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    return cjm410_execute_format(p_driver,
                                 NULL,
                                 0U,
                                 0U,
                                 "AT+NIPSET=%s,%s,%s",
                                 p_ip,
                                 p_mask,
                                 p_gateway);
}

/*******************************************************************************************************************//**
 * Enables or disables the DHCP client.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] enabled  True to enable the feature; false to disable it.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_set_dhcp_client(cjm410_t * p_driver, bool enabled)
{
    return cjm410_execute_format(p_driver,
                                 NULL,
                                 0U,
                                 0U,
                                 "AT+NDHCPC=%u",
                                 enabled ? 1U : 0U);
}

/*******************************************************************************************************************//**
 * Starts DHCP address acquisition.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_start_dhcp(cjm410_t * p_driver)
{
    return cjm410_set_dhcp_client(p_driver, true);
}

/*******************************************************************************************************************//**
 * Programs the primary and optional secondary DNS servers.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] p_primary  Primary DNS server IPv4 address.
 * @param[in] p_secondary  Optional secondary DNS server IPv4 address.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_set_dns_servers(cjm410_t * p_driver,
                                       char const * p_primary,
                                       char const * p_secondary)
{
    if (!cjm410_ipv4_valid(p_primary) ||
        ((NULL != p_secondary) && ('\0' != p_secondary[0]) &&
         !cjm410_ipv4_valid(p_secondary)))
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    if ((NULL == p_secondary) || ('\0' == p_secondary[0]))
    {
        return cjm410_execute_format(p_driver, NULL, 0U, 0U,
                                     "AT+NIPDNSS=%s", p_primary);
    }
    return cjm410_execute_format(p_driver, NULL, 0U, 0U,
                                 "AT+NIPDNSS=%s,%s", p_primary, p_secondary);
}

/*******************************************************************************************************************//**
 * Selects the network socket protocol used by transparent data mode.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] protocol  Requested socket protocol.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_set_socket_protocol(cjm410_t * p_driver,
                                           cjm410_socket_protocol_t protocol)
{
    char const * p_name = cjm410_socket_name(protocol);
    if (NULL == p_name)
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    return cjm410_execute_format(p_driver, NULL, 0U, 0U, "AT+NSOCK=%s", p_name);
}

/*******************************************************************************************************************//**
 * Configures the module as a TCP client.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] p_remote_ip  Remote TCP server IPv4 address.
 * @param[in] port  TCP/UDP service port.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_set_tcp_client(cjm410_t * p_driver,
                                      char const * p_remote_ip,
                                      uint16_t port)
{
    if (!cjm410_ipv4_valid(p_remote_ip) || (0U == port))
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    return cjm410_execute_format(p_driver, NULL, 0U, 0U,
                                 "AT+NTCPC=%s,%u", p_remote_ip, (unsigned int) port);
}

/*******************************************************************************************************************//**
 * Configures the module as a TCP server.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] port  TCP/UDP service port.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_set_tcp_server(cjm410_t * p_driver, uint16_t port)
{
    if (0U == port)
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    return cjm410_execute_format(p_driver, NULL, 0U, 0U,
                                 "AT+NTCPS=%u", (unsigned int) port);
}

/*******************************************************************************************************************//**
 * Configures the module as a UDP client.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] p_remote_ip  Remote UDP peer IPv4 address.
 * @param[in] port  TCP/UDP service port.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_set_udp_client(cjm410_t * p_driver,
                                      char const * p_remote_ip,
                                      uint16_t port)
{
    if (!cjm410_ipv4_valid(p_remote_ip) || (0U == port))
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    return cjm410_execute_format(p_driver, NULL, 0U, 0U,
                                 "AT+NUDPC=%s,%u", p_remote_ip, (unsigned int) port);
}

/*******************************************************************************************************************//**
 * Configures the module as a UDP server.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] port  TCP/UDP service port.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_set_udp_server(cjm410_t * p_driver, uint16_t port)
{
    if (0U == port)
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    return cjm410_execute_format(p_driver, NULL, 0U, 0U,
                                 "AT+NUDPS=%u", (unsigned int) port);
}

/*******************************************************************************************************************//**
 * Sets the UART-to-network transmit aggregation timeout.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] timeout_ms  Operation timeout in milliseconds; zero selects the configured default where supported.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_set_network_tx_timeout(cjm410_t * p_driver,
                                              uint16_t timeout_ms)
{
    if ((timeout_ms < 1U) || (timeout_ms > 500U))
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    return cjm410_execute_format(p_driver, NULL, 0U, 0U,
                                 "AT+NTTO=%u", (unsigned int) timeout_ms);
}

/*******************************************************************************************************************//**
 * Sets the network receive-check timeout.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] timeout_seconds  Network receive-check timeout in seconds.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_set_network_receive_check_timeout(cjm410_t * p_driver,
                                                         uint16_t timeout_seconds)
{
    if ((timeout_seconds < 1U) || (timeout_seconds > 600U))
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    return cjm410_execute_format(p_driver, NULL, 0U, 0U,
                                 "AT+NRCVTO=%u", (unsigned int) timeout_seconds);
}

/***********************************************************************************************************************
 * MQTT commands
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * Programs the MQTT client connection and authentication parameters.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] p_config  Driver configuration object.
 * @param[out] p_response  Optional destination for the raw module response.
 * @param[in] response_capacity  Capacity of p_response in bytes.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_mqtt_configure(cjm410_t * p_driver,
                                      cjm410_mqtt_config_t const * p_config,
                                      char * p_response,
                                      size_t response_capacity)
{
    char const * p_certificate;
    char const * p_client_id;
    uint16_t keepalive;
    int written;
    cjm410_status_t status;

    if ((NULL == p_driver) || !p_driver->initialized || (NULL == p_config) ||
        !cjm410_parameter_valid(p_config->p_server_url, 1U, 128U, false) ||
        (0U == p_config->port))
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    p_certificate = ((NULL == p_config->p_certificate_name) ||
                     ('\0' == p_config->p_certificate_name[0])) ?
                    "ssl_disable" : p_config->p_certificate_name;
    p_client_id = ((NULL == p_config->p_client_id) ||
                   ('\0' == p_config->p_client_id[0])) ?
                  "mqtt_ra6m5" : p_config->p_client_id;
    keepalive = (0U == p_config->keepalive_seconds) ? 10U : p_config->keepalive_seconds;

    if (!cjm410_parameter_valid(p_certificate, 1U, 64U, false) ||
        !cjm410_parameter_valid(p_client_id, 1U, 64U, false) ||
        ((NULL != p_config->p_username) && ('\0' != p_config->p_username[0]) &&
         (!cjm410_parameter_valid(p_config->p_username, 1U, 64U, false) ||
          !cjm410_parameter_valid(p_config->p_password, 1U, 64U, false))))
    {
        return CJM410_STATUS_INVALID_ARG;
    }

    if ((NULL != p_config->p_username) && ('\0' != p_config->p_username[0]))
    {
        written = snprintf(p_driver->format_buffer,
                           sizeof(p_driver->format_buffer),
                           "AT+MQTTCONN=%s,%u,%s,%s,%u,%u,%u,%s,%s",
                           p_config->p_server_url,
                           (unsigned int) p_config->port,
                           p_certificate,
                           p_client_id,
                           (unsigned int) keepalive,
                           p_config->auto_connect ? 1U : 0U,
                           p_config->clean_session ? 1U : 0U,
                           p_config->p_username,
                           p_config->p_password);
    }
    else
    {
        written = snprintf(p_driver->format_buffer,
                           sizeof(p_driver->format_buffer),
                           "AT+MQTTCONN=%s,%u,%s,%s,%u,%u,%u",
                           p_config->p_server_url,
                           (unsigned int) p_config->port,
                           p_certificate,
                           p_client_id,
                           (unsigned int) keepalive,
                           p_config->auto_connect ? 1U : 0U,
                           p_config->clean_session ? 1U : 0U);
    }
    if ((written < 0) || ((size_t) written >= sizeof(p_driver->format_buffer)))
    {
        cjm410_secure_zero(p_driver->format_buffer, sizeof(p_driver->format_buffer));
        return CJM410_STATUS_OVERFLOW;
    }
    status = cjm410_execute(p_driver,
                            p_driver->format_buffer,
                            p_response,
                            response_capacity,
                            CJM410_NETWORK_COMMAND_TIMEOUT_MS);
    cjm410_secure_zero(p_driver->format_buffer, sizeof(p_driver->format_buffer));
    return status;
}

/*******************************************************************************************************************//**
 * Disconnects the MQTT client.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_mqtt_disconnect(cjm410_t * p_driver)
{
    return cjm410_execute(p_driver, "AT+MQTTDISC=", NULL, 0U, 0U);
}

/*******************************************************************************************************************//**
 * Publishes an MQTT payload to a topic.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] p_topic  Null-terminated MQTT topic.
 * @param[in] p_message  Null-terminated MQTT message payload.
 * @param[in] message_id  MQTT packet identifier.
 * @param[in] qos  MQTT quality-of-service level.
 * @param[in] retained  True to request MQTT retained-message delivery.
 * @param[in] duplicated  True when the MQTT publish is a duplicate delivery.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_mqtt_publish(cjm410_t * p_driver,
                                    char const * p_topic,
                                    char const * p_message,
                                    uint16_t message_id,
                                    uint8_t qos,
                                    bool retained,
                                    bool duplicated)
{
    if (!cjm410_parameter_valid(p_topic, 1U, 128U, false) ||
        !cjm410_parameter_valid(p_message, 0U, 255U, false) ||
        (qos > 2U))
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    return cjm410_execute_format(p_driver,
                                 NULL,
                                 0U,
                                 CJM410_NETWORK_COMMAND_TIMEOUT_MS,
                                 "AT+MQTTPUB=%s,%s,%u,%u,%u,%u",
                                 p_topic,
                                 p_message,
                                 (unsigned int) message_id,
                                 (unsigned int) qos,
                                 retained ? 1U : 0U,
                                 duplicated ? 1U : 0U);
}

/*******************************************************************************************************************//**
 * Subscribes the MQTT client to a topic.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] p_topic  Null-terminated MQTT topic.
 * @param[in] qos  MQTT quality-of-service level.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_mqtt_subscribe(cjm410_t * p_driver,
                                      char const * p_topic,
                                      uint8_t qos)
{
    if (!cjm410_parameter_valid(p_topic, 1U, 128U, false) || (qos > 2U))
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    return cjm410_execute_format(p_driver, NULL, 0U, 0U,
                                 "AT+MQTTSUB=%s,%u", p_topic, (unsigned int) qos);
}

/*******************************************************************************************************************//**
 * Unsubscribes the MQTT client from a topic.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] p_topic  Null-terminated MQTT topic.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_mqtt_unsubscribe(cjm410_t * p_driver,
                                        char const * p_topic)
{
    if (!cjm410_parameter_valid(p_topic, 1U, 128U, false))
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    return cjm410_execute_format(p_driver, NULL, 0U, 0U,
                                 "AT+MQTTUNSUB=%s", p_topic);
}

/***********************************************************************************************************************
 * SSL and HTTP client commands
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * Starts an SSL client connection to a remote server.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[out] p_response  Optional destination for the raw module response.
 * @param[in] response_capacity  Capacity of p_response in bytes.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_ssl_client_start(cjm410_t * p_driver,
                                        char * p_response,
                                        size_t response_capacity)
{
    return cjm410_execute(p_driver, "AT+SSLC_START=", p_response, response_capacity, 0U);
}

/*******************************************************************************************************************//**
 * Creates an HTTP client connection.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] p_server  Null-terminated server address.
 * @param[in] ssl_context_index  Configured SSL context index.
 * @param[in] port  TCP/UDP service port.
 * @param[in] request_timeout_ms  HTTP request timeout in milliseconds.
 * @param[out] p_response  Optional destination for the raw module response.
 * @param[in] response_capacity  Capacity of p_response in bytes.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_http_connect(cjm410_t * p_driver,
                                    char const * p_server,
                                    uint8_t ssl_context_index,
                                    uint16_t port,
                                    uint32_t request_timeout_ms,
                                    char * p_response,
                                    size_t response_capacity)
{
    if (!cjm410_parameter_valid(p_server, 1U, 180U, false) ||
        (0U == ssl_context_index) || (0U == port) || (0U == request_timeout_ms))
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    return cjm410_execute_format(p_driver,
                                 p_response,
                                 response_capacity,
                                 request_timeout_ms + 1000U,
                                 "AT+HTTPC_CONN=%s,%u,%u,%lu",
                                 p_server,
                                 (unsigned int) ssl_context_index,
                                 (unsigned int) port,
                                 (unsigned long) request_timeout_ms);
}

/*******************************************************************************************************************//**
 * Closes an HTTP client connection.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] client_index  HTTP client index.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_http_disconnect(cjm410_t * p_driver, uint8_t client_index)
{
    if ((client_index < 1U) || (client_index > 4U))
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    return cjm410_execute_format(p_driver, NULL, 0U, 0U,
                                 "AT+HTTPC_DISC=%u", (unsigned int) client_index);
}

/*******************************************************************************************************************//**
 * Executes an HTTP request using a configured client.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] method  HTTP request method.
 * @param[in] client_index  HTTP client index.
 * @param[in] p_url  Null-terminated HTTP resource URL.
 * @param[out] p_response  Optional destination for the raw module response.
 * @param[in] response_capacity  Capacity of p_response in bytes.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_http_request(cjm410_t * p_driver,
                                    cjm410_http_method_t method,
                                    uint8_t client_index,
                                    char const * p_url,
                                    char * p_response,
                                    size_t response_capacity)
{
    static char const * const method_names[] = {"GET", "POST", "PUT", "PATCH"};
    if (((uint32_t) method >= (sizeof(method_names) / sizeof(method_names[0]))) ||
        (client_index < 1U) || (client_index > 4U) ||
        !cjm410_parameter_valid(p_url, 1U, 220U, false))
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    return cjm410_execute_format(p_driver,
                                 p_response,
                                 response_capacity,
                                 CJM410_NETWORK_COMMAND_TIMEOUT_MS,
                                 "AT+HTTPC_%s=%u,%s",
                                 method_names[method],
                                 (unsigned int) client_index,
                                 p_url);
}

/*******************************************************************************************************************//**
 * Sets an HTTP client parameter.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] client_index  HTTP client index.
 * @param[in] p_key  Null-terminated HTTP parameter name.
 * @param[in] p_value  Null-terminated parameter or header value.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_http_set_parameter(cjm410_t * p_driver,
                                          uint8_t client_index,
                                          char const * p_key,
                                          char const * p_value)
{
    if ((client_index < 1U) || (client_index > 4U) ||
        !cjm410_parameter_valid(p_key, 1U, 80U, false) ||
        !cjm410_parameter_valid(p_value, 0U, 180U, false))
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    return cjm410_execute_format(p_driver, NULL, 0U, 0U,
                                 "AT+HTTPC_SETPARAM=%u,%s,%s",
                                 (unsigned int) client_index, p_key, p_value);
}

/*******************************************************************************************************************//**
 * Adds one HTTP request header.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] client_index  HTTP client index.
 * @param[in] p_name  Null-terminated parameter or header name.
 * @param[in] p_value  Null-terminated parameter or header value.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_http_add_header(cjm410_t * p_driver,
                                       uint8_t client_index,
                                       char const * p_name,
                                       char const * p_value)
{
    if ((client_index < 1U) || (client_index > 4U) ||
        !cjm410_parameter_valid(p_name, 1U, 80U, false) ||
        !cjm410_parameter_valid(p_value, 1U, 180U, false))
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    return cjm410_execute_format(p_driver, NULL, 0U, 0U,
                                 "AT+HTTPC_ADDHEADER=%u,%s,%s",
                                 (unsigned int) client_index, p_name, p_value);
}

/*******************************************************************************************************************//**
 * Clears all configured HTTP request headers.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] client_index  HTTP client index.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_http_clear_headers(cjm410_t * p_driver,
                                          uint8_t client_index)
{
    if ((client_index < 1U) || (client_index > 4U))
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    return cjm410_execute_format(p_driver, NULL, 0U, 0U,
                                 "AT+HTTPC_CLEARHEADER=%u", (unsigned int) client_index);
}

/*******************************************************************************************************************//**
 * Sets the HTTP request body.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] client_index  HTTP client index.
 * @param[in] p_content  Null-terminated HTTP request body.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_http_set_body(cjm410_t * p_driver,
                                     uint8_t client_index,
                                     char const * p_content)
{
    if ((client_index < 1U) || (client_index > 4U) ||
        !cjm410_parameter_valid(p_content, 0U, 400U, true))
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    return cjm410_execute_format(p_driver, NULL, 0U, 0U,
                                 "AT+HTTPC_SETBODY=%u,%s",
                                 (unsigned int) client_index, p_content);
}

/***********************************************************************************************************************
 * SNTP commands
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * Enables or disables the SNTP client.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] enabled  True to enable the feature; false to disable it.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_sntp_enable(cjm410_t * p_driver, bool enabled)
{
    return cjm410_execute_format(p_driver, NULL, 0U, 0U,
                                 "AT+SNTPC=%u", enabled ? 1U : 0U);
}

/*******************************************************************************************************************//**
 * Sets the SNTP UTC offset and optional daylight-saving offset.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] p_utc_offset  Signed UTC offset string.
 * @param[in] daylight_saving  True to enable daylight-saving adjustment.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_sntp_set_zone(cjm410_t * p_driver,
                                     char const * p_utc_offset,
                                     bool daylight_saving)
{
    if (!cjm410_utc_offset_valid(p_utc_offset))
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    return cjm410_execute_format(p_driver, NULL, 0U, 0U,
                                 "AT+SNTP_ZONE=%s,%u",
                                 p_utc_offset,
                                 daylight_saving ? 1U : 0U);
}

/*******************************************************************************************************************//**
 * Reads the current SNTP date and time.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[out] p_response  Optional destination for the raw module response.
 * @param[in] response_capacity  Capacity of p_response in bytes.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_sntp_get_time(cjm410_t * p_driver,
                                     char * p_response,
                                     size_t response_capacity)
{
    return cjm410_execute(p_driver, "AT+SNTP_GETTIME=", p_response, response_capacity, 0U);
}

/*******************************************************************************************************************//**
 * Reads the current SNTP time of day.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[out] p_response  Optional destination for the raw module response.
 * @param[in] response_capacity  Capacity of p_response in bytes.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_sntp_get_time_of_day(cjm410_t * p_driver,
                                            char * p_response,
                                            size_t response_capacity)
{
    return cjm410_execute(p_driver,
                          "AT+SNTP_GETTIMEOFDAY=",
                          p_response,
                          response_capacity,
                          0U);
}

/* UART and management commands. */
/***********************************************************************************************************************
 * Module configuration and lifecycle commands
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * Reads the current CJM410 high-speed UART configuration.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[out] p_response  Optional destination for the raw module response.
 * @param[in] response_capacity  Capacity of p_response in bytes.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_get_hsuart_config(cjm410_t * p_driver,
                                         char * p_response,
                                         size_t response_capacity)
{
    return cjm410_execute(p_driver, "AT+HSUART=?", p_response, response_capacity, 0U);
}

/*******************************************************************************************************************//**
 * Programs the CJM410 high-speed UART configuration.
 *
 * This only programs the module. The RA6M5 SCI instance must be kept at the
 * same baud rate. The Smart Relay integration uses 115200, flow control off.
 **********************************************************************************************************************/
cjm410_status_t cjm410_set_hsuart_config(cjm410_t * p_driver,
                                         uint32_t baudrate,
                                         bool rts_cts_enabled)
{
    if ((NULL == p_driver) || !p_driver->initialized ||
        !cjm410_hsuart_baud_valid(baudrate))
    {
        return CJM410_STATUS_INVALID_ARG;
    }

    return cjm410_execute_format(p_driver,
                                 NULL,
                                 0U,
                                 0U,
                                 "AT+HSUART=%lu,%u",
                                 (unsigned long) baudrate,
                                 rts_cts_enabled ? 1U : 0U);
}

/*******************************************************************************************************************//**
 * Enables or disables CJM410 debug output.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] enabled  True to enable the feature; false to disable it.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_set_debug_output(cjm410_t * p_driver, bool enabled)
{
    return cjm410_execute_format(p_driver, NULL, 0U, 0U,
                                 "AT+DBG=%u", enabled ? 1U : 0U);
}

/*******************************************************************************************************************//**
 * Saves the active configuration to nonvolatile storage.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_save(cjm410_t * p_driver)
{
    return cjm410_execute(p_driver, "AT+SAVE=", NULL, 0U, 0U);
}

/*******************************************************************************************************************//**
 * Requests a CJM410 software reset and waits for the module to boot.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_reset(cjm410_t * p_driver)
{
    return cjm410_execute_reboot(p_driver, "AT+RST=");
}

/*******************************************************************************************************************//**
 * Applies the staged configuration and waits for the module to reboot.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_apply(cjm410_t * p_driver)
{
    return cjm410_execute_reboot(p_driver, "AT+APPLY=");
}

/*******************************************************************************************************************//**
 * Restores factory defaults and waits for the module to reboot.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_restore_factory_defaults(cjm410_t * p_driver)
{
    return cjm410_execute_reboot(p_driver, "AT+DEF=");
}

/*******************************************************************************************************************//**
 * Starts an over-the-air firmware update.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] p_tftp_ip  TFTP server IPv4 address containing the firmware image.
 * @param[in] p_file_name  Firmware image file name on the TFTP server.
 *
 * @retval CJM410_STATUS_OK Operation completed successfully.
 * @return A validation, state, transport, timeout, protocol, overflow, unsupported-command, or module AT error.
 **********************************************************************************************************************/
cjm410_status_t cjm410_ota_update(cjm410_t * p_driver,
                                  char const * p_tftp_ip,
                                  char const * p_file_name)
{
    if (!cjm410_ipv4_valid(p_tftp_ip) ||
        !cjm410_parameter_valid(p_file_name, 1U, 180U, false))
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    return cjm410_execute_format(p_driver,
                                 NULL,
                                 0U,
                                 CJM410_NETWORK_COMMAND_TIMEOUT_MS,
                                 "AT+OTA=%s,%s",
                                 p_tftp_ip,
                                 p_file_name);
}

/***********************************************************************************************************************
 * Diagnostics and text conversion helpers
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * Reports that a typed RSSI query is not defined by the available AT v2.6 command set.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[out] p_response  Optional destination for the raw module response.
 * @param[in] response_capacity  Capacity of p_response in bytes.
 *
 * @retval CJM410_STATUS_UNSUPPORTED RSSI query is not mapped because AT Commands v2.6 defines no RSSI command.
 **********************************************************************************************************************/
cjm410_status_t cjm410_get_rssi(cjm410_t * p_driver,
                                char * p_response,
                                size_t response_capacity)
{
    (void) p_driver;
    (void) p_response;
    (void) response_capacity;
    return CJM410_STATUS_UNSUPPORTED;
}

/*******************************************************************************************************************//**
 * Converts a portable driver status value to readable text.
 *
 * @param[in] status  Portable driver status value.
 *
 * @return Pointer to a constant readable string.
 **********************************************************************************************************************/
char const * cjm410_status_string(cjm410_status_t status)
{
    switch (status)
    {
        case CJM410_STATUS_OK:             return "OK";
        case CJM410_STATUS_INVALID_ARG:    return "INVALID_ARG";
        case CJM410_STATUS_TIMEOUT:        return "TIMEOUT";
        case CJM410_STATUS_IO_ERROR:       return "IO_ERROR";
        case CJM410_STATUS_PROTOCOL_ERROR: return "PROTOCOL_ERROR";
        case CJM410_STATUS_OVERFLOW:       return "OVERFLOW";
        case CJM410_STATUS_UNSUPPORTED:    return "UNSUPPORTED";
        case CJM410_STATUS_NOT_READY:      return "NOT_READY";
        case CJM410_STATUS_BUSY:           return "BUSY";
        case CJM410_STATUS_AT_ERROR:       return "AT_ERROR";
        default:                           return "UNKNOWN_STATUS";
    }
}

/*******************************************************************************************************************//**
 * Converts a detected command profile to readable text.
 *
 * @param[in] profile  Detected command profile value.
 *
 * @return Pointer to a constant readable string.
 **********************************************************************************************************************/
char const * cjm410_profile_string(cjm410_profile_t profile)
{
    switch (profile)
    {
        case CJM410_PROFILE_AT_V2_6:           return "CJM410_AT_V2_6";
        case CJM410_PROFILE_GENERIC_SHELL:      return "LEGACY_GENERIC_SHELL";
        case CJM410_PROFILE_QCA_HOSTLESS_SHELL: return "LEGACY_QCA_SHELL";
        default:                                return "UNKNOWN";
    }
}

/*******************************************************************************************************************//**
 * Converts a CJM410 AT error value to readable text.
 *
 * @param[in] error  CJM410 AT error value.
 *
 * @return Pointer to a constant readable string.
 **********************************************************************************************************************/
char const * cjm410_at_error_string(cjm410_at_error_t error)
{
    switch (error)
    {
        case CJM410_AT_ERROR_NONE:                return "NONE";
        case CJM410_AT_ERROR_INVALID_COMMAND:     return "INVALID_COMMAND";
        case CJM410_AT_ERROR_INVALID_PARAMETERS:  return "INVALID_PARAMETERS";
        case CJM410_AT_ERROR_FORBIDDEN_OPERATION: return "FORBIDDEN_OPERATION";
        case CJM410_AT_ERROR_SYSTEM_OPERATION:    return "SYSTEM_OPERATION_ERROR";
        default:                                  return "UNKNOWN_AT_ERROR";
    }
}

/***********************************************************************************************************************
 * Private function definitions
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * Feeds one received byte into the line-oriented response parser.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] byte  Received UART byte.
 *
 * @return Parser terminal state after processing the supplied data.
 **********************************************************************************************************************/
static cjm410_terminal_t cjm410_feed_byte(cjm410_t * p_driver, uint8_t byte)
{
    cjm410_terminal_t terminal = CJM410_TERMINAL_NONE;

    if (('\r' == (char) byte) || ('\n' == (char) byte))
    {
        if ((p_driver->line_length > 0U) || p_driver->line_overflow)
        {
            if (p_driver->line_overflow)
            {
                terminal = CJM410_TERMINAL_OVERFLOW;
            }
            else
            {
                p_driver->line_buffer[p_driver->line_length] = '\0';
                terminal = cjm410_classify_line(p_driver, p_driver->line_buffer);
                cjm410_dispatch_line(p_driver);
            }
            p_driver->line_length   = 0U;
            p_driver->line_overflow = false;
        }
    }
    else if (p_driver->line_length < (sizeof(p_driver->line_buffer) - 1U))
    {
        p_driver->line_buffer[p_driver->line_length++] = (char) byte;
    }
    else
    {
        p_driver->line_overflow = true;
    }
    return terminal;
}

/*******************************************************************************************************************//**
 * Classifies one complete response line and detects terminal responses.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] p_line  Null-terminated response line.
 *
 * @return Parser terminal state after processing the supplied data.
 **********************************************************************************************************************/
static cjm410_terminal_t cjm410_classify_line(cjm410_t * p_driver, char const * p_line)
{
    char const * p;
    int value = 0;
    bool negative = false;
    bool has_digit = false;

    if (cjm410_line_starts_case(p_line, "+ok"))
    {
        p = cjm410_find_case(p_line, "+ok");
        if ((NULL != p) && (('\0' == p[3]) || ('=' == p[3]) || isspace((unsigned char) p[3])))
        {
            return CJM410_TERMINAL_SUCCESS;
        }
    }
    /* Accept the conventional response used by a basic AT probe as well. */
    if (cjm410_line_starts_case(p_line, "ok") &&
        (('\0' == p_line[2]) || ('=' == p_line[2]) ||
         isspace((unsigned char) p_line[2])))
    {
        return CJM410_TERMINAL_SUCCESS;
    }
    if (!cjm410_line_starts_case(p_line, "+err"))
    {
        return CJM410_TERMINAL_NONE;
    }

    p = cjm410_find_case(p_line, "+err");
    p = (NULL != p) ? p + 4 : p_line;
    while (isspace((unsigned char) *p))
    {
        p++;
    }
    if ('=' == *p)
    {
        p++;
    }
    while (isspace((unsigned char) *p))
    {
        p++;
    }
    if ('-' == *p)
    {
        negative = true;
        p++;
    }
    while (isdigit((unsigned char) *p))
    {
        has_digit = true;
        value = (value * 10) + (*p - '0');
        p++;
    }
    if (has_digit)
    {
        value = negative ? -value : value;
        switch (value)
        {
            case -1: p_driver->last_at_error = CJM410_AT_ERROR_INVALID_COMMAND; break;
            case -2: p_driver->last_at_error = CJM410_AT_ERROR_INVALID_PARAMETERS; break;
            case -3: p_driver->last_at_error = CJM410_AT_ERROR_FORBIDDEN_OPERATION; break;
            case -4: p_driver->last_at_error = CJM410_AT_ERROR_SYSTEM_OPERATION; break;
            default: p_driver->last_at_error = CJM410_AT_ERROR_UNKNOWN; break;
        }
    }
    else
    {
        p_driver->last_at_error = CJM410_AT_ERROR_UNKNOWN;
    }
    return CJM410_TERMINAL_AT_ERROR;
}

/*******************************************************************************************************************//**
 * Forwards one asynchronous response line to the registered application callback.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 **********************************************************************************************************************/
static void cjm410_dispatch_line(cjm410_t * p_driver)
{
    if ((NULL != p_driver->config.event_callback) && (p_driver->line_length > 0U))
    {
        p_driver->config.event_callback(p_driver->config.p_event_context,
                                        p_driver->line_buffer);
    }
}

/*******************************************************************************************************************//**
 * Discards bytes pending in the transport receive buffer.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 **********************************************************************************************************************/
static void cjm410_drain_pending(cjm410_t * p_driver)
{
    uint8_t buffer[32];
    size_t count;
    do
    {
        size_t index;
        count = p_driver->transport.read(p_driver->transport.p_context,
                                         buffer,
                                         sizeof(buffer));
        for (index = 0U; index < count; index++)
        {
            (void) cjm410_feed_byte(p_driver, buffer[index]);
        }
    } while (count > 0U);
}

/*******************************************************************************************************************//**
 * Checks whether a response line starts with a token without case sensitivity.
 *
 * @param[in] p_line  Null-terminated response line.
 * @param[in] p_token  Null-terminated token.
 **********************************************************************************************************************/
static bool cjm410_line_starts_case(char const * p_line, char const * p_token)
{
    if ((NULL == p_line) || (NULL == p_token))
    {
        return false;
    }
    while (isspace((unsigned char) *p_line))
    {
        p_line++;
    }
    while ('\0' != *p_token)
    {
        if (tolower((unsigned char) *p_line) != tolower((unsigned char) *p_token))
        {
            return false;
        }
        p_line++;
        p_token++;
    }
    return true;
}

/*******************************************************************************************************************//**
 * Finds a token in text without case sensitivity.
 *
 * @param[in] p_text  Null-terminated text to search.
 * @param[in] p_token  Null-terminated token.
 **********************************************************************************************************************/
static char const * cjm410_find_case(char const * p_text, char const * p_token)
{
    size_t token_length;
    size_t index;
    if ((NULL == p_text) || (NULL == p_token))
    {
        return NULL;
    }
    token_length = strlen(p_token);
    if (0U == token_length)
    {
        return p_text;
    }
    while ('\0' != *p_text)
    {
        for (index = 0U; index < token_length; index++)
        {
            if (('\0' == p_text[index]) ||
                (tolower((unsigned char) p_text[index]) !=
                 tolower((unsigned char) p_token[index])))
            {
                break;
            }
        }
        if (index == token_length)
        {
            return p_text;
        }
        p_text++;
    }
    return NULL;
}

/*******************************************************************************************************************//**
 * Validates a string parameter and rejects command-injection characters.
 *
 * @param[in] p_value  Null-terminated parameter or header value.
 * @param[in] min_length  Minimum accepted string length.
 * @param[in] max_length  Maximum accepted string length.
 * @param[in] allow_comma  True when commas are permitted.
 **********************************************************************************************************************/
static bool cjm410_parameter_valid(char const * p_value,
                                   size_t min_length,
                                   size_t max_length,
                                   bool allow_comma)
{
    size_t length;
    size_t index;
    if (NULL == p_value)
    {
        return false;
    }
    length = strlen(p_value);
    if ((length < min_length) || (length > max_length))
    {
        return false;
    }
    for (index = 0U; index < length; index++)
    {
        unsigned char value = (unsigned char) p_value[index];
        if ((value < 0x20U) || (value > 0x7EU) ||
            (!allow_comma && (',' == (char) value)))
        {
            return false;
        }
    }
    return true;
}

/*******************************************************************************************************************//**
 * Validates dotted-decimal IPv4 syntax and octet ranges.
 *
 * @param[in] p_ip  Null-terminated dotted-decimal IPv4 address.
 **********************************************************************************************************************/
static bool cjm410_ipv4_valid(char const * p_ip)
{
    uint32_t octet = 0U;
    uint32_t digits = 0U;
    uint32_t separators = 0U;
    char const * p = p_ip;
    if ((NULL == p) || ('\0' == *p))
    {
        return false;
    }
    while ('\0' != *p)
    {
        if (isdigit((unsigned char) *p))
        {
            octet = (octet * 10U) + (uint32_t) (*p - '0');
            digits++;
            if ((digits > 3U) || (octet > 255U))
            {
                return false;
            }
        }
        else if ('.' == *p)
        {
            if ((0U == digits) || (separators >= 3U))
            {
                return false;
            }
            separators++;
            octet = 0U;
            digits = 0U;
        }
        else
        {
            return false;
        }
        p++;
    }
    return (3U == separators) && (digits > 0U);
}

/*******************************************************************************************************************//**
 * Validates a signed UTC offset string.
 *
 * @param[in] p_offset  Signed UTC offset string.
 **********************************************************************************************************************/
static bool cjm410_utc_offset_valid(char const * p_offset)
{
    uint32_t hour;
    uint32_t minute;
    if ((NULL == p_offset) || (9U != strlen(p_offset)) ||
        ('U' != p_offset[0]) || ('T' != p_offset[1]) || ('C' != p_offset[2]) ||
        (('+' != p_offset[3]) && ('-' != p_offset[3])) ||
        (':' != p_offset[6]) ||
        !isdigit((unsigned char) p_offset[4]) ||
        !isdigit((unsigned char) p_offset[5]) ||
        !isdigit((unsigned char) p_offset[7]) ||
        !isdigit((unsigned char) p_offset[8]))
    {
        return false;
    }
    hour   = ((uint32_t) (p_offset[4] - '0') * 10U) + (uint32_t) (p_offset[5] - '0');
    minute = ((uint32_t) (p_offset[7] - '0') * 10U) + (uint32_t) (p_offset[8] - '0');
    return (hour <= 14U) && (minute <= 59U);
}

/*******************************************************************************************************************//**
 * Checks whether a baud rate is supported by CJM410 AT v2.6.
 *
 * @param[in] baudrate  Requested high-speed UART baud rate.
 **********************************************************************************************************************/
static bool cjm410_hsuart_baud_valid(uint32_t baudrate)
{
    static uint32_t const supported[] =
    {
        115200U, 230400U, 380400U, 460800U,
        921600U, 1843200U, 2000000U, 3000000U
    };
    size_t index;
    for (index = 0U; index < (sizeof(supported) / sizeof(supported[0])); index++)
    {
        if (baudrate == supported[index])
        {
            return true;
        }
    }
    return false;
}

/*******************************************************************************************************************//**
 * Formats an AT command safely and executes it through the shared command engine.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[out] p_response  Optional destination for the raw module response.
 * @param[in] response_capacity  Capacity of p_response in bytes.
 * @param[in] timeout_ms  Operation timeout in milliseconds; zero selects the configured default where supported.
 * @param[in] p_format  printf-style AT command format string.
 * @param[in] ...  Values consumed by p_format.
 **********************************************************************************************************************/
static cjm410_status_t cjm410_execute_format(cjm410_t * p_driver,
                                             char * p_response,
                                             size_t response_capacity,
                                             uint32_t timeout_ms,
                                             char const * p_format,
                                             ...)
{
    va_list args;
    int written;
    cjm410_status_t status;

    if ((NULL == p_driver) || !p_driver->initialized || (NULL == p_format))
    {
        return CJM410_STATUS_INVALID_ARG;
    }
    va_start(args, p_format);
    written = vsnprintf(p_driver->format_buffer,
                        sizeof(p_driver->format_buffer),
                        p_format,
                        args);
    va_end(args);
    if ((written < 0) || ((size_t) written >= sizeof(p_driver->format_buffer)))
    {
        cjm410_secure_zero(p_driver->format_buffer, sizeof(p_driver->format_buffer));
        return CJM410_STATUS_OVERFLOW;
    }
    status = cjm410_execute(p_driver,
                            p_driver->format_buffer,
                            p_response,
                            response_capacity,
                            timeout_ms);
    cjm410_secure_zero(p_driver->format_buffer, sizeof(p_driver->format_buffer));
    return status;
}

/*******************************************************************************************************************//**
 * Executes a rebooting command, waits for boot, and resets runtime mode state.
 *
 * @param[in,out] p_driver  CJM410 portable driver instance.
 * @param[in] p_command  Null-terminated AT command without CR or LF.
 **********************************************************************************************************************/
static cjm410_status_t cjm410_execute_reboot(cjm410_t * p_driver,
                                             char const * p_command)
{
    cjm410_status_t status;
    cjm410_status_t verify_status;

    status = cjm410_execute(p_driver, p_command, NULL, 0U, 0U);

    /*
     * AT+APPLY=/AT+RST= can reboot before a terminal +ok is parsed.  A timeout
     * or protocol-only result is therefore allowed to continue into the boot
     * recovery path; a real AT/I/O/argument error is not.
     */
    if ((CJM410_STATUS_OK != status) &&
        (CJM410_STATUS_TIMEOUT != status) &&
        (CJM410_STATUS_PROTOCOL_ERROR != status))
    {
        return status;
    }

    p_driver->transport.delay_ms(p_driver->transport.p_context,
                                 p_driver->config.boot_wait_ms);

    /* FW 3.0.8 boots into transparent/data mode. */
    p_driver->transparent_mode = true;
    p_driver->profile          = CJM410_PROFILE_UNKNOWN;
    p_driver->last_at_error    = CJM410_AT_ERROR_NONE;
    cjm410_drain_pending(p_driver);

    /* Restore the control plane so callers may immediately issue AT queries. */
    verify_status = cjm410_enter_command_mode(p_driver);
    if (CJM410_STATUS_OK != verify_status)
    {
        return verify_status;
    }

    p_driver->profile           = CJM410_PROFILE_AT_V2_6;
    p_driver->detected_baudrate = CJM410_HSUART_BAUDRATE;
    return CJM410_STATUS_OK;
}

/*******************************************************************************************************************//**
 * Sends the documented transparent-mode escape sequence with guard times.
 *
 * @param[in,out] p_driver  Initialized CJM410 portable driver instance.
 *
 * @retval CJM410_STATUS_OK       The three escape bytes were transmitted.
 * @retval CJM410_STATUS_IO_ERROR The transport could not transmit the escape bytes.
 **********************************************************************************************************************/
static cjm410_status_t cjm410_send_command_mode_escape(cjm410_t * p_driver)
{
    static uint8_t const escape[] = {'+', '+', '+'};

    cjm410_drain_pending(p_driver);
    p_driver->transport.delay_ms(p_driver->transport.p_context,
                                 p_driver->config.command_mode_guard_ms);

    if (0 != p_driver->transport.write(p_driver->transport.p_context,
                                       escape,
                                       sizeof(escape),
                                       p_driver->config.command_timeout_ms))
    {
        return CJM410_STATUS_IO_ERROR;
    }

    p_driver->transport.delay_ms(p_driver->transport.p_context,
                                 p_driver->config.command_mode_guard_ms);
    p_driver->transparent_mode = false;
    cjm410_drain_pending(p_driver);
    return CJM410_STATUS_OK;
}

/*******************************************************************************************************************//**
 * Erases sensitive command data using volatile writes.
 *
 * @param[out] p_data  Application data buffer.
 * @param[in] length  Number of data bytes.
 **********************************************************************************************************************/
static void cjm410_secure_zero(void * p_data, size_t length)
{
    volatile uint8_t * p = (volatile uint8_t *) p_data;
    while (length > 0U)
    {
        *p++ = 0U;
        length--;
    }
}

/*******************************************************************************************************************//**
 * Maps a Wi-Fi security enum to the CJM410 AT token.
 *
 * @param[in] security  Requested Wi-Fi security mode.
 **********************************************************************************************************************/
static char const * cjm410_security_name(cjm410_security_t security)
{
    switch (security)
    {
        case CJM410_SECURITY_NONE: return "NONE";
        case CJM410_SECURITY_WEP:  return "WEP";
        case CJM410_SECURITY_WPA:  return "WPA";
        case CJM410_SECURITY_WPA2: return "WPA2";
        default:                   return NULL;
    }
}

/*******************************************************************************************************************//**
 * Maps a Wi-Fi cipher enum to the CJM410 AT token.
 *
 * @param[in] cipher  Requested Wi-Fi cipher. Updating monitoring and debugging your Nordic devices in the field is about to get a whole lot easier, introducing NRF cloud now pound by men fault. Developers building on NRF fifty four NRF fifty three NRF fifty two and NRF ninety one series devices can now collect performance data and deploy updates seamlessly with central integration and exclusive nordic pricing that starts free and scales for just cents per device launch faster ship updates with confidence and resolve issues in the field with NRF cloud powered by Memfault. Discover more at NRFCloudcom
 **********************************************************************************************************************/
static char const * cjm410_cipher_name(cjm410_cipher_t cipher)
{
    switch (cipher)
    {
        case CJM410_CIPHER_TKIP: return "TKIP";
        case CJM410_CIPHER_CCMP: return "CCMP";
        default:                 return NULL;
    }
}

/*******************************************************************************************************************//**
 * Maps a socket protocol enum to the CJM410 AT token.
 *
 * @param[in] protocol  Requested socket protocol.
 **********************************************************************************************************************/
static char const * cjm410_socket_name(cjm410_socket_protocol_t protocol)
{
    switch (protocol)
    {
        case CJM410_SOCKET_TCP:   return "TCP";
        case CJM410_SOCKET_UDP:   return "UDP";
        case CJM410_SOCKET_MQTT:  return "MQTT";
        case CJM410_SOCKET_HTTPC: return "HTTPC";
        default:                  return NULL;
    }
}
