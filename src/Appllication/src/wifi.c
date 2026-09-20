/**
 * @file wifi.c
 * @brief HLD Wi-Fi service for CJM410 FW3.0.8 over SCI6 HSUART pins 2/3.
 *
 * Layering: HLD -> IPC -> portable IP -> RA6M5 port -> g_uart_cjm410 / SCI6.
 */
#include <Appllication/inc/cjm410_ep.h>
#include <Appllication/inc/wifi.h>
#include "hal_data.h"
#include <string.h>

static bool g_wifi_initialized;
static cjm410_ep_test_result_t      g_wifi_ep_test_result;
static cjm410_ep_network_snapshot_t g_wifi_ep_network_snapshot;

volatile int32_t  g_wifi_init_cjm410_status = (int32_t) CJM410_STATUS_NOT_READY;
volatile int32_t  g_wifi_init_at_error      = (int32_t) CJM410_AT_ERROR_NONE;
volatile int32_t  g_wifi_init_failed_step   = (int32_t) CJM410_EP_TEST_STEP_NONE;
volatile uint32_t g_wifi_init_baudrate      = 0U;
volatile wifi_status_t g_wifi_status         = WIFI_STATUS_NOT_INITIALIZED;
volatile wifi_status_t g_wifi_connect_status = WIFI_STATUS_NOT_INITIALIZED;
volatile wifi_status_t g_wifi_network_status = WIFI_STATUS_NOT_INITIALIZED;
volatile wifi_status_t g_wifi_ping_status    = WIFI_STATUS_NOT_INITIALIZED;
volatile char g_wifi_dbg_link[WIFI_INFO_TEXT_SIZE];
volatile char g_wifi_dbg_ip[WIFI_INFO_TEXT_SIZE];
volatile char g_wifi_dbg_ping[WIFI_PING_RESPONSE_SIZE];

static wifi_info_t g_wifi_info;

static wifi_status_t wifi_map_status(cjm410_status_t status)
{
    if (CJM410_STATUS_OK == status)          return WIFI_STATUS_OK;
    if (CJM410_STATUS_INVALID_ARG == status) return WIFI_STATUS_INVALID_ARGUMENT;
    if (CJM410_STATUS_NOT_READY == status)   return WIFI_STATUS_NOT_INITIALIZED;
    return WIFI_STATUS_ENDPOINT_ERROR;
}

static void wifi_copy_text(char * p_dst, size_t dst_size, char const * p_src)
{
    size_t length;
    if ((NULL == p_dst) || (0U == dst_size)) return;
    if (NULL == p_src) { p_dst[0] = '\0'; return; }
    length = strlen(p_src);
    if (length >= dst_size) length = dst_size - 1U;
    memcpy(p_dst, p_src, length);
    p_dst[length] = '\0';
}

static void wifi_copy_debug(volatile char * p_dst, size_t cap, char const * p_src)
{
    size_t i = 0U;
    if ((NULL == p_dst) || (0U == cap)) return;
    if (NULL != p_src)
    {
        while ((i + 1U < cap) && ('\0' != p_src[i])) { p_dst[i] = p_src[i]; i++; }
    }
    p_dst[i] = '\0';
}

wifi_status_t Wifi_Init(void)
{
    cjm410_status_t status;
    if (g_wifi_initialized) return WIFI_STATUS_OK;

    memset(&g_wifi_ep_test_result, 0, sizeof(g_wifi_ep_test_result));
    g_wifi_init_cjm410_status = (int32_t) CJM410_STATUS_NOT_READY;
    g_wifi_init_at_error      = (int32_t) CJM410_AT_ERROR_NONE;
    g_wifi_init_failed_step   = (int32_t) CJM410_EP_TEST_STEP_NONE;
    g_wifi_init_baudrate      = 0U;

    /* SCI6: P506/TXD6 -> CJM410 pin2 HSUART_RXD; P505/RXD6 <- CJM410 pin3 HSUART_TXD. */
    status = cjm410_ep_init(&WIFI_CJM410_UART_INSTANCE);
    if (CJM410_STATUS_OK == status)
    {
        status = cjm410_ep_run_probe(&g_wifi_ep_test_result);
    }

    g_wifi_init_cjm410_status = (int32_t) status;
    g_wifi_init_at_error      = (int32_t) g_wifi_ep_test_result.at_error;
    g_wifi_init_failed_step   = (int32_t) g_wifi_ep_test_result.failed_step;
    g_wifi_init_baudrate      = g_wifi_ep_test_result.baudrate;

    if (CJM410_STATUS_OK != status)
    {
        (void) cjm410_ep_deinit();
        return wifi_map_status(status);
    }
    g_wifi_initialized = true;
    return WIFI_STATUS_OK;
}

