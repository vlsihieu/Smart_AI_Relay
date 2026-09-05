/**
 * @file    cjm410.h
 * @brief   Portable Conjing CJM410 AT driver for FW 3.0.8 HSUART operation on pins 2/3.
 *
 * This layer owns the vendor protocol only. MCU UART, reset GPIO, timing, and
 * interrupt handling are supplied through cjm410_transport_t. No dynamic
 * allocation is used.
 */

#ifndef CJM410_H
#define CJM410_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifndef CJM410_MAX_COMMAND_LENGTH
#define CJM410_MAX_COMMAND_LENGTH       (512U)
#endif

#ifndef CJM410_MAX_LINE_LENGTH
#define CJM410_MAX_LINE_LENGTH          (512U)
#endif

/**
 * Production Smart Relay transport is fixed at 115200 baud on SCI6/HSUART.
 * Keep this compatibility switch disabled; no runtime baud sweep is needed.
 */
#ifndef CJM410_ENABLE_DYNAMIC_BAUD_PROBE
#define CJM410_ENABLE_DYNAMIC_BAUD_PROBE (0U)
#endif

#ifndef CJM410_PROBE_RETRY_COUNT
#define CJM410_PROBE_RETRY_COUNT          (3U)
#endif

#ifndef CJM410_PROBE_RETRY_DELAY_MS
#define CJM410_PROBE_RETRY_DELAY_MS       (250U)
#endif

#define CJM410_AT_SPEC_MAJOR            (2U)
#define CJM410_AT_SPEC_MINOR            (6U)

/** Fixed HSUART rate used by the Smart Relay board integration. */
#ifndef CJM410_HSUART_BAUDRATE
#define CJM410_HSUART_BAUDRATE          (115200U)
#endif

typedef enum e_cjm410_status
{
    CJM410_STATUS_OK             = 0,
    CJM410_STATUS_INVALID_ARG    = -1,
    CJM410_STATUS_TIMEOUT        = -2,
    CJM410_STATUS_IO_ERROR       = -3,
    CJM410_STATUS_PROTOCOL_ERROR = -4,
    CJM410_STATUS_OVERFLOW       = -5,
    CJM410_STATUS_UNSUPPORTED    = -6,
    CJM410_STATUS_NOT_READY      = -7,
    CJM410_STATUS_BUSY           = -8,
    CJM410_STATUS_AT_ERROR       = -9
} cjm410_status_t;

typedef enum e_cjm410_at_error
{
    CJM410_AT_ERROR_NONE                = 0,
    CJM410_AT_ERROR_INVALID_COMMAND     = -1,
    CJM410_AT_ERROR_INVALID_PARAMETERS  = -2,
    CJM410_AT_ERROR_FORBIDDEN_OPERATION = -3,
    CJM410_AT_ERROR_SYSTEM_OPERATION    = -4,
    CJM410_AT_ERROR_UNKNOWN             = -127
} cjm410_at_error_t;

/** Legacy profile values remain for source compatibility with the old layer. */
typedef enum e_cjm410_profile
{
    CJM410_PROFILE_UNKNOWN = 0,
    CJM410_PROFILE_AT_V2_6,
    CJM410_PROFILE_AT = CJM410_PROFILE_AT_V2_6,
    CJM410_PROFILE_GENERIC_SHELL,
    CJM410_PROFILE_QCA_HOSTLESS_SHELL
} cjm410_profile_t;

typedef enum e_cjm410_wifi_mode
{
    CJM410_WIFI_MODE_STATION = 0,
    CJM410_WIFI_MODE_SOFT_AP = 1
} cjm410_wifi_mode_t;

typedef enum e_cjm410_phy_mode
{
    CJM410_PHY_MODE_80211B = 0,
    CJM410_PHY_MODE_80211G,
    CJM410_PHY_MODE_80211N
} cjm410_phy_mode_t;

typedef enum e_cjm410_security
{
    CJM410_SECURITY_NONE = 0,
    CJM410_SECURITY_WEP,
    CJM410_SECURITY_WPA,
    CJM410_SECURITY_WPA2
} cjm410_security_t;

typedef enum e_cjm410_cipher
{
    CJM410_CIPHER_TKIP = 0,
    CJM410_CIPHER_CCMP
} cjm410_cipher_t;

typedef enum e_cjm410_socket_protocol
{
    CJM410_SOCKET_TCP = 0,
    CJM410_SOCKET_UDP,
    CJM410_SOCKET_MQTT,
    CJM410_SOCKET_HTTPC
} cjm410_socket_protocol_t;

