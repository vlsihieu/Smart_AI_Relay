/* generated HAL header file - do not edit */
#ifndef HAL_DATA_H_
#define HAL_DATA_H_
#include <stdint.h>
#include "bsp_api.h"
#include "common_data.h"
#include "r_spi.h"
FSP_HEADER
/** SPI on SPI Instance. */
extern const spi_instance_t g_spi_master;

/** Access the SPI instance using these structures when calling API functions directly (::p_api is not used). */
extern spi_instance_ctrl_t g_spi_master_ctrl;
extern const spi_cfg_t g_spi_master_cfg;

/** Callback used by SPI Instance. */
#ifndef spi_master_callback
void spi_master_callback(spi_callback_args_t *p_args);
#endif

#define RA_NOT_DEFINED (1)
#if (RA_NOT_DEFINED == RA_NOT_DEFINED)
#define g_spi_master_P_TRANSFER_TX (NULL)
#else
    #define g_spi_master_P_TRANSFER_TX (&RA_NOT_DEFINED)
#endif
#if (RA_NOT_DEFINED == RA_NOT_DEFINED)
#define g_spi_master_P_TRANSFER_RX (NULL)
#else
    #define g_spi_master_P_TRANSFER_RX (&RA_NOT_DEFINED)
#endif
#undef RA_NOT_DEFINED
void hal_entry(void);
void g_hal_init(void);
FSP_FOOTER
#endif /* HAL_DATA_H_ */
