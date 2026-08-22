	       .CPU	 300HA
	       .EXPORT	 DLINK_ST,SLAVE_TTS_TASK,DATA_ON_INIT
	       .EXPORT	 SLAVE_PS_TASK,SLAVE_STB_TASK,TX_TO_SLAVE
	       .EXPORT	 DLINK_OWN_ID,HIGH_SPEED,DUMP_LOOP
	       .EXPORT	 BUFF_PUSH,BUFF_POP,PRG_PTY_CHK,SYS_RANGE_CHK
	       .EXPORT	 DLINK_XHG_DATA,TX_SHOOT,S_RXIN_CHK,S_TXOUT_CHK
	       .EXPORT	 RTC_CMD,RTC_BURST,S_TXOUT_SNR,S_RXIN_CHK1,REFRESH_07340
	       .EXPORT	 DUMP_EEPROM,LOAD_EEPROM,DELAY_10MS,DELAY_1MS
	       .EXPORT	 DA_CONV,HSC_INIT,DUMP_FLASH,LOAD_FLASH
	       .EXPORT	 AD_CONV1,AD_CONV2    ;V1.61
	       .EXPORT	 WR_RD_AD_COMD1,WR_RD_AD_COMD,AD_CONV_TIME1,AD_CONV_TIME ;V1.61
	       .EXPORT	 FLASH_CHECKSUM,EEPROM_CHECKSUM,DUMP_FLASH_SYS
	       .IMPORT	 COMM_PG1,EXE_OUT_D0,EXE_INP_D0,WAIT_RTM
	       .IMPORT	 NEXT_IN_NODE,DLINK_ENTER,REMOTE_TMOUT,BCD_HEX_B,HEX_BCD_B
	       .IMPORT	 TIME_INT_ST1,TIMER_B22,HEX_BCD_W,SWAP_ACC
	       .IMPORT	 IMIB1_GO3,IMIA2_GO3,IMIB2_GO3,IMIB3_GO3,IMIB4_GO3
	       .IMPORT	 IMIB1_GO1,IMIA2_GO1,IMIB2_GO1,IMIB3_GO1,IMIB4_GO1
	       .IMPORT	 DPTR_PADR1,INST_TO_ASCII,PRG_MEM_WR_128
	       .IMPORT	 SYS_234_SET,SYS_244_SET,EXE_INP_D0_B
	       .INCLUDE  "H83005.INC"
	       .INCLUDE  "SYMBOL02.INC"
;;;;;;	       .INCLUDE  "SYM2.INC"
;;;;;;	       .OUTPUT	 DBG
	   ;;; .DEBUG	 ON
	       .SECTION  COMM,CODE,LOCATE=H'0000D800  ;;E000
	       ;1995/8/28
DLINK_ST:      BCLR	 RXENDF3		 ;Broadcast message start
	       BLD	 REMOTE_MODE		 ;If not remote mode
	       BCC	 NON_CMD1		 ;then by pass
	       MOV.B	 @BROAD_MESSAGE,ACC	 ;
PS_CHK:        CMP.B	 #DCMD_PS,ACC		 ;
	       BNE	 STB_CHK:8		 ;
	       BRA	 PS_STRT		 ;
STB_CHK:       CMP.B	 #DCMD_STB,ACC		 ;
	       BNE	 NON_CMD:8		 ;
	       BRA	 STB_STRT		 ;

DLINK_OWN_ID:  BCLR	 RXENDF2		 ;None broadcast message
	       BLD	 MASTER_MODE		 ;
	       BCC	 DLINK_GO:8		 ;When master station halt,
	       BLD	 RUN_FLAG		 ;stop the data link
	       BCS	 DLINK_GO:8		 ;
	       JMP	 @COMM_PG1		 ;
DLINK_GO:      MOV.B	 @COM_BUF1,ACC		 ;
RTM_CHK:       CMP.B	 #DCMD_RTM,ACC		 ;
	       BNE	 TTS_CHK:8		 ;
	       BRA	 RTM_STRT		 ;
TTS_CHK:       CMP.B	 #DCMD_TTS,ACC		 ;
	       BNE	 NON_CMD:8		 ;
	       BLD	 MASTER_MODE		 ;;V1.1 by S,ITO
	       BCS	 NON_CMD:8		 ;;
	       BRA	 TTS_STRT		 ;
NON_CMD:       BLD	 REMOTE_MODE		 ;;data link no need to do
	       BCC	 NON_CMD1:8		 ;;
	       BSET	 DLINK_ERR		 ;;V0.F1
	       BSET	 FAULT_FLAG		 ;;V0.F1
NON_CMD1:      JMP	 @COMM_PG1		 ;
; Start data link exchange data, process in master (new) ;
DLINK_XHG_DATA: 				 ;
	       MOV.L	 #SC105_ADDR,BUFF_PTR2	 ;flag pointer(buff_ptr2)
	       MOV.B	 @DATA_W_FLAG,REG_R1	 ;working flag(reg_r1)
RIN_CHK1:      BLD	 #1,REG_R1		 ;
	       BCS	 RIN_SLAVE1:8		 ;V0.D ADD :8
	       BCLR	 #1,@BUFF_PTR2		 ;clr slave 1 flag
	       BRA	 RIN_CHK2:8		 ;V0.D ADD :8
RIN_SLAVE1:    MOV.L	 #S1_RX_BUFF,DPTR	 ;slave 1 receive buffer
	       MOV.B	 #1,REG_R0		 ;slave 1 identification
	       BSR	 RX_RECEIVE		 ;
RIN_CHK2:      BLD	 #2,REG_R1		 ;
	       BCS	 RIN_SLAVE2:8		 ;
	       BCLR	 #2,@BUFF_PTR2		 ;clr slave 2 flag
	       BRA	 RIN_CHK3:8		 ;
RIN_SLAVE2:    MOV.L	 #S2_RX_BUFF,DPTR	 ;slave 2 receive buffer
	       MOV.B	 #2,REG_R0		 ;slave 2 identification
	       BSR	 RX_RECEIVE		 ;
RIN_CHK3:      BLD	 #3,REG_R1		 ;
	       BCS	 RIN_SLAVE3:8		 ;
	       BCLR	 #3,@BUFF_PTR2		 ;clr slave 3 flag
	       BRA	 RIN_CHK4:8		 ;
RIN_SLAVE3:    MOV.L	 #S3_RX_BUFF,DPTR	 ;slave 3 receive buffer
	       MOV.B	 #3,REG_R0		 ;slave 3 identification
	       BSR	 RX_RECEIVE		 ;
RIN_CHK4:      BLD	 #4,REG_R1		 ;
	       BCS	 RIN_SLAVE4:8		 ;
	       BCLR	 #4,@BUFF_PTR2		 ;clr slave 4 flag
	       BRA	 RIN_CHK5:8		 ;
RIN_SLAVE4:    MOV.L	 #S4_RX_BUFF,DPTR	 ;slave 4 receive buffer
	       MOV.B	 #4,REG_R0		 ;slave 4 identification
	       BSR	 RX_RECEIVE		 ;
RIN_CHK5:      BLD	 #5,REG_R1		 ;
	       BCS	 RIN_SLAVE5:8		 ;
	       BCLR	 #5,@BUFF_PTR2		 ;clr slave 5 flag
	       BRA	 RIN_CHK6:8		 ;
RIN_SLAVE5:    MOV.L	 #S5_RX_BUFF,DPTR	 ;slave 5 receive buffer
	       MOV.B	 #5,REG_R0		 ;slave 5 identification
	       BSR	 RX_RECEIVE		 ;
RIN_CHK6:      BLD	 #6,REG_R1		 ;
	       BCS	 RIN_SLAVE6:8		 ;
	       BCLR	 #6,@BUFF_PTR2		 ;clr slave 6 flag
	       BRA	 RIN_CHK7:8		 ;
RIN_SLAVE6:    MOV.L	 #S6_RX_BUFF,DPTR	 ;slave 6 receive buffer
	       MOV.B	 #6,REG_R0		 ;slave 6 identification
	       BSR	 RX_RECEIVE		 ;
RIN_CHK7:      BLD	 #7,REG_R1		 ;
	       BCS	 RIN_SLAVE7:8		 ;
	       BCLR	 #7,@BUFF_PTR2		 ;clr slave 7 flag
	       BRA	 TX_MOVE_DATA:8 	 ;
RIN_SLAVE7:    MOV.L	 #S7_RX_BUFF,DPTR	 ;slave 7 receive buffer
	       MOV.B	 #7,REG_R0		 ;slave 7 identification
	       BSR	 RX_RECEIVE		 ;
TX_MOVE_DATA:  BSR	 REFRESH_07340		 ;;V0.F5 use REFRESH_07340 to
	       MOV.B	 @WS046_ADDR+1,ACC	 ;	 save memory
	       CMP.B	 #H'01,ACC               ;
	       BEQ	 TOUT_SLAVE1		 ;
	       CMP.B	 #H'02,ACC               ;
	       BEQ	 TOUT_SLAVE2		 ;
	       CMP.B	 #H'03,ACC               ;
	       BEQ	 TOUT_SLAVE3		 ;
	       CMP.B	 #H'04,ACC               ;
	       BEQ	 TOUT_SLAVE4		 ;
	       CMP.B	 #H'05,ACC               ;
	       BEQ	 TOUT_SLAVE5		 ;
	       CMP.B	 #H'06,ACC               ;
	       BEQ	 TOUT_SLAVE6		 ;
DATA_ON_INIT:					 ;When power on data link data
TOUT_SLAVE7:   MOV.B	 #H'07,REG_R1            ;initial
	       MOV.L	 #S7_TX_BUFF,DPTR	 ;
	       MOV.L	 #DL_S7_TR,BUFF_PTR1	 ;
	       MOV.L	 #DL_S7_TV,BUFF_PTR2	 ;
	       BSR	 TX_TRANSMIT		 ;
TOUT_SLAVE6:   MOV.B	 #H'06,REG_R1            ;
	       MOV.L	 #S6_TX_BUFF,DPTR	 ;
	       MOV.L	 #DL_S6_TR,BUFF_PTR1	 ;
	       MOV.L	 #DL_S6_TV,BUFF_PTR2	 ;
	       BSR	 TX_TRANSMIT		 ;
TOUT_SLAVE5:   MOV.B	 #H'05,REG_R1            ;
	       MOV.L	 #S5_TX_BUFF,DPTR	 ;
	       MOV.L	 #DL_S5_TR,BUFF_PTR1	 ;
	       MOV.L	 #DL_S5_TV,BUFF_PTR2	 ;
	       BSR	 TX_TRANSMIT		 ;
TOUT_SLAVE4:   MOV.B	 #H'04,REG_R1            ;
	       MOV.L	 #S4_TX_BUFF,DPTR	 ;
	       MOV.L	 #DL_S4_TR,BUFF_PTR1	 ;
	       MOV.L	 #DL_S4_TV,BUFF_PTR2	 ;
	       BSR	 TX_TRANSMIT		 ;
TOUT_SLAVE3:   MOV.B	 #H'03,REG_R1            ;
	       MOV.L	 #S3_TX_BUFF,DPTR	 ;
	       MOV.L	 #DL_S3_TR,BUFF_PTR1	 ;
	       MOV.L	 #DL_S3_TV,BUFF_PTR2	 ;
	       BSR	 TX_TRANSMIT		 ;
TOUT_SLAVE2:   MOV.B	 #H'02,REG_R1            ;
	       MOV.L	 #S2_TX_BUFF,DPTR	 ;
	       MOV.L	 #DL_S2_TR,BUFF_PTR1	 ;
	       MOV.L	 #DL_S2_TV,BUFF_PTR2	 ;
	       BSR	 TX_TRANSMIT		 ;
TOUT_SLAVE1:   MOV.B	 #H'01,REG_R1            ;
	       MOV.L	 #S1_TX_BUFF,DPTR	 ;
	       MOV.L	 #DL_S1_TR,BUFF_PTR1	 ;
	       MOV.L	 #DL_S1_TV,BUFF_PTR2	 ;
	       BSR	 TX_TRANSMIT		 ;
	       MOV.B	 #H'01,ACC               ;slave ring reset to 1
	       MOV.B	 ACC,@SLAVE_RING	 ;
	       RTS				 ;
TX_TRANSMIT:   MOV.B	 #H'00,B_REG             ;
	       MOV.B	 REG_R1,@DPTR		 ;reg_r1:DID, dptr:frame ptr
	       ADD.B	 REG_R1,B_REG		 ;
	       INC.L	 #1,DPTR		 ;
	       MOV.B	 #D'15,ACC               ;BNO  11->15 TP02
	       MOV.B	 ACC,@DPTR		 ;
	       ADD.B	 ACC,B_REG		 ;
	       INC.L	 #1,DPTR		 ;
	       MOV.B	 #DCMD_STS,ACC		 ;STS
	       MOV.B	 ACC,@DPTR		 ;
	       ADD.B	 ACC,B_REG		 ;
	       INC.L	 #1,DPTR		 ;
	       MOV.B	 #H'00,ACC               ;SID  V0.F6
	       MOV.B	 ACC,@DPTR		 ;
	       ADD.B	 ACC,B_REG		 ;
	       INC.L	 #1,DPTR		 ;
STS_TO_BUFF:   MOV.B	 #H'04,REG_R1            ;
STS_TO_S_LP:   MOV.B	 @BUFF_PTR1,ACC 	 ;buff_ptr1:data buffer ptr
	       MOV.B	 ACC,@DPTR		 ;
	       ADD.B	 ACC,B_REG		 ;
	       INC.L	 #1,DPTR		 ;
	       INC.L	 #1,BUFF_PTR1		 ;
	       DEC.B	 REG_R1 		 ;
	       BNE	 STS_TO_S_LP:8		 ;
STS_TO_BUFF1:  MOV.B	 #H'08,REG_R1            ;
STS_TO_S_LP1:  MOV.B	 @BUFF_PTR2,ACC 	 ;
	       MOV.B	 ACC,@DPTR		 ;
	       ADD.B	 ACC,B_REG		 ;
	       INC.L	 #1,DPTR		 ;
	       INC.L	 #1,BUFF_PTR2		 ;
	       DEC.B	 REG_R1 		 ;
	       BNE	 STS_TO_S_LP1:8 	 ;
	       MOV.B	 B_REG,@DPTR		 ;checksum value
	       RTS

RX_RECEIVE:    MOV.B	 #D'16,REG_R2            ; 12->16  TP02
	       MOV.B	 #H'00,B_REG             ;
	       MOV.L	 DPTR,BUFF_PTR1 	 ;
	       INC.L	 #2,DPTR		 ;
	       MOV.B	 @DPTR,ACC		 ;
	       CMP.B	 #DCMD_SNR,ACC		 ;check if slave not ready
	       BEQ	 RX_CHKSUM_ERR		 ;
	       CMP.B	 #DCMD_STM,ACC		 ;check if STM command correct
	       BNE	 RX_CHKSUM_ERR		 ;
	       DEC.L	 #2,DPTR		 ;
RIN_CHK_SUM:   MOV.B	 @DPTR,ACC		 ;
	       ADD.B	 ACC,B_REG		 ;
	       INC.L	 #1,DPTR		 ;
	       DEC.B	 REG_R2 		 ;
	       BNE	 RIN_CHK_SUM:8		 ;
	       MOV.B	 @DPTR,ACC		 ;
	       CMP.B	 B_REG,ACC		 ;
	       BNE	 RX_CHKSUM_ERR		 ;
	       MOV.L	 BUFF_PTR1,DPTR 	 ;
	       INC.L	 #2,DPTR		 ;data start address
	       INC.L	 #1,DPTR		 ;
STM_S1:        CMP.B	 #H'01,REG_R0            ;
	       BNE	 STM_S2:8		 ;
	       MOV.B	 @DPTR,ACC		 ;;V0.F6
	       CMP.B	 REG_R0,ACC		 ;;
	       BNE	 RX_CHKSUM_ERR		 ;;
	       INC.L	 #1,DPTR		 ;;
	       MOV.L	 #DL_S1_RR,BUFF_PTR1	 ;
	       MOV.L	 #DL_S1_RV,BUFF_PTR2	 ;
	       BRA	 STM_GO 		 ;
STM_S2:        CMP.B	 #H'02,REG_R0            ;
	       BNE	 STM_S3:8		 ;
	       MOV.B	 @DPTR,ACC		 ;;V0.F6
	       CMP.B	 REG_R0,ACC		 ;;
	       BNE	 RX_CHKSUM_ERR		 ;;
	       INC.L	 #1,DPTR		 ;;
	       MOV.L	 #DL_S2_RR,BUFF_PTR1	 ;
	       MOV.L	 #DL_S2_RV,BUFF_PTR2	 ;
	       BRA	 STM_GO 		 ;
STM_S3:        CMP.B	 #H'03,REG_R0            ;
	       BNE	 STM_S4:8		 ;
	       MOV.B	 @DPTR,ACC		 ;;V0.F6
	       CMP.B	 REG_R0,ACC		 ;;
	       BNE	 RX_CHKSUM_ERR		 ;;
	       INC.L	 #1,DPTR		 ;;
	       MOV.L	 #DL_S3_RR,BUFF_PTR1	 ;
	       MOV.L	 #DL_S3_RV,BUFF_PTR2	 ;
	       BRA	 STM_GO:8		 ;
STM_S4:        CMP.B	 #H'04,REG_R0            ;
	       BNE	 STM_S5:8		 ;
	       MOV.B	 @DPTR,ACC		 ;;V0.F6
	       CMP.B	 REG_R0,ACC		 ;;
	       BNE	 RX_CHKSUM_ERR		 ;;
	       INC.L	 #1,DPTR		 ;;
	       MOV.L	 #DL_S4_RR,BUFF_PTR1	 ;
	       MOV.L	 #DL_S4_RV,BUFF_PTR2	 ;
	       BRA	 STM_GO:8		 ;
STM_S5:        CMP.B	 #H'05,REG_R0            ;
	       BNE	 STM_S6:8		 ;
	       MOV.B	 @DPTR,ACC		 ;;V0.F6
	       CMP.B	 REG_R0,ACC		 ;;
	       BNE	 RX_CHKSUM_ERR		 ;;
	       INC.L	 #1,DPTR		 ;;
	       MOV.L	 #DL_S5_RR,BUFF_PTR1	 ;
	       MOV.L	 #DL_S5_RV,BUFF_PTR2	 ;
	       BRA	 STM_GO:8		 ;
STM_S6:        CMP.B	 #H'06,REG_R0            ;
	       BNE	 STM_S7:8		 ;
	       MOV.B	 @DPTR,ACC		 ;;V0.F6
	       CMP.B	 REG_R0,ACC		 ;;
	       BNE	 RX_CHKSUM_ERR		 ;;
	       INC.L	 #1,DPTR		 ;;
	       MOV.L	 #DL_S6_RR,BUFF_PTR1	 ;
	       MOV.L	 #DL_S6_RV,BUFF_PTR2	 ;
	       BRA	 STM_GO:8		 ;
STM_S7:        MOV.B	 @DPTR,ACC		 ;;V0.F6
	       CMP.B	 REG_R0,ACC		 ;;
	       BNE	 RX_CHKSUM_ERR		 ;;
	       INC.L	 #1,DPTR		 ;;
	       MOV.L	 #DL_S7_RR,BUFF_PTR1	 ;
	       MOV.L	 #DL_S7_RV,BUFF_PTR2	 ;
STM_GO:        MOV.B	 #H'04,REG_R2            ;
STM_GO_LOOP:   MOV.B	 @DPTR,ACC		 ;
	       MOV.B	 ACC,@BUFF_PTR1 	 ;
	       INC.L	 #1,DPTR		 ;
	       INC.L	 #1,BUFF_PTR1		 ;
	       DEC.B	 REG_R2 		 ;
	       BNE	 STM_GO_LOOP:8		 ;
STM_GO1:       MOV.B	 #H'08,REG_R2            ;
STM_GO_LOOP1:  MOV.B	 @DPTR,ACC		 ;
	       MOV.B	 ACC,@BUFF_PTR2 	 ;
	       INC.L	 #1,DPTR		 ;
	       INC.L	 #1,BUFF_PTR2		 ;
	       DEC.B	 REG_R2 		 ;
	       BNE	 STM_GO_LOOP1:8 	 ;
	       MOV.L	 #SC105_ADDR,BUFF_PTR2	 ;;V0.C
	       BSET	 REG_R0,@BUFF_PTR2	 ;
	       RTS				 ;
RX_CHKSUM_ERR: MOV.L	 #SC105_ADDR,BUFF_PTR2	 ;;V0.C
	       BCLR	 REG_R0,@BUFF_PTR2	 ;
	       RTS				 ;
;-Start transmit out by master (new)		 ;
;-Mode:data link				 ;
TX_SHOOT:      MOV.B	 @SLAVE_RING,ACC	 ;
TX1:	       CMP.B	 #H'01,ACC               ;
	       BNE	 TX2:8			 ;
	       BLD	 RUN_OUT		 ; FOR 1624/1424 ONLY
	       BCC	 TX0			 ;
	       MOV.L	 #S1_TX_BUFF,DPTR	 ;
	       BRA	 TX_OUT_STRT		 ;
TX2:	       CMP.B	 #H'02,ACC               ;
	       BNE	 TX3:8			 ;
	       MOV.L	 #S2_TX_BUFF,DPTR	 ;
	       BRA	 TX_OUT_STRT		 ;
TX3:	       CMP.B	 #H'03,ACC               ;
	       BNE	 TX4:8			 ;
	       MOV.L	 #S3_TX_BUFF,DPTR	 ;
	       BRA	 TX_OUT_STRT		 ;
TX4:	       CMP.B	 #H'04,ACC               ;
	       BNE	 TX5:8			 ;
	       MOV.L	 #S4_TX_BUFF,DPTR	 ;
	       BRA	 TX_OUT_STRT		 ;
TX5:	       CMP.B	 #H'05,ACC               ;
	       BNE	 TX6:8			 ;
	       MOV.L	 #S5_TX_BUFF,DPTR	 ;
	       BRA	 TX_OUT_STRT		 ;
TX6:	       CMP.B	 #H'06,ACC               ;
	       BNE	 TX7:8			 ;
	       MOV.L	 #S6_TX_BUFF,DPTR	 ;
	       BRA	 TX_OUT_STRT		 ;
TX7:	       CMP.B	 #H'07,ACC               ;
	       BNE	 TX0:8			 ;
	       MOV.L	 #S7_TX_BUFF,DPTR	 ;
	       BRA	 TX_OUT_STRT		 ;
