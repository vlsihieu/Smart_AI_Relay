/*******************************************************************************************************************//**
 * @file cjm410_ep.c
 * @brief Implements the Smart Relay middleware endpoint for the CJM410 Wi-Fi module.
 *
 * This IPC module owns the CJM410 portable driver, the Renesas RA6M5 UART port, and the transport interface that
 * connects them. It exposes high-level Wi-Fi use cases to the HLD application while keeping AT-command formatting,
 * response parsing, UART callbacks, and GPIO reset control below the application boundary. All public APIs execute in
 * foreground context; the RA6M5 UART callback only transfers received bytes into the port ring buffer.
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/

#include <Appllication/inc/cjm410_ep.h>
#include "cjm410_ra6m5_port.h"

#include <string.h>

/***********************************************************************************************************************
 * Private global variables
 **********************************************************************************************************************/

static cjm410_t            g_cjm410_driver;         ///< Endpoint-owned portable CJM410 AT-command driver.
static cjm410_ra6m5_port_t g_cjm410_port;           ///< Endpoint-owned Renesas RA6M5 UART-only port.
static cjm410_transport_t  g_cjm410_transport;      ///< Transport callbacks binding the driver to the RA6M5 port.
static bool                g_cjm410_ep_initialized; ///< True after the port and portable driver initialize successfully.

/***********************************************************************************************************************
 * Private function definitions
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * Stores the first failed basic-test step and the latest CJM410 AT error.
 *
 * @param[out] p_result  Test-result object updated with failure information.
 * @param[in]  step      Basic-test step that failed.
 * @param[in]  status    Driver status returned by the failed operation.
 *
 * @return The unchanged status supplied by the caller.
 **********************************************************************************************************************/
static cjm410_status_t cjm410_ep_test_fail(cjm410_ep_test_result_t * p_result,
                                           cjm410_ep_test_step_t step,
                                           cjm410_status_t status)
{
    p_result->status      = status;
    p_result->failed_step = step;
    p_result->at_error    = cjm410_last_at_error_get(&g_cjm410_driver);
    return status;
}

/***********************************************************************************************************************
 * Public API definitions
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * Initializes the RA6M5 port, creates the transport table, and initializes the portable CJM410 driver.
 *
 * @param[in] p_uart  FSP SCI6 UART instance connected to CJM410 HSUART pins 2/3.
 *
 * @retval CJM410_STATUS_OK   Endpoint initialized successfully.
 * @retval CJM410_STATUS_BUSY Endpoint has already been initialized.
 * @return Any error returned by the RA6M5 port or portable CJM410 driver.
 **********************************************************************************************************************/
cjm410_status_t cjm410_ep_init(uart_instance_t const * p_uart)
{
    cjm410_config_t config;
    cjm410_status_t status;

    if (g_cjm410_ep_initialized)
    {
        return CJM410_STATUS_BUSY;
    }

    status = cjm410_ra6m5_port_init(&g_cjm410_port, p_uart);
    if (CJM410_STATUS_OK != status)
    {
        return status;
    }

    cjm410_ra6m5_make_transport(&g_cjm410_port, &g_cjm410_transport);
    cjm410_config_default(&config);
    /* Wi-Fi association and FW3.0.8 boot logs can extend module readiness. */
    config.boot_wait_ms = CJM410_RA6M5_BOOT_WAIT_MS;
    status = cjm410_init(&g_cjm410_driver, &g_cjm410_transport, &config);
    if (CJM410_STATUS_OK != status)
    {
        (void) cjm410_ra6m5_port_deinit(&g_cjm410_port);
        memset(&g_cjm410_driver, 0, sizeof(g_cjm410_driver));
        memset(&g_cjm410_transport, 0, sizeof(g_cjm410_transport));
        return status;
    }

    g_cjm410_ep_initialized = true;
    return CJM410_STATUS_OK;
}

/*******************************************************************************************************************//**
 * Deinitializes the endpoint-owned RA6M5 port and clears all internal endpoint state.
 *
 * @retval CJM410_STATUS_OK        Endpoint deinitialized successfully.
 * @retval CJM410_STATUS_NOT_READY Endpoint has not been initialized.
 * @return Any error returned while deinitializing the RA6M5 port.
 **********************************************************************************************************************/
