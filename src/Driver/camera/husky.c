/*******************************************************************************************************************//**
 * @file huskylens_ra6m5_uart.c
 * @brief Implements the DFRobot HuskyLens K210 AI camera protocol for Renesas RA6M5 FSP.
 *
 * The implementation follows the published SEN0305 protocol framing: 0x55 0xAA, protocol address 0x11, payload length,
 * command, payload and a one-byte additive checksum. Communication uses UART only.
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/
#include <string.h>
#include "husky.h"

/***********************************************************************************************************************
 * Macro definitions
 **********************************************************************************************************************/
#define HUSKYLENS_FRAME_FIXED_SIZE                      (6U)
#define HUSKYLENS_FRAME_DATA_START_INDEX                (5U)
#define HUSKYLENS_FRAME_MAX_SIZE                        (HUSKYLENS_MAX_PAYLOAD_SIZE + HUSKYLENS_FRAME_FIXED_SIZE)
#define HUSKYLENS_RESULT_PAYLOAD_SIZE                   (10U)
#define HUSKYLENS_INFO_PAYLOAD_SIZE                     (10U)

/***********************************************************************************************************************
 * Typedef definitions
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Private function declarations
 **********************************************************************************************************************/
static void huskylens_reset_runtime(huskylens_ra6m5_t * p_driver);
static void huskylens_flush_transport_rx(huskylens_ra6m5_t * p_driver);
static uint8_t huskylens_checksum(uint8_t const * p_data, size_t length);
static size_t huskylens_build_frame(uint8_t command,
                                    uint8_t const * p_payload,
                                    uint8_t payload_length,
                                    uint8_t * p_frame,
                                    size_t frame_capacity);
static int16_t huskylens_read_le_i16(uint8_t const * p_data);
static void huskylens_write_le_u16(uint8_t * p_data, uint16_t value);
static huskylens_status_t huskylens_transport_write(huskylens_ra6m5_t * p_driver,
                                                    uint8_t const * p_data,
                                                    size_t length);
static huskylens_status_t huskylens_transport_get_byte(huskylens_ra6m5_t * p_driver,
                                                       uint8_t * p_byte,
                                                       uint32_t timeout_ms);
static huskylens_status_t huskylens_uart_write(huskylens_ra6m5_t * p_driver,
                                               uint8_t const * p_data,
                                               size_t length);
static bool huskylens_uart_ring_pop(huskylens_ra6m5_t * p_driver, uint8_t * p_byte);
static huskylens_status_t huskylens_receive_frame(huskylens_ra6m5_t * p_driver,
                                                  huskylens_frame_t * p_frame,
                                                  uint32_t timeout_ms);
static huskylens_status_t huskylens_wait_for_command(huskylens_ra6m5_t * p_driver,
                                                     uint8_t expected_command,
                                                     huskylens_frame_t * p_frame);
static huskylens_status_t huskylens_send_command(huskylens_ra6m5_t * p_driver,
                                                 uint8_t command,
                                                 uint8_t const * p_payload,
                                                 uint8_t payload_length);
static huskylens_status_t huskylens_command_wait_ok(huskylens_ra6m5_t * p_driver,
                                                    uint8_t command,
                                                    uint8_t const * p_payload,
                                                    uint8_t payload_length);
static huskylens_status_t huskylens_request_results(huskylens_ra6m5_t * p_driver,
                                                    uint8_t command,
                                                    uint8_t const * p_payload,
                                                    uint8_t payload_length);
static huskylens_status_t huskylens_decode_info(huskylens_ra6m5_t * p_driver,
                                                huskylens_frame_t const * p_frame);
static huskylens_status_t huskylens_decode_result(huskylens_frame_t const * p_frame,
                                                  huskylens_result_t * p_result);
static void huskylens_uart_callback(uart_callback_args_t * p_args);

/***********************************************************************************************************************
 * Private global variables
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Public global variables
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * @addtogroup HuskyLens_RA6M5
 * @{
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * @brief Initializes the HuskyLens driver on an FSP UART instance.
 *
 * The FSP UART should be configured for the same baud rate selected in the HuskyLens General Settings. For first bring-up,
 * DFRobot documents Serial 9600, 8 data bits, no parity and one stop bit. The driver installs its own callback at runtime.
 *
 * @param[in,out] p_driver Driver object with persistent storage.
 * @param[in]     p_uart   Generated FSP UART instance dedicated to HuskyLens.
 * @param[in]     timeout_ms Blocking command timeout in milliseconds. Zero selects the default timeout.
 *
 * @retval FSP_SUCCESS              Driver transport initialized successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT A required pointer is NULL.
 * @return Any other FSP error returned by open() or callbackSet().
 **********************************************************************************************************************/