TX0:	       MOV.L	 #S1_TX_BUFF,DPTR	 ;
	       MOV.B	 #D'3,ACC                ;V1.2
	       MOV.B	 ACC,@BYTE_NO		 ;
	       BRA	 TX_OUT_STRT1		 ;V0.F6
TX_OUT_STRT:   MOV.B	 #D'16,ACC               ;;Very important 12->16 TP02
	       MOV.B	 ACC,@BYTE_NO		 ;;
TX_OUT_STRT1:  MOV.B	 @DPTR,ACC		 ;
	       MOV.L	 DPTR,@BUFF_PTR 	 ;
	       MOV.B	 ACC,@TDR1		 ;
	       BSET	 TX_OUT_ON		 ;;
	       BSET	 #MPBT,@SSR1		 ;Set ID transmit bit
	       BCLR	 #RIE,@SCR1		 ;
	       BCLR	 #RE,@SCR1		 ;
	       BSET	 EN_422 		 ;Turn 422 to transmit mode
	       BCLR	 #TDRE,@SSR1		 ;
	       BSET	 #TIE,@SCR1		 ;
	       BSET	 #TEIE,@SCR1		 ;
	       MOV.B	 @TIME_BASE1,ACC	 ;reset timeout timer
	       MOV.B	 ACC,@DLINK_TIMEOUT	 ;
	       RTS				 ;
;-Slave station receive data (new)		 ;
;-Mode:data link				 ;
S_RXIN_CHK:    MOV.L	 #S1_RX_BUFF,DPTR	 ;
S_RXIN_CHK1:   MOV.L	 DPTR,BUFF_PTR2 	 ;;push the receive buffer
	       MOV.B	 #D'16,REG_R1            ;V0.F6  12->16 TP02
	       MOV.B	 #H'00,B_REG             ;
S_RXIN_LP:     MOV.B	 @DPTR,ACC		 ;
	       ADD.B	 ACC,B_REG		 ;
	       INC.L	 #1,DPTR		 ;
	       DEC.B	 REG_R1 		 ;
	       BNE	 S_RXIN_LP:8		 ;
	       MOV.B	 @DPTR,ACC		 ;
	       CMP.B	 B_REG,ACC		 ;
	       BEQ	 S_RXIN_STS:8		 ;
S_RXIN_ERR:    MOV.L	 #SC105_ADDR,DPTR	 ;
	       BCLR	 #0,@DPTR		 ; TEST
	       RTS				 ;
S_RXIN_STS:    MOV.L	 BUFF_PTR2,DPTR 	 ;
	       INC.L	 #2,DPTR		 ;
	       MOV.B	 @DPTR,ACC		 ;;V0.F5 to check STS command
	       CMP.B	 #DCMD_STS,ACC		 ;;
	       BNE	 S_RXIN_ERR:8		 ;;
	       INC.L	 #1,DPTR		 ;;
	       MOV.B	 @DPTR,ACC		 ;;V0.F6 to check SID command
	       CMP.B	 #H'00,ACC               ;;
	       BNE	 S_RXIN_ERR:8		 ;;
S_RXIN_OK:     MOV.L	 #SC105_ADDR,DPTR	 ;
	       BSET	 #0,@DPTR		 ;
	       INC.L	 #2,BUFF_PTR2		 ;
	       INC.L	 #2,BUFF_PTR2		 ;V0.F6
	       MOV.L	 #DL_S1_TR,BUFF_PTR1	 ;
	       MOV.B	 #D'4,REG_R1             ;
S_RXIN_RD:     MOV.B	 @BUFF_PTR2,ACC 	 ;
	       MOV.B	 ACC,@BUFF_PTR1 	 ;
	       INC.L	 #1,BUFF_PTR2		 ;
	       INC.L	 #1,BUFF_PTR1		 ;
	       DEC.B	 REG_R1 		 ;
	       BNE	 S_RXIN_RD:8		 ;
	       MOV.L	 #DL_S1_TV,BUFF_PTR1	 ;
	       MOV.B	 #D'8,REG_R1             ;
S_RXIN_RD1:    MOV.B	 @BUFF_PTR2,ACC 	 ;
	       MOV.B	 ACC,@BUFF_PTR1 	 ;
	       INC.L	 #1,BUFF_PTR2		 ;
	       INC.L	 #1,BUFF_PTR1		 ;
	       DEC.B	 REG_R1 		 ;
	       BNE	 S_RXIN_RD1:8		 ;
	       RTS				 ;
;-Slave station transmit data (new)		 ;						    ;
;-Mode:data link				 ;
S_TXOUT_CHK:   MOV.B	 #H'00,B_REG             ;
	       MOV.L	 #S1_TX_BUFF,DPTR	 ;
	       MOV.L	 #DL_S1_RR,BUFF_PTR1	 ;
	       MOV.L	 #DL_S1_RV,BUFF_PTR2	 ;
	       MOV.B	 #H'00,REG_R1            ;master's ID
	       MOV.B	 REG_R1,@DPTR		 ;reg_r1:DID, dptr:frame ptr
	       ADD.B	 REG_R1,B_REG		 ;
	       INC.L	 #1,DPTR		 ;
	       MOV.B	 #D'15,ACC               ;BNO 11->15 TP02
	       MOV.B	 ACC,@DPTR		 ;
	       ADD.B	 ACC,B_REG		 ;
	       INC.L	 #1,DPTR		 ;
	       MOV.B	 #DCMD_STM,ACC		 ;STM
	       MOV.B	 ACC,@DPTR		 ;
	       ADD.B	 ACC,B_REG		 ;
	       INC.L	 #1,DPTR		 ;
	       MOV.B	 @WS045_ADDR+1,ACC	 ;SID
	       MOV.B	 ACC,@DPTR		 ;
	       ADD.B	 ACC,B_REG		 ;
	       INC.L	 #1,DPTR		 ;
STM_TO_BUFF:   MOV.B	 #H'04,REG_R1            ;
STM_TO_S_LP:   MOV.B	 @BUFF_PTR1,ACC 	 ;buff_ptr1:data buffer ptr
	       MOV.B	 ACC,@DPTR		 ;
	       ADD.B	 ACC,B_REG		 ;
	       INC.L	 #1,DPTR		 ;
	       INC.L	 #1,BUFF_PTR1		 ;
	       DEC.B	 REG_R1 		 ;
	       BNE	 STM_TO_S_LP:8		 ;
STM_TO_BUFF1:  MOV.B	 #H'08,REG_R1            ;
STM_TO_S_LP1:  MOV.B	 @BUFF_PTR2,ACC 	 ;
	       MOV.B	 ACC,@DPTR		 ;
	       ADD.B	 ACC,B_REG		 ;
	       INC.L	 #1,DPTR		 ;
	       INC.L	 #1,BUFF_PTR2		 ;V0.C BUFF_PTR1->BUFF_PTR2
	       DEC.B	 REG_R1 		 ;
	       BNE	 STM_TO_S_LP1:8 	 ;
	       MOV.B	 B_REG,@DPTR		 ;checksum value
	       RTS				 ;
;-Slave station response not ready,stop or err(new);
;-Mode:data link				 ;
S_TXOUT_SNR:   MOV.L	 #S1_TX_BUFF,DPTR	 ;
	       MOV.B	 #H'00,ACC               ;
	       MOV.B	 ACC,@DPTR		 ;
	       INC.L	 #1,DPTR		 ;
	       MOV.B	 #D'02,ACC               ;V0.F6
	       MOV.B	 ACC,@DPTR		 ;
	       INC.L	 #1,DPTR		 ;
	       MOV.B	 #DCMD_SNR,ACC		 ;
	       MOV.B	 ACC,@DPTR		 ;
	       INC.L	 #1,DPTR		 ;;V0.F6
	       MOV.B	 @WS045_ADDR+1,ACC	 ;;
	       MOV.B	 ACC,@DPTR		 ;;
	       RTS				 ;
;For remote mode slave return to main routine	 ;
RETURN_MASTER: MOV.L	 #ASCII1_3A,DPTR	 ;
	       MOV.B	 @DPTR,ACC		 ;
	       MOV.L	 DPTR,@BUFF_PTR 	 ;
	       MOV.B	 ACC,@TDR1		 ;
	       BSET	 #MPBT,@SSR1		 ;Set ID transmit bit
	       BCLR	 #RIE,@SCR1		 ;
	       BCLR	 #RE,@SCR1		 ;
	       BSET	 EN_422 		 ;Turn 422 to transmit mode
	       BCLR	 #TDRE,@SSR1		 ;
	       BSET	 #TIE,@SCR1		 ;
	       BSET	 #TEIE,@SCR1		 ;
	       JMP	 @COMM_PG1		 ;
;-<Slave side> --Request to slave 4021 PS --	 ;
;-Mode:Remote I/O link				 ;
PS_STRT:       BLD	 E_CHKSUM_ERR	     ;;;;;
	       BCS	 PS_RET 	     ;;;;;
	       BLD	 DATA_RAM_ERR	     ;;;;;
	       BCS	 PS_RET 	     ;;;;;
	       BSET	 PS			 ;
	       BCLR	 PS			 ;
	       JSR	 @EXE_INP_D0		 ;
PS_RET:        JMP	 @COMM_PG1		 ;
;-<Slave side> --Request to slave 4094 STB --	 ;
;-Mode:Remote I/O link				 ;
STB_STRT:      JSR	 @EXE_OUT_D0		 ;
	       BSET	 EN_IO			 ;
	       BSET	 STB_B			 ;
	       MOV.B	 @STB_A,ACC		 ;
	       BCLR	 STB_B			 ;
	       BSET	 RUN_FLAG		 ;V1.0
	       BCLR	 RUN_FLAG_1		 ;  ;
	       BSET	 ERROR_LED		 ;  ;
	       BCLR	 RUN_LED		 ;  ;
	       MOV.L	 #SC105_ADDR,DPTR    ;;;;;
	       BSET	 #0,@DPTR	     ;;;;;
	       BCLR	 FAULT_FLAG		 ;
	       BCLR	 DLINK_ERR		 ;
	       MOV.B	 @TIME_BASE1,ACC	 ;
	       MOV.B	 ACC,@DLINK_TIMEOUT	 ;
	       JMP	 @COMM_PG1		 ;
;-<Master side>- Response from slave station  -- ;
;-Mode:Remote I/O link				 ;
RTM_STRT:      MOV.L	 #ASCII1_3A,DPTR	 ;
	       MOV.B	 #D'8,REG_R1             ;
	       MOV.B	 #H'00,B_REG             ;
RTM_SUM_LOOP:  MOV.B	 @DPTR,ACC		 ;
	       ADD.B	 ACC,B_REG		 ;
	       INC.L	 #1,DPTR		 ;
	       DEC.B	 REG_R1 		 ;
	       BNE	 RTM_SUM_LOOP:8 	 ;
	       MOV.B	 @DPTR,ACC		 ;
	       CMP.B	 ACC,B_REG		 ;
	       BEQ	 REFLESH_RTM		 ;
	       BLD	 DLINK_CSM_NG		 ;
	       BCS	 CSM_NG_2ND		 ;
	       BSET	 DLINK_CSM_NG		 ;
	       MOV.B	 @SCAN_TIME_BASE1,ACC	 ;V0.E
	       MOV.B	 ACC,@DLINK_TIMEOUT	 ;V0.E
	       BSR	 SLAVE_TTS_TASK 	 ; checksum NG,retransmit again
	       JMP	 @WAIT_RTM		 ; jump to wait again
CSM_NG_2ND:    BCLR	 DLINK_CSM_NG		 ;
	       JMP	 @REMOTE_TMOUT		 ; jump to error mode process
REFLESH_RTM:   BCLR	 DLINK_CSM_NG		 ;reset CSM NG retransmit flag
	       MOV.B	 @SLAVE_RING,ACC	 ;
RTM_S1:        CMP.B	 #H'01,ACC               ;
	       BNE	 RTM_S2:8		 ;
	       MOV.L	 #RL_S1_RX,BUFF_PTR1	 ;
	       BRA	 RTM_GO:8		 ;
RTM_S2:        CMP.B	 #H'02,ACC               ;
	       BNE	 RTM_S3:8		 ;
	       MOV.L	 #RL_S2_RX,BUFF_PTR1	 ;
	       BRA	 RTM_GO:8		 ;
RTM_S3:        CMP.B	 #H'03,ACC               ;
	       BNE	 RTM_S4:8		 ;
	       MOV.L	 #RL_S3_RX,BUFF_PTR1	 ;
	       BRA	 RTM_GO:8		 ;
RTM_S4:        CMP.B	 #H'04,ACC               ;
	       BEQ	 RTM_S4_D		 ;
	       JMP	 @NEXT_IN_NODE		 ; Think about here !
RTM_S4_D:      MOV.L	 #RL_S4_RX,BUFF_PTR1	 ;
RTM_GO:        MOV.L	 #COM_BUF2,DPTR 	 ;
	       MOV.B	 #H'05,REG_R1            ;IN 5 bytes
RTM_GO_LOOP:   MOV.B	 @DPTR,ACC		 ;ex.]0000-]0004 -> ]0100-]0104
	       MOV.B	 ACC,@BUFF_PTR1 	 ;   (ST-NO.001)
	       INC.L	 #1,DPTR		 ;
	       INC.L	 #1,BUFF_PTR1		 ;
	       DEC.B	 REG_R1 		 ;
	       BNE	 RTM_GO_LOOP:8		 ;
	       BCLR	 DLINK_CSM_NG		 ;
	       MOV.B	 @SLAVE_RING,ACC	 ;
	       MOV.L	 #SC105_ADDR,DPTR	 ;
	       BSET	 ACC,@DPTR		 ;Set data link communication
	       INC.B	 ACC			 ;flag
	       MOV.B	 ACC,@SLAVE_RING	 ;
	       JMP	 @NEXT_IN_NODE		 ;
;-<Slave side>- Receive from master station   -- ;
;-Mode:Remote I/O link				 ;
TTS_STRT:      BLD	 E_CHKSUM_ERR		 ;;V0.F1
	       BCS	 TTS_ERR_N:8		 ;;
	       BLD	 DATA_RAM_ERR		 ;;
	       BCS	 TTS_ERR_N:8		 ;;
	       MOV.L	 #ASCII1_3A,DPTR	 ;
	       MOV.B	 #D'6,REG_R1             ;
	       MOV.B	 #H'00,B_REG             ;
TTS_SUM_LOOP:  MOV.B	 @DPTR,ACC		 ;
	       ADD.B	 ACC,B_REG		 ;
	       INC.L	 #1,DPTR		 ;
	       DEC.B	 REG_R1 		 ;
	       BNE	 TTS_SUM_LOOP:8 	 ;
	       MOV.B	 @DPTR,ACC		 ;
	       CMP.B	 ACC,B_REG		 ;
	       BEQ	 REFLESH_TTS:8		 ;
TTS_ERR_N:     JMP	 @COMM_PG1		 ;if checksum error,no response
REFLESH_TTS: ;;BCLR	 DLINK_ERR	     ;;;;;V0.F6
	     ;;BCLR	 FAULT_FLAG	     ;;;;;NEW
	     ;;MOV.B	 @TIME_BASE1,ACC     ;;;;;
	     ;;MOV.B	 ACC,@DLINK_TIMEOUT  ;;;;;
	     ;;MOV.L	 #CODE_0734,DPTR     ;;;;;
	     ;;BSET	 #0,@DPTR	     ;;;;;
	       MOV.L	 #Y_STATE,BUFF_PTR1	 ;
TTS_GO:        MOV.L	 #COM_BUF2,DPTR 	 ;
	       MOV.B	 #H'03,REG_R1            ;OUT 3 bytes
TTS_GO_LOOP:   MOV.B	 @DPTR,ACC		 ;ex.]0000-]0004 -> ]0100-]0104
	       MOV.B	 ACC,@BUFF_PTR1 	 ;   (ST-NO.001)
	       INC.L	 #1,DPTR		 ;
	       INC.L	 #1,BUFF_PTR1		 ;
	       DEC.B	 REG_R1 		 ;
	       BNE	 TTS_GO_LOOP:8		 ;
RTM_RESPONSE:  MOV.B	 #H'00,ACC               ;
	       MOV.B	 ACC,@ASCII1_3A 	 ;
	       MOV.B	 #H'07,ACC               ;
	       MOV.B	 ACC,@ASCII2_3A 	 ;
	       MOV.B	 #H'08,ACC               ;
	       MOV.B	 ACC,@BYTE_NO		 ;
	       MOV.B	 #DCMD_RTM,ACC		 ;
	       MOV.B	 ACC,@COM_BUF1		 ;
	       MOV.L	 #X_STATE,DPTR		 ;
RTM_TO_MASTER: MOV.L	 #COM_BUF2,BUFF_PTR1	 ;
	       MOV.B	 #H'05,REG_R1            ;
RTM_TO_M_LP:   MOV.B	 @DPTR,ACC		 ;
	       MOV.B	 ACC,@BUFF_PTR1 	 ;
	       INC.L	 #1,DPTR		 ;
	       INC.L	 #1,BUFF_PTR1		 ;
	       DEC.B	 REG_R1 		 ;
	       BNE	 RTM_TO_M_LP:8		 ;
	       BLD	 BATEN			 ;;V2.3 SLAVE STATION RESPONSE
	       BCS	 RTM_TO_M_SUM:8 	 ;;BATTERY CONDITION TO MASTER
	       DEC.L	 #1,BUFF_PTR1		 ;;BY 00047 STATUS
	       BSET	 #7,@BUFF_PTR1		 ;;
RTM_TO_M_SUM:  MOV.L	 #ASCII1_3A,DPTR	 ;
	       MOV.B	 #D'8,REG_R1             ;
	       MOV.B	 #H'00,B_REG             ;
RTM_SUM_LP:    MOV.B	 @DPTR,ACC		 ;
	       ADD.B	 ACC,B_REG		 ;
	       INC.L	 #1,DPTR		 ;
	       DEC.B	 REG_R1 		 ;
	       BNE	 RTM_SUM_LP:8		 ;
	       MOV.B	 B_REG,@DPTR		 ;
	       MOV.L	 #SC081_ADDR,DPTR	 ;;V0.F2
	       BCLR	 #6,@DPTR		 ;;V0.F2
	       BCLR	 #2,@DPTR		 ;;V0.F2
	       BRA	 RETURN_MASTER		 ;
;-<Master side>- Issue PS command by broadcast-  ;
;-Mode:Remote I/O link				 ;
SLAVE_PS_TASK: MOV.B	 #H'99,ACC               ;
	       MOV.B	 ACC,@ASCII1_3A 	 ;
	       MOV.B	 #H'01,ACC               ;
	       MOV.B	 ACC,@ASCII2_3A 	 ;
	       MOV.B	 #H'02,ACC               ;
	       MOV.B	 ACC,@BYTE_NO		 ;
	       MOV.B	 #DCMD_PS,ACC		 ;
	       MOV.B	 ACC,@COM_BUF1		 ;
TX_TO_SLAVE:   MOV.L	 #ASCII1_3A,DPTR	 ;
	       MOV.B	 @DPTR,ACC		 ;
	       MOV.L	 DPTR,@BUFF_PTR 	 ;
	       MOV.B	 ACC,@TDR1		 ;
	       BSET	 #MPBT,@SSR1		 ;Set ID transmit bit
	       BCLR	 #RIE,@SCR1		 ;
	       BCLR	 #RE,@SCR1		 ;
	       BSET	 EN_422 		 ;Turn 422 to transmit mode
	       BCLR	 #TDRE,@SSR1		 ;
	       BSET	 #TIE,@SCR1		 ;
	       BSET	 #TEIE,@SCR1		 ;
	       RTS				 ;
;-<Master side>- refresh master communication flag;
;-Mode:Remote I/O link				 ;
REFRESH_07340: MOV.L	 #SC105_ADDR,DPTR	 ;;V0.F5 To refresh 7340 for
	       MOV.B	 @DPTR,B_REG		 ;master in every scan cycle
	       MOV.B	 @WS046_ADDR+1,REG_R1	 ;
	       BSET	 BIT_BUF		 ;
	       SHLR.B	 B_REG			 ;
R_FLAG_734:    SHLR.B	 B_REG			 ;
	       BAND	 BIT_BUF		 ;
	       BST	 BIT_BUF		 ;
	       DEC.B	 REG_R1 		 ;
	       BNE	 R_FLAG_734:8		 ;
	       BLD	 BIT_BUF		 ;
	       BST	 #0,@DPTR		 ;
	       RTS				 ;
;-<Master side>- Issue STB command by broadcast- ;
;-Mode:Remote I/O link				 ;
SLAVE_STB_TASK: 				 ;
	       MOV.B	 #H'99,ACC               ;
	       MOV.B	 ACC,@ASCII1_3A 	 ;
	       MOV.B	 #H'01,ACC               ;
	       MOV.B	 ACC,@ASCII2_3A 	 ;
	       MOV.B	 #H'02,ACC               ;
	       MOV.B	 ACC,@BYTE_NO		 ;
	       MOV.B	 #DCMD_STB,ACC		 ;
	       MOV.B	 ACC,@COM_BUF1		 ;
	       BSR	 TX_TO_SLAVE		 ;
	       RTS				 ;
;-<Master side>- Issue TTS command to slave ID - ;
;-Mode:Remote I/O link				 ;
SLAVE_TTS_TASK: 				 ;
	       MOV.B	 #DCMD_TTS,ACC		 ;
	       MOV.B	 ACC,@COM_BUF1		 ;
	       MOV.B	 @SLAVE_RING,ACC	 ;
	       MOV.B	 ACC,@ASCII1_3A 	 ;
TTS_S1:        CMP.B	 #H'01,ACC               ;
	       BNE	 TTS_S2:8		 ;
	       MOV.L	 #RL_S1_TX,BUFF_PTR1	 ;
	       BRA	 TTS_GOGO		 ;
TTS_S2:        CMP.B	 #H'02,ACC               ;
	       BNE	 TTS_S3:8		 ;
	       MOV.L	 #RL_S2_TX,BUFF_PTR1	 ;
	       BRA	 TTS_GOGO		 ;
TTS_S3:        CMP.B	 #H'03,ACC               ;
	       BNE	 TTS_S4:8		 ;
	       MOV.L	 #RL_S3_TX,BUFF_PTR1	 ;
	       BRA	 TTS_GOGO:8		 ;
TTS_S4:        CMP.B	 #H'04,ACC               ;
	       BEQ	 TTS_S4_D:8		 ;
	       RTS				 ; Think about here !
TTS_S4_D:      MOV.L	 #RL_S4_TX,BUFF_PTR1	 ;
TTS_GOGO:      MOV.L	 #COM_BUF2,DPTR 	 ;
	       MOV.B	 #H'03,REG_R1            ;OUT 3 bytes