cjm410_status_t cjm410_ep_deinit(void)
{
    cjm410_status_t status;

    if (!g_cjm410_ep_initialized)
    {
        return CJM410_STATUS_NOT_READY;
    }

    status = cjm410_ra6m5_port_deinit(&g_cjm410_port);
    memset(&g_cjm410_driver, 0, sizeof(g_cjm410_driver));
    memset(&g_cjm410_transport, 0, sizeof(g_cjm410_transport));
    g_cjm410_ep_initialized = false;
    return status;
}

/*******************************************************************************************************************//**
 * Probes CJM410 on the fixed 115200 HSUART path and verifies AT+VER=.
 *
 * @param[out] p_result  Destination for the raw response, detected profile, baud rate, and failed step.
 *
 * @retval CJM410_STATUS_OK          A valid CJM410 response was detected.
 * @retval CJM410_STATUS_INVALID_ARG p_result is NULL.
 * @retval CJM410_STATUS_NOT_READY   Endpoint has not been initialized.
 * @return Any error returned by cjm410_auto_probe().
 **********************************************************************************************************************/
cjm410_status_t cjm410_ep_run_probe(cjm410_ep_test_result_t * p_result)
{
    cjm410_status_t status;

    if (NULL == p_result)
    {
        return CJM410_STATUS_INVALID_ARG;
    }

    memset(p_result, 0, sizeof(*p_result));
    if (!g_cjm410_ep_initialized)
    {
        p_result->status      = CJM410_STATUS_NOT_READY;
        p_result->failed_step = CJM410_EP_TEST_STEP_INIT;
        return p_result->status;
    }

    status = cjm410_auto_probe(&g_cjm410_driver,
                               p_result->response,
                               sizeof(p_result->response));
    p_result->status   = status;
    p_result->at_error = cjm410_last_at_error_get(&g_cjm410_driver);
    p_result->profile  = g_cjm410_driver.profile;
    p_result->baudrate = g_cjm410_driver.detected_baudrate;
    p_result->failed_step = (CJM410_STATUS_OK == status) ?
                            CJM410_EP_TEST_STEP_NONE : CJM410_EP_TEST_STEP_PROBE;
    return status;
}

/*******************************************************************************************************************//**
 * Reads CJM410 module information after communication has already been probed.
 *
 * This function intentionally does not call cjm410_auto_probe().
 *
 * @param[in,out] p_result  Destination for version, MAC, mode, IP, HSUART configuration and failure information.
 *
 * @retval CJM410_STATUS_OK          All information queries completed successfully.
 * @retval CJM410_STATUS_INVALID_ARG p_result is NULL.
 * @retval CJM410_STATUS_NOT_READY   Endpoint has not been initialized.
 * @return Any error returned by a read-only CJM410 query.
 **********************************************************************************************************************/
cjm410_status_t cjm410_ep_read_info(cjm410_ep_test_result_t * p_result)
{
    cjm410_status_t status;

    if (NULL == p_result)
    {
        return CJM410_STATUS_INVALID_ARG;
    }

    if (!g_cjm410_ep_initialized)
    {
        p_result->status      = CJM410_STATUS_NOT_READY;
        p_result->failed_step = CJM410_EP_TEST_STEP_INIT;
        return p_result->status;
    }

    /*
     * Do not run cjm410_auto_probe() here. Wifi_Init() already established the
     * UART/AT link. Preserve the probe response for debugger inspection and
     * refresh only the read-only information fields below.
     */
    memset(p_result->version,       0, sizeof(p_result->version));
    memset(p_result->mac_address,   0, sizeof(p_result->mac_address));
    memset(p_result->wifi_mode,     0, sizeof(p_result->wifi_mode));
    memset(p_result->ip_config,     0, sizeof(p_result->ip_config));
    memset(p_result->hsuart_config, 0, sizeof(p_result->hsuart_config));

    p_result->profile     = g_cjm410_driver.profile;
    p_result->baudrate    = g_cjm410_driver.detected_baudrate;
    p_result->failed_step = CJM410_EP_TEST_STEP_NONE;

    status = cjm410_get_version(&g_cjm410_driver,
                                p_result->version,
                                sizeof(p_result->version));
    if (CJM410_STATUS_OK != status)
    {
        return cjm410_ep_test_fail(p_result, CJM410_EP_TEST_STEP_VERSION, status);
    }

    status = cjm410_get_mac_address(&g_cjm410_driver,
                                    p_result->mac_address,
                                    sizeof(p_result->mac_address));
    if (CJM410_STATUS_OK != status)
    {
        return cjm410_ep_test_fail(p_result, CJM410_EP_TEST_STEP_MAC, status);
    }

    status = cjm410_get_wifi_mode(&g_cjm410_driver,
                                  p_result->wifi_mode,
                                  sizeof(p_result->wifi_mode));
    if (CJM410_STATUS_OK != status)
    {
        return cjm410_ep_test_fail(p_result, CJM410_EP_TEST_STEP_WIFI_MODE, status);
    }

    status = cjm410_get_ip_config(&g_cjm410_driver,
                                  p_result->ip_config,
                                  sizeof(p_result->ip_config));
    if (CJM410_STATUS_OK != status)
    {
        return cjm410_ep_test_fail(p_result, CJM410_EP_TEST_STEP_IP_CONFIG, status);
    }

    /* Firmware ota_cjm410_multi_tcp_hs_v3.0.8.bin supports HSUART. */
    status = cjm410_get_hsuart_config(&g_cjm410_driver,
                                      p_result->hsuart_config,
                                      sizeof(p_result->hsuart_config));
    if (CJM410_STATUS_OK != status)
    {
        return cjm410_ep_test_fail(p_result, CJM410_EP_TEST_STEP_HSUART, status);
    }

    p_result->status      = CJM410_STATUS_OK;
    p_result->at_error    = CJM410_AT_ERROR_NONE;
    p_result->failed_step = CJM410_EP_TEST_STEP_COMPLETE;
    return CJM410_STATUS_OK;
}

