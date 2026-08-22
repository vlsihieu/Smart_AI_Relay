;	    ****************************************************
;      ***********    TAIAN TP02 PLC SOFTWARE PROGRAM	 ***********
;   *************	    MAIN ROUTINE MODULE Ver:0.1   *************
;***************	  TAIAN ELECTRIC CO., LTD.	   ***************
;   *************	    Written by Michael Wei	  *************
;      ***********    Start 1995/3/1	End 1995/10/20	 ***********
;	    ****************************************************
	.CPU	  300HA
	.INCLUDE  "H83005.INC"
	.INCLUDE  "SYMBOL02.INC"
	.IMPORT   COMMPP,COMPILER,COMM_STRT
	.IMPORT   DLINK_ST,SLAVE_TTS_TASK,RTC_CMD,RTC_BURST,DATA_ON_INIT
	.IMPORT   SLAVE_PS_TASK,SLAVE_STB_TASK,TX_TO_SLAVE,REFRESH_07340
	.IMPORT   DLINK_OWN_ID,HIGH_SPEED,DELAY_1MS
	.IMPORT   S_RXIN_CHK1,DA_CONV,HEX_BCD_B,DUMP_FLASH_SYS
	.IMPORT   AD_CONV1,AD_CONV2  ;;;V1.61
	.IMPORT   WR_RD_AD_COMD1,WR_RD_AD_COMD,AD_CONV_TIME1,AD_CONV_TIME ;;V1.61
	.IMPORT   SYS_RANGE_CHK,DUMP_FLASH,LOAD_FLASH,LOAD_EEPROM
	.IMPORT   BUFF_PUSH,BUFF_POP,PRG_PTY_CHK,S_TXOUT_SNR
	.IMPORT   DLINK_XHG_DATA,TX_SHOOT,S_RXIN_CHK,S_TXOUT_CHK,SWAP_ACC
	.IMPORT   HSC_INIT,HEX_BCD_W,FLASH_CHECKSUM,EEPROM_CHECKSUM
	.EXPORT   NEXT_IN_NODE,DLINK_ENTER,WAIT_RTM,REMOTE_TMOUT
	.EXPORT   LED_BUF_REFLESH,EXE_OUT_D0,EXE_INP_D0,EXE_OUT_D0_B
	.EXPORT   START_SCAN,COMM_PG,COMM_PG1,EXE_READ_BYTE,COMM_PG_C
	.EXPORT   TIMER_B2,DIAG_WR_LOOP,EXE_WR_DR_00
	.EXPORT   TIME_INT_ST1,TIMER_B22
	.EXPORT   IMIB1_GO3,IMIA2_GO3,IMIB2_GO3,IMIB3_GO3,IMIB4_GO3
	.EXPORT   IMIB1_GO1,IMIA2_GO1,IMIB2_GO1,IMIB3_GO1,IMIB4_GO1
	.EXPORT   IMIB1_GO2,IMIA2_GO2,IMIB2_GO2,IMIB3_GO2,IMIB4_GO2
	.EXPORT   MONTH_WEEK_XCHG,SYS_234_SET,SYS_244_SET
	.EXPORT   EXE_INP_D0_B
	.SECTION  VECT,CODE,LOCATE=H'000000
	.ORG	  H'000000
RES	       JMP	 @INIT_PC
	       .ORG	 H'00001C
NMI	       JMP	 @NMI_INT
	       .ORG	 H'000050
WOVI	       JMP	 @WOVI_INT
	       .ORG	 H'000054
CMI	       JMP	 @REFRESH_TIMER
	       .ORG	 H'000060
IMIA0	       JMP	 @TIMER_BASE
	       .ORG	 H'000074
IMIB1	       JMP	 @IMIB1_INT
	       .ORG	 H'000080
IMIA2	       JMP	 @IMIA2_INT
IMIB2	       JMP	 @IMIB2_INT
OVIE2	       JMP	 @OVIE2_INT
	       .ORG	 H'000094
IMIB3	       JMP	 @IMIB3_INT
	       .ORG	 H'0000A4
IMIB4	       JMP	 @IMIB4_INT
	       .ORG	 H'0000D0
ERI0	       JMP	 @SERIAL_ERI0
RXI0	       JMP	 @SERIAL_RXI0
TXI0	       JMP	 @SERIAL_TXI0
TEI0	       JMP	 @SERIAL_TEI0
ERI1	       JMP	 @SERIAL_ERI1
RXI1	       JMP	 @SERIAL_RXI1
TXI1	       JMP	 @SERIAL_TXI1
TEI1	       JMP	 @SERIAL_TEI1
; *---------------------------------------------*;
; |	 Power down interrupt			|;
; *---------------------------------------------*;
NMI_INT:       PUSH.W	 ACC_W			 ;
	       PUSH.L	 DPTR			 ;
	       MOV.B	 @H'000A0000,ACC         ; Reset 74LS123
	       MOV.B	 #D'5,ACC                ; De-bounce 20 us
HP_TEST_20US:  BLD	 POW_DOWN		 ; 2 states = 125 nS
	       BCS	 HP_OK:8		 ; 6 states = 375 nS
	       DEC.B	 ACC			 ; 2 states = 125 nS
	       BNE	 HP_TEST_20US:8 	 ; 6 states = 375 nS
DE_BOUNCE_PD:  BLD	 POW_DOWN		 ; ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
	       BCS	 HP_OK:8		 ;	     1000 nS
	       MOV.B	 #H'FB,ACC               ; Turn off led driver
	       MOV.B	 ACC,@H'000C0000         ;
	       MOV.B	 #H'A5,ACC               ; Real power shut down !
	       MOV.B	 ACC,@PDTST_ADDR	 ;
	       MOV.W	 #H'0000,ACC_W           ; Debounce 6.0 mS  1570
HP_TEST_2ND:   BLD	 POW_DOWN		 ;	   12.0 ms  3140
	       BCS	 HP_OK:8		 ;
	       DEC.W	 #1,ACC_W		 ;
	       BNE	 HP_TEST_2ND:8		 ;
	       BSET	 RUN_LED		 ; Clear RUN_LED
	       BCLR	 EN_IO			 ;
;;;;;;	       SLEEP				 ;V0.F5
;;;;;;	       RTE				 ;V0.E2
HP_OK:	       MOV.W	 #D'50,ACC_W             ;V0.D  200uS for return on
HP_OK1:        BLD	 POW_DOWN		 ;V0.D	confirm
	       BCC	 DE_BOUNCE_PD:8 	 ;V0.D
	       DEC.W	 #1,ACC_W		 ;V0.D
	       BNE	 HP_OK1:8		 ;V0.D
	       POP.L	 DPTR			 ;
	       POP.W	 ACC_W			 ;
	       RTE				 ;
NMI_INT_SOFT:  BLD	 POW_DOWN		 ; Software detect Power down
	       BCS	 INIT_PC:8		 ; loop
	       MOV.B	 @H'000A0000,ACC         ;
	       BCLR	 EN_IO			 ;
	       BSET	 RUN_LED		 ;
	       BRA	 NMI_INT_SOFT:8 	 ;
; *=============================================*;
; ||		 MAIN PROGRAM START	       ||;
; *=============================================*;
	       .ORG	 H'162                   ;
INIT_PC:       MOV.L	 #H'000FFEFE,SP          ; Set stack point
	       ORC	 #B'10000000,CCR         ;;VF.3
	       MOV.B	 #H'FB,ACC               ;;;;TEST
	       MOV.B	 ACC,@H'000C0000         ;
; *----------------------------------------------*
; | Check LPOK for 30 ms and set system parameter|
; *----------------------------------------------*
LD_CHK_CNT:    MOV.B	 #H'3F,REG_R1          ; Low power detect for 30ms
CHK_PWR1:      MOV.B	 #H'1F,REG_R2            ;
CHK_PWR2:      BLD	 POW_DOWN		 ;
	       BCC	 NMI_INT_SOFT:8 	 ;
	       DEC.B	 REG_R2 		 ;
	       BNE	 CHK_PWR2:8		 ;
	       MOV.B	 @H'000A0000,ACC         ; Reset WDT
	       DEC.B	 REG_R1 		 ;
	       BNE	 CHK_PWR1:8		 ;
	       BCLR	 DLINK_FG		 ;;V0.3
; ========  System initial     ===========	 ;
SYS_INITI:  ;; BSR	 INI_SYS_PARA		 ; Initial system parameter
	       BSET	 RUN_LED		 ; Turn off RUN & ERROR LED
	       BSET	 ERROR_LED		 ;
	       BCLR	 RUN_OUT		 ;
	       BCLR	 F0_BIT 		 ;;V0.D
; ======== Clear system diagnostic error ======= ;
	       MOV.B	 #H'00,ACC               ;
	       MOV.B	 ACC,@FAULT_STATUS	 ;
	       MOV.B	 ACC,@SYS_CNTRL_FG	 ;
	       MOV.B	 ACC,@SERI_STATUS	 ;;VF.1
;== Initial status flag/0.1/0.4/0.8/1 SEC CLOCK =;
	       MOV.B	 ACC,@SC041_ADDR	 ;
	       MOV.L	 #SC049_ADDR,DPTR	 ;
	       BCLR	 #0,@DPTR		 ;
	       BSET	 X005_LAST_STATUS	 ;;
	       BSET	 X006_LAST_STATUS	 ;;
	       MOV.L	 #STOP_INP_BUFF,DPTR	 ;;
	       BSET	 #4,@DPTR		 ;;
	       MOV.L	 #SC017_ADDR,DPTR	 ;;V1.5
	       BCLR	 #5,@DPTR		 ;;
; ========  Label interrupt flag clear	=======  ;
	       MOV.B	 ACC,@LABEL_INT_BUSY	 ;
	;;;;;  MOV.B	 ACC,@HIGH_SPEED_S	 ;
	       MOV.B	 ACC,@HSC_FLAG1 	 ;
	       MOV.B	 ACC,@HSC_FLAG2 	 ;
	       MOV.B	 ACC,@LABEL_CNTRL	 ;
	       BCLR	 F58_RXD_EN		 ;
	       BCLR	 F59_TXD_EN		 ;
	       BCLR	 TD_MOD 		 ;V0.7
	       MOV.B	 #H'99,ACC               ;
	       MOV.B	 ACC,@INT_KIND		 ;
	       BSR	 INI_SYS_PARA		 ;;
; ===== Reset AD/DA buffer bus	 =====		 ;
;	       BSR	 POW_UP_DA_CLR		 ; When power ON then D/A clear
CLR_IO_OUT:    BSR	 EXE_WR_DR_00		 ;
; *----------------------------------------------*
; |   Test Power down				 |
; *----------------------------------------------*
TST_POW_DOWN:  MOV.B	 @PDTST_ADDR,ACC	 ; Test power down register data
	       CMP.B	 #H'A5,ACC               ; saving completely
	       BNE	 WDT_ERROR:8		 ;
PDOWN_ERR:     BLD	 WDT_ERR		 ; Ver0.2
	       BCS	 WDT_ERROR_1:8		 ; Ver0.2
	       MOV.L	 #SC081_ADDR,DPTR	 ;
	       BSET	 #1,@DPTR		 ;SC018 ON
	       MOV.W	 #D'12,ACC_W             ;
	       BSR	 DIAG_WR_LOOP		 ;
	       BRA	 CLR_PW_FLAG:8		 ;
WDT_ERROR:     BLD	 USER_WDT_ERR		 ;
	       BCC	 SYS_WDT_ERR:8		 ;
WDT_ERROR_1:   BSET	 WDT_ERR		 ;
	       BSET	 FAULT_FLAG		 ;
	       BRA	 CLR_PW_FLAG:8		 ;
SYS_WDT_ERR:   BLD	 USER_WDT_ERR1		 ;;V0.F6
	       BCS	 WDT_ERROR_1:8		 ;;
	       MOV.L	 #SC081_ADDR,DPTR	 ;
	       BSET	 #0,@DPTR		 ;SC017 ON
	       BCLR	 WDT_ERR		 ;
	       MOV.W	 #D'11,ACC_W             ;
	       BSR	 DIAG_WR_LOOP		 ;
CLR_PW_FLAG:   MOV.B	 #H'00,ACC               ; Clear power down register
	       MOV.B	 ACC,@PDTST_ADDR	 ;
; *----------------------------------------------*
; |   PASSWORD initial				 |
; *----------------------------------------------*
INIT_PASSW:					 ;
; ******* Start power-on system diagnostic ******; Loop start from this point:
	       BSR	 INI_SYS_SCAN		 ; 1).After stop to run
						 ; 2).Error mode routine start
; *----------------------------------------------*
; |   *** Error mode routine start point ***	 |
; |   Memory data move & diagnostic		 |
; |   1.System EPROM checksum ok ?		 |
; |   2.Check EEPROM exist ?			 |
; |   3.EEPROM checksum ok ?			 |
; |   4.Data transfer(depend on #255 setting)	 |
; |   5.User's program parity check ok ?         |
; |   6.System memory setting check ok ?	 |
; *----------------------------------------------*
SYS_EPROM_CHK: MOV.B	 ACC,@H'000A0000         ; Reset WDT
E_CHK_GO:      MOV.L	 #EPROM_ADDR,DPTR	 ; 1.System EPROM checksum ok ?
	       MOV.B	 #H'00,B_REG             ;
	       MOV.W	 #H'0000,E1              ; 27C512(64K bytes)
E_CHK_LOOP:    MOV.B	 @DPTR,ACC		 ;
	       ADD.B	 ACC,B_REG		 ;
	       INC.L	 #1,DPTR		 ;
	       DEC.W	 #1,E1			 ;
	       BNE	 E_CHK_LOOP:8		 ;
	       CMP.B	 #H'FF,B_REG             ;
		 BEQ	   E_CHK_OK:8		   ;<<<<------------
	   ;;;	   BRA	     E_CHK_OK:8 	     ;<<<<------------
	   ;;; BSET	 E_CHKSUM_ERR		 ;  TEST
	   ;;; BSET	 FAULT_FLAG		 ;  TEST
	   ;;; BRA	 DIAG_SYSTEM		 ;  TEST
E_CHK_OK:      BCLR	 E_CHKSUM_ERR		 ;
; POWER ON :
;1.CHECK ROM PACK EXIST? Y->ID CODE & CHECKSUM OK ? Y->ROM->RAM->FLASH
;2.CHECK FLASH DATA    ?    ID CODE & CHECKSUM OK ? Y->FLASH->RAM
EEPROM_EXIST:  MOV.B	 @LED_DRIVER,ACC	 ;;;V1.1
	       BLD	 EEPROM_BIT		 ;;
	       BST	 #0,ACC 		 ;;
	       MOV.B	 ACC,@LED_DRIVER	 ;;
	       MOV.B	 ACC,@H'000C0000         ;;
	    ;  MOV.B	 #B'11110011,ACC         ;;
	    ;  MOV.B	 ACC,@WCR		 ;;
	       MOV.B	 @EE_EXIST_ADDR,ACC	 ;
	       MOV.B	 ACC,@H'000A0000         ;;;V1.2
	       CMP.B	 #H'37,ACC               ;
	       BNE	 EE_CHK_OK:8		 ;No user ROM pack exist
	       MOV.B	 #0,ACC 		 ;;;V1.2
	       MOV.B	 @EE_EXIST_ADDR+1,ACC	 ;
	       MOV.B	 ACC,B_REG		 ;;;
	       CMP.B	 #H'C8,ACC               ;
	       BNE	 EE_CHK_OK:8		 ;
USER_ROM_CHK:  JSR	 @EEPROM_CHECKSUM	 ;
	       BLD	 JUDGE_NG		 ;
	       BCS	 EE_CHK_ERR:8		 ;
	       BCLR	 EE_CHKSUM_ERR		 ;
	       JSR	 @LOAD_EEPROM		 ;
	       JSR	 @DUMP_FLASH		 ;
	       BSET	 RUN_FLAG		 ;;V1.1
	       BCLR	 RUN_FLAG_1		 ;;
	       BRA	 DIAG_SYSTEM		 ;
EE_CHK_ERR:    BSET	 EE_CHKSUM_ERR		 ;
	       BSET	 FAULT_FLAG		 ;
	       BRA	 DIAG_SYSTEM		 ;V0.F9
EE_CHK_OK:     BCLR	 EE_CHKSUM_ERR		 ;
	    ;  MOV.B	 #B'11110000,ACC         ;;V1.1
	    ;  MOV.B	 ACC,@WCR		 ;;
FLASH_CHECK:   MOV.W	 @EE_WS008_ADDR,ACC_W	 ;;VF.0
	       CMP.W	 #H'0005,ACC_W           ;;VF.3 4->5
	       BCS	 FLASH_CHK0		 ;;
FLASH_CHECK0:  BCLR	 RUN_FLAG		 ;;
	       BSET	 STOP_REFRESH		 ;;
	       BRA	 FLASH_CHK_OK		 ;;
FLASH_CHK0:    CMP.W	 #H'0000,ACC_W           ;;
	       BEQ	 FLASH_CHECK0:8 	 ;;
	       CMP.W	 #H'0001,ACC_W           ;;
	       BEQ	 FLASH_CHK_OK		 ;;
	       BSET	 RUN_FLAG		 ;;
	       BCLR	 RUN_FLAG_1		 ;;
	       CMP.W	 #H'0002,ACC_W           ;;
	       BEQ	 FLASH_CHK1:8		 ;;
	       MOV.W	 #H'0002,ACC_W           ;;
	       MOV.W	 ACC_W,@WS008_ADDR	 ;;
	       MOV.W	 #H'0000,ACC_W           ;;;V1.2
	       MOV.W	 ACC_W,@WS039_ADDR	 ;;;
	       MOV.W	 ACC_W,@WS040_ADDR	 ;;;
	       JSR	 @DUMP_FLASH		 ;;
	       BRA	 FLASH_CHK_OK		 ;;
FLASH_CHK1:    MOV.B	 @FLASH_CHECK_ADDR,ACC	 ;
	       CMP.B	 #H'37,ACC               ;
	       BNE	 FLASH_CHK_OK:8 	 ;No user ROM pack exist
	       MOV.B	 @FLASH_CHECK_ADDR+1,ACC ;
	       CMP.B	 #H'C8,ACC               ;
	       BNE	 FLASH_CHK_OK:8 	 ;
FLASH_CHK:     JSR	 @FLASH_CHECKSUM	 ;
	       BLD	 JUDGE_NG		 ;
	       BCS	 FLASH_CHK_ERR:8	 ;
	       BCLR	 EE_CHKSUM_ERR		 ;
	       JSR	 @LOAD_FLASH		 ;
	       BLD	 BATEN			 ;;;V1.2
	       BCS	 FLASH_CHK_OK:8 	 ;;;
	       BLD	 WDT_ERR		 ;;;
	       BCC	 FLASH_CHK_OK:8 	 ;;;
	       BCLR	 WDT_ERR		 ;;;
	       BCLR	 FAULT_FLAG		 ;;;
	       BRA	 FLASH_CHK_OK:8 	 ;
FLASH_CHK_ERR: BSET	 EE_CHKSUM_ERR		 ;
	       BSET	 FAULT_FLAG		 ;
	       BRA	 DIAG_SYSTEM:8		 ;V0.F9
FLASH_CHK_OK:  BCLR	 EE_CHKSUM_ERR		 ;

;;						 ;;V0.E4
DIAG_SYSTEM:					 ;
PARITY_CHK:    BLD	 FAULT_FLAG		 ;
	       BCC	 PARITY_CHK_GO:8	 ;
	       BLD	 PTY_CHK_ERR		 ;
	       BCC	 SYS_MEM_CHK:8		 ;
PARITY_CHK_GO: JSR	 @PRG_PTY_CHK		 ;5.User's program parity check                                                 ;
	       BLD	 PTY_CHK_ERR		 ;
	       BCC	 SYS_MEM_CHK:8		 ;
PTY_CHK_NG:    BSET	 FAULT_FLAG		 ;
SYS_MEM_CHK:   BLD	 FAULT_FLAG		 ;
	       BCC	 SYS_S_OK:8		 ;
	       BLD	 SYS_SET_ERR		 ;
	       BCC	 TEST_IO:8		 ;
SYS_S_OK:      BCLR	 SYS_SET_ERR		 ;
	       JSR	 @SYS_RANGE_CHK 	 ;
; *----------------------------------------------*
; |   I/O diagnostic & Caluate I/O number	 |
; |   1.I/O data and control data bus check	 |
; *----------------------------------------------*
TEST_IO:       BLD     FAULT_FLAG		 ;
	       BCC     TEST_IO_GO:8		 ;
	       BLD     IO_BUS_ERR		 ;
	       BCC     END_SYS_DIAG:8		 ;
TEST_IO_GO:    BSR     CAL_IO_NO		 ;
; *----------------------------------------------*
; |	End of power-on system diagnostic	 |
; |	& reset some system parameter		 |
; *----------------------------------------------*
END_SYS_DIAG:  BLD     FAULT_FLAG		 ;
	       BCS     TEST_RTC:8		 ;STOP->RUN
	       BSR     POW_DOWN_RETAIN		 ;V001-V256,V257-V1024/D001-D2048
; *----------------------------------------------*
; |	Test real time clock is existed 	 |
; |	  for DALLAS DS-1302 RTC		 |
; *----------------------------------------------*
TEST_RTC:      .EQU	 $			 ;
INITI_RTC:     MOV.B	 #B'10010000,ACC         ; Turn off Trickle chager
	       MOV.B	 #B'00000000,B_REG       ;
	       JSR	 @RTC_CMD		 ;
RTC_TASK_END:  MOV.B	 #B'10001110,ACC         ; RTC write no protect
	       MOV.B	 #B'00000000,B_REG       ;
	       JSR	 @RTC_CMD		 ;
RTC_FIRST_ALL: MOV.B	 #B'10111111,ACC         ; Update RTC
	       JSR	 @RTC_BURST		 ;
	       BSR	 MONTH_WEEK_XCHG	 ;
	       MOV.B	 @SECOND_ADDR,ACC	 ; Reset the stop bit
	       BCLR	 #7,ACC 		 ;
	       MOV.B	 ACC,@SECOND_ADDR	 ;
;****** End of power-on system diagnostic *******;
; *----------------------------------------------*
; |	Check run/stop mode (Normal routine strt)|
; |	Start to excute system software 	 |
; *----------------------------------------------*
CHK_RUN_FLAG:  BLD	 RUN_FLAG		 ;
	       BCC	 STOP_LP_STRT:8 	 ;
	       BLD	 RUN_FLAG_1		 ;
	       BCC	 RUN_LOOP_STRT:8	 ;
STOP_LP_STRT:  BSET	 RUN_FLAG_1		 ;
	       BCLR	 RUN_FLAG		 ;
	       BRA	 CH_COMMPP		 ;
RUN_LOOP_STRT: .EQU	 $			 ;
; *----------------------------------------------* error then jump to commpp
; |   Convert user's program                     |
; *----------------------------------------------*
EXEC_CONVERT:  BLD	 FAULT_FLAG		 ;
	       BCS	 INI_SCAN_TIME		 ;;VF.2 If existed any error,
	 ;;;;; BCC	 EXEC_GO:8		 ;	then don't compile
	 ;;;;; BLD	 LOGIC_ERR		 ;
	 ;;;;; BCC	 INI_SCAN_TIME:8	 ;
EXEC_GO:       BCLR	 LOGIC_DETECT		 ;
	       BCLR	 CHG_MODE		 ;;VF.0
	       MOV.B	 ACC,@H'000A0000         ;RESET WDT
	       BSET	 USER_WDT_ERR		 ;;VF.2
	       JSR	 @COMPILER		 ;
	       BLD	 LOGIC_ERR_BIT		 ;
	       BCS	 PROG_ERR:8		 ;
	       BCLR	 LOGIC_ERR		 ;
	       BRA	 INI_SCAN_TIME:8	 ;
PROG_ERR:      BSET	 FAULT_FLAG		 ;
	       BSET	 LOGIC_ERR		 ;
;************  INITIAL SCAN TIMER  ***************
INI_SCAN_TIME: BLD	 FAULT_FLAG		 ;
	       BCS	 START_SCAN		 ;
	       BSR	 INI_SYS_SCAN		 ;
	       BRA	 START_SCAN		 ;
INI_SYS_SCAN:  MOV.W	 @SCAN_TIME_BASE,ACC_W	 ;
	       MOV.W	 ACC_W,@SCAN_25_TIMES	 ;
	       MOV.W	 #H'FFFF,ACC_W           ;
	       MOV.W	 ACC_W,@WS002_ADDR	 ;
	       MOV.W	 #H'0000,ACC_W           ;
	       MOV.W	 ACC_W,@WS003_ADDR	 ;
	       RTS				 ;
	       .ORG	 H'470                   ;
	       NOP				 ;
; *----------------------------------------------*
; |   BATTERY diagnostic in scan mode		 |
; |   Process I/O and special I/O routine	 |
; *----------------------------------------------*
	       .ORG	 H'472                   ;
; ---------  Normally off 07366 relay	-------- ;
START_SCAN:    MOV.L   #H'000FFEFE,SP            ;
	   ;;; BCLR    USER_WDT_ERR		 ;;VF.3 CHANGE TO F00_END
	       MOV.L   #SC041_ADDR,DPTR 	 ;
	       BCLR    #4,@DPTR 		 ;SC044 OFF FOREVER
	       BLD     OP05_MODE		 ;;VF.6
	       BCC     DA_RAM_CHK:8		 ;;
	       MOV.B   #0,ACC			 ;;
	       MOV.B   ACC,@X0361_ADDR		 ;;
	       MOV.B   ACC,@X0369_ADDR		 ;;
	       MOV.B   ACC,@X0377_ADDR		 ;;
; *----------------------------------------------*
; |  Memory check for data memory fixed one byte |
; |  RAM check(R/W) 1 Byte/1 scan time		 |
; *----------------------------------------------*
DA_RAM_CHK:	MOV.W	#H'55AA,ACC_W             ;
		MOV.W	ACC_W,@DATA_CHK_BUFF	  ;
		MOV.W	@DATA_CHK_BUFF,ACC_W	  ;
		CMP.W	#H'55AA,ACC_W             ;
		BNE	RAM_CHK_ERR:8		  ;
		MOV.W	#H'AA55,ACC_W             ;
		MOV.W	ACC_W,@DATA_CHK_BUFF	  ;
		MOV.W	@DATA_CHK_BUFF,ACC_W	  ;
		CMP.W	#H'AA55,ACC_W             ;
		BEQ	RAM_CHK_OK:8		  ;
RAM_CHK_ERR:	BSET	DATA_RAM_ERR		  ;
		BSET	FAULT_FLAG		  ;
		BRA	HIGH_SP_G:8		  ;
RAM_CHK_OK:	BCLR	DATA_RAM_ERR		  ;
; If remote mode & slave station , by pass after ;
HIGH_SP_G:	 BLD	 EN_422_LINK		 ;If remote link mode
		 BCC	 HIGH_SP_UP:8		 ;in slave station
		 BLD	 REMOTE_MODE		 ;then bypass HIGH_SPEED
		 BCC	 HIGH_SP_UP:8		 ;	      RTC
		 BLD	 MASTER_MODE		 ;to SCAN_TIME
		 BCS	 HIGH_SP_UP:8		 ;
		 MOV.L	 #SC081_ADDR,DPTR	 ;
		 BCLR	 #1,@DPTR		 ;
		 BRA	 IO_LOOP		 ;Modify in Ver0.2
; *----------------------------------------------*
; |	High speed counter data update		 |
; *----------------------------------------------*
HIGH_SP_UP:	 BLD	 RUN_FLAG		 ;
		 BCC	 HIGH_SP_END:8		 ;
	      ;  BLD	 HSC_MODE		 ; TEST
	      ;  BCC	 IO_LOOP:8		 ;
		 JSR	 @HIGH_SPEED		 ;
		 BRA	 IO_LOOP:8		 ;
HIGH_SP_END:	 BCLR	 #1,@TSTR		 ;
		 BCLR	 #2,@TSTR		 ;
		 BCLR	 #3,@TSTR		 ;
		 BCLR	 #4,@TSTR		 ;
; *----------------------------------------------*
; | I/O Process routine ; IO_IN:4021/IO_OUT:4094 |
; *----------------------------------------------*
IO_LOOP:       BLD	 REMOTE_MODE		 ;;V0.F1
	       BCC	 IO_OUT:8		 ;;V0.F1
	       BLD	 MASTER_MODE		 ;;V0.F1
	       BCC	 CH_COMMPP		 ;;V0.F3
;Computer link, and data link mode I/O start	 ;
IO_OUT:        BLD	 FAULT_FLAG		 ;
	       BCC	 IO_OUT_GO:8		 ;
	       BLD	 IO_BUS_ERR		 ;
	       BCC	 IO_OUT_GO_1		 ;
IO_OUT_GO:     BSR	 AUTO_EXE_IO		 ;
	       BLD	 PULSE_EN		 ;
	       BCC	 IO_AD_JUDGE1:8 	  ;V1.61
	       MOV.L	 #SC017_ADDR,DPTR	 ;
	       BLD	 #0,@DPTR		 ;SC017 = ON, all output off
	       BCC	 IO_ON:8		 ;
	       BCLR	 EN_IO			 ;
	       BRA	 IO_AD_JUDGE1:8 	  ; V1.61
;
;;*****************	A/D    ***********************
IO_ON:	       BSET	 EN_IO			 ; V1.61 start
IO_AD_JUDGE1:	MOV.W	  @WS061_ADDR,ACC_W	 ;;V2.0
	       CMP.W	 #H'01,ACC_W             ;;
	       BNE	 IO_AD_11:8		 ;;
	       BCLR	 SYS_210_ON		 ;;
	       BCLR	 SYS_210_2047		 ;;
	       BRA	 IO_AD_GO1:8		 ;;
IO_AD_11:	CMP.W	  #H'02,ACC_W            ;;
	       BNE	 IO_AD_21:8		 ;;
	       BCLR	 SYS_210_ON		 ;;
	       BSET	 SYS_210_2047		 ;;
	       BRA	 IO_AD_GO1:8		 ;;
IO_AD_21:	CMP.W	  #H'03,ACC_W            ;;
	       BNE	 IO_AD_JUDGE2:8 	 ;;
	       BSET	 SYS_210_ON		 ;;
IO_AD_GO1:	JSR	  @AD_CONV1		 ;;
;
IO_AD_JUDGE2:	MOV.W	  @WS064_ADDR,ACC_W	  ;;V2.0
	       CMP.W	 #H'01,ACC_W             ;;
	       BNE	 IO_AD_12:8		 ;;
	       BCLR	 SYS_210_ON		 ;;
	       BCLR	 SYS_210_2047		 ;;
	       BRA	 IO_AD_GO2:8		 ;;
IO_AD_12:	CMP.W	  #H'02,ACC_W            ;;
	       BNE	 IO_AD_22:8		 ;;
	       BCLR	 SYS_210_ON		 ;;
	       BSET	 SYS_210_2047		 ;;
	       BRA	 IO_AD_GO2:8		 ;;
IO_AD_22:	CMP.W	  #H'03,ACC_W            ;;
	       BNE	 IO_DA_JUDGE:8		 ;;
	       BSET	 SYS_210_ON		 ;;
IO_AD_GO2:	JSR	  @AD_CONV2		 ;; V1.61   end
;
IO_DA_JUDGE:   MOV.W	 @WS062_ADDR,ACC_W	 ;;V2.0
	       CMP.W	 #H'01,ACC_W             ;;
	       BNE	 IO_DA_1:8		 ;;
	       BCLR	 SYS_212_ON		 ;;
	       BCLR	 SYS_212_2047		 ;;
	       BRA	 IO_DA_GO:8		 ;;
IO_DA_1:       CMP.W	 #H'02,ACC_W             ;;
	       BNE	 IO_DA_2:8		 ;;
	       BCLR	 SYS_212_ON		 ;;
	       BSET	 SYS_212_2047		 ;;
	       BRA	 IO_DA_GO:8		 ;;
IO_DA_2:       CMP.W	 #H'03,ACC_W             ;;
	       BNE	 IO_OUT_GO_1:8		 ;;
	       BSET	 SYS_212_ON		 ;;
IO_DA_GO:      JSR	 @DA_CONV		 ;;
IO_OUT_GO_1:   BLD	 REMOTE_MODE		 ;;V0.F1
	       BCC	 DATA_LINK_CHK:8	 ;;V0.F1
	       BRA	 REMOTE_LINK_S		 ;;V0.F1
;*****************************************************************************
;==Data link master start loop==		 ;			     *
DATA_LINK_CHK: BLD	 FAULT_FLAG		 ;			     *
	       BCS	 RESET_1ST_PASS 	 ;			     *
	       BLD	 EN_422_LINK		 ;			     *
	       BCC	 RESET_1ST_PASS 	 ;Not data link 	     *
	       BLD	 MASTER_MODE		 ;			     *
	       BCC	 DLINK_SLAVE		 ;jump to slave mode	     *
	       MOV.B	 @WS046_ADDR+1,B_REG	 ;			     *
	       CMP.B	 #H'00,B_REG             ;                           *
	       BEQ	 RESET_1ST_PASS 	 ;No slave station setting   *
	       MOV.B	 @SLAVE_RING,ACC	 ;			     *
	       CMP.B	 #H'00,ACC               ;first time start to txout  *
	       BEQ	 DATA_XHG_STRT:8	 ;			     *
	       INC.B	 B_REG			 ;			     *
	       CMP.B	 B_REG,ACC		 ;			     *
	       BNE	 M_JUDGE_TMOUT:8	 ;			     *
DATA_XHG_STRT: JSR	 @DLINK_XHG_DATA	 ;			     *
	       JSR	 @TX_SHOOT		 ;			     *
	       BRA	 RESET_1ST_PASS 	 ;			     *
M_JUDGE_TMOUT: MOV.B	 @TIME_BASE1,ACC	 ;			     *
	       MOV.B	 @DLINK_TIMEOUT,B_REG	 ;			     *
	       SUB.B	 B_REG,ACC		 ;			     *
	       CMP.B	 #D'01,ACC               ;10 mS as time out,(master  *
	       BHI	 M_DLINK_TOUT:8 	 ;side) 		     *
	       BRA	 RESET_1ST_PASS 	 ;			     *
