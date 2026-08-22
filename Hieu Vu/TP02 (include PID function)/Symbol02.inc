;***********************************************************************************
;*  Register Defind.      WDT_Retrigger time : 41.1 mS       2/9    2002/2/7 stone *
;***********************************************************************************
ACC_L          .REG       (R0L)
ACC_H          .REG       (R0H)
ACC_W          .REG       (R0)
ACC_E          .REG       (E0)
ACC_X          .REG       (ER0)
B_L            .REG       (R1L)
B_H            .REG       (R1H)
B_W            .REG       (R1)
B_X            .REG       (ER1)
REG_R0         .REG       (R2L)
REG_R1         .REG       (R2H)
REG_R2         .REG       (R3L)
REG_R3         .REG       (R3H)
REG_R4         .REG       (R4L)
REG_R5         .REG       (R4H)
REG_R6         .REG       (R5L)
ASCII_INST     .REG       (R4)
ASCII_INST_H   .REG       (R4H)
ASCII_INST_L   .REG       (R4L)
BUFF_PTR2      .REG       (ER4)
BUFF_PTR1      .REG       (ER5)
DPTR           .REG       (ER6)
DPTR_W         .REG       (E6)
DPTR_H         .REG       (R6H)
DPTR_L         .REG       (R6L)
DPTR_LW        .REG       (R6)
DATA1_W        .REG       (E0)
DATA2_W        .REG       (E1)
DATA3_W        .REG       (E2)
DATA4_W        .REG       (E3)
DATA5_W        .REG       (E4)