wifi_status_t Wifi_Deinit(void)
{
    cjm410_status_t status;
    if (!g_wifi_initialized) return WIFI_STATUS_NOT_INITIALIZED;
    status = cjm410_ep_deinit();
    if (CJM410_STATUS_OK == status) g_wifi_initialized = false;
    return wifi_map_status(status);
}

wifi_status_t Wifi_Get_Info(wifi_info_t * p_info)
{
    cjm410_status_t status;
    if (NULL == p_info) return WIFI_STATUS_INVALID_ARGUMENT;
    memset(p_info, 0, sizeof(*p_info));
    if (!g_wifi_initialized) { p_info->status = WIFI_STATUS_NOT_INITIALIZED; return p_info->status; }

    status = cjm410_ep_read_info(&g_wifi_ep_test_result);
    p_info->status          = wifi_map_status(status);
    p_info->cjm410_status   = (int32_t) status;
    p_info->cjm410_at_error = (int32_t) g_wifi_ep_test_result.at_error;
    p_info->baudrate        = g_wifi_ep_test_result.baudrate;
    wifi_copy_text(p_info->version, sizeof(p_info->version), g_wifi_ep_test_result.version);
    wifi_copy_text(p_info->mac_address, sizeof(p_info->mac_address), g_wifi_ep_test_result.mac_address);
    wifi_copy_text(p_info->wifi_mode, sizeof(p_info->wifi_mode), g_wifi_ep_test_result.wifi_mode);
    wifi_copy_text(p_info->ip_config, sizeof(p_info->ip_config), g_wifi_ep_test_result.ip_config);
    wifi_copy_text(p_info->hsuart_config, sizeof(p_info->hsuart_config), g_wifi_ep_test_result.hsuart_config);
    return p_info->status;
}

wifi_status_t Wifi_Scan(char * p_response, size_t response_capacity)
{
    if ((NULL == p_response) || (0U == response_capacity)) return WIFI_STATUS_INVALID_ARGUMENT;
    if (!g_wifi_initialized) return WIFI_STATUS_NOT_INITIALIZED;
    return wifi_map_status(cjm410_ep_scan(p_response, response_capacity));
}

wifi_status_t Wifi_Connect_WPA2(char const * p_ssid, char const * p_passphrase,
                                char * p_link_response, size_t response_capacity)
{
    if ((NULL == p_ssid) || (NULL == p_passphrase) ||
        ((NULL == p_link_response) && (0U != response_capacity))) return WIFI_STATUS_INVALID_ARGUMENT;
    if (!g_wifi_initialized) return WIFI_STATUS_NOT_INITIALIZED;
    return wifi_map_status(cjm410_ep_connect_station_wpa2(p_ssid, p_passphrase,
                                                           p_link_response, response_capacity));
}

wifi_status_t Wifi_Disconnect(void)
{
    if (!g_wifi_initialized) return WIFI_STATUS_NOT_INITIALIZED;
    return wifi_map_status(cjm410_ep_disconnect());
}

wifi_status_t Wifi_Get_Network_Info(wifi_network_info_t * p_info)
{
    cjm410_status_t status;
    if (NULL == p_info) return WIFI_STATUS_INVALID_ARGUMENT;
    memset(p_info, 0, sizeof(*p_info));
    if (!g_wifi_initialized) { p_info->status = WIFI_STATUS_NOT_INITIALIZED; return p_info->status; }
    status = cjm410_ep_network_snapshot_get(&g_wifi_ep_network_snapshot);
    p_info->status          = wifi_map_status(status);
    p_info->cjm410_status   = (int32_t) status;
    p_info->cjm410_at_error = (int32_t) g_wifi_ep_network_snapshot.at_error;
    wifi_copy_text(p_info->link_status, sizeof(p_info->link_status), g_wifi_ep_network_snapshot.link_status);
    wifi_copy_text(p_info->ip_config, sizeof(p_info->ip_config), g_wifi_ep_network_snapshot.ip_config);
    return p_info->status;
}