M_DLINK_TOUT:  MOV.B	 @SLAVE_RING,ACC	 ;			     *
	       MOV.L	 #SC105_ADDR,DPTR	 ;			     *
	       BCLR	 ACC,@DPTR		 ;			     *
	       BCLR	 ACC,@DATA_W_FLAG	 ;clear work flag	     *
	       BCLR	 #0,@DPTR		 ;clear 07340		     *
	       INC.B	 ACC			 ;			     *
	       MOV.B	 ACC,@SLAVE_RING	 ;			     *
	       MOV.B	 @WS046_ADDR+1,B_REG	 ;			     *
	       CMP.B	 B_REG,ACC		 ;			     *
	       BHI	 DATA_XHG_STRT:8	 ;all slave refresh finish   *
	       JSR	 @TX_SHOOT		 ;issue next slave station   *
	       BRA	 RESET_1ST_PASS 	 ;			     *
;==Data link slave start loop== 		 ;			     *
DLINK_SLAVE:   BSET	 EXCHANGE_ON		 ;			     *
S_JUDGE_TMOUT: BLD	 SLAVE_OK_IN		 ;			     *
	       BCS	 S_DATA_IN:8		 ;			     *
	       MOV.B	 @TIME_BASE1,ACC	 ;			     *
	       MOV.B	 @DLINK_TIMEOUT,B_REG	 ;			     *
	       SUB.B	 B_REG,ACC		 ;			     *
	       CMP.B	 #D'100,ACC              ;1S as time out,(slave      *
	       BHI	 S_DLINK_TOUT:8 	 ;side) 		     *
	       BRA	 S_DOUT_CHK:8		 ;			     *
S_DATA_IN:     BCLR	 SLAVE_OK_IN		 ;			     *
	       JSR	 @S_RXIN_CHK		 ;exchange slave station's   *
	       BRA	 S_DOUT_CHK		 ;RX data		     *
S_DLINK_TOUT:  MOV.L	 #SC105_ADDR,DPTR	 ;			     *
	       BCLR	 #0,@DPTR		 ;			     *
S_DOUT_CHK:    BLD	 TX_OUT_ON		 ;			     *
	       BCS	 S_DLINK_END:8		 ;			     *
S_DOUT:        JSR	 @S_TXOUT_CHK		 ;exchange slave station's   *
S_DLINK_END:   BLD	 SLAVE_XHG_S8		 ;V0.E3 		     *
	       BCC	 S_D_E3:8		 ;V0.E3 		     *
	       MOV.W	 #D'1000,DATA1_W         ;                           *
S_D_E1:        BLD	 SLAVE_OK_IN		 ;;V1.2 		     *
	       BCS	 S_D_E2:8		 ;;			     *
	       DEC.W	 #1,DATA1_W		 ;			     *
	       BNE	 S_D_E1:8		 ;			     *
	       BRA	 S_D_E3:8		 ;			     *
S_D_E2:        MOV.L	 #S8_RX_BUFF,DPTR	 ;V0.E3 		     *
	       BCLR	 SLAVE_OK_IN		 ;;V1.2 		     *
	       JSR	 @S_RXIN_CHK1		 ;V0.E3 		     *
	       BCLR	 SLAVE_XHG_S8		 ;V0.E3 		     *
S_D_E3:        BCLR	 EXCHANGE_ON		 ;			     *
	       BLD	 RX_MAIN_TX		 ;TX data		     *
	       BCC	 RESET_1ST_PASS 	 ;			     *
	       JSR	 @TX_SHOOT		 ;interrupt request main to  *
	       BCLR	 RX_MAIN_TX		 ;issue response	     *
;*****************************************************************************
	       BRA	 RESET_1ST_PASS 	 ;
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;  Remote I/O link master start loop		 ;			     ++
REMOTE_LINK_S: BLD	 FAULT_FLAG		 ;If master run into fault   ++
	       BCC	 REMOTE_CHK:8		 ;status ,can't execute link ++
	       BLD	 DLINK_ERR		 ;			     ++
	       BCC	 RESET_1ST_PASS 	 ;			     ++
REMOTE_CHK:    BLD	 MASTER_MODE		 ;			     ++
	       BCC	 CH_COMMPP		 ;Remote slave station bypass++
TEST_S_EXIST:  MOV.B	 @WS046_ADDR+1,ACC	 ;			     ++
	       CMP.B	 #H'00,ACC               ;                           ++
	       BEQ	 RESET_1ST_PASS 	 ;No slave station,no need to++
RSR_BUSY:      BLD	 EN_422 		 ;link			     ++
	       BCS	 RSR_BUSY:8		 ;			     ++
PS_TASK:       JSR	 @SLAVE_PS_TASK 	 ;If no slave station,return ++
	 ;;;;  BSET	 PS	  ;; V0.F1	 ;from subroutine immediately++
	 ;;;;  BCLR	 PS			 ;			     ++
	 ;;;;  BSR	 EXE_INP_D0		 ;			     ++
	       MOV.B	 #H'01,ACC               ;link                       ++
	       MOV.B	 ACC,@SLAVE_RING	 ;Initial slave ID number    ++
NEXT_IN_NODE:  MOV.B	 @WS046_ADDR+1,B_REG	 ;Slave station number	     ++
	       MOV.B	 @SLAVE_RING,ACC	 ;This time's slave ID       ++
	       CMP.B	 B_REG,ACC		 ;			     ++
	       BGT	 SLAVE_STBOUT		 ;All slave transmit ok      ++
MSR_BUSY:      BLD	 EN_422 		 ;			     ++
	       BCS	 MSR_BUSY:8		 ;			     ++
	       JSR	 @SLAVE_TTS_TASK	 ;			     ++
	       MOV.B	 @SCAN_TIME_BASE1,ACC	 ;Reset remote link timeout  ++
	       MOV.B	 ACC,@DLINK_TIMEOUT	 ;			     ++
WAIT_RTM:      BLD	 RXENDF2		 ;			     ++
	       BCC	 CAL_TIMEOUT1:8 	 ;			     ++
	       JMP	 @DLINK_OWN_ID		 ;			     ++
CAL_TIMEOUT1:  MOV.B	 @H'000A0000,ACC         ; Reset WDT                 ++
	       MOV.B	 @SCAN_TIME_BASE1,ACC	 ;			     ++
	       MOV.B	 @DLINK_TIMEOUT,B_REG	 ;			     ++
	       SUB.B	 B_REG,ACC		 ;			     ++
	       CMP.B	 #H'0A,ACC               ;10 mS as timeout reach     ++
	       BCC	 REMOTE_TMOUT1:8	 ;			     ++
	       BRA	 WAIT_RTM:8		 ;			     ++
; Timeout caused master run into error mode	 ;			     ++
REMOTE_TMOUT1: BLD	 STOP_IOLINK		 ;			     ++
	       BCS	 REMOTE_TMOUT:8 	 ;			     ++
	       JSR	 @SLAVE_TTS_TASK	 ;retransmit again	     ++
	       MOV.B	 @SCAN_TIME_BASE1,ACC	 ;reset the timeout timer    ++
	       MOV.B	 ACC,@DLINK_TIMEOUT	 ;			     ++
	       BSET	 STOP_IOLINK		 ;			     ++
	       BRA	 WAIT_RTM		 ;			     ++
REMOTE_TMOUT:  BSET	 FAULT_FLAG		 ;			     ++
	       BSET	 DLINK_ERR		 ;			     ++
	       BCLR	 STOP_IOLINK		 ;reset retransmit flag      ++
	       MOV.L	 #SC105_ADDR,DPTR	 ;			     ++
;;;;	       MOV.B	 #H'00,ACC               ;V0.E3                      ++
	       BCLR	 #0,@DPTR		 ;V0.E3 		     ++
	       MOV.B	 @SLAVE_RING,ACC	 ;V0.E4 		     ++
	       BCLR	 ACC,@DPTR		 ;V0.E4 		     ++
	       BRA	 TST_ONE_PULSE		 ;flag			     ++
SLAVE_STBOUT:  BCLR	 STOP_IOLINK		 ;;;V0.F5 reset timeout flag ++
	       JSR	 @REFRESH_07340 	 ;;;V0.F5		     ++
	       BLD	 FIRST_PASS_FG		 ;No execute in the first tim++
	       BCC	 RESET_1ST_PASS 	 ;STOP -> RUN		     ++
	       MOV.B	 #H'01,ACC               ;                           ++
	       MOV.B	 ACC,@SLAVE_RING	 ;Initial slave ID number    ++
;;STB_TASK:	 BLD	   FIRST_PASS_FG	 ;;;V0.F5 CANCEL !	     ++
;;		 BCC	   RESET_1ST_PASS	 ;;;V0.F5		     ++
STB_BUSY:      BLD	 EN_422 		 ;			     ++
	       BCS	 STB_BUSY:8		 ;			     ++
	       JSR	 @SLAVE_STB_TASK	 ;If no slave station,return ++
	;;;;   BSR	 EXE_OUT_D0 ;;V0.F1	 ;from subroutine immediately++
	;;;;   BSET	 STB_B			 ;			     ++
	;;;;   MOV.B	 @STB_A,ACC		 ;			     ++
	;;;;   BCLR	 STB_B			 ;			     ++
	       BCLR	 DLINK_ERR		 ;V0.4			     ++
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
RESET_1ST_PASS: 				 ;
TST_ONE_PULSE: BLD	 FIRST_PASS_FG		 ;
	       BCC	 CLR_FIRST_PULSE:8	 ;
	       MOV.L	 #SC057_ADDR,DPTR	 ;
	       BCLR	 #1,@DPTR		 ;
	       BLD	 PULSE_EN		 ;First scan no execution
	       BCS	 CH_COMMPP:8		 ;
	       BLD	 FAULT_FLAG		 ;
	       BCS	 LL:8			 ;
L:	       BSET	 EN_IO			 ; (to make sure output
LL:	       MOV.B	 @SC081_ADDR,ACC	 ;  start in second scan)
	       AND.B	 #B'00100000,ACC         ;
	       MOV.B	 ACC,@SC081_ADDR	 ;
	       BSET	 PULSE_EN		 ;
	       BRA	 CH_COMMPP:8		 ;
CLR_FIRST_PULSE:				 ;only first scan execution
	       MOV.L	 #SC057_ADDR,DPTR	 ;
	       BSET	 #1,@DPTR		 ;
	       BSET	 FIRST_PASS_FG		 ;
; *---------------------------------------------------------*
; |	STOP mode re_enter point			    |
; |	Check communication function			    |
; |	1.RS422 port0 : PG communication		    |
; |	2.RS422 port1 : 1). Computer link(EN_422_LINK=0)    |
; |			2). Data link(EN_422_LINK=1)	    |
; |			3). Remote I/O link(EN_422_LINK=1)  |
; *---------------------------------------------------------*
CH_COMMPP:     BLD     EN_422_LINK		 ;
	       BCC     COMPUTER_LINK:8		 ;
	       BLD     RXENDF3			 ;
	       BCC     DLINK_ENTER:8		 ;
	       JMP     @DLINK_ST		 ; Executing broadcast
DLINK_ENTER:   BLD     RXENDF2			 ;
	       BCC     CHK_DLINK_T:8		 ;
	       JMP     @DLINK_OWN_ID		 ; Executing data link
CHK_DLINK_T:   BLD     REMOTE_MODE		 ;
	       BCS     COMM_PG1 		 ;
; ---------  Computer link only -----------	 ;
COMPUTER_LINK: BLD     RXENDF1			 ; Executing computer link ?
	       BCC     COMM_PG:8		 ;
	       JMP     @COMM_STRT		 ;
COMM_PG:       BLD     TXENDF1			 ;
	       BCC     COMM_PG1:8		 ;
	       MOV.B   @TIME_BASE1,ACC		 ;
	       MOV.B   @RESP_TM_BASE,REG_R1	 ;
	       MOV.B   @RI_ADDR,B_REG		 ;
	       SUB.B   REG_R1,ACC		 ;
	       CMP.B   B_REG,ACC		 ;
	       BCS     COMM_PG1:8		 ;
	       BCLR    TXENDF1			 ;
	       BSET    EN_422			 ; Start to transmit 422 out
	       BCLR    #TDRE,@SSR1		 ; TEST
	       BSET    #TIE,@SCR1		 ;
	       BSET    #TEIE,@SCR1		 ;
; ------  PG link start   -----------		 ;
COMM_PG1:      BLD     EN_422_LINK		 ;Data link & Remote link->
	       BCC     COMM_PG2:8		 ;
	       BLD     REMOTE_MODE		 ;V0.4
	       BCC     COMM_PG2 		 ;V0.4
R_T_OUT:       BLD     MASTER_MODE		 ;Slave mode->execute
	       BCS     COMM_PG2:8		 ;
	       MOV.B   @TIME_BASE1,ACC		 ;
	       MOV.B   @DLINK_TIMEOUT,B_REG	 ;
	       SUB.B   B_REG,ACC		 ;
	       CMP.B   #D'100,ACC                ;1000 ms (V0.E)
	       BCC     DLINK_TOUT2:8		 ;
	       BRA     COMM_PG2:8		 ;
DLINK_TOUT2:   MOV.B   @TIME_BASE1,ACC		 ;
	       MOV.B   ACC,@DLINK_TIMEOUT	 ;
	       MOV.L   #SC105_ADDR,DPTR 	 ;
	       BCLR    #0,@DPTR 		 ;
	       BLD     REMOTE_MODE		 ;V0.E
	       BCC     COMM_PG2:8		 ;V0.E
	       BSET    FAULT_FLAG		 ;V0.E
	       BSET    DLINK_ERR		 ;V0.E
	       MOV.B   @SYS_234_IO,ACC		 ;;V0.F1
	       CMP.B   #H'02,ACC                 ;;
	       BNE     COMM_PG2:8		 ;;
	       MOV.B   @WS043_ADDR+1,ACC	 ;;V0.F1
	       CMP.B   #H'02,ACC                 ;;
	       BEQ     XHG_234_MODE:8		 ;;
	       MOV.B   @WS045_ADDR+1,ACC	  ;;
	       CMP.B   #H'00,ACC                 ;;
	       BEQ     COMM_PG2:8		 ;;
XHG_237_MODE:  MOV.B   #H'00,ACC                 ;;
	       MOV.B   ACC,@SYS_234_IO		 ;;
	       BCLR    RUN_FLAG 		 ;;
	       BRA     COMM_PG2:8		 ;;V0.F2
XHG_234_MODE:  MOV.B   @WS045_ADDR+1,ACC	 ;;
	       CMP.B   #H'00,ACC                 ;;
	       BEQ     XHG_237_MODE:8		 ;;
