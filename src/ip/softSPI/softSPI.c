/*******************************************************************************************************************//**
 * @file soft_spi_ra6m5.c
 * @brief Implements the GPIO-based software SPI driver for the Renesas RA6M5.
 *
 * This file generates SPI clock, MOSI, chip-select, and MISO sampling in software by using the Renesas FSP IOPORT API.
 * No SCI/SPI hardware peripheral is required, which allows the interface to be used as a hardware-workaround path for
 * low/medium-speed devices such as a touchscreen controller.
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/

#include "softSPI.h"

/***********************************************************************************************************************
 * Macro definitions
 **********************************************************************************************************************/


/***********************************************************************************************************************
 * Typedef definitions
 **********************************************************************************************************************/


/***********************************************************************************************************************
 * Private function declarations
 **********************************************************************************************************************/

static fsp_err_t SoftSPI_ValidateHandle(soft_spi_handle_t const * hspi);
static inline void SoftSPI_Delay(soft_spi_handle_t const * hspi);
static inline fsp_err_t SoftSPI_WritePin(soft_spi_handle_t const * hspi,
                                         bsp_io_port_pin_t pin,
                                         bsp_io_level_t level);
static inline uint8_t SoftSPI_ReadPin(soft_spi_handle_t const * hspi,
                                      bsp_io_port_pin_t pin);
static inline bsp_io_level_t SoftSPI_GetIdleClock(soft_spi_handle_t const * hspi);
static inline bsp_io_level_t SoftSPI_GetActiveClock(soft_spi_handle_t const * hspi);

/***********************************************************************************************************************
 * Private global variables
 **********************************************************************************************************************/


/***********************************************************************************************************************
 * Global variables
 **********************************************************************************************************************/


/*******************************************************************************************************************//**
 * @addtogroup SOFT_SPI_RA6M5
 * @{
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Functions
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * @brief Validates a software SPI handle and its mode configuration.
 *
 * @details The function verifies the handle, the FSP IOPORT control pointer, and all software SPI mode selections before
 *          the driver accesses any GPIO pin.
 *
 * @param[in] hspi Pointer to the software SPI handle to validate.
 *
 * @retval FSP_SUCCESS              Handle and configuration are valid.
 * @retval FSP_ERR_INVALID_ARGUMENT Handle, IOPORT control pointer, or SPI mode configuration is invalid.
 **********************************************************************************************************************/