typedef enum e_cjm410_http_method
{
    CJM410_HTTP_GET = 0,
    CJM410_HTTP_POST,
    CJM410_HTTP_PUT,
    CJM410_HTTP_PATCH
} cjm410_http_method_t;

typedef struct st_cjm410_mqtt_config
{
    char const * p_server_url;
    uint16_t     port;
    char const * p_certificate_name;
    char const * p_client_id;
    uint16_t     keepalive_seconds;
    bool         auto_connect;
    bool         clean_session;
    char const * p_username;
    char const * p_password;
} cjm410_mqtt_config_t;

typedef int32_t (* cjm410_transport_write_t)(void * p_context,
                                             uint8_t const * p_data,
                                             size_t length,
                                             uint32_t timeout_ms);
typedef size_t (* cjm410_transport_read_t)(void * p_context,
                                           uint8_t * p_data,
                                           size_t capacity);
typedef cjm410_status_t (* cjm410_transport_set_baud_t)(void * p_context,
                                                        uint32_t baudrate);
typedef cjm410_status_t (* cjm410_transport_reset_t)(void * p_context,
                                                     bool asserted);
typedef void (* cjm410_transport_delay_t)(void * p_context, uint32_t delay_ms);
typedef void (* cjm410_event_callback_t)(void * p_context, char const * p_line);

typedef struct st_cjm410_transport
{
    void                         * p_context;
    cjm410_transport_write_t       write;
    cjm410_transport_read_t        read;
    cjm410_transport_set_baud_t    set_baud;
    cjm410_transport_reset_t       reset;
    cjm410_transport_delay_t       delay_ms;
} cjm410_transport_t;

typedef struct st_cjm410_config
{
    uint32_t reset_assert_ms;
    uint32_t boot_wait_ms;
    uint32_t command_timeout_ms;
    uint32_t response_idle_ms;
    uint32_t command_mode_guard_ms;
    cjm410_event_callback_t event_callback;
    void                  * p_event_context;
} cjm410_config_t;

/* Probe diagnostics for e2 studio Expressions/Live Watch. */
extern volatile uint32_t g_cjm410_probe_fix_version;
extern volatile uint32_t g_cjm410_probe_stage;
extern volatile int32_t  g_cjm410_probe_last_status;
extern volatile uint32_t g_cjm410_probe_attempt_baudrate;
extern volatile uint32_t g_cjm410_probe_attempt_index;
extern volatile uint32_t g_cjm410_probe_retry_index;
extern volatile uint32_t g_cjm410_probe_attempt_count;
extern volatile uint32_t g_cjm410_probe_baud_set_error_count;

typedef struct st_cjm410
{
    cjm410_transport_t transport;
    cjm410_config_t    config;
    cjm410_profile_t   profile;
    cjm410_at_error_t  last_at_error;
    uint32_t           detected_baudrate;
    char               line_buffer[CJM410_MAX_LINE_LENGTH];
    char               tx_buffer[CJM410_MAX_COMMAND_LENGTH + 3U];
    char               format_buffer[CJM410_MAX_COMMAND_LENGTH + 1U];
    uint8_t            rx_work_buffer[32U];
    size_t             line_length;
    bool               line_overflow;
    bool               initialized;
    bool               command_active;
    bool               transparent_mode;
} cjm410_t;

/* Core command engine. */
void cjm410_config_default(cjm410_config_t * p_config);
cjm410_status_t cjm410_init(cjm410_t * p_driver,
                            cjm410_transport_t const * p_transport,
                            cjm410_config_t const * p_config);
cjm410_status_t cjm410_hardware_reset(cjm410_t * p_driver);
cjm410_status_t cjm410_auto_probe(cjm410_t * p_driver,
                                  char * p_response,
                                  size_t response_capacity);
cjm410_status_t cjm410_execute(cjm410_t * p_driver,
                               char const * p_command,
                               char * p_response,
                               size_t response_capacity,
                               uint32_t timeout_ms);
cjm410_status_t cjm410_process(cjm410_t * p_driver);
cjm410_at_error_t cjm410_last_at_error_get(cjm410_t const * p_driver);
cjm410_status_t cjm410_response_payload_get(char const * p_response,
                                             char * p_payload,
                                             size_t payload_capacity);