COMM_PG2:      BLD     RXENDF0			 ; Executing PG communication ?
	       BCC     COMM_PG_C:8		 ;
	       JMP     @COMMPP			 ;
; ------  PG port computer link  ----------	 ;
COMM_PG_C:     BLD     TXENDF0			 ; Executing PG trannsmit out ?
	       BCC     PGBRT_REFRESH:8		 ;
	       MOV.B   @TIME_BASE1,ACC		 ;
	       MOV.B   @RESP_TM_BASEPG,REG_R1	 ;
	       MOV.B   @PG_RI_ADDR,B_REG	 ;
	       SUB.B   REG_R1,ACC		 ;
	       CMP.B   B_REG,ACC		 ;
	       BCS     PGBRT_REFRESH:8		 ;
	       BCLR    TXENDF0			 ;
	       BCLR    #TDRE,@SSR0		 ;
	       BSET    #TIE,@SCR0		 ;
	       BSET    #TEIE,@SCR0		 ;
PGBRT_REFRESH: BLD     PGBRT			 ;;;V1.4
	       BCC     PGCOM_LINK:8		 ;
	       BLD     PGBRT_STATUS		 ;
	       BCS     LED_BUF_REFLESH:8	 ;
	       BSR     PG_INI			 ;
	       BRA     LED_BUF_REFLESH:8	 ;
PGCOM_LINK:    BLD     PGBRT_STATUS		 ;
	       BCC     LED_BUF_REFLESH:8	 ;
	       BSR     PG_INI			 ;
; *----------------------------------------------*
; |	LED's buffer reflesh loop                |
; *----------------------------------------------*
LED_BUF_REFLESH: BLD	 RUN_FLAG		 ;
		 BCS	 LED_BUF_RUN:8		 ;
LED_BUF_STOP:	 MOV.L	 #STOP_INP_BUFF,DPTR	 ;
		 BRA	 LED_BUF_GO:8		 ;
LED_BUF_RUN:	 MOV.L	 #X_STATE,DPTR		 ;
LED_BUF_GO:	 MOV.B	 @DPTR,ACC		 ;
		 INC.L	 #1,DPTR		 ;
		 NOT.B	 ACC			 ;
		 BLD	 HSC_MODE		 ;;V2.0I If not high speed
		 BCC	 LED_BUFF_REF:8 	 ;;counter mode, use normal
REFLESH_HSC_LED: BILD	 TCLK_A 		 ; input point to refresh LED
		 BST	 #0,ACC 		 ;
		 BILD	 TCLK_B 		 ;
		 BST	 #1,ACC 		 ;
		 BILD	 TCLK_C 		 ;
		 BST	 #2,ACC 		 ;
		 BILD	 TCLK_D 		 ;
		 BST	 #3,ACC 		 ;
LED_BUFF_REF:	 MOV.B	 ACC,@X1_X8_BUFF	 ;
		 MOV.B	 @DPTR,ACC		 ;;V0.6
		 INC.L	 #1,DPTR		 ;;
		 NOT.B	 ACC			 ; 1
		 JSR	 @SWAP_ACC		 ;
		 MOV.B	 ACC,@X9_X12_BUFF	 ;
		 AND.B	 #H'0F,ACC               ;
		 MOV.B	 ACC,B_REG		 ;
		 MOV.B	 @DPTR,ACC		 ;;V0.6
		 INC.L	 #1,DPTR		 ;;
		 NOT.B	 ACC			 ; 2
		 MOV.B	 ACC,@X21_X24_BUFF	 ;
		 JSR	 @SWAP_ACC		 ;
		 AND.B	 #H'F0,ACC               ;
		 OR.B	 B_REG,ACC		 ;
		 MOV.B	 ACC,@X13_X20_BUFF	 ;
		 MOV.B	 @DPTR,ACC		 ;;V0.6
		 INC.L	 #1,DPTR		 ;;
		 NOT.B	 ACC			 ; 3
		 MOV.B	 ACC,@X25_X32_BUFF	 ;
		 MOV.B	 @DPTR,ACC		 ;;V0.6
		 NOT.B	 ACC			 ; 4
		 JSR	 @SWAP_ACC		 ;
		 MOV.B	 ACC,@X33_X36_BUFF	 ;
		 BLD	 RUN_OUT		 ;;V0.6
		 BCC	 WS004_CHK:8		 ;;VF.1
		 MOV.B	 @Y_STATE,ACC		 ;
		 NOT.B	 ACC			 ; 5
		 MOV.B	 ACC,@Y1_Y8_BUFF	 ;
		 MOV.B	 @Y_STATE+1,ACC 	 ;
		 NOT.B	 ACC			 ; 6
		 JSR	 @SWAP_ACC		 ;
		 MOV.B	 ACC,@Y9_Y12_BUFF	 ;
		 AND.B	 #H'0F,ACC               ;
		 MOV.B	 ACC,B_REG		 ;
		 MOV.B	 @Y_STATE+2,ACC 	 ;
		 NOT.B	 ACC			 ; 7
		 MOV.B	 ACC,@Y21_Y24_BUFF	 ;
		 JSR	 @SWAP_ACC		 ;
		 AND.B	 #H'F0,ACC               ;
		 OR.B	 B_REG,ACC		 ;
		 MOV.B	 ACC,@Y13_Y20_BUFF	 ;
WS004_CHK:	 MOV.W	 @WS004_ADDR,ACC_W	 ;;VF.1
		 CMP.W	 #H'0001,ACC_W           ;;
		 BNE	 WS004_CHK1:8		 ;;
		 BSET	 X_NO_REFRESH		 ;;
		 BRA	 BATT_TEST:8		 ;;
WS004_CHK1:	 CMP.W	 #H'0000,ACC_W           ;;V1.1
		 BNE	 X_IN_FILTER:8		 ;;
		 BCLR	 X_FILTER		 ;;
		 BRA	 WS004_CHK2:8		 ;;
X_IN_FILTER:	 BSET	 X_FILTER		 ;;V1.1
WS004_CHK2:	 BCLR	 X_NO_REFRESH		 ;;
; *----------------------------------------------*
; |   Test battery				 |
; *----------------------------------------------*
BATT_TEST:     BLD	 BATEN			 ;
	       BCS	 BATT_OK:8		 ;
BATT_NG:       MOV.L	 #SC081_ADDR,DPTR	 ; Set SC086:Battery error
	       BSET	 #5,@DPTR		 ;
	       BSET	 BATT_ERR		 ;
	       MOV.W	 #D'8,ACC_W              ;
	       BSR	 DIAG_WR_LOOP		 ;
TURN_ERR_LED:  BCLR	 ERROR_LED		 ; Turn on error led
	       BRA	 RTC_UPDATE:8		 ;
BATT_OK:       MOV.L	 #SC081_ADDR,DPTR	 ; Clear SC086(Battery ok)
	       BCLR	 #5,@DPTR		 ;
	       BCLR	 BATT_ERR		 ;
	       BLD	 FAULT_FLAG		 ;
	       BCS	 RTC_UPDATE:8		 ;
	       BSET	 ERROR_LED		 ;
; *----------------------------------------------*
; |	RTC current time update 		 |
; *----------------------------------------------*
RTC_UPDATE:	 MOV.L	 #SC017_ADDR,DPTR	 ;
		 BLD	 #1,@DPTR		 ;SC018
		 BCS	 STOP_RTC		 ;
		 BLD	 RTC_STOP_BIT		 ;
		 BCC	 UPDATE_30SEC:8 	 ;
		 MOV.B	 @SECOND_ADDR,REG_R4	 ;
		 BCLR	 #7,REG_R4		 ;
		 JSR	 @HEX_BCD_B		 ;
		 MOV.B	 REG_R4,B_REG		 ;
		 MOV.B	 #B'10000000,ACC         ;
		 JSR	 @RTC_CMD		 ;
		 BCLR	 RTC_STOP_BIT		 ;
UPDATE_30SEC:	 BLD	 #2,@DPTR		 ; 30 SECOND COMPENSATION
		 BCS	 UPDATE_30SEC1:8	 ;;V1.5
		 BCLR	 PRE_SC019		 ;;
		 BRA	 RTC_WR_ALL:8		 ;;
UPDATE_30SEC1:	 BLD	 PRE_SC019		 ;;V1.5
		 BCS	 RTC_WR_ALL:8		 ;;V1.5
		 BSET	 PRE_SC019		 ;;V1.5
		 MOV.B	 #B'10000001,ACC         ;
		 JSR	 @RTC_CMD		 ;
		 CMP.B	 #D'30,B_REG             ; TEST D'30
		 BCS	 SEC_CLR_0:8		 ;
		 MOV.B	 @HOUR_ADDR,ACC 	 ;
		 MOV.B	 ACC,@DS_HOUR_ADDR	 ;
		 MOV.B	 @MINUTE_ADDR,ACC	 ;
		 MOV.B	 ACC,@DS_MINUTE_ADDR	 ;
		 MOV.B	 @SECOND_ADDR,ACC	 ;
		 MOV.B	 ACC,@DS_SECOND_ADDR	 ;
		 MOV.B	 #B'10000000,ACC         ;
		 MOV.B	 #H'59,B_REG             ;
		 JSR	 @RTC_CMD		 ;
		 BSET	 SECOND_59SET		 ;
		 BRA	 RTC_ALL		 ;
SEC_CLR_0:	 MOV.B	 #B'10000000,ACC         ;
		 MOV.B	 #H'00,B_REG             ;
		 JSR	 @RTC_CMD		 ;
		 BCLR	 SECOND_59SET		 ;
		 BRA	 RTC_READ_ALL:8 	 ;
MONTH_WEEK_XCHG: MOV.B	 @MONTH_ADDR,ACC	 ; Exchange the MONTH & WEEK
		 MOV.B	 @WEEK_ADDR,B_REG	 ; address
		 MOV.B	 B_REG,@MONTH_ADDR	 ;
		 MOV.B	 ACC,@WEEK_ADDR 	 ;
		 RTS
RTC_WR_ALL:	 BLD	 #3,@DPTR		 ;
		 BCC	 RTC_READ_ALL:8 	 ;
		 BLD	 SECOND_59SET		 ;
		 BCS	 RTC_READ_ALL:8 	 ;
		 BCLR	 #3,@DPTR		 ; V0.7
		 BSR	 MONTH_WEEK_XCHG	 ; V0.7
		 MOV.B	 #B'10111110,ACC         ;
		 JSR	 @RTC_BURST		 ;
		 BSR	 MONTH_WEEK_XCHG	 ;;V0.7
		 BRA	 RTC_READ_ALL:8 	 ;
STOP_RTC:	 MOV.B	 #B'10000001,ACC         ; stop bit enable
		 JSR	 @RTC_CMD		 ;
		 MOV.B	 B_REG,REG_R4		 ;
		 JSR	 @HEX_BCD_B		 ;
		 MOV.B	 REG_R4,B_REG		 ;
		 BSET	 #7,B_REG		 ;
		 MOV.B	 #B'10000000,ACC         ;
		 JSR	 @RTC_CMD		 ;
		 BSET	 RTC_STOP_BIT		 ;
		 BRA	 SCAN_TIME		 ;;;;V0.7
RTC_READ_ALL:	 MOV.B	 #B'10000001,ACC         ;
		 JSR	 @RTC_CMD		 ;
		 CMP.B	 #H'00,B_REG             ;
		 BEQ	 RTC_ALL:8		 ;
		 BCLR	 RTC_ONE_BURST		 ;;V1.3
		 BLD	 SECOND_59SET		 ;
		 BCS	 RTC_ALL:8		 ;
		 BCLR	 #7,B_REG		 ;
		 MOV.B	 B_REG,@SECOND_ADDR	 ;
		 BRA	 SCAN_TIME		 ;
RTC_ALL:	 BLD	 RTC_ONE_BURST		 ;;V1.3
		 BCS	 SCAN_TIME		 ;;
		 BCLR	 IO_INT_BIT		 ; Ver0.2
		 MOV.B	 #B'10111111,ACC         ; Update RTC
		 JSR	 @RTC_BURST		 ;
		 BLD	 IO_INT_BIT		 ;
		 BCS	 RTC_ALL:8		 ;
		 BSET	 RTC_ONE_BURST		 ;;V1.3
		 BSR	 MONTH_WEEK_XCHG	 ;;V0.7
		 MOV.B	 @SECOND_ADDR,ACC	 ; Reset the stop bit
		 BCLR	 #7,ACC 		 ;
		 MOV.B	 ACC,@SECOND_ADDR	 ;
		 BLD	 SECOND_59SET		 ;
		 BCC	 SCAN_TIME:8		 ;
		 MOV.B	 @SECOND_ADDR,ACC	 ;
		 CMP.B	 #D'59,ACC               ;
		 BEQ	 SEC_STILL_59:8 	 ;
		 BCLR	 SECOND_59SET		 ;
		 BRA	 SCAN_TIME		 ;
SEC_STILL_59:	 MOV.B	 @DS_SECOND_ADDR,ACC	 ;
		 MOV.B	 ACC,@SECOND_ADDR	 ;
		 MOV.B	 @MINUTE_ADDR,ACC	 ;
		 MOV.B	 @DS_MINUTE_ADDR,REG_R4  ;
		 CMP.B	 REG_R4,ACC		 ;
		 BEQ	 SCAN_TIME:8		 ;
		 MOV.B	 REG_R4,@MINUTE_ADDR	 ;
		 JSR	 @HEX_BCD_B		 ;
		 MOV.B	 REG_R4,B_REG		 ;
		 MOV.B	 #B'10000010,ACC         ;
		 JSR	 @RTC_CMD		 ;
		 MOV.B	 @DS_HOUR_ADDR,B_REG	 ;
		 MOV.B	 B_REG,REG_R4		 ;
		 JSR	 @HEX_BCD_B		 ;
		 MOV.B	 REG_R4,B_REG		 ;
		 MOV.B	 #B'10000100,ACC         ;
		 JSR	 @RTC_CMD		 ;
; * --------------------------------------------*;
; |   Scan time calculate			 |
; |   1.Scan time minimum value #30-#31 	 |
; |   2.Scan time current value #32-#33 	 |
; |   3.Scan time maximum value #34-#35 	 |
; *----------------------------------------------;
SCAN_TIME:     MOV.W	 @SCAN_TIME_BASE,ACC_W	 ;
	       MOV.W	 @SCAN_25_TIMES,B_W	 ;
	       MOV.W	 ACC_W,@SCAN_25_TIMES	 ;
	       SUB.W	 B_W,ACC_W		 ;
SCAN_BCD_CONV: MOV.W	 ACC_W,@WS001_ADDR	 ; @SCAN_TIME_NOW
SORT_MAX:      MOV.W	 @WS003_ADDR,B_W	 ;
	       CMP.W	 B_W,ACC_W		 ;
	       BCS	 SORT_MIN:8		 ;
NEW_MAX:       MOV.W	 ACC_W,@WS003_ADDR	 ; @SCAN_TIME_MAX
	       BRA	 NOT_25_TIMES:8 	 ;
SORT_MIN:      MOV.W	 @WS002_ADDR,B_W	 ;
	       CMP.W	 ACC_W,B_W		 ;
	       BCS	 NOT_25_TIMES:8 	 ;
NEW_MIN:       MOV.W	 ACC_W,@WS002_ADDR	 ; @SCAN_TIME_MIN
NOT_25_TIMES:					 ;
RESET_WDDD:    MOV.B	 @H'000A0000,ACC         ; Reset WDT
; *----------------------------------------------*
; |   RUN / STOP flow process return loop	 |
; |   1.Run mode				 |
; |   2.Stop mode				 |
; |   3.Error mode				 |
; *----------------------------------------------*
PC_CHK_RUN:	 MOV.L	 #SC049_ADDR,DPTR	 ;;V0.E SC055/SC056
		 BLD	 SECRET_BIT		 ;;
		 BST	 #7,@DPTR		 ;;
		 BLD	 RUN_FLAG		 ;;
		 BST	 #6,@DPTR		 ;;
		 BCC	 CHK_REQ_RUN:8		 ; RUN_FLAG   = 1
		 BLD	 RUN_FLAG_1		 ; RUN_FLAG_1 = 0
		 BCC	 RUN_ENABLE		 ; Jump to run mode loop
CHK_REQ_RUN:	 BSET	 RUN_FLAG_1		 ;
		 BLD	 REQ_RUN_FG		 ; Stop mode check if run again?
		 BCC	 STOP_MODE:8		 ;
		 BCLR	 REQ_RUN_FG		 ;
		 BRA	 SET_TO_RUN		 ; Stop mode -> Run mode
X005_RUN:	 BLD	 #4,@DPTR		 ;;
		 BST	 X005_LAST_STATUS	 ;;
		 MOV.L	 #SC057_ADDR,DPTR	 ;;V0.E SC064
		 BSET	 #7,@DPTR		 ;;
		 BRA	 SET_TO_RUN		 ;;
; ===========  2.Stop mode  ==============	 ;;
CHK_FORCE_RUN:	 MOV.L	 #STOP_INP_BUFF,DPTR	 ;;
		 BILD	 #4,@DPTR		 ;;
		 BOR	 X005_LAST_STATUS	 ;;
		 BCC	 X005_RUN		 ;;
		 BLD	 #4,@DPTR		 ;;
		 BST	 X005_LAST_STATUS	 ;;
		 BRA	 STOP_MODE1:8		 ;;
STOP_MODE:	 BLD	 EN_422_LINK		 ;;
		 BCC	 STOP_MODE0:8		 ;;
		 BLD	 REMOTE_MODE		 ;;
		 BCC	 STOP_MODE0:8		 ;;
		 BLD	 MASTER_MODE		 ;;
		 BCC	 STOP_MODE1:8		 ;;
STOP_MODE0:	 MOV.W	 @WS049_ADDR,ACC_W	 ;
		 CMP.W	 #1,ACC_W		 ;
		 BEQ	 CHK_FORCE_RUN:8	 ;
		 CMP.W	 #2,ACC_W		 ;
		 BEQ	 CHK_FORCE_RUN:8	 ;
STOP_MODE1:	 MOV.L	 #SC057_ADDR,DPTR	 ;;V0.E SC064
		 BCLR	 #7,@DPTR		 ;;
		 MOV.B	 @TIME_BASE1,ACC	 ;
		 BLD	 #5,ACC 		 ;
		 BST	 RUN_LED		 ;
		 BLD	 BATT_ERR		 ;V0.4
		 BCC	 STOP_M1:8		 ;V0.4
		 BRA	 STOP_M2:8		 ;V0.4
STOP_M1:	 BSET	 ERROR_LED		 ; Turn off error led
STOP_M2:	 BCLR	 ENBL_HSCNT		 ;
		 MOV.B	 @FAULT_STATUS,ACC	 ;V0.D
		 AND.B	 #B'11000000,ACC         ;V0.D
		 MOV.B	 ACC,@FAULT_STATUS	 ;V0.D
		 BCLR	 DLINK_ERR		 ;
		 BCLR	 WDT_ERR		 ;
		 MOV.B	 #0,ACC 		 ;;RESET FLAG STATUS AND CLOCK
		 MOV.B	 ACC,@SC041_ADDR	 ;;TP02
		 MOV.L	 #SC049_ADDR,DPTR	 ;
		 BCLR	 #0,@DPTR		 ;
; ========  System ROM version address #41 ===== ;
		 MOV.W	 #D'2416,ACC_W           ; TP02/4K/Ver1.4/V1.6<<<--
		 MOV.W	 ACC_W,@WS017_ADDR	 ;
		 MOV.W	 #H'0001,ACC_W           ; STOP MODE
		 MOV.W	 ACC_W,@WS008_ADDR	 ;
		 BLD	 STOP_REFRESH		 ;;VF.0
		 BCC	 SYS234_SET:8		 ;;
		 JSR	 @DUMP_FLASH_SYS	 ;;
		 BCLR	 STOP_REFRESH		 ;;
		 MOV.W	 @WS007_ADDR,R0 	 ;;VF.2
		 INC.W	 #1,R0			 ;;
		 MOV.W	 R0,@WS007_ADDR 	 ;;
;Communication mode setting reflesh		 ;
SYS234_SET:	 BSR	 SYS_234_SET		 ;
;High speed counter mode setting reflesh	 ;
		 JSR	 @HSC_INIT		 ;
;AD filter enable mode refresh			 ;
		 MOV.W	 @WS063_ADDR,ACC_W	 ;SC057 AD FILTER START BIT
		 CMP.W	 #H'03,ACC_W             ;
		 BNE	 USE_SOFT_FILTER:8	 ;
		 BSET	 AD_FILTER		 ;
		 BSET	 AD_FILTER1		 ;
		 BCLR	 AD_FILTER2		 ;
		 BRA	 ADD_AD_BUFFER:8	 ;
USE_SOFT_FILTER: CMP.W	 #H'02,ACC_W             ;
		 BNE	 USE_SOFT_FILTER1:8	 ;;
		 BSET	 AD_FILTER		 ;
		 BSET	 AD_FILTER1		 ;
		 BCLR	 AD_FILTER2		 ;
		 BRA	 ADD_AD_BUFFER:8	 ;
USE_SOFT_FILTER1: CMP.W   #H'01,ACC_W            ;
		 BNE	 USE_SOFT_FILTER2:8	 ;;
		 BSET	 AD_FILTER		 ;
		 BCLR	 AD_FILTER1		 ;
		 BCLR	 AD_FILTER2		 ;
		 BRA	 ADD_AD_BUFFER:8	 ;
USE_SOFT_FILTER2: BCLR	 AD_FILTER		 ;
ADD_AD_BUFFER:	 MOV.L	 #AD_FILTER_ADDR1,DPTR	 ;
		 MOV.L	 DPTR,@AD_FILTER_BUFF	 ;
	   ;	  MOV.B   #H'FF,ACC               ; V1.61
	   ;	  MOV.B   ACC,@AD_FILTER_TIMES	  ;
	   ;	  BCLR	  AD_FILTER_ST		  ;
;
ADD_AD_BUFFER2:   MOV.L   #AD_FILTER_ADDR3,DPTR   ; V1.61
		  MOV.L   DPTR,@AD_FILTER_BUFF2    ;
		 MOV.B	 #H'FF,ACC               ;
		 MOV.B	 ACC,@AD_FILTER_TIMES2	  ;
;		 BCLR	 AD_FILTER_ST		 ; V1.61  end
;
;
;10 mS interrupt setting LB177			 ;
SYS_244_EN:	 BSR	 SYS_244_SET		 ;
;;#43 model judgement code			  ;
;		  MOV.B   @TOTAL_IO_NO,ACC	  ;
;JUDGE_MODEL:	  CMP.B   #D'05,ACC               ;
;		  BEQ	  JW1424K:8		  ;
;		  CMP.B   #D'07,ACC               ;
;		  BEQ	  JW1424K:8		  ;
;		  CMP.B   #D'09,ACC               ;
;		  BEQ	  JW1424K:8		  ;
;		  CMP.B   #D'11,ACC               ;
;		  BEQ	  JW1424K:8		  ;
;		  CMP.B   #D'13,ACC               ;
;		  BEQ	  JW1424K:8		  ;
;		  MOV.B   #H'16,ACC               ;
;		  MOV.B   ACC,@SYS_043_ADDR	  ;
;		  BRA	  STOP_IO_MODE:8	  ;
;JW1424K:	  MOV.B   #H'14,ACC               ;
;		  MOV.B   ACC,@SYS_043_ADDR	  ;
;		  BRA	  STOP_IO_MODE:8	  ;
; When stop mode output retention according to SC039;;
STOP_IO_MODE:	 BSR	 OUT_CONDITION		 ;
		 BLD	 EN_422_LINK		 ;
		 BCC	 STOP_RET:8		 ;If master station
		 BLD	 MASTER_MODE		 ;
		 BCC	 STOP_RET:8		 ;
CLR_COMM_FG:	 MOV.B	 #H'00,ACC               ;Stop mode ,reset all link flag
		 MOV.B	 ACC,@SC105_ADDR	 ;
STOP_RET:	 BCLR	 COMPILER_BIT		 ;Reset the compiler finished
		 MOV.W	 @WS012_ADDR,ACC_W	 ;;VF.6
		 CMP.W	 #H'0001,ACC_W           ;;
		 BNE	 STOP_RET1:8		 ;;
		 MOV.W	 #D'1010,ACC_W           ;;
		 MOV.W	 ACC_W,@WS041_ADDR	 ;;
		 MOV.W	 #H'0001,ACC_W           ;;
		 MOV.W	 ACC_W,@WS042_ADDR	 ;;
		 BRA	 STOP_RET11:8		 ;;