static fsp_err_t SoftSPI_ValidateHandle(soft_spi_handle_t const * hspi)
{
    if ((NULL == hspi) || (NULL == hspi->p_ioport_ctrl))
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    if ((hspi->cfg.cpol > SOFT_SPI_CPOL_HIGH) ||
        (hspi->cfg.cpha > SOFT_SPI_CPHA_2EDGE) ||
        (hspi->cfg.first_bit > SOFT_SPI_FIRSTBIT_LSB))
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Delays for the configured half-clock period.
 *
 * @param[in] hspi Pointer to the software SPI handle.
 *
 * @note The delay is implemented with R_BSP_SoftwareDelay() and therefore is intended for low/medium-speed SPI use.
 **********************************************************************************************************************/
static inline void SoftSPI_Delay(soft_spi_handle_t const * hspi)
{
    if (hspi->cfg.half_period_us > 0U)
    {
        R_BSP_SoftwareDelay(hspi->cfg.half_period_us, BSP_DELAY_UNITS_MICROSECONDS);
    }
}

/*******************************************************************************************************************//**
 * @brief Writes one software SPI GPIO output.
 *
 * @param[in] hspi  Pointer to the software SPI handle.
 * @param[in] pin   RA6M5 BSP pin identifier.
 * @param[in] level Output level to drive.
 *
 * @return Result returned by R_IOPORT_PinWrite().
 **********************************************************************************************************************/
static inline fsp_err_t SoftSPI_WritePin(soft_spi_handle_t const * hspi,
                                         bsp_io_port_pin_t pin,
                                         bsp_io_level_t level)
{
    return R_IOPORT_PinWrite(hspi->p_ioport_ctrl, pin, level);
}

/*******************************************************************************************************************//**
 * @brief Reads one software SPI GPIO input.
 *
 * @param[in] hspi Pointer to the software SPI handle.
 * @param[in] pin  RA6M5 BSP pin identifier.
 *
 * @retval 0 Pin is LOW, or the underlying IOPORT read failed.
 * @retval 1 Pin is HIGH.
 **********************************************************************************************************************/
static inline uint8_t SoftSPI_ReadPin(soft_spi_handle_t const * hspi,
                                      bsp_io_port_pin_t pin)
{
    bsp_io_level_t level = BSP_IO_LEVEL_LOW;

    if (FSP_SUCCESS != R_IOPORT_PinRead(hspi->p_ioport_ctrl, pin, &level))
    {
        return 0U;
    }

    return (BSP_IO_LEVEL_HIGH == level) ? 1U : 0U;
}

/*******************************************************************************************************************//**
 * @brief Returns the SCK idle level defined by CPOL.
 *
 * @param[in] hspi Pointer to the software SPI handle.
 *
 * @return BSP_IO_LEVEL_LOW when CPOL is LOW; otherwise BSP_IO_LEVEL_HIGH.
 **********************************************************************************************************************/
static inline bsp_io_level_t SoftSPI_GetIdleClock(soft_spi_handle_t const * hspi)
{
    return (SOFT_SPI_CPOL_HIGH == hspi->cfg.cpol) ? BSP_IO_LEVEL_HIGH : BSP_IO_LEVEL_LOW;
}

/*******************************************************************************************************************//**
 * @brief Returns the active SCK level opposite to the CPOL-defined idle level.
 *
 * @param[in] hspi Pointer to the software SPI handle.
 *
 * @return BSP_IO_LEVEL_HIGH when the idle level is LOW; otherwise BSP_IO_LEVEL_LOW.
 **********************************************************************************************************************/
static inline bsp_io_level_t SoftSPI_GetActiveClock(soft_spi_handle_t const * hspi)
{
    return (SOFT_SPI_CPOL_HIGH == hspi->cfg.cpol) ? BSP_IO_LEVEL_LOW : BSP_IO_LEVEL_HIGH;
}

/*******************************************************************************************************************//**
 * @brief Initializes software SPI GPIO directions and idle levels.
 *
 * @details SCK, MOSI, and CS are configured as outputs while MISO is configured as an input. CS is released HIGH, SCK is
 *          driven to the idle level selected by CPOL, and MOSI is initialized LOW before the driver enters READY state.
 *
 * @param[in,out] hspi Pointer to the software SPI handle.
 *
 * @retval FSP_SUCCESS              Initialization completed successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT The handle or SPI configuration is invalid.
 * @return Any error returned by R_IOPORT_PinCfg().
 **********************************************************************************************************************/
fsp_err_t SoftSPI_Init(soft_spi_handle_t * hspi)
{
    fsp_err_t err;
    uint32_t sck_cfg;
    bsp_io_level_t idle;

    err = SoftSPI_ValidateHandle(hspi);
    if (FSP_SUCCESS != err)
    {
        return err;
    }

    idle = SoftSPI_GetIdleClock(hspi);

    sck_cfg = (uint32_t) IOPORT_CFG_PORT_DIRECTION_OUTPUT |
              (uint32_t) IOPORT_CFG_DRIVE_HIGH;

    if (BSP_IO_LEVEL_HIGH == idle)
    {
        sck_cfg |= (uint32_t) IOPORT_CFG_PORT_OUTPUT_HIGH;
    }
    else
    {
        sck_cfg |= (uint32_t) IOPORT_CFG_PORT_OUTPUT_LOW;
    }

    err = R_IOPORT_PinCfg(hspi->p_ioport_ctrl, hspi->cfg.pins.sck, sck_cfg);
    if (FSP_SUCCESS != err)
    {
        return err;
    }

    err = R_IOPORT_PinCfg(hspi->p_ioport_ctrl,
                          hspi->cfg.pins.mosi,
                          (uint32_t) IOPORT_CFG_PORT_DIRECTION_OUTPUT |
                          (uint32_t) IOPORT_CFG_PORT_OUTPUT_LOW |
                          (uint32_t) IOPORT_CFG_DRIVE_HIGH);
    if (FSP_SUCCESS != err)
    {
        return err;
    }

    err = R_IOPORT_PinCfg(hspi->p_ioport_ctrl,
                          hspi->cfg.pins.cs,
                          (uint32_t) IOPORT_CFG_PORT_DIRECTION_OUTPUT |
                          (uint32_t) IOPORT_CFG_PORT_OUTPUT_HIGH |
                          (uint32_t) IOPORT_CFG_DRIVE_HIGH);
    if (FSP_SUCCESS != err)
    {
        return err;
    }

    err = R_IOPORT_PinCfg(hspi->p_ioport_ctrl,
                          hspi->cfg.pins.miso,
                          (uint32_t) IOPORT_CFG_PORT_DIRECTION_INPUT);
    if (FSP_SUCCESS != err)
    {
        return err;
    }

    /* Apply deterministic idle bus levels after GPIO configuration. */
    (void) SoftSPI_WritePin(hspi, hspi->cfg.pins.cs, BSP_IO_LEVEL_HIGH);
    (void) SoftSPI_WritePin(hspi, hspi->cfg.pins.sck, idle);
    (void) SoftSPI_WritePin(hspi, hspi->cfg.pins.mosi, BSP_IO_LEVEL_LOW);

    hspi->state = SOFT_SPI_STATE_READY;

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Asserts or releases the active-low software SPI chip-select line.
 *
 * @param[in,out] hspi   Pointer to the software SPI handle.
 * @param[in]     enable true to assert CS LOW; false to deassert CS HIGH.
 *
 * @retval FSP_SUCCESS              Chip-select updated successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT The handle or configuration is invalid.
 * @return Any error returned by R_IOPORT_PinWrite().
 **********************************************************************************************************************/
fsp_err_t SoftSPI_ChipSelect(soft_spi_handle_t * hspi, bool enable)
{
    fsp_err_t err = SoftSPI_ValidateHandle(hspi);
    if (FSP_SUCCESS != err)
    {
        return err;
    }

    return SoftSPI_WritePin(hspi,
                            hspi->cfg.pins.cs,
                            enable ? BSP_IO_LEVEL_LOW : BSP_IO_LEVEL_HIGH);
}

/*******************************************************************************************************************//**
 * @brief Exchanges one byte on the software SPI bus.
 *
 * @details Eight software-generated SCK cycles are produced. MOSI is driven and MISO is sampled according to the
 *          configured CPOL, CPHA, and first-bit settings.
 *
 * @param[in,out] hspi    Pointer to the software SPI handle.
 * @param[in]     tx_data Byte to transmit on MOSI.
 *
 * @return Byte sampled from MISO. Returns 0 if the handle is invalid.
 *
 * @note CS is not controlled by this function.
 **********************************************************************************************************************/
uint8_t SoftSPI_TransmitReceiveByte(soft_spi_handle_t * hspi, uint8_t tx_data)
{
    uint8_t rx_data = 0U;
    uint8_t i;
    uint8_t bit_pos;
    uint8_t mosi_bit;
    bsp_io_level_t idle;
    bsp_io_level_t active;

    if (FSP_SUCCESS != SoftSPI_ValidateHandle(hspi))
    {
        return 0U;
    }

    hspi->state = SOFT_SPI_STATE_BUSY;

    idle   = SoftSPI_GetIdleClock(hspi);
    active = SoftSPI_GetActiveClock(hspi);

    for (i = 0U; i < 8U; i++)
    {
        bit_pos = (SOFT_SPI_FIRSTBIT_MSB == hspi->cfg.first_bit) ?
                  (uint8_t) (7U - i) : i;
        mosi_bit = (uint8_t) ((tx_data >> bit_pos) & 0x01U);

        if (SOFT_SPI_CPHA_1EDGE == hspi->cfg.cpha)
        {
            /* CPHA = 0: drive MOSI before the leading edge and sample MISO on the leading edge. */
            (void) SoftSPI_WritePin(hspi,
                                    hspi->cfg.pins.mosi,
                                    (0U != mosi_bit) ? BSP_IO_LEVEL_HIGH : BSP_IO_LEVEL_LOW);
            SoftSPI_Delay(hspi);

            (void) SoftSPI_WritePin(hspi, hspi->cfg.pins.sck, active);
            SoftSPI_Delay(hspi);

            if (0U != SoftSPI_ReadPin(hspi, hspi->cfg.pins.miso))
            {
                rx_data |= (uint8_t) (1U << bit_pos);
            }

            (void) SoftSPI_WritePin(hspi, hspi->cfg.pins.sck, idle);
            SoftSPI_Delay(hspi);
        }
        else
        {
            /* CPHA = 1: leading edge starts the bit period and MISO is sampled on the trailing edge. */
            (void) SoftSPI_WritePin(hspi, hspi->cfg.pins.sck, active);
            SoftSPI_Delay(hspi);

            (void) SoftSPI_WritePin(hspi,
                                    hspi->cfg.pins.mosi,
                                    (0U != mosi_bit) ? BSP_IO_LEVEL_HIGH : BSP_IO_LEVEL_LOW);
            SoftSPI_Delay(hspi);

            (void) SoftSPI_WritePin(hspi, hspi->cfg.pins.sck, idle);
            SoftSPI_Delay(hspi);

            if (0U != SoftSPI_ReadPin(hspi, hspi->cfg.pins.miso))
            {
                rx_data |= (uint8_t) (1U << bit_pos);
            }
        }
    }

    /* Guarantee that SCK returns to the configured idle state at the end of the byte. */
    (void) SoftSPI_WritePin(hspi, hspi->cfg.pins.sck, idle);
    hspi->state = SOFT_SPI_STATE_READY;

    return rx_data;
}

/*******************************************************************************************************************//**
 * @brief Transmits a byte buffer using software SPI.
 *
 * @details Every byte is shifted through SoftSPI_TransmitReceiveByte(). The simultaneously received data is intentionally
 *          discarded because this API provides transmit-only behavior to the caller.
 *
 * @param[in,out] hspi   Pointer to the software SPI handle.
 * @param[in]     p_data Pointer to the transmit buffer.
 * @param[in]     size   Number of bytes to transmit.
 *
 * @retval FSP_SUCCESS              Transmission completed successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT The handle, data pointer, or size is invalid.
 **********************************************************************************************************************/
fsp_err_t SoftSPI_Transmit(soft_spi_handle_t * hspi,
                           uint8_t const * p_data,
                           uint16_t size)
{
    uint16_t i;

    if ((FSP_SUCCESS != SoftSPI_ValidateHandle(hspi)) ||
        (NULL == p_data) ||
        (0U == size))
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    for (i = 0U; i < size; i++)
    {
        (void) SoftSPI_TransmitReceiveByte(hspi, p_data[i]);
    }

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Receives a byte buffer using software SPI.
 *
 * @details The master transmits 0xFF for every byte so that the required SCK pulses are generated while data is sampled
 *          from MISO.
 *
 * @param[in,out] hspi   Pointer to the software SPI handle.
 * @param[out]    p_data Destination buffer for received bytes.
 * @param[in]     size   Number of bytes to receive.
 *
 * @retval FSP_SUCCESS              Reception completed successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT The handle, data pointer, or size is invalid.
 *
 * @note The master transmits dummy value 0xFF for every byte in order to generate the required clock pulses.
 **********************************************************************************************************************/
fsp_err_t SoftSPI_Receive(soft_spi_handle_t * hspi,
                          uint8_t * p_data,
                          uint16_t size)
{
    uint16_t i;

    if ((FSP_SUCCESS != SoftSPI_ValidateHandle(hspi)) ||
        (NULL == p_data) ||
        (0U == size))
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    for (i = 0U; i < size; i++)
    {
        p_data[i] = SoftSPI_TransmitReceiveByte(hspi, 0xFFU);
    }

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @brief Performs a full-duplex software SPI buffer transfer.
 *
 * @details Each transmitted byte produces eight SCK cycles and the byte sampled from MISO is stored in the corresponding
 *          receive-buffer position.
 *
 * @param[in,out] hspi      Pointer to the software SPI handle.
 * @param[in]     p_tx_data Pointer to the transmit buffer.
 * @param[out]    p_rx_data Destination buffer for received bytes.
 * @param[in]     size      Number of bytes to exchange.
 *
 * @retval FSP_SUCCESS              Transfer completed successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT The handle, buffer pointers, or size is invalid.
 **********************************************************************************************************************/
fsp_err_t SoftSPI_TransmitReceive(soft_spi_handle_t * hspi,
                                  uint8_t const * p_tx_data,
                                  uint8_t * p_rx_data,
                                  uint16_t size)
{
    uint16_t i;

    if ((FSP_SUCCESS != SoftSPI_ValidateHandle(hspi)) ||
        (NULL == p_tx_data) ||
        (NULL == p_rx_data) ||
        (0U == size))
    {
        return FSP_ERR_INVALID_ARGUMENT;
    }

    for (i = 0U; i < size; i++)
    {
        p_rx_data[i] = SoftSPI_TransmitReceiveByte(hspi, p_tx_data[i]);
    }

    return FSP_SUCCESS;
}

/*******************************************************************************************************************//**
 * @} (end addtogroup SOFT_SPI_RA6M5)
 **********************************************************************************************************************/