TTS_MOV_LP:    MOV.B	 @BUFF_PTR1,ACC 	 ;ex.]0140-]0142 -> ]0040-]0042
	       MOV.B	 ACC,@DPTR		 ;   (ST-NO.001)
	       INC.L	 #1,DPTR		 ;
	       INC.L	 #1,BUFF_PTR1		 ;
	       DEC.B	 REG_R1 		 ;
	       BNE	 TTS_MOV_LP:8		 ;
	       MOV.B	 #H'05,ACC               ;
	       MOV.B	 ACC,@ASCII2_3A 	 ;
	       MOV.B	 #H'06,ACC               ;
	       MOV.B	 ACC,@BYTE_NO		 ;
TTS_TO_S_SUM:  MOV.L	 #ASCII1_3A,DPTR	 ;
	       MOV.B	 #D'6,REG_R1             ;
	       MOV.B	 #H'00,B_REG             ;
TTS_SUM_LOOP2: MOV.B	 @DPTR,ACC		 ;
	       ADD.B	 ACC,B_REG		 ;
	       INC.L	 #1,DPTR		 ;
	       DEC.B	 REG_R1 		 ;
	       BNE	 TTS_SUM_LOOP2:8	 ;
	       MOV.B	 B_REG,@DPTR		 ;
	       BSR	 TX_TO_SLAVE		 ;
	       RTS