STOP_RET1:	 CMP.W	 #H'0002,ACC_W           ;;
		 BNE	 STOP_RET2:8		 ;;
		 MOV.W	 #H'0,ACC_W              ;;
		 MOV.W	 ACC_W,@WS043_ADDR	 ;;
		 MOV.W	 #D'1010,ACC_W           ;;
		 MOV.W	 ACC_W,@WS044_ADDR	 ;;
		 MOV.W	 #H'0001,ACC_W           ;;
		 MOV.W	 ACC_W,@WS045_ADDR	 ;;
STOP_RET11:	 BSET	 OP05_MODE		 ;;
		 BRA	 CH_COMMPP		 ;;
STOP_RET2:	 BCLR	 OP05_MODE		 ;;flag
		 BRA	 CH_COMMPP		 ;;
; ============ RUN loop process ===========	 ;
RUN_ENABLE:	 BLD	 FAULT_FLAG		 ;V0.D
		 BCC	 RUN_MODE		 ;
		 BLD	 E_CHKSUM_ERR		 ;1.system EPROM checksum error
		 BCS	 ERROR_MODE		 ;
		 BLD	 EE_CHKSUM_ERR		 ;2.user ROM checksum error
		 BCS	 ERROR_MODE		 ;
		 BLD	 PTY_CHK_ERR		 ;3.user program parity error
		 BCS	 ERROR_MODE		 ;
		 BLD	 SYS_SET_ERR		 ;4.system setting error
		 BCS	 ERROR_MODE		 ;
		 BLD	 DATA_RAM_ERR		 ;5.Data RAM check error
		 BCS	 ERROR_MODE		 ;
		 BLD	 IO_BUS_ERR		 ;6.I/O bus check error
		 BCS	 ERROR_MODE		 ;
		 BLD	 LOGIC_ERR		 ;7.Logic error mode
		 BCS	 ERROR_MODE		 ;
		 BLD	 DLINK_ERR		 ;8.Remote link timeout error
		 BCS	 ERROR_MODE		 ;
		 BLD	 WDT_ERR		 ; TEST
		 BCS	 ERROR_MODE		 ;
SET_TO_RUN:	 BSET	 RUN_FLAG		 ;
		 BCLR	 RUN_FLAG_1		 ;
		 BSET	 STOP_REFRESH		 ;;VF.0
		 BCLR	 MAIN_INT_BIT		 ;;;VER0.2
		 BCLR	 TIMER_BUSY_BIT 	 ;;;
		 BCLR	 COMPILER_BIT		 ;;;
		 BCLR	 ENC1_INT_BUSY		 ;;;
		 BCLR	 INC1_INT_BUSY		 ;;;
		 BCLR	 INC2_INT_BUSY		 ;;;
		 MOV.W	 #H'0002,ACC_W           ;;
		 MOV.W	 ACC_W,@WS008_ADDR	 ;;VF.0
		 MOV.B	 #H'00,ACC               ;;;
		 MOV.B	 ACC,@INT_KIND		 ;;;V0.2	    V0.3
		 MOV.B	 ACC,@DATA_W_FLAG	 ;;;V0.E4
		 JSR	 @HSC_INIT		 ;;;INI_SYS_PARA ->
		 BCLR	 FAULT_FLAG		 ;Modify by WEI
		 BLD	 E_CHKSUM_ERR		 ;;V0.D
		 BST	 FAULT_FLAG		 ;;V0.D
		 BSET	 RUN_LED		 ;TEST
		 BCLR	 FIRST_PASS_FG		 ;
		 BCLR	 PULSE_EN		 ;
;;;;;;;;;;;;;	 JSR	 @DELAY_1MS		 ;;;VF.0
		 JSR	 @DUMP_FLASH		 ;;;TEST
		 MOV.L	 #D'0,ER0                   ;;V1.633
		 MOV.L	 ER0,@CHANNEL_BUFFER	    ;;
		 MOV.L	 ER0,@AD_RUN_TIMES1	    ;;
		 MOV.L	 ER0,@AD_RUN_TIMES3	    ;;
		 MOV.L	 ER0,@AD_RUN_TIMES5	    ;;
		 MOV.L	 ER0,@AD_RUN_TIMES7	    ;;
;
;======================================================================
;|	Read the first time temperature on THERMOMETER module	      |
;======================================================================
	   ;	PUSH.W	  R1			 ;V1.61  start
	   ;	MOV.B	  @SC017_ADDR,R1L
	   ;	BLD	  #4,R1L
	   ;	BCC	  RES_SCAN_RUN
	   ;	BCLR	  #4,R1L
	   ;	MOV.B	  R1L,@SC017_ADDR
	   ;	POP.W	  R1
	   ;	MOV.W	  @WS061_ADDR,ACC_W	  ;; JUDGE
	   ;	CMP.W	  #H'01,ACC_W             ;;
	   ;	BNE	  ON_BOARD_SENSOR2	  ;;
	   ;	MOV.B	  #B'10001110,ACC         ;write 1st channel command
	   ;	MOV.L	  #H'000A0000,DPTR        ;pseudo address(reset WDT)
	   ;	JSR	  @WR_RD_AD_COMD1	    ;
	   ;	JSR	  @AD_CONV_TIME1	    ;
	   ;	MOV.B	  #B'10011110,ACC         ;write 2nd channel command
	   ;	MOV.L	  #WS067_ADDR,DPTR	  ;read  1st channel data
	   ;	JSR	  @WR_RD_AD_COMD1	    ;
	   ;	JSR	  @AD_CONV_TIME1	    ;
	   ;	MOV.B	  #B'10101110,ACC         ;write 3rd channel command
	   ;	MOV.L	  #WS068_ADDR,DPTR	  ;read  2nd channel data
	   ;	JSR	  @WR_RD_AD_COMD1	    ;
	   ;	JSR	  @AD_CONV_TIME1	    ;
	   ;	MOV.B	  #B'10111110,ACC         ;write 4th channel command
	   ;	MOV.L	  #WS069_ADDR,DPTR	  ;read  3rd channel data
	   ;	JSR	  @WR_RD_AD_COMD1	    ;
	   ;	JSR	  @AD_CONV_TIME1	    ;
	   ;	MOV.B	  #B'11111110,ACC         ;write on board sensor command
	   ;	MOV.L	  #WS070_ADDR,DPTR	  ;read  4td channel data
	   ;	JSR	  @WR_RD_AD_COMD1	    ;
	   ;	JSR	  @AD_CONV_TIME1	  ;
	   ;	MOV.B	  #B'11001110,ACC         ;write psuedo command
	   ;	MOV.L	  #WS065_ADDR,DPTR	  ;read on board sensor data
	   ;	JSR	  @WR_RD_AD_COMD1	  ;
;
;ON_BOARD_SENSOR2:;				  ;
	   ;	MOV.W	  @WS064_ADDR,ACC_W	  ;;
	   ;	CMP.W	 #H'01,ACC_W             ;;
	   ;	BNE	  RES_SCAN_RUN		  ;;
	   ;	MOV.B	 #B'10001110,ACC         ;write 1st channel command
	   ;	MOV.L	 #H'000A0000,DPTR        ;pseudo address(reset WDT)
	   ;	JSR	  @WR_RD_AD_COMD	   ;
	   ;	JSR	  @AD_CONV_TIME 	   ;
	   ;	MOV.B	  #B'10011110,ACC         ;write 2nd channel command
	   ;	MOV.L	  #WS071_ADDR,DPTR	  ;read  1st channel data
	   ;	JSR	  @WR_RD_AD_COMD	   ;
	   ;	JSR	  @AD_CONV_TIME 	   ;
	   ;	MOV.B	 #B'10101110,ACC         ;write 3rd channel command
	   ;	MOV.L	  #WS072_ADDR,DPTR	  ;read  2nd channel data
	   ;	JSR	  @WR_RD_AD_COMD	   ;
	   ;	JSR	  @AD_CONV_TIME 	   ;
	   ;	MOV.B	 #B'10111110,ACC         ;write 4th channel command
	   ;	MOV.L	  #WS073_ADDR,DPTR	  ;read  3rd channel data
	   ;	JSR	  @WR_RD_AD_COMD	   ;
	   ;	JSR	  @AD_CONV_TIME 	   ;
	   ;	MOV.B	  #B'11111110,ACC         ;write on board sensor command
	   ;	MOV.L	  #WS074_ADDR,DPTR	  ;read  4th channel data
	   ;	JSR	  @WR_RD_AD_COMD	   ;
	   ;	JSR	  @AD_CONV_TIME 	   ;
	   ;	MOV.B	 #B'11001110,ACC         ;write psuedo command
	   ;	MOV.L	  #WS066_ADDR,DPTR	  ;read on board sensor data
	   ;	JSR	  @WR_RD_AD_COMD	   ;
;						  ;V1.61  end
	  ;	MOV.W	  #0,ACC_W		  ;;PID  V1.62
	  ;	MOV.W	  ACC_W,@PID_LOOP	  ;;PID  V1.62
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RES_SCAN_RUN:	 MOV.B	 @TIME_BASE1,ACC	 ; Reset the 0.1s & 1s time base
		 MOV.B	 ACC,@TIME_01S_BASE	 ;
		 MOV.B	 ACC,@TIME_04S_BASE	 ;
		 MOV.B	 ACC,@TIME_08S_BASE	 ;
		 MOV.B	 ACC,@TIME_1S_BASE	 ;
		 MOV.B	 ACC,@TIME_BASE2	 ;TP02
		 MOV.B	 ACC,@TIME_BASE3	 ;TP02
; If remote mode & slave station , by pass after ;
		 BLD	 EN_422_LINK		 ;If remote link mode
		 BCC	 STOP_RUN_R:8		 ;in slave station
		 BLD	 REMOTE_MODE		 ;then bypass HIGH_SPEED
		 BCC	 STOP_RUN_R:8		 ;	      RTC
		 BLD	 MASTER_MODE		 ;to SCAN_TIME
		 BCS	 STOP_RUN_R:8		 ;
		 BRA	 INI_SCAN_TIME		 ;
STOP_RUN_R:	 BRA	 DIAG_SYSTEM		 ;
;  ==========  3.Error mode  =============	 ;
ERROR_MODE:	 BSET	 RUN_LED		 ;Turn off RUN LED
		 BCLR	 ERROR_LED		 ;Turn on error led
		 BSR	 OUT_CONDITION		 ;#206 output
		 MOV.W	 #H'0004,ACC_W           ;
		 MOV.W	 ACC_W,@WS008_ADDR	 ;
; *----------------------------------------------*
; |	Diagnostic shift			 |
; *----------------------------------------------*
DIAG_SHIFT:	 MOV.B	 @H'000A0000,ACC         ; Reset WDT
		 MOV.L	 #SC081_ADDR,BUFF_PTR2	 ;
CHK_ERR_1:	 BLD	 E_CHKSUM_ERR		 ;
		 BCC	 CHK_ERR_2:8		 ;
		 MOV.W	 #D'01,ACC_W             ;
		 BSR	 DIAG_WR_LOOP		 ;
		 BSET	 #2,@BUFF_PTR2		 ;SC019
CHK_ERR_2:	 BLD	 EE_CHKSUM_ERR		 ;
		 BCC	 CHK_ERR_3:8		 ;
		 MOV.W	 #D'03,ACC_W             ;
		 BSR	 DIAG_WR_LOOP		 ;
		 BSET	 #2,@BUFF_PTR2		 ;SC019
CHK_ERR_3:	 BLD	 PTY_CHK_ERR		 ;
		 BCC	 CHK_ERR_4:8		 ;
		 MOV.W	 #D'04,ACC_W             ;
		 BSR	 DIAG_WR_LOOP		 ;
		 BSET	 #2,@BUFF_PTR2		 ;SC019
CHK_ERR_4:	 BLD	 SYS_SET_ERR		 ;
		 BCC	 CHK_ERR_5:8		 ;
		 MOV.W	 #D'05,ACC_W             ;
		 BSR	 DIAG_WR_LOOP		 ;
		 BSET	 #2,@BUFF_PTR2		 ;SC019
CHK_ERR_5:	 BLD	 DATA_RAM_ERR		 ;
		 BCC	 CHK_ERR_6:8		 ;
		 MOV.W	 #D'02,ACC_W             ;
		 BSR	 DIAG_WR_LOOP		 ;
		 BSET	 #2,@BUFF_PTR2		 ;SC019
CHK_ERR_6:	 BLD	 IO_BUS_ERR		 ;
		 BCC	 CHK_ERR_7:8		 ;
		 MOV.W	 #D'06,ACC_W             ;
		 BSR	 DIAG_WR_LOOP		 ;
		 BSET	 #4,@BUFF_PTR2		 ;SC021
CHK_ERR_7:	 BLD	 LOGIC_ERR		 ;
		 BCC	 CHK_ERR_8:8		 ;
		 MOV.W	 #D'04,ACC_W             ;
		 BSR	 DIAG_WR_LOOP		 ;
		 BSET	 #2,@BUFF_PTR2		 ;SC019
CHK_ERR_8:	 BLD	 WDT_ERR		 ;
		 BCC	 CHK_ERR_9:8		 ;
		 MOV.W	 #D'10,ACC_W             ;
		 BSR	 DIAG_WR_LOOP		 ;
		 BSET	 #3,@BUFF_PTR2		 ;
CHK_ERR_9:	 BLD	 DLINK_ERR		 ;
		 BCC	 ERR_LP_RET:8		 ;
		 MOV.W	 #D'07,ACC_W             ;
		 BSR	 DIAG_WR_LOOP		 ;
		 BSET	 #6,@BUFF_PTR2		 ;SC023
ERR_LP_RET:	 BRA	 DIAG_SYSTEM		 ;
;;;;
DIAG_WR_LOOP:	 MOV.W	 @WS050_ADDR,B_W	 ;
		 CMP.W	 B_W,ACC_W		 ;
		 BEQ	 DIAG_WR_RET:8		 ;
DIAG_SHIFT_IN:	 MOV.L	 #WS057_ADDR,DPTR	 ;
		 MOV.L	 #WS056_ADDR,BUFF_PTR1	 ;
		 MOV.B	 #H'07,REG_R1            ;
DIAG_SHIFT_LOOP: MOV.W	 @BUFF_PTR1,B_W 	 ;
		 MOV.W	 B_W,@DPTR		 ;
		 DEC.L	 #2,DPTR		 ;
		 DEC.L	 #2,BUFF_PTR1		 ;
		 DEC.B	 REG_R1 		 ;
		 BNE	 DIAG_SHIFT_LOOP:8	 ;
		 INC.L	 #2,BUFF_PTR1		 ;
		 MOV.W	 ACC_W,@BUFF_PTR1	 ;
DIAG_WR_RET:	 RTS				 ;
;;;; SC039 output condition  ;;;;;;;;;;;	 ;
OUT_CONDITION:	 MOV.W	 @WS023_ADDR,ACC_W	 ;
		 CMP.W	 #H'00,ACC_W             ;
		 BEQ	 RETAIN_RET:8		 ;
		 BCLR	 EN_IO			 ;
		 BSR	 EXE_WR_DR_00		 ;
		 MOV.B	 #H'FF,ACC               ;
		 MOV.L	 #Y1_Y8_BUFF,DPTR	 ;
CLR_OUT_LED:	 MOV.B	 ACC,@DPTR		 ;
		 INC.L	 #1,DPTR		 ;
		 CMP.L	 #Y21_Y24_BUFF+1,DPTR	 ;
		 BNE	 CLR_OUT_LED:8		 ;
RETAIN_RET:	 MOV.B	 @DINP_IO_NO,REG_R2	 ; (or) start output 4094
		 MOV.L	 #STOP_INP_BUFF,DPTR	 ; Trigger 4021 & 4094
		 BSET	 PS			 ;
		 BCLR	 RUN_OUT		 ;
		 BCLR	 PS			 ;
		 BSR	 EXE_INP_D0_B		 ; Input scan loop
DATA_SNR_IN:	 BLD	 EN_422_LINK		 ;
		 BCC	 OUT_C_RET:8		 ;
		 BLD	 REMOTE_MODE		 ;
		 BCS	 OUT_C_RET:8		 ;
		 BLD	 MASTER_MODE		 ;
		 BCS	 OUT_C_RET:8		 ;
		 JSR	 @S_TXOUT_SNR		 ;for data link slave mode only
		 MOV.B	 #H'00,ACC               ;
		 MOV.B	 ACC,@SLAVE_RING	 ;
OUT_C_RET:	 RTS				 ;
;  ==========  1.Run mode   ==============	 ;
RUN_MODE:	 BCLR	 RUN_LED		 ;Turn on RUN LED
		 BSET	 RUN_OUT		 ;
	 ;;;;;	 MOV.W	 #H'0002,ACC_W           ;VF.3
	 ;;;;;	 MOV.W	 ACC_W,@WS008_ADDR	 ;
		 BLD	 EN_422_LINK		 ;
		 BCC	 CHK_X006:8		 ;
		 BLD	 REMOTE_MODE		 ;
		 BCC	 CHK_X006:8		 ;
		 BLD	 MASTER_MODE		 ;
		 BCS	 CHK_X006:8		 ;
		 BRA	 START_SCAN		 ;SLAVE MODE
; *----------------------------------------------*
; |	100mS & 1000mS system timer update	 |
; *----------------------------------------------*
CHK_X006:	 MOV.W	 @WS049_ADDR,ACC_W	 ;;
		 CMP.W	 #2,ACC_W		 ;;
		 BNE	 SYS_TIM_UPDATE:8	 ;;
		 MOV.L	 #X_STATE,DPTR		 ;;
		 BILD	 #5,@DPTR		 ;;
		 BOR	 X006_LAST_STATUS	 ;;
		 BCC	 X006_STOP:8		 ;;
		 BLD	 #5,@DPTR		 ;;
		 BST	 X006_LAST_STATUS	 ;;
		 BRA	 SYS_TIM_UPDATE:8	 ;;
X006_STOP:	 BLD	 #5,@DPTR		 ;;
		 BST	 X006_LAST_STATUS	 ;;
		 BCLR	 RUN_FLAG		 ;;
		 BRA	 STOP_MODE		 ;;
SYS_TIM_UPDATE:  MOV.L	 #SC041_ADDR,DPTR	 ;
		 MOV.B	 @TIME_01S_BASE,B_REG	 ;
		 MOV.B	 @TIME_BASE1,ACC	 ; #7360:100mS
		 MOV.B	 ACC,REG_R1		 ;
		 SUB.B	 B_REG,ACC		 ;   ÚÄÄ¿  ÚÄÄ¿
		 CMP.B	 #D'10,ACC               ; ÄÄÙ  ÀÄÄÙ  ÀÄÄÄ
		 BCS	 NO_OFFSET_100MS:8	 ;   ³100mS³
		 MOV.B	 @TIME_BASE1,ACC	 ;
		 MOV.B	 ACC,@TIME_01S_BASE	 ;
		 BRA	 UPDATE_400MS:8 	 ;
NO_OFFSET_100MS: CMP.B	 #D'5,ACC                ;
		 BCS	 UPDATE_400MS:8 	 ;
		 BNOT	 #5,@DPTR		 ;
		 MOV.B	 @TIME_01S_BASE,ACC	 ; V0.4
		 ADD.B	 #D'5,ACC                ;
		 MOV.B	 ACC,@TIME_01S_BASE	 ;
UPDATE_400MS:	 MOV.B	 @TIME_04S_BASE,B_REG	 ;
		 MOV.B	 REG_R1,ACC		 ;
		 SUB.B	 B_REG,ACC		 ;
		 CMP.B	 #D'20,ACC               ;
		 BCS	 UPDATE_800MS:8 	 ;
		 BNOT	 #6,@DPTR		 ;
		 MOV.B	 @TIME_04S_BASE,ACC	 ;
		 ADD.B	 #D'20,ACC               ;
		 MOV.B	 ACC,@TIME_04S_BASE	 ;

UPDATE_800MS:	 MOV.B	 @TIME_08S_BASE,B_REG	 ;
		 MOV.B	 REG_R1,ACC		 ;
		 SUB.B	 B_REG,ACC		 ;
		 CMP.B	 #D'40,ACC               ;
		 BCS	 UPDATE_1S:8		 ;
		 BNOT	 #7,@DPTR		 ;
		 MOV.B	 @TIME_08S_BASE,ACC	 ;
		 ADD.B	 #D'40,ACC               ;
		 MOV.B	 ACC,@TIME_08S_BASE	 ;

UPDATE_1S:	 MOV.B	 @TIME_1S_BASE,B_REG	 ;
		 MOV.B	 REG_R1,ACC		 ; SC001
		 SUB.B	 B_REG,ACC		 ;   ÚÄÄ¿  ÚÄÄ¿
		 CMP.B	 #D'50,ACC               ; ÄÄÙ  ÀÄÄÙ  ÀÄÄ
		 BCS	 UPDATE_TMR_BASE:8	 ;   ³ 1S  ³
		 MOV.L	 #SC049_ADDR,DPTR	 ;
		 BNOT	 #0,@DPTR		 ;?????
		 MOV.B	 @TIME_1S_BASE,ACC	 ;
		 ADD.B	 #D'50,ACC               ;
		 MOV.B	 ACC,@TIME_1S_BASE	 ;

UPDATE_TMR_BASE: MOV.B	 REG_R1,R5L		 ;
		 MOV.B	 @TIME_BASE2,R6L	 ;
		 MOV.B	 R5L,@TIME_BASE2	 ;
		 SUB.B	 R6L,R5L		 ;
		 MOV.B	 R5L,@TIME_DIFF_10MS	 ;

UPDATE_IN_MAP:	 MOV.B	 #D'5,REG_R1             ;Total 10 bytes need to be
		 MOV.L	 #X_STATE,DPTR		 ;refresh
		 MOV.L	 #IN_STR_ADDR,BUFF_PTR1  ;
UPDATE_IN_LP:	 MOV.W	 @DPTR,R0		 ;
		 MOV.W	 R0,@BUFF_PTR1		 ;
		 INC.L	 #2,DPTR		 ;
		 INC.L	 #2,BUFF_PTR1		 ;
		 DEC.B	 REG_R1 		 ;
		 BNE	 UPDATE_IN_LP:8 	 ;
UPDATE_OUT_MAP:  MOV.B	 #D'4,REG_R1             ;Total 8 bytes need to be
		 MOV.L	 #Y_STATE,DPTR		 ;refresh
		 MOV.L	 #OUT_STR_ADDR,BUFF_PTR1 ;
UPDATE_OUT_LP:	 MOV.W	 @DPTR,R0		 ;
		 MOV.W	 R0,@BUFF_PTR1		 ;
		 INC.L	 #2,DPTR		 ;
		 INC.L	 #2,BUFF_PTR1		 ;
		 DEC.B	 REG_R1 		 ;
		 BNE	 UPDATE_OUT_LP:8	 ;
STR_TO_SOLVER:					 ;
		 ANDC	 #B'11111110,CCR         ;
		 BSET	 USER_WDT_ERR		 ;
		 MOV.W	 #H'000F,E2              ;
		 MOV.W	 #H'000F,E3              ;
		 MOV.W	 #H'000F,E4              ;
		 MOV.W	 #H'0,R0                 ;
		 MOV.W	 #H'0,R1                 ;
		 MOV.B	 #H'99,ACC               ;
		 MOV.B	 ACC,@INT_KIND		 ;
		 JMP	 @MACHINE_CODE		 ;
