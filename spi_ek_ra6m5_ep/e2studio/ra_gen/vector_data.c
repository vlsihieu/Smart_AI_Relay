/* generated vector source file - do not edit */
#include "bsp_api.h"
/* Do not build these data structures if no interrupts are currently allocated because IAR will have build errors. */
#if VECTOR_DATA_IRQ_COUNT > 0
        BSP_DONT_REMOVE const fsp_vector_t g_vector_table[BSP_ICU_VECTOR_NUM_ENTRIES] BSP_PLACE_IN_SECTION(BSP_SECTION_APPLICATION_VECTORS) =
        {
                        [0] = spi_rxi_isr, /* SPI0 RXI (Receive buffer full) */
            [1] = spi_txi_isr, /* SPI0 TXI (Transmit buffer empty) */
            [2] = spi_tei_isr, /* SPI0 TEI (Transmission complete event) */
            [3] = spi_eri_isr, /* SPI0 ERI (Error) */
        };
        #if BSP_FEATURE_ICU_HAS_IELSR
        const bsp_interrupt_event_t g_interrupt_event_link_select[BSP_ICU_VECTOR_NUM_ENTRIES] =
        {
            [0] = BSP_PRV_VECT_ENUM(EVENT_SPI0_RXI,GROUP0), /* SPI0 RXI (Receive buffer full) */
            [1] = BSP_PRV_VECT_ENUM(EVENT_SPI0_TXI,GROUP1), /* SPI0 TXI (Transmit buffer empty) */
            [2] = BSP_PRV_VECT_ENUM(EVENT_SPI0_TEI,GROUP2), /* SPI0 TEI (Transmission complete event) */
            [3] = BSP_PRV_VECT_ENUM(EVENT_SPI0_ERI,GROUP3), /* SPI0 ERI (Error) */
        };
        #endif
        #endif