/* Mode switch. */
cjm410_status_t cjm410_enter_command_mode(cjm410_t * p_driver);
cjm410_status_t cjm410_enter_transparent_mode(cjm410_t * p_driver);
cjm410_status_t cjm410_transparent_write(cjm410_t * p_driver,
                                          uint8_t const * p_data,
                                          size_t length,
                                          uint32_t timeout_ms);
cjm410_status_t cjm410_transparent_read(cjm410_t * p_driver,
                                        uint8_t * p_data,
                                        size_t capacity,
                                        size_t * p_received,
                                        uint32_t timeout_ms);

/* Wireless commands. */
cjm410_status_t cjm410_get_version(cjm410_t * p_driver,
                                   char * p_response,
                                   size_t response_capacity);
cjm410_status_t cjm410_get_link_status(cjm410_t * p_driver,
                                       char * p_response,
                                       size_t response_capacity);
cjm410_status_t cjm410_get_mac_address(cjm410_t * p_driver,
                                       char * p_response,
                                       size_t response_capacity);
cjm410_status_t cjm410_scan(cjm410_t * p_driver,
                            char const * p_optional_ssid,
                            char * p_response,
                            size_t response_capacity);
cjm410_status_t cjm410_disconnect(cjm410_t * p_driver);
cjm410_status_t cjm410_start_wps(cjm410_t * p_driver);
cjm410_status_t cjm410_set_wifi_mode(cjm410_t * p_driver,
                                     cjm410_wifi_mode_t mode);
cjm410_status_t cjm410_get_wifi_mode(cjm410_t * p_driver,
                                     char * p_response,
                                     size_t response_capacity);
cjm410_status_t cjm410_set_phy_mode(cjm410_t * p_driver,
                                    cjm410_phy_mode_t mode);
cjm410_status_t cjm410_connect_open(cjm410_t * p_driver,
                                    char const * p_ssid,
                                    char * p_response,
                                    size_t response_capacity);
cjm410_status_t cjm410_connect_wpa2(cjm410_t * p_driver,
                                    char const * p_ssid,
                                    char const * p_passphrase,
                                    char * p_response,
                                    size_t response_capacity);
cjm410_status_t cjm410_start_soft_ap_open(cjm410_t * p_driver,
                                          char const * p_ssid,
                                          char * p_response,
                                          size_t response_capacity);
cjm410_status_t cjm410_start_soft_ap_wpa2(cjm410_t * p_driver,
                                          char const * p_ssid,
                                          char const * p_passphrase,
                                          char * p_response,
                                          size_t response_capacity);
cjm410_status_t cjm410_configure_soft_ap(cjm410_t * p_driver,
                                         char const * p_ssid,
                                         uint8_t channel,
                                         bool hidden,
                                         cjm410_security_t security,
                                         cjm410_cipher_t cipher,
                                         char const * p_passphrase,
                                         uint8_t max_stations);

/* Network commands. */
cjm410_status_t cjm410_get_tcp_link_status(cjm410_t * p_driver,
                                           char * p_response,
                                           size_t response_capacity);
cjm410_status_t cjm410_ping(cjm410_t * p_driver,
                            char const * p_ipv4,
                            char * p_response,
                            size_t response_capacity);
cjm410_status_t cjm410_get_ip_config(cjm410_t * p_driver,
                                     char * p_response,
                                     size_t response_capacity);
cjm410_status_t cjm410_set_static_ip(cjm410_t * p_driver,
                                     char const * p_ip,
                                     char const * p_mask,
                                     char const * p_gateway);
cjm410_status_t cjm410_set_dhcp_client(cjm410_t * p_driver, bool enabled);
cjm410_status_t cjm410_start_dhcp(cjm410_t * p_driver);
cjm410_status_t cjm410_set_dns_servers(cjm410_t * p_driver,
                                       char const * p_primary,
                                       char const * p_secondary);
cjm410_status_t cjm410_set_socket_protocol(cjm410_t * p_driver,
                                           cjm410_socket_protocol_t protocol);
cjm410_status_t cjm410_set_tcp_client(cjm410_t * p_driver,
                                      char const * p_remote_ip,
                                      uint16_t port);
cjm410_status_t cjm410_set_tcp_server(cjm410_t * p_driver, uint16_t port);
cjm410_status_t cjm410_set_udp_client(cjm410_t * p_driver,
                                      char const * p_remote_ip,
                                      uint16_t port);
cjm410_status_t cjm410_set_udp_server(cjm410_t * p_driver, uint16_t port);
cjm410_status_t cjm410_set_network_tx_timeout(cjm410_t * p_driver,
                                              uint16_t timeout_ms);
