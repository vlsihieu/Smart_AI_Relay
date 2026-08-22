;*******************************
;*  Interrupt Control Reg.  7  *
;*******************************
MDCR	  .EQU	   H'FFFFF1
SYSCR	  .EQU	   H'FFFFF2
ISCR	  .EQU	   H'FFFFF4
IER	      .EQU	   H'FFFFF5
ISR	      .EQU	   H'FFFFF6
IPRA	  .EQU	   H'FFFFF8
IPRB	  .EQU	   H'FFFFF9
;********************************
;*  Bus Control Reg.	   5	*
;********************************
ABWCR	  .EQU	   H'FFFFEC
ASTCR	  .EQU	   H'FFFFED
WCR	      .EQU	   H'FFFFEE
WCER	  .EQU	   H'FFFFEF
BRCR	  .EQU	   H'FFFFF3
;********************************
;*  Refresh Control Reg.    4	*
;********************************
RFSHCR	  .EQU	   H'FFFFAC
RTMCSR	  .EQU	   H'FFFFAD
CMF	      .BEQU    7,RTMCSR
CMIE	  .BEQU    6,RTMCSR
RTCNT	  .EQU	   H'FFFFAE
RTCOR	  .EQU	   H'FFFFAF
;********************************
;*    DMAC Registers	    64	*
;********************************
MAR0AR	  .EQU	   H'FFFF20
MAR0AE	  .EQU	   H'FFFF21
MAR0AH	  .EQU	   H'FFFF22
MAR0AL	  .EQU	   H'FFFF23
IOAR0A	  .EQU	   H'FFFF26
ETCR0AH   .EQU	   H'FFFF24
ETCR0AL   .EQU	   H'FFFF25
DTCR0A	  .EQU	   H'FFFF27
MAR0BR	  .EQU	   H'FFFF28
MAR0BE	  .EQU	   H'FFFF29
MAR0BH	  .EQU	   H'FFFF2A
MAR0BL	  .EQU	   H'FFFF2B
IOAR0B	  .EQU	   H'FFFF2E
ETCR0BH   .EQU	   H'FFFF2C
ETCR0BL   .EQU	   H'FFFF2D
DTCR0B	  .EQU	   H'FFFF2F
;
MAR1AR	  .EQU	   H'FFFF30
MAR1AE	  .EQU	   H'FFFF31
MAR1AH	  .EQU	   H'FFFF32
MAR1AL	  .EQU	   H'FFFF33
IOAR1A	  .EQU	   H'FFFF36
ETCR1AH   .EQU	   H'FFFF34
ETCR1AL   .EQU	   H'FFFF35
DTCR1A	  .EQU	   H'FFFF37
MAR1BR	  .EQU	   H'FFFF38
MAR1BE	  .EQU	   H'FFFF39
MAR1BH	  .EQU	   H'FFFF3A
MAR1BL	  .EQU	   H'FFFF3B
IOAR1B	  .EQU	   H'FFFF3E
ETCR1BH   .EQU	   H'FFFF3C
ETCR1BL   .EQU	   H'FFFF3D
DTCR1B	  .EQU	   H'FFFF3F
;
MAR2AR	  .EQU	   H'FFFF40
MAR2AE	  .EQU	   H'FFFF41
MAR2AH	  .EQU	   H'FFFF42
MAR2AL	  .EQU	   H'FFFF43
IOAR2A	  .EQU	   H'FFFF46
ETCR2AH   .EQU	   H'FFFF44
ETCR2AL   .EQU	   H'FFFF45
DTCR2A	  .EQU	   H'FFFF47
MAR2BR	  .EQU	   H'FFFF48
MAR2BE	  .EQU	   H'FFFF49
MAR2BH	  .EQU	   H'FFFF4A
MAR2BL	  .EQU	   H'FFFF4B
IOAR2B	  .EQU	   H'FFFF4E
ETCR2BH   .EQU	   H'FFFF4C
ETCR2BL   .EQU	   H'FFFF4D
DTCR2B	  .EQU	   H'FFFF4F
MAR3AR	  .EQU	   H'FFFF50
MAR3AE	  .EQU	   H'FFFF51
MAR3AH	  .EQU	   H'FFFF52
MAR3AL	  .EQU	   H'FFFF53
IOAR3A	  .EQU	   H'FFFF56
ETCR3AH   .EQU	   H'FFFF54
ETCR3AL   .EQU	   H'FFFF55
DTCR3A	  .EQU	   H'FFFF57
MAR3BR	  .EQU	   H'FFFF58
MAR3BE	  .EQU	   H'FFFF59
MAR3BH	  .EQU	   H'FFFF5A
MAR3BL	  .EQU	   H'FFFF5B
IOAR3B	  .EQU	   H'FFFF5E
ETCR3BH   .EQU	   H'FFFF5C
ETCR3BL   .EQU	   H'FFFF5D
DTCR3B	  .EQU	   H'FFFF5F
;********************************
;*  Port 4 Defind Address    3	*
;********************************
; P4DDR (W):
;	 =0 -> Input
;	 =1 -> Output
;
; PORT4(R/W):
;	 Store P4 State
;
; P4PCR(R/W):
;	 Input Pull Up
;	=0 Disable
;	=1 Enable
P4DDR	  .EQU	   H'FFFFC5
P4DR	  .EQU	   H'FFFFC7
P4PCR	  .EQU	   H'FFFFDA
;********************************
;*  Port 5 Defind Address    3	*
;********************************
;  P5.0 - P5.3 =A20 - A23
;
; P5DDR(W): P5.4 - P5.7
;	    =0 Input
;	    =1 Output
;
; PORT5(R/W):
;   P5.0 - P5.3 Reserve
;   P5.4 - P5.7 Store state
;
; P5PCR (R/W):
;   P5.0 - P5.3 Reserve
;   P5.4 - P5.7 Store State
;
P5DDR	  .EQU	   H'FFFFC8
P5DR	  .EQU	   H'FFFFCA
P5PCR	  .EQU	   H'FFFFDB
LED9	  .BEQU    4,P5DR	  ;
LED10	  .BEQU    5,P5DR	  ;
LED11	  .BEQU    6,P5DR	  ;
LED12	  .BEQU    7,P5DR	  ;
;*********************************
;*   Port 6 Defind Address    2  *
;*********************************
; P6.3 - P6.7 Reserve
P6DDR	  .EQU	   H'FFFFC9
P6DR	  .EQU	   H'FFFFCB
DA_LD1	  .BEQU    0,P6DR
AD_DOUT   .BEQU    1,P6DR
AD_CS	  .BEQU    2,P6DR
;*********************************
;*  Port 7 Defind Address     1  *
;*********************************
; Read Only, AN0 - AN7
P7DR	  .EQU	   H'FFFFCE
BATEN	  .BEQU    4,P7DR
POW_DOWN  .BEQU    5,P7DR
PGCL	  .BEQU    6,P7DR      ;PG_MODE=L 
IO_DINP   .BEQU    7,P7DR
;*********************************
;*  Port 8 Defind Address     2  *
;*********************************
; P8.5 - P8.7 Reserve
P8DDR	  .EQU	   H'FFFFCD
P8DR	  .EQU	   H'FFFFCF
RUN_OUT   .BEQU    0,P8DR
AD_DINP   .BEQU    2,P8DR
;*********************************
;*  Port 9 Defind Address     2  *
;*********************************
;P 9.6 - P9.7 Reserve
P9DDR	  .EQU	   H'FFFFD0
P9DR	  .EQU	   H'FFFFD2
EN_IO	  .BEQU    4,P9DR
STB_B	  .BEQU    5,P9DR
;*********************************
;*  Port A Defind Address     2  *
;*********************************
PADDR	  .EQU	   H'FFFFD1
PADR	  .EQU	   H'FFFFD3
TCLK_A	  .BEQU    0,PADR
TCLK_B	  .BEQU    1,PADR
TCLK_C	  .BEQU    2,PADR
TCLK_D	  .BEQU    3,PADR
RTC_DATA  .BEQU    4,PADR
RTC_SCLK  .BEQU    5,PADR
RTC_RST   .BEQU    6,PADR
IO_LED	  .BEQU    7,PADR
;*********************************
;*  Port B Defind Address     2  *
;*********************************
PBDDR	  .EQU	   H'FFFFD4
PBDR	  .EQU	   H'FFFFD6
LED1	  .BEQU    0,PBDR
LED2	  .BEQU    1,PBDR
LED3	  .BEQU    2,PBDR
LED4	  .BEQU    3,PBDR
LED5	  .BEQU    4,PBDR
LED6	  .BEQU    5,PBDR
LED7	  .BEQU    6,PBDR
LED8	  .BEQU    7,PBDR
;*********************************
;*  Port C Defind Address     2  *
;*********************************
PCDDR	  .EQU	   H'FFFFD5
PCDR	  .EQU	   H'FFFFD7  ;PC.0~PC.7 PORT C
IO_DOUT    .BEQU   0,PCDR
PS	       .BEQU   1,PCDR
WDT_EN	   .BEQU   3,PCDR
EN_422	   .BEQU   6,PCDR	 ;WR_EEPROM -> EN_ABLE PC.6( EN_422 )
IO_SCLK    .BEQU   7,PCDR          
DOUT       .BEQU   0,PCDR    ;1'P6DR=AD_DOUT
                             ;0'PCDR=IO_DOUT=CN1_DOUT
                             ;5,P9DR=STB_B
