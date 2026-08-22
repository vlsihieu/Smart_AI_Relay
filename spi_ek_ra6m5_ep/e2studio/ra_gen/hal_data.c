/* generated HAL source file - do not edit */
#include "hal_data.h"
#define RA_NOT_DEFINED (UINT32_MAX)
#if (RA_NOT_DEFINED) != (RA_NOT_DEFINED)

/* If the transfer module is DMAC, define a DMAC transfer callback. */
#include "r_dmac.h"
extern void spi_tx_dmac_callback(spi_instance_ctrl_t const * const p_ctrl);

void g_spi_master_tx_transfer_callback (dmac_callback_args_t * p_args)
{
    FSP_PARAMETER_NOT_USED(p_args);
    spi_tx_dmac_callback(&g_spi_master_ctrl);
}
#endif

#if (RA_NOT_DEFINED) != (RA_NOT_DEFINED)

/* If the transfer module is DMAC, define a DMAC transfer callback. */
#include "r_dmac.h"
extern void spi_rx_dmac_callback(spi_instance_ctrl_t const * const p_ctrl);

void g_spi_master_rx_transfer_callback (dmac_callback_args_t * p_args)
{
    FSP_PARAMETER_NOT_USED(p_args);
    spi_rx_dmac_callback(&g_spi_master_ctrl);
}
#endif
#undef RA_NOT_DEFINED

spi_instance_ctrl_t g_spi_master_ctrl;

/** SPI extended configuration for SPI HAL driver */
const spi_extended_cfg_t g_spi_master_ext_cfg =
{ .spi_clksyn = SPI_SSL_MODE_CLK_SYN,
  .spi_comm = SPI_COMMUNICATION_FULL_DUPLEX,
  .ssl_polarity = SPI_SSLP_LOW,
  .ssl_select = SPI_SSL_SELECT_SSL0,
  .mosi_idle = SPI_MOSI_IDLE_VALUE_FIXING_DISABLE,
  .parity = SPI_PARITY_MODE_DISABLE,
  .byte_swap = SPI_BYTE_SWAP_DISABLE,
  .spck_div =
  {
  /* Actual calculated bitrate: 5000000. */.spbr = 0,
    .brdv = 0 },
  .spck_delay = SPI_DELAY_COUNT_1,
  .ssl_negation_delay = SPI_DELAY_COUNT_1,
  .next_access_delay = SPI_DELAY_COUNT_1,
  .burst_interframe_delay = SPI_BURST_TRANSFER_WITH_DELAY };

/** SPI configuration for SPI HAL driver */
const spi_cfg_t g_spi_master_cfg =
{ .channel = 0,

#if defined(VECTOR_NUMBER_SPI0_RXI)
    .rxi_irq             = VECTOR_NUMBER_SPI0_RXI,
#else
  .rxi_irq = FSP_INVALID_VECTOR,
#endif
#if defined(VECTOR_NUMBER_SPI0_TXI)
    .txi_irq             = VECTOR_NUMBER_SPI0_TXI,
#else
  .txi_irq = FSP_INVALID_VECTOR,
#endif
#if defined(VECTOR_NUMBER_SPI0_TEI)
    .tei_irq             = VECTOR_NUMBER_SPI0_TEI,
#else
  .tei_irq = FSP_INVALID_VECTOR,
#endif
#if defined(VECTOR_NUMBER_SPI0_ERI)
    .eri_irq             = VECTOR_NUMBER_SPI0_ERI,
#else
  .eri_irq = FSP_INVALID_VECTOR,
#endif

  .rxi_ipl = (2),
  .txi_ipl = (2), .tei_ipl = (2), .eri_ipl = (2),

  .operating_mode = SPI_MODE_MASTER,

  .clk_phase = SPI_CLK_PHASE_EDGE_EVEN,
  .clk_polarity = SPI_CLK_POLARITY_LOW,

  .mode_fault = SPI_MODE_FAULT_ERROR_DISABLE,
  .bit_order = SPI_BIT_ORDER_MSB_FIRST, .p_transfer_tx = g_spi_master_P_TRANSFER_TX, .p_transfer_rx =
          g_spi_master_P_TRANSFER_RX,
  .p_callback = spi_master_callback,

  .p_context = NULL,
  .p_extend = (void*) &g_spi_master_ext_cfg, };

/* Instance structure to use this module. */
const spi_instance_t g_spi_master =
{ .p_ctrl = &g_spi_master_ctrl, .p_cfg = &g_spi_master_cfg, .p_api = &g_spi_on_spi };
void g_hal_init(void)
{
    g_common_init ();
}
