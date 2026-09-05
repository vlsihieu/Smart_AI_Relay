/*******************************************************************************************************************//**
 * @file soft_spi_ra6m5.h
 * @brief Declares the GPIO-based software SPI driver for the Renesas RA6M5.
 *
 * This file provides the public data types and APIs required to implement an SPI master by bit-banging GPIO pins through
 * the Renesas FSP IOPORT interface. The driver is intended for low/medium-speed peripherals, such as a touchscreen
 * controller, when the hardware SPI peripheral cannot be used.
 *
 * @note The IOPORT control block referenced by soft_spi_handle_t::p_ioport_ctrl must already be initialized by FSP/BSP.
 **********************************************************************************************************************/

#ifndef SOFT_SPI_RA6M5_H_
#define SOFT_SPI_RA6M5_H_

/***********************************************************************************************************************
 * Includes
 **********************************************************************************************************************/
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include "hal_data.h"

#ifdef __cplusplus
extern "C" {
#endif

/*******************************************************************************************************************//**
 * @defgroup SOFT_SPI_RA6M5 Software SPI for RA6M5
 * @brief    GPIO-based SPI master driver for Renesas RA6M5.
 * @{
 **********************************************************************************************************************/

/***********************************************************************************************************************
 * Typedef definitions
 **********************************************************************************************************************/

/** @brief SPI clock polarity selection. */
typedef enum e_soft_spi_cpol
{
    SOFT_SPI_CPOL_LOW  = 0U,    /**< SCK is LOW while the bus is idle. */
    SOFT_SPI_CPOL_HIGH = 1U     /**< SCK is HIGH while the bus is idle. */
} soft_spi_cpol_t;

/** @brief SPI clock phase selection. */
typedef enum e_soft_spi_cpha
{
    SOFT_SPI_CPHA_1EDGE = 0U,   /**< Sample on the first clock edge, equivalent to CPHA = 0. */
    SOFT_SPI_CPHA_2EDGE = 1U    /**< Sample on the second clock edge, equivalent to CPHA = 1. */
} soft_spi_cpha_t;

/** @brief SPI bit transmission order. */
typedef enum e_soft_spi_first_bit
{
    SOFT_SPI_FIRSTBIT_MSB = 0U, /**< Transmit the most-significant bit first. */
    SOFT_SPI_FIRSTBIT_LSB = 1U  /**< Transmit the least-significant bit first. */
} soft_spi_first_bit_t;

/** @brief Runtime state of a software SPI handle. */
typedef enum e_soft_spi_state
{
    SOFT_SPI_STATE_RESET = 0U,  /**< Driver has not been initialized. */
    SOFT_SPI_STATE_READY,       /**< Driver is initialized and ready for a transfer. */
    SOFT_SPI_STATE_BUSY         /**< Driver is currently performing a transfer. */
} soft_spi_state_t;

/** @brief GPIO pin assignment for one software SPI instance. */
typedef struct st_soft_spi_pins
{
    bsp_io_port_pin_t sck;      /**< SPI serial clock output pin. */
    bsp_io_port_pin_t mosi;     /**< SPI master-out/slave-in output pin. */
    bsp_io_port_pin_t miso;     /**< SPI master-in/slave-out input pin. */
    bsp_io_port_pin_t cs;       /**< Active-low chip-select output pin. */
} soft_spi_pins_t;

/** @brief Software SPI configuration. */
typedef struct st_soft_spi_cfg
{
    soft_spi_pins_t      pins;             /**< GPIO pins used by the software SPI bus. */
    soft_spi_cpol_t      cpol;             /**< SPI clock polarity. */
    soft_spi_cpha_t      cpha;             /**< SPI clock phase. */
    soft_spi_first_bit_t first_bit;        /**< Bit transmission order. */
    uint32_t             half_period_us;   /**< Delay for one half SCK period, in microseconds. */
} soft_spi_cfg_t;

/** @brief Software SPI instance handle. */
typedef struct st_soft_spi_handle
{
    ioport_ctrl_t            * p_ioport_ctrl; /**< FSP IOPORT control block used for GPIO access. */
    soft_spi_cfg_t             cfg;           /**< Static software SPI configuration. */
    volatile soft_spi_state_t  state;         /**< Current runtime state of the driver. */
} soft_spi_handle_t;

/***********************************************************************************************************************
 * Function declarations
 **********************************************************************************************************************/

/*******************************************************************************************************************//**
 * @brief Initializes the software SPI GPIO pins and bus idle state.
 *
 * @details The function configures SCK, MOSI, and CS as outputs, configures MISO as an input, drives CS inactive HIGH,
 *          sets SCK to the CPOL-defined idle level, and drives MOSI LOW.
 *
 * @param[in,out] hspi Pointer to the software SPI handle.
 *
 * @retval FSP_SUCCESS              Initialization completed successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT The handle or its configuration is invalid.
 * @return Any error returned by R_IOPORT_PinCfg().
 **********************************************************************************************************************/
fsp_err_t SoftSPI_Init(soft_spi_handle_t * hspi);

/*******************************************************************************************************************//**
 * @brief Controls the active-low software SPI chip-select line.
 *
 * @param[in,out] hspi   Pointer to the software SPI handle.
 * @param[in]     enable true to assert CS LOW; false to deassert CS HIGH.
 *
 * @retval FSP_SUCCESS              Chip-select was updated successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT The handle or its configuration is invalid.
 * @return Any error returned by R_IOPORT_PinWrite().
 **********************************************************************************************************************/
fsp_err_t SoftSPI_ChipSelect(soft_spi_handle_t * hspi, bool enable);

/*******************************************************************************************************************//**
 * @brief Exchanges one byte over the software SPI bus.
 *
 * @details Eight software-generated SCK cycles are produced. One MOSI bit is transmitted and one MISO bit is sampled
 *          during each cycle according to the configured CPOL, CPHA, and bit-order settings.
 *
 * @param[in,out] hspi    Pointer to the software SPI handle.
 * @param[in]     tx_data Byte to transmit on MOSI.
 *
 * @return Byte sampled from MISO. A value of 0 is returned if the handle is invalid.
 *
 * @note This function does not control CS. The caller shall assert/deassert CS as required by the slave protocol.
 **********************************************************************************************************************/
uint8_t SoftSPI_TransmitReceiveByte(soft_spi_handle_t * hspi, uint8_t tx_data);

/*******************************************************************************************************************//**
 * @brief Transmits a byte buffer using software SPI.
 *
 * @param[in,out] hspi   Pointer to the software SPI handle.
 * @param[in]     p_data Pointer to the transmit buffer.
 * @param[in]     size   Number of bytes to transmit.
 *
 * @retval FSP_SUCCESS              Buffer transmitted successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT The handle, buffer pointer, or size is invalid.
 **********************************************************************************************************************/
fsp_err_t SoftSPI_Transmit(soft_spi_handle_t * hspi, uint8_t const * p_data, uint16_t size);

/*******************************************************************************************************************//**
 * @brief Receives a byte buffer using software SPI.
 *
 * @details Dummy value 0xFF is transmitted for every received byte so that the master generates the clock pulses
 *          required by the SPI slave.
 *
 * @param[in,out] hspi   Pointer to the software SPI handle.
 * @param[out]    p_data Destination buffer for received bytes.
 * @param[in]     size   Number of bytes to receive.
 *
 * @retval FSP_SUCCESS              Requested number of bytes received successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT The handle, buffer pointer, or size is invalid.
 **********************************************************************************************************************/
fsp_err_t SoftSPI_Receive(soft_spi_handle_t * hspi, uint8_t * p_data, uint16_t size);

/*******************************************************************************************************************//**
 * @brief Performs a full-duplex software SPI buffer transfer.
 *
 * @param[in,out] hspi      Pointer to the software SPI handle.
 * @param[in]     p_tx_data Pointer to the transmit buffer.
 * @param[out]    p_rx_data Destination buffer for received bytes.
 * @param[in]     size      Number of bytes to exchange.
 *
 * @retval FSP_SUCCESS              Full-duplex transfer completed successfully.
 * @retval FSP_ERR_INVALID_ARGUMENT The handle, buffer pointers, or size is invalid.
 **********************************************************************************************************************/
fsp_err_t SoftSPI_TransmitReceive(soft_spi_handle_t * hspi,
                                  uint8_t const * p_tx_data,
                                  uint8_t * p_rx_data,
                                  uint16_t size);

/*******************************************************************************************************************//**
 * @} (end defgroup SOFT_SPI_RA6M5)
 **********************************************************************************************************************/

#ifdef __cplusplus
}
#endif

#endif /* SOFT_SPI_RA6M5_H_ */