/*******************************************************************************************************************//**
 * Runs the complete read-only bring-up test: probe first, then read module info.
 **********************************************************************************************************************/
cjm410_status_t cjm410_ep_run_basic_test(cjm410_ep_test_result_t * p_result)
{
    cjm410_status_t status;

    if (NULL == p_result)
    {
        return CJM410_STATUS_INVALID_ARG;
    }

    status = cjm410_ep_run_probe(p_result);
    if (CJM410_STATUS_OK != status)
    {
        return status;
    }

    return cjm410_ep_read_info(p_result);
}

/*******************************************************************************************************************//**
 * Scans the 2.4 GHz Wi-Fi environment using the documented AT+WS= command.
 **********************************************************************************************************************/
cjm410_status_t cjm410_ep_scan(char * p_response, size_t response_capacity)
{
    if (!g_cjm410_ep_initialized)
    {
        return CJM410_STATUS_NOT_READY;
    }
    return cjm410_scan(&g_cjm410_driver, NULL, p_response, response_capacity);
}

/*******************************************************************************************************************//**
 * Configures the CJM410 as a WPA2 Station and verifies the resulting Wi-Fi link state.
 *
 * @param[in]  p_ssid             Null-terminated access-point SSID.
 * @param[in]  p_passphrase       Null-terminated WPA2 passphrase.
 * @param[out] p_response         Optional destination for the final module response.
 * @param[in]  response_capacity  Capacity of p_response in bytes.
 *
 * @retval CJM410_STATUS_OK        Station configuration completed successfully.
 * @retval CJM410_STATUS_NOT_READY Endpoint has not been initialized.
 * @return Any validation, communication, protocol, or AT error returned by the portable driver.
 **********************************************************************************************************************/
cjm410_status_t cjm410_ep_connect_station_wpa2(char const * p_ssid,
                                               char const * p_passphrase,
                                               char * p_response,
                                               size_t response_capacity)
{
    if (!g_cjm410_ep_initialized)
    {
        return CJM410_STATUS_NOT_READY;
    }
    return cjm410_connect_wpa2(&g_cjm410_driver,
                               p_ssid,
                               p_passphrase,
                               p_response,
                               response_capacity);
}

/*******************************************************************************************************************//**
 * Disconnects the current Station connection.
 *
 * @retval CJM410_STATUS_OK        Disconnect command completed successfully.
 * @retval CJM410_STATUS_NOT_READY Endpoint has not been initialized.
 * @return Any validation, communication, protocol, or AT error returned by the portable driver.
 **********************************************************************************************************************/
cjm410_status_t cjm410_ep_disconnect(void)
{
    if (!g_cjm410_ep_initialized)
    {
        return CJM410_STATUS_NOT_READY;
    }

    return cjm410_disconnect(&g_cjm410_driver);
}