cjm410_status_t cjm410_set_network_receive_check_timeout(cjm410_t * p_driver,
                                                         uint16_t timeout_seconds);

/* MQTT commands. */
cjm410_status_t cjm410_mqtt_configure(cjm410_t * p_driver,
                                      cjm410_mqtt_config_t const * p_config,
                                      char * p_response,
                                      size_t response_capacity);
cjm410_status_t cjm410_mqtt_disconnect(cjm410_t * p_driver);
cjm410_status_t cjm410_mqtt_publish(cjm410_t * p_driver,
                                    char const * p_topic,
                                    char const * p_message,
                                    uint16_t message_id,
                                    uint8_t qos,
                                    bool retained,
                                    bool duplicated);
cjm410_status_t cjm410_mqtt_subscribe(cjm410_t * p_driver,
                                      char const * p_topic,
                                      uint8_t qos);
cjm410_status_t cjm410_mqtt_unsubscribe(cjm410_t * p_driver,
                                        char const * p_topic);

/* HTTP client commands. */
cjm410_status_t cjm410_ssl_client_start(cjm410_t * p_driver,
                                        char * p_response,
                                        size_t response_capacity);
cjm410_status_t cjm410_http_connect(cjm410_t * p_driver,
                                    char const * p_server,
                                    uint8_t ssl_context_index,
                                    uint16_t port,
                                    uint32_t request_timeout_ms,
                                    char * p_response,
                                    size_t response_capacity);
cjm410_status_t cjm410_http_disconnect(cjm410_t * p_driver, uint8_t client_index);
cjm410_status_t cjm410_http_request(cjm410_t * p_driver,
                                    cjm410_http_method_t method,
                                    uint8_t client_index,
                                    char const * p_url,
                                    char * p_response,
                                    size_t response_capacity);
cjm410_status_t cjm410_http_set_parameter(cjm410_t * p_driver,
                                          uint8_t client_index,
                                          char const * p_key,
                                          char const * p_value);
cjm410_status_t cjm410_http_add_header(cjm410_t * p_driver,
                                       uint8_t client_index,
                                       char const * p_name,
                                       char const * p_value);
cjm410_status_t cjm410_http_clear_headers(cjm410_t * p_driver,
                                          uint8_t client_index);
cjm410_status_t cjm410_http_set_body(cjm410_t * p_driver,
                                     uint8_t client_index,
                                     char const * p_content);

/* SNTP commands. */
cjm410_status_t cjm410_sntp_enable(cjm410_t * p_driver, bool enabled);
cjm410_status_t cjm410_sntp_set_zone(cjm410_t * p_driver,
                                     char const * p_utc_offset,
                                     bool daylight_saving);
cjm410_status_t cjm410_sntp_get_time(cjm410_t * p_driver,
                                     char * p_response,
                                     size_t response_capacity);
cjm410_status_t cjm410_sntp_get_time_of_day(cjm410_t * p_driver,
                                            char * p_response,
                                            size_t response_capacity);

/* UART and management commands. The multi_tcp_hs FW3.0.8 image supports AT+HSUART. */
cjm410_status_t cjm410_get_hsuart_config(cjm410_t * p_driver,
                                         char * p_response,
                                         size_t response_capacity);
cjm410_status_t cjm410_set_hsuart_config(cjm410_t * p_driver,
                                         uint32_t baudrate,
                                         bool rts_cts_enabled);
cjm410_status_t cjm410_set_debug_output(cjm410_t * p_driver, bool enabled);
cjm410_status_t cjm410_save(cjm410_t * p_driver);
cjm410_status_t cjm410_reset(cjm410_t * p_driver);
cjm410_status_t cjm410_apply(cjm410_t * p_driver);
cjm410_status_t cjm410_restore_factory_defaults(cjm410_t * p_driver);
cjm410_status_t cjm410_ota_update(cjm410_t * p_driver,
                                  char const * p_tftp_ip,
                                  char const * p_file_name);

/** Not defined by AT Commands v2.6; retained to make unsupported use explicit. */
cjm410_status_t cjm410_get_rssi(cjm410_t * p_driver,
                                char * p_response,
                                size_t response_capacity);

char const * cjm410_status_string(cjm410_status_t status);
char const * cjm410_profile_string(cjm410_profile_t profile);
char const * cjm410_at_error_string(cjm410_at_error_t error);

#ifdef __cplusplus
}
#endif

#endif /* CJM410_H */
