/**
 * @file wifi.h
 * @brief High-level Smart Relay Wi-Fi API for CJM410 FW3.0.8 HSUART pins 2/3.
 */
#ifndef WIFI_H_
#define WIFI_H_

#ifdef __cplusplus
extern "C" {
#endif

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define WIFI_INFO_TEXT_SIZE     (256U)
#define WIFI_SCAN_RESPONSE_SIZE (1024U)
#define WIFI_PING_RESPONSE_SIZE (256U)

/* Override this macro if the generated FSP UART instance uses another symbol. */
#ifndef WIFI_CJM410_UART_INSTANCE
#define WIFI_CJM410_UART_INSTANCE g_uart_cjm410
#endif

typedef enum e_wifi_status
{
    WIFI_STATUS_OK = 0,
    WIFI_STATUS_INVALID_ARGUMENT,
    WIFI_STATUS_NOT_INITIALIZED,
    WIFI_STATUS_ENDPOINT_ERROR
} wifi_status_t;

typedef struct st_wifi_info
{
    wifi_status_t status;
    int32_t       cjm410_status;
    int32_t       cjm410_at_error;
    uint32_t      baudrate;
    char          version[WIFI_INFO_TEXT_SIZE];
    char          mac_address[WIFI_INFO_TEXT_SIZE];
    char          wifi_mode[WIFI_INFO_TEXT_SIZE];
    char          ip_config[WIFI_INFO_TEXT_SIZE];
    /* Current CJM410 HSUART configuration from AT+HSUART=?. */
    char          hsuart_config[WIFI_INFO_TEXT_SIZE];
} wifi_info_t;

typedef struct st_wifi_network_info
{
    wifi_status_t status;
    int32_t       cjm410_status;
    int32_t       cjm410_at_error;
    char          link_status[WIFI_INFO_TEXT_SIZE];
    char          ip_config[WIFI_INFO_TEXT_SIZE];
} wifi_network_info_t;

wifi_status_t Wifi_Init(void);
wifi_status_t Wifi_Deinit(void);
wifi_status_t Wifi_Get_Info(wifi_info_t * p_info);
wifi_status_t Wifi_Scan(char * p_response, size_t response_capacity);
wifi_status_t Wifi_Connect_WPA2(char const * p_ssid,
                                 char const * p_passphrase,
                                 char * p_link_response,
                                 size_t response_capacity);
wifi_status_t Wifi_Disconnect(void);
wifi_status_t Wifi_Get_Network_Info(wifi_network_info_t * p_info);
wifi_status_t Wifi_Ping(char const * p_ipv4,
                         char * p_response,
                         size_t response_capacity);

/* TCP + transparent data mode. */
wifi_status_t Wifi_TCP_Client_Configure(char const * p_server_ip, uint16_t server_port);
wifi_status_t Wifi_TCP_Link_Status(char * p_response, size_t response_capacity);
wifi_status_t Wifi_Enter_Command_Mode(void);
wifi_status_t Wifi_Enter_Data_Mode(void);
wifi_status_t Wifi_Data_Write(uint8_t const * p_data, size_t length, uint32_t timeout_ms);
wifi_status_t Wifi_Data_Read(uint8_t * p_data,
                              size_t capacity,
                              size_t * p_received,
                              uint32_t timeout_ms);

wifi_status_t Wifi_Process(void);
bool Wifi_Is_Initialized(void);
void App_Wifi_Test(void);

/* e2 studio bring-up diagnostics. */
extern volatile int32_t  g_wifi_init_cjm410_status;
extern volatile int32_t  g_wifi_init_at_error;
extern volatile int32_t  g_wifi_init_failed_step;
extern volatile uint32_t g_wifi_init_baudrate;
extern volatile wifi_status_t g_wifi_status;
extern volatile wifi_status_t g_wifi_connect_status;
extern volatile wifi_status_t g_wifi_network_status;
extern volatile wifi_status_t g_wifi_ping_status;
extern volatile char g_wifi_dbg_link[WIFI_INFO_TEXT_SIZE];
extern volatile char g_wifi_dbg_ip[WIFI_INFO_TEXT_SIZE];
extern volatile char g_wifi_dbg_ping[WIFI_PING_RESPONSE_SIZE];

#ifdef __cplusplus
}
#endif

#endif /* WIFI_H_ */
