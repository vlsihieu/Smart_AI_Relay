#ifndef HUSKYLENS_RA6M5_H
#define HUSKYLENS_RA6M5_H

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "bsp_api.h"
#include "r_uart_api.h"

#ifdef __cplusplus
extern "C" {
#endif

/***********************************************************************************************************************
 * Configuration
 **********************************************************************************************************************/
#define HUSKYLENS_PROTOCOL_HEADER_0             (0x55U)
#define HUSKYLENS_PROTOCOL_HEADER_1             (0xAAU)
#define HUSKYLENS_PROTOCOL_ADDRESS              (0x11U)
#define HUSKYLENS_MAX_PAYLOAD_SIZE              (128U)
#define HUSKYLENS_MAX_RESULTS                   (32U)
#define HUSKYLENS_UART_RX_RING_SIZE             (256U)
#define HUSKYLENS_DEFAULT_TIMEOUT_MS            (1000U)
#define HUSKYLENS_KNOCK_RETRY_COUNT             (5U)
#define HUSKYLENS_CUSTOM_NAME_MAX_LENGTH        (20U)

/***********************************************************************************************************************
 * HuskyLens protocol commands
 **********************************************************************************************************************/
#define HUSKYLENS_CMD_REQUEST                    (0x20U)
#define HUSKYLENS_CMD_REQUEST_BLOCKS             (0x21U)
#define HUSKYLENS_CMD_REQUEST_ARROWS             (0x22U)
#define HUSKYLENS_CMD_REQUEST_LEARNED            (0x23U)
#define HUSKYLENS_CMD_REQUEST_BLOCKS_LEARNED     (0x24U)
#define HUSKYLENS_CMD_REQUEST_ARROWS_LEARNED     (0x25U)
#define HUSKYLENS_CMD_REQUEST_BY_ID              (0x26U)
#define HUSKYLENS_CMD_REQUEST_BLOCKS_BY_ID       (0x27U)
#define HUSKYLENS_CMD_REQUEST_ARROWS_BY_ID       (0x28U)
#define HUSKYLENS_CMD_RETURN_INFO                (0x29U)
#define HUSKYLENS_CMD_RETURN_BLOCK               (0x2AU)
#define HUSKYLENS_CMD_RETURN_ARROW               (0x2BU)
#define HUSKYLENS_CMD_REQUEST_KNOCK              (0x2CU)
#define HUSKYLENS_CMD_REQUEST_ALGORITHM          (0x2DU)
#define HUSKYLENS_CMD_RETURN_OK                  (0x2EU)
#define HUSKYLENS_CMD_REQUEST_CUSTOM_NAME        (0x2FU)
#define HUSKYLENS_CMD_REQUEST_PHOTO              (0x30U)
#define HUSKYLENS_CMD_REQUEST_LEARN              (0x36U)
#define HUSKYLENS_CMD_REQUEST_FORGET             (0x37U)
#define HUSKYLENS_CMD_REQUEST_SAVE_SCREENSHOT    (0x39U)
#define HUSKYLENS_CMD_REQUEST_SAVE_MODEL         (0x3AU)
#define HUSKYLENS_CMD_REQUEST_LOAD_MODEL         (0x3BU)
#define HUSKYLENS_CMD_RETURN_BUSY                (0x3CU)
#define HUSKYLENS_CMD_RETURN_NEED_PRO            (0x3DU)
#define HUSKYLENS_CMD_REQUEST_IS_PRO             (0x3EU)

/***********************************************************************************************************************
 * Public types
 **********************************************************************************************************************/
typedef enum e_huskylens_status
{
    HUSKYLENS_STATUS_OK = 0,
    HUSKYLENS_STATUS_INVALID_ARGUMENT,
    HUSKYLENS_STATUS_NOT_INITIALIZED,
    HUSKYLENS_STATUS_TIMEOUT,
    HUSKYLENS_STATUS_FSP_ERROR,
    HUSKYLENS_STATUS_PROTOCOL_ERROR,
    HUSKYLENS_STATUS_CHECKSUM_ERROR,
    HUSKYLENS_STATUS_OVERFLOW,
    HUSKYLENS_STATUS_BUSY,
    HUSKYLENS_STATUS_NEED_PRO
} huskylens_status_t;

typedef enum e_huskylens_algorithm
{
    HUSKYLENS_ALGORITHM_FACE_RECOGNITION = 0,
    HUSKYLENS_ALGORITHM_OBJECT_TRACKING,
    HUSKYLENS_ALGORITHM_OBJECT_RECOGNITION,
    HUSKYLENS_ALGORITHM_LINE_TRACKING,
    HUSKYLENS_ALGORITHM_COLOR_RECOGNITION,
    HUSKYLENS_ALGORITHM_TAG_RECOGNITION,
    HUSKYLENS_ALGORITHM_OBJECT_CLASSIFICATION
} huskylens_algorithm_t;

typedef enum e_huskylens_result_type
{
    HUSKYLENS_RESULT_BLOCK = 0,
    HUSKYLENS_RESULT_ARROW
} huskylens_result_type_t;

typedef struct st_huskylens_block
{
    int16_t x_center;
    int16_t y_center;
    int16_t width;
    int16_t height;
    int16_t id;
} huskylens_block_t;

typedef struct st_huskylens_arrow
{
    int16_t x_origin;
    int16_t y_origin;
    int16_t x_target;
    int16_t y_target;
    int16_t id;
} huskylens_arrow_t;

typedef struct st_huskylens_result
{
    huskylens_result_type_t type;
    union
    {
        huskylens_block_t block;
        huskylens_arrow_t arrow;
    } data;
} huskylens_result_t;

typedef struct st_huskylens_info
{
    int16_t result_count;
    int16_t learned_id_count;
    int16_t frame_number;
} huskylens_info_t;

typedef struct st_huskylens_frame
{
    uint8_t command;
    uint8_t payload_length;
    uint8_t payload[HUSKYLENS_MAX_PAYLOAD_SIZE];
} huskylens_frame_t;

typedef struct st_huskylens_ra6m5
{
    uart_instance_t const * p_uart;
    uart_callback_args_t uart_callback_memory;
    uint32_t timeout_ms;
    fsp_err_t last_fsp_error;

    volatile bool uart_tx_complete;
    volatile bool uart_error;
    volatile uint16_t uart_rx_head;
    volatile uint16_t uart_rx_tail;
    uint8_t uart_rx_ring[HUSKYLENS_UART_RX_RING_SIZE];

    bool initialized;
    bool transport_opened_by_driver;
    huskylens_info_t info;
    huskylens_result_t results[HUSKYLENS_MAX_RESULTS];
    size_t result_count;
} huskylens_ra6m5_t;

/***********************************************************************************************************************
 * Public API
 **********************************************************************************************************************/
fsp_err_t HuskyLens_RA6M5_Init_UART(huskylens_ra6m5_t * p_driver,
                                    uart_instance_t const * p_uart,
                                    uint32_t timeout_ms);
fsp_err_t HuskyLens_RA6M5_Close(huskylens_ra6m5_t * p_driver);
huskylens_status_t HuskyLens_RA6M5_Ping(huskylens_ra6m5_t * p_driver);
huskylens_status_t HuskyLens_RA6M5_Set_Algorithm(huskylens_ra6m5_t * p_driver,
                                                 huskylens_algorithm_t algorithm);
huskylens_status_t HuskyLens_RA6M5_Request_All(huskylens_ra6m5_t * p_driver);
huskylens_status_t HuskyLens_RA6M5_Request_Blocks(huskylens_ra6m5_t * p_driver);
huskylens_status_t HuskyLens_RA6M5_Request_Arrows(huskylens_ra6m5_t * p_driver);
huskylens_status_t HuskyLens_RA6M5_Request_Learned(huskylens_ra6m5_t * p_driver);
huskylens_status_t HuskyLens_RA6M5_Request_Blocks_Learned(huskylens_ra6m5_t * p_driver);
huskylens_status_t HuskyLens_RA6M5_Request_Arrows_Learned(huskylens_ra6m5_t * p_driver);
huskylens_status_t HuskyLens_RA6M5_Request_By_ID(huskylens_ra6m5_t * p_driver, uint16_t id);
huskylens_status_t HuskyLens_RA6M5_Request_Blocks_By_ID(huskylens_ra6m5_t * p_driver, uint16_t id);
huskylens_status_t HuskyLens_RA6M5_Request_Arrows_By_ID(huskylens_ra6m5_t * p_driver, uint16_t id);
huskylens_status_t HuskyLens_RA6M5_Learn(huskylens_ra6m5_t * p_driver, uint16_t id);
huskylens_status_t HuskyLens_RA6M5_Forget(huskylens_ra6m5_t * p_driver);
huskylens_status_t HuskyLens_RA6M5_Set_Custom_Name(huskylens_ra6m5_t * p_driver,
                                                    uint8_t id,
                                                    char const * p_name);
huskylens_status_t HuskyLens_RA6M5_Save_Photo(huskylens_ra6m5_t * p_driver);
huskylens_status_t HuskyLens_RA6M5_Save_Screenshot(huskylens_ra6m5_t * p_driver);
huskylens_status_t HuskyLens_RA6M5_Save_Model(huskylens_ra6m5_t * p_driver, uint16_t file_number);
huskylens_status_t HuskyLens_RA6M5_Load_Model(huskylens_ra6m5_t * p_driver, uint16_t file_number);
huskylens_status_t HuskyLens_RA6M5_Is_Pro(huskylens_ra6m5_t * p_driver, bool * p_is_pro);
huskylens_info_t const * HuskyLens_RA6M5_Get_Info(huskylens_ra6m5_t const * p_driver);
size_t HuskyLens_RA6M5_Get_Result_Count(huskylens_ra6m5_t const * p_driver);
huskylens_result_t const * HuskyLens_RA6M5_Get_Result(huskylens_ra6m5_t const * p_driver, size_t index);
fsp_err_t HuskyLens_RA6M5_Get_Last_FSP_Error(huskylens_ra6m5_t const * p_driver);

#ifdef __cplusplus
}
#endif

#endif /* HUSKYLENS_RA6M5_H */