;******************************************************************************
;******************	  REFRESH TIMER 	*******************************
;******************************************************************************
;/* Module Name:   REFLESH TIMER()
;   Description:   Interrupt handling processing module for led scan timer
REFRESH_TIMER: PUSH.W	 ACC_W
	       MOV.B	 @LED_SCAN,ACC
	       ROTR.B	 ACC
	       MOV.B	 ACC,@LED_SCAN
X1_X12_ON:     CMP.B	 #B'00000001,ACC
	       BNE	 X13_X24_ON:8
	       MOV.B	 @X1_X8_BUFF,ACC
	       MOV.B	 ACC,@PBDR
	       MOV.B	 @X9_X12_BUFF,ACC
	       MOV.B	 ACC,@P5DR
	       MOV.B	 @LED_DRIVER,ACC    ;11110XXX
	       BCLR	 #3,ACC
	       BRA	 LED_RET:8
X13_X24_ON:    CMP.B	 #B'00000010,ACC
	       BNE	 X25_X36_ON:8
	       MOV.B	 @X13_X20_BUFF,ACC
	       MOV.B	 ACC,@PBDR
	       MOV.B	 @X21_X24_BUFF,ACC
	       MOV.B	 ACC,@P5DR
	       MOV.B	 @LED_DRIVER,ACC
	       BCLR	 #4,ACC
	       BRA	 LED_RET:8
X25_X36_ON:    CMP.B	 #B'00000100,ACC
	       BNE	 Y1_Y12_ON:8
	       MOV.B	 @X25_X32_BUFF,ACC
	       MOV.B	 ACC,@PBDR
	       MOV.B	 @X33_X36_BUFF,ACC
	       MOV.B	 ACC,@P5DR
	       MOV.B	 @LED_DRIVER,ACC
	       BCLR	 #5,ACC
	       BRA	 LED_RET:8
Y1_Y12_ON:     CMP.B	 #B'00001000,ACC
	       BNE	 Y13_Y24_ON:8
	       MOV.B	 @Y1_Y8_BUFF,ACC
	       MOV.B	 ACC,@PBDR
	       MOV.B	 @Y9_Y12_BUFF,ACC
	       MOV.B	 ACC,@P5DR
	       MOV.B	 @LED_DRIVER,ACC
	       BCLR	 #6,ACC
	       BRA	 LED_RET:8
Y13_Y24_ON:    MOV.B	 #B'00010000,ACC
	       MOV.B	 ACC,@LED_SCAN
	       MOV.B	 @Y13_Y20_BUFF,ACC
	       MOV.B	 ACC,@PBDR
	       MOV.B	 @Y21_Y24_BUFF,ACC
	       MOV.B	 ACC,@P5DR
	       MOV.B	 @LED_DRIVER,ACC
	       BCLR	 #7,ACC
LED_RET:       MOV.B	 ACC,@H'000C0000
	       BCLR	 CMF
	       POP.W	 ACC_W
	       RTE
;******************************************************************************
;******************	  WDT TIMER BASE	*******************************
;******************************************************************************
;/* Module Name:   WOVI_INT()
;   Description:   Interrupt handling processing module for scan timer
WOVI_INT:      PUSH.W	 R0			 ;
	       MOV.W	 @SCAN_TIME_BASE,R0	 ;
	       INC.W	 #1,R0			 ;
	       MOV.W	 R0,@SCAN_TIME_BASE	 ;
	       MOV.W	 #H'5A19,R0              ;1 ms
	       MOV.W	 R0,@H'000FFFA8          ;
	       MOV.W	 @H'000FFFA8,R0          ;KEY point !
	       MOV.W	 #H'A53A,R0              ;
	       MOV.W	 R0,@H'000FFFA8          ;
	       BLD	 COM_NOISE_BIT		 ;;VF.4
	       BCC	 WOVI_INT_RET:8 	 ;;
	       MOV.W	 @COM_TIME_OUT,R0	 ;;V1.5
	       DEC.W	 #1,R0			 ;;
	       BNE	 WOVI_INT_RET:8 	 ;;
	       BCLR	 REQ_START_FG0		 ;;
	       BCLR	 COM_NOISE_BIT		 ;;
WOVI_INT_RET:  MOV.W	 R0,@COM_TIME_OUT	 ;;
	       POP.W	 R0			 ;
	       RTE				 ;
;******************************************************************************
;******************	  ITU TIMER0		*******************************
;******************************************************************************
;/* Module Name:   ITU TIMER()
;   Description:   Interrupt handling processing module for system timer
TIMER_BASE:    BCLR	 #0,@TSR0		 ;
	       ANDC	 #H'7F,CCR               ;;V1.1
	       PUSH.L	 ER0			 ;
	       MOV.W	 @TIME_BASE,ACC_W	 ;
	       INC.W	 #1,ACC_W		 ;
	       MOV.W	 ACC_W,@TIME_BASE	 ;
	       BTST	 TIMER_BUSY_BIT 	 ;
	       BNE	 TIMER_B1:8		 ;
	       BTST	 COMPILER_BIT		 ;Compiler OK?
	       BEQ	 TIMER_B0:8		 ;NO->Jump TIMER_B0
	       BTST	 RUN_FLAG		 ;Run Mode?
	       BEQ	 TIMER_B0:8		 ;NO->Jump TIMER_B0
	       BLD	 LB128_TM_INT		 ;Test WS047 =1 ?
	       BCC	 TIMER_B0:8		 ;No Jump TIMER_B0
	       BLD	 FAULT_FLAG		 ;If fault status,then bypass
	       BCS	 TIMER_B0:8		 ;
TIME_INT_ST:   BSET	 USER_WDT_ERR1		 ;V0.4
	       BSET	 TIMER_BUSY_BIT 	 ;
	       PUSH.L	 ER1			 ;PUSH.L ER0(in the strt)
	       PUSH.L	 ER2			 ;
	       PUSH.L	 ER3			 ;
	       PUSH.L	 ER4			 ;
	       PUSH.L	 ER5			 ;
	       PUSH.L	 ER6			 ;
	       MOV.B	 @INT_KIND,ACC		 ;
	       MOV.B	 ACC,@INT_KIND_BUFF6	 ;
	       MOV.B	 #H'66,ACC               ;
	       MOV.B	 ACC,@INT_KIND		 ;
	       JMP	 @BUFF_PUSH		 ;
TIME_INT_ST1:  MOV.W	 @H'FFF076,R3            ;V0.7
	       CMP.W	 #END_ADDR,R3		 ;;VF.0
	       BEQ	 TIMER_B2:8		 ;;
	       SHLL.W	 R3			 ;
	       SHLL.W	 R3			 ;
	       SHLL.W	 R3			 ;
	       MOV.L	 #MACHINE_CODE,ER2	 ;
	       ADD.W	 R3,R2			 ;LB128 label address
	       MOV.W	 #0,R0			 ;
	       MOV.W	 #0,R1			 ;
	   ;;; ANDC	 #H'7E,CCR               ;V0.7 TP02
	       JMP	 @ER2			 ;
TIMER_B0:					 ;
	   ;;; ANDC	 #H'7E,CCR               ;V0.7 TP02
	       BCLR	 TIMER_BUSY_BIT 	 ;
TIMER_B1:      POP.L	 ER0			 ;
	       RTE				 ;
;// LB128 return point //			 ;
TIMER_B2:     .EQU	 $			 ;
	       JMP	 @BUFF_POP		 ;
TIMER_B22:     MOV.B	 @INT_KIND_BUFF6,ACC	 ;
	       MOV.B	 ACC,@INT_KIND		 ;
	       POP.L	 ER6			 ;
	       POP.L	 ER5			 ;
	       POP.L	 ER4			 ;
	       POP.L	 ER3			 ;
	       POP.L	 ER2			 ;
	       POP.L	 ER1			 ;
	       POP.L	 ER0			 ;
	       BCLR	 TIMER_BUSY_BIT 	 ;
	       BCLR	 USER_WDT_ERR1		 ;V0.4
	       RTE				 ;
; *----------------------------------------------*
; |	Initial system parameter		 |
; |	& set I/O port direction		 |
; *----------------------------------------------*
INI_SYS_PARA:  MOV.B	 #B'01111111,R0L          ;Area7(16bits) Area0-6(8bits)
	       MOV.B	 R0L,@ABWCR		  ;
	       MOV.B	 #B'11111111,R0L          ;Area0-7,Access in 3 states
	       MOV.B	 R0L,@ASTCR		  ;
	       MOV.B	 #B'11110000,R0L          ;Area0-7,0 wait states insert
	       MOV.B	 R0L,@WCR		  ;Area4, 3 wait states
	       MOV.B	 #B'11111111,R0L          ;Disable wait state controller
	       MOV.B	 R0L,@WCER		  ;
;
	       MOV.B	 #H'FF,R0L                ;Set the P5_PORT out put pin
	       MOV.B	 R0L,@P5DDR		  ;
	       MOV.B	 #H'FF,R0L                ;Turn led off when power on
	       MOV.B	 R0L,@P5DR		  ;(low enable)
;
	       MOV.B	 #H'87,R0L                ;Set the P6_PORT out put pin
	       MOV.B	 R0L,@P6DDR		  ;
	 ;;;   MOV.B	 #H'00,R0L                ;Turn port off when power on
	 ;;;   MOV.B	 R0L,@P6DR		  ;
;
	       MOV.B	 #H'FB,R0L                ;Set the P8_PORT out put pin
	       MOV.B	 R0L,@P8DDR		  ;V1.4 FF->FB
	       MOV.B	 #H'FE,R0L                ;Turn RUN_OUT off when
	       MOV.B	 R0L,@P8DR		  ;power on
;
	       MOV.B	 #H'F2,R0L                ;V1.4 Set the P9_PORT out put pin
	       MOV.B	 R0L,@P9DDR		  ;
	 ;;;   MOV.B	 #H'00,R0L                ;Turn EN_IO & EN_485 off when
	 ;;;   MOV.B	 R0L,@P9DR		  ;power on
;
	       MOV.B	 #H'F0,R0L                ;Set the PA_4-PA_7 output pin
	       MOV.B	 R0L,@PADDR		  ;PA_0-PA_3,PA7 input pin
	 ;;;   MOV.B	 #H'00,R0L                ;
	 ;;;   MOV.B	 R0L,@PADR		  ;
;
	       MOV.B	 #H'FF,R0L                ;Set the PB_0-PB_7 output pin
	       MOV.B	 R0L,@PBDDR		  ;
	       MOV.B	 #H'FF,R0L                ;Turn LED1-LED8 off when power
	       MOV.B	 R0L,@PBDR		  ;on(low enable)
;
	       MOV.B	 #H'FF,R0L                ;Set the PC_0-PC_7 output pin
	       MOV.B	 R0L,@PCDDR		  ;
	       MOV.B	 #H'3C,R0L                ;Turn PC_PORT off when power
	       MOV.B	 R0L,@PCDR		  ;on
; ========  Clear LED reflesh buffer   ========= ;
	       MOV.B	 #H'FF,ACC               ;
	       MOV.L	 #X1_X8_BUFF,DPTR	 ;;;V0.F6
LED_BUFF_CLR:  MOV.B	 ACC,@DPTR		;;
	       INC.L	 #1,DPTR		;;
	       CMP.L	 #Y21_Y24_BUFF+1,DPTR	;;
	       BCS	 LED_BUFF_CLR:8 	;;
; ========  EEPROM or EPROM judge  ========	 ;
EE_EXIST_JU:   MOV.B	 #H'FB,ACC               ;;V1.1
	       MOV.B	 ACC,@LED_DRIVER	 ;;
	       MOV.B	 ACC,@H'000C0000         ;;
	    ;  MOV.B	 #B'11110011,ACC         ;;
	    ;  MOV.B	 ACC,@WCR		 ;;
	       MOV.B	 #H'55,ACC               ;;
	       MOV.B	 ACC,@H'00083FFD         ;
	       JSR	 @DELAY_1MS		 ;
	       MOV.B	 #H'00,ACC               ;
	       MOV.B	 @H'00083FFD,ACC         ;
	       CMP.B	 #H'55,ACC               ;
	       BNE	 EEROM_NOT_EXIST:8	 ;
	       BSET	 EEPROM_BIT		 ;
	       MOV.B	 #H'37,ACC               ;
	       MOV.B	 ACC,@H'00083FFD         ;
	       JSR	 @DELAY_1MS		 ;
	       BRA	 EE_J_END:8		 ;
EEROM_NOT_EXIST:   BCLR      EEPROM_BIT 	 ;V0.9
EE_J_END:    ; MOV.B	 #B'11110000,ACC         ;;
	     ; MOV.B	 ACC,@WCR		 ;;
;------------  Serial port1  ---------------------;
RS422_INI:     BSR	 SYS_234_SET		  ;
	       BSET	 #RIE,@SCR1		  ;
	       BSET	 #RE,@SCR1		  ;
;------------  Serial port0  ---------------------;
	       BSR	 PG_INI 		  ;
;-------------	ITU 0 free-running mode  ---------;
	       MOV.B	 #B'10100010,ACC          ; clock/4 ITU TIMER0
	       MOV.B	 ACC,@TCR0		  ;Select the counter clock
	       MOV.W	 #H'9000,ACC_W            ;V0.3>9C3F
	       MOV.W	 ACC_W,@GRA0		  ;
	       BSET	 #0,@TIER0		  ;
	       BSET	 #0,@TSTR		  ;Start/stop the timer counter
;------------ WDT timer  -------------------------;
	       MOV.W	 #H'A53A,R0               ;;
	       MOV.W	 R0,@H'000FFFA8           ;;V0.7
;-----------  High speed counter mode ------------;
	       JSR	 @HSC_INIT		  ;Initial high speed counter
;-----------  10 mS interrupt setting ------------;
	       BSR	 SYS_244_SET		  ;Initial 10mS interrupt set
;-----------  Power on version code update -------;
	       BCLR	 X_NO_REFRESH		  ;;V1.1
	       MOV.W	 #D'2416,ACC_W           ; TP02/4K/Ver0.6
	       MOV.W	 ACC_W,@WS017_ADDR	 ;		  '97
	       MOV.W	 @WS007_ADDR,R0 	  ;;VF.2
	       INC.W	 #1,R0			  ;;
	       MOV.W	 R0,@WS007_ADDR 	  ;;
	       MOV.W	 @EE_WS008_ADDR,R0	  ;;FIRST TIME NO NEED
	       CMP.W	 #0,R0			  ;;WRITE TO FLASH
	       BEQ	 SET_PIORITY:8		  ;;
	       CMP.W	 #H'FFFF,R0               ;;V1.5
	       BEQ	 SET_PIORITY:8		  ;;
	       BLD	 BATEN			  ;;NO BATTERY NO NEED
	       BCC	 SET_PIORITY:8		  ;;WRITE TO FLASH
	       JSR	 @DUMP_FLASH_SYS	  ;;VF.3
	       MOV.W	 @WS012_ADDR,ACC_W	  ;;;V1.1
	       CMP.W	 #H'0001,ACC_W            ;;
	       BEQ	 OP05_06_MODE:8 	  ;;
	       CMP.W	 #H'0002,ACC_W            ;;
	       BEQ	 OP05_06_MODE:8 	  ;;
	       BCLR	 OP05_MODE		  ;;
	       BRA	 SET_PIORITY:8		  ;;
OP05_06_MODE:  BSET	 OP05_MODE		  ;;
;-------------------------------------------------;
SET_PIORITY: ; BSET	 #3,@IPRB		  ;Set SCI 0 higher priority
	     ; BSET	 #2,@IPRB		  ;Set SCI 1 higher priority
	     ; BSET	 #2,@IPRA		  ;ITU 0 as higher piority
	     ; BSET	 #3,@IPRA		  ;Reflesh as higher piority
	       MOV.B	 #B'01101111,R0L          ;Enable reflesh timer
	       MOV.B	 R0L,@RTMCSR		  ;
	       MOV.B	 #H'57,R0L                ; 4 ms, total 20 ms (5F)
	       MOV.B	 R0L,@RTCOR		  ; V0.4, 3ms total 15ms
	       BSET	 CMIE			  ;
	    ;  BCLR	 #3,@SYSCR		  ;Clear UE bit (two level int)
	       ANDC	 #B'01111111,CCR          ;Clear I
	       BSET	 PRG_4K_MODE		  ;TP02-40MR,60MR USED
	       MOV.L	 @WS039_ADDR,ER0	  ;;VF.2
	       CMP.L	 #0,ER0 		  ;;
	       BNE	 COM_SECRET_ON:8	  ;;
	       BCLR	 COM_SECRET		  ;;
	       RTS				  ;;
COM_SECRET_ON: BSET	 COM_SECRET		  ;;
	       RTS				  ;				 ;						   ;
; ----------  Serial port1 setting  ------------  ;
SYS_234_SET:   MOV.B	 @WS043_ADDR+1,ACC	  ;
	       CMP.B	 #H'00,ACC                ;
	       BNE	 D_LINK_MODE:8		  ;
	       BLD	 DLINK_FG		  ;
	       BCC	 COM_LINK_MODE:8	  ;
;;;	       BCLR	 TXENDF1		  ;1.computer link
OVER_234_R:    MOV.B	 #H'84,ACC                ;
	       MOV.B	 ACC,@SSR1		  ;
	       BCLR	 DLINK_FG		  ;
COM_LINK_MODE: BCLR	 EN_422_LINK		  ;
	       BCLR	 REMOTE_MODE		  ;
	       BCLR	 MASTER_MODE		  ;
DEF_COM_LINK:  BCLR	 #2,@SMR1		  ;
	       BCLR	 #MPIE,@SCR1		  ;
	       BSET	 #TE,@SCR1		  ;
	       MOV.W	 @WS044_ADDR,R4 	  ;;TP02
	       BSR	 SYS_TO_WS_CHG		  ;;
	       MOV.B	 ACC,@SYS_236_ADDR	  ;;
	       MOV.L	 #SYS_236_ADDR,DPTR	  ;Data bit
	       MOV.L	 #SMR1,BUFF_PTR1	  ;
	       BCLR	 SYS226_OR_236		  ;V0.E4
	       BSR	 COM_INI_PARA		  ;
	       RTS				  ;
D_LINK_MODE:   CMP.B	 #H'01,ACC                ;
	       BNE	 IO_LINK_MODE:8 	  ;
	       BSET	 EN_422_LINK		  ;2.data link
	       BCLR	 REMOTE_MODE		  ;
	       BCLR	 TXENDF2		  ;
	       MOV.B	 @WS045_ADDR+1,B_REG	  ;
	       CMP.B	 #H'00,B_REG              ;
	       BNE	 SLAVE_INIT:8		  ;
	       JSR	 @DATA_ON_INIT		  ;;V0.E
	       BRA	 D_LINK_M2:8		  ;
SLAVE_INIT:    JSR	 @S_TXOUT_SNR		  ;
D_LINK_M2:     MOV.L	 #SC105_ADDR,DPTR	  ;V0.4
	       BCLR	 #0,@DPTR		  ;V0.4
	       BRA	 DLINK_SET_ST:8 	  ;
IO_LINK_MODE:  CMP.B	 #H'02,ACC                ;
	       BNE	 OVER_234_R:8		  ;V0.E
	       BCLR	 STOP_IOLINK		  ;V0.E
IO_LINK_SET:   BSET	 EN_422_LINK		  ;
	       BSET	 REMOTE_MODE		  ;
DLINK_SET_ST:  MOV.B	 @WS044_ADDR+1,R0L     ;;;;V0.5
DB_38400:      CMP.B	 #H'01,R0L             ;;;
	       BNE	 DB_76800:8	       ;;;
	       MOV.B	 #11,R0L	       ;;;CKS0,1=0,N=51
	       BRA	 DATA_L_BSET:8	       ;;;
DB_76800:      MOV.B	 #5,R0L 	       ;;;
DATA_L_BSET:   MOV.B	 R0L,@BRR1	       ;;;;76800bps,V0.3>38400
	       BLD	 DLINK_FG		  ; For first time initial used
	       BCS	 DLINK_OK:8		  ; only
	       BSET	 DLINK_FG		  ;
	       MOV.B	 #B'00000100,R0L          ;Asyncro mode,8bit,np,stop1
	       MOV.B	 R0L,@SMR1		  ;multiprocessor mode
	       MOV.L	 #ASCII1_3A,BUFF_PTR1	  ;Initial the buff_pointer
	       MOV.L	 BUFF_PTR1,@BUFF_PTR	  ;
	       BSET	 #RIE,@SCR1		  ;Enable RXI interrupt
	       BSET	 #RE,@SCR1		  ;Enable receive
	       BSET	 #TE,@SCR1		  ;Enable transmit
	       BSET	 #MPIE,@SCR1		  ;Multiprocessor interrupt
	       BCLR	 REQ_START_FG1		  ;
	       BCLR	 EN_422 		  ;Initial receive mode
DLINK_OK:      MOV.B	 @WS045_ADDR+1,ACC	  ;
	       CMP.B	 #H'00,ACC                ;
	       BNE	 SLAVE_MODE:8		  ;
	       BSET	 MASTER_MODE		  ;
	       MOV.B	 #H'00,ACC                ;;V0.E
	       MOV.B	 ACC,@SLAVE_RING	  ;;V0.E
	       RTS				  ;
SLAVE_MODE:    BCLR	 MASTER_MODE		  ;
	       MOV.B	 @WS043_ADDR+1,ACC	  ;;V0.F1
	       CMP.B	 #H'02,ACC                ;;
	       BNE	 END_DLINK1:8		  ;;
	       MOV.B	 ACC,@SYS_234_IO	  ;;
	       JSR	 @DUMP_FLASH		  ;;V0.D
	       BSET	 RUN_FLAG		  ;;
	       BCLR	 RUN_FLAG_1		  ;;
	  ;;   MOV.B	 #ASCII_3,ACC		  ;;
	  ;;   MOV.B	 ACC,@SET_MODE		  ;;
	       BCLR	 SECRET_BIT		  ;;V0.F4 in remote i/o, slave
	 ;;    MOV.L	 #H'FFFFFFFF,DPTR         ;;station secret should cancel
	 ;;    MOV.L	 DPTR,@PASS_MEM 	  ;;
	       MOV.B	 @TIME_BASE1,ACC	  ;;
	       MOV.B	 ACC,@DLINK_TIMEOUT	  ;;
END_DLINK1:    MOV.B	 #H'01,ACC                ;;V0.E
	       MOV.B	 ACC,@SLAVE_RING	  ;;V0.E
	       BCLR	 RX_IN_ON		  ;;V0.E
	       BCLR	 TX_OUT_ON		  ;;V0.E
END_DLINK_SET: RTS				  ;
;----------  SMR initial subroutine   ------------;
COM_INI_PARA:  BLD	 #7,@DPTR		  ;
	       BIST	 #6,@BUFF_PTR1		  ;
	       BLD	 #5,@DPTR		  ;Stop bit V0.3
	       BST	 #3,@BUFF_PTR1		  ;
	       MOV.B	 @DPTR,ACC		  ;
	       AND.B	 #B'00011000,ACC          ;
NON_PTY:       CMP.B	 #B'00000000,ACC          ;
	       BNE	 ODD_PTY:8		  ;
	       BCLR	 #5,@BUFF_PTR1		  ;
	       BRA	 BAUD_SET:8		  ;
ODD_PTY:       CMP.B	 #B'00001000,ACC          ;
	       BNE	 EVEN_PTY:8		  ;
	       BSET	 #5,@BUFF_PTR1		  ;
	       BSET	 #4,@BUFF_PTR1		  ;
	       BRA	 BAUD_SET:8		  ;
EVEN_PTY:      BSET	 #5,@BUFF_PTR1		  ;
	       BCLR	 #4,@BUFF_PTR1		  ;
BAUD_SET:      MOV.B	 @DPTR,ACC		  ;
	       AND.B	 #B'00000111,ACC          ;
BAUD_38400:    CMP.B	 #B'00000111,ACC          ;
	       BNE	 BAUD_19200:8		  ;
	       MOV.B	 #11,R0L		  ;
	       BRA	 BAUD_SMR_WR0:8 	  ;;V1.3
BAUD_19200:    CMP.B	 #B'00000000,ACC          ;
	       BNE	 BAUD_9600:8		  ;
	       MOV.B	 #23,R0L		  ;
	       BRA	 BAUD_SMR_WR0:8 	  ;;
BAUD_9600:     CMP.B	 #B'00000001,ACC          ;
	       BNE	 BAUD_4800:8		  ;
	       MOV.B	 #47,R0L		  ;
	       BRA	 BAUD_SMR_WR0:8 	  ;;
BAUD_4800:     CMP.B	 #B'00000010,ACC          ;
	       BNE	 BAUD_2400:8		  ;
	       MOV.B	 #95,R0L		  ;
	       BRA	 BAUD_SMR_WR0:8 	  ;;
BAUD_2400:     CMP.B	 #B'00000011,ACC          ;
	       BNE	 BAUD_1200:8		  ;
	       MOV.B	 #191,R0L		  ;
	       BRA	 BAUD_SMR_WR0:8 	  ;;
BAUD_1200:     CMP.B	 #B'00000100,ACC          ;
	       BNE	 BAUD_600:8		  ;
	       BSET	 #0,@BUFF_PTR1		  ; n=1
	       BCLR	 #1,@BUFF_PTR1		  ;;
	       MOV.B	 #95,R0L		  ;
	       BRA	 BAUD_SMR_WR:8		  ;
BAUD_600:      CMP.B	 #B'00000101,ACC          ;
	       BNE	 BAUD_300:8		  ;
	       BSET	 #0,@BUFF_PTR1		  ; n=1
	       BCLR	 #1,@BUFF_PTR1		  ;;
	       MOV.B	 #191,R0L		  ;
	       BRA	 BAUD_SMR_WR:8		  ;
BAUD_300:      CMP.B	 #B'00000110,ACC          ;
	       BEQ	 BAUD_300_GO:8		  ;
	       RTS				  ;
BAUD_SMR_WR0:  BCLR	 #0,@BUFF_PTR1		  ;;V1.3
	       BCLR	 #1,@BUFF_PTR1		  ;;
	       BRA	 BAUD_SMR_WR:8		  ;;
BAUD_300_GO:   BSET	 #1,@BUFF_PTR1		  ; n=2
	       BCLR	 #0,@BUFF_PTR1		  ;;
	       MOV.B	 #95,R0L		  ;
BAUD_SMR_WR:   BLD	 SYS226_OR_236		  ;V0.E4
	       BCS	 BAUD_SMR_WR1:8 	  ;
	       MOV.B	 R0L,@BRR1		  ;
;;;;;;;;;      BSET	 #RIE,@SCR1		  ; RS422 COMPUTER LINK V0.8
;;;;;;;;;      BSET	 #RE,@SCR1		  ;Enable receive
	       RTS				  ;
BAUD_SMR_WR1:  MOV.B	 R0L,@BRR0		  ;
	       BSET	 #RIE,@SCR0		  ;
	       BSET	 #RE,@SCR0		  ;Enable receive
	       RTS				  ;

; 10mS interrupt enable judge  LB177 jump	  ;
SYS_244_SET:   MOV.W	 @WS047_ADDR,ACC_W	  ;
	       CMP.W	 #H'01,ACC_W              ;
	       BEQ	 TM_LB128_EN:8		  ;
TM_LB_DIS:     BCLR	 LB128_TM_INT		  ;
	       RTS				  ;
TM_LB128_EN:   BLD	 REMOTE_MODE		  ;;V1.2 to prevent remote slave
	       BCC	 TM_LB128_EN1:8 	  ;;run 10ms interrupt
	       BLD	 MASTER_MODE		  ;;
	       BCC	 TM_LB_DIS:8		  ;;
TM_LB128_EN1:  BSET	 LB128_TM_INT		  ;
	       RTS				  ;
;;;;;;; 					  ;
SYS_TO_WS_CHG: JSR	 @HEX_BCD_W		  ;
	       MOV.B	 R4L,ACC		  ;
	       AND.B	 #B'00000111,ACC          ;000-111 BAUDRATE
	       BLD	 #4,R4L 		  ;PARITY 0
	       BST	 #3,ACC 		  ;
	       BLD	 #5,R4L 		  ;PARITY 1
	       BST	 #4,ACC 		  ;
	       BLD	 #0,R4H 		  ;STOP BIT
	       BST	 #5,ACC 		  ;
	       BLD	 #4,R4H 		  ;DATA LENGTH
	       BST	 #7,ACC 		  ;
	       RTS				  ;
; PG port parameter initialize			  ;
PG_INI:        BLD	 PGBRT			  ;
	       BCS	 BR_19200:8		  ;
	       BCLR	 PGBRT_STATUS		  ;;V1.4
	       BSET	 #TE,@SCR0		  ;
	       MOV.W	 @WS041_ADDR,R4 	  ;;TP02
	       BSR	 SYS_TO_WS_CHG		  ;;
	       MOV.B	 ACC,@SYS_226_ADDR	  ;;
	       MOV.L	 #SYS_226_ADDR,DPTR	  ;Data bit
	       MOV.L	 #SMR0,BUFF_PTR1	  ;
	       BSET	 SYS226_OR_236		  ;
	       BSR	 COM_INI_PARA		  ;
	       BCLR	 TXENDF0		  ;;;V0.4 ADD
	       BRA	 INI_PGSTX:8		  ;
BR_19200:      BSET	 PGBRT_STATUS		  ;;V1.4
	       MOV.B	 #23,R0L		  ;19200bps:23
	       MOV.B	 R0L,@BRR0		  ;9600bps:47
	       MOV.B	 #B'00110000,R0L          ;Asyncro mode,8bit,odd,stop1
	       MOV.B	 R0L,@SMR0		  ;
INI_PGSTX:     MOV.L	 #PG_STX,BUFF_PTR1	  ;Initial the buff_pointer
	       MOV.L	 BUFF_PTR1,@FRAME_PTR	  ;
	       BSET	 #TE,@SCR0		  ;Enable transmit
	       BSET	 #RIE,@SCR0		  ;Enable RXI interrupt
	       BSET	 #RE,@SCR0		  ;Enable receive
;;;;;;;        MOV.B	 #H'00,R0L                ;;VF.0
;;;;;;;        MOV.B	 R0L,@SERI_STATUS	  ;
	       RTS				  ;
;;;;;
CLR_X_Y_C:     MOV.B	 #H'00,B_REG             ;;VF.3
	       CMP.B	 #0,REG_R1		 ;;
	       BNE	 CLR_B_LP:8		 ;;
	       RTS				 ;;
CLR_B_LP:      MOV.B	 B_REG,@DPTR
	       INC.L	 #1,DPTR
	       DEC.B	 REG_R1
	       BNE	 CLR_B_LP:8
	       RTS
POW_DOWN_RETAIN: .EQU	 $
X001_X384_JU:  MOV.W	 @WS018_ADDR,ACC_W	 ; X0001-X0384 : 0130
	       CMP.B	 #H'00,ACC_H             ;
	       BEQ	 CLR_X_L:8		 ;
	       DEC.B	 ACC_H			 ;
	       BEQ	 CLR_X_L:8		 ;
	       MOV.L	 #X_STATE,DPTR		 ; 1. 02-XX
	       MOV.B	 ACC_H,REG_R1		 ;
	       BSR	 CLR_X_Y_C		 ;
CLR_X_L:       MOV.B	 #H'00,ACC_H             ; 1. 00-XX
	       MOV.L	 #X_STATE,DPTR		 ; 2. 01-XX
	       ADD.W	 ACC_W,DPTR_LW		 ;
	       MOV.B	 #D'48,REG_R1            ;
	       SUB.B	 ACC,REG_R1		 ;
	       BSR	 CLR_X_Y_C		 ;
Y001_Y384_JU:  MOV.W	 @WS019_ADDR,ACC_W
	       CMP.B	 #H'00,ACC_H
	       BEQ	 CLR_Y_L:8
	       DEC.B	 ACC_H
	       BEQ	 CLR_Y_L:8
	       MOV.L	 #Y_STATE,DPTR
	       MOV.B	 ACC_H,REG_R1
	       BSR	 CLR_X_Y_C
CLR_Y_L:       MOV.B	 #H'00,ACC_H
	       MOV.L	 #Y_STATE,DPTR
	       ADD.W	 ACC_W,DPTR_LW
	       MOV.B	 #D'48,REG_R1
	       SUB.B	 ACC,REG_R1
	       BSR	 CLR_X_Y_C
C001_C2048_JU: MOV.W	 @WS020_ADDR,ACC_W
	       CMP.B	 #H'00,ACC_H
	       BEQ	 CLR_C_L:8
	       DEC.B	 ACC_H
	       BEQ	 CLR_C_L:8
	       MOV.L	 #C_STATE,DPTR
	       MOV.B	 ACC_H,REG_R1
	       BSR	 CLR_X_Y_C
CLR_C_L:       MOV.B	 #H'00,ACC_H
	       MOV.L	 #C_STATE,DPTR
	       ADD.W	 ACC_W,DPTR_LW
	       MOV.B	 #D'255,REG_R1
	;;;;   DEC.B	 ACC			 ;;VF.3
	       SUB.B	 ACC,REG_R1
	       BSR	 CLR_X_Y_C
	       CMP.B	 #H'FF,ACC
	       BEQ	 V1_V256_JU:8
	       MOV.B	 #0,ACC
	       MOV.B	 ACC,@H'000FC25F         ;;VF.3
V1_V256_JU:    MOV.W	 @WS022_ADDR,ACC_W
	       CMP.W	 #H'00,ACC_W
	       BNE	 V256_D2048_JU:8
	       MOV.L	 #V_MEMORY_ADDR,DPTR
	       MOV.W	 #H'00,ACC_W
	       MOV.W	 #D'256,B_W
V1_V256_CLR:   MOV.W	 ACC_W,@DPTR
	       INC.L	 #2,DPTR
	       DEC.W	 #1,B_W
	       BNE	 V1_V256_CLR:8
V256_D2048_JU: MOV.W	 @WS024_ADDR,ACC_W
	       CMP.W	 #H'00,ACC_W
	       BNE	 POW_DOWN_RET:8
	       MOV.L	 #V_MEMORY_ADDR+512,DPTR
V256_D2048_CLR: MOV.W	  ACC_W,@DPTR
	       INC.L	 #2,DPTR
	       CMP.L	 #V0617_ADDR,DPTR	 ;;V1.1
	       BCS	 V256_D2048_CLR:8	 ;;
	       MOV.W	 @WS012_ADDR,B_W	 ;;
	       CMP.W	 #H'0001,B_W             ;;
	       BEQ	 V813_D2048_C1:8	 ;;
	       CMP.W	 #H'0002,B_W             ;;
	       BNE	 V813_D2048_C2:8	 ;;
V813_D2048_C1: MOV.L	 #V0812_ADDR+2,DPTR	 ;;
V813_D2048_C2: MOV.W	 ACC_W,@DPTR		 ;;
	       INC.L	 #2,DPTR		 ;;
	       CMP.L	 #WS_MEMORY_ADDR,DPTR	 ;;
	       BCS	 V813_D2048_C2:8	 ;;
POW_DOWN_RET:  RTS				 ;;
;	   *********************************************
;	*****  Execution I/O modules data Read/Write  *****
;	   *********************************************
;
; ******************************************************************************
; ******************************************************************************
; ******************************************************************************
; ***** Subroutine  : Write data to the output modules
;	Name	    : EXE_OUT_D0			  ;
; Working registr   : ACC, REG_R1, REG_R2, REG_R3, REG_R6 ;
; Working memory    : @DOUT_IO_NO, @COIL_STR_RADDR	  ;
; Used subroutine   :	None				  ;
;						     ;
EXE_OUT_D0:	 MOV.B	@DOUT_IO_NO,REG_R2	     ;
EXE_OUT_D0_A:	 MOV.L	#Y_STATE-1,DPTR 	     ; Output coil start address
EXE_OUT_D0_B:	 ADD.B	REG_R2,DPTR_L		     ; F80,F81 enter point
WR_BYTE_AG1:	 MOV.B	#H'08,REG_R3                 ; High address first write
		 MOV.B	@DPTR,ACC		     ;
		 DEC.B	DPTR_L			     ;
WR_ONE_AG1:	 SHLL.B ACC			     ;
		 BST	IO_DOUT 		     ;
		 BSET	IO_SCLK 		     ;
		 BCLR	IO_SCLK 		     ;
		 DEC.B	REG_R3			     ;
		 BNE	WR_ONE_AG1:8		     ;
		 DEC.B	REG_R2			     ;
		 BNE	WR_BYTE_AG1:8		     ;
		 BCLR	IO_DOUT 		     ;
RET_WR_OUT:	 RTS				     ;
;						     ;
; *****************************************************************************
; ***** Subroutine  : Read data from the input modules
;	Name	    : EXE_INP_D0		    ;
;						    ;
EXE_INP_D0:	 MOV.B	@DINP_IO_NO,REG_R2	    ;
EXE_INP_D0_A:	 MOV.L	#X_STATE,DPTR		    ; Get start to read contact address
EXE_INP_D0_B:	 BSET	IO_DOUBLE_CHK		    ;V0.4
		 BRA	EXE_RD_DR1:8		    ;V0.4
EXE_READ_BYTE:	 BLD	IO_DOUBLE_CHK		    ;V0.4
		 BCC	EXE_RD_DR1:8		    ;V0.4
		 BCLR	IO_LED			    ;V0.4
		 BCLR	IO_DOUBLE_CHK		    ;V0.4
		 BSET	IO_LED			    ;V0.4
EXE_RD_DR1:	 MOV.B	#H'08,REG_R3                ; Low address first read
RD_DATA1:	 BILD	IO_DINP 		    ;
		 BCS	INP_1_1:8		    ;
INP_0_1:	 BIOR	IO_DINP 		    ;
		 BCS	RD_DATA1:8		    ;
		 ROTXR.B ACC			    ;
		 BSET	IO_SCLK 		    ;
		 BCLR	IO_SCLK 		    ;
		 DEC.B	REG_R3			    ;
		 BNE	RD_DATA1:8		    ;
		 BLD	X_NO_REFRESH		    ;;V0.C
		 BCS	INP_BYPASS1:8		    ;;
		 MOV.B	ACC,@DPTR		    ;
INP_BYPASS1:	 INC.B	DPTR_L			    ;
		 DEC.B	REG_R2			    ;
		 BNE	EXE_READ_BYTE:8 	    ;
		 BRA	RET_RD_DATA:8		    ;
INP_1_1:	 BIAND	IO_DINP 		    ;
		 BCC	RD_DATA1:8		    ;
		 ROTXR.B ACC			    ;
		 BSET	IO_SCLK 		    ;
		 BCLR	IO_SCLK 		    ;
		 DEC.B	REG_R3			    ;
		 BNE	RD_DATA1:8		    ;
		 BLD	X_NO_REFRESH		    ;;V0.C
		 BCS	INP_BYPASS2:8		    ;;
		 MOV.B	ACC,@DPTR		    ;
INP_BYPASS2:	 INC.B	DPTR_L			    ;
		 DEC.B	REG_R2			    ;
		 BNE	EXE_READ_BYTE:8 	    ;
RET_RD_DATA:	 BCLR	IO_DOUBLE_CHK		    ;
		 RTS				    ;
; ******************************************************************************
; ***** Subroutine  : Clear all points of output modules ***
;	Name	    : EXE_WR_DR_00
; ***** Subroutine  : Write "data" to all I/O modules
;	Name	    : SEND_ONE			    ;
; Input register    : MAX_IO_NO 		    ;
;						    ;
EXE_WR_DR_00:	 BCLR	IO_DOUT 		    ;
EXE_WR_DR_XX:	 MOV.B	@TOTAL_IO_NO,REG_R2	    ;Max output discrete/register
SEND_ONE:					    ;
WR_BYTE_00_AG:	 MOV.B	#H'08,REG_R3                ; I/O number
WR_DIS_DATA:	 BSET	IO_SCLK 		    ;
		 BCLR	IO_SCLK 		    ;
		 DEC.B	REG_R3			    ; (24)
		 BNE	WR_DIS_DATA:8		    ;
		 DEC.B	REG_R2			    ; (12)
		 BNE	WR_BYTE_00_AG:8 	    ;
		 RTS				    ;
; ***************************************************
; ***** Subroutine  : Calculate I/O module numbers **
;	Name	    : CAL_IO_NO 		  ***
; Return data	    : @TOTAL_IO_NO, @DOUT_IO_NO,    ;
;		    : @DINP_IO_NO, IO_BUS_ERR = 1 IO bus NG
;					      = 0 IO bus OK
CAL_IO_NO:	 MOV.B	#D'16,REG_R2                ;V2.0
		 BCLR	IO_DOUT 		    ;V0.4
		 BSET	IO_LED			    ;
		 BSR	WR_BYTE_00_AG		    ;V0.4
		 MOV.B	#H'55,ACC                   ; First check code 55
		 MOV.B	#H'02,REG_R4                ; Check two times(55,AA)
		 MOV.B	#H'55,REG_R6                ; Check code register
CHK_IO_ENTER:	 MOV.B	#D'16,REG_R2                ; Maximum I/O module number
		 MOV.B	#H'08,REG_R1                ;
WR_CHK_CODE:	 SHLL.B ACC			    ;
		 BST	IO_DOUT 		    ;
		 BSET	IO_SCLK 		    ;
		 BCLR	IO_SCLK 		    ;
		 DEC.B	REG_R1			    ;
		 BNE	WR_CHK_CODE:8		    ;
		 BCLR	IO_DOUT 		    ;
SHIFT_CHK_CODE:  MOV.B	#H'08,REG_R3                ;
RD_CHK_CODE:	 BILD	IO_DINP 		    ;
		 BCS	RD_INP2:8		    ;
RD_INP1:	 BIOR	IO_DINP 		    ;
		 BCS	RD_CHK_CODE:8		    ;
		 ROTXL.B ACC			    ; (LSB -> MSB FIRST)
		 BSET	IO_SCLK 		    ;
		 BCLR	IO_SCLK 		    ;
		 DEC.B	REG_R3			    ;
		 BNE	RD_CHK_CODE:8		    ;
		 CMP.B	REG_R6,ACC		    ; If equal check code
		 BEQ	TOTAL_IO_OK:8		    ;
		 DEC.B	REG_R2			    ;
		 BNE	SHIFT_CHK_CODE:8	    ;
		 BRA	TOTAL_IO_NG		    ; No receive check code
;						    ;
RD_INP2:	 BIAND	IO_DINP 		    ;
		 BCC	RD_CHK_CODE:8		    ;
		 ROTXL.B ACC			    ; (LSB -> MSB FIRST)
		 BSET	IO_SCLK 		    ;
		 BCLR	IO_SCLK 		    ;
		 DEC.B	REG_R3			    ;
		 BNE	RD_CHK_CODE:8		    ;
		 CMP.B	REG_R6,ACC		    ;
		 BEQ	TOTAL_IO_OK:8		    ;
		 DEC.B	REG_R2			    ;
		 BNE	SHIFT_CHK_CODE:8	    ;
		 BRA	TOTAL_IO_NG		    ;No receive check code
TOTAL_IO_OK:	 DEC.B	REG_R4			    ;Check double times
		 BEQ	TOTAL_IO_OK1:8		    ;
		 MOV.B	REG_R2,REG_R5		    ;REG_R5;first time check no
		 MOV.B	#H'AA,ACC                   ;second time check code
		 MOV.B	#H'AA,REG_R6                ;
		 BRA	CHK_IO_ENTER:8		    ;
TOTAL_IO_OK1:	 CMP.B	REG_R2,REG_R5		    ;
		 BNE	TOTAL_IO_NG		    ;
		 MOV.B	#D'17,REG_R5                ;V2.0 19->17
		 SUB.B	REG_R2,REG_R5		    ;
		 MOV.B	REG_R5,@TOTAL_IO_NO	    ;The total I/O number
		 BCLR	IO_BUS_ERR		    ;
;; Calculate the 4021 4094 numbers by this routine  ;
		 BSET	IO_DOUT 		    ;
		 MOV.B	#H'FF,REG_R6                ;REG_R6;check code
CAL_4021_4094:	 BSR	EXE_WR_DR_XX		    ;
		 BSET	PS			    ;
		 BCLR	PS			    ;
		 MOV.L	#IO_CHK_BUFF1,DPTR	    ;
		 MOV.B	@TOTAL_IO_NO,REG_R2	    ;
RD_FF_ST:	 MOV.B	#H'08,REG_R3                ;
RD_FF_CODE:	 BILD	IO_DINP 		    ;
		 BCS	RD_INP21:8		    ;
RD_INP11:	 BIOR	IO_DINP 		    ;
		 BCS	RD_FF_CODE:8		    ;
		 ROTXL.B ACC			    ;
		 BSET	IO_SCLK 		    ;
		 BCLR	IO_SCLK 		    ;
		 DEC.B	REG_R3			    ;
		 BNE	RD_FF_CODE:8		    ;
		 MOV.B	ACC,@DPTR		    ;
		 INC.L	#1,DPTR 		    ;
		 DEC.B	REG_R2			    ;
		 BNE	RD_FF_ST:8		    ;
		 BRA	CAL_IO_NUM:8		    ;
;						    ;
RD_INP21:	 BIAND	IO_DINP 		    ;
		 BCC	RD_FF_CODE:8		    ;
		 ROTXL.B ACC			    ;
		 BSET	IO_SCLK 		    ;
		 BCLR	IO_SCLK 		    ;
		 DEC.B	REG_R3			    ;
		 BNE	RD_FF_CODE:8		    ;
		 MOV.B	ACC,@DPTR		    ;
		 INC.L	#1,DPTR 		    ;
		 DEC.B	REG_R2			    ;
		 BNE	RD_FF_ST:8		    ;
CAL_IO_NUM:	 MOV.B	@TOTAL_IO_NO,REG_R2	    ;
		 MOV.B	#H'00,REG_R0                ; 4094 NUMBER
		 MOV.L	#IO_CHK_BUFF1,DPTR	    ;
		 DEC.B	REG_R2			    ;
		 ADD.B	REG_R2,DPTR_L		    ;
		 INC.B	REG_R2			    ;
CAL_IO_LP:	 MOV.B	@DPTR,ACC		    ;
		 CMP.B	REG_R6,ACC		    ;
		 BEQ	INC_4094:8		    ;
		 BRA	WR_IO_NUM:8		    ;
INC_4094:	 INC.B	REG_R0			    ;
		 DEC.L	#1,DPTR 		    ;
		 DEC.B	REG_R2			    ;
		 BNE	CAL_IO_LP:8		    ;
WR_IO_NUM:	 BLD	IO_DOUBLE_CHK		    ;
		 BCC	DOUBLE_CHK:8		    ;
		 BCLR	IO_DOUBLE_CHK		    ;
		 MOV.B	@DOUT_IO_NO,REG_R1	    ;REG_R1:first time 4094's no
		 CMP.B	REG_R0,REG_R1		    ;REG_R0:this time 4094's no
		 BCC	RE_CAL_IO:8		    ;
		 BEQ	FINAL_NO:8		    ;
		 RTS				    ;
DOUBLE_CHK:	 MOV.B	REG_R0,@DOUT_IO_NO	    ;
		 MOV.B	@TOTAL_IO_NO,REG_R2	    ;
		 SUB.B	REG_R0,REG_R2		    ;
		 MOV.B	REG_R2,@DINP_IO_NO	    ;
		 BSET	IO_DOUBLE_CHK		    ;
		 BCLR	IO_DOUT 		    ;
		 MOV.B	#H'00,REG_R6                ;
		 BRA	CAL_4021_4094		    ;
RE_CAL_IO:	 MOV.B	@TOTAL_IO_NO,REG_R2	    ;reflesh by the last time's
		 MOV.B	REG_R0,@DOUT_IO_NO	    ;4094 number
		 SUB.B	REG_R0,REG_R2		    ;
		 MOV.B	REG_R2,@DINP_IO_NO	    ;
		 RTS				    ;
FINAL_NO:	 MOV.B	REG_R0,@DOUT_IO_NO	    ;
		 MOV.B	@TOTAL_IO_NO,REG_R2	    ;
		 SUB.B	REG_R0,REG_R2		    ;
		 MOV.B	REG_R2,@DINP_IO_NO	    ;
		 RTS				    ;
TOTAL_IO_NG:	 BSET	FAULT_FLAG		    ; TEST
		 BSET	IO_BUS_ERR		    ;
		 RTS				    ;
; *************************************************************
; ***** Subroutine  : Execute I/O reflesh and loop back detect;
;	Name	    : AUTO_EXE_IO			      ;
;	Return data : IO_BUS_ERR = 1 IO bus NG
;				 = 0 IO bus OK
AUTO_EXE_IO:	 BCLR	IO_INT_BIT		    ;To prevent INT LABEL in
		 MOV.B	#H'AA,ACC                   ;F80,F81 spoil the data
		 MOV.B	#H'01,REG_R2                ;Ver0.2
		 MOV.B	#H'08,REG_R3                ;
		 BSR	WR_ONE_AG1		    ;
		 MOV.B	@DOUT_IO_NO,REG_R2	    ;
		 MOV.L	#Y_STATE-1,DPTR 	    ;
		 ADD.B	REG_R2,DPTR_L		    ;
		 DEC.B	REG_R2			    ;
		 BSR	WR_BYTE_AG1		    ;
		 BSET	PS			    ;
		 BCLR	PS			    ;
SAME_TIME_RW:	 MOV.B	@Y_STATE,B_REG		    ;Same time read and write
		 MOV.B	@DINP_IO_NO,REG_R2	    ;
		 MOV.L	#X_STATE,DPTR		    ; Get start to read contact
		 MOV.B	#H'08,REG_R3                ; Low address first read
RD_DATA2:	 BILD	IO_DINP 		    ;
		 BCS	INP_OUT_1:8		    ;
INP_OUT_0:	 BIOR	IO_DINP 		    ;
		 BCS	RD_DATA2:8		    ;
		 ROTXR.B ACC			    ;
		 SHLL.B  B_REG			    ;
		 BST	IO_DOUT 		    ;
		 BSET	IO_SCLK 		    ;
		 BCLR	IO_SCLK 		    ;
		 DEC.B	REG_R3			    ;
		 BNE	RD_DATA2:8		    ;
		 BLD	X_NO_REFRESH		    ;;V0.C
		 BCS	FIRST_RESET:8		    ;;
		 MOV.B	ACC,@DPTR		    ;
		 BRA	FIRST_RESET:8		    ;
INP_OUT_1:	 BIAND	IO_DINP 		    ;
		 BCC	RD_DATA2:8		    ;
		 ROTXR.B ACC			    ;
		 SHLL.B  B_REG			    ;
		 BST	 IO_DOUT		    ;
		 BSET	IO_SCLK 		    ;
		 BCLR	IO_SCLK 		    ;
		 DEC.B	REG_R3			    ;
		 BNE	RD_DATA2:8		    ;
		 BLD	X_NO_REFRESH		    ;;V0.C
		 BCS	FIRST_RESET:8		    ;;
		 MOV.B	ACC,@DPTR		    ;
FIRST_RESET:	 ORC	#B'10000000,CCR             ;;V1.1
		 BLD	IO_INT_BIT		    ;;V0.F6
		 BCC	FIRST_RESET0:8		    ;;V1.1
		 ANDC	#B'01111111,CCR             ;;V1.1
		 BRA	AUTO_EXE_IO		    ;;V1.1
FIRST_RESET0:	 BCLR	IO_LED			    ;V0.4
		 BSET	IO_LED			    ;V0.4
		 ANDC	#B'01111111,CCR             ;;V0.F6
FIRST_RESET1:	 BLD	FIRST_PASS_FG		    ;
		 BCC	NO_OUT_1ST:8		    ;
		 ORC	#B'10000000,CCR             ;;V1.1
		 BLD	IO_INT_BIT		    ; Ver0.2
		 BCC	FIRST_RESET2:8		    ;;V1.1
		 ANDC	#B'01111111,CCR             ;;V1.1
		 BRA	AUTO_EXE_IO		    ;;V1.1
FIRST_RESET2:	 BSET	STB_B			    ;
		 MOV.B	@STB_A,ACC		    ;
		 BCLR	STB_B			    ;
		 ANDC	#B'01111111,CCR             ;;V1.1
NO_OUT_1ST:	 MOV.B	@DINP_IO_NO,REG_R2	    ;
		 MOV.L	#X_STATE,DPTR		    ;
		 INC.L	#1,DPTR 		    ;
		 DEC.B	REG_R2			    ;
	   ;;;	 BLD	IO_INT_BIT		    ;;V0.F6  JUN/3
	   ;;;	 BCS	AUTO_EXE_IO		    ;;
	   ;;;	 BCLR	IO_DOUBLE_CHK		    ;;
		 BSR	EXE_READ_BYTE		    ;
READ_CHK_CODE:	 MOV.B	#1,REG_R2		    ;
		 MOV.L	#CHK_CODE_RADDR,DPTR	    ;
	   ;;;	 BCLR	IO_DOUBLE_CHK		    ;;V0.F6
		 BLD	X_NO_REFRESH		    ;;V0.C
		 BST	X_NO_REFRESH1		    ;;
		 BCLR	X_NO_REFRESH		    ;;
		 BSR	EXE_READ_BYTE		    ;
		 BLD	X_NO_REFRESH1		    ;;
		 BST	X_NO_REFRESH		    ;;
		 BLD	IO_INT_BIT		    ; Ver0.2
		 BCS	AUTO_EXE_IO		    ; Ver0.E4
		 MOV.B	@CHK_CODE_RADDR,ACC	    ;
		 CMP.B	#H'55,ACC                   ;
		 BNE	AUTO_IO_ERR		    ;
AUTO_IO_OK:	 BCLR	IO_BUS_ERR		    ;
		 BLD	X_FILTER		    ;;V1.1
		 BCS	X_FILTER_CHK		    ;;
		 RTS				    ;;
X_FILTER_CHK:	 MOV.L	#X_STATE,DPTR		    ;;
		 BLD	X1_LAST 		    ;;V1.1
		 BST	X_BIT_BUF		    ;;
		 BXOR	#0,@DPTR		    ;;
		 BCC	X2_CHK:8		    ;;
		 BLD	#0,@DPTR		    ;;
		 BST	X1_LAST 		    ;;
		 BLD	X_BIT_BUF		    ;;
		 BST	#0,@DPTR		    ;;
X2_CHK: 	 BLD	X2_LAST 		    ;;
		 BST	X_BIT_BUF		    ;;
		 BXOR	#1,@DPTR		    ;;
		 BCC	X3_CHK:8		    ;;
		 BLD	#1,@DPTR		    ;;
		 BST	X2_LAST 		    ;;
		 BLD	X_BIT_BUF		    ;;
		 BST	#1,@DPTR		    ;;
X3_CHK: 	 BLD	X3_LAST 		    ;;
		 BST	X_BIT_BUF		    ;;
		 BXOR	#2,@DPTR		    ;;
		 BCC	X4_CHK:8		    ;;
		 BLD	#2,@DPTR		    ;;
		 BST	X3_LAST 		    ;;
		 BLD	X_BIT_BUF		    ;;
		 BST	#2,@DPTR		    ;;
X4_CHK: 	 BLD	X4_LAST 		    ;;
		 BST	X_BIT_BUF		    ;;
		 BXOR	#3,@DPTR		    ;;
		 BCC	X_F_END:8		    ;;
		 BLD	#3,@DPTR		    ;;
		 BST	X4_LAST 		    ;;
		 BLD	X_BIT_BUF		    ;;
		 BST	#3,@DPTR		    ;;
X_F_END:	 RTS				    ;
AUTO_IO_ERR:	 BSET	FAULT_FLAG		    ;
		 BSET	IO_BUS_ERR		    ;
		 RTS				    ;
;******************************************************************************
;******************	  IMIB1_INT		*******************************
;******************************************************************************
;/* Module Name:   IMIB1_INT()
;   Description:   Interrupt handling processing for HSC,mode3,4,5 INT mode
IMIB1_INT:     BCLR	 #1,@TSR1
	       ANDC	 #H'7F,CCR               ;;V1.1
	       BLD	 INT11_BUSY		 ;bypass re-enter
	       BCC	 IMIB1_GO:8
	       RTE
IMIB1_GO:      PUSH.L	 ER0
	       PUSH.L	 ER1
	       PUSH.L	 ER2
	       PUSH.L	 ER3
	       PUSH.L	 ER4
	       PUSH.L	 ER5
	       PUSH.L	 ER6
	       BSET	 INT11_BUSY
	       BCLR	 #1,@TIER1		 ; NEW ADD
	       MOV.B	 @INT_KIND,ACC		 ; PUSH MAIN_INT_BIT
	       MOV.B	 ACC,@INT_KIND_BUFF1	 ;
	       MOV.B	 #H'11,ACC
	       MOV.B	 ACC,@INT_KIND
	       JMP	 @BUFF_PUSH
IMIB1_GO1:     MOV.W	 @LB111_ADDR,R3
	       CMP.W	 #END_ADDR,R3
	       BEQ	 IMIB1_GO2:8
	       SHLL.W	 R3
	       SHLL.W	 R3
	       SHLL.W	 R3
	       MOV.L	 #MACHINE_CODE,ER2
	       ADD.W	 R3,R2
	       MOV.W	 #0,R0
	       MOV.W	 #0,R1
	   ;;; ANDC	 #H'7E,CCR      ;;;V0.7 TP02
	       BSET	 USER_WDT_ERR	       ;;
	       JMP	 @ER2
IMIB1_GO2:     JMP	 @BUFF_POP
IMIB1_GO3:     MOV.B	 @INT_KIND_BUFF1,ACC
	       MOV.B	 ACC,@INT_KIND
	       BCLR	 INT11_BUSY
	       BCLR	 USER_WDT_ERR	       ;;
	       BSET	 #1,@TIER1	       ; NEW ADD  V0.7
	       POP.L	 ER6
	       POP.L	 ER5
	       POP.L	 ER4
	       POP.L	 ER3
	       POP.L	 ER2
	       POP.L	 ER1
	       POP.L	 ER0
	       RTE
;******************************************************************************
;******************	  IMIA2_INT		*******************************
;******************************************************************************
;/* Module Name:   IMIA2_INT()
;   Description:
IMIA2_INT:     BCLR	 #0,@TSR2
	       ANDC	 #H'7F,CCR               ;;V1.1
	       BLD	 INT22_BUSY
	       BCC	 IMIA2_GO:8
	       RTE
IMIA2_GO:      PUSH.L	 ER0
	       PUSH.L	 ER1
	       PUSH.L	 ER2
	       PUSH.L	 ER3
	       PUSH.L	 ER4
	       PUSH.L	 ER5
	       PUSH.L	 ER6
	       BSET	 INT22_BUSY
	       BCLR	 #0,@TIER2		 ; NEW ADD
	       MOV.B	 @INT_KIND,ACC		 ; PUSH MAIN_INT_BIT
	       MOV.B	 ACC,@INT_KIND_BUFF2	 ;
	       MOV.B	 #H'22,ACC
	       MOV.B	 ACC,@INT_KIND
	       JMP	 @BUFF_PUSH
IMIA2_GO1:     MOV.W	 @LB111_ADDR,R3
	       CMP.W	 #END_ADDR,R3
	       BEQ	 IMIA2_GO2:8
	       SHLL.W	 R3
	       SHLL.W	 R3
	       SHLL.W	 R3
	       MOV.L	 #MACHINE_CODE,ER2
	       ADD.W	 R3,R2
	       MOV.W	 #0,R0
	       MOV.W	 #0,R1
	       ANDC	 #H'7E,CCR
	       BSET	 USER_WDT_ERR	       ;;V0.F6
	       JMP	 @ER2	      ;
IMIA2_GO2:     JMP	 @BUFF_POP    ;
IMIA2_GO3:     MOV.B	 @INT_KIND_BUFF2,ACC
	       MOV.B	 ACC,@INT_KIND
	       BCLR	 INT22_BUSY
	       BCLR	 USER_WDT_ERR	       ;;V0.F6	??????
	       BSET	 #0,@TIER2	       ; NEW ADD V0.7 TP02
	       POP.L	 ER6
	       POP.L	 ER5
	       POP.L	 ER4
	       POP.L	 ER3
	       POP.L	 ER2
	       POP.L	 ER1
	       POP.L	 ER0
	       RTE
;******************************************************************************
;******************	  IMIB2_INT		*******************************
;******************************************************************************
;/* Module Name:   IMIB2_INT()
;   Description:   Interrupt handling processing for PRESET(INC-1)
IMIB2_INT:     BLD	 IMIB2_LB		 ;
	       BCC	 IMIB2_RESET		 ;
IMIB2_INT1:    BCLR	 #1,@TSR2
	       ANDC	 #H'7F,CCR               ;;V1.1
	       BLD	 INT33_BUSY
	       BCC	 IMIB2_GO:8
	       RTE
IMIB2_GO:      PUSH.L	 ER0
	       PUSH.L	 ER1
	       PUSH.L	 ER2
	       PUSH.L	 ER3
	       PUSH.L	 ER4
	       PUSH.L	 ER5
	       PUSH.L	 ER6
	       BSET	 INT33_BUSY
	       BCLR	 #1,@TIER2		 ; NEW ADD
	       MOV.B	 @INT_KIND,ACC		 ; PUSH MAIN_INT_BIT
	       MOV.B	 ACC,@INT_KIND_BUFF3	 ;
	       MOV.B	 #H'33,ACC
	       MOV.B	 ACC,@INT_KIND
	       JMP	 @BUFF_PUSH
IMIB2_GO1:     MOV.W	 @LB112_ADDR,R3
	       CMP.W	 #END_ADDR,R3
	       BEQ	 IMIB2_GO2:8
	       SHLL.W	 R3
	       SHLL.W	 R3
	       SHLL.W	 R3
	       MOV.L	 #MACHINE_CODE,ER2
	       ADD.W	 R3,R2
	       MOV.W	 #0,R0
	       MOV.W	 #0,R1
	       ANDC	 #H'7E,CCR
	       BSET	 USER_WDT_ERR	       ;
	       JMP	 @ER2
IMIB2_GO2:     JMP	 @BUFF_POP
IMIB2_GO3:     MOV.B	 @INT_KIND_BUFF3,ACC
	       MOV.B	 ACC,@INT_KIND
	       BCLR	 INT33_BUSY
	       BCLR	 USER_WDT_ERR	       ;
	       BSET	 #1,@TIER2	       ; NEW ADD  V0.7 TP02
	       POP.L	 ER6
	       POP.L	 ER5
	       POP.L	 ER4
	       POP.L	 ER3
	       POP.L	 ER2
	       POP.L	 ER1
	       POP.L	 ER0
	       RTE
IMIB2_RESET:   PUSH.W	 ACC_W			 ;
	       MOV.W	 #H'0000,ACC_W           ;
	       MOV.W	 ACC_W,@TCNT1		 ;
IMIB2_RET:     BCLR	 #1,@TSR2		 ;
	       POP.W	 ACC_W			 ;
	       RTE				 ;
;******************************************************************************
;******************	  OVIE2_INT		*******************************
;******************************************************************************
;/* Module Name:   OVIE2_INT()
;   Description:   Interrupt handling processing for over/underflow ENC-1
OVIE2_INT:     PUSH.W	 ACC_W
	       MOV.W	 @TCNT2,ACC_W
	       CMP.W	 #H'8000,ACC_W
	       BCC	 UNDER_FLOW_I:8
OVER_FLOW_I:   MOV.W	 #H'0000,ACC_W           ;TCNT2,FFFF -> 0000
	       BLD	 TB0
	       BST	 #0,ACC
	       BLD	 TB1
	       BST	 #1,ACC
	       INC.W	 #1,ACC_W
	       BLD	 #0,ACC
	       BST	 TB0
	       BLD	 #1,ACC
	       BST	 TB1
	       BRA	 TB_CB_COMP:8
UNDER_FLOW_I:  MOV.W	 #H'0000,ACC_W           ;TCNT2,0000 -> FFFF
	       BLD	 TB0
	       BST	 #0,ACC
	       BLD	 TB1
	       BST	 #1,ACC
	       DEC.W	 #1,ACC_W
	       BLD	 #0,ACC
	       BST	 TB0
	       BLD	 #1,ACC
	       BST	 TB1
TB_CB_COMP:    BLD	 TB0
	       BXOR	 CB0
	       BCS	 OVIE2_RET:8
	       BLD	 TB1
	       BXOR	 CB1
	       BCS	 OVIE2_RET:8
	       BCLR	 #0,@TSR2		 ;;V1.5
	       BSET	 #0,@TIER2
	       BCLR	 #2,@TSR2
	       POP.W	 ACC_W
	       RTE
OVIE2_RET:     BCLR	 #2,@TSR2		 ;Clear OVIE2 flag
	       BCLR	 #0,@TIER2
	       BCLR	 #0,@TSR2		 ;;V1.5
	       POP.W	 ACC_W
	       RTE
;******************************************************************************
;******************	  IMIB3_INT		*******************************
;******************************************************************************
;/* Module Name:   IMIB3_INT()			 ;
;   Description:   Interrupt handling processing for HRST-1 for ENC-1
IMIB3_INT:     BLD	 IMIB3_LB		 ;
	       BCC	 IMIB3_RESET		 ;
IMIB3_INT1:    BCLR	 #1,@TSR3
	       ANDC	 #H'7F,CCR               ;;V1.1
	       BLD	 INT44_BUSY
	       BCC	 IMIB3_GO:8
	       RTE
IMIB3_GO:      PUSH.L	 ER0
	       PUSH.L	 ER1
	       PUSH.L	 ER2
	       PUSH.L	 ER3
	       PUSH.L	 ER4
	       PUSH.L	 ER5
	       PUSH.L	 ER6
	       BSET	 INT44_BUSY
	       BCLR	 #1,@TIER3		 ; NEW ADD
	       MOV.B	 @INT_KIND,ACC		 ; PUSH MAIN_INT_BIT
	       MOV.B	 ACC,@INT_KIND_BUFF4	 ;
	       MOV.B	 #H'44,ACC
	       MOV.B	 ACC,@INT_KIND
	       JMP	 @BUFF_PUSH
IMIB3_GO1:     BLD	 IMIB3_LB112
	       BCS	 IMIB3_GO11:8
	       MOV.W	 @LB113_ADDR,R3
	       BRA	 IMIB3_GO12:8
IMIB3_GO11:    MOV.W	 @LB112_ADDR,R3
IMIB3_GO12:    CMP.W	 #END_ADDR,R3
	       BEQ	 IMIB3_GO2:8
	       SHLL.W	 R3
	       SHLL.W	 R3
	       SHLL.W	 R3
	       MOV.L	 #MACHINE_CODE,ER2
	       ADD.W	 R3,R2
	       MOV.W	 #0,R0
	       MOV.W	 #0,R1
	       ANDC	 #H'7E,CCR
	       BSET	 USER_WDT_ERR	       ;
	       JMP	 @ER2
IMIB3_GO2:     JMP	 @BUFF_POP
IMIB3_GO3:     MOV.B	 @INT_KIND_BUFF4,ACC
	       MOV.B	 ACC,@INT_KIND
	       BCLR	 INT44_BUSY
	       BCLR	 USER_WDT_ERR	       ;
	       BSET	 #1,@TIER3	       ; NEW ADD V0.7 TP02
	       POP.L	 ER6
	       POP.L	 ER5
	       POP.L	 ER4
	       POP.L	 ER3
	       POP.L	 ER2
	       POP.L	 ER1
	       POP.L	 ER0
	       RTE
IMIB3_RESET:   BCLR	 #1,@TSR3		 ;
	       BLD	 TCLK_D 		 ;
	       BCC	 IMIB3_RET:8		 ;
	       PUSH.W	 ACC_W			 ;
	       MOV.W	 #H'0000,ACC_W           ;
	       MOV.W	 ACC_W,@TCNT2		 ;
	       BCLR	 TB1			 ;
	       BCLR	 TB0			 ;
       ;;;;;   BCLR	 #0,@TIER2		 ;;;TEST  V0.7 TP02
	       POP.W	 ACC_W			 ;
IMIB3_RET:     RTE				 ;
;******************************************************************************
;******************	  IMIB4_INT  (V0.5)	*******************************
;******************************************************************************
;/* Module Name:   IMIB4_INT()
;   Description:   Interrupt handling processing module for HRST-1(INC-2)
IMIB4_INT:     BLD	 IMIB4_LB		 ;
	       BCC	 IMIB4_RESET		 ;
IMIB4_INT1:    BCLR	 #1,@TSR4
	       ANDC	 #H'7F,CCR               ;;V1.1
	       BLD	 INT55_BUSY
	       BCC	 IMIB4_GO:8
	       RTE
IMIB4_GO:      PUSH.L	 ER0
	       PUSH.L	 ER1
	       PUSH.L	 ER2
	       PUSH.L	 ER3
	       PUSH.L	 ER4
	       PUSH.L	 ER5
	       PUSH.L	 ER6
	       BSET	 INT55_BUSY
	       BCLR	 #1,@TIER4		 ; NEW ADD
	       MOV.B	 @INT_KIND,ACC		 ; PUSH MAIN_INT_BIT
	       MOV.B	 ACC,@INT_KIND_BUFF5	 ;
	       MOV.B	 #H'55,ACC
	       MOV.B	 ACC,@INT_KIND
	       JMP	 @BUFF_PUSH
IMIB4_GO1:     BLD	 IMIB4_LB113
	       BCS	 IMIB4_GO11:8
	       MOV.W	 @LB114_ADDR,R3
	       BRA	 IMIB4_GO12:8
IMIB4_GO11:    MOV.W	 @LB113_ADDR,R3
IMIB4_GO12:    CMP.W	 #END_ADDR,R3
	       BEQ	 IMIB4_GO3:8
	       SHLL.W	 R3
	       SHLL.W	 R3
	       SHLL.W	 R3
	       MOV.L	 #MACHINE_CODE,ER2
	       ADD.W	 R3,R2
	       MOV.W	 #0,R0
	       MOV.W	 #0,R1
	       ANDC	 #H'7E,CCR
	       BSET	 USER_WDT_ERR	       ;
	       JMP	 @ER2
IMIB4_GO2:     JMP	 @BUFF_POP
IMIB4_GO3:     MOV.B	 @INT_KIND_BUFF5,ACC
	       MOV.B	 ACC,@INT_KIND
	       BCLR	 INT55_BUSY
	       BCLR	 USER_WDT_ERR	       ;
	       BSET	 #1,@TIER4	       ; NEW ADD  V0.7 TP02
	       POP.L	 ER6
	       POP.L	 ER5
	       POP.L	 ER4
	       POP.L	 ER3
	       POP.L	 ER2
	       POP.L	 ER1
	       POP.L	 ER0
	       RTE
IMIB4_RESET:   PUSH.W	 ACC_W			 ;
	       MOV.W	 #H'0000,ACC_W           ;
	       MOV.W	 ACC_W,@TCNT3		 ;
	       BCLR	 #1,@TSR4		 ;
	       POP.W	 ACC_W			 ;
	       RTE				 ;
;******************************************************************************
;******************	  SERIAL_PORT1_INT	*******************************
;******************************************************************************
;/* Module Name:   SERIAL_PORT1_INT()
;   Description:   Interrupt handling processing module for receive support
;		   tool's message.  PC(master) <---->JW10(slave)
;		   SERI_STATUS:  b7    b6    b5    b4	 b3    b2    b1    b0
;		   9600,8,O,1
;   Require Module:
;   Require Reg.:  BUF_CNT1, BUFF_PTR(ER6), DATA_BUFF(R2L)
;   Input:	   BUF_CNT1, BUFF_PTR
;   Return: SERI_STATUS:
;	 b7   ³ b6    ³ b5    ³ b4    ³  b3    ³  b2  ³  b1   ³
;      TXENDF0³RXENDF0³PARI_E ³       ³        ³      ³OP_MODE³
SERIAL_ERI1:   .EQU	 $			 ;
	       BLD	 EN_422_LINK		 ;
	       BCC	 ERR_COMPUTER:8 	 ;
	      ;BCLR	 #RDRF,@SSR1		 ; V0.F5
	       BSET	 #MPIE,@SCR1		 ; reset the MPIE, prevent
	       BRA	 PER_ERR:8		 ; receive error data
ERR_COMPUTER:  BCLR	 REQ_START_FG1	;;V1.64
	       BCLR	 RXENDF1	;;V1.64
PER_ERR:       BLD	 #3,@SSR1
	       BCC	 FER_ERR:8
	       BCLR	 #3,@SSR1
	     ;;RTE		    ;;V1.1
FER_ERR:       BLD	 #4,@SSR1
	       BCC	 ORER_ERR:8
	       BCLR	 #4,@SSR1
	     ;;RTE		    ;;V1.1
ORER_ERR:      BLD	 #5,@SSR1
	       BCC	 SER_ERR_RET:8
	       BCLR	 #5,@SSR1
SER_ERR_RET:   BCLR	 #RDRF,@SSR1		  ;;V1.1
	       RTE
;--- Computer link receive interrupt ----
SERIAL_RXI1:   PUSH.W	 ACC_W
	       PUSH.L	 DPTR
	       BLD	 EN_422_LINK
	       BCS	 SERIAL_RXI2
	       BLD	 REQ_START_FG1
	       BCS	 NON_FIRST_BYTE1:8
	       MOV.L	 #ASCII1_3A,DPTR	    ;;
	       MOV.B	 @RDR1,ACC
	       BCLR	 #RDRF,@SSR1		    ;
	       CMP.B	 #ASCII_3AH,ACC 	    ;V0.5
	       BEQ	 SERIAL_RXI1G		    ;V0.5
	    ;; BRA	 JUDGE_OK1RET:8 	    ;V0.5
	       BCLR	 RXENDF1		    ;;V1.64
	       BCLR	 REQ_START_FG1		    ;;V1.64
	       BRA	 JUDGE_OK1RET		    ;;V1.64
SERIAL_RXI1G:  MOV.B	 ACC,@DPTR
	       INC.L	 #1,DPTR
	       MOV.L	 DPTR,@BUFF_PTR
	       BSET	 REQ_START_FG1
	       BRA	 JUDGE_OK1:8
NON_FIRST_BYTE1:
	       MOV.B	 @RDR1,ACC		    ;Get receive data
	       BCLR	 #RDRF,@SSR1		    ;
	       MOV.L	 @BUFF_PTR,DPTR 	    ;
LOCK_CHK1:     CMP.L	 #ASCII2_3A,DPTR	    ;;;V1.5
	       BNE	 LOCK_CHK2:8		    ;;;
	       CMP.B	 #ASCII_3AH,ACC 	    ;;;
	       BEQ	 LOCK_CHK3:8		    ;;;
	       BRA	 LOCK_ERR:8		    ;;;
LOCK_CHK2:     CMP.B	 #ASCII_3AH,ACC 	    ;;;
	       BNE	 LOCK_CHK3:8		    ;;;
LOCK_ERR:      BCLR	 RXENDF1		    ;;;
	       BCLR	 REQ_START_FG1		    ;;;
LOCK_CHK3:     MOV.B	 ACC,@DPTR		    ;
	       INC.L	 #1,DPTR		    ;
	       MOV.L	 DPTR,@BUFF_PTR 	    ;
JUDGE_OK1:     CMP.B	 #H'0D,ACC                  ;Is the end byte ?(Yes,Z=1)
	       BEQ	 RECEIVE_OVER1:8	    ;
JUDGE_OK1RET:  POP.L	 DPTR
	       POP.W	 ACC_W
NXT_BYTE:      RTE				    ;
RECEIVE_OVER1: BSET	 RXENDF1		    ;Set bit the receive flag
	       BCLR	 REQ_START_FG1
	       POP.L	 DPTR
	       POP.W	 ACC_W
	       RTE

;=== Data link receive interrupt ====		 ;
SERIAL_RXI2:   BLD	 #MPB,@SSR1		 ;;
	       BCC	 NON_ID_BYTE		 ;;
	       BLD	 REMOTE_MODE		 ;;
	       BCS	 SERIAL_OLD2		 ;;
	       MOV.B	 @RDR1,ACC		 ;;
	       BRA	 CHECK_ID		 ;;
SERIAL_OLD2:   MOV.B	 @RDR1,ACC		 ;
	       CMP.B	 #H'99,ACC               ; Check if broadcast message
	       BNE	 CHECK_ID:8		 ;
	       BSET	 ALL_NODE_FG		 ; Broadcast message
	       BRA	 OWN_ID_ST:8		 ;
CHECK_ID:      BCLR	 ALL_NODE_FG		 ; Not broadcast message
	       MOV.B	 @WS045_ADDR+1,ACC_H	 ;
	       CMP.B	 ACC,ACC_H		 ; Check if own ID
	       BEQ	 OWN_ID_ST:8		 ;
	       BCLR	 #RDRF,@SSR1		 ;
	       BSET	 #MPIE,@SCR1		 ; Not own ID, reset the MPIE
	       POP.L	 DPTR			 ; again
	       POP.W	 ACC_W			 ;
	       RTE				 ;
OWN_ID_ST:     BLD	 REMOTE_MODE		 ;;
	       BCS	 OWN_ID_OLD		 ;;
	       BSET	 RX_IN_ON		 ;;
	       BLD	 MASTER_MODE		 ;;
	       BCS	 ID_00_LP:8		 ;;
	       BCLR	 SLAVE_OK_IN		 ;;V1.2
	       BLD	 EXCHANGE_ON		 ;;
	       BCC	 RX_S1:8		 ;;
	       MOV.L	 #S8_RX_BUFF,DPTR	 ;;****PSEUDO ADDRESS*****
	       BSET	 DATA_WORK_FG1		 ;;
	       BSET	 SLAVE_XHG_S8		 ;;
	       BRA	 OWN_ID_NEW		 ;;
ID_00_LP:      MOV.B	 @SLAVE_RING,ACC_H	 ;;
RX_SL1:        CMP.B	 #H'01,ACC_H             ;;
	       BNE	 RX_SL2:8		 ;;
RX_S1:	       MOV.L	 #S1_RX_BUFF,DPTR	 ;;
	       BSET	 DATA_WORK_FG1		 ;;
	       BRA	 OWN_ID_NEW:8		 ;;
RX_SL2:        CMP.B	 #H'02,ACC_H             ;;
	       BNE	 RX_SL3:8		 ;;
	       MOV.L	 #S2_RX_BUFF,DPTR	 ;;
	       BSET	 DATA_WORK_FG2		 ;;
	       BRA	 OWN_ID_NEW:8		 ;;
RX_SL3:        CMP.B	 #H'03,ACC_H             ;;
	       BNE	 RX_SL4:8		 ;;
	       MOV.L	 #S3_RX_BUFF,DPTR	 ;;
	       BSET	 DATA_WORK_FG3		 ;;
	       BRA	 OWN_ID_NEW:8		 ;;
RX_SL4:        CMP.B	 #H'04,ACC_H             ;;
	       BNE	 RX_SL5:8		 ;;
	       MOV.L	 #S4_RX_BUFF,DPTR	 ;;
	       BSET	 DATA_WORK_FG4		 ;;
	       BRA	 OWN_ID_NEW:8		 ;;
RX_SL5:        CMP.B	 #H'05,ACC_H             ;;
	       BNE	 RX_SL6:8		 ;;
	       MOV.L	 #S5_RX_BUFF,DPTR	 ;;
	       BSET	 DATA_WORK_FG5		 ;;
	       BRA	 OWN_ID_NEW:8		 ;;
RX_SL6:        CMP.B	 #H'06,ACC_H             ;;
	       BNE	 RX_SL7:8		 ;;
	       MOV.L	 #S6_RX_BUFF,DPTR	 ;;
	       BSET	 DATA_WORK_FG6		 ;;
	       BRA	 OWN_ID_NEW:8		 ;;
RX_SL7:        MOV.L	 #S7_RX_BUFF,DPTR	 ;;
	       BSET	 DATA_WORK_FG7		 ;;
OWN_ID_NEW:    BCLR	 #RDRF,@SSR1		 ;;
	       MOV.B	 ACC,@DPTR		 ;;
	       INC.L	 #1,DPTR		 ;;
	       MOV.L	 DPTR,@BUFF_PTR 	 ;;
	       BSET	 REQ_START_FG1		 ;;
	       BRA	 NEXT_BYTE2		 ;;
OWN_ID_OLD:    BCLR	 #RDRF,@SSR1		 ;
	       MOV.B	 ACC,@ASCII1_3A 	 ;
	       MOV.L	 #ASCII1_3A,DPTR	 ;;
	       INC.L	 #1,DPTR		 ;;
	       MOV.L	 DPTR,@BUFF_PTR 	 ;;
	       BSET	 REQ_START_FG1		 ;ID byte coming
	       BRA	 NEXT_BYTE2:8		 ;
NON_ID_BYTE:   BLD	 REQ_START_FG1		 ;
	       BCC	 CMD_DATA_ST:8		 ;
	       BCLR	 REQ_START_FG1		 ;
	       MOV.B	 @RDR1,ACC		 ;Get receive data
	       BCLR	 #RDRF,@SSR1		 ;
	       MOV.L	 @BUFF_PTR,DPTR 	 ;;
	       MOV.B	 ACC,@DPTR		 ;
	       MOV.B	 ACC,@BYTE_NO		 ;Byte number
	       INC.L	 #1,DPTR		 ;
	       MOV.L	 DPTR,@BUFF_PTR 	 ;
	       BRA	 NEXT_BYTE2:8		 ;
CMD_DATA_ST:   MOV.B	 @RDR1,ACC		 ;
	       BCLR	 #RDRF,@SSR1		 ;
	       MOV.L	 @BUFF_PTR,DPTR 	 ;
	       MOV.B	 ACC,@DPTR		 ;
	       INC.L	 #1,DPTR		 ;
	       MOV.L	 DPTR,@BUFF_PTR 	 ;
	       MOV.B	 @BYTE_NO,ACC		 ;
	       DEC.B	 ACC			 ;
	       BEQ	 RECEIVE_OVER2:8	 ;
	       MOV.B	 ACC,@BYTE_NO		 ;
NEXT_BYTE2:    POP.L	 DPTR			 ;
	       POP.W	 ACC_W			 ;
	       RTE				 ;
RECEIVE_OVER2: BLD	 ALL_NODE_FG		 ;
	       BCC	 NOT_BROAD_R:8		 ;
	       BCLR	 ALL_NODE_FG		 ;
	       MOV.W	 @COM_BUF1,ACC_W	 ;
	       MOV.W	 ACC_W,@BROAD_MESSAGE	 ;Broadcast message temp buffer
	       BSET	 RXENDF3		 ;Broadcast message bit
	       BRA	 NOT_BROAD_R1		 ;
NOT_BROAD_R:   BLD	 REMOTE_MODE		 ;;
	       BCC	 NOT_BROAD_NEW		 ;;
	       BSET	 RXENDF2		 ;Set bit the receive flag
NOT_BROAD_R1:  BSET	 #MPIE,@SCR1		 ;Reset the ID detection bit
	       POP.L	 DPTR			 ;
	       POP.W	 ACC_W			 ;
	       RTE				 ;
NOT_BROAD_NEW: BSET	 #MPIE,@SCR1		 ;;
	       BCLR	 RX_IN_ON		 ;;
	       BLD	 MASTER_MODE		 ;;
	       BCS	 END_M_LINK:8		 ;;
	       BSET	 SLAVE_OK_IN		 ;;indicate slave has data in
	       BLD	 EXCHANGE_ON		 ;;
	       BCC	 END_S_LINK:8		 ;;
	       BSET	 RX_MAIN_TX		 ;;REQUEST MAIN TO TRANSMIT
	       BRA	 M_STOP_COMM		 ;;
END_S_LINK:    MOV.B	 #H'01,ACC               ;;
	       MOV.B	 ACC,@SLAVE_RING	 ;;
	       BRA	 M_TX_INT		 ;;
END_M_LINK:    MOV.B	 @SLAVE_RING,ACC	 ;;
	       INC.B	 ACC			 ;;
	       MOV.B	 ACC,@SLAVE_RING	 ;;
	       MOV.B	 @WS046_ADDR+1,ACC_H	 ;;
	       CMP.B	 ACC_H,ACC		 ;;
	       BHI	 M_STOP_COMM		 ;;
M_TX_INT:      JSR	 @TX_SHOOT		 ;;
M_STOP_COMM:   POP.L	 DPTR			 ;;
	       POP.W	 ACC_W			 ;;
	       RTE				 ;;
;--- Computer link transmit interrupt ----	 ;
SERIAL_TXI1:   PUSH.W	 ACC_W			 ;
	       PUSH.L	 DPTR			 ;
	       BLD	 EN_422_LINK		 ;
	       BCS	 SERIAL_TXI2:8		 ;
	       MOV.L	 @BUFF_PTR,DPTR 	 ;
	       INC.L	 #1,DPTR		 ;
	       MOV.L	 DPTR,@BUFF_PTR 	 ;
	       MOV.B	 @DPTR,ACC		 ;
	       CMP.B	 #ASCII_CR,ACC		 ;
	       BNE	 TX_MORE1:8		 ;
	       BCLR	 #TIE,@SCR1		 ;
	       BSET	 #TEIE,@SCR1		 ;;V1.3 TEST
TX_MORE1:      MOV.B	 ACC,@TDR1		 ;
	       BCLR	 #TDRE,@SSR1		 ;
END_TX1:       POP.L	 DPTR			 ;
	       POP.W	 ACC_W			 ;
	       RTE				 ;
;=== Data link transmit interrupt ===		 ;
SERIAL_TXI2:   MOV.L	 @BUFF_PTR,DPTR 	 ;
	       INC.L	 #1,DPTR		 ;
	       MOV.L	 DPTR,@BUFF_PTR 	 ;
	       MOV.B	 @BYTE_NO,ACC_H 	 ;
	       DEC.B	 ACC_H			 ;
	       BNE	 TX_MORE2:8		 ;
	       BCLR	 #TIE,@SCR1		 ;
TX_MORE2:      MOV.B	 ACC_H,@BYTE_NO 	 ;
	       MOV.B	 @DPTR,ACC		 ;
	       MOV.B	 ACC,@TDR1		 ;
	       BCLR	 #MPBT,@SSR1		 ;
	       BCLR	 #TDRE,@SSR1		 ;
	       POP.L	 DPTR			 ;
	       POP.W	 ACC_W			 ;
	       RTE				 ;
						 ;
;--- Computer link transmit end ----		 ;
SERIAL_TEI1:   BLD	 EN_422_LINK		 ;
	       BCS	 SERIAL_TEI2:8		 ;
	   ;;; BCLR	 EN_422 		 ;Change to receive mode
	       BCLR	 #TEIE,@SCR1		 ;
	       BSET	 #RIE,@SCR1		 ;
	       BSET	 #RE,@SCR1		 ;
	       BCLR	 EN_422 		 ;;;V1.1
	       RTE				 ;
;==== Data link transmit end  =====		 ;
SERIAL_TEI2:   BCLR	 #TEIE,@SCR1		 ;
	       BSET	 #RIE,@SCR1		 ;Enable receive interrupt
	       BCLR	 TX_OUT_ON		 ;
	       BCLR	 EN_422 		 ;Change to receive mode
	       BSET	 #RE,@SCR1		 ;
	       BSET	 #MPIE,@SCR1		 ;
	       RTE				 ;
;******************************************************************************
;******************	  SERIAL_PORT0_INT	*******************************
;******************************************************************************
;/* Module Name:   SERIAL_PORT0_INT()
;   Description:   Interrupt handling processing module for receive support
;		   tool's message.  PU03(master) <---->TP20(slave)
;		   SERI_STATUS:  b7    b6    b5    b4	 b3    b2    b1    b0
;		   19200,8,O,1
;   Require Module:
;   Require Reg.:  BUF_CNT1, BUFF_PTR(ER6), DATA_BUFF(R2L)
;   Input:	   BUF_CNT1, BUFF_PTR
;   Return: SERI_STATUS:
;	 b7   ³ b6    ³ b5    ³ b4    ³  b3    ³  b2  ³  b1   ³
;	      ³RXENDF0³PARI_E ³       ³        ³      ³OP_MODE³
SERIAL_ERI0:   .EQU	 $			    ;
	   ;   PUSH.W	 ACC_W			    ;; VF.4
	   ;   MOV.B	 #3,ACC 		    ;;
	   ;   MOV.B	 ACC,@BYTE_COUNTER	    ;;
	   ;   POP.W	 ACC_W			    ;;
	       BLD	 #3,@SSR0		    ;PER
	       BCC	 SERIAL_ERI01:8 	    ;
	       BCLR	 #3,@SSR0		    ;
	   ;;; RTE				    ;;;V1.1
SERIAL_ERI01:  BLD	 #4,@SSR0		    ;FER
	       BCC	 SERIAL_ERI02:8 	    ;
	       BCLR	 #4,@SSR0		    ;
	   ;;; RTE				    ;;;V1.1
SERIAL_ERI02:  BLD	 #5,@SSR0		    ;ORER
	       BCC	 SERIAL_ERI03:8 	    ;
	       BCLR	 #5,@SSR0		    ;
SERIAL_ERI03:  BCLR	 #RDRF,@SSR0		    ;;V1.1
	       RTE				    ;
SERIAL_RXI0:   .EQU	 $			    ;
	       PUSH.W	 ACC_W			    ;
	       PUSH.L	 DPTR			    ;
	       BLD	 PGBRT			    ; V0.4
	       BCS	 SERIAL_RXI0PG		    ; TP02
;;;;;PG PORT COMPUTER LINK;;;;;;;;;;;;;;;;	    ;
	       BLD	 REQ_START_FG0		    ;
	       BCS	 NON_FIRST_BYTE0:8	    ;
	       MOV.L	 #PG_STX,DPTR		    ;
	       MOV.B	 @RDR0,ACC		    ;
	       BCLR	 #RDRF,@SSR0		    ;
	       BLD	 F58_RXD_EN		    ;;;;
	       BCS	 F58_RX_LP:8		    ;;;;
	       CMP.B	 #ASCII_3AH,ACC 	    ;
	       BNE	 JUDGE_OK_RET:8 	    ;
F58_RX_LP:     MOV.B	 ACC,@DPTR		    ;;;;
	       INC.L	 #1,DPTR		    ;
	       MOV.L	 DPTR,@FRAME_PTR	    ;
	       BSET	 REQ_START_FG0
	       BRA	 JUDGE_OK0:8		    ;
NON_FIRST_BYTE0:				    ;
	       MOV.B	 @RDR0,ACC		    ;
	       BCLR	 #RDRF,@SSR0		    ;
	       MOV.L	 @FRAME_PTR,DPTR
	       MOV.B	 ACC,@DPTR		    ;
	       INC.L	 #1,DPTR		    ;
	       MOV.L	 DPTR,@FRAME_PTR	    ;
JUDGE_OK0:     BLD	 F58_RXD_EN		    ;;;;
	       BCC	 JUDGE_OK01:8		    ;;;;
	       BLD	 F58_RXD_BYTE		    ;;;;
	       BCC	 CHK_F58_ENDC:8 	    ;;;;
	       MOV.B	 @BYTE_COUNTER,ACC	    ;;;;
	       DEC.B	 ACC			    ;;;;
	       MOV.B	 ACC,@BYTE_COUNTER	    ;;;;
	       BEQ	 RECEIVE_OVER0:8	    ;;;;
	       BRA	 JUDGE_OK_RET:8 	    ;;;;
CHK_F58_ENDC:  MOV.B	 @F58_END_CODE,ACC_H	    ;;;;
	       CMP.B	 ACC,ACC_H		    ;;;;
	       BEQ	 RECEIVE_OVER0:8	    ;;;;
	       BRA	 JUDGE_OK_RET:8 	    ;;;;
JUDGE_OK01:    CMP.B	 #H'0D,ACC                  ;Is the end byte ?(Yes,Z=1)
	       BEQ	 RECEIVE_OVER0:8	    ;
JUDGE_OK_RET:  POP.L	 DPTR			    ;
	       POP.W	 ACC_W			    ;
NXT_BYTE0:     RTE				    ;
RECEIVE_OVER0: BSET	 RXENDF0		    ;Set bit the receive flag
	       BCLR	 REQ_START_FG0		    ;;;PG PORT FOR COMMPUTER
	       BCLR	 BYTE_CNT_OK		    ;;TP02
	       BCLR	 COM_NOISE_BIT		    ;;VF.4
	       BSET	 #TE,@SCR0		    ;;;;;V1.6
RECEIVE_OVER0E: POP.L	  DPTR			    ;
	       POP.W	 ACC_W			    ;
	       RTE				    ;
;========  PG port PG protocol link ==========	    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SERIAL_RXI0PG: BLD	 REQ_START_FG0		    ;
	       BCS	 NON_FIRST_BYTE0PG:8	    ;
	       MOV.L	 #PG_STX,DPTR		    ;
	       MOV.B	 @RDR0,ACC		    ;
	       BCLR	 #RDRF,@SSR0		    ;
SERIAL_RX_S:   MOV.B	 ACC,@DPTR		    ;
	       INC.L	 #1,DPTR		    ;
	       MOV.L	 DPTR,@FRAME_PTR	    ;
	       BSET	 REQ_START_FG0		    ;
	       BCLR	 BYTE_CNT_OK		    ;;
	       BRA	 JUDGE_OK0RET:8 	    ;
NON_FIRST_BYTE0PG:	 .EQU	$		    ;
	       MOV.B	 @RDR0,ACC		    ;
	       BCLR	 #RDRF,@SSR0		    ;
	       MOV.L	 @FRAME_PTR,DPTR	    ;
	       MOV.B	 ACC,@DPTR		    ;
	       INC.L	 #1,DPTR		    ;
	       MOV.L	 DPTR,@FRAME_PTR	    ;
	       BLD	 BYTE_CNT_OK		    ;
	       BCS	 JUDGE_OK0PG:8		    ;
	       BSET	 BYTE_CNT_OK		    ;
	       INC.B	 ACC			    ;
	       MOV.B	 ACC,@BYTE_COUNTER	    ;
	       ADD.B	 #5,ACC 		    ;;VF.4
	       MOV.B	 ACC,@COM_TIME_OUT	    ;;VF.4
	       MOV.B	 #0,ACC 	      ;;V1.5
	       MOV.B	 ACC,@COM_TIME_OUT+1  ;;
	       MOV.L	 #SC017_ADDR,DPTR     ;;V1.5
	       BLD	 #5,@DPTR	      ;;SC022
	       BCC	 SC022_OFF:8	      ;;
	       MOV.W	 #755,ACC_W	      ;;
	       MOV.W	 ACC_W,@COM_TIME_OUT  ;;
SC022_OFF:     BSET	 COM_NOISE_BIT		    ;;VF.4
	       BRA	 JUDGE_OK0RET		    ;;VF.4
;RESET_FRAME:	BCLR	  BYTE_CNT_OK		     ;
;		MOV.L	  #PG_STX,DPTR		     ;
;		BRA	  SERIAL_RX_S:8 	     ;
JUDGE_OK0PG:   MOV.B	 @BYTE_COUNTER,ACC	    ;
	       DEC.B	 ACC			    ;
	       MOV.B	 ACC,@BYTE_COUNTER	    ;
	       CMP.B	 #0,ACC 		    ;;VF.4
	       BEQ	 RECEIVE_OVER0		    ;
JUDGE_OK0RET:  POP.L	 DPTR			    ;
	       POP.W	 ACC_W			    ;
NXT_BYTEPG:    RTE				    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;						    ;
SERIAL_TXI0:   .EQU	 $			    ;
	       PUSH.W	 ACC_W			    ;
	       PUSH.L	 DPTR			    ;
	       MOV.L	 @FRAME_PTR,DPTR	    ;
	       INC.L	 #1,DPTR		    ;
	       MOV.L	 DPTR,@FRAME_PTR	    ;
	       MOV.B	 @DPTR,ACC		    ;
	       BLD	 PGBRT			    ;
	       BCS	 SERIAL_TXIPG:8 	    ; TP02
	       BLD	 F59_TXD_EN		    ;;;;;;
	       BCS	 SERIAL_TXIPG:8 	    ;;;;;;
	       CMP.B	 #ASCII_CR,ACC		    ;
	       BNE	 TX_MORE0:8		    ;
	       BCLR	 #TIE,@SCR0		    ;
	       BSET	 #TEIE,@SCR0		    ;;TEST
	       BRA	 TX_MORE0:8		    ;
SERIAL_TXIPG:  MOV.B	 @BYTE_COUNTER,ACC_H	    ;
	       DEC.B	 ACC_H			    ;
	       MOV.B	 ACC_H,@BYTE_COUNTER	    ;
	       BNE	 TX_MORE0:8		    ;
	       BCLR	 #TIE,@SCR0		    ;
	       BSET	 #TEIE,@SCR0		    ;;TEST
TX_MORE0:      MOV.B	 ACC,@TDR0		    ;
	       BCLR	 #TDRE,@SSR0		    ;
END_TX0:       POP.L	 DPTR			    ;
	       POP.W	 ACC_W			    ;
	       RTE				    ;
SERIAL_TEI0:   .EQU	 $			    ;
	       BLD	 PGBRT			    ;;;;;;
	       BCS	 SERIAL_TEI01:8 	    ;;;;;;
	       BLD	 F59_TXD_EN		    ;;;;;;
	       BCS	 SERIAL_TEI02:8 	    ;;;;;;
SERIAL_TEI01:  BCLR	 #TEIE,@SCR0		    ;
	       BSET	 #RE,@SCR0		    ;;;NEW
	       RTE				    ;
SERIAL_TEI02:  PUSH.L	 DPTR			    ;;;;;;
	       MOV.L	 #SC073_ADDR,DPTR	    ;;;;;;
	       BSET	 #2,@DPTR		    ;;;;;;
	       BCLR	 #TEIE,@SCR0		    ;;;;;;
	       BSET	 #RE,@SCR0		    ;;;;;;
	   ;;; BCLR	 #TE,@SCR0		    ;;V1.4///V1.6
	       BCLR	 F59_TXD_EN		    ;;V0.9
	       POP.L	 DPTR			    ;;;;;;
	       RTE				    ;;;;;;
	       .END				    ;