/*******************************************************************************************************************//**
 * Configures and starts a CJM410 WPA2 SoftAP.
 *
 * @param[in]  p_ssid             Null-terminated SoftAP SSID.
 * @param[in]  p_passphrase       Null-terminated WPA2 passphrase.
 * @param[out] p_response         Optional destination for the final module response.
 * @param[in]  response_capacity  Capacity of p_response in bytes.
 *
 * @retval CJM410_STATUS_OK        SoftAP configuration completed successfully.
 * @retval CJM410_STATUS_NOT_READY Endpoint has not been initialized.
 * @return Any validation, communication, protocol, or AT error returned by the portable driver.
 **********************************************************************************************************************/
cjm410_status_t cjm410_ep_start_soft_ap_wpa2(char const * p_ssid,
                                             char const * p_passphrase,
                                             char * p_response,
                                             size_t response_capacity)
{
    if (!g_cjm410_ep_initialized)
    {
        return CJM410_STATUS_NOT_READY;
    }
    return cjm410_start_soft_ap_wpa2(&g_cjm410_driver,
                                     p_ssid,
                                     p_passphrase,
                                     p_response,
                                     response_capacity);
}

/*******************************************************************************************************************//**
 * Reads the current CJM410 Wi-Fi link status and IPv4 configuration.
 *
 * @param[out] p_snapshot  Destination for the link status, IP configuration, and latest AT error.
 *
 * @retval CJM410_STATUS_OK          Network information was read successfully.
 * @retval CJM410_STATUS_INVALID_ARG p_snapshot is NULL.
 * @retval CJM410_STATUS_NOT_READY   Endpoint has not been initialized.
 * @return Any communication, protocol, or AT error returned by the portable driver.
 **********************************************************************************************************************/
cjm410_status_t cjm410_ep_network_snapshot_get(cjm410_ep_network_snapshot_t * p_snapshot)
{
    cjm410_status_t link_status;
    cjm410_status_t ip_status;
    cjm410_at_error_t link_at_error;
    cjm410_at_error_t ip_at_error;

    if (NULL == p_snapshot)
    {
        return CJM410_STATUS_INVALID_ARG;
    }

    memset(p_snapshot, 0, sizeof(*p_snapshot));
    if (!g_cjm410_ep_initialized)
    {
        p_snapshot->status = CJM410_STATUS_NOT_READY;
        return p_snapshot->status;
    }

    /* Always query both fields so the debugger receives as much real module state as possible. */
    link_status = cjm410_get_link_status(&g_cjm410_driver,
                                         p_snapshot->link_status,
                                         sizeof(p_snapshot->link_status));
    link_at_error = cjm410_last_at_error_get(&g_cjm410_driver);

    ip_status = cjm410_get_ip_config(&g_cjm410_driver,
                                     p_snapshot->ip_config,
                                     sizeof(p_snapshot->ip_config));
    ip_at_error = cjm410_last_at_error_get(&g_cjm410_driver);

    if (CJM410_STATUS_OK != link_status)
    {
        p_snapshot->status   = link_status;
        p_snapshot->at_error = link_at_error;
    }
    else
    {
        p_snapshot->status   = ip_status;
        p_snapshot->at_error = ip_at_error;
    }

    return p_snapshot->status;
}

/*******************************************************************************************************************//**
 * Pings one IPv4 target through the CJM410 Wi-Fi interface.
 **********************************************************************************************************************/
cjm410_status_t cjm410_ep_ping(char const * p_ipv4,
                               char * p_response,
                               size_t response_capacity)
{
    if (!g_cjm410_ep_initialized)
    {
        return CJM410_STATUS_NOT_READY;
    }
    return cjm410_ping(&g_cjm410_driver,
                       p_ipv4,
                       p_response,
                       response_capacity);
}

/*******************************************************************************************************************//**
 * Runs an end-to-end TCP echo test through CJM410 transparent data mode.
 **********************************************************************************************************************/