wifi_status_t Wifi_Ping(char const * p_ipv4, char * p_response, size_t response_capacity)
{
    if ((NULL == p_ipv4) || ((NULL == p_response) && (0U != response_capacity))) return WIFI_STATUS_INVALID_ARGUMENT;
    if (!g_wifi_initialized) return WIFI_STATUS_NOT_INITIALIZED;
    return wifi_map_status(cjm410_ep_ping(p_ipv4, p_response, response_capacity));
}

wifi_status_t Wifi_TCP_Client_Configure(char const * p_server_ip, uint16_t server_port)
{
    if ((NULL == p_server_ip) || (0U == server_port)) return WIFI_STATUS_INVALID_ARGUMENT;
    if (!g_wifi_initialized) return WIFI_STATUS_NOT_INITIALIZED;
    return wifi_map_status(cjm410_ep_tcp_client_configure(p_server_ip, server_port));
}

wifi_status_t Wifi_TCP_Link_Status(char * p_response, size_t response_capacity)
{
    if ((NULL == p_response) || (0U == response_capacity)) return WIFI_STATUS_INVALID_ARGUMENT;
    if (!g_wifi_initialized) return WIFI_STATUS_NOT_INITIALIZED;
    return wifi_map_status(cjm410_ep_tcp_link_status(p_response, response_capacity));
}

wifi_status_t Wifi_Enter_Command_Mode(void)
{
    if (!g_wifi_initialized) return WIFI_STATUS_NOT_INITIALIZED;
    return wifi_map_status(cjm410_ep_enter_command_mode());
}

wifi_status_t Wifi_Enter_Data_Mode(void)
{
    if (!g_wifi_initialized) return WIFI_STATUS_NOT_INITIALIZED;
    return wifi_map_status(cjm410_ep_enter_data_mode());
}

wifi_status_t Wifi_Data_Write(uint8_t const * p_data, size_t length, uint32_t timeout_ms)
{
    if ((NULL == p_data) || (0U == length)) return WIFI_STATUS_INVALID_ARGUMENT;
    if (!g_wifi_initialized) return WIFI_STATUS_NOT_INITIALIZED;
    return wifi_map_status(cjm410_ep_data_write(p_data, length, timeout_ms));
}

wifi_status_t Wifi_Data_Read(uint8_t * p_data, size_t capacity,
                             size_t * p_received, uint32_t timeout_ms)
{
    if ((NULL == p_data) || (0U == capacity) || (NULL == p_received)) return WIFI_STATUS_INVALID_ARGUMENT;
    if (!g_wifi_initialized) return WIFI_STATUS_NOT_INITIALIZED;
    return wifi_map_status(cjm410_ep_data_read(p_data, capacity, p_received, timeout_ms));
}

wifi_status_t Wifi_Process(void)
{
    if (!g_wifi_initialized) return WIFI_STATUS_NOT_INITIALIZED;
    return wifi_map_status(cjm410_ep_process());
}

bool Wifi_Is_Initialized(void) { return g_wifi_initialized; }

void App_Wifi_Test(void)
{
    memset(&g_wifi_info, 0, sizeof(g_wifi_info));
    wifi_copy_debug(g_wifi_dbg_link, sizeof(g_wifi_dbg_link), "NOT RUN");
    wifi_copy_debug(g_wifi_dbg_ip, sizeof(g_wifi_dbg_ip), "NOT RUN");
    wifi_copy_debug(g_wifi_dbg_ping, sizeof(g_wifi_dbg_ping), "NOT RUN");

    g_wifi_status = Wifi_Init();
    if (WIFI_STATUS_OK == g_wifi_status)
    {
        g_wifi_status = Wifi_Get_Info(&g_wifi_info);
        wifi_copy_debug(g_wifi_dbg_ip, sizeof(g_wifi_dbg_ip), g_wifi_info.ip_config);
    }
    /* No SSID/password is compiled into this source. Call Wifi_Connect_WPA2() from the application. */
}