;******************************************************************************
;*  Bit Defind.     0FFF00-0FFF1B                                             *
;******************************************************************************
FLAG1          .EQU     H'00FFFF00
X005_LAST_STATUS .BEQU  0,FLAG1
X006_LAST_STATUS .BEQU  1,FLAG1
ERR_BIT        .BEQU    2,FLAG1       ;Bit1 -> E_FLAG SAME MEAN.
FN_BIT         .BEQU    3,FLAG1       ;Bit3 -> Logic Jugement Bit.(FN_BI
S_BIT          .BEQU    4,FLAG1       ;COMM F12,F14
F53_BIT_IN     .BEQU    5,FLAG1
F54_FILTER     .BEQU    6,FLAG1
F54_FILTER_ON  .BEQU    7,FLAG1
                                           
LABEL_INT_BUSY .EQU     H'00FFFF01
INC1_INT_BUSY  .BEQU    0,LABEL_INT_BUSY
INC2_INT_BUSY  .BEQU    1,LABEL_INT_BUSY
ENC1_INT_BUSY  .BEQU    2,LABEL_INT_BUSY
COMPILER_BIT   .BEQU    3,LABEL_INT_BUSY
TIMER_BUSY_BIT .BEQU    4,LABEL_INT_BUSY
F56_DATA_OK    .BEQU    5,LABEL_INT_BUSY
JCS_BIT        .BEQU    6,LABEL_INT_BUSY
F58_RXD_F0     .BEQU    7,LABEL_INT_BUSY

;HIGH_SPEED_S   .EQU     H'00FFFF02
;PRES_7323      .BEQU    0,HIGH_SPEED_S
;PRES_7327      .BEQU    1,HIGH_SPEED_S
;PRES_7333      .BEQU    2,HIGH_SPEED_S

OP05_06         .EQU     H'00FFFF02
OP05_MODE       .BEQU    0,OP05_06
F33_TOGGLE      .BEQU    1,OP05_06        ;;V1.0
X_FILTER        .BEQU    2,OP05_06        ;;V1.1
X1_LAST         .BEQU    3,OP05_06        ;;V1.1
X2_LAST         .BEQU    4,OP05_06        ;;V1.1
X3_LAST         .BEQU    5,OP05_06        ;;V1.1
X4_LAST         .BEQU    6,OP05_06        ;;V1.1
X_BIT_BUF       .BEQU    7,OP05_06        ;;V1.1

HSC_FLAG1      .EQU     H'00FFFF03
IMIB2_LB       .BEQU    0,HSC_FLAG1
IMIB3_LB       .BEQU    1,HSC_FLAG1
IMIB3_LB112    .BEQU    2,HSC_FLAG1
IMIB4_LB       .BEQU    3,HSC_FLAG1
IMIB4_LB113    .BEQU    4,HSC_FLAG1
HSC_RESET      .BEQU    5,HSC_FLAG1
HSC_MODE       .BEQU    6,HSC_FLAG1
F0_BIT         .BEQU    7,HSC_FLAG1
                                   
HSC_FLAG2      .EQU     H'00FFFF04
INT11_BUSY     .BEQU    0,HSC_FLAG2
INT22_BUSY     .BEQU    1,HSC_FLAG2
INT33_BUSY     .BEQU    2,HSC_FLAG2
INT44_BUSY     .BEQU    3,HSC_FLAG2
INT55_BUSY     .BEQU    4,HSC_FLAG2
PRE_SC002      .BEQU    5,HSC_FLAG2
PRE_SC004      .BEQU    6,HSC_FLAG2
PRE_SC006      .BEQU    7,HSC_FLAG2

LABEL_CNTRL    .EQU     H'00FFFF05
LB128_TM_INT   .BEQU    7,LABEL_CNTRL    ;
MAIN_INT_BIT   .BEQU    6,LABEL_CNTRL    ;
ENC_TM_INT     .BEQU    5,LABEL_CNTRL    ;
INC1_INT       .BEQU    4,LABEL_CNTRL    ;
MAIN_INT_BIT0  .BEQU    3,LABEL_CNTRL    ;bit buffer
ENC_TM_INT0    .BEQU    2,LABEL_CNTRL    ;   ;
INC1_INT0      .BEQU    1,LABEL_CNTRL    ;   ;
IO_INT_BIT     .BEQU    0,LABEL_CNTRL    ;Ver0.2,to prevent F80,FF81 dead lock

;
TP02_USED6     .EQU     H'00FFFF06
PRE_SC008      .BEQU    0,TP02_USED6
TD_MOD         .BEQU    1,TP02_USED6
FILE_TYPE      .BEQU    2,TP02_USED6
F50_BIT5       .BEQU    3,TP02_USED6
X_NO_REFRESH   .BEQU    4,TP02_USED6     ;;V0.C
X_NO_REFRESH1  .BEQU    5,TP02_USED6     ;;V0.C
AD_FILTER1     .BEQU    6,TP02_USED6     ;;V0.D
AD_FILTER2     .BEQU    7,TP02_USED6     ;;V0.D
;
TP02_USED7     .EQU     H'00FFFF07
F50_BIT1       .BEQU    0,TP02_USED7
F50_BIT2       .BEQU    1,TP02_USED7
F50_BIT3       .BEQU    2,TP02_USED7
F50_BIT4       .BEQU    3,TP02_USED7
F58_RXD_EN     .BEQU    4,TP02_USED7
F59_TXD_EN     .BEQU    5,TP02_USED7
F58_RXD_BYTE   .BEQU    6,TP02_USED7
AD_3_ORDER     .BEQU    7,TP02_USED7     ;;V0.D
;
DOUBLE_FUNC    .EQU     H'00FFFF08       ;V0.C NEW ADDED, for double function
F52_USED       .BEQU    0,DOUBLE_FUNC    ;                check used
F53_USED       .BEQU    1,DOUBLE_FUNC    ;
F55_USED       .BEQU    2,DOUBLE_FUNC    ;
F58_USED       .BEQU    3,DOUBLE_FUNC    ;
F59_USED       .BEQU    4,DOUBLE_FUNC    ;
BROADCAST_BIT  .BEQU    5,DOUBLE_FUNC    ;;VF.3
F53_SCAN_BOUNCE .BEQU   6,DOUBLE_FUNC    ;;VF.3
PGBRT_STATUS1  .BEQU    7,DOUBLE_FUNC    ;;VF.5 FOR F58_RXD USED
;
SPARE_FUNC     .EQU     H'00FFFF09       ;;V1.5 SPARE FUNCTION
PRE_SC019      .BEQU    0,SPARE_FUNC     ;;FOR 30 SECONDS COMPENSATION
HSC1_SET       .BEQU    1,SPARE_FUNC     ;;F11 V1001 MOV TO NEW DATA V1.6
HSC2_SET       .BEQU    2,SPARE_FUNC     ;;F11 V1003 MOV TO NEW DATA
HSC3_SET       .BEQU    3,SPARE_FUNC     ;;F11 V1005 MOV TO NEW DATA
HSC4_SET       .BEQU    4,SPARE_FUNC     ;;F11 V1007 MOV TO NEW DATA
AD_2_D_ST0     .BEQU    5,SPARE_FUNC     ;;v1.61
BIT_4TM_OFFSET .BEQU    6,SPARE_FUNC     ;;V1.7   4TM+ SC022(offset on) ON-->BSET 1 ;SC023(offset off) ON-->BCLR

;
SERI_STATUS    .EQU     H'00FFFF0A       ;Flag area
RXENDF0        .BEQU    7,SERI_STATUS    ;PG Recive end flag
TXENDF0        .BEQU    6,SERI_STATUS    ;PG Transmit end flag
RXENDF1        .BEQU    5,SERI_STATUS    ;RXENDF2 identify by EN_422_LINK
TXENDF1        .BEQU    4,SERI_STATUS    ;TXENDF2 identify by EN_422_LINK
RXENDF2        .BEQU    3,SERI_STATUS    ;
TXENDF2        .BEQU    2,SERI_STATUS    ;
REQ_START_FG0  .BEQU    1,SERI_STATUS    ;
REQ_START_FG1  .BEQU    0,SERI_STATUS    ;

FAULT_STATUS   .EQU     H'00FFFF0B
FAULT_FLAG     .BEQU    7,FAULT_STATUS
E_CHKSUM_ERR   .BEQU    6,FAULT_STATUS
EE_CHKSUM_ERR  .BEQU    5,FAULT_STATUS
PTY_CHK_ERR    .BEQU    4,FAULT_STATUS
SYS_SET_ERR    .BEQU    3,FAULT_STATUS
DATA_RAM_ERR   .BEQU    2,FAULT_STATUS
IO_BUS_ERR     .BEQU    1,FAULT_STATUS
LOGIC_ERR      .BEQU    0,FAULT_STATUS

SYS_CNTRL_FG   .EQU     H'00FFFF0C
POW_DOWN_ERR   .BEQU    7,SYS_CNTRL_FG
EEROM_VERIFY_FG .BEQU   6,SYS_CNTRL_FG
FIRST_PASS_FG  .BEQU    5,SYS_CNTRL_FG
PULSE_EN       .BEQU    4,SYS_CNTRL_FG
DLINK_ERR      .BEQU    3,SYS_CNTRL_FG
BATT_ERR       .BEQU    2,SYS_CNTRL_FG
INST_ERROR     .BEQU    1,SYS_CNTRL_FG
LOGIC_ERR_BIT  .BEQU    0,SYS_CNTRL_FG


PG_CNTRL_FG    .EQU     H'00FFFF0D
EEPROM_BIT     .BEQU    7,PG_CNTRL_FG       ;;V1.1
PG_COM_BIT     .BEQU    6,PG_CNTRL_FG
INST_NU_ONLY   .BEQU    5,PG_CNTRL_FG
SPACE_NG       .BEQU    4,PG_CNTRL_FG
PG_ERR_CODE    .BEQU    3,PG_CNTRL_FG
NU_ERR         .BEQU    2,PG_CNTRL_FG
PADR_ERR       .BEQU    1,PG_CNTRL_FG
ESC_EXIST      .BEQU    0,PG_CNTRL_FG

RTC_PG_CTRL_FG .EQU     H'00FFFF0E
EN_422_LINK    .BEQU    7,RTC_PG_CTRL_FG       ;Judge for data or computer link
DLINK_FG       .BEQU    6,RTC_PG_CTRL_FG       ;Data link used only
NS_NOP_EXIST   .BEQU    5,RTC_PG_CTRL_FG
INST_SERCH_DIR .BEQU    4,RTC_PG_CTRL_FG
NO_NU_CODE     .BEQU    3,RTC_PG_CTRL_FG
F18_FUN_ONLY   .BEQU    2,RTC_PG_CTRL_FG       ; Judge F10 or F18 function
DADR_BIT       .BEQU    1,RTC_PG_CTRL_FG       ; For PADR or DADR judge
SADR_BIT       .BEQU    0,RTC_PG_CTRL_FG       ; =1 System address, =0 Data add

REMOTE_LINK_M  .EQU     H'00FFFF0F
ALL_NODE_FG    .BEQU    7,REMOTE_LINK_M        ;Remote link used only
LOGIC_DETECT   .BEQU    6,REMOTE_LINK_M
RTC_STOP_BIT   .BEQU    5,REMOTE_LINK_M
SECOND_59SET   .BEQU    4,REMOTE_LINK_M
REMOTE_MODE    .BEQU    3,REMOTE_LINK_M        ;Data link & remote used only
MASTER_MODE    .BEQU    2,REMOTE_LINK_M        ;Data link & remote used only
DLINK_CSM_NG   .BEQU    1,REMOTE_LINK_M        ;Remote link checksum NG
RXENDF3        .BEQU    0,REMOTE_LINK_M        ;Remote link used only

LED_DRIVER     .EQU     H'00FFFF10
RUN_LED        .BEQU    0,LED_DRIVER
ERROR_LED      .BEQU    1,LED_DRIVER
WR_EEPROM      .BEQU    2,LED_DRIVER
RECEVIEC_OK    .BEQU    3,LED_DRIVER
                         

ENCODE_MODE_U  .EQU     H'00FFFF11
ENC_MODE       .BEQU    0,ENCODE_MODE_U
ENBL_HSCNT     .BEQU    1,ENCODE_MODE_U
CB0            .BEQU    2,ENCODE_MODE_U
CB1            .BEQU    3,ENCODE_MODE_U
PB0            .BEQU    4,ENCODE_MODE_U
PB1            .BEQU    5,ENCODE_MODE_U
TB0            .BEQU    6,ENCODE_MODE_U
TB1            .BEQU    7,ENCODE_MODE_U     

PG_COM_BYTE    .EQU     H'00FFFF12
RXENDFPG       .BEQU    0,PG_COM_BYTE
SECRET_BIT     .BEQU    1,PG_COM_BYTE
BIT_BUF        .BEQU    2,PG_COM_BYTE
PRE_7321_S     .BEQU    3,PG_COM_BYTE
PRE_7325_S     .BEQU    4,PG_COM_BYTE
PRE_7331_S     .BEQU    5,PG_COM_BYTE
D0_F5E_F31     .BEQU    6,PG_COM_BYTE
EEPROM_EXEC    .BEQU    7,PG_COM_BYTE

ALL_MIX        .EQU     H'00FFFF13
REQ_RUN_FG     .BEQU    0,ALL_MIX        ;
MTC_USED_BIT   .BEQU    1,ALL_MIX        ; FOR COMPUTER LINK ONLY
IO_DOUBLE_CHK  .BEQU    2,ALL_MIX        ; FOR I/O NUMBER CALCULATE
COM_LNK_ERR    .BEQU    3,ALL_MIX        ;Computer link only
TMR_CNT_MODE   .BEQU    4,ALL_MIX        ; =1 TIMER, =0 COUNTER
TX_OUT_ON      .BEQU    5,ALL_MIX        ;V0.E
RX_IN_ON       .BEQU    6,ALL_MIX        ;V0.E
EXCHANGE_ON    .BEQU    7,ALL_MIX        ;V0.E

DATA_W_FLAG    .EQU     H'00FFFF14         ;V0.E
RX_MAIN_TX     .BEQU    0,DATA_W_FLAG    ;
DATA_WORK_FG1  .BEQU    1,DATA_W_FLAG    ;
DATA_WORK_FG2  .BEQU    2,DATA_W_FLAG    ;
DATA_WORK_FG3  .BEQU    3,DATA_W_FLAG    ;
DATA_WORK_FG4  .BEQU    4,DATA_W_FLAG    ;
DATA_WORK_FG5  .BEQU    5,DATA_W_FLAG    ;
DATA_WORK_FG6  .BEQU    6,DATA_W_FLAG    ;
DATA_WORK_FG7  .BEQU    7,DATA_W_FLAG    ;

PRO_AD_DA       .EQU     H'00FFFF15        ;V0.E
SLAVE_OK_IN     .BEQU    0,PRO_AD_DA     ;for data link used
C_BIT_STACK     .BEQU    1,PRO_AD_DA     ;
EEPROM_F14_USED .BEQU    2,PRO_AD_DA     ;
SLAVE_XHG_S8    .BEQU    3,PRO_AD_DA     ;for data link slave exchange again
F34_OR_F54      .BEQU    4,PRO_AD_DA     ;V0.E3
SYS226_OR_236   .BEQU    5,PRO_AD_DA     ;=1 226
SECOND_BUFF_R   .BEQU    6,PRO_AD_DA     ;;
RTC_ONE_BURST   .BEQU    7,PRO_AD_DA     ;;FOR RTC
; After H'FFFF16, Power on retention ;;;
RUN_STOP_FG    .EQU     H'00FFFF16
RUN_FLAG       .BEQU    7,RUN_STOP_FG
RUN_FLAG_1     .BEQU    6,RUN_STOP_FG
USER_WDT_ERR   .BEQU    5,RUN_STOP_FG
STOP_IOLINK    .BEQU    4,RUN_STOP_FG          ;Remote link used only
F82_PRESET_DIS .BEQU    3,RUN_STOP_FG          ;High speed counter used only
WDT_ERR        .BEQU    2,RUN_STOP_FG
CLOCK_7360     .BEQU    1,RUN_STOP_FG
USER_WDT_ERR1  .BEQU    0,RUN_STOP_FG
;                       
;AD_DA_FUNC     .EQU     H'000FF0CF       ;FALSE1
AD_DA_FUNC     .EQU     H'00FFFF1B       ;FALSE2+chgadr

;AD_DA_FUNC     .EQU     H'00FFFF17      ;TRUR

SYS_210_2047   .BEQU    0,AD_DA_FUNC  
SYS_212_2047   .BEQU    1,AD_DA_FUNC
SYS_260_ON     .BEQU    2,AD_DA_FUNC
SYS_210_ON     .BEQU    3,AD_DA_FUNC

SYS_212_ON     .BEQU    4,AD_DA_FUNC
AD_FILTER_ST   .BEQU    5,AD_DA_FUNC
AD_FILTER      .BEQU    6,AD_DA_FUNC
PGBRT_STATUS   .BEQU    7,AD_DA_FUNC

TP02_USED1     .EQU     H'00FFFF18
JUDGE_NG       .BEQU    0,TP02_USED1
TMR_TYPEB      .BEQU    0,TP02_USED1
PRG_4K_MODE    .BEQU    1,TP02_USED1
BYTE_CNT_OK    .BEQU    2,TP02_USED1
READ_TABLE_BIT .BEQU    3,TP02_USED1
WR_TABLE_BIT   .BEQU    4,TP02_USED1
OVER_PASSWORD  .BEQU    5,TP02_USED1
PASSWORD_EXIST .BEQU    6,TP02_USED1
NU_EXIST       .BEQU    7,TP02_USED1

TP02_USED2     .EQU     H'00FFFF19
WORD_TYPE      .BEQU    0,TP02_USED2
TMR_CNT_OUT    .BEQU    1,TP02_USED2
OPERAND_TYPE   .BEQU    2,TP02_USED2
BITN0          .BEQU    3,TP02_USED2
BITN1          .BEQU    4,TP02_USED2
ERR_RESP       .BEQU    5,TP02_USED2
SCLK           .BEQU    6,TP02_USED2
FOR_NEXT       .BEQU    7,TP02_USED2

TP02_USED3     .EQU     H'00FFFF1A
C_BIT_BUFFER   .BEQU    0,TP02_USED3
C_CALL_BUFFER  .BEQU    1,TP02_USED3
NO_NEED_REFRESH .BEQU   2,TP02_USED3   ;;VF.0
STOP_REFRESH   .BEQU    3,TP02_USED3   ;;VF.0
COM_NOISE_BIT  .BEQU    4,TP02_USED3   ;;VF.4
AD_2_D_ST      .BEQU    5,TP02_USED3   ;;V0.D
CHG_MODE       .BEQU    6,TP02_USED3   ;;VF.0
COM_SECRET     .BEQU    7,TP02_USED3   ;;VF.2

LED_DRIVER2    .EQU     H'00FFFF1B     ;;TP02-28MR

MCS             .EQU      H'7
JCS             .EQU      H'6
TMR_OFFSET_KEEP .EQU      H'4
TMR_LOAD_OK     .EQU      H'5
FUN_SKIP        .EQU      H'4
ONLS            .EQU      H'7                  ;R1H
STMR            .EQU      H'7

;********* ASCII DEFINE ************
ASCII_STX      .EQU       H'02
ASCII_ETX      .EQU       H'03
ASCII_ACK      .EQU       H'06
ASCII_NAK      .EQU       H'15
ASCII_ESC      .EQU       H'1B
ASCII_3AH      .EQU       H'3A    ; :
ASCII_CO       .EQU       H'3A
ASCII_23H      .EQU       H'23    ; #
ASCII_NM       .EQU       H'23
ASCII_3FH      .EQU       H'3F    ; ?
ASCII_25H      .EQU       H'25    ; %
ASCII_0        .EQU       H'30
ASCII_1        .EQU       H'31
ASCII_2        .EQU       H'32
ASCII_3        .EQU       H'33
ASCII_4        .EQU       H'34
ASCII_5        .EQU       H'35
ASCII_6        .EQU       H'36
ASCII_7        .EQU       H'37
ASCII_8        .EQU       H'38
ASCII_9        .EQU       H'39
ASCII_A        .EQU       H'41
ASCII_B        .EQU       H'42
ASCII_C        .EQU       H'43
ASCII_D        .EQU       H'44
ASCII_E        .EQU       H'45
ASCII_F        .EQU       H'46
ASCII_G        .EQU       H'47
ASCII_H        .EQU       H'48
ASCII_I        .EQU       H'49
ASCII_J        .EQU       H'4A
ASCII_K        .EQU       H'4B
ASCII_L        .EQU       H'4C
ASCII_M        .EQU       H'4D
ASCII_N        .EQU       H'4E
ASCII_O        .EQU       H'4F
ASCII_P        .EQU       H'50
ASCII_Q        .EQU       H'51
ASCII_R        .EQU       H'52
ASCII_S        .EQU       H'53
ASCII_T        .EQU       H'54
ASCII_U        .EQU       H'55
ASCII_V        .EQU       H'56
ASCII_W        .EQU       H'57
ASCII_X        .EQU       H'58
ASCII_Y        .EQU       H'59
ASCII_Z        .EQU       H'5A
ASCII_CR       .EQU       H'0D
;********   Computer link symbol   ***********
CMD_MRL        .EQU       H'4D524C00
CMD_MRG        .EQU       H'4D524700
CMD_MTC        .EQU       H'4D544300
CMD_MTM        .EQU       H'4D544D00
CMD_MDY        .EQU       H'4D445900
CMD_MPC        .EQU       H'4D504300
CMD_SRR        .EQU       H'53525200
CMD_SRT        .EQU       H'53525400
CMD_SDY        .EQU       H'53445900
CMD_SVL        .EQU       H'53564C00
CMD_SWE        .EQU       H'53574500
CMD_STM        .EQU       H'53544D00
CMD_RSM        .EQU       H'52534D00
;CMD_RUN        .EQU       H'52554E00
CMD_RPM        .EQU       H'52504D00
CMD_RPS        .EQU       H'52505300
CMD_RPO        .EQU       H'52504F00
CMD_WSM        .EQU       H'57534D00
CMD_WPO        .EQU       H'57504F00
CMD_WPM        .EQU       H'57504D00
CMD_WPS        .EQU       H'57505300
CMD_WRT        .EQU       H'57525400
CMD_WRG        .EQU       H'57524700
CMD_CTC        .EQU       H'43544300
CMD_EWR        .EQU       H'45575200
CMD_HLT        .EQU       H'484C5400
CMD_VLM        .EQU       H'564C4D00
CMD_FRG        .EQU       H'46524700
CMD_ACL        .EQU       H'41434C00
CMD_SES        .EQU       H'53455300
;CMD_PAS        .EQU       H'50415300
CMD_SEI        .EQU       H'53454900
CMD_TST        .EQU       H'54535400
;; TP02
CMD_MCR        .EQU       H'4D435200
CMD_MRV        .EQU       H'4D525600
CMD_RBP        .EQU       H'52425000
CMD_SCS        .EQU       H'53435300
CMD_WRV        .EQU       H'57525600
CMD_WBP        .EQU       H'57425000
CMD_PSR        .EQU       H'50535200
CMD_STP        .EQU       H'53545000
CMD_RUN        .EQU       H'52554E00
CMD_RTC        .EQU       H'52544300
CMD_PAS        .EQU       H'50415300
CMD_ROM        .EQU       H'524F4D00
CMD_CLR        .EQU       H'434C5200
;;;;;;;;;
NOT_W          .EQU       H'FFFF
YES_W          .EQU       H'0000
; **** Data link & Remote I/O link ****
DCMD_SNR       .EQU       H'11
DCMD_STS       .EQU       H'84
DCMD_STM       .EQU       H'26
DCMD_RSR       .EQU       H'19
DCMD_RSH       .EQU       H'81
DCMD_PS        .EQU       H'21
DCMD_STB       .EQU       H'94
DCMD_MSR       .EQU       H'77
DCMD_RTM       .EQU       H'33
DCMD_TTS       .EQU       H'66
DCMD_SMR1      .EQU       H'44
DCMD_SMR2      .EQU       H'22

WORD_RANGE       .EQU       H'C6C0

;**************** Memory map *******************
EPROM_ADDR             .EQU     H'00000000 
AD_DA_OFFSET           .EQU     H'00000150           ;V1.4
C_STATE1               .EQU     H'0000C160
;********* CONSTANT DEFINE *********
FLASH_CHECK_ADDR1      .EQU     H'000122FD
EE_WS008_ADDR          .EQU     H'00012F0E   ;;VF.0
FLASH_CHECK_ADDR       .EQU     H'00013FFD
STB_A                  .EQU     H'00060000           ;
EEPROM_ADDR            .EQU     H'00080000
EE_EXIST_ADDR          .EQU     H'00083FFD
INST_STR_ADDR          .EQU     H'000F0000           ;INSTRUCTION CODE START ADDRESS
F00_END_ADDR           .EQU     H'000F1F40           ;;TP02-40MR/TP02-60MR
END_ADDR               .EQU     H'1F40               ;;VF.2
NU_STR_ADDR            .EQU     H'000F1F50           ;NU CODE START ADDRESS
MAC_CODE_ADDR          .EQU     H'000F2F00           ;MACHINE CODE START ADDRESS
MACHINE_CODE           .EQU     H'000F2F00           ;;TP02-60MR
INST_STR_ADDR1         .EQU     H'000F8000
F00_END_ADDR1          .EQU     H'000F8BB8
END_ADDR1              .EQU     H'8BB8               ;;VF.2
NU_STR_ADDR1           .EQU     H'000F8BC0
MACHINE_CODE1          .EQU     H'000F91A0           ;;TP02-28MR   
;;****************************************************************?
;;?                    A/D MODULE      V1.61  start               ?
;;?***************************************************************?
NOW_INPUT              .EQU    H'000FAC96     ;1 WORD
TO_C_OR_F              .EQU    H'000FAC97     ;1 WORD
SENSOR_SLOPE           .EQU    H'000FAC99     ;1 WORD
SENSOR_SHIFT           .EQU    H'000FAC9B     ;2 WORD
AD_OFFSET_TIMES0       .EQU    H'000FAC9F     ;1 WORD

AD_FILTER_TIMES2       .EQU    H'000FACA0     ;2 WORDS
AD_FILTER_BUFF2        .EQU    H'000FACA4     ;2 WORDS
AD_MIN_BUFF2           .EQU    H'000FACA8     ;1 WORDS
AD_MAX_BUFF2           .EQU    H'000FACAA     ;1 WORDS
AD_FILTER_BUFF1        .EQU    H'000FACAC     ;2 WORDS
ON_BOARD_SENSOR_THM    .EQU    H'000FACAE     ;2 WORD
AD_FILTER_ADDR3        .EQU    H'000FACB0     ;4AD+  HAVE 20 WORDS
AD_FILTER_ADDR4        .EQU    H'000FACD8     ;4AD+  8 words
AD_FILTER_BUFF         .EQU    H'000FACE0     ;2 WORD
AD_MIN_BUFF            .EQU    H'000FACE4     ;1 WORD
AD_MAX_BUFF            .EQU    H'000FACE6     ;1 WORD
AD_FILTER_ADDR1        .EQU    H'000FACE8     ;; ONLY TP02-60MR/40MR;20 word
AD_FILTER_ADDR2        .EQU    H'000FAD10     ;; 8 words

;**********************************************************
;----------------4TM1/2------------------------------------ (與4AD+共用FILTER BUFFER!!)
V0961_BUFF             .EQU    H'000FAD20         ;16 WORDS       ;4TM+ CH1 TEMP REG
V0962_BUFF             .EQU    H'000FAD40         ;16 WORDS       ;4TM+ CH2 TEMP REG
V0963_BUFF             .EQU    H'000FAD60         ;16 WORDS       ;4TM+ CH3 TEMP REG
V0964_BUFF             .EQU    H'000FAD80         ;16 WORDS       ;4TM+ CH4 TEMP REG
V0966_BUFF             .EQU    H'000FADA0         ;4AD+ ;16 WORDS ;4TM+ CH5 TEMP REG
V0965_BUFF             .EQU    H'000FADC0         ;4AD+ ;16 WORDS ;4TM+ CH6 TEMP REG
V0967_BUFF             .EQU    H'000FADE0         ;4AD+ ;16 WORDS ;4TM+ CH7 TEMP REG
V0968_BUFF             .EQU    H'000FAE00         ;4AD+ ;16 WORDS ;4TM+ CH8 TEMP REG
                              ;H'000FAE20
;|----------------------------------------------------|
;|                   PID          V1.633              |      
;|----------------------------------------------------|
;SV
;Ts
;Kp
;Td
;Ti
;SysFlag             
;------------------------------------------------------
Sub_TI               .EQU    H'000FAE20         ;1 WORD
Err0                 .EQU    H'000FAE22         ;1 WORD
Err1                 .EQU    H'000FAE24         ;1 WORD
Err2                 .EQU    H'000FAE26         ;1 WORD
U1                   .EQU    H'000FAE28         ;1 WORD
                  ;  .EQU    H'000FAE2A         ;1 WORD
A0                   .EQU    H'000FAE2C         ;1 WORD
                  ;  .EQU    H'000FAE2E         ;1 WORD
A1                   .EQU    H'000FAE30         ;1 WORD
                  ;  .EQU    H'000FAE32         ;1 WORD                                         
A2                   .EQU    H'000FAE34         ;1 WORD
                  ;  .EQU    H'000FAE36         ;1 WORD                                        
Pre_Count            .EQU    H'000FAE38         ;1 WORD
A0E0                 .EQU    H'000FAE3A         ;1 WORD
                  ;  .EQU    H'000FAE3C
                  ;  .EQU    H'000FAE3E
A1E1                 .EQU    H'000FAE40         ;1 WORD
                  ;  .EQU    H'000FAE42
                  ;  .EQU    H'000FAE44
RnY0_005             .EQU    H'000FAE46
                  ;  .EQU    H'000FAE48
RnY0_05              .EQU    H'000FAE4A
                  ;  .EQU    H'000FAE4C
FstConV              .EQU    H'000FAE4E         ;1 WORD
                  ;  .EQU    H'000FAE50         ;1 WORD
DeadTime             .EQU    H'000FAE52         ;1 WORD
                  ;  .EQU    H'000FAE54         ;1 WORD
RiseTime             .EQU    H'000FAE56         ;1 WORD
                  ;  .EQU    H'000FAE58         ;1 WORD
YinitV               .EQU    H'000FAE5A         ;1 WORD
TimeCount            .EQU    H'000FAE5C         ;1 WORD
KpAuto               .EQU    H'000FAE5E         ;1 WORD                                        
TdAuto               .EQU    H'000FAE60         ;1 WORD
TiAuto               .EQU    H'000FAE62         ;1 WORD
;----------------------------------------------------------------
AD_RUN_TIMES1        .EQU    H'000FAE64         ;1 WORD  V1.6
AD_RUN_TIMES2        .EQU    H'000FAE66         ;1 WORD  V1.6
AD_RUN_TIMES3        .EQU    H'000FAE68         ;1 WORD  V1.6
AD_RUN_TIMES4        .EQU    H'000FAE6A         ;1 WORD  V1.6
AD_RUN_TIMES5        .EQU    H'000FAE6C         ;1 WORD  V1.6
AD_RUN_TIMES6        .EQU    H'000FAE6E         ;1 WORD  V1.6
AD_RUN_TIMES7        .EQU    H'000FAE70         ;1 WORD  V1.6
AD_RUN_TIMES8        .EQU    H'000FAE72         ;1 WORD  V1.6
CHANNEL_BUFFER       .EQU    H'000FAE74         ;1 WORD  V1.6
NOW_TEMP             .EQU    H'000FAE76         ;1 WORD  V1.6
THM_N_TYPE           .EQU    H'000FAE78         ;1 WORD  V1.6

;----------------------------------------------------------
;**********************************************************

STOP_INP_BUFF        .EQU    H'000FC0E0         ;;FOR INPUT POINT  V0.B


; ****** TP02 USED AS BELOW ********
X0001_ADDR              .EQU    H'000FC100
X_STATE                 .EQU    H'000FC100

;;;REMOTE IO AREA;;;
RL_S1_RX                .EQU    H'000FC119
RL_S2_RX                .EQU    H'000FC11E
RL_S3_RX                .EQU    H'000FC123
RL_S4_RX                .EQU    H'000FC128

X0384_ADDR              .EQU    H'000FC129
X0361_ADDR              .EQU    H'000FC12D           ;;VF.6 OP05/OP06
X0369_ADDR              .EQU    H'000FC12E           ;;
X0377_ADDR              .EQU    H'000FC12F           ;;


Y0001_ADDR              .EQU    H'000FC130
Y_STATE                 .EQU    H'000FC130
Y_STATE1                .EQU    H'C130


RL_S1_TX                .EQU    H'000FC149
RL_S2_TX                .EQU    H'000FC14E
RL_S3_TX                .EQU    H'000FC153
RL_S4_TX                .EQU    H'000FC158

Y0384_ADDR              .EQU    H'000FC159

C0001_ADDR              .EQU    H'000FC160  
C0009_ADDR              .EQU    H'000FC161
C0017_ADDR              .EQU    H'000FC162
C0025_ADDR              .EQU    H'000FC163

C_STATE                 .EQU    H'000FC160

C0241_C0248_ADDR        .EQU     H'000FC17E

DL_S1_TR                .EQU       H'000FC228
DL_S1_RR                .EQU       H'000FC22C
DL_S2_TR                .EQU       H'000FC230
DL_S2_RR                .EQU       H'000FC234
DL_S3_TR                .EQU       H'000FC238
DL_S3_RR                .EQU       H'000FC23C
DL_S4_TR                .EQU       H'000FC240
DL_S4_RR                .EQU       H'000FC244
DL_S5_TR                .EQU       H'000FC248
DL_S5_RR                .EQU       H'000FC24C
DL_S6_TR                .EQU       H'000FC250
DL_S6_RR                .EQU       H'000FC254
DL_S7_TR                .EQU       H'000FC258
DL_S7_RR                .EQU       H'000FC25C
CLRCL_ADDR              .EQU       H'000FC25F

M_STATE                 .EQU       H'000FC260
C2048_ADDR              .EQU       H'000FC260

SC001_ADDR              .EQU       H'000FC260
SC009_ADDR              .EQU       H'000FC261
SC017_ADDR              .EQU       H'000FC262
SC025_ADDR              .EQU       H'000FC263
SC033_ADDR              .EQU       H'000FC264
SC041_ADDR              .EQU       H'000FC265
SC049_ADDR              .EQU       H'000FC266
SC057_ADDR              .EQU       H'000FC267
SC065_ADDR              .EQU       H'000FC268
SC073_ADDR              .EQU       H'000FC269
SC081_ADDR              .EQU       H'000FC26A
SC089_ADDR              .EQU       H'000FC26B ;4tm+  CH1~CH8  USED
SC097_ADDR              .EQU       H'000FC26C  
SC105_ADDR              .EQU       H'000FC26D  
;************************************ 0713 NEW DEFINE **********************
SC113_ADDR              .EQU       H'000FC26E ;TP02 <->N2/V2
SC121_ADDR              .EQU       H'000FC26F ;TP02 <->N2/V2 
SC129_ADDR              .EQU       H'000FC270 ;TP02 <->N2/V2 
SC137_ADDR              .EQU       H'000FC271 ;TP02 <->N2/V2 
SC145_ADDR              .EQU       H'000FC272  
SC153_ADDR              .EQU       H'000FC273  
SC161_ADDR              .EQU       H'000FC274  
SC169_ADDR              .EQU       H'000FC275
SC177_ADDR              .EQU       H'000FC276
SC185_ADDR              .EQU       H'000FC277
SC193_ADDR              .EQU       H'000FC278
SC201_ADDR              .EQU       H'000FC279
SC209_ADDR              .EQU       H'000FC27A
SC217_ADDR              .EQU       H'000FC27B
SC225_ADDR              .EQU       H'000FC27C
SC233_ADDR              .EQU       H'000FC27D
SC241_ADDR              .EQU       H'000FC27E
SC249_ADDR              .EQU       H'000FC27F



;;|--------------------------------------------------------------------------------------|
;;|  TXXXX=>data type is WORD   TOTAL=84B-16B=68B                                        |
;;|  Tmp_ofst_CH1 --> H'000FDF44 ,  Tmp_ofst_CH8 --> H'000FDF52  16B  USED WS067~WS074   |
;;|  Tmp_Val_CH1  --> H'000FC290 ,  Tmp_Val_CH8  --> H'000FC29E  16B                     |
;;|  Tmp_ADC_CH1  --> H'000FCE40 ,  Tmp_ADC_CH8  --> H'000FCE4E  16B                     |
;;|  Tmp_Val_4TM1 --> H'000FC2A0 ,  Tmp_Cnt_4TM2 --> H'000FC2A6   8B                     |
;;|  ChN_ADC_Val  --> H'000FC2A8 ,  ChN_ADC_uV_Val-> H'000FC2B2  12B                     |
;;|  C_F_TEMP1    --> H'000FC2B4 ,  J_K_T_TY8    --> H'000FC2D2  16B                     |
;;|--------------------------------------------------------------------------------------| 
;--------------------------------------------------------------------
;--------------------------------------------------------------------
;Tmp_ofst_CH1     .EQU       WS067_ADDR                        V1.9
;Tmp_ofst_CH2     .EQU       WS068_ADDR 
;Tmp_ofst_CH3     .EQU       WS069_ADDR 
;Tmp_ofst_CH4     .EQU       WS070_ADDR 
;Tmp_ofst_CH5     .EQU       WS071_ADDR 
;Tmp_ofst_CH6     .EQU       WS072_ADDR 
;Tmp_ofst_CH7     .EQU       WS073_ADDR 
;Tmp_ofst_CH8     .EQU       WS074_ADDR
;------------------------------------------------------------------
Tmp_Val_CH1      .EQU       H'000FC290      ;4TM+原V0961
Tmp_Val_CH2      .EQU       H'000FC292      ;4TM+原V0962
Tmp_Val_CH3      .EQU       H'000FC294      ;4TM+原V0963
Tmp_Val_CH4      .EQU       H'000FC296      ;4TM+原V0964
Tmp_Val_CH5      .EQU       H'000FC298      ;4TM+原V0965
Tmp_Val_CH6      .EQU       H'000FC29A      ;4TM+原V0966
Tmp_Val_CH7      .EQU       H'000FC29C      ;4TM+原V0967
Tmp_Val_CH8      .EQU       H'000FC29E      ;4TM+原V0968
;------------------------------------------------------------------
Tmp_ADC_CH1      .EQU       H'000FCE40      ;盧要求增=V0961 ?
Tmp_ADC_CH2      .EQU       H'000FCE42      ;盧要求增=V0962
Tmp_ADC_CH3      .EQU       H'000FCE44      ;盧要求增=V0963
Tmp_ADC_CH4      .EQU       H'000FCE46      ;盧要求增=V0964
Tmp_ADC_CH5      .EQU       H'000FCE48      ;盧要求增=V0965
Tmp_ADC_CH6      .EQU       H'000FCE4A      ;盧要求增=V0966
Tmp_ADC_CH7      .EQU       H'000FCE4C      ;盧要求增=V0967
Tmp_ADC_CH8      .EQU       H'000FCE4E      ;盧要求增=V0968
;------------------------------------------------------------------
Tmp_Val_4TM1     .EQU       H'000FC2A0      ;4TM+原V0979
Tmp_Val_4TM2     .EQU       H'000FC2A2      ;4TM+原V0980
Tmp_Cnt_4TM1     .EQU       H'000FC2A4      ;4TM+原V0981
Tmp_Cnt_4TM2     .EQU       H'000FC2A6      ;4TM+原V0982
;------------------------------------------------------------------
ChN_ADC_Val      .EQU       H'000FC2A8      ;4TM+原V0990
ChN_ADC_oC       .EQU       H'000FC2AA      ;4TM+原V0991
ChN_RefT_oC      .EQU       H'000FC2AC      ;4TM+原V0992
ChN_Object_Temp  .EQU       H'000FC2AE      ;4TM+原V0993
ChN_ADC_uV_Val   .EQU       H'000FC2B0      ;4TM+原V0988_9 ;;2 WORD
                                   ;B2
;------------------------------------------------------------------
C_F_TEMP1        .EQU       H'000FC2B4      ;4TM-1 Channel C/F 選擇(0:C 1:F)                           D2033
J_K_T_TY1        .EQU       H'000FC2B6      ;4TM-1 Channel CT_type_J/K/T Channel選擇(0:無 1:J 2:K 3:T) D2034
C_F_TEMP2        .EQU       H'000FC2B8      ;4TM-1 Channel C/F 選擇(0:C 1:F)                           D2035
J_K_T_TY2        .EQU       H'000FC2BA      ;4TM-1 Channe2 CT_type_J/K/T Channel選擇(0:無 1:J 2:K 3:T) D2036
C_F_TEMP3        .EQU       H'000FC2BC      ;4TM-1 Channel C/F 選擇(0:C 1:F)                           D2037
J_K_T_TY3        .EQU       H'000FC2BE      ;4TM-1 Channe3 CT_type_J/K/T Channel選擇(0:無 1:J 2:K 3:T) D2038
C_F_TEMP4        .EQU       H'000FC2C0      ;4TM-1 Channel C/F 選擇(0:C 1:F)                           D2039
J_K_T_TY4        .EQU       H'000FC2C2      ;4TM-1 Channe4 CT_type_J/K/T Channel選擇(0:無 1:J 2:K 3:T) D2040
C_F_TEMP5        .EQU       H'000FC2C4      ;4TM-2 Channel C/F 選擇(0:C 1:F)                           D2041
J_K_T_TY5        .EQU       H'000FC2C6      ;4TM-2 Channel CT_type_J/K/T Channel選擇(0:無 1:J 2:K 3:T) D2042
C_F_TEMP6        .EQU       H'000FC2C8      ;4TM-2 Channel C/F 選擇(0:C 1:F)                           D2043
J_K_T_TY6        .EQU       H'000FC2CA      ;4TM-2 Channe2 CT_type_J/K/T Channel選擇(0:無 1:J 2:K 3:T) D2044
C_F_TEMP7        .EQU       H'000FC2CC      ;4TM-2 Channel C/F 選擇(0:C 1:F)                           D2045
J_K_T_TY7        .EQU       H'000FC2CE      ;4TM-2 Channe3 CT_type_J/K/T Channel選擇(0:無 1:J 2:K 3:T) D2046
C_F_TEMP8        .EQU       H'000FC2D0      ;4TM-2 Channel C/F 選擇(0:C 1:F)                           D2047
J_K_T_TY8        .EQU       H'000FC2D2      ;4TM-2 Channe4 CT_type_J/K/T Channel選擇(0:無 1:J 2:K 3:T) D2048
;;|---------------------------------------------------------|
;;|one Vxxxx -> 1 word( 2 bytes)                            |
;;|V0001->FC6C0, V0002->FC6C2, V0003->FC6C4, ........       |
;;|last is ->>>>V1024->FCEBF                                |
;;|---------------------------------------------------------|
          
V0001_ADDR       .EQU       H'000FC6C0           
V_MEMORY_ADDR    .EQU       H'000FC6C0    ;;V0001
V_MEMORY_ADDR1   .EQU       H'C6C0        ;;V0001
V_MEMORY_ADDR2   .EQU       H'C6C2        ;;
V_MEMORY_ADDR3   .EQU       H'C6C4
V_MEMORY_ADDR4   .EQU       H'C6C6
V_MEMORY_ADDR5   .EQU       H'C6C8
V_MEMORY_ADDR6   .EQU       H'C6CA
V_MEMORY_ADDR7   .EQU       H'C6CC
V_MEMORY_ADDR8   .EQU       H'C6CE
V0251_ADDR       .EQU       H'C8B4
V0600_ADDR       .EQU       H'000FCB6E        ;OP05 VF.6
V0601_ADDR       .EQU       H'000FCB70        ;OP05 VF.6
V0604_ADDR       .EQU       H'000FCB76        ;OP05 VF.6
V0615_ADDR       .EQU       H'000FCB8C        ;OP05 VF.6
V0616_ADDR       .EQU       H'000FCB8E        ;OP05 VF.6
V0617_ADDR       .EQU       H'000FCB90        ;OP05 V1.1

V0812_ADDR       .EQU       H'000FCD16        ;OP05 V1.1

;;********************************************************************        
V0850_ADDR       .EQU       H'000FCD62     
V0851_ADDR       .EQU       H'000FCD64                                                
DL_S1_TV         .EQU       H'000FCDC8
DL_S1_RV         .EQU       H'000FCDD0
DL_S2_TV         .EQU       H'000FCDD8
DL_S2_RV         .EQU       H'000FCDE0
DL_S3_TV         .EQU       H'000FCDE8
DL_S3_RV         .EQU       H'000FCDF0
DL_S4_TV         .EQU       H'000FCDF8
DL_S4_RV         .EQU       H'000FCE00
DL_S5_TV         .EQU       H'000FCE08
DL_S5_RV         .EQU       H'000FCE10
DL_S6_TV         .EQU       H'000FCE18
DL_S6_RV         .EQU       H'000FCE20
DL_S7_TV         .EQU       H'000FCE28
DL_S7_RV         .EQU       H'000FCE30

;;********************************************************************
V0961_ADDR       .EQU       H'000FCE40      ;A/D V0.D
V0962_ADDR       .EQU       H'000FCE42      ;A/D V0.D
V0963_ADDR       .EQU       H'000FCE44      ;A/D V0.D
V0964_ADDR       .EQU       H'000FCE46      ;A/D V0.D
V0965_ADDR       .EQU       H'000FCE48      ;A/D V1.61 4AD+
V0966_ADDR       .EQU       H'000FCE4A      ;A/D V1.61 4AD+
V0967_ADDR       .EQU       H'000FCE4C      ;A/D V1.61 4AD+
V0968_ADDR       .EQU       H'000FCE4E      ;A/D V1.61 4AD+
V0969_ADDR       .EQU       H'000FCE50      ;4TM-1 itself tm v1.61
V0970_ADDR       .EQU       H'000FCE52      ;4TM-2 itself tm v1.61
;----------------4TM1/2------------------------------------
V0971_ADDR       .EQU       H'000FCE54       ;4TM1_C/T1 Value.--ADC_Value
V0972_ADDR       .EQU       H'000FCE56       ;4TM1_C/T2 Value.--ADC_Value
V0973_ADDR       .EQU       H'000FCE58       ;4TM1_C/T3 Value.--ADC_Value
V0974_ADDR       .EQU       H'000FCE5A       ;4TM1_C/T4 Value.--ADC_Value
;----------------
V0975_ADDR       .EQU       H'000FCE5C       ;4TM2_C/T1 Value.--ADC_Value
V0976_ADDR       .EQU       H'000FCE5E       ;4TM2_C/T2 Value.--ADC_Value
V0977_ADDR       .EQU       H'000FCE60       ;4TM2_C/T3 Value.--ADC_Value
V0978_ADDR       .EQU       H'000FCE62       ;4TM2_C/T4 Value.--ADC_Value
;----------------
V0979_ADDR       .EQU       H'000FCE64       ;4TM1_Temp1 Value. --ADC_Value
V0980_ADDR       .EQU       H'000FCE66       ;4TM2_Temp1 Value. --ADC_Value
;----------------
V0981_ADDR       .EQU       H'000FCE68       ;4TM1_Ch_Cnt Value. --ScanValue 0-4: 0:RefT1 ,1:CT1 2:CT2 3:CT3  4:CT4
V0982_ADDR       .EQU       H'000FCE6A       ;4TM2_Ch_Cnt Value. --ScanValue 0-4: 0:RefT2 ,1:CT5 2:CT6 3:CT7  4:CT8
;----------------
V0983_ADDR       .EQU       H'000FCE6C       ;4TM1/2 軟體濾波器On時,每個ChN皆需經五次 A/D讀取方有效!!(RnL=TM1,RnH=TM2)
;----------------------------------------------------------
V0984_ADDR       .EQU       H'000FCE6E
;**********************************************************
V0985_ADDR       .EQU       H'000FCE70       ;D/A
V0986_ADDR       .EQU       H'000FCE72       ;D/A 
V0987_ADDR       .EQU       H'000FCE74      ;D/A
V0988_ADDR       .EQU       H'000FCE76       ;D/A
;********************************************************** 注意2DA之V0987_ADDR~V0990和4TM有沖

;---------------4TM1/2-------------------------------------
;V0987_ADDR       .EQU       H'000FCE74      ;驗証:F68W-->S1-S2=? 0:S1=S2  1:S1>S2  2:S1<S2  3:ERR

V0990_ADDR       .EQU       H'000FCE7A      ;驗証:欲轉換溫度之 ChN_ADC_Val(含符號之16bits表示)
V0991_ADDR       .EQU       H'000FCE7C      ;驗証:欲轉換 ChN之 CT溫度值   (正值:0-29999 負值:絕對值+30000 for PU12 demo表示)
V0992_ADDR       .EQU       H'000FCE7E      ;驗証:欲轉換 ChN之 參考溫度值 (正值:0-1000  負值:無)
V0993_ADDR       .EQU       H'000FCE80      ;驗証:欲轉換 ChN之 實測溫度值 (正值:0-29999 負值:絕對值+30000 for PU12 demo表示)
V0994_ADDR       .EQU       H'000FCE82      ;驗証:欲轉換 ChN之 實測溫度值 (回傳值,暫用! 絕對值 oC/oF + SC041/42)
V0988_9_ADDR     .EQU       H'000FCE84      ;驗証:4TM_ChN_uV Value.(2Word) --轉換ChN成溫度值時,先轉成電壓(uV)之暫存值!!
;----------------------------------------------------------
;**********************************************************
V1000_ADDR       .EQU       H'000FCE8E
V1001_ADDR       .EQU       H'000FCE90
V1002_ADDR       .EQU       H'000FCE92
V1003_ADDR       .EQU       H'000FCE94
V1004_ADDR       .EQU       H'000FCE96
V1005_ADDR       .EQU       H'000FCE98
V1006_ADDR       .EQU       H'000FCE9A
V1007_ADDR       .EQU       H'000FCE9C
V1008_ADDR       .EQU       H'000FCE9E
;
;;;RTC_CTRL_ADDR    .EQU       H'000FCEB1   ; *V1017 TEMPORARY
SECOND_ADDR      .EQU       H'000FCEB3      ;  V1018 LOW BYTE
MINUTE_ADDR      .EQU       H'000FCEB5      ;  V1019 LOW BYTE
HOUR_ADDR        .EQU       H'000FCEB7      ;  V1020 LOW BYTE
DATE_ADDR        .EQU       H'000FCEB9      ;  V1021 LOW BYTE
MONTH_ADDR       .EQU       H'000FCEBD      ;  V1023 LOW BYTE
YEAR_ADDR        .EQU       H'000FCEBF      ;  V1024 LOW BYTE
WEEK_ADDR        .EQU       H'000FCEBB      ;  V1022 LOW BYTE
V1024_ADDR       .EQU       H'000FCEBF 

;;|----------------------------------------------------------|
;;|  Dxxxx=>data type is WORD                                |
;;|  D0001->FCEC0 ,  D0002->FCEC2  .....                     |
;;|  D2048->FDEBF                                            |
;;|----------------------------------------------------------|
D_MEMORY_ADDR    .EQU       H'000FCEC0
D2048_ADDR       .EQU       H'000FDEBF

D0001_ADDR       .EQU       H'000FCEC0
D0002_ADDR       .EQU       H'000FCEC2
D0003_ADDR       .EQU       H'000FCEC4
D0004_ADDR       .EQU       H'000FCEC6
D0005_ADDR       .EQU       H'000FCEC8
D0006_ADDR       .EQU       H'000FCECA
D0007_ADDR       .EQU       H'000FCECC
D0008_ADDR       .EQU       H'000FCECE
D0009_ADDR       .EQU       H'000FCED0
D0010_ADDR       .EQU       H'000FCED2
D_MEMORY_ADDR1   .EQU       H'CEC0
WS_MEMORY_ADDR   .EQU       H'000FDEC0
WS_MEMORY_ADDR1  .EQU       H'DEC0
WS001_ADDR       .EQU       H'000FDEC0
WS002_ADDR       .EQU       H'000FDEC2
WS003_ADDR       .EQU       H'000FDEC4
WS004_ADDR       .EQU       H'000FDEC6
WS005_ADDR       .EQU       H'000FDEC8
WS006_ADDR       .EQU       H'000FDECA
WS007_ADDR       .EQU       H'000FDECC
WS008_ADDR       .EQU       H'000FDECE
WS009_ADDR       .EQU       H'000FDED0
WS010_ADDR       .EQU       H'000FDED2
WS011_ADDR       .EQU       H'000FDED4
WS012_ADDR       .EQU       H'000FDED6
WS013_ADDR       .EQU       H'000FDED8
WS014_ADDR       .EQU       H'000FDEDA
WS015_ADDR       .EQU       H'000FDEDC
WS016_ADDR       .EQU       H'000FDEDE
WS017_ADDR       .EQU       H'000FDEE0
WS018_ADDR       .EQU       H'000FDEE2
WS019_ADDR       .EQU       H'000FDEE4
WS020_ADDR       .EQU       H'000FDEE6
WS021_ADDR       .EQU       H'000FDEE8
WS022_ADDR       .EQU       H'000FDEEA
WS023_ADDR       .EQU       H'000FDEEC
WS024_ADDR       .EQU       H'000FDEEE
WS025_ADDR       .EQU       H'000FDEF0
WS026_ADDR       .EQU       H'000FDEF2
WS027_ADDR       .EQU       H'000FDEF4
WS028_ADDR       .EQU       H'000FDEF6
WS029_ADDR       .EQU       H'000FDEF8
WS030_ADDR       .EQU       H'000FDEFA
WS031_ADDR       .EQU       H'000FDEFC
WS032_ADDR       .EQU       H'000FDEFE
WS033_ADDR       .EQU       H'000FDF00
WS034_ADDR       .EQU       H'000FDF02
WS035_ADDR       .EQU       H'000FDF04
WS036_ADDR       .EQU       H'000FDF06
WS037_ADDR       .EQU       H'000FDF08
WS038_ADDR       .EQU       H'000FDF0A
WS039_ADDR       .EQU       H'000FDF0C
WS040_ADDR       .EQU       H'000FDF0E
WS041_ADDR       .EQU       H'000FDF10
;-------------------------------------
WS042_ADDR       .EQU       H'000FDF12
WS043_ADDR       .EQU       H'000FDF14   ;FDF14   TEST : WS013
WS044_ADDR       .EQU       H'000FDF16   ;FDF16          WS014
WS045_ADDR       .EQU       H'000FDF18   ;FDF18          WS015
WS046_ADDR       .EQU       H'000FDF1A   ;FDF1A          WS016
WS047_ADDR       .EQU       H'000FDF1C
WS048_ADDR       .EQU       H'000FDF1E
WS049_ADDR       .EQU       H'000FDF20
WS050_ADDR       .EQU       H'000FDF22
WS051_ADDR       .EQU       H'000FDF24
WS052_ADDR       .EQU       H'000FDF26
WS053_ADDR       .EQU       H'000FDF28
WS054_ADDR       .EQU       H'000FDF2A
WS055_ADDR       .EQU       H'000FDF2C
WS056_ADDR       .EQU       H'000FDF2E
WS057_ADDR       .EQU       H'000FDF30
WS058_ADDR       .EQU       H'000FDF32
WS059_ADDR       .EQU       H'000FDF34
WS060_ADDR       .EQU       H'000FDF36
WS061_ADDR       .EQU       H'000FDF38
WS062_ADDR       .EQU       H'000FDF3A
WS063_ADDR       .EQU       H'000FDF3C   ;;V0.D 3B->3C
WS064_ADDR       .EQU       H'000FDF3E   ;;SECOND 4AD+ Control MODE v1.61
WS065_ADDR       .EQU       H'000FDF40   ;1ST MODULE THERMAL VALUE v1.61
WS066_ADDR       .EQU       H'000FDF42   ;2ND MODULE THERMAL VALUE v1.61
;----------------------- 4TM+ Offset Buffer -------------------------------
WS067_ADDR       .EQU       H'000FDF44   ;CH1 OFFSET REGISTER v1.61
WS068_ADDR       .EQU       H'000FDF46   ;CH2 OFFSET REGISTER v1.61
WS069_ADDR       .EQU       H'000FDF48   ;CH3 OFFSET REGISTER v1.61
WS070_ADDR       .EQU       H'000FDF4A   ;CH4 OFFSET REGISTER v1.61
WS071_ADDR       .EQU       H'000FDF4C   ;CH5 OFFSET REGISTER v1.61
WS072_ADDR       .EQU       H'000FDF4E   ;CH6 OFFSET REGISTER v1.61
WS073_ADDR       .EQU       H'000FDF50   ;CH7 OFFSET REGISTER v1.61
WS074_ADDR       .EQU       H'000FDF52   ;CH8 OFFSET REGISTER v1.61
;----------------------- 4TM+ Offset Buffer -------------------------------
;-------------------------------------
;----------------- 4TM+ ------------------------------
Tmp_ofst_CH1     .EQU       H'000FDF44   ;OFFSET BUFF1 WS067_ADDR
Tmp_ofst_CH2     .EQU       H'000FDF46   ;OFFSET BUFF2 WS068_ADDR
Tmp_ofst_CH3     .EQU       H'000FDF48   ;OFFSET BUFF3 WS069_ADDR
Tmp_ofst_CH4     .EQU       H'000FDF4A   ;OFFSET BUFF4 WS070_ADDR
Tmp_ofst_CH5     .EQU       H'000FDF4C   ;OFFSET BUFF5 WS071_ADDR
Tmp_ofst_CH6     .EQU       H'000FDF4E   ;OFFSET BUFF6 WS072_ADDR
Tmp_ofst_CH7     .EQU       H'000FDF50   ;OFFSET BUFF7 WS073_ADDR
Tmp_ofst_CH8     .EQU       H'000FDF52   ;OFFSET BUFF8 WS074_ADDR
;-----------------------------------------------------

;-------------------------------------
;***************************************************************************
;---------------------------------------------------------------------------(暫時定義!!)
WS075_ADDR       .EQU       H'000FDF54    ;4TM-1:存在否? 0:不存在  other:存在(啟動4TM_Module1 ADC_Converter!! Ch1-4)
WS076_ADDR       .EQU       H'000FDF56    ;4TM-2:存在否? 0:不存在  other:存在(啟動4TM_Module2 ADC_Converter!! Ch5-8)
;---------------------------------------------------------------------------
WS077_ADDR       .EQU       H'000FDF58    ;OFFSET VALUE1
WS078_ADDR       .EQU       H'000FDF5A    ;OFFSET VALUE2
WS079_ADDR       .EQU       H'000FDF5C    ;OFFSET VALUE3
WS080_ADDR       .EQU       H'000FDF5E    ;OFFSET VALUE4
WS081_ADDR       .EQU       H'000FDF60    ;OFFSET VALUE5
WS082_ADDR       .EQU       H'000FDF62    ;OFFSET VALUE6
WS083_ADDR       .EQU       H'000FDF64    ;OFFSET VALUE7
WS084_ADDR       .EQU       H'000FDF66    ;OFFSET VALUE8
;---------------------------------------------------------------------------
WS085_ADDR       .EQU       H'000FDF68    ;4TM-1:軟體濾波器? 0:無  other:有,5筆取3筆後平均!!
WS086_ADDR       .EQU       H'000FDF6A    ;4TM-2:軟體濾波器? 0:無  other:有,5筆取3筆後平均!!
;---------------------------------------------------------------------------
WS087_ADDR       .EQU       H'000FDF6C    ;
WS088_ADDR       .EQU       H'000FDF6E    ;
WS089_ADDR       .EQU       H'000FDF70    ;
WS090_ADDR       .EQU       H'000FDF72    ;
WS091_ADDR       .EQU       H'000FDF74    
WS092_ADDR       .EQU       H'000FDF76    
WS093_ADDR       .EQU       H'000FDF78    
WS094_ADDR       .EQU       H'000FDF7A    
WS095_ADDR       .EQU       H'000FDF7C    
WS096_ADDR       .EQU       H'000FDF7E    
WS097_ADDR       .EQU       H'000FDF80    
WS098_ADDR       .EQU       H'000FDF82    
WS099_ADDR       .EQU       H'000FDF84
WS100_ADDR       .EQU       H'000FDF86 
WS101_ADDR       .EQU       H'000FDF88 
WS102_ADDR       .EQU       H'000FDF8A 
WS103_ADDR       .EQU       H'000FDF8C 
WS104_ADDR       .EQU       H'000FDF8E
WS105_ADDR       .EQU       H'000FDF90 
WS106_ADDR       .EQU       H'000FDF92 
WS107_ADDR       .EQU       H'000FDF94 
WS108_ADDR       .EQU       H'000FDF96 
WS109_ADDR       .EQU       H'000FDF98
WS110_ADDR       .EQU       H'000FDF9A 
WS111_ADDR       .EQU       H'000FDF9C 
WS112_ADDR       .EQU       H'000FDF9E 
WS113_ADDR       .EQU       H'000FDFA0 
WS114_ADDR       .EQU       H'000FDFA2
WS115_ADDR       .EQU       H'000FDFA4
WS116_ADDR       .EQU       H'000FDFA6 
WS117_ADDR       .EQU       H'000FDFA8
WS118_ADDR       .EQU       H'000FDFAA
WS119_ADDR       .EQU       H'000FDFAC
WS120_ADDR       .EQU       H'000FDFAE
WS121_ADDR       .EQU       H'000FDFB0    
WS122_ADDR       .EQU       H'000FDFB2    
WS123_ADDR       .EQU       H'000FDFB4    
WS124_ADDR       .EQU       H'000FDFB6    
WS125_ADDR       .EQU       H'000FDFB8    
WS126_ADDR       .EQU       H'000FDFBA    
;-----------------------------------------
WS127_ADDR       .EQU       H'000FDFBC   ;UP_DATA 
WS128_ADDR       .EQU       H'000FDFBE   ;COUNT 
;;----------------------------------------
WS041_ADDR_UPDATA .EQU       H'000FDFBC  ;=WS067->WS0127
WS041_ADDR_COUNT  .EQU       H'000FDFBE  ;=WS068->WS0128
;***************************************************************************
;;|----------------------------------------------------------|
;;|  WCxxx=>data type is WORD                                |
;;|  WC001->FDFC0 ,  WC002->FDFC2  .....                     |
;;|  WC912->FE6E0                                            |
;;|----------------------------------------------------------|           
WC001_ADDR       .EQU       H'000FDFC0           
WC_MEMORY_ADDR   .EQU       H'000FDFC0   ;FDFC0 COMPILER CODE F2F00 v1.61
WC_MEMORY_ADDR1  .EQU       H'DFC0
FILE21_ADDR      .EQU       H'000FE6E0   ;;
;;|----------------------------------------------------------|
;;|  FXXXX=>data type is WORD                                |
;;|  F0001->FEE74 ,  F0002->FEE76  .....                     |
;;|  F0130->FEF78                                            |
;;|----------------------------------------------------------|           
F0001_ADDR       .EQU       H'000FEE74           
F0130_ADDR       .EQU       H'000FEF78 

WX_MEMORY_ADDR   .EQU       H'000FEF78   ;FFAE0 INST CODE F0000
WY_MEMORY_ADDR   .EQU       H'000FEF78   ;FFB10 NU CODE F1F50
;************************************************************
LABEL_INST_ADDR  .EQU       H'000FEF78   ;;FEF78~FF078
LABEL_INST_ADDR1 .EQU       H'EF78       ;;LB001 LB128
                                         ;;FEF78+(128-1)*2=FF078
LB111_ADDR       .EQU       H'000FF054
LB112_ADDR       .EQU       H'000FF056
LB113_ADDR       .EQU       H'000FF058
LB114_ADDR       .EQU       H'000FF05A
                           
;************************************************************





;******************************************************************************
;*  Word Defind.    000FFD00-000FF03F     WEI:FFC040-FFC07F                     *
;******************************************************************************
IO_CHK_BUFF1           .EQU    H'000FF078         ;For I/O loop back used
IN_STR_ADDR            .EQU    H'000FF078         ;FOR F80,F81 INPUT refresh
IO_CHK_BUFF2           .EQU    H'000FF079         ;JW10 series maximum 128 points
IO_CHK_BUFF3           .EQU    H'000FF07A         ;need 16 bytes to check
IO_CHK_BUFF4           .EQU    H'000FF07B         ;
IO_CHK_BUFF5           .EQU    H'000FF07C         ;
IO_CHK_BUFF6           .EQU    H'000FF07D         ;
IO_CHK_BUFF7           .EQU    H'000FF07E         ;
IO_CHK_BUFF8           .EQU    H'000FF07F         ;
IO_CHK_BUFF9           .EQU    H'000FF080         ;
IO_CHK_BUFF10          .EQU    H'000FF081         ;
IO_CHK_BUFF11          .EQU    H'000FF082         ;
IO_CHK_BUFF12          .EQU    H'000FF083         ;
IO_CHK_BUFF13          .EQU    H'000FF084         ;
OUT_STR_ADDR           .EQU    H'000FF084           ;FOR F80,F81 OUTPUT refresh
IO_CHK_BUFF14          .EQU    H'000FF085         ;
IO_CHK_BUFF15          .EQU    H'000FF086         ;
IO_CHK_BUFF16          .EQU    H'000FF087         ;
;;***************************************************************?

;******************************************************************************
;*  Byte Defind.      FFF08A-FFF0DF                                           *
;******************************************************************************
DATA_CHK_BUFF     .EQU     H'000FF08A         ;;VF.2
R5L_BUFFER        .EQU     H'000FF08A         ;;TP02
R5H_BUFFER        .EQU     H'000FF08B         ;;TP02
INST_CODE         .EQU     H'000FF08E         ; 1 WORD
INST_FUN_DATA     .EQU     H'000FF090         ; 3 WORDS
STR_NUMBER        .EQU     H'000FF098         ;1 BYTE
FN_KIND           .EQU     H'000FF099         ;1 BYTE
DATA_TYPE         .EQU     H'000FF09A         ;1 BYTE
MCS_NUMBER        .EQU     H'000FF09B         ;1 BYTE
ONLS_NUMBER       .EQU     H'000FF09C         ;1 BYTE
JCS_NUMBER        .EQU     H'000FF09D         ;1 BYTE
NEXT_NUMBER       .EQU     H'000FF09E         ;1 BYTE
FOR_NUMBER        .EQU     H'000FF09F         ;1 BYTE
CALL_NUMBER       .EQU     H'000FF0A0         ;1 BYTE
JMP_NUMBER        .EQU     H'000FF0A1         ;1 BYTE
;;;COM_TIME_OUT      .EQU     H'000FF0A2         ;1 BYTE
NU_CODE           .EQU     H'000FF0A3         ;1 BYTE
ASCII_1000C       .EQU     H'000FF0A4         ;1 BYTE
ASCII_100C        .EQU     H'000FF0A5         ;1 BYTE
ASCII_10C         .EQU     H'000FF0A6         ;1 BYTE
ASCII_0C          .EQU     H'000FF0A7         ;1 BYTE
ER3_BUFFER        .EQU     H'000FF0A8         ;;TP02 2 WORD
R4_BUFFER         .EQU     H'000FF0AC         ;;TP02 1 WORD
R3_BUFFER         .EQU     H'000FF0AE         ;;TP02 1 WORD
R2_BUFFER         .EQU     H'000FF0B0         ;;TP02 1 WORD
R6_BUFFER         .EQU     H'000FF0B2         ;;TP02 1 WORD
R5_BUFFER         .EQU     H'000FF0B4         ;;TP02 1 WORD
R6L_BUFFER        .EQU     H'000FF0B6         ;;TP02 1 BYTE
SYS_226_ADDR      .EQU     H'000FF0B7         ;;TP02 1 BYTE
SYS_236_ADDR      .EQU     H'000FF0B8         ;;TP02 1 BYTE
SKIP_NUMBER       .EQU     H'000FF0B9         ;;TP02 1 BYTE
CHK_CODE_RADDR    .EQU     H'000FF0BA         ;;2 WORDS
F58_END_CODE      .EQU     H'000FF0BE         ;;1 BYTE TP02
FN_TYPE           .EQU     H'000FF0BF         ;;TP02  1 BYTE
;;;
BYTE_NO           .EQU     H'000FF0C0      ;Data link used only
BYTE_COUNT        .EQU     H'000FF0C1      ;;;TP02
TIME_DIFF_10MS    .EQU     H'000FF0C2      ;;;TP02
TIME_04S_BASE     .EQU     H'000FF0C3      ;;;TP02
TIME_08S_BASE     .EQU     H'000FF0C4      ;;;TP02
INT_KIND          .EQU     H'000FF0C5      ;1 BYTE
SYS_234_IO        .EQU     H'000FF0C6      ;;;TP02
SCLK_STR          .EQU     H'000FF0C7      ;;;TP02
OLD_INST_NO       .EQU     H'000FF0C8      ;;;TP02
X1_X8_BUFF        .EQU     H'000FF0C9
X9_X12_BUFF       .EQU     H'000FF0CA
X13_X20_BUFF      .EQU     H'000FF0CB
X21_X24_BUFF      .EQU     H'000FF0CC
X25_X32_BUFF      .EQU     H'000FF0CD
X33_X36_BUFF      .EQU     H'000FF0CE
Y1_Y8_BUFF        .EQU     H'000FF0CF
Y9_Y12_BUFF       .EQU     H'000FF0D0
Y13_Y20_BUFF      .EQU     H'000FF0D1
Y21_Y24_BUFF      .EQU     H'000FF0D2
TIME_01S_BASE     .EQU     H'000FF0D3
TIME_1S_BASE      .EQU     H'000FF0D4
LOGIC_ERR_KIND    .EQU     H'000FF0D5
DS_SECOND_ADDR    .EQU     H'000FF0D6
DS_MINUTE_ADDR    .EQU     H'000FF0D7
DS_HOUR_ADDR      .EQU     H'000FF0D8
F52_TENK          .EQU     H'000FF0D9           ;;TP02
F52_TENK1         .EQU     H'000FF0DA           ;;TP02
F53_SCAN          .EQU     H'000FF0DB           ;;TP02
F50_BIT1_BUFF     .EQU     H'000FF0DC           ;;TP02
F50_BIT2_BUFF     .EQU     H'000FF0DD           ;;TP02
F50_BIT3_BUFF     .EQU     H'000FF0DE           ;;TP02
F50_BIT4_BUFF     .EQU     H'000FF0DF           ;;TP02

Y_USED_TABLE     .EQU       H'000FF0E0
C_USED_TABLE     .EQU       H'000FF110
M_USED_TABLE     .EQU       H'000FF210
T_C_USED_TABLE   .EQU       H'000FF220


;;STACK POINTER   .EQU     H'000FFEFE




;***  PU12/PC12 COMMUNICATION BUFFFR  FF240--FF68F SIZE:(1104 bytes)  ***
PG_STX            .EQU     H'000FF240               
PG_BUF1           .EQU     H'000FF241                
PG_BUF2           .EQU     H'000FF242                
PG_BUF3           .EQU     H'000FF243                
PG_BUF4           .EQU     H'000FF244                
PG_BUF5           .EQU     H'000FF245                
PG_BUF6           .EQU     H'000FF246                
PG_BUF7           .EQU     H'000FF247                
PG_BUF8           .EQU     H'000FF248                
PG_BUF9           .EQU     H'000FF249                
PG_BUF10          .EQU     H'000FF24A                
PG_BUF11          .EQU     H'000FF24B                
PG_BUF12          .EQU     H'000FF24C                
PG_BUF13          .EQU     H'000FF24D                
PG_BUF14          .EQU     H'000FF24E                
PG_BUF15          .EQU     H'000FF24F                
PG_BUF16          .EQU     H'000FF250                
PG_BUF17          .EQU     H'000FF251                
PG_BUF18          .EQU     H'000FF252                
PG_BUF19          .EQU     H'000FF253                
PG_BUF20          .EQU     H'000FF254                
PG_BUF21          .EQU     H'000FF255                
PG_BUF22          .EQU     H'000FF256                

PG_EXT            .EQU     H'000FF400

F33_TX_CNT        .EQU     H'000FF680               ;;16 BYTES
F33_TX_BUFF       .EQU     H'000FF681               ;;  

;***  COMPUTER LINK BUFFER  FF690--FFADF SIZE:(1104 bytes)  ***
ASCII1_3A         .EQU     H'000FF690               ; :
ASCII2_3A         .EQU     H'000FF691               ; :
COM_BUF1          .EQU     H'000FF692               ;AD(H)
COM_BUF2          .EQU     H'000FF693               ;AD(L)
COM_BUF3          .EQU     H'000FF694               ; ?
COM_BUF4          .EQU     H'000FF695               ;RI
COM_BUF5          .EQU     H'000FF696               ;Command first byte
COM_BUF6          .EQU     H'000FF697               ;Command second byte
COM_BUF7          .EQU     H'000FF698               ;Command third byte
COM_BUF8          .EQU     H'000FF699               ;
COM_BUF9          .EQU     H'000FF69A               ;
COM_BUF10         .EQU     H'000FF69B               ;
COM_BUF11         .EQU     H'000FF69C               ;
COM_BUF12         .EQU     H'000FF69D               ;
COM_BUF13         .EQU     H'000FF69E               ;
COM_BUF14         .EQU     H'000FF69F               ;
COM_BUF15         .EQU     H'000FF6A0               ;
COM_BUF16         .EQU     H'000FF6A1               ;
COM_BUF17         .EQU     H'000FF6A2               ;
COM_BUF18         .EQU     H'000FF6A3               ;
COM_BUF19         .EQU     H'000FF6A4               ;
COM_BUF20         .EQU     H'000FF6A5               ;

S1_TX_BUFF     .EQU       H'000FF8E0           ;TP02
S1_RX_BUFF     .EQU       H'000FF900           ;TP02
S2_TX_BUFF     .EQU       H'000FF920           ;TP02
S2_RX_BUFF     .EQU       H'000FF940           ;TP02
S3_TX_BUFF     .EQU       H'000FF960           ;TP02
S3_RX_BUFF     .EQU       H'000FF980           ;TP02
S4_TX_BUFF     .EQU       H'000FF9A0           ;TP02
S4_RX_BUFF     .EQU       H'000FF9C0           ;TP02
S5_TX_BUFF     .EQU       H'000FF9E0           ;TP02
S5_RX_BUFF     .EQU       H'000FFA00           ;TP02
S6_TX_BUFF     .EQU       H'000FFA20           ;TP02
S6_RX_BUFF     .EQU       H'000FFA40           ;TP02
S7_TX_BUFF     .EQU       H'000FFA60           ;TP02
S7_RX_BUFF     .EQU       H'000FFA80           ;TP02
S8_TX_BUFF     .EQU       H'000FFAA0           ;TP02
S8_RX_BUFF     .EQU       H'000FFAC0           ;TP02
T_C_STATUS     .EQU       H'000FFAE0           ;16 byte   FFAE0~FFAF0
;;                        H'000FFAF0         
;;--------------------- TP02 <--> MOTOR_BUS ,,V2,,E2,,---------------
S1_Buffer      .EQU       H'000FFAF0           ;32X2 = 64 byte   H'40    ;紀錄ID0~ID31的S1位址
S2_Buffer      .EQU       H'000FFB30           ;32X2 = 64 byte   H'40    ;紀錄ID0~ID31的S2位址
Times_Up       .EQU       H'000FFB70           ;32X1 = 32 byte   H'20    ;紀錄ID0~ID31的每次SCANTIME檢查是否有Respond總次數
Command_Buff   .EQU       H'000FFB90           ;40X1 = 40 byte   H'28    ;
Respond_Buff   .EQU       H'000FFBB8           ;40X1 = 40 byte   H'28    ;回應值暫存器:00 數量 資料1 資料2 .... 資料38
;;Respond_Buff   .EQU       H'000FC6C0                                   ;TEST V0001_ADDR
Base_Time      .EQU       H'000FFBE0           ;01X2 = 2  byte   H'02    ;存放scan 30 ms初始時間值
ID_Block       .EQU       H'000FFBE2           ;01X2 = 2  byte   H'02    ;ID0~ID7(Block 0)～ID24~ID31(Block 3)共四個
Scan_Bit08     .EQU       H'000FFBE4           ;01X1 = 1  byte   H'01    ;ID00~ID07
Scan_Bit16     .EQU       H'000FFBE5           ;01X1 = 1  byte   H'01    ;ID08~ID15
Scan_Bit24     .EQU       H'000FFBE6           ;01X1 = 1  byte   H'01    ;ID16~ID23
Scan_Bit32     .EQU       H'000FFBE7           ;01X1 = 1  byte   H'01    ;ID24~ID31
Run_Stop_State .EQU       H'000FFBE8           ;01X4 = 4  byte   H'04    ;紀錄每個ID目前正處於Run或Stop狀態,方便判斷執行正負轉
Fwd_Rev_State  .EQU       H'000FFBEC           ;01X4 = 4  byte   H'04    ;紀錄每個ID目前正處於Fwd或Rev 狀態,方便判斷執行Run/Stop
Log_RefBit     .EQU       H'000FFBF2           ;01X4 = 4  byte   H'04
;;Log_RefBit   .EQU       H'000FC26E                                     ;TEST
;;PluseUp_Scan .EQU       H'000FC26E           ;01X4 = 4  byte   H'04    ;紀錄曾經發生Respond 的每個ID SC129  ~ SC137
;;-------------------------------------------------------------------
;;;//////////////////////////////////////////////////////////////////
R2_DATA                 .EQU    H'000FFCDC         ;2 WORDS TP02
R3_DATA                 .EQU    H'000FFCE0         ;2 WORDS TP02
R4_DATA                 .EQU    H'000FFCE4         ;2 WORDS TP02
FOR_NEXT_ADDR           .EQU    H'000FFCE8         ;2 WORDS TP02
FOR_NEXT_LPNUM          .EQU    H'000FFCEC         ;1 WORD TP02
FOR_NEXT_NUM            .EQU    H'000FFCEE         ;1 WORD TP02
PDTST_ADDR              .EQU    H'000FFCF0         ;1 BYTE TP02
BYTE_COUNTER            .EQU    H'000FFCF1         ;;TP02
LABEL_RET_BUFFER        .EQU    H'000FFCF2         ;1 WORD TP02
R0_BUFFER               .EQU    H'000FFCF4         ;1 WORD TP02
R1_BUFFER               .EQU    H'000FFCF6         ;1 WORD TP02
SCAN_25_TIMES           .EQU    H'000FFCF8         ;;V0.7  ;1 WORD TP02
LAST_HSC_MODE           .EQU    H'000FFCFA         ;1 WORD TP02
BUFF_PTR                .EQU    H'000FFCFC         ; 2 WORDS  Serial_int2 used
BROAD_MESSAGE           .EQU    H'000FFD00         ; 1 WORD
SCAN_TIME_BASE          .EQU    H'000FFD02         ; 1 WORD
SCAN_TIME_BASE1         .EQU    H'000FFD03         ;
TIME_BASE               .EQU    H'000FFD04         ; 1 WORD
TIME_BASE1              .EQU    H'000FFD05         ;
;;INP_A_BUFF              .EQU    H'000FFD06         ; 2 WORDS
;;INP_B_BUFF              .EQU    H'000FFD0A         ; 2 WORDS
TOTAL_BYTE              .EQU    H'000FFD0E         ; 1 WORD
;;; FFD10 ON CHIP MEMORY START  ;;;;;;;;;;;;;;;;;;;;
FRAME_PTR               .EQU    H'000FFD10         ; 2 WORDS  Serial_int1 used
PADR_ADDR               .EQU    H'000FFD14         ; 2 WORDS
PG_RI_ADDR              .EQU    H'000FFD18           ;
RESP_TM_BASEPG          .EQU    H'000FFD19           ;
TIMER_SYS               .EQU    H'000FFD1A
TIMER_LED               .EQU    H'000FFD1B
SLAVE_RING              .EQU    H'000FFD1C           ;Data link used only
TIME_BASE2              .EQU    H'000FFD1D
TIME_BASE3              .EQU    H'000FFD1E
LED_SCAN                .EQU    H'000FFD1F
RESP_TM_BASE            .EQU    H'000FFD20         ;Computer link response time base
RI_ADDR                 .EQU    H'000FFD21         ;RI response time unit
DLINK_TIMEOUT           .EQU    H'000FFD22         ;Remote I/O link used only
TOTAL_IO_NO             .EQU    H'000FFD23         ;The total 4094,4021 numbers
DOUT_IO_NO              .EQU    H'000FFD24         ; 4094 numbers
DINP_IO_NO              .EQU    H'000FFD25         ; 4021 numbers
SECOND_WORD             .EQU    H'000FFD26         ;;TP02  1 WORD
THIRD_WORD              .EQU    H'000FFD28         ;;TP02  1 WORD
FOURTH_WORD             .EQU    H'000FFD2A         ;;TP02  1 WORD
F08_ENDS_ADDR           .EQU    H'000FFD2C         ;;TP02  1 WORD
F55_DSW                 .EQU    H'000FFD2E         ; 2 WORD TP02
INT_KIND_BUFF1          .EQU    H'000FFD32         ;1 BYTE
INT_KIND_BUFF2          .EQU    H'000FFD33         ;1 BYTE
INT_KIND_BUFF3          .EQU    H'000FFD34         ;1 BYTE
INT_KIND_BUFF4          .EQU    H'000FFD35         ;1 BYTE
INT_KIND_BUFF5          .EQU    H'000FFD36         ;1 BYTE TP02
INT_KIND_BUFF6          .EQU    H'000FFD37         ;;TP02 1 BYTE
JCS_ADDR                .EQU    H'000FFD38         ;;1 WORD, V0.C
MCR_NUMBER              .EQU    H'000FFD3A         ;;TP02  1 BYTE
AD_FILTER_TIMES         .EQU    H'000FFD3B         ;;TP02  1 BYTE
AD_OFFSET_TIMES         .EQU    H'000FFD3C         ;;TP02  1 BYTE
COM_TIME_OUT            .EQU    H'000FFD3D         ;;VF.4

ST_POINT                .EQU    H'000FFEFE