cjm410_status_t cjm410_ep_tcp_echo_test(cjm410_ep_tcp_echo_cfg_t const * p_cfg,
                                        cjm410_ep_tcp_echo_result_t * p_result)
{
    cjm410_status_t status;
    cjm410_status_t command_mode_status = CJM410_STATUS_OK;
    bool transparent_entered = false;

    if ((NULL == p_cfg) || (NULL == p_result))
    {
        return CJM410_STATUS_INVALID_ARG;
    }

    memset(p_result, 0, sizeof(*p_result));
    if (!g_cjm410_ep_initialized)
    {
        p_result->status = CJM410_STATUS_NOT_READY;
        return p_result->status;
    }
    if ((NULL == p_cfg->p_server_ip) || (0U == p_cfg->server_port) ||
        (NULL == p_cfg->p_payload) || (0U == p_cfg->payload_length) ||
        (p_cfg->payload_length > sizeof(p_result->rx_data)))
    {
        p_result->status = CJM410_STATUS_INVALID_ARG;
        return p_result->status;
    }

    status = cjm410_set_socket_protocol(&g_cjm410_driver, CJM410_SOCKET_TCP);
    if (CJM410_STATUS_OK == status)
    {
        status = cjm410_set_tcp_client(&g_cjm410_driver,
                                       p_cfg->p_server_ip,
                                       p_cfg->server_port);
    }
    if (CJM410_STATUS_OK == status)
    {
        /* TCP endpoint settings are applied across a module reboot. */
        status = cjm410_apply(&g_cjm410_driver);
    }
    if (CJM410_STATUS_OK == status)
    {
        status = cjm410_get_tcp_link_status(&g_cjm410_driver,
                                            p_result->link_status,
                                            sizeof(p_result->link_status));
    }
    if (CJM410_STATUS_OK == status)
    {
        status = cjm410_enter_transparent_mode(&g_cjm410_driver);
        transparent_entered = (CJM410_STATUS_OK == status);
    }
    if (CJM410_STATUS_OK == status)
    {
        status = cjm410_transparent_write(&g_cjm410_driver,
                                          p_cfg->p_payload,
                                          p_cfg->payload_length,
                                          p_cfg->timeout_ms);
        if (CJM410_STATUS_OK == status)
        {
            p_result->tx_length = p_cfg->payload_length;
        }
    }
    if (CJM410_STATUS_OK == status)
    {
        status = cjm410_transparent_read(&g_cjm410_driver,
                                         p_result->rx_data,
                                         p_cfg->payload_length,
                                         &p_result->rx_length,
                                         p_cfg->timeout_ms);
    }
    if (CJM410_STATUS_OK == status)
    {
        p_result->echo_match =
            (p_result->rx_length == p_cfg->payload_length) &&
            (0 == memcmp(p_cfg->p_payload,
                         p_result->rx_data,
                         p_cfg->payload_length));
        if (!p_result->echo_match)
        {
            status = CJM410_STATUS_PROTOCOL_ERROR;
        }
    }

    if (transparent_entered)
    {
        command_mode_status = cjm410_enter_command_mode(&g_cjm410_driver);
        if (CJM410_STATUS_OK == status)
        {
            status = command_mode_status;
        }
    }

    p_result->status   = status;
    p_result->at_error = cjm410_last_at_error_get(&g_cjm410_driver);
    return status;
}

/*******************************************************************************************************************//**
 * Configures and applies a TCP client endpoint, then returns in AT command mode.
 **********************************************************************************************************************/
cjm410_status_t cjm410_ep_tcp_client_configure(char const * p_server_ip, uint16_t server_port)
{
    cjm410_status_t status;

    if (!g_cjm410_ep_initialized)
    {
        return CJM410_STATUS_NOT_READY;
    }

    if (g_cjm410_driver.transparent_mode)
    {
        status = cjm410_enter_command_mode(&g_cjm410_driver);
        if (CJM410_STATUS_OK != status)
        {
            return status;
        }
    }

    status = cjm410_set_socket_protocol(&g_cjm410_driver, CJM410_SOCKET_TCP);
    if (CJM410_STATUS_OK == status)
    {
        status = cjm410_set_tcp_client(&g_cjm410_driver, p_server_ip, server_port);
    }
    if (CJM410_STATUS_OK == status)
    {
        status = cjm410_apply(&g_cjm410_driver);
    }
    return status;
}

cjm410_status_t cjm410_ep_tcp_link_status(char * p_response, size_t response_capacity)
{
    cjm410_status_t status;

    if (!g_cjm410_ep_initialized)
    {
        return CJM410_STATUS_NOT_READY;
    }
    if (g_cjm410_driver.transparent_mode)
    {
        status = cjm410_enter_command_mode(&g_cjm410_driver);
        if (CJM410_STATUS_OK != status)
        {
            return status;
        }
    }
    return cjm410_get_tcp_link_status(&g_cjm410_driver, p_response, response_capacity);
}

cjm410_status_t cjm410_ep_enter_command_mode(void)
{
    if (!g_cjm410_ep_initialized)
    {
        return CJM410_STATUS_NOT_READY;
    }
    return cjm410_enter_command_mode(&g_cjm410_driver);
}

