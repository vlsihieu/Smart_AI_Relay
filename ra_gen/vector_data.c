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
            [4] = sci_uart_rxi_isr, /* SCI6 RXI (Receive data full) */
            [5] = sci_uart_txi_isr, /* SCI6 TXI (Transmit data empty) */
            [6] = sci_uart_tei_isr, /* SCI6 TEI (Transmit end) */
            [7] = sci_uart_eri_isr, /* SCI6 ERI (Receive error) */
        };
        #if BSP_FEATURE_ICU_HAS_IELSR
        const bsp_interrupt_event_t g_interrupt_event_link_select[BSP_ICU_VECTOR_NUM_ENTRIES] =
        {
            [0] = BSP_PRV_VECT_ENUM(EVENT_SPI0_RXI,GROUP0), /* SPI0 RXI (Receive buffer full) */
            [1] = BSP_PRV_VECT_ENUM(EVENT_SPI0_TXI,GROUP1), /* SPI0 TXI (Transmit buffer empty) */
            [2] = BSP_PRV_VECT_ENUM(EVENT_SPI0_TEI,GROUP2), /* SPI0 TEI (Transmission complete event) */
            [3] = BSP_PRV_VECT_ENUM(EVENT_SPI0_ERI,GROUP3), /* SPI0 ERI (Error) */
            [4] = BSP_PRV_VECT_ENUM(EVENT_SCI6_RXI,GROUP4), /* SCI6 RXI (Receive data full) */
            [5] = BSP_PRV_VECT_ENUM(EVENT_SCI6_TXI,GROUP5), /* SCI6 TXI (Transmit data empty) */
            [6] = BSP_PRV_VECT_ENUM(EVENT_SCI6_TEI,GROUP6), /* SCI6 TEI (Transmit end) */
            [7] = BSP_PRV_VECT_ENUM(EVENT_SCI6_ERI,GROUP7), /* SCI6 ERI (Receive error) */
        };
        #endif
        #endif