fsp_err_t HuskyLens_RA6M5_Init_UART(huskylens_ra6m5_t * p_driver,
                                    uart_instance_t const * p_uart,
                                    uint32_t timeout_ms)
{
    fsp_err_t err;

    if ((NULL == p_driver) || (NULL == p_uart) || (NULL == p_uart->p_api) ||
        (NULL == p_uart->p_ctrl) || (NULL == p_uart->p_cfg))
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    memset(p_driver, 0, sizeof(*p_driver));
    p_driver->timeout_ms = (0U == timeout_ms) ? HUSKYLENS_DEFAULT_TIMEOUT_MS : timeout_ms;
    p_driver->p_uart = p_uart;
    p_driver->last_fsp_error = FSP_SUCCESS;

    err = p_uart->p_api->open(p_uart->p_ctrl, p_uart->p_cfg);

    if (FSP_SUCCESS == err)
    {
        p_driver->transport_opened_by_driver = true;
    }
    else if (FSP_ERR_ALREADY_OPEN == err)
    {
        p_driver->transport_opened_by_driver = false;
    }
    else
    {
        p_driver->last_fsp_error = err;
        return err;
    }

    err = p_uart->p_api->callbackSet(p_uart->p_ctrl,
                                     huskylens_uart_callback,
                                     p_driver,
                                     &p_driver->uart_callback_memory);

    if (FSP_SUCCESS != err)
    {
        p_driver->last_fsp_error = err;

        if (p_driver->transport_opened_by_driver)
        {
            (void) p_uart->p_api->close(p_uart->p_ctrl);
        }

        return err;
    }

    p_driver->initialized = true;
    huskylens_reset_runtime(p_driver);

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Closes the transport when it was opened by this driver.
 *
 * @param[in,out] p_driver Driver object.
 *
 * @retval FSP_SUCCESS              Driver closed successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT p_driver is NULL.
 * @return Any FSP close error from the UART transport.
 **********************************************************************************************************************/
fsp_err_t HuskyLens_RA6M5_Close(huskylens_ra6m5_t * p_driver)
{
    fsp_err_t err = FSP_SUCCESS;

    if (NULL == p_driver)
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    if (p_driver->initialized && p_driver->transport_opened_by_driver)
    {
        if (NULL != p_driver->p_uart)
        {
            err = p_driver->p_uart->p_api->close(p_driver->p_uart->p_ctrl);
        }
        else
        {
            err = FSP_ERR_INVALID_ARGUMENT;
        }
    }

    p_driver->initialized = false;
    p_driver->last_fsp_error = err;

    return err;
}

/*******************************************************************************************************************//**
 * @brief Tests communication by sending COMMAND_REQUEST_KNOCK and waiting for COMMAND_RETURN_OK.
 *
 * The published Arduino library retries the knock command up to five times. This driver uses the same bring-up behavior.
 *
 * @param[in,out] p_driver Driver object.
 *
 * @retval HUSKYLENS_STATUS_OK Communication is working.
 * @return HuskyLens driver status code describing the failure.
 **********************************************************************************************************************/
huskylens_status_t HuskyLens_RA6M5_Ping(huskylens_ra6m5_t * p_driver)
{
    huskylens_status_t status = HUSKYLENS_STATUS_TIMEOUT;
    uint32_t retry;

    if ((NULL == p_driver) || !p_driver->initialized)
    {
        return HUSKYLENS_STATUS_NOT_INITIALIZED;
    }

    for (retry = 0U; retry < HUSKYLENS_KNOCK_RETRY_COUNT; retry++)
    {
        status = huskylens_command_wait_ok(p_driver,
                                           HUSKYLENS_CMD_REQUEST_KNOCK,
                                           NULL,
                                           0U);

        if (HUSKYLENS_STATUS_OK == status)
        {
            return status;
        }

        R_BSP_SoftwareDelay(10U, BSP_DELAY_UNITS_MILLISECONDS);
    }

    return status;
}

/*******************************************************************************************************************//**
 * @brief Selects the active HuskyLens AI algorithm.
 *
 * @param[in,out] p_driver  Driver object.
 * @param[in]     algorithm Requested AI algorithm.
 *
 * @retval HUSKYLENS_STATUS_OK Algorithm changed successfully.
 * @return HuskyLens driver status code describing the failure.
 **********************************************************************************************************************/
huskylens_status_t HuskyLens_RA6M5_Set_Algorithm(huskylens_ra6m5_t * p_driver,
                                                 huskylens_algorithm_t algorithm)
{
    uint8_t payload[2];

    if ((uint32_t) algorithm > (uint32_t) HUSKYLENS_ALGORITHM_OBJECT_CLASSIFICATION)
    {
        return HUSKYLENS_STATUS_INVALID_ARGUMENT;
    }

    huskylens_write_le_u16(payload, (uint16_t) algorithm);

    return huskylens_command_wait_ok(p_driver,
                                     HUSKYLENS_CMD_REQUEST_ALGORITHM,
                                     payload,
                                     (uint8_t) sizeof(payload));
}

/*******************************************************************************************************************//**
 * @brief Requests all blocks and arrows detected in the current frame.
 **********************************************************************************************************************/
huskylens_status_t HuskyLens_RA6M5_Request_All(huskylens_ra6m5_t * p_driver)
{
    return huskylens_request_results(p_driver, HUSKYLENS_CMD_REQUEST, NULL, 0U);
}

/*******************************************************************************************************************//**
 * @brief Requests only block results detected in the current frame.
 **********************************************************************************************************************/
huskylens_status_t HuskyLens_RA6M5_Request_Blocks(huskylens_ra6m5_t * p_driver)
{
    return huskylens_request_results(p_driver, HUSKYLENS_CMD_REQUEST_BLOCKS, NULL, 0U);
}

/*******************************************************************************************************************//**
 * @brief Requests only arrow results detected in the current frame.
 **********************************************************************************************************************/
huskylens_status_t HuskyLens_RA6M5_Request_Arrows(huskylens_ra6m5_t * p_driver)
{
    return huskylens_request_results(p_driver, HUSKYLENS_CMD_REQUEST_ARROWS, NULL, 0U);
}

/*******************************************************************************************************************//**
 * @brief Requests all learned blocks and arrows with ID greater than or equal to one.
 **********************************************************************************************************************/
huskylens_status_t HuskyLens_RA6M5_Request_Learned(huskylens_ra6m5_t * p_driver)
{
    return huskylens_request_results(p_driver, HUSKYLENS_CMD_REQUEST_LEARNED, NULL, 0U);
}

/*******************************************************************************************************************//**
 * @brief Requests learned block results only.
 **********************************************************************************************************************/
huskylens_status_t HuskyLens_RA6M5_Request_Blocks_Learned(huskylens_ra6m5_t * p_driver)
{
    return huskylens_request_results(p_driver, HUSKYLENS_CMD_REQUEST_BLOCKS_LEARNED, NULL, 0U);
}

/*******************************************************************************************************************//**
 * @brief Requests learned arrow results only.
 **********************************************************************************************************************/
huskylens_status_t HuskyLens_RA6M5_Request_Arrows_Learned(huskylens_ra6m5_t * p_driver)
{
    return huskylens_request_results(p_driver, HUSKYLENS_CMD_REQUEST_ARROWS_LEARNED, NULL, 0U);
}

/*******************************************************************************************************************//**
 * @brief Requests all result types for one learned ID.
 *
 * @param[in,out] p_driver Driver object.
 * @param[in]     id       Learned object ID.
 **********************************************************************************************************************/
huskylens_status_t HuskyLens_RA6M5_Request_By_ID(huskylens_ra6m5_t * p_driver, uint16_t id)
{
    uint8_t payload[2];

    huskylens_write_le_u16(payload, id);
    return huskylens_request_results(p_driver,
                                     HUSKYLENS_CMD_REQUEST_BY_ID,
                                     payload,
                                     (uint8_t) sizeof(payload));
}

/*******************************************************************************************************************//**
 * @brief Requests block results for one learned ID.
 **********************************************************************************************************************/
huskylens_status_t HuskyLens_RA6M5_Request_Blocks_By_ID(huskylens_ra6m5_t * p_driver, uint16_t id)
{
    uint8_t payload[2];

    huskylens_write_le_u16(payload, id);
    return huskylens_request_results(p_driver,
                                     HUSKYLENS_CMD_REQUEST_BLOCKS_BY_ID,
                                     payload,
                                     (uint8_t) sizeof(payload));
}

/*******************************************************************************************************************//**
 * @brief Requests arrow results for one learned ID.
 **********************************************************************************************************************/
huskylens_status_t HuskyLens_RA6M5_Request_Arrows_By_ID(huskylens_ra6m5_t * p_driver, uint16_t id)
{
    uint8_t payload[2];

    huskylens_write_le_u16(payload, id);
    return huskylens_request_results(p_driver,
                                     HUSKYLENS_CMD_REQUEST_ARROWS_BY_ID,
                                     payload,
                                     (uint8_t) sizeof(payload));
}

/*******************************************************************************************************************//**
 * @brief Learns the currently recognized object using the requested ID.
 **********************************************************************************************************************/
huskylens_status_t HuskyLens_RA6M5_Learn(huskylens_ra6m5_t * p_driver, uint16_t id)
{
    uint8_t payload[2];

    if (0U == id)
    {
        return HUSKYLENS_STATUS_INVALID_ARGUMENT;
    }

    huskylens_write_le_u16(payload, id);

    return huskylens_command_wait_ok(p_driver,
                                     HUSKYLENS_CMD_REQUEST_LEARN,
                                     payload,
                                     (uint8_t) sizeof(payload));
}

/*******************************************************************************************************************//**
 * @brief Forgets learned objects for the currently active algorithm.
 **********************************************************************************************************************/
huskylens_status_t HuskyLens_RA6M5_Forget(huskylens_ra6m5_t * p_driver)
{
    return huskylens_command_wait_ok(p_driver, HUSKYLENS_CMD_REQUEST_FORGET, NULL, 0U);
}

/*******************************************************************************************************************//**
 * @brief Assigns a custom name to one learned object ID.
 *
 * @param[in,out] p_driver Driver object.
 * @param[in]     id       Learned object ID in the range 1 through 255.
 * @param[in]     p_name   Null-terminated name, maximum 20 characters.
 **********************************************************************************************************************/
huskylens_status_t HuskyLens_RA6M5_Set_Custom_Name(huskylens_ra6m5_t * p_driver,
                                                    uint8_t id,
                                                    char const * p_name)
{
    uint8_t payload[HUSKYLENS_CUSTOM_NAME_MAX_LENGTH + 3U];
    size_t name_length;

    if ((0U == id) || (NULL == p_name))
    {
        return HUSKYLENS_STATUS_INVALID_ARGUMENT;
    }

    name_length = strlen(p_name);

    if ((0U == name_length) || (name_length > HUSKYLENS_CUSTOM_NAME_MAX_LENGTH))
    {
        return HUSKYLENS_STATUS_INVALID_ARGUMENT;
    }

    payload[0] = id;
    payload[1] = (uint8_t) (name_length + 1U);
    memcpy(&payload[2], p_name, name_length);
    payload[name_length + 2U] = 0U;

    return huskylens_command_wait_ok(p_driver,
                                     HUSKYLENS_CMD_REQUEST_CUSTOM_NAME,
                                     payload,
                                     (uint8_t) (name_length + 3U));
}

/*******************************************************************************************************************//**
 * @brief Requests HuskyLens to save a camera photo to its SD card.
 **********************************************************************************************************************/
huskylens_status_t HuskyLens_RA6M5_Save_Photo(huskylens_ra6m5_t * p_driver)
{
    return huskylens_command_wait_ok(p_driver, HUSKYLENS_CMD_REQUEST_PHOTO, NULL, 0U);
}

/*******************************************************************************************************************//**
 * @brief Requests HuskyLens to save the current UI screenshot to its SD card.
 **********************************************************************************************************************/
huskylens_status_t HuskyLens_RA6M5_Save_Screenshot(huskylens_ra6m5_t * p_driver)
{
    return huskylens_command_wait_ok(p_driver, HUSKYLENS_CMD_REQUEST_SAVE_SCREENSHOT, NULL, 0U);
}

/*******************************************************************************************************************//**
 * @brief Saves the current algorithm model to an SD-card slot.
 **********************************************************************************************************************/
huskylens_status_t HuskyLens_RA6M5_Save_Model(huskylens_ra6m5_t * p_driver, uint16_t file_number)
{
    uint8_t payload[2];

    huskylens_write_le_u16(payload, file_number);
    return huskylens_command_wait_ok(p_driver,
                                     HUSKYLENS_CMD_REQUEST_SAVE_MODEL,
                                     payload,
                                     (uint8_t) sizeof(payload));
}

/*******************************************************************************************************************//**
 * @brief Loads an algorithm model from an SD-card slot.
 **********************************************************************************************************************/
huskylens_status_t HuskyLens_RA6M5_Load_Model(huskylens_ra6m5_t * p_driver, uint16_t file_number)
{
    uint8_t payload[2];

    huskylens_write_le_u16(payload, file_number);
    return huskylens_command_wait_ok(p_driver,
                                     HUSKYLENS_CMD_REQUEST_LOAD_MODEL,
                                     payload,
                                     (uint8_t) sizeof(payload));
}

/*******************************************************************************************************************//**
 * @brief Queries whether the connected HuskyLens reports itself as a Pro model.
 *
 * @param[in,out] p_driver Driver object.
 * @param[out]    p_is_pro Receives true for a Pro model and false for a standard model.
 **********************************************************************************************************************/
huskylens_status_t HuskyLens_RA6M5_Is_Pro(huskylens_ra6m5_t * p_driver, bool * p_is_pro)
{
    huskylens_frame_t frame;
    huskylens_status_t status;

    if (NULL == p_is_pro)
    {
        return HUSKYLENS_STATUS_INVALID_ARGUMENT;
    }

    status = huskylens_send_command(p_driver, HUSKYLENS_CMD_REQUEST_IS_PRO, NULL, 0U);

    if (HUSKYLENS_STATUS_OK != status)
    {
        return status;
    }

    status = huskylens_wait_for_command(p_driver, HUSKYLENS_CMD_REQUEST_IS_PRO, &frame);

    if (HUSKYLENS_STATUS_OK != status)
    {
        return status;
    }

    if (2U != frame.payload_length)
    {
        return HUSKYLENS_STATUS_PROTOCOL_ERROR;
    }

    *p_is_pro = (0 != huskylens_read_le_i16(frame.payload));
    return HUSKYLENS_STATUS_OK;
}

/*******************************************************************************************************************//**
 * @brief Returns the most recently decoded information frame.
 **********************************************************************************************************************/
huskylens_info_t const * HuskyLens_RA6M5_Get_Info(huskylens_ra6m5_t const * p_driver)
{
    return (NULL != p_driver) ? &p_driver->info : NULL;
}

/*******************************************************************************************************************//**
 * @brief Returns the number of decoded results stored by the most recent request.
 **********************************************************************************************************************/
size_t HuskyLens_RA6M5_Get_Result_Count(huskylens_ra6m5_t const * p_driver)
{
    return (NULL != p_driver) ? p_driver->result_count : 0U;
}

/*******************************************************************************************************************//**
 * @brief Returns one decoded result by zero-based index.
 **********************************************************************************************************************/
huskylens_result_t const * HuskyLens_RA6M5_Get_Result(huskylens_ra6m5_t const * p_driver, size_t index)
{
    if ((NULL == p_driver) || (index >= p_driver->result_count))
    {
        return NULL;
    }

    return &p_driver->results[index];
}

/*******************************************************************************************************************//**
 * @brief Returns the last raw FSP error captured by a transport operation.
 **********************************************************************************************************************/
fsp_err_t HuskyLens_RA6M5_Get_Last_FSP_Error(huskylens_ra6m5_t const * p_driver)
{
    return (NULL != p_driver) ? p_driver->last_fsp_error : FSP_ERR_INVALID_ARGUMENT;
}

/*******************************************************************************************************************//**
 * @} (end addtogroup HuskyLens_RA6M5)
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * @brief Resets parser/transport state while preserving configuration fields.
 **********************************************************************************************************************/
static void huskylens_reset_runtime(huskylens_ra6m5_t * p_driver)
{
    p_driver->uart_tx_complete = false;
    p_driver->uart_error = false;
    p_driver->uart_rx_head = 0U;
    p_driver->uart_rx_tail = 0U;
    p_driver->result_count = 0U;
    memset(&p_driver->info, 0, sizeof(p_driver->info));
    memset(p_driver->results, 0, sizeof(p_driver->results));
}

/*******************************************************************************************************************//**
 * @brief Discards stale receive bytes before starting a new command transaction.
 **********************************************************************************************************************/
static void huskylens_flush_transport_rx(huskylens_ra6m5_t * p_driver)
{
    p_driver->uart_rx_tail = p_driver->uart_rx_head;
}

/*******************************************************************************************************************//**
 * @brief Calculates the low byte of the additive HuskyLens checksum.
 **********************************************************************************************************************/
static uint8_t huskylens_checksum(uint8_t const * p_data, size_t length)
{
    uint32_t sum = 0U;
    size_t index;

    for (index = 0U; index < length; index++)
    {
        sum += p_data[index];
    }

    return (uint8_t) (sum & 0xFFU);
}

/*******************************************************************************************************************//**
 * @brief Builds one complete HuskyLens command frame.
 **********************************************************************************************************************/
static size_t huskylens_build_frame(uint8_t command,
                                    uint8_t const * p_payload,
                                    uint8_t payload_length,
                                    uint8_t * p_frame,
                                    size_t frame_capacity)
{
    size_t frame_length = (size_t) payload_length + HUSKYLENS_FRAME_FIXED_SIZE;

    if ((NULL == p_frame) || (frame_capacity < frame_length) ||
        (payload_length > HUSKYLENS_MAX_PAYLOAD_SIZE) ||
        ((0U != payload_length) && (NULL == p_payload)))
    {
        return 0U;
    }

    p_frame[0] = HUSKYLENS_PROTOCOL_HEADER_0;
    p_frame[1] = HUSKYLENS_PROTOCOL_HEADER_1;
    p_frame[2] = HUSKYLENS_PROTOCOL_ADDRESS;
    p_frame[3] = payload_length;
    p_frame[4] = command;

    if (0U != payload_length)
    {
        memcpy(&p_frame[HUSKYLENS_FRAME_DATA_START_INDEX], p_payload, payload_length);
    }

    p_frame[frame_length - 1U] = huskylens_checksum(p_frame, frame_length - 1U);

    return frame_length;
}

/*******************************************************************************************************************//**
 * @brief Reads a little-endian signed 16-bit field from a protocol payload.
 **********************************************************************************************************************/
static int16_t huskylens_read_le_i16(uint8_t const * p_data)
{
    uint16_t value = (uint16_t) p_data[0] | ((uint16_t) p_data[1] << 8U);
    return (int16_t) value;
}

/*******************************************************************************************************************//**
 * @brief Writes a 16-bit field in little-endian order.
 **********************************************************************************************************************/
static void huskylens_write_le_u16(uint8_t * p_data, uint16_t value)
{
    p_data[0] = (uint8_t) (value & 0xFFU);
    p_data[1] = (uint8_t) ((value >> 8U) & 0xFFU);
}

/*******************************************************************************************************************//**
 * @brief Writes raw bytes through the FSP UART transport.
 **********************************************************************************************************************/
static huskylens_status_t huskylens_transport_write(huskylens_ra6m5_t * p_driver,
                                                    uint8_t const * p_data,
                                                    size_t length)
{
    if ((NULL == p_driver) || !p_driver->initialized)
    {
        return HUSKYLENS_STATUS_NOT_INITIALIZED;
    }

    if ((NULL == p_data) || (0U == length))
    {
        return HUSKYLENS_STATUS_INVALID_ARGUMENT;
    }

    return huskylens_uart_write(p_driver, p_data, length);
}

/*******************************************************************************************************************//**
 * @brief Gets one byte from the UART ring buffer.
 **********************************************************************************************************************/
static huskylens_status_t huskylens_transport_get_byte(huskylens_ra6m5_t * p_driver,
                                                       uint8_t * p_byte,
                                                       uint32_t timeout_ms)
{
    uint32_t elapsed_ms = 0U;

    if ((NULL == p_driver) || (NULL == p_byte))
    {
        return HUSKYLENS_STATUS_INVALID_ARGUMENT;
    }

    while (elapsed_ms < timeout_ms)
    {
        if (p_driver->uart_error)
        {
            p_driver->uart_error = false;
            return HUSKYLENS_STATUS_FSP_ERROR;
        }

        if (huskylens_uart_ring_pop(p_driver, p_byte))
        {
            return HUSKYLENS_STATUS_OK;
        }

        R_BSP_SoftwareDelay(1U, BSP_DELAY_UNITS_MILLISECONDS);
        elapsed_ms++;
    }

    return HUSKYLENS_STATUS_TIMEOUT;
}

/*******************************************************************************************************************//**
 * @brief Sends one UART frame and waits for the physical transmit-complete event.
 **********************************************************************************************************************/
static huskylens_status_t huskylens_uart_write(huskylens_ra6m5_t * p_driver,
                                               uint8_t const * p_data,
                                               size_t length)
{
    fsp_err_t err;
    uint32_t elapsed_ms = 0U;

    p_driver->uart_tx_complete = false;
    p_driver->uart_error = false;

    err = p_driver->p_uart->p_api->write(p_driver->p_uart->p_ctrl, p_data, (uint32_t) length);

    if (FSP_SUCCESS != err)
    {
        p_driver->last_fsp_error = err;
        return HUSKYLENS_STATUS_FSP_ERROR;
    }

    while (!p_driver->uart_tx_complete && !p_driver->uart_error && (elapsed_ms < p_driver->timeout_ms))
    {
        R_BSP_SoftwareDelay(1U, BSP_DELAY_UNITS_MILLISECONDS);
        elapsed_ms++;
    }

    if (p_driver->uart_error)
    {
        return HUSKYLENS_STATUS_FSP_ERROR;
    }

    if (!p_driver->uart_tx_complete)
    {
        return HUSKYLENS_STATUS_TIMEOUT;
    }

    return HUSKYLENS_STATUS_OK;
}

/*******************************************************************************************************************//**
 * @brief Pops one byte from the interrupt-driven UART receive ring.
 **********************************************************************************************************************/
static bool huskylens_uart_ring_pop(huskylens_ra6m5_t * p_driver, uint8_t * p_byte)
{
    uint16_t tail = p_driver->uart_rx_tail;

    if (tail == p_driver->uart_rx_head)
    {
        return false;
    }

    *p_byte = p_driver->uart_rx_ring[tail];
    tail++;

    if (tail >= HUSKYLENS_UART_RX_RING_SIZE)
    {
        tail = 0U;
    }

    p_driver->uart_rx_tail = tail;
    return true;
}

/*******************************************************************************************************************//**
 * @brief Receives and validates one complete protocol frame.
 **********************************************************************************************************************/
static huskylens_status_t huskylens_receive_frame(huskylens_ra6m5_t * p_driver,
                                                  huskylens_frame_t * p_frame,
                                                  uint32_t timeout_ms)
{
    uint8_t raw[HUSKYLENS_FRAME_MAX_SIZE];
    uint8_t byte;
    uint8_t payload_length;
    size_t index;
    size_t total_length;
    huskylens_status_t status;

    if ((NULL == p_driver) || (NULL == p_frame))
    {
        return HUSKYLENS_STATUS_INVALID_ARGUMENT;
    }

    /* Synchronize to 0x55 0xAA. */
    while (true)
    {
        status = huskylens_transport_get_byte(p_driver, &byte, timeout_ms);

        if (HUSKYLENS_STATUS_OK != status)
        {
            return status;
        }

        if (HUSKYLENS_PROTOCOL_HEADER_0 != byte)
        {
            continue;
        }

        status = huskylens_transport_get_byte(p_driver, &byte, timeout_ms);

        if (HUSKYLENS_STATUS_OK != status)
        {
            return status;
        }

        if (HUSKYLENS_PROTOCOL_HEADER_1 == byte)
        {
            break;
        }
    }

    raw[0] = HUSKYLENS_PROTOCOL_HEADER_0;
    raw[1] = HUSKYLENS_PROTOCOL_HEADER_1;

    for (index = 2U; index < 5U; index++)
    {
        status = huskylens_transport_get_byte(p_driver, &raw[index], timeout_ms);

        if (HUSKYLENS_STATUS_OK != status)
        {
            return status;
        }
    }

    if (HUSKYLENS_PROTOCOL_ADDRESS != raw[2])
    {
        return HUSKYLENS_STATUS_PROTOCOL_ERROR;
    }

    payload_length = raw[3];

    if (payload_length > HUSKYLENS_MAX_PAYLOAD_SIZE)
    {
        return HUSKYLENS_STATUS_OVERFLOW;
    }

    total_length = (size_t) payload_length + HUSKYLENS_FRAME_FIXED_SIZE;

    for (index = 5U; index < total_length; index++)
    {
        status = huskylens_transport_get_byte(p_driver, &raw[index], timeout_ms);

        if (HUSKYLENS_STATUS_OK != status)
        {
            return status;
        }
    }

    if (raw[total_length - 1U] != huskylens_checksum(raw, total_length - 1U))
    {
        return HUSKYLENS_STATUS_CHECKSUM_ERROR;
    }

    p_frame->command = raw[4];
    p_frame->payload_length = payload_length;

    if (0U != payload_length)
    {
        memcpy(p_frame->payload, &raw[5], payload_length);
    }

    return HUSKYLENS_STATUS_OK;
}

/*******************************************************************************************************************//**
 * @brief Waits for a requested response command and maps BUSY/NEED_PRO frames to driver status values.
 **********************************************************************************************************************/
static huskylens_status_t huskylens_wait_for_command(huskylens_ra6m5_t * p_driver,
                                                     uint8_t expected_command,
                                                     huskylens_frame_t * p_frame)
{
    huskylens_status_t status;
    uint32_t attempts = 0U;

    while (attempts < 8U)
    {
        status = huskylens_receive_frame(p_driver, p_frame, p_driver->timeout_ms);

        if (HUSKYLENS_STATUS_OK != status)
        {
            return status;
        }

        if (HUSKYLENS_CMD_RETURN_BUSY == p_frame->command)
        {
            return HUSKYLENS_STATUS_BUSY;
        }

        if (HUSKYLENS_CMD_RETURN_NEED_PRO == p_frame->command)
        {
            return HUSKYLENS_STATUS_NEED_PRO;
        }

        if (expected_command == p_frame->command)
        {
            return HUSKYLENS_STATUS_OK;
        }

        attempts++;
    }

    return HUSKYLENS_STATUS_PROTOCOL_ERROR;
}

/*******************************************************************************************************************//**
 * @brief Encodes and sends one command frame.
 **********************************************************************************************************************/
static huskylens_status_t huskylens_send_command(huskylens_ra6m5_t * p_driver,
                                                 uint8_t command,
                                                 uint8_t const * p_payload,
                                                 uint8_t payload_length)
{
    uint8_t frame[HUSKYLENS_FRAME_MAX_SIZE];
    size_t frame_length;

    if ((NULL == p_driver) || !p_driver->initialized)
    {
        return HUSKYLENS_STATUS_NOT_INITIALIZED;
    }

    frame_length = huskylens_build_frame(command,
                                         p_payload,
                                         payload_length,
                                         frame,
                                         sizeof(frame));

    if (0U == frame_length)
    {
        return HUSKYLENS_STATUS_INVALID_ARGUMENT;
    }

    huskylens_flush_transport_rx(p_driver);
    return huskylens_transport_write(p_driver, frame, frame_length);
}

/*******************************************************************************************************************//**
 * @brief Sends a command that is acknowledged with COMMAND_RETURN_OK.
 **********************************************************************************************************************/
static huskylens_status_t huskylens_command_wait_ok(huskylens_ra6m5_t * p_driver,
                                                    uint8_t command,
                                                    uint8_t const * p_payload,
                                                    uint8_t payload_length)
{
    huskylens_frame_t frame;
    huskylens_status_t status;

    status = huskylens_send_command(p_driver, command, p_payload, payload_length);

    if (HUSKYLENS_STATUS_OK != status)
    {
        return status;
    }

    return huskylens_wait_for_command(p_driver, HUSKYLENS_CMD_RETURN_OK, &frame);
}

/*******************************************************************************************************************//**
 * @brief Runs one result request transaction and decodes INFO followed by BLOCK/ARROW frames.
 **********************************************************************************************************************/
static huskylens_status_t huskylens_request_results(huskylens_ra6m5_t * p_driver,
                                                    uint8_t command,
                                                    uint8_t const * p_payload,
                                                    uint8_t payload_length)
{
    huskylens_frame_t frame;
    huskylens_status_t status;
    int16_t expected_results;
    int16_t index;
    bool overflow = false;

    if ((NULL == p_driver) || !p_driver->initialized)
    {
        return HUSKYLENS_STATUS_NOT_INITIALIZED;
    }

    p_driver->result_count = 0U;
    memset(&p_driver->info, 0, sizeof(p_driver->info));

    status = huskylens_send_command(p_driver, command, p_payload, payload_length);

    if (HUSKYLENS_STATUS_OK != status)
    {
        return status;
    }

    status = huskylens_wait_for_command(p_driver, HUSKYLENS_CMD_RETURN_INFO, &frame);

    if (HUSKYLENS_STATUS_OK != status)
    {
        return status;
    }

    status = huskylens_decode_info(p_driver, &frame);

    if (HUSKYLENS_STATUS_OK != status)
    {
        return status;
    }

    expected_results = p_driver->info.result_count;

    if (expected_results < 0)
    {
        return HUSKYLENS_STATUS_PROTOCOL_ERROR;
    }

    for (index = 0; index < expected_results; index++)
    {
        status = huskylens_receive_frame(p_driver, &frame, p_driver->timeout_ms);

        if (HUSKYLENS_STATUS_OK != status)
        {
            return status;
        }

        if (HUSKYLENS_CMD_RETURN_BUSY == frame.command)
        {
            return HUSKYLENS_STATUS_BUSY;
        }

        if ((HUSKYLENS_CMD_RETURN_BLOCK != frame.command) &&
            (HUSKYLENS_CMD_RETURN_ARROW != frame.command))
        {
            return HUSKYLENS_STATUS_PROTOCOL_ERROR;
        }

        if (p_driver->result_count < HUSKYLENS_MAX_RESULTS)
        {
            status = huskylens_decode_result(&frame, &p_driver->results[p_driver->result_count]);

            if (HUSKYLENS_STATUS_OK != status)
            {
                return status;
            }

            p_driver->result_count++;
        }
        else
        {
            overflow = true;
        }
    }

    return overflow ? HUSKYLENS_STATUS_OVERFLOW : HUSKYLENS_STATUS_OK;
}

/*******************************************************************************************************************//**
 * @brief Decodes COMMAND_RETURN_INFO.
 **********************************************************************************************************************/
static huskylens_status_t huskylens_decode_info(huskylens_ra6m5_t * p_driver,
                                                huskylens_frame_t const * p_frame)
{
    if ((HUSKYLENS_CMD_RETURN_INFO != p_frame->command) ||
        (HUSKYLENS_INFO_PAYLOAD_SIZE != p_frame->payload_length))
    {
        return HUSKYLENS_STATUS_PROTOCOL_ERROR;
    }

    p_driver->info.result_count = huskylens_read_le_i16(&p_frame->payload[0]);
    p_driver->info.learned_id_count = huskylens_read_le_i16(&p_frame->payload[2]);
    p_driver->info.frame_number = huskylens_read_le_i16(&p_frame->payload[4]);

    return HUSKYLENS_STATUS_OK;
}

/*******************************************************************************************************************//**
 * @brief Decodes one BLOCK or ARROW result frame.
 **********************************************************************************************************************/
static huskylens_status_t huskylens_decode_result(huskylens_frame_t const * p_frame,
                                                  huskylens_result_t * p_result)
{
    if ((NULL == p_frame) || (NULL == p_result) ||
        (HUSKYLENS_RESULT_PAYLOAD_SIZE != p_frame->payload_length))
    {
        return HUSKYLENS_STATUS_PROTOCOL_ERROR;
    }

    if (HUSKYLENS_CMD_RETURN_BLOCK == p_frame->command)
    {
        p_result->type = HUSKYLENS_RESULT_BLOCK;
        p_result->data.block.x_center = huskylens_read_le_i16(&p_frame->payload[0]);
        p_result->data.block.y_center = huskylens_read_le_i16(&p_frame->payload[2]);
        p_result->data.block.width = huskylens_read_le_i16(&p_frame->payload[4]);
        p_result->data.block.height = huskylens_read_le_i16(&p_frame->payload[6]);
        p_result->data.block.id = huskylens_read_le_i16(&p_frame->payload[8]);
        return HUSKYLENS_STATUS_OK;
    }

    if (HUSKYLENS_CMD_RETURN_ARROW == p_frame->command)
    {
        p_result->type = HUSKYLENS_RESULT_ARROW;
        p_result->data.arrow.x_origin = huskylens_read_le_i16(&p_frame->payload[0]);
        p_result->data.arrow.y_origin = huskylens_read_le_i16(&p_frame->payload[2]);
        p_result->data.arrow.x_target = huskylens_read_le_i16(&p_frame->payload[4]);
        p_result->data.arrow.y_target = huskylens_read_le_i16(&p_frame->payload[6]);
        p_result->data.arrow.id = huskylens_read_le_i16(&p_frame->payload[8]);
        return HUSKYLENS_STATUS_OK;
    }

    return HUSKYLENS_STATUS_PROTOCOL_ERROR;
}

/*******************************************************************************************************************//**
 * @brief Receives UART characters and transmit/error events from FSP.
 **********************************************************************************************************************/
static void huskylens_uart_callback(uart_callback_args_t * p_args)
{
    huskylens_ra6m5_t * p_driver;
    uint16_t next_head;

    if ((NULL == p_args) || (NULL == p_args->p_context))
    {
        return;
    }

    p_driver = (huskylens_ra6m5_t *) p_args->p_context;

    switch (p_args->event)
    {
        case UART_EVENT_RX_CHAR:
            next_head = (uint16_t) (p_driver->uart_rx_head + 1U);

            if (next_head >= HUSKYLENS_UART_RX_RING_SIZE)
            {
                next_head = 0U;
            }

            if (next_head != p_driver->uart_rx_tail)
            {
                p_driver->uart_rx_ring[p_driver->uart_rx_head] = (uint8_t) p_args->data;
                p_driver->uart_rx_head = next_head;
            }
            else
            {
                p_driver->uart_error = true;
            }
            break;

        case UART_EVENT_TX_COMPLETE:
            p_driver->uart_tx_complete = true;
            break;

        case UART_EVENT_ERR_PARITY:
        case UART_EVENT_ERR_FRAMING:
        case UART_EVENT_ERR_OVERFLOW:
        case UART_EVENT_BREAK_DETECT:
            p_driver->uart_error = true;
            break;

        default:
            break;
    }
}