cjm410_status_t cjm410_ep_enter_data_mode(void)
{
    if (!g_cjm410_ep_initialized)
    {
        return CJM410_STATUS_NOT_READY;
    }
    return cjm410_enter_transparent_mode(&g_cjm410_driver);
}

cjm410_status_t cjm410_ep_data_write(uint8_t const * p_data, size_t length, uint32_t timeout_ms)
{
    if (!g_cjm410_ep_initialized)
    {
        return CJM410_STATUS_NOT_READY;
    }
    return cjm410_transparent_write(&g_cjm410_driver, p_data, length, timeout_ms);
}

cjm410_status_t cjm410_ep_data_read(uint8_t * p_data,
                                    size_t capacity,
                                    size_t * p_received,
                                    uint32_t timeout_ms)
{
    if (!g_cjm410_ep_initialized)
    {
        return CJM410_STATUS_NOT_READY;
    }
    return cjm410_transparent_read(&g_cjm410_driver,
                                   p_data,
                                   capacity,
                                   p_received,
                                   timeout_ms);
}

/*******************************************************************************************************************//**
 * Sets the CJM410 AT v2.6 UART-to-network and network receive-check timeouts.
 *
 * @param[in] uart_to_network_ms     UART-to-network timeout in milliseconds, valid range 1 to 500.
 * @param[in] network_check_seconds  Network receive-check timeout in seconds, valid range 1 to 600.
 *
 * @retval CJM410_STATUS_OK        Both timeout commands completed successfully.
 * @retval CJM410_STATUS_NOT_READY Endpoint has not been initialized.
 * @return Any validation, communication, protocol, or AT error returned by the portable driver.
 **********************************************************************************************************************/
cjm410_status_t cjm410_ep_v26_timeouts_set(uint16_t uart_to_network_ms,
                                           uint16_t network_check_seconds)
{
    cjm410_status_t status;

    if (!g_cjm410_ep_initialized)
    {
        return CJM410_STATUS_NOT_READY;
    }

    status = cjm410_set_network_tx_timeout(&g_cjm410_driver, uart_to_network_ms);
    if (CJM410_STATUS_OK == status)
    {
        status = cjm410_set_network_receive_check_timeout(&g_cjm410_driver,
                                                          network_check_seconds);
    }
    return status;
}

/*******************************************************************************************************************//**
 * Executes one raw CJM410 AT command through the shared portable command engine.
 *
 * @param[in]  p_command          Null-terminated CJM410 command without CR/LF.
 * @param[out] p_response         Optional destination for the raw module response.
 * @param[in]  response_capacity  Capacity of p_response in bytes.
 * @param[in]  timeout_ms         Command timeout in milliseconds; use 0 for the driver default.
 *
 * @retval CJM410_STATUS_OK        The module returned a terminal +ok response.
 * @retval CJM410_STATUS_NOT_READY Endpoint has not been initialized.
 * @return Any validation, communication, timeout, protocol, overflow, or AT error returned by the command engine.
 **********************************************************************************************************************/
cjm410_status_t cjm410_ep_execute(char const * p_command,
                                  char * p_response,
                                  size_t response_capacity,
                                  uint32_t timeout_ms)
{
    if (!g_cjm410_ep_initialized)
    {
        return CJM410_STATUS_NOT_READY;
    }
    return cjm410_execute(&g_cjm410_driver,
                          p_command,
                          p_response,
                          response_capacity,
                          timeout_ms);
}

/*******************************************************************************************************************//**
 * Processes pending unsolicited CJM410 data while no synchronous command is active.
 *
 * @retval CJM410_STATUS_OK        Pending data was processed successfully or no data was available.
 * @retval CJM410_STATUS_NOT_READY Endpoint has not been initialized.
 * @return Any parser or transport status returned by the portable driver.
 **********************************************************************************************************************/
cjm410_status_t cjm410_ep_process(void)
{
    if (!g_cjm410_ep_initialized)
    {
        return CJM410_STATUS_NOT_READY;
    }
    return cjm410_process(&g_cjm410_driver);
}

/*******************************************************************************************************************//**
 * Returns read-only access to the endpoint-owned portable CJM410 driver instance.
 *
 * @return Pointer to the initialized CJM410 driver instance.
 * @retval NULL Endpoint has not been initialized.
 **********************************************************************************************************************/
cjm410_t const * cjm410_ep_driver_get(void)
{
    return g_cjm410_ep_initialized ? &g_cjm410_driver : NULL;
}
