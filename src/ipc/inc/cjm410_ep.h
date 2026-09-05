/**
 * @file cjm410_ep.h
 * @brief CJM410 middleware endpoint for RA6M5 SCI6 + HSUART pins 2/3.
 *
 * Layering:
 *   HLD wifi -> IPC cjm410_ep -> IP cjm410 -> RA6M5 SCI6 port -> CJM410 HSUART pins 2/3
 */
#ifndef CJM410_EP_H_
#define CJM410_EP_H_

#ifdef __cplusplus
extern "C" {
#endif

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "hal_data.h"
#include "cjm410.h"

#define CJM410_EP_RESPONSE_SIZE (1024U)
#define CJM410_EP_INFO_SIZE     (256U)
#define CJM410_EP_TCP_DATA_SIZE (256U)

typedef enum e_cjm410_ep_test_step
{
    CJM410_EP_TEST_STEP_NONE = 0,
    CJM410_EP_TEST_STEP_INIT,
    CJM410_EP_TEST_STEP_PROBE,
    CJM410_EP_TEST_STEP_VERSION,
    CJM410_EP_TEST_STEP_MAC,
    CJM410_EP_TEST_STEP_WIFI_MODE,
    CJM410_EP_TEST_STEP_IP_CONFIG,
    /* Verify HSUART configuration using AT+HSUART=?. */
    CJM410_EP_TEST_STEP_HSUART,
    CJM410_EP_TEST_STEP_COMPLETE
} cjm410_ep_test_step_t;

typedef struct st_cjm410_ep_test_result
{
    cjm410_status_t       status;
    cjm410_at_error_t     at_error;
    cjm410_profile_t      profile;
    cjm410_ep_test_step_t failed_step;
    uint32_t              baudrate; /* Fixed 115200 in this project profile. */
    char                  response[CJM410_EP_RESPONSE_SIZE];
    char                  version[CJM410_EP_INFO_SIZE];
    char                  mac_address[CJM410_EP_INFO_SIZE];
    char                  wifi_mode[CJM410_EP_INFO_SIZE];
    char                  ip_config[CJM410_EP_INFO_SIZE];
    /* Raw HSUART configuration response from AT+HSUART=?. */
    char                  hsuart_config[CJM410_EP_INFO_SIZE];
} cjm410_ep_test_result_t;

typedef struct st_cjm410_ep_network_snapshot
{
    cjm410_status_t   status;
    cjm410_at_error_t at_error;
    char              link_status[CJM410_EP_INFO_SIZE];
    char              ip_config[CJM410_EP_INFO_SIZE];
} cjm410_ep_network_snapshot_t;

typedef struct st_cjm410_ep_tcp_echo_cfg
{
    char const    * p_server_ip;
    uint16_t        server_port;
    uint8_t const * p_payload;
    size_t          payload_length;
    uint32_t        timeout_ms;
} cjm410_ep_tcp_echo_cfg_t;

typedef struct st_cjm410_ep_tcp_echo_result
{
    cjm410_status_t   status;
    cjm410_at_error_t at_error;
    size_t            tx_length;
    size_t            rx_length;
    bool              echo_match;
    char              link_status[CJM410_EP_INFO_SIZE];
    uint8_t           rx_data[CJM410_EP_TCP_DATA_SIZE];
} cjm410_ep_tcp_echo_result_t;

/* Lifecycle / probe. */
cjm410_status_t cjm410_ep_init(uart_instance_t const * p_uart);
cjm410_status_t cjm410_ep_deinit(void);
cjm410_status_t cjm410_ep_run_probe(cjm410_ep_test_result_t * p_result);
cjm410_status_t cjm410_ep_read_info(cjm410_ep_test_result_t * p_result);
cjm410_status_t cjm410_ep_run_basic_test(cjm410_ep_test_result_t * p_result);

/* Wi-Fi / network. */
cjm410_status_t cjm410_ep_scan(char * p_response, size_t response_capacity);
cjm410_status_t cjm410_ep_connect_station_wpa2(char const * p_ssid,
                                               char const * p_passphrase,
                                               char * p_response,
                                               size_t response_capacity);
cjm410_status_t cjm410_ep_disconnect(void);
cjm410_status_t cjm410_ep_start_soft_ap_wpa2(char const * p_ssid,
                                             char const * p_passphrase,
                                             char * p_response,
                                             size_t response_capacity);
cjm410_status_t cjm410_ep_network_snapshot_get(cjm410_ep_network_snapshot_t * p_snapshot);
cjm410_status_t cjm410_ep_ping(char const * p_ipv4,
                               char * p_response,
                               size_t response_capacity);

/* TCP and transparent-data path on the same HSUART pins 2/3. */
cjm410_status_t cjm410_ep_tcp_client_configure(char const * p_server_ip,
                                               uint16_t server_port);
cjm410_status_t cjm410_ep_tcp_link_status(char * p_response,
                                          size_t response_capacity);
cjm410_status_t cjm410_ep_enter_command_mode(void);
cjm410_status_t cjm410_ep_enter_data_mode(void);
cjm410_status_t cjm410_ep_data_write(uint8_t const * p_data,
                                     size_t length,
                                     uint32_t timeout_ms);
cjm410_status_t cjm410_ep_data_read(uint8_t * p_data,
                                    size_t capacity,
                                    size_t * p_received,
                                    uint32_t timeout_ms);
cjm410_status_t cjm410_ep_tcp_echo_test(cjm410_ep_tcp_echo_cfg_t const * p_cfg,
                                        cjm410_ep_tcp_echo_result_t * p_result);

/* Diagnostics / low-level endpoint wrappers. */
cjm410_status_t cjm410_ep_v26_timeouts_set(uint16_t uart_to_network_ms,
                                           uint16_t network_check_seconds);
cjm410_status_t cjm410_ep_execute(char const * p_command,
                                  char * p_response,
                                  size_t response_capacity,
                                  uint32_t timeout_ms);
cjm410_status_t cjm410_ep_process(void);
cjm410_t const * cjm410_ep_driver_get(void);

#ifdef __cplusplus
}
#endif

#endif /* CJM410_EP_H_ */