;******************************************************************************
;******************	  HIGH_SPEED		*******************************
;******************************************************************************
;/* Module Name:   HIGH_SPEED()
;   Description:   Processing high speed counter
;   Require Module:
;   Require Reg: ACC,B_REG,REG_R1
;   Input: ACC (SWn content)
;   Return:
HIGH_SPEED:	 BLD	 HSC_MODE		 ;
		 BCS	 HI_SPEED_TYPE:8	 ; Not high speed counter mode
		 RTS				 ;
HI_SPEED_TYPE:	 MOV.W	 @WS059_ADDR,R0 	 ;
		 CMP.W	 #0,R0			 ;
		 BNE	 HIGH_SPEED_T1:8	 ;
		 RTS				 ;
HIGH_SPEED_T1:	 .EQU	 $			 ;
		 DEC.W	 #1,R0			 ;
		 SHLL.W  R0			 ;
		 MOV.L	 #HIGH_SPEED_TABL,ER1	 ;
		 ADD.W	 R0,R1			 ;
		 MOV.W	 @ER1,R2		 ;
		 MOV.W	 #H'0000,E2              ;
		 JMP	 @ER2			 ;
HIGH_SPEED_TABL  .DATA.W  MODE1 		 ;
		 .DATA.W  MODE2 		 ;
		 .DATA.W  MODE3 		 ;
		 .DATA.W  MODE4 		 ;
		 .DATA.W  MODE5 		 ;
		 .DATA.W  MODE6 		 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MODE2:		 BSR	 MODE21 		  ;
		 BSR	 MODE22 		  ;
MODE23: 	 MOV.L	 #SC001_ADDR,DPTR	  ;
		 BLD	 #0,@DPTR		  ;SC001= 1 ?
		 BCS	 MODE23_ENABLE:8	  ;
MODE23_DISABLE:  BCLR	 #2,@TSTR		  ;
		 BCLR	 HSC1_SET		  ;;V1.6
		 BSET	 PRE_SC002		  ;
		 RTS				  ;
MODE23_ENABLE:	 BSET	 #2,@TSTR		  ;
		 BSET	 #2,@TIER2		  ;
		 BSR	 TWO_PHASE		  ;
		 RTS				  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MODE1:		 MOV.L	 #SC001_ADDR,DPTR	  ;
		 BLD	 #0,@DPTR		  ;SC001= 1 ?
		 BCS	 MODE1_ENABLE:8 	  ;
MODE1_DISABLE:	 MOV.B	 #H'E1,R0L                ;Stop counting both in input
		 MOV.B	 R0L,@TSTR		  ;and hardware reset
		 BCLR	 #0,@TIER2		  ;
		 BCLR	 #2,@TIER2		  ;
		 BCLR	 #1,@TIER3		  ;
		 BSET	 PRE_SC002		  ;
		 RTS				  ;
MODE1_ENABLE:	 BSET	 #2,@TSTR		  ;
		 BSET	 #3,@TSTR		  ;
		 BSET	 #2,@TIER2		  ;
		 BSET	 #1,@TIER3		  ;
		 BSR	 TWO_PHASE		  ;
		 RTS				  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MODE3:		 .EQU	 $
		 BSR	 MODE31 		  ;
MODE32: 	 MOV.L	 #SC001_ADDR,DPTR	 ;
		 BLD	 #2,@DPTR		 ;SC003= 1 ?
		 BCS	 MODE32_ENABLE:8	 ;
MODE32_DISABLE:  BCLR	 #2,@TSTR		 ;disable TCNT2
		 BSET	 PRE_SC004		 ;
		 BRA	 MODE33 		 ;
MODE32_ENABLE:	 BSET	 #2,@TSTR		 ;
		 BLD	 PRE_SC004		 ;
		 BCS	 MODE32_RST_END:8	 ;
MODE32_CHK_RESET: BLD	 #3,@DPTR		 ;
		 BCC	 MODE32_RST_END:8	 ;
		 MOV.W	 #0,ACC_W		 ;
		 MOV.W	 ACC_W,@TCNT2		 ;
MODE32_RST_END:  BLD	 #3,@DPTR		 ;
		 BST	 PRE_SC004		 ;
MODE32_COMP_R:	 MOV.W	 @V1004_ADDR,ACC_W	 ;Compare data -> GRB3
		 DEC.W	 #1,ACC_W		 ;
		 MOV.W	 ACC_W,@GRB2		 ;
		 BLD	 HSC2_SET		 ;;V1.6
		 BCC	 HSC2_CHK:8		 ;;
		 BCLR	 HSC2_SET		 ;;
		 MOV.W	 @V1003_ADDR,ACC_W	 ;;
		 MOV.W	 ACC_W,@TCNT2		 ;;
		 BRA	 HSC2_CHK2		 ;;
HSC2_CHK:	 MOV.W	 @TCNT2,ACC_W		 ;
		 MOV.W	 ACC_W,@V1003_ADDR	 ;
HSC2_CHK2:	 MOV.B	 #H'FA,ACC               ;
		 MOV.B	 ACC,@TIER2		 ;
MODE33: 	 MOV.L	 #SC001_ADDR,DPTR	 ;
		 BLD	 #4,@DPTR		 ;SC005= 1 ?
		 BCS	 MODE33_ENABLE:8	 ;
MODE33_DISABLE:  BCLR	 #3,@TSTR		 ;disable TCNT3
		 BSET	 PRE_SC006		 ;
		 BRA	 MODE34 		 ;
MODE33_ENABLE:	 BSET	 #3,@TSTR		 ;
		 BLD	 PRE_SC006		 ;
		 BCS	 MODE33_RST_END:8	 ;
MODE33_CHK_RESET: BLD	 #5,@DPTR		 ;
		 BCC	 MODE33_RST_END:8	 ;
		 MOV.W	 #0,ACC_W		 ;
		 MOV.W	 ACC_W,@TCNT3		 ;
MODE33_RST_END:  BLD	 #5,@DPTR		 ;
		 BST	 PRE_SC006		 ;
MODE33_COMP_R:	 MOV.W	 @V1006_ADDR,ACC_W	 ;Compare data -> GRB3
		 DEC.W	 #1,ACC_W		 ;
		 MOV.W	 ACC_W,@GRB3		 ;
		 BLD	 HSC3_SET		 ;;V1.6
		 BCC	 HSC3_CHK:8		 ;;
		 BCLR	 HSC3_SET		 ;;
		 MOV.W	 @V1005_ADDR,ACC_W	 ;;
		 MOV.W	 ACC_W,@TCNT3		 ;;
		 BRA	 HSC3_CHK2		 ;;
HSC3_CHK:	 MOV.W	 @TCNT3,ACC_W		 ;
		 MOV.W	 ACC_W,@V1005_ADDR	 ;
HSC3_CHK2:	 MOV.B	 #H'FA,ACC               ;
		 MOV.B	 ACC,@TIER3		 ;
MODE34: 	 MOV.L	 #SC001_ADDR,DPTR	  ;
		 BLD	 #6,@DPTR		  ;SC007= 1 ?
		 BCS	 MODE34_ENABLE:8	  ;
MODE34_DISABLE:  BCLR	 #4,@TSTR		  ;disable TCNT3
		 BSET	 PRE_SC008		  ;
		 RTS				  ;
MODE34_ENABLE:	 BSET	 #4,@TSTR		  ;
		 BLD	 PRE_SC008		  ;
		 BCS	 MODE34_RST_END:8	  ;
MODE34_CHK_RESET: BLD	 #7,@DPTR		  ;
		 BCC	 MODE34_RST_END:8	  ;
		 MOV.W	 #0,ACC_W		  ;
		 MOV.W	 ACC_W,@TCNT4		  ;
MODE34_RST_END:  BLD	 #7,@DPTR		  ;
		 BST	 PRE_SC008		  ;
MODE34_COMP_R:	 MOV.W	 @V1008_ADDR,ACC_W	  ;Compare data -> GRB3
		 DEC.W	 #1,ACC_W		  ;
		 MOV.W	 ACC_W,@GRB4		  ;
		 BLD	 HSC4_SET		 ;;V1.6
		 BCC	 HSC4_CHK:8		 ;;
		 BCLR	 HSC4_SET		 ;;
		 MOV.W	 @V1007_ADDR,ACC_W	 ;;
		 MOV.W	 ACC_W,@TCNT4		 ;;
		 BRA	 HSC4_CHK2		 ;;
HSC4_CHK:	 MOV.W	 @TCNT4,ACC_W		  ;
		 MOV.W	 ACC_W,@V1007_ADDR	  ;
HSC4_CHK2:	 MOV.B	 #H'FA,ACC                ;
		 MOV.B	 ACC,@TIER4		  ;
		 RTS				  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MODE4:		 .EQU	 $			  ;
MODE41: 	 MOV.L	 #SC001_ADDR,DPTR	  ;
		 BLD	 #0,@DPTR		  ;SC001= 1 ?
		 BCS	 MODE41_ENABLE:8	  ;
MODE41_DISABLE:  BCLR	 #1,@TSTR		  ;disable TCNT1
		 BCLR	 #2,@TSTR		  ;disable TCNT2
		 BSET	 PRE_SC002		  ;
		 BRA	 MODE42 		  ;
MODE41_ENABLE:	 BSET	 #1,@TSTR		  ;
		 BSET	 #2,@TSTR		  ;
		 BLD	 PRE_SC002		  ;
		 BCS	 MODE41_RST_END:8	  ;
MODE41_CHK_RESET: BLD	 #1,@DPTR		  ;
		 BCC	 MODE41_RST_END:8	  ;
		 MOV.W	 #0,ACC_W		  ;
		 MOV.W	 ACC_W,@TCNT1		  ;
MODE41_RST_END:  BLD	 #1,@DPTR		  ;
		 BST	 PRE_SC002		  ;
MODE41_COMP_R:	 MOV.W	 @V1002_ADDR,ACC_W	  ;Compare data -> GRB3
		 DEC.W	 #1,ACC_W		  ;
		 MOV.W	 ACC_W,@GRB1		  ;
		 BLD	 HSC1_SET		 ;;V1.6
		 BCC	 HSC1_CHK:8		 ;;
		 BCLR	 HSC1_SET		 ;;
		 MOV.W	 @V1001_ADDR,ACC_W	 ;;
		 MOV.W	 ACC_W,@TCNT1		 ;;
		 BRA	 HSC1_CHK2		 ;;
HSC1_CHK:	 MOV.W	 @TCNT1,ACC_W		  ;
		 MOV.W	 ACC_W,@V1001_ADDR	  ;
HSC1_CHK2:	 MOV.B	 #H'FA,ACC                ;
		 MOV.B	 ACC,@TIER1		  ;
		 MOV.B	 ACC,@TIER2		  ;
MODE42: 	 MOV.L	 #SC001_ADDR,DPTR	  ;
		 BLD	 #2,@DPTR		  ;SC003= 1 ?
		 BCS	 MODE42_ENABLE:8	  ;
MODE42_DISABLE:  BCLR	 #3,@TSTR		  ;disable TCNT3
		 BCLR	 #4,@TSTR		  ;disable TCNT4
		 BSET	 PRE_SC004		  ;
		 RTS				  ;
MODE42_ENABLE:	 BSET	 #3,@TSTR		  ;
		 BSET	 #4,@TSTR		  ;
		 BLD	 PRE_SC004		  ;
		 BCS	 MODE42_RST_END:8	  ;
MODE42_CHK_RESET: BLD	 #3,@DPTR		  ;
		 BCC	 MODE42_RST_END:8	  ;
		 MOV.W	 #0,ACC_W		  ;
		 MOV.W	 ACC_W,@TCNT3		  ;
MODE42_RST_END:  BLD	 #3,@DPTR		  ;
		 BST	 PRE_SC004		  ;
MODE42_COMP_R:	 MOV.W	 @V1004_ADDR,ACC_W	  ;Compare data -> GRB3
		 DEC.W	 #1,ACC_W		  ;
		 MOV.W	 ACC_W,@GRB3		  ;
		 BLD	 HSC2_SET		 ;;V1.6
		 BCC	 HSC42_CHK:8		 ;;
		 BCLR	 HSC2_SET		 ;;
		 MOV.W	 @V1003_ADDR,ACC_W	 ;;
		 MOV.W	 ACC_W,@TCNT3		 ;;
		 BRA	 HSC42_CHK2		 ;;
HSC42_CHK:	 MOV.W	 @TCNT3,ACC_W		  ;
		 MOV.W	 ACC_W,@V1003_ADDR	  ;
HSC42_CHK2:	 MOV.B	 #H'FA,ACC                ;
		 MOV.B	 ACC,@TIER3		  ;
		 MOV.B	 ACC,@TIER4		  ;
		 RTS				  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MODE5:		 BSR	 MODE31 		  ;
		 MOV.W	 @WS060_ADDR,R0 	  ;
MODE5_WS040_4:	 CMP.W	 #4,R0			  ;
		 BNE	 MODE5_WS040_3:8	  ;
		 BSET	 #2,@TSTR		  ;
		 BSET	 #3,@TSTR		  ;
		 BSET	 #4,@TSTR		  ;
		 MOV.B	 #H'FA,R0L                ;
		 MOV.B	 R0L,@TIER2		  ;
		 MOV.B	 R0L,@TIER3		  ;
		 MOV.B	 R0L,@TIER4		  ;
		 RTS				  ;
MODE5_WS040_3:	 CMP.W	 #3,R0			  ;
		 BNE	 MODE5_WS040_2:8	  ;
		 BSET	 #2,@TSTR		  ;
		 BSET	 #3,@TSTR		  ;
		 BCLR	 #4,@TSTR		  ;
		 MOV.B	 #H'FA,R0L                ;
		 MOV.B	 R0L,@TIER2		  ;
		 MOV.B	 R0L,@TIER3		  ;
		 MOV.B	 #H'F8,R0L                ;
		 MOV.B	 R0L,@TIER4		  ;
		 RTS				  ;
MODE5_WS040_2:	 CMP.W	 #2,R0			  ;
		 BNE	 MODE5_WS040_1:8	  ;
		 BSET	 #2,@TSTR		  ;
		 BCLR	 #3,@TSTR		  ;
		 BCLR	 #4,@TSTR		  ;
		 MOV.B	 #H'FA,R0L                ;
		 MOV.B	 R0L,@TIER2		  ;
		 MOV.B	 #H'F8,R0L                ;
		 MOV.B	 R0L,@TIER3		  ;
		 MOV.B	 R0L,@TIER4		  ;
		 RTS				  ;
MODE5_WS040_1:	 BCLR	 #2,@TSTR		  ;
		 BCLR	 #3,@TSTR		  ;
		 BCLR	 #4,@TSTR		  ;
		 MOV.B	 #H'F8,R0L                ;
		 MOV.B	 R0L,@TIER2		  ;
		 MOV.B	 R0L,@TIER3		  ;
		 MOV.B	 R0L,@TIER4		  ;
		 RTS				  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MODE6:		 MOV.L	 #SC001_ADDR,DPTR	  ;
		 BLD	 #0,@DPTR		  ;SC001= 1 ?
		 BCS	 MODE6_ENABLE:8 	  ;
MODE6_DISABLE:	 BCLR	 #1,@TSTR		  ;
		 BCLR	 #2,@TSTR		  ;and hardware reset
		 BCLR	 #0,@TIER2		  ;
		 BCLR	 #2,@TIER2		  ;
		 BSET	 PRE_SC002		  ;
		 BRA	 MODE6_WS040:8		  ;
MODE6_ENABLE:	 BSET	 #2,@TSTR		  ;
		 BSET	 #2,@TIER2		  ;
		 BSR	 TWO_PHASE		  ;
MODE6_WS040:	 MOV.W	 @WS060_ADDR,R0 	  ;
MODE6_WS040_4:	 CMP.W	 #4,R0			  ;
		 BNE	 MODE6_WS040_3:8	  ;
		 BSET	 #3,@TSTR		  ;
		 BSET	 #4,@TSTR		  ;
		 MOV.B	 #H'FA,R0L                ;
		 MOV.B	 R0L,@TIER3		  ;
		 MOV.B	 R0L,@TIER4		  ;
		 RTS				  ;
MODE6_WS040_3:	 CMP.W	 #3,R0			  ;
		 BNE	 MODE6_WS040_2:8	  ;
		 BSET	 #3,@TSTR		  ;
		 BCLR	 #4,@TSTR		  ;
		 MOV.B	 #H'FA,R0L                ;
		 MOV.B	 R0L,@TIER3		  ;
		 MOV.B	 #H'F8,R0L                ;
		 MOV.B	 R0L,@TIER4		  ;
		 RTS				  ;
MODE6_WS040_2:	 BCLR	 #3,@TSTR		  ;
		 BCLR	 #4,@TSTR		  ;
		 MOV.B	 #H'F8,R0L                ;
		 MOV.B	 R0L,@TIER3		  ;
		 MOV.B	 R0L,@TIER4		  ;
		 RTS				  ;
;;
INT_MODE:	 MOV.W	 @WS060_ADDR,R0 	  ;
INT_WS040_4:	 CMP.W	 #4,R0			  ;
		 BNE	 INT_WS040_3:8		  ;
		 BSET	 #1,@TSTR		  ;
		 BSET	 #2,@TSTR		  ;
		 BSET	 #3,@TSTR		  ;
		 BSET	 #4,@TSTR		  ;
		 MOV.B	 #H'FA,R0L                ;
		 MOV.B	 R0L,@TIER1		  ;
		 MOV.B	 R0L,@TIER2		  ;
		 MOV.B	 R0L,@TIER3		  ;
		 MOV.B	 R0L,@TIER4		  ;
		 RTS				  ;
INT_WS040_3:	 CMP.W	 #3,R0			  ;
		 BNE	 INT_WS040_2:8		  ;
		 BSET	 #1,@TSTR		  ;
		 BSET	 #2,@TSTR		  ;
		 BSET	 #3,@TSTR		  ;
		 BCLR	 #4,@TSTR		  ;
		 MOV.B	 #H'FA,R0L                ;
		 MOV.B	 R0L,@TIER1		  ;
		 MOV.B	 R0L,@TIER2		  ;
		 MOV.B	 R0L,@TIER3		  ;
		 MOV.B	 #H'F8,R0L                ;
		 MOV.B	 R0L,@TIER4		  ;
		 RTS				  ;
INT_WS040_2:	 CMP.W	 #2,R0			  ;
		 BNE	 INT_WS040_1:8		  ;
		 BSET	 #1,@TSTR		  ;
		 BSET	 #2,@TSTR		  ;
		 BCLR	 #3,@TSTR		  ;
		 BCLR	 #4,@TSTR		  ;
		 MOV.B	 #H'FA,R0L                ;
		 MOV.B	 R0L,@TIER1		  ;
		 MOV.B	 R0L,@TIER2		  ;
		 MOV.B	 #H'F8,R0L                ;
		 MOV.B	 R0L,@TIER3		  ;
		 MOV.B	 R0L,@TIER4		  ;
		 RTS				  ;
INT_WS040_1:	 CMP.W	 #1,R0			  ;
		 BNE	 INT_WS040_0:8		  ;
		 BSET	 #1,@TSTR		  ;
		 BCLR	 #2,@TSTR		  ;
		 BCLR	 #3,@TSTR		  ;
		 BCLR	 #4,@TSTR		  ;
		 MOV.B	 #H'FA,R0L                ;
		 MOV.B	 R0L,@TIER1		  ;
		 MOV.B	 #H'F8,R0L                ;
		 MOV.B	 R0L,@TIER2		  ;
		 MOV.B	 R0L,@TIER3		  ;
		 MOV.B	 R0L,@TIER4		  ;
		 RTS				  ;
INT_WS040_0:	 BCLR	 #1,@TSTR		  ;
		 BCLR	 #2,@TSTR		  ;
		 BCLR	 #3,@TSTR		  ;
		 BCLR	 #4,@TSTR		  ;
		 MOV.B	 #H'F8,R0L                ;
		 MOV.B	 R0L,@TIER1		  ;
		 MOV.B	 R0L,@TIER2		  ;
		 MOV.B	 R0L,@TIER3		  ;
		 MOV.B	 R0L,@TIER4		  ;
		 RTS				  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MODE21: 	 MOV.L	 #SC001_ADDR,DPTR	 ;
		 BLD	 #2,@DPTR		 ;SC003= 1 ?
		 BCS	 MODE21_ENABLE:8	 ;
MODE21_DISABLE:  BCLR	 #3,@TSTR		 ;disable TCNT3
		 BSET	 PRE_SC004		 ;
		 RTS				 ;
MODE21_ENABLE:	 BSET	 #3,@TSTR		 ;
		 BLD	 PRE_SC004		 ;
		 BCS	 MODE21_RST_END:8	 ;
MODE21_CHK_RESET: BLD	 #3,@DPTR		 ;
		 BCC	 MODE21_RST_END:8	 ;
		 MOV.W	 #0,ACC_W		 ;
		 MOV.W	 ACC_W,@TCNT3		 ;
MODE21_RST_END:  BLD	 #3,@DPTR		 ;
		 BST	 PRE_SC004		 ;
MODE21_COMP_R:	 MOV.W	 @V1004_ADDR,ACC_W	 ;Compare data -> GRB3
		 DEC.W	 #1,ACC_W		 ;
		 MOV.W	 ACC_W,@GRB3		 ;
		 MOV.W	 @TCNT3,ACC_W		 ;
		 MOV.W	 ACC_W,@V1003_ADDR	 ;
		 MOV.B	 #H'FA,ACC               ;
		 MOV.B	 ACC,@TIER3		 ;
		 RTS
MODE22: 	 MOV.L	 #SC001_ADDR,DPTR	 ;
		 BLD	 #4,@DPTR		 ;SC003= 1 ?
		 BCS	 MODE22_ENABLE:8	 ;
MODE22_DISABLE:  BCLR	 #4,@TSTR		 ;disable TCNT3
		 BSET	 PRE_SC006		 ;
		 RTS				 ;
MODE22_ENABLE:	 BSET	 #4,@TSTR		 ;
		 BLD	 PRE_SC006		 ;
		 BCS	 MODE22_RST_END:8	 ;
MODE22_CHK_RESET: BLD	 #5,@DPTR		 ;
		 BCC	 MODE22_RST_END:8	 ;
		 MOV.W	 #0,ACC_W		 ;
		 MOV.W	 ACC_W,@TCNT4		 ;
MODE22_RST_END:  BLD	 #5,@DPTR		 ;
		 BST	 PRE_SC006		 ;
MODE22_COMP_R:	 MOV.W	 @V1006_ADDR,ACC_W	 ;Compare data -> GRB3
		 DEC.W	 #1,ACC_W		 ;
		 MOV.W	 ACC_W,@GRB4		 ;
		 MOV.W	 @TCNT4,ACC_W		 ;
		 MOV.W	 ACC_W,@V1005_ADDR	 ;
		 MOV.B	 #H'FA,ACC               ;
		 MOV.B	 ACC,@TIER4		 ;
		 RTS
;;;;;
MODE31: 	 MOV.L	 #SC001_ADDR,DPTR	  ;
		 BLD	 #0,@DPTR		  ;SC001= 1 ?
		 BCS	 MODE31_ENABLE:8	  ;
MODE31_DISABLE:  BCLR	 #1,@TSTR		  ;disable TCNT1
		 BSET	 PRE_SC002		  ;
		 RTS				  ;
MODE31_ENABLE:	 BSET	 #1,@TSTR		  ;
		 BLD	 PRE_SC002		  ;
		 BCS	 MODE31_RST_END:8	  ;
MODE31_CHK_RESET: BLD	 #1,@DPTR		  ;
		 BCC	 MODE31_RST_END:8	  ;
		 MOV.W	 #0,ACC_W		  ;
		 MOV.W	 ACC_W,@TCNT1		  ;
MODE31_RST_END:  BLD	 #1,@DPTR		  ;
		 BST	 PRE_SC002		  ;
MODE31_COMP_R:	 MOV.W	 @V1002_ADDR,ACC_W	  ;Compare data -> GRB3
		 DEC.W	 #1,ACC_W		  ;
		 MOV.W	 ACC_W,@GRB1		  ;
		 MOV.W	 @TCNT1,ACC_W		  ;
		 MOV.W	 ACC_W,@V1001_ADDR	  ;
		 MOV.B	 #H'FA,ACC                ;
		 MOV.B	 ACC,@TIER1		  ;
		 RTS				  ;
;;;;;;
TWO_PHASE:	 BLD	 PRE_SC002		 ;
		 BCS	 MODE1_RST_END:8	 ;
MODE1_CHK_RESET: BLD	 #1,@DPTR		 ;
		 BCC	 MODE1_RST_END:8	 ;
		 MOV.W	 #0,ACC_W		 ;
		 MOV.W	 ACC_W,@TCNT2		 ;
		 BCLR	 TB0			 ;
		 BCLR	 TB1			 ;
		 BCLR	 #0,@TIER2		 ;;;V1.5
		 BCLR	 #0,@TSR2		 ;;;V1.5
MODE1_RST_END:	 BLD	 #1,@DPTR		 ;
		 BST	 PRE_SC002		 ;
MODE1_COMP_R:	 MOV.W	 @V1002_ADDR,ACC_W	 ;Compare data -> GRA2
		 MOV.W	 #0,ACC_E		 ;
		 SHLL.L  ACC_X			 ;Multiple 4 times
		 SHLL.L  ACC_X			 ;
		 INC.L	 #1,ACC_X		 ;V0.9 TEST
		 MOV.W	 ACC_W,@GRA2		 ;
		 MOV.W	 ACC_E,B_W		 ;
		 BLD	 #0,B_REG		 ;
		 BST	 CB0			 ;
		 BLD	 #1,B_REG		 ;
		 BST	 CB1			 ;
		 BLD	 CB0			 ; CB1,CB0 = TB1,TB0 ?
		 BXOR	 TB0			 ;
		 BCS	 MODE1_OVER_FFFF:8	 ; not equal jump
		 BLD	 CB1			 ;
		 BXOR	 TB1			 ;
		 BCC	 MODE1_NO_FFFF:8	 ;
MODE1_OVER_FFFF: BCLR	 #0,@TIER2		 ;
		 BRA	 MODE1_D_UPDATE:8	 ;
MODE1_NO_FFFF:	 BSET	 #0,@TIER2		 ;
MODE1_D_UPDATE:  BLD	 HSC1_SET		 ;;V1.6
		 BCC	 MODE1_D_UPDATE1:8	 ;;
		 BCLR	 HSC1_SET		 ;;
		 MOV.W	 @V1001_ADDR,ACC_W	 ;;
		 MOV.W	 #0,ACC_E		 ;;
		 SHLL.L  ACC_X			 ;;Multiple 4 times
		 SHLL.L  ACC_X			 ;;
		 MOV.W	 ACC_W,@TCNT2		 ;;
		 MOV.W	 ACC_E,B_W		 ;;
		 BLD	 #0,B_REG		 ;;
		 BST	 TB0			 ;;
		 BLD	 #1,B_REG		 ;;
		 BST	 TB1			 ;;
		 RTS				 ;;
MODE1_D_UPDATE1: MOV.W	 @TCNT2,ACC_W		 ;
		 SHLR.W  ACC_W			 ;
		 SHLR.W  ACC_W			 ;
		 BLD	 TB1			 ;
		 BST	 #7,ACC_H		 ;
		 BLD	 TB0			 ;
		 BST	 #6,ACC_H		 ;
		 MOV.W	 ACC_W,@V1001_ADDR	 ;
MODE1_RET:	 RTS				 ;

; ==========   BUFFER PUSH   =============	 ;
BUFF_PUSH:     .EQU	 $			 ;
	       MOV.L	 @R3_DATA,ER0		 ;;
	       PUSH.L	 ER0			 ;;
	       MOV.L	 @R4_DATA,ER0		 ;;
	       PUSH.L	 ER0			 ;;
	       MOV.L	 @FOR_NEXT_ADDR,ER0	 ;;
	       PUSH.L	 ER0			 ;;
	       MOV.W	 @FOR_NEXT_LPNUM,R0	 ;;
	       PUSH.W	 R0			 ;;
	       MOV.W	 @LABEL_RET_BUFFER,R0	 ;;
	       PUSH.W	 R0			 ;;
	       MOV.W	 @R0_BUFFER,R0		 ;;
	       PUSH.W	 R0			 ;;
	       MOV.W	 @R1_BUFFER,R0		 ;;
	       PUSH.W	 R0			 ;;
	       MOV.W	 @R5L_BUFFER,R0 	 ;;
	       PUSH.W	 R0			 ;;
	       MOV.L	 @ER3_BUFFER,ER0	 ;;
	       PUSH.L	 ER0			 ;;
	       MOV.L	 @R4_BUFFER,ER0 	 ;;
	       PUSH.L	 ER0			 ;;
	       MOV.L	 @R2_BUFFER,ER0 	 ;;
	       PUSH.L	 ER0			 ;;
	       MOV.L	 @R5_BUFFER,ER0 	 ;;
	       PUSH.L	 ER0			 ;;
	       MOV.B	 @INT_KIND,R0L		 ;
TIME_INT1:     CMP.B	 #H'66,ACC               ;
	       BNE	 HSC_MODE11:8		 ;
	       JMP	 @TIME_INT_ST1		 ;
HSC_MODE11:    CMP.B	 #H'11,ACC               ;
	       BNE	 HSC_MODE21:8		 ;
	       JMP	 @IMIB1_GO1		 ;
HSC_MODE21:    CMP.B	 #H'22,ACC               ;
	       BNE	 HSC_MODE31:8		 ;
	       JMP	 @IMIA2_GO1		 ;
HSC_MODE31:    CMP.B	 #H'33,ACC               ;
	       BNE	 HSC_MODE41:8		 ;
	       JMP	 @IMIB2_GO1		 ;
HSC_MODE41:    CMP.B	 #H'44,ACC               ;
	       BNE	 HSC_MODE51:8		 ;
	       JMP	 @IMIB3_GO1		 ;
HSC_MODE51:    JMP	 @IMIB4_GO1		 ;

;; ========   BUFFER POP      ===============	 ;
BUFF_POP:      .EQU	 $			 ;
	       POP.L	 ER0			 ;;VF.2
	       MOV.L	 ER0,@R5_BUFFER 	 ;;
	       POP.L	 ER0			 ;;
	       MOV.L	 ER0,@R2_BUFFER 	 ;;
	       POP.L	 ER0			 ;;
	       MOV.L	 ER0,@R4_BUFFER 	 ;;
	       POP.L	 ER0			 ;;
	       MOV.L	 ER0,@ER3_BUFFER	 ;;
	       POP.W	 R0			 ;;
	       MOV.W	 R0,@R5L_BUFFER 	 ;;
	       POP.W	 R0			 ;;
	       MOV.W	 R0,@R1_BUFFER		 ;;
	       POP.W	 R0			 ;;
	       MOV.W	 R0,@R0_BUFFER		 ;;
	       POP.W	 R0			 ;;
	       MOV.W	 R0,@LABEL_RET_BUFFER	 ;;
	       POP.W	 R0			 ;;
	       MOV.W	 R0,@FOR_NEXT_LPNUM	 ;;
	       POP.L	 ER0			 ;;
	       MOV.L	 ER0,@FOR_NEXT_ADDR	 ;;
	       POP.L	 ER0			 ;;
	       MOV.L	 ER0,@R4_DATA		 ;;
	       POP.L	 ER0			 ;;
	       MOV.L	 ER0,@R3_DATA		 ;;
	       MOV.B	 @INT_KIND,R0L		 ;
TIME_INT2:     CMP.B	 #H'66,ACC               ;
	       BNE	 HSC_MODE12:8		 ;
	       JMP	 @TIMER_B22		 ;
HSC_MODE12:    CMP.B	 #H'11,ACC               ;
	       BNE	 HSC_MODE22:8		 ;
	       JMP	 @IMIB1_GO3		 ;
HSC_MODE22:    CMP.B	 #H'22,ACC               ;
	       BNE	 HSC_MODE32:8		 ;
	       JMP	 @IMIA2_GO3		 ;
HSC_MODE32:    CMP.B	 #H'33,ACC               ;
	       BNE	 HSC_MODE42:8		 ;
	       JMP	 @IMIB2_GO3		 ;
HSC_MODE42:    CMP.B	 #H'44,ACC               ;
	       BNE	 HSC_MODE52:8		 ;
	       JMP	 @IMIB3_GO3		 ;
HSC_MODE52:    JMP	 @IMIB4_GO3		 ;

;******************************************************************************
;******************	 PRG_PTY_CHK   ****************************************
;******************************************************************************
;/* Module Name:   PRG_PTY_CHK()
;   Description:   Check INST PARITY
;   Input:
;   Return:	   PTY_CHK_ERR
PRG_PTY_CHK:	 MOV.L	 #H'000F0000,DPTR        ;
		 MOV.L	 #H'000F1F50,BUFF_PTR1   ;
PTY_CHK_LOOP:	 MOV.W	 @DPTR,ACC_W		 ;INST
		 MOV.B	 @BUFF_PTR1,B_REG	 ;NU
		 MOV.B	 #H'00,REG_R1            ;
		 MOV.B	 ACC,REG_R2		 ;REG_R2:BUFFER
		 AND.B	 #H'0F,ACC               ;INST LB,LN
		 ADD.B	 ACC,REG_R1		 ;
		 MOV.B	 REG_R2,ACC		 ;
		 JSR	 @SWAP_ACC		 ;
		 AND.B	 #H'0F,ACC               ;INST LB,HN
		 ADD.B	 ACC,REG_R1		 ;
		 MOV.B	 ACC_H,ACC		 ;
		 AND.B	 #H'0F,ACC               ;INST HB,LN
		 ADD.B	 ACC,REG_R1		 ;
		 MOV.B	 ACC_H,ACC		 ;
		 JSR	 @SWAP_ACC		 ;
		 AND.B	 #H'0F,ACC               ;INST HB,HN
		 ADD.B	 ACC,REG_R1		 ;
		 MOV.B	 B_REG,ACC		 ;
		 JSR	 @SWAP_ACC		 ;
		 AND.B	 #H'0F,ACC               ;
		 ADD.B	 ACC,REG_R1		 ;
		 AND.B	 #H'0F,REG_R1            ;CSM
		 AND.B	 #H'0F,B_REG             ;
		 CMP.B	 REG_R1,B_REG		 ;
		 BNE	 PRG_PTY_NG:8		 ;
		 INC.L	 #2,DPTR		 ;
		 INC.L	 #1,BUFF_PTR1		 ;
		 CMP.L	 #F00_END_ADDR+2,DPTR	 ;
		 BCS	 PTY_CHK_LOOP:8 	 ;
PRG_PTY_RET:	 BCLR	 PTY_CHK_ERR		 ;
		 RTS				 ;
PRG_PTY_NG:	 BSET	 PTY_CHK_ERR		 ;
		 SUB.L	 #H'000F0002,DPTR        ;
		 SHLR.L  DPTR			 ;
		 MOV.W	 DPTR_LW,@WS006_ADDR	 ;
		 RTS				 ;
;=================================================
SYS_RANGE_CHK: MOV.W	 @WS004_ADDR,ACC_W	 ;;V0.C
	       CMP.W	 #H'0006,ACC_W           ;;V1.1
	       BCS	 WS012_CHK:8		 ;;
	       MOV.L	 #WS004_ADDR,DPTR	 ;;
	       BRA	 SYS_RANGE_ERR		 ;;
WS012_CHK:     MOV.W	 @WS012_ADDR,ACC_W	 ;;VF.6
	       CMP.W	 #H'0003,ACC_W           ;;
	       BCS	 WS018_CHK:8		 ;;
WS012_CHK1:    MOV.L	 #WS012_ADDR,DPTR	 ;;
	       BRA	 SYS_RANGE_ERR		 ;;
WS018_CHK:     MOV.W	 @WS018_ADDR,ACC_W	 ;
	       CMP.B	 ACC_H,ACC		 ;
	       BCS	 WS018_CHK1:8		 ;;V0.E
	       CMP.B	 #H'31,ACC               ;;VF.1
	       BCS	 WS019_CHK:8		 ;
WS018_CHK1:    MOV.L	 #WS018_ADDR,DPTR	 ;
	       BRA	 SYS_RANGE_ERR		 ;
WS019_CHK:     MOV.W	 @WS019_ADDR,ACC_W	 ;
	       CMP.B	 ACC_H,ACC		 ;
	       BCS	 WS019_CHK1:8		 ;;V0.E
	       CMP.B	 #H'31,ACC               ;;VF.1
	       BCS	 WS020_CHK:8		 ;
WS019_CHK1:    MOV.L	 #WS019_ADDR,DPTR	 ;
	       BRA	 SYS_RANGE_ERR		 ;
WS020_CHK:     MOV.W	 @WS020_ADDR,ACC_W	 ;
	       CMP.B	 ACC_H,ACC		 ;
	       BCC	 WS021_CHK:8		 ;
	       MOV.L	 #WS041_ADDR,DPTR	 ;
	       BRA	 SYS_RANGE_ERR		 ;
WS021_CHK:     MOV.W	 @WS021_ADDR,ACC_W	 ;
	       CMP.W	 #D'002,ACC_W            ;
	       BCS	 WS022_CHK:8		 ;
	       MOV.L	 #WS021_ADDR,DPTR	 ;
	       BRA	 SYS_RANGE_ERR		 ;
WS022_CHK:     MOV.W	 @WS022_ADDR,ACC_W	 ;
	       CMP.W	 #D'002,ACC_W            ;
	       BCS	 WS023_CHK:8		 ;
	       MOV.L	 #WS022_ADDR,DPTR	 ;
	       BRA	 SYS_RANGE_ERR		 ;
WS023_CHK:     MOV.W	 @WS023_ADDR,ACC_W	 ;
	       CMP.W	 #D'002,ACC_W            ;
	       BCS	 WS024_CHK:8		 ;
	       MOV.L	 #WS023_ADDR,DPTR	 ;
	       BRA	 SYS_RANGE_ERR		 ;
WS024_CHK:     MOV.W	 @WS024_ADDR,ACC_W	 ;
	       CMP.W	 #D'002,ACC_W            ;
	       BCS	 WS041_CHK:8		 ;
	       MOV.L	 #WS024_ADDR,DPTR	 ;
	       BRA	 SYS_RANGE_ERR		 ;
WS041_CHK:     MOV.L	 #WS041_ADDR,DPTR	 ;
	       BSR	 WS041_CHK_GO		 ;
	       BLD	 JUDGE_NG		 ;
	       BCS	 SYS_RANGE_ERR		 ;
WS042_CHK:     MOV.W	 @WS042_ADDR,ACC_W	 ;
	       CMP.W	 #D'100,ACC_W            ;
	       BCS	 WS043_CHK:8		 ;
	       MOV.L	 #WS042_ADDR,DPTR	 ;
	       BRA	 SYS_RANGE_ERR		 ;
WS043_CHK:     MOV.W	 @WS043_ADDR,ACC_W	 ;
	       CMP.W	 #H'03,ACC_W             ;
	       BCS	 WS043_CHK1:8		 ;
	       MOV.L	 #WS043_ADDR,DPTR	 ;
	       BRA	 SYS_RANGE_ERR		 ;
WS043_CHK1:    CMP.W	 #H'0,ACC_W              ;
	       BNE	 WS043_1:8		 ;
WS043_0:       MOV.L	 #WS044_ADDR,DPTR	 ;COMPUTER LINK
	       BSR	 WS041_CHK_GO		 ;
	       BLD	 JUDGE_NG		 ;
	       BCS	 SYS_RANGE_ERR		 ;
	       MOV.W	 @WS045_ADDR,ACC_W	 ;
	       CMP.W	 #D'100,ACC_W            ;
	       BCS	 WS047_CHK		 ;
	       MOV.L	 #WS045_ADDR,DPTR	 ;
	       BRA	 SYS_RANGE_ERR		 ;
WS043_1:       CMP.W	 #H'1,ACC_W              ;DATA LINK
	       BNE	 WS043_2:8		 ;
	       MOV.W	 @WS045_ADDR,ACC_W	 ;
	       CMP.W	 #H'8,ACC_W              ;
	       BCS	 WS043_1_2:8		 ;
	       MOV.L	 #WS045_ADDR,DPTR	 ;
	       BRA	 SYS_RANGE_ERR		 ;
WS043_1_2:     MOV.W	 @WS046_ADDR,ACC_W	 ;
	       CMP.W	 #H'8,ACC_W              ;
	       BCS	 WS047_CHK:8		 ;
	       MOV.L	 #WS046_ADDR,DPTR	 ;
	       BRA	 SYS_RANGE_ERR		 ;
WS043_2:       MOV.W	 @WS045_ADDR,ACC_W	 ;REMOTE I/O LINK
	       CMP.W	 #H'5,ACC_W              ;
	       BCS	 WS043_2_2:8		 ;
	       MOV.L	 #WS045_ADDR,DPTR	 ;
	       BRA	 SYS_RANGE_ERR		 ;
WS043_2_2:     MOV.W	 @WS046_ADDR,ACC_W	 ;
	       CMP.W	 #H'5,ACC_W              ;
	       BCS	 WS047_CHK:8		 ;
	       MOV.L	 #WS046_ADDR,DPTR	 ;
	       BRA	 SYS_RANGE_ERR		 ;
WS047_CHK:     MOV.W	 @WS047_ADDR,ACC_W	 ;V1.5
	       CMP.W	 #H'02,ACC_W             ;
	       BCS	 WS049_CHK:8		 ;
	       MOV.L	 #WS047_ADDR,DPTR	 ;
	       BRA	 SYS_RANGE_ERR		 ;
WS049_CHK:     MOV.W	 @WS049_ADDR,ACC_W	 ;;V2.0
	       CMP.W	 #H'03,ACC_W             ;;
	       BCS	 WS058_CHK:8		 ;;
	       MOV.L	 #WS049_ADDR,DPTR	 ;;
	       BRA	 SYS_RANGE_ERR:8	 ;;
WS058_CHK:     MOV.W	 @WS058_ADDR,ACC_W	 ;;
	       CMP.W	 #H'02,ACC_W             ;;1->2 V0.D
	       BCS	 WS059_CHK:8		 ;;
	       MOV.L	 #WS058_ADDR,DPTR	 ;;
	       BRA	 SYS_RANGE_ERR:8	 ;;
WS059_CHK:     MOV.W	 @WS059_ADDR,ACC_W	 ;;
	       CMP.W	 #H'07,ACC_W             ;;
	       BCS	 WS060_CHK:8		 ;;
	       MOV.L	 #WS059_ADDR,DPTR	 ;;
	       BRA	 SYS_RANGE_ERR:8	 ;;
WS060_CHK:     MOV.W	 @WS060_ADDR,ACC_W	 ; 0000-037F
	       CMP.W	 #H'5,ACC_W              ;
	       BCS	 WS061_CHK:8		 ;
	       MOV.L	 #WS060_ADDR,DPTR	 ;;
	       BRA	 SYS_RANGE_ERR:8	 ;;
WS061_CHK:     MOV.W	 @WS061_ADDR,ACC_W	 ;
	       CMP.W	 #H'04,ACC_W             ;
	       BCS	 WS062_CHK:8		 ;
	       MOV.L	 #WS061_ADDR,DPTR	 ;
	       BRA	 SYS_RANGE_ERR		 ;
WS062_CHK:     MOV.W	 @WS062_ADDR,ACC_W	 ;
	       CMP.W	 #H'04,ACC_W             ;
	       BCS	 WS063_CHK:8		 ;V0.D
	       MOV.L	 #WS062_ADDR,DPTR	 ;
	       BRA	 SYS_RANGE_ERR		 ;
WS063_CHK:     MOV.W	 @WS063_ADDR,ACC_W	 ;
	       CMP.W	 #H'04,ACC_W             ;V0.D
	       BCS	 SYS_RANGE_OK:8 	 ;
	       MOV.L	 #WS063_ADDR,DPTR	 ;
SYS_RANGE_ERR: BSET	 SYS_SET_ERR		 ;
	       BSET	 FAULT_FLAG		 ;
	       SUB.W	 #H'DEC0,DPTR_LW         ;
	       SHLR.W	 DPTR_LW		 ;
	       INC.W	 #1,DPTR_LW		 ;
	       MOV.W	 DPTR_LW,@WS005_ADDR	 ;
	       RTS				 ;
SYS_RANGE_OK:  BCLR	 SYS_SET_ERR		 ;
	       RTS				 ;
;;;;
WS041_CHK_GO:  MOV.W	 @DPTR,R4		 ;
	       JSR	 @HEX_BCD_W		 ;
	       MOV.B	 R4H,ACC		 ;
	       JSR	 @SWAP_ACC		 ;
	       AND.B	 #H'0F,ACC               ;
	       CMP.B	 #H'02,ACC               ;
	       BCC	 WS041_CHK_ERR:8	 ;
	       MOV.B	 R4H,ACC		 ;
	       AND.B	 #H'0F,ACC               ;
	       CMP.B	 #H'02,ACC               ;
	       BCC	 WS041_CHK_ERR:8	 ;
	       MOV.B	 R4L,ACC		 ;
	       JSR	 @SWAP_ACC		 ;
	       AND.B	 #H'0F,ACC               ;
	       CMP.B	 #H'03,ACC               ;
	       BCC	 WS041_CHK_ERR:8	 ;
	       MOV.B	 R4L,ACC		 ;
	       AND.B	 #H'0F,ACC               ;
	       CMP.B	 #H'08,ACC               ;
	       BCS	 WS041_CHK_OK:8 	 ;
WS041_CHK_ERR: BSET	 JUDGE_NG		 ;
	       RTS				 ;
WS041_CHK_OK:  BCLR	 JUDGE_NG		 ;
	       RTS				 ;
;******************************************************************************
;******************	  RTC_CMD		*******************************
;******************************************************************************
;/* Module Name:   RTC_CMD()
;   Description:   Processing RTC command write/read(1 byte)
;   Require Module:
;   Require Reg: ACC,B_REG,REG_R1
;   Input: ACC (command content),B_REG(write data)
;   Return: 1.WR command: return none
;	    2.RD command: return B_REG for reading data
RTC_CMD:	 BSET	RTC_RST 		 ;    ->³  ³<- 1uS
		 NOP				 ; /RST ÚÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
		 MOV.B	#H'08,REG_R1             ;     ÄÙ  ³ ->³ ³<- 250 nS
CMD_WR_8BIT:	 ROTR.B ACC			 ;  SCLK   ÚÄ¿ ÚÄ¿ ÚÄ¿
		 BST	RTC_DATA		 ;	 ÄÄÙ ÀÄÙ ÀÄÙ ÀÄ
		 BSET	RTC_SCLK		 ;  I/O   ÚÄ¿ ÚÄ¿ ÚÄ¿
		 BCLR	RTC_SCLK		 ;	ÄÄÙ0ÀÄÙ1ÀÄÙ2ÀÄ
		 DEC.B	REG_R1			 ;
		 BNE	CMD_WR_8BIT:8		 ;
		 BLD	#0,ACC			 ;
		 BCC	WR_RTC:8		 ;
RD_RTC: 	 MOV.B	#H'E0,REG_R4             ;
		 MOV.B	REG_R4,@PADDR		 ;RTC_DATA become input pin
		 MOV.B	#H'08,REG_R1             ;
RD_RTC_1BYTE:	 BLD	RTC_DATA		 ;
		 ROTXR.B B_REG			 ;Return B_REG
		 BSET	RTC_SCLK		 ;
		 BCLR	RTC_SCLK		 ;
		 DEC.B	REG_R1			 ;
		 BNE	RD_RTC_1BYTE:8		 ;
		 MOV.B	B_REG,REG_R4		 ;BCD->HEX
		 JSR	@BCD_HEX_B		 ;
		 MOV.B	REG_R4,B_REG		 ;
		 MOV.B	#H'F0,REG_R4             ;
		 MOV.B	REG_R4,@PADDR		 ;RTC_DATA become output pin
		 BCLR	RTC_DATA		 ;
		 BCLR	RTC_RST 		 ;
		 RTS				 ;
WR_RTC: 	 MOV.B	#H'08,REG_R1             ;
	      ;; MOV.B	B_REG,REG_R4		 ;Do it in main !
	      ;; JSR	@HEX_BCD_B		 ;
	      ;; MOV.B	REG_R4,B_REG		 ;
WR_RTC_1BYTE:	 ROTR.B B_REG			 ;
		 BST	RTC_DATA		 ;
		 BSET	RTC_SCLK		 ;
		 BCLR	RTC_SCLK		 ;
		 DEC.B	REG_R1			 ;
		 BNE	WR_RTC_1BYTE:8		 ;
		 BCLR	RTC_DATA		 ;
		 BCLR	RTC_RST 		 ;
		 RTS				 ;
;************************************************;
;**********	 RTC_BURST	     ************;
;************************************************;
;/* Module Name:   RTC_BURST()
;   Description:   Processing RTC command write/read(1 byte)
;   Require Module:
;   Require Reg: ACC,REG_R1,REG_R2,REG_R3
;   Input: ACC (command content),SEC_ADDR <--> CTRL_ADDR
;   Return: 1.WR command: return none
;	    2.RD command: return SEC <--> CTRL_ADDR for reading data
RTC_BURST:	 BCLR	IO_INT_BIT		 ; Ver0.2
		 BSET	RTC_RST 		 ;
	     ;;  MOV.B	@RTC_CTRL_ADDR,REG_R3	 ; MODIFY BY WEI
	     ;;  MOV.B	#H'00,REG_R1             ; ;;
	     ;;  MOV.B	REG_R1,@RTC_CTRL_ADDR	 ; ;;
		 MOV.B	#H'08,REG_R1             ;
CMD_WR_8BITS:	 ROTR.B ACC			 ;
		 BST	RTC_DATA		 ;
		 BSET	RTC_SCLK		 ;
		 BCLR	RTC_SCLK		 ;
		 DEC.B	REG_R1			 ;
		 BNE	CMD_WR_8BITS:8		 ;
		 BLD	#0,ACC			 ;
		 BCC	RTC_WR_BURST:8		 ;
RTC_RD_BURST:	 MOV.B	#H'E0,REG_R4             ;RTC_DATA become input pin
		 MOV.B	REG_R4,@PADDR		 ;
		 MOV.B	#H'07,REG_R2             ;Read 7 bytes
		 MOV.L	#SECOND_ADDR,DPTR	 ;
RD_NEXT:	 MOV.B	#H'08,REG_R1             ;
RD_RTC_LOOP:	 BLD	RTC_DATA		 ;
		 ROTXR.B ACC			 ;
		 BSET	RTC_SCLK		 ;
		 BCLR	RTC_SCLK		 ;
		 DEC.B	REG_R1			 ;
		 BNE	RD_RTC_LOOP:8		 ;
		 MOV.B	ACC,REG_R4		 ;
		 JSR	@BCD_HEX_B		 ;
		 MOV.B	REG_R4,@DPTR		 ;
		 INC.L	#2,DPTR 		 ;
		 DEC.B	REG_R2			 ;
		 BNE	RD_NEXT:8		 ;
		 MOV.B	#H'08,REG_R1             ;;V0.B
RD_RTC_CNTRL:	 BLD	RTC_DATA		 ;;
		 ROTXR.B ACC			 ;;
		 BSET	RTC_SCLK		 ;;
		 BCLR	RTC_SCLK		 ;;
		 DEC.B	REG_R1			 ;;
		 BNE	RD_RTC_CNTRL:8		 ;;
	     ;;  MOV.B	REG_R3,@RTC_CTRL_ADDR	 ; RESTORE @RTC_CTRL_ADDR
		 MOV.B	#H'F0,REG_R4             ;
		 MOV.B	REG_R4,@PADDR		 ;RTC_DATA become output pin
		 BCLR	RTC_DATA		 ;
		 BCLR	RTC_RST 		 ;
		 MOV.B	@YEAR_ADDR,ACC		 ;
		 CMP.B	#H'07,ACC                ;
		 BEQ	CHG_WEEK1		 ;
		 RTS				 ;
CHG_WEEK1:	 MOV.B	#H'8A,ACC                ; SUN DAY , 7 -> 0
		 MOV.B	#H'00,B_REG              ;
		 MOV.B	B_REG,@YEAR_ADDR	 ;
		 BSR	RTC_CMD 		 ;
		 RTS				 ;
RTC_WR_BURST:	 MOV.B	#H'07,REG_R2             ;WRITE 7 BYTES
		 MOV.L	#SECOND_ADDR,DPTR	 ;
WR_NEXT:	 MOV.B	@DPTR,ACC		 ;
		 MOV.B	#H'08,REG_R1             ;
		 MOV.B	ACC,REG_R4		 ;;TP02
		 JSR	@HEX_BCD_B		 ;;
		 MOV.B	REG_R4,ACC		 ;;
WR_RTC_LOOP:	 ROTR.B ACC			 ;
		 BST	RTC_DATA		 ;
		 BSET	RTC_SCLK		 ;
		 BCLR	RTC_SCLK		 ;
		 DEC.B	REG_R1			 ;
		 BNE	WR_RTC_LOOP:8		 ;
		 INC.L	#2,DPTR 		 ;
		 DEC.B	REG_R2			 ;
		 BNE	WR_NEXT:8		 ;
		 MOV.B	#H'08,REG_R1             ;;V0.B
		 MOV.B	#0,ACC			 ;;TP02
WR_RTC_CNTRL:	 ROTR.B ACC			 ;;
		 BST	RTC_DATA		 ;;
		 BSET	RTC_SCLK		 ;;
		 BCLR	RTC_SCLK		 ;;
		 DEC.B	REG_R1			 ;;
		 BNE	WR_RTC_CNTRL:8		 ;;
	     ;;  MOV.B	REG_R3,@RTC_CTRL_ADDR	 ;
		 BCLR	RTC_DATA		 ;
		 BCLR	RTC_RST 		 ;
		 RTS				 ;
;************************************************;
;**********	 DA_CONV	     ************;
;************************************************;
;/* Module Name    : DA_CONV()
;   Description    : Processing DA module output data
;   Output data(X) : 1st DA: ]241(H),]240(L) -->V0985
;		     2nd DA: ]243(H),]242(L) -->V0986
;   Output to IC(y): DAC-8043 D/A converter
;   #212 = 01	   : y = X		    (SYS_212_ON = 0)
;   #212 = 02	   : y =(1600/2000)*X + 400 (SYS_212_ON = 1)
;   1 channel processing time 100uS(TOTAL = 200uS)
DA_CONV:       BLD	 FIRST_PASS_FG		 ;
	       BCC	 IO_DA_RET:8		 ;
	       BSR	 DA_DATA_OUT		 ;
IO_DA_RET:     RTS				 ;
;;; Transfer data to DAC-8043			 ;
DA_DATA_OUT:   ANDC	 #B'01111111,CCR         ;;
	       BCLR	 IO_INT_BIT		 ;;
	    ;; MOV.B	 @CODE_0240,ACC 	 ;;
	    ;; MOV.B	 @CODE_0241,ACC_H	 ;;
	       MOV.W	 @V0985_ADDR,ACC_W	 ;;
	    ;; AND.B	 #B'00001111,ACC_H       ;;
	       BLD	 SYS_212_ON		 ;;V2.0
	       BCC	 OUT_CH1:8		 ;;
	       SHAL.W	 ACC_W			 ;;
	       SHAL.W	 ACC_W			 ;;y = 4/5 X + 400
	       MOV.W	 #0,ACC_E		 ;;
	       MOV.W	 #H'0005,B_W             ;;
	       DIVXU.W	 B_W,ACC_X		 ;;
	       ADD.W	 #D'400,ACC_W            ;;
OUT_CURRENT1:  CMP.W	 #H'0800,ACC_W           ;;
	       BCS	 OUT_CH11:8		 ;;
	       MOV.W	 #H'07FF,ACC_W           ;;
	       BRA	 OUT_CH11:8		 ;;
OUT_CH1:       BLD	 SYS_212_2047		 ;;
	       BCS	 OUT_CURRENT1:8 	 ;;
OUT_VOLT:      CMP.W	 #H'1000,ACC_W           ;;
	       BCS	 OUT_CH11:8		 ;;
	       MOV.W	 #H'0FFF,ACC_W           ;;
OUT_CH11:      BSR	 DA_OUTPUT		 ;
	       MOV.B	 @P6DR,ACC		 ;
	       AND.B	 #B'11111010,ACC         ;
	       ORC	 #B'10000000,CCR         ;
	       BLD	 IO_INT_BIT		 ;
	       BCS	 DA_DATA_OUT:8		 ;
	       MOV.B	 ACC,@P6DR		 ;
	       OR.B	 #B'00000101,ACC         ;
	       MOV.B	 ACC,@P6DR		 ;
DA_DATA_OUT1:  ANDC	 #B'01111111,CCR         ;
	       BCLR	 AD_DOUT		 ;
	       BCLR	 IO_INT_BIT		 ;
	   ;;  MOV.B	 @CODE_0242,ACC 	 ;
	   ;;  MOV.B	 @CODE_0243,ACC_H	 ;
	       MOV.W	 @V0986_ADDR,ACC_W	 ;;
	  ;;	 BCLR	   AD_CS
	  ;;	 BSET	   DA_LD1
	  ;;;  AND.B	 #B'00001111,ACC_H       ;
	       BLD	 SYS_212_ON		 ;;V2.0
	       BCC	 OUT_CH2:8		 ;;
	       SHAL.W	 ACC_W			 ;;
	       SHAL.W	 ACC_W			 ;;y = 4/5 X + 400
	       MOV.W	 #0,ACC_E		 ;;
	       MOV.W	 #H'0005,B_W             ;;
	       DIVXU.W	 B_W,ACC_X		 ;;
	       ADD.W	 #D'400,ACC_W            ;;
OUT_CURRENT2:  CMP.W	 #H'0800,ACC_W           ;;
	       BCS	 OUT_CH22:8		 ;;
	       MOV.W	 #H'07FF,ACC_W           ;;
	       BRA	 OUT_CH22:8		 ;;
OUT_CH2:       BLD	 SYS_212_2047		 ;;
	       BCS	 OUT_CURRENT2:8 	 ;;
	       CMP.W	 #H'1000,ACC_W           ;;
	       BCS	 OUT_CH22:8		 ;;
	       MOV.W	 #H'0FFF,ACC_W           ;;
OUT_CH22:      BSR	 DA_OUTPUT		 ;
	       MOV.B	 @P6DR,ACC		 ;
	       AND.B	 #B'11111011,ACC         ;
	       ORC	 #B'10000000,CCR         ;
	       BLD	 IO_INT_BIT		 ;
	       BCS	 DA_DATA_OUT1:8 	 ;
	       MOV.B	 ACC,@P6DR		 ;
	       OR.B	 #B'00000101,ACC         ;
	       MOV.B	 ACC,@P6DR		 ;
	       ANDC	 #B'01111111,CCR         ;
	       BCLR	 AD_DOUT		 ;
	       RTS				 ;
DA_OUTPUT:     MOV.B	 #D'4,REG_R1             ;
MASK_BIT_OUT:  SHLL.W	 ACC_W			 ;
	       DEC.B	 REG_R1 		 ;
	       BNE	 MASK_BIT_OUT:8 	 ;
	       MOV.B	 #D'12,REG_R1            ;
DA_OUT_LOOP:   SHLL.W	 ACC_W			 ;
	       BST	 AD_DOUT		 ;
	       NOP				 ;
	       NOP				 ;
	       NOP				 ;
	       NOP				 ;
	       BSET	 IO_SCLK		 ;
	       NOP				 ;;V2.0H
	       NOP				 ;;
	       NOP				 ;;
	       NOP				 ;;
	       BCLR	 IO_SCLK		 ;
	       DEC.B	 REG_R1 		 ;
	       BNE	 DA_OUT_LOOP:8		 ;
	       RTS				 ;
;V1.61	start
;***************************************************************************
;************************      AD_CONV1 	    ************************
;***************************************************************************
;/* Module Name  :   AD_CONV1() 				    ********
;   Description  :   Processing  first 4AD module input data	    ********
;   Input data(y):   1st AD: V0961				    ********
;		     2nd AD: V0962				    ********
;		     3rd AD: V0963				    ********
;		     4th AD: V0964				    ********
;   From IC(X)	 :   LTC-1290					    ********
;   WS061 = 01	  :   y = X					    ********
;   WS061 = 02	  :   y = (X-400)*(2000/1600),if {X-400 < 0} then {X-400 = 0}
;***************************************************************************
AD_CONV1:      BLD	 AD_FILTER		 ;
	       BCS	 AD_IN_FILTER1		  ;
	       BCLR	 IO_INT_BIT		 ;
	       MOV.B	 #B'10001110,ACC         ;write 1st channel command
	       MOV.L	 #H'000A0000,DPTR        ;pseudo address(reset WDT)
	       BSR	 WR_RD_AD_COMD1 	  ;
	       BSR	 AD_CONV_TIME1		  ;
	       MOV.B	 #B'10011110,ACC         ;write 2nd channel command
	       MOV.L	 #V0961_ADDR,DPTR	 ;read	1st channel data
	       BSR	 WR_RD_AD_COMD1 	  ;
	       BSR	 AD_CONV_TIME1		  ;
	       MOV.B	 #B'10101110,ACC         ;write 3rd channel command
	       MOV.L	 #V0962_ADDR,DPTR	 ;read	2nd channel data
	       BSR	 WR_RD_AD_COMD1 	  ;
	       BSR	 AD_CONV_TIME1		  ;
	       MOV.B	 #B'10111110,ACC         ;write 4th channel command
	       MOV.L	 #V0963_ADDR,DPTR	 ;read	3rd channel data
	       BSR	 WR_RD_AD_COMD1 	  ;
	       BSR	 AD_CONV_TIME1		  ;
	       MOV.B	 #B'11111110,ACC         ;write on board sensor command
	       MOV.L	 #V0964_ADDR,DPTR	 ;read	4td channel data
	       BSR	 WR_RD_AD_COMD1 	  ;
	       BSR	 AD_CONV_TIME1		  ;
	       MOV.B	 #B'11001110,ACC         ;write psuedo command
	       MOV.L	 #V0969_ADDR,DPTR	 ;read on board sensor data
	       BSR	 WR_RD_AD_COMD1 	  ;
	       BLD	 IO_INT_BIT		 ;
	       BCS	 AD_CONV1		  ;
	       RTS				 ;
;;;;;;;;;;;;;;NEW ADDED ;;;;;;;;;;;;;;;;;;;;;;;;;;
AVER_2_ORDER1:	  BLD	  AD_FILTER1		  ;;V0.D 4 TIMES
		 BCS	 AVER_2_ORDER11:8	  ;;
		 RTS				 ;;
;;;						 ;;
AVER_2_ORDER11:   BLD	  AD_2_D_ST		  ;
		 BCS	 AVER_2_ORDER21:8	  ;
		 MOV.L	 DPTR,BUFF_PTR1 	 ;
		 MOV.B	 @AD_FILTER_TIMES,ACC	 ;
		 MOV.B	 #0,ACC_H		 ;
		 SHLL.W  ACC_W			 ;
		 ADD.W	 ACC_W,DPTR_LW		 ;
		 MOV.W	 B_W,@DPTR		 ;
		 BLD	 AD_FILTER2		 ;
		 BCS	 AVER_2_ORDER111:8	  ;
		 ADD.L	 #8,BUFF_PTR1		 ;last time's average
		 MOV.W	 @BUFF_PTR1,B_W 	 ;
		 RTS				 ;
AVER_2_ORDER111:  ADD.L   #14,BUFF_PTR1 	  ;
		 MOV.W	 @BUFF_PTR1,B_W 	 ;
		 RTS				 ;
AVER_2_ORDER21:   MOV.B   #H'03,REG_R1            ;
		 MOV.W	 B_W,ACC_W		 ;
DIAG_4_TIMES1:	  MOV.W   @DPTR+,B_W		  ;
		 ADD.W	 B_W,ACC_W		 ;
		 DEC.B	 REG_R1 		 ;
		 BNE	 DIAG_4_TIMES1:8	  ;
		 SHLR.W  ACC_W			 ;
		 SHLR.W  ACC_W			 ;
		 MOV.W	 ACC_W,B_W		 ;
		 INC.L	 #2,DPTR		 ;
		 MOV.W	 ACC_W,@DPTR		 ;
		 BLD	 AD_FILTER2		 ;
		 BCS	 AVER_3_ORDER1:8	  ;;
		 RTS				 ;
AVER_3_ORDER1:	  MOV.B   @AD_OFFSET_TIMES0,ACC    ;
		 INC.B	 ACC			 ;
		 MOV.B	 ACC,@AD_OFFSET_TIMES0	  ;
		 CMP.B	 #H'5,ACC                ;
		 BCS	 AD_3_ORDER_RET 	 ;
AVER_3_ORDER01:   MOV.B   #0,ACC		  ;
		 MOV.B	 ACC,@AD_OFFSET_TIMES0	  ;
		 ADD.L	 #2,DPTR		 ;
		 MOV.W	 @DPTR+,ACC_W		 ;
		 MOV.W	 @DPTR+,B_W		 ;
		 ADD.W	 ACC_W,B_W		 ;
		 SHLR.W  B_W			 ;
		 MOV.W	 B_W,@DPTR		 ;
		 SUB.L	 #2,DPTR		 ;
		 MOV.W	 #0,ACC_W		 ;
		 MOV.W	 ACC_W,@DPTR		 ;
		 SUB.L	 #2,DPTR		 ;
		 MOV.W	 #H'FFFF,ACC_W           ;
		 MOV.W	 ACC_W,@DPTR		 ;
		 RTS				 ;
AD_3_ORDER_RET1:  ADD.L   #2,DPTR		  ;
		 MOV.W	 @DPTR,ACC_W		 ;MIN
		 CMP.W	 B_W,ACC_W		 ;
		 BCS	 CHK_AD_3_MAX1:8	  ;
AD_3_NEW_MIN1:	  MOV.W   B_W,@DPTR		  ;
CHK_AD_3_MAX1:	  ADD.L   #2,DPTR		  ;
		 MOV.W	 @DPTR,ACC_W		 ;
		 CMP.W	 B_W,ACC_W		 ;
		 BCC	 AD_3_NEW_MAX11:8	  ;
AD_3_NEW_MAX1:	  MOV.W   B_W,@DPTR		  ;
AD_3_NEW_MAX11:   ADD.L   #2,DPTR		  ;
		 MOV.W	 @DPTR,B_W		 ;
		 RTS				 ;
;;;;;						 ;
AD_IN_FILTER1:	BCLR	  IO_INT_BIT		  ;
	       MOV.L	 @AD_FILTER_BUFF,DPTR	 ;
	       MOV.B	 #B'10001110,ACC         ;write 1st channel command
	       BSR	 WR_RD_AD_COMD1 	  ;
	       BSR	 AD_CONV_TIME1		  ;
	       MOV.L	 @AD_FILTER_BUFF,DPTR	 ;
	       MOV.B	 #B'10011110,ACC         ;write 2nd channel command
	       BSR	 WR_RD_AD_COMD1 	  ;
	       BSR	 AD_CONV_TIME1		  ;
	       MOV.B	 #B'10101110,ACC         ;write 3rd channel command
	       BSR	 WR_RD_AD_COMD1 	  ;
	       BSR	 AD_CONV_TIME1		  ;
	       MOV.B	 #B'10111110,ACC         ;write 4th channel command
	       BSR	 WR_RD_AD_COMD1 	  ;
	       BSR	 AD_CONV_TIME1		  ;
	       MOV.B	 #B'11111110,ACC         ;write on board sensor command
	       BSR	 WR_RD_AD_COMD1 	  ;
	       BSR	 AD_CONV_TIME1		  ;
	       PUSH.L	 DPTR
	       MOV.B	 #B'11111110,ACC         ;write pseudo command
	       MOV.L	 #V0969_ADDR,DPTR
	       BSR	 WR_RD_AD_COMD1 	  ;
	       POP.L	 DPTR
	       BLD	 IO_INT_BIT		 ;
	       BCS	 AD_IN_FILTER1		  ;
	       CMP.L	 #AD_FILTER_ADDR2,DPTR	 ;
	       BCC	 RES_AD_PTR1:8		  ;
	       MOV.L	 DPTR,@AD_FILTER_BUFF	 ;
	       BRA	 CAL_AD_FILTER1:8	  ;
RES_AD_PTR1:	MOV.L	  #AD_FILTER_ADDR1,DPTR   ;
	       MOV.L	 DPTR,@AD_FILTER_BUFF	 ;
	       BSET	 AD_FILTER_ST		 ;
CAL_AD_FILTER1: BLD	  AD_FILTER_ST		  ;
	       BCS	 STR_AD_FILTER1:8	  ;
	       RTS				 ;
STR_AD_FILTER1: MOV.B	  @AD_FILTER_TIMES,ACC	  ;
	       INC.B	 ACC			 ;
	       CMP.B	 #H'03,ACC               ;
	       BCC	 STR_AD_F01:8		  ;
	       BCLR	 AD_2_D_ST		 ;
	       MOV.B	 ACC,@AD_FILTER_TIMES	 ;
	       BRA	 STR_AD_FILTER11:8	  ;;
STR_AD_F01:	BSET	  AD_2_D_ST		  ;;
	       MOV.B	 #H'FF,ACC               ;;
	       MOV.B	 ACC,@AD_FILTER_TIMES	 ;;
STR_AD_FILTER11: MOV.L	   #AD_FILTER_ADDR1,DPTR  ;;
	       BSR	 CAL_AD_MIN1		  ;
	       BSR	 CAL_AD_MAX1		  ;
	       BSR	 CAL_AD_AVER1		  ;
	       MOV.L	 #V0961_BUFF,DPTR	 ;;V0.D
	       BSR	 AVER_2_ORDER1		  ;;
	       MOV.W	 B_W,@V0961_ADDR	 ;
	       MOV.L	 #AD_FILTER_ADDR1,DPTR	 ;
	       INC.L	 #2,DPTR		 ;
	       BSR	 CAL_AD_MIN1		  ;
	       BSR	 CAL_AD_MAX1		  ;
	       BSR	 CAL_AD_AVER1		  ;
	       MOV.L	 #V0962_BUFF,DPTR	 ;;V0.D
	       BSR	 AVER_2_ORDER1		  ;;
	       MOV.W	 B_W,@V0962_ADDR	 ;
	       MOV.L	 #AD_FILTER_ADDR1,DPTR	 ;
	       INC.L	 #2,DPTR		 ;
	       INC.L	 #2,DPTR		 ;
	       BSR	 CAL_AD_MIN1		  ;
	       BSR	 CAL_AD_MAX1		  ;
	       BSR	 CAL_AD_AVER1		  ;
	       MOV.L	 #V0963_BUFF,DPTR	 ;;V0.D
	       BSR	 AVER_2_ORDER1		  ;;
	       MOV.W	 B_W,@V0963_ADDR	 ;
	       MOV.L	 #AD_FILTER_ADDR1,DPTR	 ;
	       INC.L	 #2,DPTR		 ;
	       INC.L	 #2,DPTR		 ;
	       INC.L	 #2,DPTR		 ;
	       BSR	 CAL_AD_MIN1		  ;
	       BSR	 CAL_AD_MAX1		  ;
	       BSR	 CAL_AD_AVER1		  ;
	       MOV.L	 #V0964_BUFF,DPTR	 ;;V0.D
	       BSR	 AVER_2_ORDER1		  ;;
	       MOV.W	 B_W,@V0964_ADDR	 ;
	       RTS				 ;
CAL_AD_MIN1:	MOV.L	  DPTR,BUFF_PTR1	  ;
	       MOV.B	 #D'4,REG_R1             ;
	       MOV.W	 @BUFF_PTR1+,ACC_W	 ;;V0.D
	       MOV.W	 ACC_W,@AD_MIN_BUFF	 ;
CAL_MIN_LP1:	ADD.L	  #D'6,BUFF_PTR1          ;
	       MOV.W	 @BUFF_PTR1+,ACC_W	 ;
	       MOV.W	 @AD_MIN_BUFF,B_W	 ;
	       CMP.W	 B_W,ACC_W		 ;
	       BCS	 NEW_MIN1:8		  ;
	       BRA	 NEW_MIN11:8		  ;
NEW_MIN1:	MOV.W	  ACC_W,@AD_MIN_BUFF	  ;
NEW_MIN11:	DEC.B	  REG_R1		  ;
	       BNE	 CAL_MIN_LP1:8		  ;
	       RTS				 ;
CAL_AD_MAX1:	MOV.L	  DPTR,BUFF_PTR1	  ;
	       MOV.B	 #D'4,REG_R1             ;
	       MOV.W	 @BUFF_PTR1+,ACC_W	 ;;V0.D
	       MOV.W	 ACC_W,@AD_MAX_BUFF	 ;
CAL_MAX_LP1:	ADD.L	  #D'6,BUFF_PTR1          ;
	       MOV.W	 @BUFF_PTR1+,ACC_W	 ;
	       MOV.W	 @AD_MAX_BUFF,B_W	 ;
	       CMP.W	 B_W,ACC_W		 ;
	       BCC	 NEW_MAX1:8		  ;
	       BRA	 NEW_MAX11:8		  ;
NEW_MAX1:	MOV.W	  ACC_W,@AD_MAX_BUFF	  ;
NEW_MAX11:	DEC.B	  REG_R1		  ;
	       BNE	 CAL_MAX_LP1:8		  ;
	       RTS				 ;
CAL_AD_AVER1:	MOV.L	  DPTR,BUFF_PTR1	  ;
	       MOV.W	 #H'00,B_W               ;
	       MOV.B	 #D'5,REG_R1             ;
CAL_AD_LP1:	MOV.W	  @BUFF_PTR1+,ACC_W	  ;;V0.D
	       ADD.L	 #6,BUFF_PTR1		 ;
	       ADD.W	 ACC_W,B_W		 ;
	       DEC.B	 REG_R1 		 ;
	       BNE	 CAL_AD_LP1:8		  ;
	       MOV.W	 @AD_MIN_BUFF,ACC_W	 ;
	       SUB.W	 ACC_W,B_W		 ;
	       MOV.W	 @AD_MAX_BUFF,ACC_W	 ;
	       SUB.W	 ACC_W,B_W		 ;
	       MOV.W	 #H'0,E1                 ;
	       MOV.W	 #D'3,R0                 ;
	       DIVXU.W	 R0,ER1 		 ;
	  ;;;  MOV.B	 B_H,ACC		 ;TP02 no need to xchg
	  ;;;  MOV.B	 B_REG,B_H		 ;high byte / low byte
	  ;;;  MOV.B	 ACC,B_REG		 ;
	       RTS				 ;
WR_RD_AD_COMD1: BCLR	  DA_LD1		  ;
	       BSET	 AD_CS			 ;
	       NOP				 ;
	       NOP				 ;
	       NOP				 ;
	       NOP				 ;
	       MOV.B	 #D'12,REG_R1            ;
WR_RD_AD_LP_S1: SHLL.B	  ACC			  ;
	       BST	 AD_DOUT		 ;
WR_RD_AD_LP1:	BILD	  AD_DINP		  ;
	       BCS	 WR_RD_AD_LP11:8	  ;
WR_RD_AD_LP01:	BIOR	  AD_DINP		  ;MSB first
	       BCS	 WR_RD_AD_LP1:8 	  ;
	       ROTXL.W	 B_W			 ;
	       NOP				 ;
	       NOP				 ;
	       NOP				 ;
	       NOP				 ;
	       BSET	 IO_SCLK		 ;
	       NOP				 ;;V2.0H
	       NOP				 ;;
	       NOP				 ;;
	       NOP				 ;;
	       BCLR	 IO_SCLK		 ;
	       NOP				 ;
	       NOP				 ;
	       NOP				 ;
	       NOP				 ;
	       NOP				 ;
	       DEC.B	 REG_R1 		 ;
	       BNE	 WR_RD_AD_LP_S1:8	  ;
	       BRA	 WR_RD_AD_LP21:8	  ;
WR_RD_AD_LP11:	BIAND	  AD_DINP		  ;
	       BCC	 WR_RD_AD_LP1:8 	  ;
	       ROTXL.W	 B_W			 ;
	       NOP				 ;
	       NOP				 ;
	       NOP				 ;
	       NOP				 ;
	       BSET	 IO_SCLK		 ;
	       NOP				 ;;V2.0H
	       NOP				 ;;
	       NOP				 ;;
	       NOP				 ;;
	       BCLR	 IO_SCLK		 ;
	       NOP				 ;
	       NOP				 ;
	       NOP				 ;
	       NOP				 ;
	       NOP				 ;
	       DEC.B	 REG_R1 		 ;
	       BNE	 WR_RD_AD_LP_S1:8	  ;
WR_RD_AD_LP21:	AND.B	  #H'0F,B_H               ;
	       BLD	 SYS_210_ON		 ;;V2.0
	       BCC	 WR_RD_AD_LP31:8	  ;;
	       MOV.W	 #0,E1			 ;;
	       SUB.W	 #D'400,B_W              ;;
	       BCC	 OVER_4001:8		  ;;
	       MOV.W	 #H'0000,B_W             ;;
OVER_4001:	MOV.W	  #H'0005,ACC_W           ;;(X-400)*(5/4)
	       MULXU.W	 ACC_W,B_X		 ;;
	       SHLR.W	 B_W			 ;;
	       SHLR.W	 B_W			 ;;
INPUT_VOLT1:	CMP.W	  #H'0800,B_W             ;;Compare if saturation area
	       BCS	 WR_RD_AD_LP41:8	  ;;
	       MOV.W	 #H'07FF,B_W             ;;
	       BRA	 WR_RD_AD_LP41:8	  ;;
WR_RD_AD_LP31:	BLD	  SYS_210_2047		  ;;
	       BCS	 INPUT_VOLT1:8		  ;;
	       CMP.W	 #H'1000,B_W             ;;Compare if saturation area
	       BCS	 WR_RD_AD_LP41:8	  ;;
	       MOV.W	 #H'0FFF,B_W             ;;
WR_RD_AD_LP41: ;MOV.B	  B_REG,@DPTR		  ;
	      ;INC.L	 #1,DPTR		 ;
	      ;MOV.B	 B_H,@DPTR		 ;
	      ;INC.L	 #1,DPTR		 ;
	       MOV.W	 B_W,@DPTR		 ;;TP02
	       INC.L	 #2,DPTR		 ;;
	 ;;	 BCLR	   DA_LD1		   ;
	 ;;	BCLR	  AD_CS 		 ;;
	       BSET	 DA_LD1 		 ;<<<<<-------v1.631
	       BSET	 AD_CS			;;<<<<<-------v1.631
	       RTS				 ;
AD_CONV_TIME1:	MOV.B	  #D'35,REG_R2            ;next channel convert time
AD_CONV_LOOP1:	DEC.B	  REG_R2		  ;52 ACLK time  40
	       BNE	 AD_CONV_LOOP1:8	  ;
	       RTS				 ;
;**************************************************************************
;*********************	    AD_CONV2		 **************************
;**************************************************************************
;/* Module Name  :   AD_CONV2() 				   *********
;   Description  :   Processing 2nd AD module input data	  *********
;   Input data(y):   1st AD: V0965				  *********
;		     2nd AD: V0966				  *********
;		     3rd AD: V0967				  *********
;		     4th AD: V0968				  *********
;   From IC(X)	 :   LTC-1290					  *********
;   #210 = 01	 :   y = X					  *********
;   #210 = 02	 :   y = (X-400)*(2000/1600),if {X-400 < 0} then {X-400 = 0}
;**************************************************************************
AD_CONV2:      BLD	 AD_FILTER	       ;
	       BCS	 AD_IN_FILTER		 ;
	       BCLR	 IO_INT_BIT		 ;
	       MOV.B	 #B'10001110,ACC         ;write 1st channel command
	       MOV.L	 #H'000A0000,DPTR        ;pseudo address(reset WDT)
	       BSR	 WR_RD_AD_COMD		 ;
	       BSR	 AD_CONV_TIME		 ;
	       MOV.B	 #B'10011110,ACC         ;write 2nd channel command
	       MOV.L	 #V0965_ADDR,DPTR	 ;read	1st channel data
	       BSR	 WR_RD_AD_COMD		 ;
	       BSR	 AD_CONV_TIME		 ;
	       MOV.B	 #B'10101110,ACC         ;write 3rd channel command
	       MOV.L	 #V0966_ADDR,DPTR	 ;read	2nd channel data
	       BSR	 WR_RD_AD_COMD		 ;
	       BSR	 AD_CONV_TIME		 ;
	       MOV.B	 #B'10111110,ACC         ;write 4th channel command
	       MOV.L	 #V0967_ADDR,DPTR	 ;read	3rd channel data
	       BSR	 WR_RD_AD_COMD		 ;
	       BSR	 AD_CONV_TIME		 ;
	       MOV.B	 #B'11111110,ACC         ;write on board sensor command
	       MOV.L	 #V0968_ADDR,DPTR	 ;read	4th channel data
	       BSR	 WR_RD_AD_COMD		 ;
	       BSR	 AD_CONV_TIME		 ;
	       MOV.B	 #B'11111110,ACC         ;write psuedo command
	       MOV.L	 #V0970_ADDR,DPTR	 ;read on board sensor data
	       BSR	 WR_RD_AD_COMD		 ;
	       BLD	 IO_INT_BIT		 ;
	       BCS	 AD_CONV2		  ;
	       RTS				 ;
;;;;;;;;;;;;;;NEW ADDED ;;;;;;;;;;;;;;;;;;;;;;;;;;
AVER_2_ORDER:	 BLD	 AD_FILTER1		 ;;V0.D 4 TIMES
		 BCS	 AVER_2_ORDER12:8	  ;;
		 RTS				 ;;
;;;						 ;;
AVER_2_ORDER12:   BLD	  AD_2_D_ST0		   ;
		 BCS	 AVER_2_ORDER2:8	 ;
		 MOV.L	 DPTR,BUFF_PTR1 	 ;
		 MOV.B	 @AD_FILTER_TIMES2,ACC	  ;
		 MOV.B	 #0,ACC_H		 ;
		 SHLL.W  ACC_W			 ;
		 ADD.W	 ACC_W,DPTR_LW		 ;
		 MOV.W	 B_W,@DPTR		 ;
		 BLD	 AD_FILTER2		 ;
		 BCS	 AVER_2_ORDER112:8	  ;
		 ADD.L	 #8,BUFF_PTR1		 ;last time's average
		 MOV.W	 @BUFF_PTR1,B_W 	 ;
		 RTS				 ;
AVER_2_ORDER112:  ADD.L   #14,BUFF_PTR1 	  ;
		 MOV.W	 @BUFF_PTR1,B_W 	 ;
		 RTS				 ;
AVER_2_ORDER2:	 MOV.B	 #H'03,REG_R1            ;
		 MOV.W	 B_W,ACC_W		 ;
DIAG_4_TIMES:	 MOV.W	 @DPTR+,B_W		 ;
		 ADD.W	 B_W,ACC_W		 ;
		 DEC.B	 REG_R1 		 ;
		 BNE	 DIAG_4_TIMES:8 	 ;
		 SHLR.W  ACC_W			 ;
		 SHLR.W  ACC_W			 ;
		 MOV.W	 ACC_W,B_W		 ;
		 INC.L	 #2,DPTR		 ;
		 MOV.W	 ACC_W,@DPTR		 ;
		 BLD	 AD_FILTER2		 ;
		 BCS	 AVER_3_ORDER:8 	 ;;
		 RTS				 ;
AVER_3_ORDER:	 MOV.B	 @AD_OFFSET_TIMES,ACC	 ;
		 INC.B	 ACC			 ;
		 MOV.B	 ACC,@AD_OFFSET_TIMES	 ;
		 CMP.B	 #H'5,ACC                ;
		 BCS	 AD_3_ORDER_RET 	 ;
AVER_3_ORDER0:	 MOV.B	 #0,ACC 		 ;
		 MOV.B	 ACC,@AD_OFFSET_TIMES	 ;
		 ADD.L	 #2,DPTR		 ;
		 MOV.W	 @DPTR+,ACC_W		 ;
		 MOV.W	 @DPTR+,B_W		 ;
		 ADD.W	 ACC_W,B_W		 ;
		 SHLR.W  B_W			 ;
		 MOV.W	 B_W,@DPTR		 ;
		 SUB.L	 #2,DPTR		 ;
		 MOV.W	 #0,ACC_W		 ;
		 MOV.W	 ACC_W,@DPTR		 ;
		 SUB.L	 #2,DPTR		 ;
		 MOV.W	 #H'FFFF,ACC_W           ;
		 MOV.W	 ACC_W,@DPTR		 ;
		 RTS				 ;
AD_3_ORDER_RET:  ADD.L	 #2,DPTR		 ;
		 MOV.W	 @DPTR,ACC_W		 ;MIN
		 CMP.W	 B_W,ACC_W		 ;
		 BCS	 CHK_AD_3_MAX:8 	 ;
AD_3_NEW_MIN:	 MOV.W	 B_W,@DPTR		 ;
CHK_AD_3_MAX:	 ADD.L	 #2,DPTR		 ;
		 MOV.W	 @DPTR,ACC_W		 ;
		 CMP.W	 B_W,ACC_W		 ;
		 BCC	 AD_3_NEW_MAX12:8	 ;
AD_3_NEW_MAX:	 MOV.W	 B_W,@DPTR		 ;
AD_3_NEW_MAX12:   ADD.L   #2,DPTR		 ;
		 MOV.W	 @DPTR,B_W		 ;
		 RTS				 ;
;;;;;						 ;
AD_IN_FILTER:  BCLR	 IO_INT_BIT		 ;
	       MOV.L	 @AD_FILTER_BUFF2,DPTR	 ;
	       MOV.B	 #B'10001110,ACC         ;write 1st channel command
	       BSR	 WR_RD_AD_COMD		 ;
	       BSR	 AD_CONV_TIME		 ;
	       MOV.L	 @AD_FILTER_BUFF2,DPTR	 ;
	       MOV.B	 #B'10011110,ACC         ;write 2nd channel command
	       BSR	 WR_RD_AD_COMD		 ;
	       BSR	 AD_CONV_TIME		 ;
	       MOV.B	 #B'10101110,ACC         ;write 3rd channel command
	       BSR	 WR_RD_AD_COMD		 ;
	       BSR	 AD_CONV_TIME		 ;
	       MOV.B	 #B'10111110,ACC         ;write 4th channel command
	       BSR	 WR_RD_AD_COMD		 ;
	       BSR	 AD_CONV_TIME		 ;
	       MOV.B	 #B'11111110,ACC         ;write on board sensor command
	       BSR	 WR_RD_AD_COMD		 ;
	       BSR	 AD_CONV_TIME		 ;
	       PUSH.L	 DPTR			 ;
	       MOV.B	 #B'11111110,ACC         ;write pseudo command
	       MOV.L	 #V0970_ADDR,DPTR
	       BSR	 WR_RD_AD_COMD		 ;
	       POP.L	 DPTR
	       BLD	 IO_INT_BIT		 ;
	       BCS	 AD_IN_FILTER		 ;
	       CMP.L	 #AD_FILTER_ADDR4,DPTR	 ;
	       BCC	 RES_AD_PTR:8		 ;
	       MOV.L	 DPTR,@AD_FILTER_BUFF2	  ;
	       BRA	 CAL_AD_FILTER:8	 ;
RES_AD_PTR:    MOV.L	 #AD_FILTER_ADDR3,DPTR	 ;
	       MOV.L	 DPTR,@AD_FILTER_BUFF2	  ;
	       BSET	 AD_FILTER_ST		 ;
CAL_AD_FILTER: BLD	 AD_FILTER_ST		 ;
	       BCS	 STR_AD_FILTER:8	 ;
	       RTS				 ;
STR_AD_FILTER: MOV.B	 @AD_FILTER_TIMES2,ACC	  ;
	       INC.B	 ACC			 ;
	       CMP.B	 #H'03,ACC               ;
	       BCC	 STR_AD_F0:8		 ;
	       BCLR	 AD_2_D_ST0		  ;
	       MOV.B	 ACC,@AD_FILTER_TIMES2	  ;
	       BRA	 STR_AD_FILTER12:8	  ;;
STR_AD_F0:     BSET	 AD_2_D_ST0		  ;;
	       MOV.B	 #H'FF,ACC               ;;
	       MOV.B	 ACC,@AD_FILTER_TIMES2	  ;;
STR_AD_FILTER12: MOV.L	   #AD_FILTER_ADDR3,DPTR  ;;
	       BSR	 CAL_AD_MIN		 ;
	       BSR	 CAL_AD_MAX		 ;
	       BSR	 CAL_AD_AVER		 ;
	       MOV.L	 #V0965_BUFF,DPTR	 ;;V0.D
	       BSR	 AVER_2_ORDER		 ;;
	       MOV.W	 B_W,@V0965_ADDR	 ;
	       MOV.L	 #AD_FILTER_ADDR3,DPTR	 ;
	       INC.L	 #2,DPTR		 ;
	       BSR	 CAL_AD_MIN		 ;
	       BSR	 CAL_AD_MAX		 ;
	       BSR	 CAL_AD_AVER		 ;
	       MOV.L	 #V0966_BUFF,DPTR	 ;;V0.D
	       BSR	 AVER_2_ORDER		 ;;
	       MOV.W	 B_W,@V0966_ADDR	 ;
	       MOV.L	 #AD_FILTER_ADDR3,DPTR	 ;
	       INC.L	 #2,DPTR		 ;
	       INC.L	 #2,DPTR		 ;
	       BSR	 CAL_AD_MIN		 ;
	       BSR	 CAL_AD_MAX		 ;
	       BSR	 CAL_AD_AVER		 ;
	       MOV.L	 #V0967_BUFF,DPTR	 ;;V0.D
	       BSR	 AVER_2_ORDER		 ;;
	       MOV.W	 B_W,@V0967_ADDR	 ;
	       MOV.L	 #AD_FILTER_ADDR3,DPTR	 ;
	       INC.L	 #2,DPTR		 ;
	       INC.L	 #2,DPTR		 ;
	       INC.L	 #2,DPTR		 ;
	       BSR	 CAL_AD_MIN		 ;
	       BSR	 CAL_AD_MAX		 ;
	       BSR	 CAL_AD_AVER		 ;
	       MOV.L	 #V0968_BUFF,DPTR	 ;;V0.D
	       BSR	 AVER_2_ORDER		 ;;
	       MOV.W	 B_W,@V0968_ADDR	 ;
	       RTS				 ;
CAL_AD_MIN:    MOV.L	 DPTR,BUFF_PTR1 	 ;
	       MOV.B	 #D'4,REG_R1             ;
	       MOV.W	 @BUFF_PTR1+,ACC_W	 ;;V0.D
	       MOV.W	 ACC_W,@AD_MIN_BUFF2	  ;
CAL_MIN_LP:    ADD.L	 #D'6,BUFF_PTR1          ;
	       MOV.W	 @BUFF_PTR1+,ACC_W	 ;
	       MOV.W	 @AD_MIN_BUFF2,B_W	  ;
	       CMP.W	 B_W,ACC_W		 ;
	       BCS	 NEW_MIN:8		 ;
	       BRA	 NEW_MIN12:8		  ;
NEW_MIN:       MOV.W	 ACC_W,@AD_MIN_BUFF2	  ;
NEW_MIN12:	DEC.B	  REG_R1		  ;
	       BNE	 CAL_MIN_LP:8		 ;
	       RTS				 ;
CAL_AD_MAX:    MOV.L	 DPTR,BUFF_PTR1 	 ;
	       MOV.B	 #D'4,REG_R1             ;
	       MOV.W	 @BUFF_PTR1+,ACC_W	 ;;V0.D
	       MOV.W	 ACC_W,@AD_MAX_BUFF2	  ;
CAL_MAX_LP:    ADD.L	 #D'6,BUFF_PTR1          ;
	       MOV.W	 @BUFF_PTR1+,ACC_W	 ;
	       MOV.W	 @AD_MAX_BUFF2,B_W	  ;
	       CMP.W	 B_W,ACC_W		 ;
	       BCC	 NEW_MAX:8		 ;
	       BRA	 NEW_MAX12:8		  ;
NEW_MAX:       MOV.W	 ACC_W,@AD_MAX_BUFF2	  ;
NEW_MAX12:	DEC.B	  REG_R1		  ;
	       BNE	 CAL_MAX_LP:8		 ;
	       RTS				 ;
CAL_AD_AVER:   MOV.L	 DPTR,BUFF_PTR1 	 ;
	       MOV.W	 #H'00,B_W               ;
	       MOV.B	 #D'5,REG_R1             ;
CAL_AD_LP:     MOV.W	 @BUFF_PTR1+,ACC_W	 ;;V0.D
	       ADD.L	 #6,BUFF_PTR1		 ;
	       ADD.W	 ACC_W,B_W		 ;
	       DEC.B	 REG_R1 		 ;
	       BNE	 CAL_AD_LP:8		 ;
	       MOV.W	 @AD_MIN_BUFF2,ACC_W	  ;
	       SUB.W	 ACC_W,B_W		 ;
	       MOV.W	 @AD_MAX_BUFF2,ACC_W	  ;
	       SUB.W	 ACC_W,B_W		 ;
	       MOV.W	 #H'0,E1                 ;
	       MOV.W	 #D'3,R0                 ;
	       DIVXU.W	 R0,ER1 		 ;
	  ;;;  MOV.B	 B_H,ACC		 ;TP02 no need to xchg
	  ;;;  MOV.B	 B_REG,B_H		 ;high byte / low byte
	  ;;;  MOV.B	 ACC,B_REG		 ;
	       RTS				 ;
WR_RD_AD_COMD: BSET	 DA_LD1 		 ;
	       BSET	 AD_CS			 ;
	       NOP				 ;
	       NOP				 ;
	       NOP				 ;
	       NOP				 ;
	       MOV.B	 #D'12,REG_R1            ;
WR_RD_AD_LP_S: SHLL.B	 ACC			 ;
	       BST	 AD_DOUT		 ;
WR_RD_AD_LP:   BILD	 AD_DINP		 ;
	       BCS	 WR_RD_AD_LP12:8	  ;
WR_RD_AD_LP0:  BIOR	 AD_DINP		 ;MSB first
	       BCS	 WR_RD_AD_LP:8		 ;
	       ROTXL.W	 B_W			 ;
	       NOP				 ;
	       NOP				 ;
	       NOP				 ;
	       NOP				 ;
	       BSET	 IO_SCLK		 ;
	       NOP				 ;;V2.0H
	       NOP				 ;;
	       NOP				 ;;
	       NOP				 ;;
	       BCLR	 IO_SCLK		 ;
	       NOP				 ;
	       NOP				 ;
	       NOP				 ;
	       NOP				 ;
	       NOP				 ;
	       DEC.B	 REG_R1 		 ;
	       BNE	 WR_RD_AD_LP_S:8	 ;
	       BRA	 WR_RD_AD_LP2:8 	 ;
WR_RD_AD_LP12:	BIAND	  AD_DINP		  ;
	       BCC	 WR_RD_AD_LP:8		 ;
	       ROTXL.W	 B_W			 ;
	       NOP				 ;
	       NOP				 ;
	       NOP				 ;
	       NOP				 ;
	       BSET	 IO_SCLK		 ;
	       NOP				 ;;V2.0H
	       NOP				 ;;
	       NOP				 ;;
	       NOP				 ;;
	       BCLR	 IO_SCLK		 ;
	       NOP				 ;
	       NOP				 ;
	       NOP				 ;
	       NOP				 ;
	       NOP				 ;
	       DEC.B	 REG_R1 		 ;
	       BNE	 WR_RD_AD_LP_S:8	 ;
WR_RD_AD_LP2:  AND.B	 #H'0F,B_H               ;
	       BLD	 SYS_210_ON		 ;;V2.0
	       BCC	 WR_RD_AD_LP3:8 	 ;;
	       MOV.W	 #0,E1			 ;;
	       SUB.W	 #D'400,B_W              ;;
	       BCC	 OVER_400:8		 ;;
	       MOV.W	 #H'0000,B_W             ;;
OVER_400:      MOV.W	 #H'0005,ACC_W           ;;(X-400)*(5/4)
	       MULXU.W	 ACC_W,B_X		 ;;
	       SHLR.W	 B_W			 ;;
	       SHLR.W	 B_W			 ;;
INPUT_VOLT:    CMP.W	 #H'0800,B_W             ;;Compare if saturation area
	       BCS	 WR_RD_AD_LP4:8 	 ;;
	       MOV.W	 #H'07FF,B_W             ;;
	       BRA	 WR_RD_AD_LP4:8 	 ;;
WR_RD_AD_LP3:  BLD	 SYS_210_2047		 ;;
	       BCS	 INPUT_VOLT:8		 ;;
	       CMP.W	 #H'1000,B_W             ;;Compare if saturation area
	       BCS	 WR_RD_AD_LP4:8 	 ;;
	       MOV.W	 #H'0FFF,B_W             ;;
WR_RD_AD_LP4: ;MOV.B	 B_REG,@DPTR		 ;
	      ;INC.L	 #1,DPTR		 ;
	      ;MOV.B	 B_H,@DPTR		 ;
	      ;INC.L	 #1,DPTR		 ;
	       MOV.W	 B_W,@DPTR		 ;;TP02
	       INC.L	 #2,DPTR		 ;;
	       BSET	 DA_LD1 		 ;v1.631
	       BSET	 AD_CS			 ;v1.631
	       RTS				 ;
AD_CONV_TIME:  MOV.B	 #D'35,REG_R2            ;next channel convert time
AD_CONV_LOOP:  DEC.B	 REG_R2 		 ;52 ACLK time	40
	       BNE	 AD_CONV_LOOP:8 	 ;
	       RTS				 ;
;V1.61	end
;
; DUMP LOOP subroutine				;
DUMP_LOOP:	MOV.B	REG_R2,REG_R1		;total bytes = 128 =8*16
DUMP_LOP:	MOV.B	@DPTR,ACC		;
		MOV.B	ACC,@BUFF_PTR1		;
		INC.L	#1,DPTR 		;
		INC.L	#1,BUFF_PTR1		;
		DEC.B	REG_R1			;
		BNE	DUMP_LOP:8		;
		JSR	@DELAY_10MS		; V0.4
		MOV.B	@TIME_BASE1,ACC 	;;STOP MODE LED REFLESH
		BLD	#5,ACC			;;
		BST	RUN_LED 		;;
		DEC.B	REG_R0			;
		BNE	DUMP_LOOP:8		;
		RTS				;
;===== TP02 ROM OPERATION MEMORY MAP ======
;    PACK ADDR	 FLASH ADDR			      PLC ADDRESS(DPTR)
;			   ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;    80000H	 10000H    ³ User's instruction     ³    F0000H
;			   ³  (4001 words)	    ³	 F1F41H
;      |	   |	   ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;			   ³ Spare area 	    ³	 F1F42H
;      |  (128*94) |	   ³			    ³	 F1F4FH
;			   ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;      |	   |	   ³ User's NU CODE         ³    F1F50H
;			   ³  (4001 bytes)	    ³	 F2EF0H
;      |	   |	   ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;			   ³ Spare area 	    ³	 F2EF1H
;    82EFFH	 12EFFH    ³			    ³	 F2EFFH
; ------------------------ ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´ -----------------
;    82F00H	 12F00H    ³ System register	    ³	 FDEC0H
;			   ³ WS001-WS128(256 bytes) ³	 FDFBFH
;      |	   |	   ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;			   ³ CONSTANT REGISTER	    ³	 FDFC0H
;      |	   |	   ³ WC001-WC512(1024 bytes)³	 FE3BEH
;	  (128*34)	   ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;      |	   |	   ³ FILE001-FILE150	    ³	 FE3C0H
;		(13F80)    ³ (20*150=3000 bytes)    ³	 FEF77H  (EF40H)
;      |	   |	   ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;			   ³ SPARE AREA 	    ³	 FEF78H
;      |	   |	   ³			    ³	 FEFBCH
;			   ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    83FFDH	 13FFDH    ³ Exist check code #37   ³	 FEFBDH
;			   ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    83FFEH	 13FFEH    ³ Exist check code #C8   ³	 FEFBEH
;			   ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;    83FFFH	 13FFFH    ³ CHECKSUM CODE	    ³	 FEFBFH  (EFBFH)
;			   ³10000-13FFF SUM = FF    ³
;			   ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
DUMP_FLASH_SYS: .EQU	 $			 ;;VF.0
	       BCLR	 #RE,@SCR1		 ;;;V1.4
	       BSET	 JUDGE_NG		 ;;
	       BRA	 DUMP_FLASH0:8		 ;;
DUMP_FLASH:    BCLR	 JUDGE_NG		 ;;
	       BCLR	 #RE,@SCR1		 ;;VF.0
	       MOV.B	 #H'FF,ACC               ;;
	       MOV.L	 #X1_X8_BUFF,DPTR	 ;;
LED_BUFF_CLR2: MOV.B	 ACC,@DPTR		 ;;
	       INC.L	 #1,DPTR		 ;;
	       CMP.L	 #Y21_Y24_BUFF+1,DPTR	 ;;V0.A
	       BNE	 LED_BUFF_CLR2:8	 ;;V0.A
DUMP_FLASH0:   MOV.L	 #DUMP_FLASH1,ER5	 ;;TEST FLASH MEMORY
	       MOV.L	 #H'000FF800,ER6         ;;
	       MOV.B	 #D'255,R4L              ;;V0.A
	       EEPMOV.B 			 ;;
	       MOV.B	 #D'255,R4L              ;;50
	       EEPMOV.B 			 ;;
	       JMP	 @H'000FF800             ;;
;;;						 ;;
DUMP_FLASH1: ;;BCLR	 #RE,@SCR0		 ;;VF.0
	       BLD	 JUDGE_NG		 ;;
	       BCC	 DUMP_FLASH11:8 	 ;;
	       MOV.L	 #H'000FDEC0,ER5         ;;DUMP SYSTEM MEMORY WSXXX
	       MOV.L	 #H'00012F00,ER6         ;;
	       BSR	 RAM_TO_FLASH		 ;;
	       BRA	 FLASH_CHKSUM:8 	 ;;
DUMP_FLASH11:  MOV.L	 #H'000F0000,ER5         ;;DUMP PROGRAM
	       MOV.L	 #H'00010000,ER6         ;;
	       MOV.B	 #D'47,R4H               ;;V1.632 D'94->D'47
DUMP_FLA_LP:   PUSH.W	 R4			;;V1.632
	       BSR	 RAM_TO_FLASH		 ;;
	       POP.W	 R4			 ;;V1.632
	       MOV.B	 @H'000A0000,R3L         ;;RESET WDT
	       DEC.B	 R4H			 ;;
	       BNE	 DUMP_FLA_LP:8		 ;;
DUMP_FLASH2:   MOV.L	 #H'000FDEC0,ER5         ;;DUMP CONSTANT DATA
	       MOV.L	 #H'00012F00,ER6         ;;V0.A
	       MOV.B	 #D'17,R4H               ;;V1.632 D'34->D'17
DUMP_FLA_LP1:  PUSH.W	 R4			 ;;V1.632
	       BSR	 RAM_TO_FLASH		 ;;
	       MOV.B	 @H'000A0000,R3L         ;;RESET WDT
	       POP.W	 R4			 ;;V1.632
	       DEC.B	 R4H			 ;;
	       BNE	 DUMP_FLA_LP1:8 	 ;;
FLASH_CHKSUM:  MOV.L	 #H'00010000,ER5         ;;
	       MOV.B	 #H'0,R0H                ;;
FLASH_SUM_LP:  MOV.B	 @ER5+,R0L		 ;;
	       ADD.B	 R0L,R0H		 ;;
	       CMP.L	 #H'00013FFD,ER5         ;;
	       BNE	 FLASH_SUM_LP:8 	 ;;
	       ADD.B	 #H'37,R0H               ;;
	       ADD.B	 #H'C8,R0H               ;;
	       NOT.B	 R0H			 ;;
	       MOV.B	 R0H,@R6L_BUFFER	 ;;CHECKSUM CODE
	       MOV.L	 #H'00013F00,ER5         ;;13F80->13F00
	       MOV.L	 #H'000FEEF8,ER6         ;;V1.632 FEF78->FEEF8
	       MOV.W	 #D'253,R4               ;;V1.632 125->253
	       EEPMOV.W 			 ;;
	       MOV.B	 #H'37,R0H               ;;
	       MOV.B	 R0H,@ER6		 ;;
	       INC.L	 #1,ER6 		 ;;
	       MOV.B	 #H'C8,R0H               ;;
	       MOV.B	 R0H,@ER6		 ;;
	       INC.L	 #1,ER6 		 ;;
	       MOV.B	 @R6L_BUFFER,R0H	 ;;
	       MOV.B	 R0H,@ER6		 ;;
	       MOV.L	 #H'000FEEF8,ER5         ;;V1.1  V1.632 FEF78->FEEF8
	       MOV.L	 #H'00013F00,ER6         ;;V1.632 13F80->13F00
	       BSR	 RAM_TO_FLASH1		 ;;
	       BCLR	 #RDRF,@SSR1		 ;;V1.4
	       BSET	 #RE,@SCR1		 ;;V1.4
	       RTS				 ;;
RAM_TO_FLASH:  MOV.L	 ER5,ER1		 ;;;V0.A
	       MOV.L	 ER6,ER2		 ;;;
	       MOV.B	 #D'0,R0L                ;;V1.632 D'128->D'0
RAM_TO_F_LP:   MOV.B	 @ER1+,R3L		 ;;
	       MOV.B	 @ER2+,R3H		 ;;
	       CMP.B	 R3L,R3H		 ;;;
	       BNE	 RAM_TO_FLASH1:8	 ;;;
	       DEC.B	 R0L			 ;;;
	       BNE	 RAM_TO_F_LP:8		 ;;;
	       ADD.L	 #D'256,ER5              ;;V1.632  D'128->D'256
	       ADD.L	 #D'256,ER6              ;;V1.632  D'128->D'256
	       RTS				 ;;;
RAM_TO_FLASH1: MOV.W	 #H'FFFF,R3              ;;VF.3
RAM_TO_FLASH11: BLD	  #RE,@SCR0		  ;VF.3
	       BCS	 RAM_TO_FLASH2:8	 ;If TX mode, then wait !
	       DEC.W	 #1,R3			 ;;
	       BNE	 RAM_TO_FLASH11:8	 ;;
RAM_TO_FLASH2: ORC	 #B'10000000,CCR         ;;
	       MOV.B	 @LED_DRIVER,R0L	 ;;
	       OR.B	 #B'00000100,R0L         ;;
	       MOV.B	 R0L,@H'000C0000         ;;
	       MOV.B	 #B'11110011,R0L         ;;TEST 3-WAIT STATE
	       MOV.B	 R0L,@WCR		 ;;
	       MOV.B	 #H'AA,R0L               ;;
	       MOV.B	 #H'55,R0H               ;;
	       MOV.B	 #H'A0,R3L               ;;
	       MOV.W	 #D'256,R4               ;; V0.A ;;V1.632  D'128->D'256
	       MOV.W	 #H'000F,E5              ;; V0.A
	       MOV.W	 #H'0001,E6              ;; V0.A
	       MOV.B	 R0L,@H'00005555         ;;
	       MOV.B	 R0H,@H'00002AAA         ;;
	       MOV.B	 R3L,@H'00005555         ;;
	       EEPMOV.W 			 ;;EEPMOV.B->EEPMOV.W
DELAY_20MS:    MOV.W	 #D'4200,R3              ;;8400
DELAY_LP:      BLD	 #RDRF,@SSR0		 ;;;
	       BCC	 DELAY_LP1:8		 ;;;
	       BSR	 ROM_SERIAL_RX		 ;;;
DELAY_LP1:     DEC.W	 #1,R3			 ;;(1*6+2*6)*K*8192=10mS
	       BNE	 DELAY_LP:8		 ;;(1*12+2*12)*J*4096=10mS
	       MOV.B	 @LED_DRIVER,R0L	 ;;
	       MOV.B	 R0L,@H'000C0000         ;;
	       MOV.B	 #B'11110000,R0L         ;;TEST 3-WAIT STATE V0.A
	       MOV.B	 R0L,@WCR		 ;;
	       MOV.B	 @TIME_BASE1,R3L	 ; STOP MODE LED REFLESH
	       BLD	 #5,R3L 		 ;
	       BOR	 RUN_FLAG		 ;
	       BST	 RUN_LED		 ;
	       ANDC	 #B'01111111,CCR         ;;
	       RTS				 ;;
;;;;
ROM_SERIAL_RX: .EQU	 $			    ;
	       PUSH.W	 ACC_W			    ;
	       PUSH.L	 DPTR			    ;
	       BLD	 PGBRT			    ; V0.4
	       BCS	 SERIAL_RXI0PG:8	    ; TP02
	       BRA	 RECEIVE_OVER0E:8	    ;
RECEIVE_OVER0: BSET	 RXENDF0		    ;Set bit the receive
	       BCLR	 REQ_START_FG0		    ;;;PG PORT FOR COMMPU
	       BCLR	 BYTE_CNT_OK		    ;;TP02
RECEIVE_OVER0E: POP.L	  DPTR			    ;
	       POP.W	 ACC_W			    ;
	       RTS				    ;
;========  PG port PG protocol link ==========	    ;
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
	       BLD	 #7,ACC 		    ;
	       BCC	 JUDGE_OK0RET:8 	    ;
	       CMP.B	 #H'F1,ACC                  ;F0
	       BEQ	 RESET_FRAME:8		    ;
	       CMP.B	 #H'F6,ACC                  ;F5
	       BNE	 JUDGE_OK0RET:8 	    ;
RESET_FRAME:   BCLR	 BYTE_CNT_OK		    ;
	       MOV.L	 #PG_STX,DPTR		    ;
	       BRA	 SERIAL_RX_S:8		    ;
JUDGE_OK0PG:   MOV.B	 @BYTE_COUNTER,ACC	    ;
	       DEC.B	 ACC			    ;
	       MOV.B	 ACC,@BYTE_COUNTER	    ;
	       BEQ	 RECEIVE_OVER0		    ;
JUDGE_OK0RET:  POP.L	 DPTR			    ;
	       POP.W	 ACC_W			    ;
NXT_BYTEPG:    RTS				    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LOAD_FLASH:    MOV.L	 #WS050_ADDR,ER5	 ;;V1.0
	       MOV.L	 #PG_EXT,ER6		 ;;
	       MOV.B	 #D'16,R4L               ;;
	       EEPMOV.B 			 ;;
LOAD_FLASH1:   MOV.L	 #H'00010000,ER5         ;;LOAD PROGRAM
	       MOV.L	 #H'000F0000,ER6         ;;
	       MOV.B	 #D'94,R4H               ;;
LOAD_FLA_LP:   MOV.B	 #D'128,R4L              ;;
	       EEPMOV.B 			 ;;
	       DEC.B	 R4H			 ;;
	       BNE	 LOAD_FLA_LP:8		 ;;
	       MOV.L	 #H'000FDEC0,ER6         ;;DUMP CONSTANT DATA
	       MOV.B	 #D'34,R4H               ;;
LOAD_FLA_LP1:  MOV.B	 #D'128,R4L              ;;
	       EEPMOV.B 			 ;;
	       DEC.B	 R4H			 ;;
	       BNE	 LOAD_FLA_LP1:8 	 ;;
	       MOV.L	 #WS050_ADDR,ER6	 ;;V1.0
	       MOV.L	 #PG_EXT,ER5		 ;;
	       MOV.B	 #D'16,R4L               ;;
	       EEPMOV.B 			 ;;
	       RTS				 ;;
;;;
FLASH_CHECKSUM:
	       MOV.L	 #H'00010000,ER5
	       MOV.B	 #H'0,R0H
F_C_LP:        MOV.B	 @ER5+,R0L
	       ADD.B	 R0L,R0H
	       CMP.L	 #H'00014000,ER5
	       BNE	 F_C_LP:8
	       CMP.B	 #H'FF,R0H
	       BNE	 F_C_ERR:8
	       BCLR	 JUDGE_NG
	       RTS
F_C_ERR:       BSET	 JUDGE_NG
	       RTS
EEPROM_CHECKSUM:
	    ;; MOV.B	 #B'11110011,R0H         ;;V1.1
	    ;; MOV.B	 R0H,@WCR		 ;;
	       MOV.L	 #H'00080000,ER5
	       MOV.B	 #H'0,R0H
E_C_LP:        MOV.B	 @ER5+,R0L
	       ADD.B	 R0L,R0H
	       CMP.L	 #H'00084000,ER5
	       BNE	 E_C_LP:8
	       CMP.B	 #H'FF,R0H
	       BNE	 F_C_ERR:8
	       BCLR	 JUDGE_NG
	    ;; MOV.B	 #B'11110000,R0H         ;;V1.1
	    ;; MOV.B	 R0H,@WCR		 ;;
	       RTS
;*******************************************************************************
;******************  DUMP USER MEMORY FORM PLC TO EEPROM  **********************
;*******************************************************************************
DUMP_EEPROM:   MOV.L	 #H'000F0000,ER5         ;;DUMP PROGRAM
	       MOV.L	 #H'00080000,ER6         ;;
	       MOV.B	 #D'188,R4H              ;;
DUMP_EE_LP:    MOV.B	 #D'64,R4L               ;;
	       EEPMOV.B 			 ;;
	       JSR	 @DELAY_10MS		 ;;
	       MOV.B	 R4H,@H'000A0000         ;;RESET WDT
	       DEC.B	 R4H			 ;;
	       BNE	 DUMP_EE_LP:8		 ;;
DUMP_EEPROM2:  MOV.L	 #H'000FDEC0,ER5         ;;DUMP CONSTANT DATA
	       MOV.B	 #D'68,R4H               ;;
DUMP_EE_LP1:   MOV.B	 #D'64,R4L               ;;
	       EEPMOV.B 			 ;;
	       JSR	 @DELAY_10MS		 ;;
	       MOV.B	 R4H,@H'000A0000         ;;RESET WDT
	       DEC.B	 R4H			 ;;
	       BNE	 DUMP_EE_LP1:8		 ;;
EEPRO_CHKSUM:  MOV.L	 #H'00080000,ER5         ;;
	       MOV.B	 #H'0,R0H                ;;
EEPRO_SUM_LP:  MOV.B	 @ER5+,R0L		 ;;
	       ADD.B	 R0L,R0H		 ;;
	       CMP.L	 #H'00083FFD,ER5         ;;
	       BNE	 EEPRO_SUM_LP:8 	 ;;
	       ADD.B	 #H'37,R0H               ;;
	       ADD.B	 #H'C8,R0H               ;;
	       NOT.B	 R0H			 ;;
	       MOV.B	 R0H,@R6L_BUFFER	 ;;CHECKSUM CODE
	       MOV.L	 #H'00083F80,ER5         ;;
	       MOV.L	 #H'000FEFC0,ER6         ;;;V1.1
	       MOV.B	 #D'125,R4L              ;;
	       EEPMOV.B 			 ;;
	       MOV.B	 #H'37,R0H               ;;
	       MOV.B	 R0H,@ER6		 ;;
	       INC.L	 #1,ER6 		 ;;
	       MOV.B	 #H'C8,R0H               ;;
	       MOV.B	 R0H,@ER6		 ;;
	       INC.L	 #1,ER6 		 ;;
	       MOV.B	 @R6L_BUFFER,R0H	 ;;
	       MOV.B	 R0H,@ER6		 ;;
	       MOV.L	 #H'000FEFC0,ER5         ;;;V1.1
	       MOV.L	 #H'00083F80,ER6         ;;
	       MOV.B	 #D'64,R4L               ;;
	       EEPMOV.B 			 ;;
	       JSR	 @DELAY_10MS		 ;;
	       MOV.B	 #D'64,R4L               ;;
	       EEPMOV.B 			 ;;
	       JSR	 @DELAY_10MS		 ;;
	       RTS				 ;;
;******************************************************************************
;*******************  LOAD USER MEMORY FORM PACK TO P/C  **********************
;******************************************************************************
;****** BLOCK 1 :load user memory , total 8192 bytes = 4k words ****************
LOAD_EEPROM: ;;MOV.B	 #B'11110011,R4L         ;;V1.1
	     ;;MOV.B	 R4L,@WCR		 ;;
	       MOV.L	 #H'00080000,ER5         ;;LOAD PROGRAM
	       MOV.L	 #H'000F0000,ER6         ;;
	       MOV.B	 #D'188,R4H              ;;
LOAD_EE_LP:    MOV.B	 #D'64,R4L               ;;
	       EEPMOV.B 			 ;;
	       DEC.B	 R4H			 ;;
	       BNE	 LOAD_EE_LP:8		 ;;
	       MOV.L	 #H'000FDEC0,ER6         ;;DUMP CONSTANT DATA
	       MOV.B	 #D'68,R4H               ;;
LOAD_EE_LP1:   MOV.B	 #D'64,R4L               ;;
	       EEPMOV.B 			 ;;
	       DEC.B	 R4H			 ;;
	       BNE	 LOAD_EE_LP1:8		 ;;
	    ;; MOV.B	 #B'11110000,R4L         ;;V1.1
	    ;; MOV.B	 R4L,@WCR		 ;;
	       RTS				 ;;
;;;;
DELAY_10MS:  ;	MOV.B	@TIME_BASE1,ACC 	; STOP MODE LED REFLESH
	     ;	BLD	#5,ACC			;
	     ;	BST	RUN_LED 		;
		MOV.B	@H'000A0000,ACC         ; Reset WDT
DELAY_1MS:	MOV.W	#D'14000,E4             ;V2.3D Twc=20mS,RECOMMEND BY SMS
DELAY_LOOP:	DEC.W	#1,E4			;1*8  BUS TO BE ONE WAIT
		BNE	DELAY_LOOP:8		;2*8  STATE WHEN WRITE TO
		RTS				;EEPROM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ------- High speed counter mode setting  ------ ;
HSC_INIT:      MOV.W	 @WS058_ADDR,R0 	  ;
	       CMP.W	 #1,R0			  ;
	       BNE	 HSC_INIT1:8		  ;
HSC_INIT0:     BSET	 HSC_RESET		  ;
	       BRA	 WS039_040_SET:8	  ;
HSC_INIT1:     BCLR	 HSC_RESET		  ;;V1.7
	       MOV.W	 @LAST_HSC_MODE,R0	  ;
	       MOV.W	 @WS059_ADDR,R1 	  ;
	       CMP.W	 #0,R1			  ;
	       BEQ	 INT_INIT		  ;
	       BRA	 INT_INIT1:8		  ;
INT_INIT:      MOV.W	 @WS060_ADDR,R1 	  ;
INT_INIT1:     MOV.W	 R1,@LAST_HSC_MODE	  ;
	       CMP.W	 R1,R0			  ;
	       BNE	 HSC_INIT0:8		  ;
	       BCLR	 HSC_RESET		  ;
WS039_040_SET: MOV.W	 @WS059_ADDR,R0 	  ;
WS039_0:       CMP.W	 #0,R0			  ;
	       BNE	 WS039_1
	       BCLR	 HSC_MODE
	       BSET	 IMIB2_LB
	       BSET	 IMIB3_LB
	       BCLR	 IMIB3_LB112
	       BSET	 IMIB4_LB
	       BCLR	 IMIB4_LB113
	       MOV.W	 @WS060_ADDR,R3
	       CMP.W	 #0,R3
	       BEQ	 NORMAL_INPUT
	   ;;; BLD	 HSC_RESET
	   ;;; BCC	 WS039_0_1:8
RESET_INT0:    MOV.W	 #0,R1
	       MOV.W	 R1,@TCNT1
	       MOV.W	 R1,@GRB1
	       MOV.W	 R1,@TCNT2
	       MOV.W	 R1,@GRB2
	       MOV.W	 R1,@TCNT3
	       MOV.W	 R1,@GRB3
	       MOV.W	 R1,@TCNT4
	       MOV.W	 R1,@GRB4
WS039_0_1:     BSR	 WS040_COMMON
WS040_1:       CMP.W	 #1,R3
	       BNE	 WS040_2:8
	       MOV.B	 #H'F8,R0L
	       MOV.B	 R0L,@TIER2  ;Disable TCNT2-TCNT4
	       MOV.B	 R0L,@TIER3
	       MOV.B	 R0L,@TIER4
	       MOV.B	 #H'E3,R0L
	       MOV.B	 R0L,@TSTR
	       RTS
WS040_2:       CMP.W	 #2,R3
	       BNE	 WS040_3:8
	       MOV.B	 #H'C5,R0L
	       MOV.B	 R0L,@TCR2   ;TCNT2 is cleared by GRB compare match
	       MOV.B	 R0H,@GRB2   ;Reset GRB2
	       MOV.B	 R1H,@TIER2  ;
	       MOV.B	 #H'F8,R0L   ;
	       MOV.B	 R0L,@TIER3  ;Disable TCNT3-TCNT4
	       MOV.B	 R0L,@TIER4
	       MOV.B	 #H'E7,R0L
	       MOV.B	 R0L,@TSTR
	       RTS
WS040_3:       CMP.W	 #3,R3
	       BNE	 WS040_4:8
	       MOV.B	 #H'C5,R0L
	       MOV.B	 R0L,@TCR2   ;
	       MOV.B	 #H'C6,R0L
	       MOV.B	 R0L,@TCR3   ;
	       MOV.B	 R0H,@GRB2   ;Reset GRB2
	       MOV.B	 R0H,@GRB3   ;Reset GRB3
	       MOV.B	 R1H,@TIER2  ;
	       MOV.B	 R1H,@TIER3  ;
	       MOV.B	 #H'F8,R0L   ;
	       MOV.B	 R0L,@TIER4  ;Disable TCNT4
	       MOV.B	 #H'EF,R0L
	       MOV.B	 R0L,@TSTR
	       RTS
WS040_4:       CMP.W	 #4,R3	     ;
	       BNE	 NORMAL_INPUT;
	       MOV.B	 #H'C5,R0L   ;
	       MOV.B	 R0L,@TCR2   ;
	       MOV.B	 #H'C6,R0L   ;
	       MOV.B	 R0L,@TCR3   ;
	       MOV.B	 #H'C7,R0L   ;
	       MOV.B	 R0L,@TCR4   ;
	       MOV.B	 R0H,@GRB2   ;Reset GRB2
	       MOV.B	 R0H,@GRB3   ;Reset GRB3
	       MOV.B	 R0H,@GRB4   ;Reset GRB4
	       MOV.B	 R1H,@TIER2  ;
	       MOV.B	 R1H,@TIER3  ;
	       MOV.B	 R1H,@TIER4  ;
	       MOV.B	 #H'FF,R0L
	       MOV.B	 R0L,@TSTR
	       RTS
;;;;SUBROUTINE;;;;;;
WS040_COMMON:  MOV.B	 #H'C4,R0L   ;TCNT1,TCNT2,TCNT3,TCNT4 is cleared by GRB
	       MOV.B	 R0L,@TCR1   ;compare match with TCLKA,TCLKB,TCLKC,TCLKD
	       MOV.B	 #H'80,R1L   ;
	       MOV.B	 R1L,@TMDR   ;Reset TMDR
	       MOV.B	 #H'00,R0H   ;
	       MOV.B	 R0H,@GRB1   ;Reset GRB1
	       MOV.B	 #H'FA,R1H   ;Set IMIEB interrupt enable
	       MOV.B	 R1H,@TIER1  ;
	       RTS
;;;;;;;;;;;;;;;;;;;;
;;MODE1;;

WS039_1:       BSET	 HSC_MODE
	       CMP.W	 #1,R0
	       BNE	 WS039_2:8
	       BCLR	 IMIB3_LB
	       MOV.B	 #H'80,R0L
	       MOV.B	 R0L,@TCR1
	       MOV.B	 R0L,@TCR2
	       MOV.B	 R0L,@TCR4
	       MOV.B	 #H'C6,R0L
	       MOV.B	 R0L,@TCR3
	       MOV.B	 #H'C0,R0L
	       MOV.B	 R0L,@TMDR
	       BLD	 HSC_RESET	;TEST
	       BCS	 WS039_1_RESET	;
	       BSR	 TCNT2_PRESET	;
	       RTS			;
WS039_1_RESET  BSR	 TCNT2_RESET
	       MOV.W	 #0,R0
	       MOV.W	 R0,@GRB3
	       RTS
;;MODE2;;
WS039_2:       CMP.W	 #2,R0
	       BNE	 WS039_3:8
	       BSET	 IMIB3_LB
	       BSET	 IMIB3_LB112
	       BSET	 IMIB4_LB
	       BSET	 IMIB4_LB113
	       MOV.B	 #H'80,R0L       ;TEST
	       MOV.B	 R0L,@TCR1
	       MOV.B	 R0L,@TCR2
	       MOV.B	 #H'86,R0L
	       MOV.B	 R0L,@TCR3
	       MOV.B	 #H'87,R0L
	       MOV.B	 R0L,@TCR4
	       MOV.B	 #H'C0,R0L
	       MOV.B	 R0L,@TMDR
	       BLD	 HSC_RESET
	       BCS	 WS039_2_RESET:8
	       BSR	 TCNT2_PRESET
	       MOV.W	 @V1003_ADDR,R0
	       MOV.W	 R0,@TCNT3
	       MOV.W	 @V1005_ADDR,R0
	       MOV.W	 R0,@TCNT4
	       RTS
WS039_2_RESET: BSR	 TCNT2_RESET
	       MOV.W	 #0,R0
	       MOV.W	 R0,@V1003_ADDR
	       MOV.W	 R0,@TCNT3
	       MOV.W	 R0,@V1005_ADDR
	       MOV.W	 R0,@TCNT4
	       RTS
;;MODE3;;
WS039_3:       CMP.W	 #3,R0
	       BNE	 WS039_4:8
	       BSET	 IMIB2_LB
	       BSET	 IMIB3_LB
	       BCLR	 IMIB3_LB112
	       BSET	 IMIB4_LB
	       BCLR	 IMIB4_LB113
	       MOV.B	 #H'84,R0L
	       MOV.B	 R0L,@TCR1
	       MOV.B	 #H'85,R0L
	       MOV.B	 R0L,@TCR2
	       MOV.B	 #H'86,R0L
	       MOV.B	 R0L,@TCR3
	       MOV.B	 #H'87,R0L
	       MOV.B	 R0L,@TCR4
	       MOV.B	 #H'80,R0L
	       MOV.B	 R0L,@TMDR
	       BLD	 HSC_RESET
	       BCS	 WS039_3_RESET
	       BSR	 TCNT_PRESET
	       MOV.W	 @V1003_ADDR,R0
	       MOV.W	 R0,@TCNT2
	       MOV.W	 @V1005_ADDR,R0
	       MOV.W	 R0,@TCNT3
	       MOV.W	 @V1007_ADDR,R0
	       MOV.W	 R0,@TCNT4
	       RTS
WS039_3_RESET: BSR	 TCNT_RESET
	       MOV.W	 #0,R0
	       MOV.W	 R0,@V1003_ADDR
	       MOV.W	 R0,@V1005_ADDR
	       MOV.W	 R0,@V1007_ADDR
	       RTS
;;MODE4;;
WS039_4:       CMP.W	 #4,R0
	       BNE	 WS039_5:8
	       BCLR	 IMIB2_LB
	       BSET	 IMIB3_LB
	       BSET	 IMIB3_LB112
	       BCLR	 IMIB4_LB
	       MOV.B	 #H'84,R0L
	       MOV.B	 R0L,@TCR1
	       MOV.B	 #H'C5,R0L
	       MOV.B	 R0L,@TCR2
	       MOV.B	 #H'86,R0L
	       MOV.B	 R0L,@TCR3
	       MOV.B	 #H'C7,R0L
	       MOV.B	 R0L,@TCR4
	       MOV.B	 #H'80,R0L
	       MOV.B	 R0L,@TMDR
	       BLD	 HSC_RESET
	       BCS	 WS039_4_RESET
	       BSR	 TCNT_PRESET
	       MOV.W	 @V1003_ADDR,R0
	       MOV.W	 R0,@TCNT3
	       RTS
WS039_4_RESET: BSR	 TCNT_RESET
	       MOV.W	 #0,R0
	       MOV.W	 R0,@GRB2
	       MOV.W	 R0,@V1003_ADDR
	       MOV.W	 R0,@GRB4
	       RTS
;;MODE5;;
WS039_5:       CMP.W	 #5,R0
	       BNE	 WS039_6:8
	       BSET	 IMIB2_LB
	       BSET	 IMIB3_LB
	       BCLR	 IMIB3_LB112
	       BSET	 IMIB4_LB
	       BCLR	 IMIB4_LB113
	       BLD	 HSC_RESET
	       BCS	 WS039_5_RESET
	       BSR	 TCNT_PRESET
	       BRA	 WS039_5_1:8
WS039_5_RESET: BSR	 TCNT_RESET
	       MOV.W	 #0,R0
	       MOV.W	 R0,@GRB2
	       MOV.W	 R0,@GRB3
	       MOV.W	 R0,@GRB4
WS039_5_1:     MOV.B	 #H'84,R0L
	       MOV.B	 R0L,@TCR1
	       MOV.B	 #H'80,R0L
	       MOV.B	 R0L,@TMDR
WS040_20:      MOV.W	 @WS060_ADDR,R0
	       CMP.W	 #2,R0
	       BNE	 WS040_30:8
	       MOV.B	 #H'C5,R0L
	       MOV.B	 R0L,@TCR2
	       RTS
WS040_30:      CMP.W	 #3,R0
	       BNE	 WS040_40:8
	       MOV.B	 #H'C5,R0L
	       MOV.B	 R0L,@TCR2
	       MOV.B	 #H'C6,R0L
	       MOV.B	 R0L,@TCR3
	       RTS
WS040_40:      CMP.W	 #4,R0
	       BNE	 WS040_OVER40:8
	       MOV.B	 #H'C5,R0L
	       MOV.B	 R0L,@TCR2
	       MOV.B	 #H'C6,R0L
	       MOV.B	 R0L,@TCR3
	       MOV.B	 #H'C7,R0L
	       MOV.B	 R0L,@TCR4
	       RTS
WS040_OVER40:  RTS
;;MODE6;;
WS039_6:       CMP.W	 #6,R0
	       BNE	 NORMAL_INPUT
	       BSET	 IMIB2_LB		 ;;V0.D
	       BSET	 IMIB3_LB
	       BCLR	 IMIB3_LB112		 ;;V0.D
	       BSET	 IMIB4_LB
	       BCLR	 IMIB4_LB113		 ;;V0.D
	       MOV.B	 #H'80,R0L
	       MOV.B	 R0L,@TCR1
	       MOV.B	 R0L,@TCR2
	       MOV.B	 #H'C0,R0L
	       MOV.B	 R0L,@TMDR
WS040_31:      MOV.W	 @WS060_ADDR,R0
	       CMP.W	 #3,R0
	       BNE	 WS040_41:8
	       MOV.B	 #H'C6,R0L
	       MOV.B	 R0L,@TCR3
	       MOV.B	 #0,R0L 	   ;;V1.6
	       MOV.B	 R0L,@GRB3	   ;;
	       MOV.B	 #H'FA,R0L         ;;
	       MOV.B	 R0L,@TIER3	   ;;
	       BSET	 #3,@TSTR	   ;;
	       BRA	 WS040_OVER41:8
WS040_41:      CMP.W	 #4,R0
	       BNE	 WS040_OVER41:8
	       MOV.B	 #H'C6,R0L
	       MOV.B	 R0L,@TCR3
	       MOV.B	 #H'C7,R0L
	       MOV.B	 R0L,@TCR4
WS040_OVER41:  BLD	 HSC_RESET
	       BCS	 WS039_6_RESET:8
	       BSR	 TCNT2_PRESET
	       RTS
WS039_6_RESET: BSR	 TCNT2_RESET
	       MOV.W	 #0,R0
	       MOV.W	 R0,@GRB3
	       MOV.W	 R0,@TCNT3
	       MOV.W	 R0,@GRB4
	       MOV.W	 R0,@TCNT4
	       RTS
NORMAL_INPUT:;;BCLR	 ENBL_HSCNT		  ;
	       BCLR	 HSC_MODE		  ;
	       MOV.B	 #H'01,ACC                ;
	       MOV.B	 ACC,@TSTR		  ;
	       RTS				  ;
TCNT2_RESET:   MOV.W	 #0,R0
	       MOV.W	 R0,@V1001_ADDR
	       MOV.W	 R0,@TCNT2
	       BCLR	 TB0
	       BCLR	 TB1
	       RTS
TCNT2_PRESET:  MOV.W	 @V1001_ADDR,R0
	       MOV.W	 #0,E0
	       SHLL.L	 ER0
	       SHLL.L	 ER0
	       INC.L	 #1,ER0
	       MOV.W	 R0,@TCNT2
	       MOV.W	 E0,R0
	       BLD	 #0,R0L
	       BST	 TB0
	       BLD	 #1,R0L
	       BST	 TB1
	       BCLR	 CB0			 ;;V1.3
	       BCLR	 CB1			 ;;
	       RTS
TCNT_RESET:    MOV.W	 #0,R0
	       MOV.W	 R0,@V1001_ADDR
	       MOV.W	 R0,@TCNT1
	       MOV.W	 R0,@TCNT2
	       MOV.W	 R0,@TCNT3
	       MOV.W	 R0,@TCNT4
	       BCLR	 CB0			 ;;V1.3
	       BCLR	 CB1			 ;;
	       RTS
TCNT_PRESET:   MOV.W	 @V1001_ADDR,R0
	       MOV.W	 R0,@TCNT1
	       RTS
;;;;;;;;;;;;;;;;
	       .END