;*********************************
;*Integrated time-pulse unit	 *
;*    ITU  Defind Address	 *
;*********************************
TSTR	  .EQU	   H'FFFF60
TSNC	  .EQU	   H'FFFF61
TMDR	  .EQU	   H'FFFF62
TFCR	  .EQU	   H'FFFF63
TOER	  .EQU	   H'FFFF90
TOCR	  .EQU	   H'FFFF91
TCR0	  .EQU	   H'FFFF64
TIOR0	  .EQU	   H'FFFF65
TIER0	  .EQU	   H'FFFF66
TSR0	  .EQU	   H'FFFF67
TCNT0	  .EQU	   H'FFFF68
GRA0	  .EQU	   H'FFFF6A   ;6A Hi,6B Lo byte.
GRB0	  .EQU	   H'FFFF6C
TCR1	  .EQU	   H'FFFF6E
TIOR1	  .EQU	   H'FFFF6F
TIER1	  .EQU	   H'FFFF70
TSR1	  .EQU	   H'FFFF71
TCNT1	  .EQU	   H'FFFF72
GRA1	  .EQU	   H'FFFF74
GRB1	  .EQU	   H'FFFF76
;
TCR2	  .EQU	   H'FFFF78
TIOR2	  .EQU	   H'FFFF79
TIER2	  .EQU	   H'FFFF7A
TSR2	  .EQU	   H'FFFF7B
TCNT2	  .EQU	   H'FFFF7C
GRA2	  .EQU	   H'FFFF7E
GRB2	  .EQU	   H'FFFF80
;
TCR3	  .EQU	   H'FFFF82
TIOR3	  .EQU	   H'FFFF83
TIER3	  .EQU	   H'FFFF84
TSR3	  .EQU	   H'FFFF85
TCNT3	  .EQU	   H'FFFF86
GRA3	  .EQU	   H'FFFF88
GRB3	  .EQU	   H'FFFF8A
BRA3	  .EQU	   H'FFFF8C
BRB3	  .EQU	   H'FFFF8E
;
TCR4	  .EQU	   H'FFFF92
TIOR4	  .EQU	   H'FFFF93
TIER4	  .EQU	   H'FFFF94
TSR4	  .EQU	   H'FFFF95
TCNT4	  .EQU	   H'FFFF96
GRA4	  .EQU	   H'FFFF98
GRB4	  .EQU	   H'FFFF9A
BRA4	  .EQU	   H'FFFF9C
BRB4	  .EQU	   H'FFFF9E
;********************************
;*    TPC Registers		*
;********************************
TPMR	  .EQU	   H'FFFFA0
TPCR	  .EQU	   H'FFFFA1
NDERB	  .EQU	   H'FFFFA2
NDERA	  .EQU	   H'FFFFA3
NDRA	  .EQU	   H'FFFFA5
NDRB	  .EQU	   H'FFFFA4
;********************************
;*  WDT  Register		*
;********************************
TCSR	  .EQU	   H'FFFFA8
TCNT	  .EQU	   H'FFFFA9
RSTCSR	  .EQU	   H'FFFFAA
TME	      .BEQU    5,TCSR
WRST	  .BEQU    7,RSTCR
;********************************
;*  Serial Registers		*
;********************************
SMR0	  .EQU	   H'FFFFB0
BRR0	  .EQU	   H'FFFFB1
SCR0	  .EQU	   H'FFFFB2
TDR0	  .EQU	   H'FFFFB3
SSR0	  .EQU	   H'FFFFB4
RDR0	  .EQU	   H'FFFFB5
TIE	      .EQU	   7		  ;Transmit interrupt enable
RIE	      .EQU	   6		  ;Receive interrupt enable
TE	      .EQU	   5		  ;Transmit enable
RE	      .EQU	   4		  ;Receive enable
MPIE	  .EQU	   3		  ;Multi processor interrupt enable
TEIE	  .EQU	   2		  ;Transmit end interrutp enable
CKE1	  .EQU	   1		  ;
CKE0	  .EQU	   0		  ;
TEND	  .EQU	   2		  ;
TDRE	  .EQU	   7		  ;Transmit data register empty
RDRF	  .EQU	   6		  ;Receive data register full
MPBT	  .EQU	   0		  ;Multiprocessor bit transfer
MPB	      .EQU	   1		  ;Multiprocessor bit
;
SMR1	  .EQU	   H'FFFFB8
BRR1	  .EQU	   H'FFFFB9
SCR1	  .EQU	   H'FFFFBA
TDR1	  .EQU	   H'FFFFBB
SSR1	  .EQU	   H'FFFFBC
RDR1	  .EQU	   H'FFFFBD
;********************************
;*   A/D Convert Registers   10 *
;********************************
ADDRA	  .EQU	   H'FFFFE0
ADDRB	  .EQU	   H'FFFFE2
ADDRC	  .EQU	   H'FFFFE4
ADDRD	  .EQU	   H'FFFFE6
ADCSR	  .EQU	   H'FFFFE8
ADCR	  .EQU	   H'FFFFE9
;