;	    ****************************************************
;      ***********    TAIAN TP02 PLC SOFTWARE PROGRAM	 ***********
;   *************	 PG COMM ROUTINE MODULE Ver:0.1   *************
;***************	   TAIAN ELECTRIC CO., LTD.	   ***************
;   *************	    Written by Michael Wei	  *************
;      ***********    Start 1997/7/21	End 1997/ ?/ ?	 ***********
;	    ****************************************************
; Ver:0.1/ Issued in
	       .CPU	 300HA
	       .EXPORT	 COMMPP,COMM_STRT,SWAP_ACC,DPTR_PADR1
	       .EXPORT	 INST_TO_ASCII,PRG_MEM_WR_128
	       .IMPORT	 COMM_PG1,MONTH_WEEK_XCHG,EXE_WR_DR_00,COMPILER
	       .IMPORT	 LED_BUF_REFLESH,RTC_CMD,RTC_BURST,DELAY_1MS
	       .IMPORT	 COMM_PG,COMM_PG_C,LOAD_EEPROM,DUMP_EEPROM,DELAY_10MS
	       .IMPORT	 BCD_HEX_W,BCD_HEX_B,EEPROM_CHECKSUM,DUMP_FLASH
	       .IMPORT	 DUMP_FLASH_SYS
	       .INCLUDE  "H83005.INC"
	       .INCLUDE  "SYMBOL02.INC"
;;;;;;;;;;     .INCLUDE  "SYM2.INC"
	       .OUTPUT	 DBG
	       .SECTION  COMM,CODE,LOCATE=H'00009300
DPTR_PADR1:
VERIFY_PACK:
INST_TO_ASCII:
PRG_MEM_WR_128:  RTS
;******************************************************************************
;******************	  COMMPP		*******************************
;******************************************************************************
;/* Module Name:   COMMPP()
;   Description:   JW-12PG communication subroutine
COMMPP: 	 BCLR	   RXENDF0		   ;
	     ;;;;BSET	   F58_RXD_F0		   ;;FOR F58 USED
		 BLD	   PGBRT		   ;
		 BCS	   JW12PG:8		   ;
		 BSET	   F58_RXD_F0		   ;;VF.5
		 BLD	   F58_RXD_EN		   ;;
		 BCC	   COMMPP1:8		   ;;
		 JMP	   @LED_BUF_REFLESH	   ;;
COMMPP1:	 BSET	   PG_COM_BIT		   ;
		 BRA	   COMM_STRT_PG 	   ;Jump to computer link
JW12PG: 	 .EQU	   $			   ;
PG_CHECKSUM:	 MOV.B	   @PG_BUF1,R0L 	   ;
		 ADD.B	   #3,R0L		   ;
		 MOV.L	   #PG_STX,ER6		   ;
		 MOV.B	   #0,R0H		   ;
PG_CHK_LP:	 MOV.B	   @ER6,R1L		   ;
		 INC.L	   #1,ER6		   ;
		 ADD.B	   R1L,R0H		   ;
		 DEC.B	   R0L			   ;
		 BNE	   PG_CHK_LP:8		   ;
		 CMP.B	   #H'FF,R0H               ;
		 BEQ	   PG_CODE_JUDGE:8	   ;
	      ;  BCLR	   REQ_START_FG0	   ;
	      ;  BCLR	   BYTE_CNT_OK		   ;
	      ;  JMP	   @LED_BUF_REFLESH	   ;
CHK_SUM_ERR:	 MOV.B	   #H'09,R1H               ;
		 BRA	   RET_ERROR		   ;
PG_CODE_JUDGE:	 MOV.B	   @PG_STX,ACC		   ;
		 .SWITCH.B  (ACC)		   ;
		 .CASE	   #D'20                   ;
			   BRA	 SET_PASSWORD_OK   ;
		 .CASE	   #D'21                   ;
			   BRA	 WR_NG_PASSWORD    ;
		 .CASE	   #D'29                   ;
			   BRA	 CHECK_PASSWORD    ;
		 .CASE	   #D'30                   ;
			   BRA	 UPDATE_PASSWORD   ;
		 .CASE	   #H'F0                   ;
			   BRA	 INIT_CONTROL_ID   ;
		 .CASE	   #H'F5                   ;
			   BRA	 INIT_NEW_TYPE	   ;
		 .CASE	   #D'15                   ;
			   BRA	 CLR_ALL	   ;Clear all memory
		 .CASE	   #D'09                   ;
			   BRA	 WRITE_STATE	   ;
		 .CASE	   #D'10                   ;
			   BRA	 READ_STATE	   ;
		 .CASE	   #D'12                   ;
			   BRA	 WRITE_STATE_BIT   ;
		 .CASE	   #D'14                   ;
			   BRA	 READ_STATE_BIT    ;
		 .CASE	   #D'01                   ;
			   BRA	 STOP_PLC	   ;STOP_PLC
		 .CASE	   #D'02                   ;
			   BRA	 START_PLC	   ;START_PLC
		 .OTHERS			   ;
			   BRA	 INHIBIT_RD:8	   ;
		 .ENDS				   ;
INHIBIT_RD:	 BLD	   SECRET_BIT		   ;
		 BCS	   RET_OK_00		   ;
		 BLD	   F0_BIT		   ;;V0.D
		 BCC	   NO_F0_ERR		   ;;
		 .SWITCH.B  (ACC)		   ;
		 .CASE	   #D'03                   ;
			   BRA	 CLR_USER_PROG	   ;CLR_USER_PROG
		 .CASE	   #D'04                   ;
			   BRA	 CLR_SYS_MEM	   ;CLR_SYS_MEM
		 .CASE	   #D'05                   ;
			   BRA	 INSERT_INST	   ;
		 .CASE	   #D'06                   ;
			   BRA	 DELETE_INST	   ;
		 .CASE	   #D'07                   ;
			   BRA	 WRITE_INST	   ;
		 .CASE	   #D'08                   ;
			   BRA	 READ_INST	   ;
		 .CASE	   #D'13                   ;
			   BRA	 READ_TABLE	   ;
		 .CASE	   #D'16                   ;
			   BRA	 WRITE_TABLE	   ;
		 .CASE	   #D'18                   ;
			   BRA	 LOAD_PACK	   ;
		 .CASE	   #D'19                   ;
			   BRA	 DUMP_PACK	   ;
;		 .CASE	   #D'26                   ;
;			   BRA	 WR_MC_MODULE	   ;
;		 .CASE	   #D'27                   ;
;			   BRA	 WR_ADDR_MC	   ;
;		 .CASE	   #D'28                   ;
;			   BRA	 READ_MC_MODULE    ;
		 .CASE	   #D'17                   ;NEW ADDED FOR TP02
			   BRA	 CLR_DATA_MEM	   ;
;		 .CASE	   #D'99                   ;
;			   BRA	 ENABLE_MC_FUNCTION;
		 .CASE	   #D'50                   ;
			   BRA	 INSERT_INST_PU12  ;
		 .CASE	   #D'51                   ;
			   BRA	 WRITE_INST_PU12   ;
		 .CASE	   #D'52                   ;
			   BRA	 READ_INST_PU12    ;
		 .CASE	   #D'53                   ;
			   BRA	 SET_RESET_COIL    ;
		 .CASE	   #D'54                   ;
			   BRA	 CHECK_USER_PROGRAM;
		 .CASE	   #D'55                   ;;FROM VER 0.9 AVAILABLE
			   BRA	 UPDATE_SYS_ROM    ;;
		 .CASE	   #D'56                   ;;V0.D
			   BRA	 READ_END_PROG	   ;
		 .OTHERS			   ;
			   BRA	 NOT_FUNCTION	   ;
		 .ENDS				   ;

RET_OK_00:	 MOV.B	   #H'00,R0L               ;set response byte counter
		 MOV.B	   R0L,@PG_BUF1 	   ;to zero
RET_OK: 	 BLD	   ERR_RESP		   ;;
		 BCC	   RET_OK1		   ;;
RET_OK0:	 BLD	   FAULT_FLAG		   ;;NEW
		 BCC	   RET_OK1:8		   ;;
		 MOV.W	   @WS008_ADDR,R0	   ;;;V1.0
		 CMP.W	   #H'0004,R0              ;;;
		 BNE	   RET_OK1:8		   ;;;
		 BCLR	   ERR_RESP		   ;;
		 MOV.B	   @WS050_ADDR+1,R1H	   ;;
		 BRA	   RET_ERROR		   ;;
RET_OK1:	 BLD	   TD_MOD
		 BCC	   RET_OK2:8
		 BCLR	   TD_MOD
		 MOV.B	   #H'08,R0L
		 MOV.L	   #PG_STX,ER6
		 MOV.L	   ER6,ER5
		 MOV.B	   R0L,@ER6
		 INC.L	   #1,ER6
		 MOV.B	   @F33_TX_CNT,R0L
		 MOV.B	   R0L,@ER6
		 INC.L	   #1,ER6
		 INC.B	   R0L			   ;
		 INC.B	   R0L			   ;
		 MOV.B	   R0L,@BYTE_COUNTER	   ;;TP02
		 MOV.B	   @F33_TX_BUFF,R0L
		 MOV.B	   R0L,@ER6
		 INC.L	   #1,ER6
		 MOV.B	   @F33_TX_BUFF+1,R0L
		 MOV.B	   R0L,@ER6
		 INC.L	   #1,ER6
		 MOV.B	   @F33_TX_BUFF+2,R0L
		 MOV.B	   R0L,@ER6
		 INC.L	   #1,ER6
		 MOV.B	   @F33_TX_BUFF+3,R0L
		 MOV.B	   R0L,@ER6
		 INC.L	   #1,ER6
		 MOV.B	   @F33_TX_BUFF+4,R0L
		 MOV.B	   R0L,@ER6
		 INC.L	   #1,ER6
		 MOV.B	   @F33_TX_BUFF+5,R0L
		 MOV.B	   R0L,@ER6
		 MOV.B	   #0,R1L
		 MOV.B	   @BYTE_COUNTER,R0L
		 BRA	   RET_CSUM_LP:8
RET_OK2:	 MOV.B	   #H'00,R0L               ;Load response format code
		 MOV.L	   #PG_STX,ER6		   ;
		 MOV.L	   ER6,ER5		   ;
		 MOV.B	   R0L,@ER6		   ;
		 BLD	   RUN_FLAG		   ;
		 BST	   #6,@ER6		   ;store RUN flag
		 BLD	   SECRET_BIT		   ;
		 BST	   #5,@ER6		   ;
		 INC.L	   #1,ER6		   ;
		 MOV.B	   @ER6,R0L		   ;
		 INC.B	   R0L			   ;
		 INC.B	   R0L			   ;
		 MOV.B	   R0L,@BYTE_COUNTER	   ;;TP02
		 MOV.B	   #0,R1L		   ;
RET_CSUM_LP:	 MOV.B	   @ER5,R0H		   ;
		 ADD.B	   R0H,R1L		   ;
		 INC.L	   #1,ER5		   ;
		 DEC.B	   R0L			   ;
		 BNE	   RET_CSUM_LP:8	   ;
		 NOT.B	   R1L			   ;
		 MOV.B	   R1L,@ER5		   ;
		 MOV.L	   #PG_STX,DPTR 	   ;
		 MOV.B	   @DPTR,ACC		   ;
		 MOV.L	   DPTR,@FRAME_PTR	   ; Frame pointer
		 BCLR	   #RE,@SCR0		   ;;NEW
		 MOV.B	   ACC,@TDR0		   ;
		 BCLR	   #TDRE,@SSR0		   ;Start transmit
		 BSET	   #TIE,@SCR0		   ;Enable TXI interrupt
	      ;;;BSET	   #TEIE,@SCR0		   ;Enable TEI interrupt
		 JMP	   @LED_BUF_REFLESH	   ;
NOT_FUNCTION:	 MOV.B	   #H'14,R1H               ;
		 BRA	   RET_ERROR:8		   ;
NO_F0_ERR:	 MOV.B	   #H'15,R1H               ;;V0.D
		 BRA	   RET_ERROR:8		   ;;
PASSWORD_ERR:	 MOV.B	   #H'1A,R1H               ;
		 BRA	   RET_ERROR:8		   ;
PC_RUNNING_ERR:  MOV.B	   #H'12,R1H               ;R1H : error code
		 BRA	   RET_ERROR:8		   ;
NO_SPACE_ERR:	 BCLR	   JUDGE_NG		   ;
		 MOV.B	   #H'11,R1H               ;
		 BRA	   RET_ERROR:8		   ;
RET_ERROR:	 MOV.B	   #H'00,R0L               ;Load response format code
		 MOV.L	   #PG_STX,ER6		   ;
		 MOV.L	   ER6,ER5		   ;
		 MOV.B	   R0L,@ER6		   ;
		 BLD	   RUN_FLAG		   ;
		 BST	   #6,@ER6		   ;store RUN flag
		 BSET	   #7,@ER6		   ;set ER bit to 1
		 INC.L	   #1,ER6		   ;
		 MOV.B	   #H'01,R0L               ;byte counter
		 MOV.B	   R0L,@ER6		   ;
		 INC.B	   R0L			   ;
		 INC.B	   R0L			   ;
		 MOV.B	   R0L,@BYTE_COUNTER	   ;
		 INC.L	   #1,ER6		   ;
		 MOV.B	   R1H,@ER6		   ;error code
		 MOV.B	   #0,R1L		   ;
		 MOV.B	   #3,R0L		   ;
		 BRA	   RET_CSUM_LP		   ;
;============	 #54 Check user program  ==========;
CHECK_USER_PROGRAM:   .EQU  $			   ;
		 BLD	   RUN_FLAG		   ;
		 BCS	   PC_RUNNING_ERR	   ;
		 BSET	   LOGIC_DETECT 	   ;
		 MOV.B	   ACC,@H'000A0000         ;
		 JSR	   @COMPILER		   ;
		 BLD	   LOGIC_ERR_BIT	   ;
		 BCC	   RET_OK_00		   ;
		 MOV.B	   #H'00,R0L               ;Load response format code
		 MOV.L	   #PG_STX,ER6		   ;
		 MOV.L	   ER6,ER5		   ;
		 MOV.B	   R0L,@ER6		   ;
		 BLD	   RUN_FLAG		   ;
		 BST	   #6,@ER6		   ;store RUN flag
		 BSET	   #7,@ER6		   ;set ER bit to 1
		 INC.L	   #1,ER6		   ;
		 MOV.B	   #H'03,R0L               ;byte counter
		 MOV.B	   R0L,@ER6		   ;
		 INC.B	   R0L			   ;
		 INC.B	   R0L			   ;
		 MOV.B	   R0L,@BYTE_COUNTER	   ;
		 INC.L	   #1,ER6		   ;
		 MOV.B	   @WS009_ADDR+1,R1H	   ;
		 ADD.B	   #H'1F,R1H               ;;V0.B
		 MOV.B	   R1H,@ER6		   ;error code
		 INC.L	   #1,ER6		   ;
		 MOV.B	   @WS006_ADDR,R1H	   ;
		 MOV.B	   R1H,@ER6		   ;
		 INC.L	   #1,ER6		   ;
		 MOV.B	   @WS006_ADDR+1,R1H	   ;
		 MOV.B	   R1H,@ER6		   ;
		 MOV.B	   #0,R1L		   ;
		 MOV.B	   #5,R0L		   ;
		 BRA	   RET_CSUM_LP		   ;
;============	 #01 To stop controller  ==========;
STOP_PLC:	 BLD	   REMOTE_MODE		   ;Remote I/O slave station
		 BCC	   STOP_PLC_ST:8	   ;can not be setted by PG
		 BLD	   MASTER_MODE		   ;
		 BCS	   STOP_PLC_ST:8	   ;
;		  MOV.B     @SYS_234_ADDR,ACC	    ;;New add for protect remote
;		  CMP.B     #H'02,ACC               ; mode dead lock
;		  BEQ	    STATION_CHK1:8	    ; Ver0.1
;		  BRA	    STOP_PLC_ST:8	    ;
;STATION_CHK1:	  MOV.B     @SYS_237_ADDR,ACC	    ;
;		  CMP.B     #H'00,ACC               ;
;		  BEQ	    STOP_PLC_ST:8	    ;
;		  CMP.B     #H'78,ACC               ;
;		  BCC	    STOP_PLC_ST:8	    ;
;		  BRA	    RET_ERROR		    ;
STOP_PLC_ST:	 BCLR	   RUN_FLAG		   ;
		 BSET	   RUN_FLAG_1		   ;
		 BCLR	   REQ_RUN_FG		   ;
		 BRA	   RET_OK		   ;
;============  #02 To start controller ==========;
START_PLC:	 BLD	   REMOTE_MODE		   ;Remote I/O slave station
		 BCC	   START_PLC_ST:8	   ;can not be setted by PG
		 BLD	   MASTER_MODE		   ;
		 BCS	   START_PLC_ST:8	   ;
;		  MOV.B     @SYS_234_ADDR,ACC	    ;;New add for protect remote
;		  CMP.B     #H'02,ACC               ; mode dead lock
;		  BEQ	    STATION_CHK2:8	    ;
;		  BRA	    START_PLC_ST:8	    ;
;STATION_CHK2:	  MOV.B     @SYS_237_ADDR,ACC	    ;
;		  CMP.B     #H'00,ACC               ;
;		  BEQ	    START_PLC_ST:8	    ;
;		  CMP.B     #H'78,ACC               ;
;		  BCC	    START_PLC_ST:8	    ;
;		  BRA	    RET_ERROR		    ;

START_PLC_ST:	 BLD	   RUN_FLAG		   ;
		 BCC	   STOP_TO_RUN:8	   ;
		 BLD	   RUN_FLAG_1		   ;
		 BCS	   STOP_TO_RUN:8	   ;
		 BRA	   RET_OK		   ;
STOP_TO_RUN:	 BSET	   REQ_RUN_FG		   ;
		 BSET	   RUN_LED		   ;
		 BSET	   ERR_RESP		   ;
		 BRA	   RET_OK1		   ;

;============  #03 To clear user program ==========;
;***************************************************
;*CLEAR_PROGRAM    : TP02-40/60:LC0000 - LC4000    *
;*		     TP02-20/28:LC0000 - LC1500    *
;*CLEAR_USED_TABLE : 1.LABEL_INST_ADDR		   *
;*		     2.LABEL_JUMP_ADDR		   *
;*		     3.T_C_STATUS		   *
;*		     4.T_C_PRESET		   *
;*		     5.Y_USED_TABLE		   *
;*		     6.C_USED_TABLE		   *
;*		     7.M_USED_TABLE		   *
;***************************************************
CLR_USER_PROG:	 BLD	   RUN_FLAG		   ;
		 BCS	   PC_RUNNING_ERR	   ;
		 BSR	   CLEAR_PROGRAM	   ;
		 BSR	   CLR_USED_TABLE	   ;
		 BRA	   RET_OK		   ;

;============  #31 To clear system memory =========;
;***************************************************
;*INIT_SYS_MEMORY: WS_MEMORY_ADDR(WS001-WS128)	   *
;***************************************************
CLR_SYS_MEM:	 BLD	   RUN_FLAG		   ;
		 BCS	   PC_RUNNING_ERR	   ;
		 BSR	   INIT_SYS_MEMORY	   ;
		 BRA	   RET_OK		   ;

;============  #32 To clear data memory  ==========;
;***************************************************
;*CLEAR_DATA_MEM: X_STATE(X0001-X0384)		   *
;*		  Y_STATE(Y0001-Y0384)		   *
;*		  C_STATE(C0001-C0384)		   *
;*		  V_MEMORY_ADDR(V0001-V1024)	   *
;*		  D_MEMORY_ADDR(D0001-D2048)	   *
;*		  WC_MEMORY_ADDR(WC001-WC912)	   *
;*		  FILE1-FILE130 		   *
;***************************************************
CLR_DATA_MEM:	 BLD	   RUN_FLAG		   ;
		 BCS	   PC_RUNNING_ERR	   ;
		 BSR	   CLEAR_DATA_MEM	   ;
		 BRA	   RET_OK		   ;
;============  #15 To clear all memory	 ==========;
CLR_ALL:	 BLD	   RUN_FLAG		   ;
		 BCS	   PC_RUNNING_ERR	   ;
		 BSR	   CLEAR_PROGRAM	   ;
		 BSR	   CLR_USED_TABLE	   ;
		 BSR	   INIT_SYS_MEMORY	   ;VF.2
		 BSR	   CLEAR_DATA_MEM	   ;
		 BCLR	   SECRET_BIT		   ;
		 BCLR	   OVER_PASSWORD	   ;
		 BRA	   RET_OK		   ;

;=======  #05 Insert instruction for PU02   =======;
INSERT_INST:	 BLD	   RUN_FLAG		   ;
		 BCS	   PC_RUNNING_ERR	   ;
		 BCLR	   NU_EXIST		   ;
INSERT_INST1:	 MOV.B	   @PG_BUF2,R1H 	   ;
		 MOV.B	   @PG_BUF3,R1L 	   ;
		 MOV.B	   @PG_BUF4,R0L 	   ;
		 BSR	   CHECK_SPACE		   ;Check space enough ?
		 BLD	   JUDGE_NG		   ;
		 BCS	   NO_SPACE_ERR 	   ;space NG and no shift
		 MOV.B	   @PG_BUF4,R0L 	   ;
		 BSR	   RELOAD_PRG_SPTR	   ;
		 MOV.L	   ER6,ER2		   ;
		 MOV.B	   @PG_BUF2,R1H 	   ;
		 MOV.B	   @PG_BUF3,R1L 	   ;
		 SHLL.W    R1			   ;1 STEP = 2 BYTES
		 ADD.W	   R1,R2		   ;
		 BSR	   RELOAD_PRG_EPTR	   ;;
		 INC.L	   #2,ER6		   ;;
		 CMP.L	   ER6,ER2		   ;CHECK IF F00_END
		 BEQ	   NO_SPACE_ERR 	   ;;
		 BSR	   SHIFT_INC		   ;
		 BSR	   RELOAD_PRG_SPTR	   ;
		 MOV.B	   @PG_BUF2,R1H 	   ;
		 MOV.B	   @PG_BUF3,R1L 	   ;
		 SHLL.W    R1			   ;
		 ADD.W	   R1,R6		   ;
		 SHLR.W    R1			   ;
		 ADD.W	   R1,R5		   ;
		 MOV.B	   @PG_BUF4,R0H 	   ;
		 MOV.L	   #PG_BUF5,ER4 	   ;
		 BSR	   INST_MEM_WR		   ;
		 BLD	   JUDGE_NG		   ;
		 BCS	   NO_SPACE_ERR 	   ;
		 MOV.B	   #H'00,R0L               ;set response byte counter
		 MOV.L	   #PG_BUF1,ER6 	   ;to zero
		 MOV.B	   R0L,@ER6		   ;
		 BRA	   RET_OK		   ;

;=======  #06 Delete instruction   =============   ;
DELETE_INST:	 BLD	   RUN_FLAG		   ;
		 BCS	   PC_RUNNING_ERR	   ;
		 BSR	   RELOAD_PRG_EPTR	   ;
		 MOV.L	   ER6,ER2		   ;
		 INC.L	   #1,ER2		   ;point to F40_END address
		 BSR	   RELOAD_PRG_SPTR	   ;V0.B-> 2>1
		 MOV.B	   @PG_BUF2,R1H 	   ;
		 MOV.B	   @PG_BUF3,R1L 	   ;
		 SHLL.W    R1			   ;
		 ADD.W	   R1,R6		   ;
		 CMP.L	   #F00_END_ADDR,ER6	   ;;V0.2
		 BCC	   RET_OK		   ;;
		 SHLR.W    R1			   ;
		 ADD.W	   R1,R5		   ;
		 MOV.B	   @PG_BUF4,R0L 	   ;
		 BSR	   SHIFT_DEC		   ;
		 MOV.B	   #H'00,R0L               ;set response byte counter
		 MOV.L	   #PG_BUF1,ER6 	   ;to zero
		 MOV.B	   R0L,@ER6		   ;
		 BRA	   RET_OK		   ;

;=======   #07 Write instruction    =============  ;
WRITE_INST:	 BLD	   RUN_FLAG		   ;
		 BCS	   PC_RUNNING_ERR	   ;
		 BCLR	   NU_EXIST		   ;
WRITE_INST1:	 MOV.B	   @PG_BUF3,R1H 	   ;
		 MOV.B	   @PG_BUF4,R1L 	   ;
		 BSR	   RELOAD_PRG_SPTR	   ;
		 MOV.B	   @PG_BUF5,R0L 	   ;
		 MOV.B	   #H'0,R0H                ;
		 SHLL.W    R1			   ;
		 ADD.W	   R1,R6		   ;
		 ADD.W	   R0,R6		   ;
		 CMP.L	   #F00_END_ADDR+2,ER6	   ;
		 BCS	   WRITE_INST2:8	   ;
		 CMP.B	   #H'02,R0L               ;
		 BEQ	   WR_RET		   ;
		 BRA	   NO_SPACE_ERR 	   ;
START_WR_COMP:	 BLD	   RUN_FLAG		   ;;VF.0
		 BCC	   START_WRITE		   ;;
		 BSET	   CHG_MODE		   ;;
		 BRA	   START_WRITE1 	   ;;
WRITE_INST2:	 MOV.B	   @PG_BUF2,R0L 	   ;
		 AND.B	   #H'0F,R0L               ;
		 CMP.B	   #H'00,R0L               ;
		 BEQ	   START_WR_COMP	   ;;V0.D
		 CMP.B	   #H'01,R0L               ;
		 BEQ	   DELETE_1_2		   ;
		 CMP.B	   #H'02,R0L               ;
		 BEQ	   DELETE_1_3		   ;
		 CMP.B	   #H'03,R0L               ;
		 BEQ	   DELETE_2_3		   ;
		 CMP.B	   #H'04,R0L               ;
		 BEQ	   INSERT_2_1		   ;
		 CMP.B	   #H'05,R0L               ;
		 BEQ	   INSERT_3_1		   ;
		 CMP.B	   #H'06,R0L               ;;V0.7
		 BEQ	   INSERT_3_2		   ;;
		 CMP.B	   #H'07,R0L               ;;
		 BEQ	   DELETE_1_4		   ;;
		 CMP.B	   #H'08,R0L               ;;
		 BEQ	   DELETE_1_3		   ;;
		 CMP.B	   #H'09,R0L               ;;
		 BEQ	   DELETE_1_2		   ;;
		 CMP.B	   #H'0A,R0L               ;;
		 BEQ	   INSERT_4_1		   ;;
		 CMP.B	   #H'0B,R0L               ;;
		 BEQ	   INSERT_4_2		   ;;
		 CMP.B	   #H'0C,R0L               ;;
		 BEQ	   INSERT_4_3		   ;;
INSERT_2_1:	 MOV.B	   #2,R0L		   ;Insert 2 bytes
		 MOV.B	   R0L,@R4_BUFFER	   ;
		 MOV.W	   #0,R5		   ;shift end address
		 MOV.W	   R5,@R5_BUFFER	   ;
		 BRA	   INSERT_GO:8		   ;
INSERT_3_1:	 MOV.B	   #4,R0L		   ;
		 MOV.B	   R0L,@R4_BUFFER	   ;
		 MOV.W	   #0,R5		   ;
		 MOV.W	   R5,@R5_BUFFER	   ;
		 BRA	   INSERT_GO:8		   ;
INSERT_3_2:	 MOV.B	   #2,R0L		   ;
		 MOV.B	   R0L,@R4_BUFFER	   ;
		 MOV.W	   #2,R5		   ;
		 MOV.W	   R5,@R5_BUFFER	   ;
		 BRA	   INSERT_GO:8		   ;
INSERT_4_1:	 MOV.B	   #6,R0L		   ;
		 MOV.B	   R0L,@R4_BUFFER	   ;
		 MOV.W	   #0,R5		   ;
		 MOV.W	   R5,@R5_BUFFER	   ;
		 BRA	   INSERT_GO:8		   ;
INSERT_4_2:	 MOV.B	   #4,R0L		   ;
		 MOV.B	   R0L,@R4_BUFFER	   ;
		 MOV.W	   #2,R5		   ;
		 MOV.W	   R5,@R5_BUFFER	   ;
		 BRA	   INSERT_GO:8		   ;
INSERT_4_3:	 MOV.B	   #2,R0L		   ;
		 MOV.B	   R0L,@R4_BUFFER	   ;
		 MOV.W	   #4,R5		   ;
		 MOV.W	   R5,@R5_BUFFER	   ;
INSERT_GO:	 MOV.B	   @R4_BUFFER,R0L	   ;;VF.1
		 MOV.B	   @PG_BUF3,R1H 	   ;
		 MOV.B	   @PG_BUF4,R1L 	   ;
		 BSR	   CHECK_SPACE		   ;
		 BLD	   JUDGE_NG		   ;
		 BCS	   NO_SPACE_ERR 	   ;
		 BSR	   RELOAD_PRG_SPTR	   ;
		 MOV.B	   @PG_BUF3,R1H 	   ;
		 MOV.B	   @PG_BUF4,R1L 	   ;
		 SHLL.W    R1			   ;;
		 ADD.W	   R1,R6		   ;;
		 MOV.W	   @R5_BUFFER,R5	   ;
		 ADD.W	   R5,R6		   ;;VF.1
		 MOV.L	   ER6,ER2		   ;
		 MOV.B	   @R4_BUFFER,R0L	   ;;VF.1
		 BSR	   SHIFT_INC		   ;
		 BRA	   START_WRITE		   ;
DELETE_1_4:	 MOV.B	   #6,R0L		   ;
		 BRA	   START_DELETE:8	   ;
DELETE_2_3:	 .EQU	   $			   ;
DELETE_1_2:	 MOV.B	   #2,R0L		   ;
		 BRA	   START_DELETE:8	   ;
DELETE_1_3:	 MOV.B	   #4,R0L		   ;
START_DELETE:	 BSR	   RELOAD_PRG_EPTR	   ;
		 MOV.L	   ER6,ER2		   ;
		 INC.L	   #1,ER2		   ;;V0.B
		 BSR	   RELOAD_PRG_SPTR	   ;
		 MOV.B	   @PG_BUF3,R1H 	   ;V0.7
		 MOV.B	   @PG_BUF4,R1L 	   ;
		 SHLL.W    R1			   ;
		 ADD.W	   R1,R6		   ;
		 SHLR.W    R1			   ;
		 ADD.W	   R1,R5		   ;
		 BSR	   SHIFT_DEC		   ;
START_WRITE:	 BCLR	   CHG_MODE		   ;;VF.0
START_WRITE1:	 BSR	   RELOAD_PRG_SPTR	   ;
		 MOV.B	   @PG_BUF3,R1H 	   ;
		 MOV.B	   @PG_BUF4,R1L 	   ;
		 SHLL.W    R1			   ;
		 ADD.W	   R1,R6		   ;
		 SHLR.W    R1			   ;
		 ADD.W	   R1,R5		   ;
		 MOV.B	   @PG_BUF5,R0H 	   ;
		 MOV.L	   #PG_BUF6,ER4 	   ;
		 BSR	   INST_MEM_WR		   ;
		 BLD	   CHG_MODE		   ;;VF.0
		 BCC	   WR_RET:8		   ;;
		 BCLR	   LOGIC_DETECT 	   ;;
		 MOV.B	   R0L,@H'000A0000         ;;
		 JSR	   @COMPILER		   ;;
 ;;;;		 MOV.W	   @EE_WS008_ADDR,ACC_W    ;;
 ;;;;		 CMP.W	   #H'0003,ACC_W           ;;
 ;;;;		 BEQ	   WR_RET0:8		   ;;
		 MOV.W	   #H'0003,ACC_W           ;;
		 MOV.W	   ACC_W,@WS008_ADDR	   ;;
 ;;;;		 JSR	   @DUMP_FLASH_SYS	   ;;
WR_RET0:	 BCLR	   CHG_MODE		   ;;
WR_RET: 	 MOV.B	   #H'00,R0L               ;set response byte counter
		 MOV.L	   #PG_BUF1,ER6 	   ;to zero
		 MOV.B	   R0L,@ER6		   ;
		 BRA	   RET_OK		   ;

;=======   #08 Read instruction    ==============  ;
READ_INST:	 BCLR	   NU_EXIST		   ;
READ_INST1:	 MOV.B	   @PG_BUF2,R1H 	   ;R1 : address
		 MOV.B	   @PG_BUF3,R1L 	   ;
		 MOV.B	   @PG_BUF4,R0L 	   ;number of bytes to read
		 MOV.B	   R0L,R0H		   ;
		 SHLR.B    R0H			   ;number of NU to read
		 MOV.B	   R0H,R2L		   ;
		 MOV.B	   #0,R2H		   ;
		 BSR	   RELOAD_PRG_SPTR	   ;
	;;;;;;;; ADD.W	   R2,R5		   ; V0.3
		 ADD.W	   R1,R5		   ;
		 SHLL.W    R1			   ;
		 ADD.W	   R1,R6		   ;
		 MOV.L	   #PG_BUF1,ER4 	   ;
		 BLD	   NU_EXIST		   ;;
		 BCC	   READ_INST2:8 	   ;;
		 ADD.B	   R0H,R0L		   ;;RESPONSE BYTE COUNTER
		 CMP.B	   #0,R0L		   ;;INCLUDE "NU"
		 BEQ	   CHK_SUM_ERR		   ;;FRAME ERROR
		 CMP.B	   #D'253,R0L              ;;FRAME ERROR
		 BCC	   CHK_SUM_ERR		   ;;FRAME ERROR
READ_INST2:	 MOV.B	   R0L,@ER4		   ;;
		 INC.L	   #1,ER4		   ;
		 BLD	   NU_EXIST		   ;;V0.3
		 BCC	   READ_INST_LP:8	   ;;
		 SUB.B	   R0H,R0L		   ;;
READ_INST_LP:	 MOV.B	   @ER6,R1L		   ;
		 MOV.B	   R1L,@ER4		   ;
		 INC.L	   #1,ER6		   ;
		 INC.L	   #1,ER4		   ;
		 DEC.B	   R0L			   ;
		 BNE	   READ_INST_LP:8	   ;
		 BLD	   NU_EXIST		   ;;
		 BCC	   RET_OK		   ;;
READ_NU_LP:	 MOV.B	   @ER5,R1L		   ;
		 MOV.B	   R1L,@ER4		   ;
		 INC.L	   #1,ER5		   ;
		 INC.L	   #1,ER4		   ;
		 DEC.B	   R0H			   ;
		 BNE	   READ_NU_LP:8 	   ;
		 BRA	   RET_OK		   ;

;===   #09 Write state of the reference number === ;
WRITE_STATE:	 BCLR	   WR_TABLE_BIT 	   ;
WRITE_STATE1:	 MOV.B	   @PG_BUF1,R1H 	   ;
		 MOV.B	   R1H,@BYTE_COUNT	   ;total byte counter
		 MOV.L	   #PG_BUF2,ER6 	   ;
WRITE_STA_LP:	 MOV.B	   @ER6,R1H		   ;PG_BUF2
		 MOV.B	   R1H,R0L		   ;data type
		 AND.B	   #H'0F,R1H               ;high byte address
		 INC.L	   #1,ER6		   ;
		 MOV.B	   @ER6,R1L		   ;PG_BUF3 low byte address
		 INC.L	   #1,ER6		   ;
		 BSR	   WS039_CHECK		   ;check if write in password
		 BSR	   RTC_CHECK		   ;check if set RTC
		 BLD	   JUDGE_NG		   ;;VF.3
		 BCS	   RET_OK		   ;;
		 MOV.B	   @ER6,R0H		   ;PG_BUF4 number of bytes to write
		 MOV.B	   R0H,R3H		   ;;
		 MOV.B	   @BYTE_COUNT,R3L	   ;;
		 ADD.B	   #3,R3H		   ;;
		 SUB.B	   R3H,R3L		   ;;
		 BCS	   START_STA_END	   ;;
		 MOV.B	   R3L,@BYTE_COUNT	   ;;
		 INC.L	   #1,ER6		   ;
		 BSR	   SWAP_R0L		   ;
		 AND.B	   #H'0F,R0L               ;
		 BLD	   WR_TABLE_BIT 	   ;
		 BCC	   WRITE_STATE2:8	   ;
		 BSR	   JUDGE_TABLE_TYPE	   ;
		 BLD	   JUDGE_NG		   ;
		 BCS	   RET_OK		   ;
		 BRA	   WRITE_STATE3 	   ;
WRITE_STATE2:	 BSR	   JUDGE_STA_TYPE	   ;
WRITE_STATE3:	 BLD	   JUDGE_NG		   ;
		 BCC	   START_STA_WR:8	   ;
		 BRA	   RET_OK		   ;NO ERROR RETURN
START_STA_WR:	 BLD	   WORD_TYPE		   ;
		 BCC	   START_BYTE_WR:8	   ;
		 BLD	   FILE_TYPE		   ;;V0.8
		 BCS	   START_FILE_WR	   ;;
START_WORD_WR:	 SHLL.W    R1			   ;Vxxxx,Dxxxx,WCxxx=2 bytes
START_BYTE_WR:	 ADD.W	   R1,R5		   ;
START_STA_WR1:	 MOV.B	   @ER6,R0L		   ;
		 MOV.B	   R0L,@ER5		   ;
		 INC.L	   #1,ER6		   ;
		 INC.L	   #1,ER5		   ;
		 DEC.B	   R0H			   ;
		 BNE	   START_STA_WR1:8	   ;
		 BRA	   START_STA_END0	   ;
START_FILE_WR:	 CMP.W	   #D'20,R1                ;V0.8
		 BCC	   START_FILE_WR2:8	   ;
		 SHLL.W    R1			   ;;
		 MOV.W	   #D'20,R2                ;;
		 MULXU.W   R1,ER2		   ;;
		 INC.W	   #1,R2		   ;;
		 ADD.W	   R2,R5		   ;;
START_FILE_WR1:  MOV.B	   @ER6,R0L		   ;;
		 MOV.B	   R0L,@ER5		   ;;
		 INC.L	   #1,ER6		   ;;V0.9 (2)
		 INC.L	   #2,ER5		   ;;	  (1)
		 DEC.B	   R0H			   ;;
		 BNE	   START_FILE_WR1:8	   ;;
		 BRA	   START_STA_END0:8	   ;;
START_FILE_WR2:  SUB.W	   #D'20,R1                ;;
		 MOV.W	   #D'20,R2                ;;
		 MULXU.W   R1,ER2		   ;;
		 MOV.L	   #FILE21_ADDR,ER5	   ;;
		 ADD.W	   R2,R5		   ;;
START_FILE_WR22: MOV.B	   @ER6,R0L		   ;;
		 MOV.B	   R0L,@ER5		   ;;
		 INC.L	   #1,ER6		   ;;
		 INC.L	   #1,ER5		   ;;
		 DEC.B	   R0H			   ;;
		 BNE	   START_FILE_WR22:8	   ;;
START_STA_END0:  MOV.B	   @BYTE_COUNT,R3L	   ;
		 CMP.B	   #0,R3L		   ;
		 BNE	   WRITE_STA_LP 	   ;
START_STA_END:	 MOV.B	   #H'00,R0L               ;set response byte counter
		 MOV.L	   #PG_BUF1,ER6 	   ;to zero
		 MOV.B	   R0L,@ER6		   ;
		 BRA	   RET_OK		   ;
;R0L : T3,T2,T1,T0,0,R10,R9,R8			   ;
;R1L   R7,R6,R5,R4,R3,R2,R1,R0			   ;
WS039_CHECK:	 PUSH.W    R2			   ;
		 PUSH.W    R0			   ;
		 PUSH.W    R1			   ;
		 PUSH.L    ER5			   ;
		 PUSH.L    ER6			   ;
		 MOV.B	   R0L,R2L		   ;
		 AND.B	   #B'11110000,R2L         ;
		 CMP.B	   #B'01100000,R2L         ;
		 BNE	   WS039_CHECK_RET	   ;
		 MOV.B	   R1L,R2L		   ;
		 MOV.B	   R0L,R2H		   ;
		 AND.W	   #H'0FFF,R2              ;
		 CMP.W	   #D'38,R2               ;38 FOR WS039
		 BNE	   WS039_CHECK_RET	  ;
WRITE_PASSWORD:  MOV.L	   #WS039_ADDR,ER6	   ;
		 MOV.L	   #PG_BUF5,ER5 	   ;
		 MOV.B	   #4,R1L		   ;;VF.3 2->4
WR_PASS_LOOP:	 MOV.B	   @ER5,R0L		   ;
		 MOV.B	   R0L,@ER6		   ;
		 INC.L	   #1,ER6		   ;
		 INC.L	   #1,ER5		   ;
		 DEC.B	   R1L			   ;
	    ;;	 MOV.B	   @ER5,R0L		   ;;VF.3
	    ;;	 MOV.B	   R0L,@ER6		   ;
	    ;;	 INC.L	   #1,ER6		   ;
	    ;;	 INC.L	   #1,ER5		   ;
	    ;;	 DEC.B	   R1L			   ;
		 BNE	   WR_PASS_LOOP:8	   ;
		 MOV.W	   @WS039_ADDR,R0	   ;
		 MOV.W	   @WS040_ADDR,R1	   ;
	   ;;	 ADD.W	   R0,R1		   ;
	   ;;	 MOV.W	   R1,@PASS_MEM 	   ;
		 MOV.W	   R1,E0		   ;
		 BCLR	   SECRET_BIT		   ;;VF.3
		 CMP.L	   #0,ER0		   ;
		 BEQ	   WS039_CHECK_RET:8	   ;
		 BSET	   SECRET_BIT		   ;
WS039_CHECK_RET: POP.L	   ER6			   ;
		 POP.L	   ER5			   ;
		 POP.W	   R1			   ;
		 POP.W	   R0			   ;
		 POP.W	   R2			   ;
		 RTS				   ;
;R0L : T3,T2,T1,T0,0,R10,R9,R8			   ;
;R1L   R7,R6,R5,R4,R3,R2,R1,R0			   ;
RTC_CHECK:	 PUSH.W    R2			   ;
		 PUSH.W    R0			   ;
		 PUSH.W    R1			   ;
		 PUSH.L    ER5			   ;;
		 PUSH.L    ER6			   ;;
		 MOV.B	   R0L,R2L		   ;
		 AND.B	   #B'11110000,R2L         ;
		 CMP.B	   #B'01010000,R2L         ;
		 BNE	   RTC_CHK_RET0 	   ;;VF.3
		 MOV.B	   R1L,R2L		   ;
		 MOV.B	   R0L,R2H		   ;
		 AND.W	   #H'0FFF,R2              ;
		 MOV.B	   @PG_BUF5,R6H 	   ;;VF.3
		 MOV.B	   @PG_BUF6,R6L 	   ;;
V_1018_CHK:	 CMP.W	   #D'1017,R2              ;
		 BNE	   V_1019_CHK:8 	   ;
		 CMP.W	   #D'60,R6                ;;VF.3
		 BCC	   RTC_CHK_RET_NG	   ;;
		 MOV.L	   #SECOND_ADDR-1,ER6	   ;
		 BRA	   WRITE_RTC		   ;
V_1019_CHK:	 CMP.W	   #D'1018,R2              ;
		 BNE	   V_1020_CHK:8 	   ;
		 CMP.W	   #D'60,R6                ;;VF.3
		 BCC	   RTC_CHK_RET_NG	   ;;
		 MOV.L	   #MINUTE_ADDR-1,ER6	   ;
		 BRA	   WRITE_RTC		   ;
V_1020_CHK:	 CMP.W	   #D'1019,R2              ;
		 BNE	   V_1021_CHK:8 	   ;
		 CMP.W	   #D'24,R6                ;;VF.3
		 BCC	   RTC_CHK_RET_NG	   ;;
		 MOV.L	   #HOUR_ADDR-1,ER6	   ;
		 BRA	   WRITE_RTC		   ;
V_1021_CHK:	 CMP.W	   #D'1020,R2              ;
		 BNE	   V_1022_CHK:8 	   ;
		 CMP.W	   #D'32,R6                ;;VF.3
		 BCC	   RTC_CHK_RET_NG	   ;;
		 MOV.L	   #DATE_ADDR-1,ER6	   ;
		 BRA	   WRITE_RTC		   ;
V_1022_CHK:	 CMP.W	   #D'1021,R2              ;
		 BNE	   V_1023_CHK:8 	   ;
		 CMP.W	   #D'8,R6                 ;;VF.3
		 BCC	   RTC_CHK_RET_NG	   ;;
		 CMP.W	   #0,R6		   ;;V1.5
		 BEQ	   RTC_CHK_RET_NG	   ;;
		 MOV.L	   #WEEK_ADDR-1,ER6	   ;
		 BRA	   WRITE_RTC		   ;
V_1023_CHK:	 CMP.W	   #D'1022,R2              ;
		 BNE	   V_1024_CHK:8 	   ;
		 CMP.W	   #D'13,R6                ;;VF.3
		 BCC	   RTC_CHK_RET_NG	   ;;
		 CMP.W	   #0,R6		   ;;V1.5
		 BEQ	   RTC_CHK_RET_NG	   ;;
		 MOV.L	   #MONTH_ADDR-1,ER6	   ;
		 BRA	   WRITE_RTC		   ;
V_1024_CHK:	 CMP.W	   #D'1023,R2              ;
		 BNE	   RTC_CHK_RET0:8	   ;
		 CMP.W	   #D'100,R6               ;;V1.5
		 BCC	   RTC_CHK_RET_NG	   ;;
		 MOV.L	   #YEAR_ADDR-1,ER6	   ;
WRITE_RTC:	 MOV.L	   #PG_BUF5,ER5 	   ;
		 MOV.B	   @PG_BUF4,R1L 	   ;
WR_RTC_LOOP:	 MOV.B	   @ER5,R0L		   ;
		 MOV.B	   R0L,@ER6		   ;
		 INC.L	   #1,ER6		   ;
		 INC.L	   #1,ER5		   ;
		 DEC.B	   R1L			   ;
		 BEQ	   RTC_CHK_RET0:8	   ;;
		 MOV.B	   @ER5,R0L		   ;
		 MOV.B	   R0L,@ER6		   ;
		 INC.L	   #1,ER6		   ;
		 INC.L	   #1,ER5		   ;
		 DEC.B	   R1L			   ;
		 BNE	   WR_RTC_LOOP:8	   ;
		 JSR	   @MONTH_WEEK_XCHG	   ;;
		 MOV.B	   #B'10111110,ACC         ;;
		 JSR	   @RTC_BURST		   ;;
		 JSR	   @MONTH_WEEK_XCHG	   ;;
RTC_CHK_RET0:	 BCLR	   JUDGE_NG		   ;;;VF.3
		 BRA	   RTC_CHK_RET:8	   ;;;
RTC_CHK_RET_NG:  BSET	   JUDGE_NG		   ;;VF.3
RTC_CHK_RET:	 POP.L	   ER6			   ;TEST
		 POP.L	   ER5			   ;TEST
		 POP.W	   R1			   ;
		 POP.W	   R0			   ;
		 POP.W	   R2			   ;
		 RTS				   ;
; ==== #10 Read state of the reference number  === ;
READ_STATE:	 BCLR	   READ_TABLE_BIT	   ;
READ_STATE1:	 MOV.B	   @PG_BUF1,R0L
		 MOV.B	   R0L,@BYTE_COUNT
		 MOV.L	   #PG_BUF2,ER6
		 MOV.L	   #PG_EXT,ER5
READ_TO_EXT:	 MOV.B	   @ER6+,R0H
		 MOV.B	   R0H,@ER5
		 INC.L	   #1,ER5
		 DEC.B	   R0L
		 BNE	   READ_TO_EXT:8
		 MOV.B	   #H'0,R0L
		 MOV.B	   R0L,@PG_BUF1
		 MOV.L	   #PG_BUF2,ER6
		 MOV.L	   #PG_EXT,ER3
READ_STATE2:	 MOV.B	   @ER3+,R1H		   ;
		 MOV.B	   R1H,R0L		   ;data type
		 AND.B	   #H'0F,R1H               ;
		 MOV.B	   @ER3+,R1L		   ;
		 MOV.B	   @ER3+,R0H		   ;number of bytes to read
		 MOV.B	   @PG_BUF1,R2L 	   ;
		 ADD.B	   R0H,R2L		   ;
		 MOV.B	   R2L,@PG_BUF1 	   ;
		 BSR	   SWAP_R0L		   ;
		 AND.B	   #H'0F,R0L               ;
		 BLD	   READ_TABLE_BIT	   ;
		 BCC	   STATE_R:8		   ;
		 BSR	   JUDGE_TABLE_TYPE	   ;
		 BLD	   JUDGE_NG		   ;
		 BCS	   FILL_00_ALL		   ;
		 BRA	   START_STA_RD:8	   ;

STATE_R:	 BSR	   JUDGE_STA_TYPE	   ;
STATE_R_1:	 BLD	   JUDGE_NG		   ;
		 BCC	   START_STA_RD:8	   ;
		 BRA	   RET_OK		   ;NO ERROR RETURN
START_STA_RD:	 BLD	   WORD_TYPE
		 BCC	   START_BYTE_RD:8
		 BLD	   FILE_TYPE
		 BCS	   START_FILE_RD
START_WORD_RD:	 SHLL.W    R1			   ;
START_BYTE_RD:	 ADD.W	   R1,R5		   ;
START_STA_RD1:	 MOV.B	   @ER5,R0L		   ;
		 MOV.B	   R0L,@ER6		   ;
		 INC.L	   #1,ER5		   ;
		 INC.L	   #1,ER6		   ;
		 DEC.B	   R0H			   ;
		 BNE	   START_STA_RD1:8	   ;
		 BRA	   START_STA_RD2:8	   ;
START_FILE_RD:	 CMP.W	   #D'20,R1                ;V0.8
		 BCC	   START_FILE_RD2:8	   ;
		 SHLL.W    R1			   ;;
		 MOV.W	   #D'20,R2                ;;
		 MULXU.W   R1,ER2		   ;;
		 INC.W	   #1,R2		   ;;
		 ADD.W	   R2,R5		   ;;
START_FILE_RD1:  MOV.B	   @ER5,R0L		   ;;
		 MOV.B	   R0L,@ER6		   ;;
		 INC.L	   #2,ER5		   ;;
		 INC.L	   #1,ER6		   ;;
		 DEC.B	   R0H			   ;;
		 BNE	   START_FILE_RD1:8	   ;;
		 BRA	   START_STA_RD2:8	   ;;
START_FILE_RD2:  SUB.W	   #D'20,R1                ;;
		 MOV.W	   #D'20,R2                ;;
		 MULXU.W   R1,ER2		   ;;
		 MOV.L	   #FILE21_ADDR,ER5	   ;;
		 ADD.W	   R2,R5		   ;;
START_FILE_RD22: MOV.B	   @ER5,R0L		   ;;
		 MOV.B	   R0L,@ER6		   ;;
		 INC.L	   #1,ER5		   ;;
		 INC.L	   #1,ER6		   ;;
		 DEC.B	   R0H			   ;;
		 BNE	   START_FILE_RD22:8	   ;;
START_STA_RD2:	 MOV.B	   @BYTE_COUNT,R2L
		 DEC.B	   R2L
		 DEC.B	   R2L
		 DEC.B	   R2L
		 MOV.B	   R2L,@BYTE_COUNT
		 BNE	   READ_STATE2
		 BRA	   RET_OK
FILL_00_ALL:	 MOV.B	   #H'0,R0L
FILL_00_ALL_1:	 MOV.B	   R0L,@ER6
		 INC.L	   #1,ER6
		 DEC.B	   R0H
		 BNE	   FILL_00_ALL_1:8
		 BRA	   RET_OK
;; ======= #12 Write state in bit  =============
WRITE_STATE_BIT: MOV.B	   @PG_BUF1,R0H
		 MOV.B	   R0H,@BYTE_COUNT
		 MOV.L	   #PG_BUF2,ER6
WRITE_BIT_LP:	 MOV.W	   @ER6,R0
		 INC.L	   #2,ER6
		 BLD	   #3,R0H
		 BST	   S_BIT
		 JSR	   @JUDGE_BIT_TYPE
		 BLD	   S_BIT
		 BCC	   WR_BIT_RS:8
		 BSET	   R3L,@ER5
		 BRA	   WR_BIT_S1:8
WR_BIT_RS:	 BCLR	   R3L,@ER5
WR_BIT_S1:	 MOV.B	   @BYTE_COUNT,R0H
		 DEC.B	   R0H
		 DEC.B	   R0H
		 BNE	   WRITE_BIT_LP:8
		 BRA	   RET_OK
;; ======= #14 Read state in bit   =============
READ_STATE_BIT:  MOV.B	   @PG_BUF1,R0L
		 MOV.B	   R0L,@BYTE_COUNT
		 SHLR.B    R0L
		 MOV.B	   R0L,@PG_BUF1
		 MOV.L	   #PG_BUF2,ER6
		 MOV.L	   #PG_EXT,ER5
READ_TO_EXT1:	 MOV.B	   @ER6+,R0H
		 MOV.B	   R0H,@ER5
		 INC.L	   #1,ER5
		 DEC.B	   R0L
		 BNE	   READ_TO_EXT1:8
		 MOV.L	   #PG_EXT,ER6
		 MOV.L	   #PG_BUF2,ER2
READ_S_LP:	 MOV.W	   @ER6,R0
		 INC.L	   #2,ER6
		 JSR	   @JUDGE_BIT_TYPE
		 BTST	   R3L,@ER5
		 BEQ	   S_0:8
		 MOV.B	   #H'01,R3H
		 BRA	   S_1:8
S_0:		 MOV.B	   #H'00,R3H
S_1:		 MOV.B	   R3H,@ER2
		 INC.L	   #1,ER2
		 MOV.B	   @BYTE_COUNT,R3H
		 DEC.B	   R3H
		 MOV.B	   R3H,@BYTE_COUNT
		 BNE	   READ_S_LP:8
		 BRA	   RET_OK
; ========  #13 Read table     =================   ;
READ_TABLE:	 BSET	   READ_TABLE_BIT
		 BRA	   READ_STATE1
; ========  #16 Write table   ==================   ;
WRITE_TABLE:	 BSET	   WR_TABLE_BIT
		 BRA	   WRITE_STATE1
; ========  #18 Load memory from PACK  ==========  ;
LOAD_PACK:	 BLD	   RUN_FLAG		   ;
		 BCS	   LOAD_PACK_ERR	   ;
		 MOV.B	   @LED_DRIVER,ACC	   ;
		 BLD	   EEPROM_BIT		   ;;V1.1
		 BST	   #0,ACC		   ;;
		 MOV.B	   ACC,@LED_DRIVER	   ;;
		 MOV.B	   ACC,@H'000C0000         ;;
	    ;;	 MOV.B	   #B'11110011,ACC         ;;;V1.1
	    ;;	 MOV.B	   ACC,@WCR		   ;;;
		 MOV.B	   @EE_EXIST_ADDR,ACC	   ;
		 CMP.B	   #H'37,ACC               ;
		 BNE	   LOAD_PACK_ERR	   ;No user ROM pack exist
		 MOV.B	   @EE_EXIST_ADDR+1,ACC    ;
		 CMP.B	   #H'C8,ACC               ;
		 BNE	   LOAD_PACK_ERR	   ;
USER_ROM_CHK:	 JSR	   @EEPROM_CHECKSUM	   ;
		 BLD	   JUDGE_NG		   ;
		 BCS	   LOAD_PACK_ERR:8	   ;
		 JSR	   @LOAD_EEPROM 	   ;
		 JSR	   @DUMP_FLASH		   ;
		 BRA	   RET_OK_00		   ;
LOAD_PACK_ERR:	 MOV.B	   #H'16,R1H               ;;;V1.1
	    ;;	 MOV.B	   #B'11110000,B_REG       ;;
	    ;;	 MOV.B	   B_REG,@WCR		   ;;
		 BRA	   RET_ERROR		   ;
; ========  #19 Dump memory to PACK   ===========  ;
DUMP_PACK:    ;; BSET	   RUN_LED		   ;
		 BLD	   EEPROM_BIT		   ;;V1.1
		 BCC	   LOAD_PACK_ERR	   ;;
		 MOV.B	   @LED_DRIVER,ACC	   ;
		 BSET	   #0,ACC		   ;;
		 MOV.B	   ACC,@LED_DRIVER	   ;;
		 MOV.B	   ACC,@H'000C0000         ;;
		 MOV.B	   #H'55,ACC               ;
		 MOV.B	   ACC,@H'00082EFF         ;
		 JSR	   @DELAY_10MS		   ;
		 JSR	   @DELAY_10MS
		 MOV.B	   #H'00,ACC
		 MOV.B	   @H'00082EFF,ACC
		 MOV.B	   ACC,@H'000A0000         ;;VF.2
		 CMP.B	   #H'55,ACC
		 BNE	   LOAD_PACK_ERR
		 JSR	   @DUMP_EEPROM
		 BRA	   RET_OK_00
; ========  #20 Set password ok =================  ;
SET_PASSWORD_OK:
		 BLD	   OVER_PASSWORD	   ;
		 BCS	   RET_OK_00		   ;
		 BCLR	   SECRET_BIT		   ;
		 MOV.W	   #H'0,R0                 ;
		 MOV.W	   R0,@WS010_ADDR	   ;WS010
		 BRA	   RET_OK_00		   ;
; ========  #21 Write not correct password ======= ;
WR_NG_PASSWORD:  MOV.W	   @WS010_ADDR,R0	   ;
		 INC.W	   #1,R0		   ;
		 CMP.W	   #20,R0		   ;;TEST 5 TIMES ERROR
		 BCS	   WS010_INC		   ;
		 BSET	   OVER_PASSWORD	   ;
		 DEC.W	   #1,R0		   ;
WS010_INC:	 MOV.W	   R0,@WS010_ADDR	   ;
		 BRA	   RET_OK_00		   ;
; ========  #56 Read end of program ============== ;
READ_END_PROG:	 MOV.L	   #H'000F1F3E,ER6         ;
READ_END_LP:	 MOV.W	   @ER6,R5		   ;
		 CMP.W	   #H'0000,R5              ;
		 BNE	   READ_END_OK		   ;
		 DEC.L	   #2,ER6		   ;
		 CMP.L	   #H'000F0000,ER6         ;
		 BCC	   READ_END_LP:8	   ;
		 MOV.W	   #H'0000,R6              ;
READ_END_OK:	 MOV.B	   #H'00,R1L               ;
		 MOV.B	   R1L,@PG_STX		   ;
		 MOV.B	   #H'02,R1L               ;
		 MOV.B	   R1L,@PG_BUF1 	   ;
		 MOV.B	   R6H,@PG_BUF2 	   ;
		 MOV.B	   R6L,@PG_BUF3 	   ;
		 BRA	   RET_OK		   ;
; ========  #29 Compare password ================= ;
CHECK_PASSWORD:  MOV.L	   #WS039_ADDR,ER6	   ;
		 MOV.L	   #PG_BUF5,ER5 	   ;
		 MOV.B	   #2,R2L		   ;
CHK_PASS_LP:	 MOV.W	   @ER6,R0		   ;
		 MOV.W	   @ER5,R1		   ;
		 INC.L	   #2,ER6		   ;
		 INC.L	   #2,ER5		   ;
		 CMP.W	   R0,R1		   ;
		 BNE	   PASSWORD_ERR 	   ;
		 DEC.B	   R2L			   ;
		 BNE	   CHK_PASS_LP:8	   ;
		 BRA	   RET_OK_00		   ;
; ========  #30 Update password =================  ;
UPDATE_PASSWORD: MOV.L	   #WS039_ADDR,ER6	   ;
		 MOV.L	   #PG_BUF5,ER5 	   ;
		 MOV.B	   #4,R1L		   ;
WR_PASS_LP:	 MOV.B	   @ER5,R0L		   ;
		 MOV.B	   R0L,@ER6		   ;
		 INC.L	   #1,ER6		   ;
		 INC.L	   #1,ER5		   ;
		 DEC.B	   R1L			   ;
		 BNE	   WR_PASS_LP:8 	   ;
	     ;	 MOV.W	   @WS039_ADDR,R0	   ;
	     ;	 MOV.W	   @WS040_ADDR,R1	   ;
	     ;	 ADD.W	   R0,R1		   ;
	     ;	 MOV.W	   R1,@PASS_MEM 	   ;
		 MOV.L	   @WS039_ADDR,ER5	   ;;VF.3
		 CMP.L	   #0,ER5		   ;;
		 BEQ	   NO_PASS_WORD:8	   ;;
		 BSET	   SECRET_BIT		   ;
		 BRA	   RET_OK_00		   ;
NO_PASS_WORD:	 BCLR	   SECRET_BIT		   ;;VF.3
		 BRA	   RET_OK_00		   ;;
; ========  #50 Insert instruction with NU ======  ;
INSERT_INST_PU12: .EQU	   $			   ;
		 BLD	   RUN_FLAG		   ;
		 BCS	   PC_RUNNING_ERR	   ;
		 BSET	   NU_EXIST		   ;
		 BRA	   INSERT_INST1 	   ;
; ========  #51 Write instruction with NU =======  ;
WRITE_INST_PU12: ;BLD	    RUN_FLAG		    ;VF.0
		 ;BCS	    PC_RUNNING_ERR	    ;
		 BSET	   NU_EXIST		   ;
		 BRA	   WRITE_INST1		   ;
; ========  #52 Read instruction with NU ========  ;
READ_INST_PU12:  BSET	   NU_EXIST		   ;
		 BRA	   READ_INST1		   ;
; ========  #53 Update password =================  ;
SET_RESET_COIL:  MOV.B	   @PG_BUF2,R1H 	   ;;T3 T2 T1 T0 0 R10 R9 R8
		 MOV.B	   @PG_BUF3,R1L 	   ;;R7 R6 R5 R4 R3 R2 R1 R0
		 MOV.B	   @PG_BUF4,R2L 	   ;;
		 MOV.B	   R1H,R0L
		 AND.B	   #B'00000111,R1H
		 AND.B	   #B'11110000,R0L
Y_STATE_SR:	 CMP.B	   #B'00010000,R0L
		 BNE	   C_STATE_SR:8
		 MOV.L	   #Y_STATE,ER6
		 BRA	   STATE_REFRESH
C_STATE_SR:	 CMP.B	   #B'00110000,R0L
		 BNE	   X_STATE_SR:8
		 MOV.L	   #C_STATE,ER6
		 BRA	   STATE_REFRESH
X_STATE_SR:	 CMP.B	   #B'01010000,R0L
		 BNE	   M_STATE_SR:8
		 MOV.L	   #X_STATE,ER6
		 BRA	   STATE_REFRESH
M_STATE_SR:	 CMP.B	   #B'10010000,R0L
		 BNE	   T_C_STATE_SR:8
		 MOV.L	   #M_STATE,ER6
		 BRA	   STATE_REFRESH
T_C_STATE_SR:	 BRA	   RET_OK_00		;????NOT FINISH
STATE_REFRESH:	 ADD.W	   R1,R6
		 BLD	   #7,R2L
		 AND.B	   #B'00000111,R2L
		 BCS	   STATE_SET
		 BCLR	   R2L,@ER6
		 BRA	   RET_OK_00
STATE_SET:	 BSET	   R2L,@ER6
		 BRA	   RET_OK_00
; ========  #F0 Initial controller ID ===========  ;
INIT_CONTROL_ID: BCLR	   TD_MOD		   ;;FOR F33
		 BSET	   F0_BIT		   ;;V0.D
		 MOV.B	   #H'02,R0L               ;byte counter
		 MOV.L	   #PG_BUF1,ER6 	   ;
		 MOV.B	   R0L,@ER6		   ;
		 INC.L	   #1,ER6		   ;
		 MOV.B	   #H'10,R0L               ;model type  TP02-40MR/60MR
		 MOV.B	   R0L,@ER6		   ;	   H'11 TP02-20MR/28MR
		 INC.L	   #1,ER6		   ;
                 MOV.B     #H'16,R0L               ;version number V1.6
		 MOV.B	   R0L,@ER6		   ;	       12/03/1998
PASS_CHECK_F0:	 MOV.W	   @WS039_ADDR,R0	   ;
		 MOV.W	   @WS040_ADDR,R1	   ;
		 CMP.W	   #H'0000,R0              ;
		 BNE	   PASS_EXIST		   ;
		 CMP.W	   #H'0000,R1              ;
		 BNE	   PASS_EXIST		   ;
		 BCLR	   SECRET_BIT		   ;
		 BRA	   F0_RET:8		   ;;V0.D
PASS_EXIST:	 BSET	   SECRET_BIT		   ;
F0_RET: 	 BLD	   RUN_FLAG		   ;;
		 BCC	   RET_OK1		   ;;
		 BSET	   ERR_RESP		   ;;
		 BRA	   RET_OK		   ;
; ========  #F5 Initial new model type =========   ;
INIT_NEW_TYPE:
		 BRA	   RET_OK0		   ;

;;;;;; SUBROUTINE TO PUT INTO TP02SUBR.ASM ;;;;;;;
;  inst code map   TP02-20,28	F8000H - F8BB9H    ;
;		   TP02-40,60	F0000H - F1F41H    ;
;  NU code map	   TP02-20,28	F8BC0H - F919CH    ;
;		   TP02-40,60	F1F50H - F2EF0H    ;
CLEAR_PROGRAM:	 BLD	   PRG_4K_MODE		   ;
		 BCC	   TP02_28_MODE 	   ;
TP02_60_MODE:	 MOV.L	   #H'000F0000,ER6         ;INST code pointer
		 MOV.L	   #H'000F1F50,ER5         ;NU code pointer
		 MOV.W	   #D'4000,R0              ;4000 FOR TP02-60,ONLY TEST
		 BRA	   CLR_PROG_LP:8	   ;
TP02_28_MODE:	 MOV.L	   #H'000F8000,ER6         ;
		 MOV.L	   #H'000F8BC0,ER5         ;
		 MOV.W	   #D'1500,R0              ;
CLR_PROG_LP:	 MOV.W	   #H'00,R1                ;NOP : 00
CLR_PROG_LP1:	 MOV.W	   R1,@ER6		   ;
		 MOV.B	   R1L,@ER5		   ;
		 INC.L	   #2,ER6		   ;
		 INC.L	   #1,ER5		   ;
		 DEC.W	   #1,R0		   ;
		 BNE	   CLR_PROG_LP1:8	   ;
RESTORE_F00:	 MOV.B	   R1L,@ER6		   ; F00_END  00H
		 INC.L	   #1,ER6		   ;	      F0H
		 MOV.B	   #H'70,R1L               ;          0FH
		 MOV.B	   R1L,@ER6		   ;
		 MOV.B	   #H'07,R1L               ;
		 MOV.B	   R1L,@ER5		   ;
		 RTS				   ;
;;;
CLR_USED_TABLE:  MOV.L	   #Y_USED_TABLE,ER6	   ;
		 MOV.W	   #D'352,R1               ;V0.7
		 MOV.B	   #H'00,R2L               ;
CLR_USED_LP:	 MOV.B	   R2L,@ER6		   ;
		 INC.L	   #1,ER6		   ;
		 DEC.W	   #1,R1		   ;
		 BNE	   CLR_USED_LP:8	   ;
		 RTS				   ;
;;;
INIT_SYS_MEMORY: MOV.L	   #WS_MEMORY_ADDR,ER6	   ;
		 MOV.W	   #D'256,R1               ;
		 MOV.B	   #H'00,R2L               ;
CLR_SYS_LP:	 MOV.B	   R2L,@ER6		   ;
		 INC.L	   #1,ER6		   ;
		 DEC.W	   #1,R1		   ;
		 BNE	   CLR_SYS_LP:8 	   ;
		 RTS				   ;
;;;
CLEAR_DATA_MEM:  MOV.L	   #X_STATE,ER6 	   ;;Xxxx-V1017
		 MOV.W	   #D'3506,R1              ;
		 MOV.B	   #H'00,R2L               ;
CLR_DATA_LP1:	 MOV.B	   R2L,@ER6		   ;
		 INC.L	   #1,ER6		   ;
		 DEC.W	   #1,R1		   ;
		 BNE	   CLR_DATA_LP1:8	   ;
		 MOV.L	   #D_MEMORY_ADDR,ER6	   ;;VF.2
		 MOV.W	   #D'4096,R1              ;
		 MOV.B	   #H'00,R2L               ;
CLR_DATA_LP11:	 MOV.B	   R2L,@ER6		   ;
		 INC.L	   #1,ER6		   ;
		 DEC.W	   #1,R1		   ;
		 BNE	   CLR_DATA_LP11:8	   ;
		 MOV.L	   #WC_MEMORY_ADDR,ER6	   ;
		 MOV.W	   #D'1024,R1              ;WC001-WC512
		 MOV.B	   #H'00,R2L               ;
CLR_DATA_LP2:	 MOV.B	   R2L,@ER6		   ;
		 INC.L	   #1,ER6		   ;
		 DEC.W	   #1,R1		   ;
		 BNE	   CLR_DATA_LP2:8	   ;
		 MOV.W	   #D'400,R1               ;FILE1-FILE20
		 MOV.W	   #H'20,R2                ;20*20=400
CLR_DATA_LP21:	 MOV.W	   R2,@ER6		   ;
		 INC.L	   #2,ER6		   ;
		 DEC.W	   #1,R1		   ;
		 BNE	   CLR_DATA_LP21:8	   ;
		 MOV.W	   #D'2200,R1              ;FILE21-FILE130
		 MOV.B	   #H'20,R2L               ;110*20=2200
CLR_DATA_LP22:	 MOV.B	   R2L,@ER6		   ;
		 INC.L	   #1,ER6		   ;
		 DEC.W	   #1,R1		   ;
		 BNE	   CLR_DATA_LP22:8	   ;
		 MOV.B	   #H'FF,ACC               ;;;V0.D
		 MOV.L	   #X1_X8_BUFF,DPTR	   ;;
CLR_LED_BUFF:	 MOV.B	   ACC,@DPTR		  ;;
		 INC.L	   #1,DPTR		  ;;
		 CMP.L	   #Y21_Y24_BUFF+1,DPTR   ;;
		 BCS	   CLR_LED_BUFF:8	  ;;
		 JSR	   @EXE_WR_DR_00	  ;;
		 RTS				   ;

RELOAD_PRG_EPTR: BLD	   PRG_4K_MODE		   ;
		 BCC	   TP02_28_SPACE2:8	   ;
TP02_60_SPACE2:  MOV.L	   #H'000F1F3F,ER6         ;F1F3F
		 MOV.L	   #H'000F2EEF,ER5         ;F2EEF
		 RTS				   ;
TP02_28_SPACE2:  MOV.L	   #H'000F8BB7,ER6         ;
		 MOV.L	   #H'000F919B,ER5         ;
		 RTS				   ;

RELOAD_PRG_SPTR: BLD	   PRG_4K_MODE		   ;
		 BCC	   TP02_28_SPACE1:8	   ;
TP02_60_SPACE1:  MOV.L	   #H'000F0000,ER6         ;
		 MOV.L	   #H'000F1F50,ER5         ;
		 RTS				   ;
TP02_28_SPACE1:  MOV.L	   #H'000F8000,ER6         ;
		 MOV.L	   #H'000F8BC0,ER5         ;
		 RTS				   ;





;******************************************************************************
;******************    CHECK_SPACE     ****************************************
;******************************************************************************
;/* Module Name:   CHECK_SPACE
;   Description:   Check the last address for R0L bytes are NOP or not
;   Input:	   R0L(byte number),R1 byte address
;   Return:	   JUDGE_NG = 1 ERROR, = 0 OK,
CHECK_SPACE:	 BSR	   RELOAD_PRG_SPTR	   ;
		 MOV.B	   #H'00,R0H               ;
		 SHLL.W    R1			   ;
		 ADD.W	   R1,R6		   ;
		 ADD.W	   R0,R6		   ;
		 CMP.L	   #F00_END_ADDR,ER6	   ;
		 BCC	   CHECK_MEM_NG 	   ;
		 MOV.B	   R0L,R2L		   ;
		 SHLR.B    R2L			   ;1 word = 2 bytes
		 BSR	   RELOAD_PRG_EPTR	   ;
CHECK_SPACE_LP:  MOV.W	   @ER6,E0		   ;
		 MOV.B	   @ER5,R0L		   ;
		 DEC.L	   #2,ER6		   ;
		 DEC.L	   #1,ER5		   ;
		 CMP.L	   #0,ER0		   ;
		 BNE	   CHECK_MEM_NG:8	   ;
		 DEC.B	   R2L			   ;
		 BNE	   CHECK_SPACE_LP:8	   ;
CHECK_MEM_OK:	 BCLR	   JUDGE_NG		   ;
		 RTS				   ;
CHECK_MEM_NG:	 BSET	   JUDGE_NG		   ;
		 RTS				   ;
;******************************************************************************
;******************    SHIFT_INC       ****************************************
;******************************************************************************
;/* Module Name:   SHIFT_INC
;   Description:   Shift start address for increment N bytes
;   Input:	   R0L(shift byte number),ER2(inst shift end address)			       ;
;   Operation:	   ER6-N->ER4,ER5-N/2->ER3
;		   @ER4- -> @ER6-
;		   @ER4- -> @ER6-
;		   @ER3- -> @ER5-
;		   IF ER4 >= ER2   , THEN CONTINUE
;   Return: none
SHIFT_INC:	 MOV.B	   #00,R0H		   ;
		 BSR	   RELOAD_PRG_EPTR	   ;
		 MOV.L	   ER6,ER4		   ;
		 MOV.L	   ER5,ER3		   ;
		 SUB.W	   R0,R4		   ;
		 SHLR.W    R0			   ;
		 SUB.W	   R0,R3		   ;
SHIFT_INC_INST:  MOV.B	   @ER4,R0L		   ;
		 MOV.B	   R0L,@ER6		   ;
		 MOV.B	   @ER3,R0L		   ;
		 MOV.B	   R0L,@ER5		   ;
		 DEC.L	   #1,ER4		   ;
		 DEC.L	   #1,ER6		   ;
		 DEC.L	   #1,ER3		   ;
		 DEC.L	   #1,ER5		   ;
		 MOV.B	   @ER4,R0L		   ;
		 MOV.B	   R0L,@ER6		   ;
		 DEC.L	   #1,ER4		   ;
		 DEC.L	   #1,ER6		   ;
		 CMP.L	   ER4,ER2		   ;
		 BCS	   SHIFT_INC_INST:8	   ;;VF.1
		 RTS				   ;
;******************************************************************************
;******************    SHIFT_DEC       ****************************************
;******************************************************************************
;/* Module Name:   SHIFT_DEC
;   Description:   Shift start address for decrement N bytes
;   Input:	   R0L(shift byte number),ER6(inst shift start address)
;					  ER5(NU shift start address)
;					  ER2(shift end address)
;   Operation:	   ER6+N->ER4,ER5+N/2->ER3
;		   @ER4+ -> @ER6+
;		   @ER4+ -> @ER6+
;		   @ER3+ -> @ER5+
;		   IF ER4 < ER2   , THEN CONTINUE
;		   NOP -> ER2-2 -> ER2-2-N
;   Return: none
SHIFT_DEC:    ;; BSR	   UPDATE_USED_TABL	   ;
		 MOV.B	   #0,R0H		   ;
		 MOV.W	   R0,R1		   ;byte number buffer
		 MOV.L	   ER6,ER4		   ;
		 ADD.W	   R0,R4		   ;
		 MOV.L	   ER5,ER3		   ;
		 SHLR.W    R0			   ;
		 ADD.W	   R0,R3		   ;
SHIFT_INST_NU_D: MOV.B	   @ER4,R0L		   ;
		 MOV.B	   R0L,@ER6		   ;
		 INC.L	   #1,ER4		   ;
		 INC.L	   #1,ER6		   ;
		 MOV.B	   @ER3,R0L		   ;NU code move
		 MOV.B	   R0L,@ER5		   ;
		 INC.L	   #1,ER3		   ;
		 INC.L	   #1,ER5		   ;
		 MOV.B	   @ER4,R0L		   ;
		 MOV.B	   R0L,@ER6		   ;
		 INC.L	   #1,ER4		   ;
		 INC.L	   #1,ER6		   ;
		 CMP.L	   ER2,ER4		   ;
		 BCS	   SHIFT_INST_NU_D:8	   ;
		 MOV.B	   #H'00,R0L               ;RESTORE F40_END
		 MOV.B	   R0L,@ER4		   ;
		 INC.L	   #1,ER4		   ;
		 MOV.B	   #H'70,R0L               ; V0.B
		 MOV.B	   R0L,@ER4		   ;
		 MOV.B	   #H'07,R0L               ;
		 MOV.B	   R0L,@ER5		   ;
RESTORE_NOP:	 BSR	   RELOAD_PRG_EPTR	   ;
RESTORE_NOP_LP:  MOV.B	   R1H,@ER6		   ;
		 DEC.L	   #1,ER6		   ;
		 MOV.B	   R1H,@ER5		   ;
		 DEC.L	   #1,ER5		   ;
		 DEC.B	   R1L			   ;
		 BNE	   RES_NOP_LP1:8	   ;
		 RTS				   ;
RES_NOP_LP1:	 MOV.B	   R1H,@ER6		   ;
		 DEC.L	   #1,ER6		   ;
		 DEC.B	   R1L			   ;
		 BNE	   RESTORE_NOP_LP:8	   ;
		 RTS				   ;

UPDATE_USED_TABL1: .EQU     $
		 PUSH.L    ER6
		 PUSH.L    ER5
		 PUSH.W    R0
		 PUSH.L    ER2
		 MOV.B	   #H'01,R0L
		 BRA	   UPDATE_U_LP:8
UPDATE_USED_TABL: .EQU	   $
		 PUSH.L    ER6
		 PUSH.L    ER5
		 PUSH.W    R0
		 PUSH.L    ER2
		 SHLL.B    R0L
UPDATE_U_LP:	 MOV.B	   @ER6,R2H	      ;R2H : 0,TP1,TP0,A4,A3,A2,A1,A0
		 INC.L	   #1,ER6	      ;R2L : P,C3,C2,C1,C0,B2,B1,B0
		 MOV.B	   @ER6,R2L
		 MOV.W	   R2,E2	      ;BUFFER FOR T/C JUDGE
		 INC.L	   #1,ER6
		 BLD	   #7,R2H	      ;
		 BCS	   NON_USED_JUG1      ;NOT FUNCTION START
		 MOV.B	   R2L,R3H	      ;;
		 AND.B	   #B'01111000,R3H    ;;
		 CMP.B	   #B'01000000,R3H    ;;
		 BNE	   T_C_USED_JUG1      ;;NOT OUT FUNCTION
		 MOV.B	   R2H,R3L
		 AND.B	   #B'00000111,R2L
		 MOV.B	   #H'0,R3H
		 AND.B	   #B'01100000,R3L
Y_USED_JUG1:	 CMP.B	   #B'00100000,R3L
		 BNE	   C_USED_JUG1:8
		 MOV.B	   R2H,R3L
		 AND.B	   #B'00011111,R3L
		 BLD	   NU_EXIST	      ;
		 BCC	   Y_USED_JUG11:8     ;
		 MOV.L	   @ER3_BUFFER,ER1    ;
		 MOV.B	   @ER1,R0L	      ;
		 MOV.B	   #0,R0H	      ;
		 SHLL.W    R0		      ;
		 AND.W	   #H'01E0,R0         ;
		 ADD.W	   R0,R3	      ;
Y_USED_JUG11:	 MOV.L	   #Y_USED_TABLE,ER6
		 ADD.W	   R3,R6
		 BCLR	   R2L,@ER6
		 BRA	   NON_USED_JUG1
C_USED_JUG1:	 CMP.B	   #B'01000000,R3L
		 BNE	   M_USED_JUG1:8
		 MOV.B	   R2H,R3L
		 AND.B	   #B'00011111,R3L
		 BLD	   NU_EXIST	      ;
		 BCC	   C_USED_JUG11:8     ;
		 MOV.L	   @ER3_BUFFER,ER1    ;
		 MOV.B	   @ER1,R0L	      ;
		 MOV.B	   #0,R0H	      ;
		 SHLL.W    R0		      ;
		 AND.W	   #H'01E0,R0         ;
		 ADD.W	   R0,R3	      ;
C_USED_JUG11:	 MOV.L	   #C_USED_TABLE,ER6
		 ADD.W	   R3,R6
		 BCLR	   R2L,@ER6
		 BRA	   NON_USED_JUG1
M_USED_JUG1:	 CMP.B	   #B'01100000,R3L
		 BNE	   NON_USED_JUG1:8
		 MOV.B	   R2H,R3L
		 AND.B	   #B'00011111,R3L
		 BLD	   NU_EXIST	      ;
		 BCC	   M_USED_JUG11:8     ;
		 MOV.L	   @ER3_BUFFER,ER1    ;
		 MOV.B	   @ER1,R0L	      ;
		 MOV.B	   #0,R0H	      ;
		 SHLL.W    R0		      ;
		 AND.W	   #H'01E0,R0         ;
		 ADD.W	   R0,R3	      ;
M_USED_JUG11:	 MOV.L	   #M_USED_TABLE,ER6
		 ADD.W	   R3,R6
		 BCLR	   R2L,@ER6
		 BRA	   NON_USED_JUG1
T_C_USED_JUG1:	 MOV.W	   E2,R2	      ;R2H : 0,TP1,TP0,A4,A3,A2,A1,A0
		 MOV.B	   R2L,R3L	      ;R2L : P,C3,C2,C1,C0,B2,B1,B0
		 AND.B	   #B'01111000,R3L    ;R2H : 0,D6,D5,D4,D3,D2,D1,D0
		 CMP.B	   #B'01100000,R3L    ;R2L : P,C3,C2,C1,C0,D9,D8,D7
		 BEQ	   TC_USED_ST:8       ;R2H': 0,D9,D8,D7,D6,D5,D4,D3
		 CMP.B	   #B'01101000,R3L    ;R2L':               D2,D1,D0
		 BEQ	   TC_USED_ST:8
		 BRA	   NON_USED_JUG1:8
TC_USED_ST:	 SHLR.B    R2H
		 SHLR.B    R2H
		 SHLR.B    R2H
		 BLD	   #0,R2L
		 BST	   #4,R2H
		 BLD	   #1,R2L
		 BST	   #5,R2H
		 BLD	   #2,R2L
		 BST	   #6,R2H
		 MOV.B	   R2H,R3L
		 MOV.B	   #0,R3H
		 MOV.L	   #T_C_USED_TABLE,ER6
		 ADD.W	   R3,R6
		 MOV.W	   E2,R2
		 AND.B	   #B'00000111,R2H
		 BCLR	   R2H,@ER6
		 BRA	   NON_USED_JUG1
NON_USED_JUG1:	 DEC.B	   R0L
		 BNE	   UPDATE_U_LP
		 POP.L	   ER2
		 POP.W	   R0
		 POP.L	   ER5
		 POP.L	   ER6
		 RTS

;******************************************************************************
;******************    INST_MEM_WR     ****************************************
;******************************************************************************
;/* Module Name:   INST_MEM_WR
;   Description:   Write instruction code into memory
;   Input:	   R0H(byte numbers to write),ER6(inst start address)
;					      ER5(NU start address)
;					      ER4(PG inst start address)
;   Operation:	   @ER4+ -> @ER6+
;		   @ER4+ -> @ER6+
;		   read NU
;		   calculate checksum
;		   OR checksum with NU
;		   NU -> @ER5+
;		   R0H-1 -> R0H, IF NOT EQUAL TO ZERO, THEN CONTINUE
;   Return: none
INST_MEM_WR:	 MOV.L	   ER6,ER3		   ;
		 CMP.L	   #F00_END_ADDR,ER3	   ;+2
		 BCS	   INST_MEM_WR1:8	   ;BNE
		 BCLR	   JUDGE_NG		   ;
		 RTS				   ;
INST_MEM_WR1:	 MOV.B	   R0H,R1L		   ;
		 MOV.B	   #H'0,R1H                ;
		 ADD.W	   R1,R3		   ;
		 CMP.L	   #F00_END_ADDR+2,ER3	   ;
		 BEQ	   WR_INST_NG		   ;
HIGH_BYTE_WR:	 BLD	   NU_EXIST		   ;;
		 BCC	   HIGH_BYTE_WR1:8	   ;;
		 MOV.L	   ER4,ER3		   ;;NEW TP02 PROTOCOL USED
		 MOV.B	   R0H,R1L		   ;;
		 ADD.W	   R1,R3		   ;;
		 MOV.L	   ER3,@ER3_BUFFER	   ;;
HIGH_BYTE_WR1: ;;BSR	   UPDATE_USED_TABL1	   ;
		 MOV.B	   @ER4,R0L		   ;
		 MOV.B	   R0L,R2H		  ;;0,TP1,TP0,A4,A3,A2,A1,A0
		 INC.L	   #1,ER4		   ;
		 MOV.B	   R0L,@ER6		   ;
		 INC.L	   #1,ER6		   ;
		 MOV.B	   R0L,R1L		   ;
		 BSR	   SWAP_R0L		   ;
		 ADD.B	   R0L,R1L		   ;low nibble : checksum code
		 DEC.B	   R0H			   ;
		 BNE	   LOW_BYTE_WR:8	   ;???
		 RTS				   ;???
LOW_BYTE_WR:	 MOV.B	   @ER4,R0L		   ;
		 BLD	   #7,R2H		   ;JUDGE IF START FUNCTION
		 BCS	   LOW_BYTE_WR2 	   ;
		 MOV.B	   R0L,R2L		  ;;P,C3,C2,C1,C0,B2,B1,B0
		 MOV.W	   R2,E2		  ;;BUFFER FOR TC JUDGE
		 AND.B	   #B'01111000,R2L        ;;
		 CMP.B	   #B'01000000,R2L        ;;judge if OUT element
		 BNE	   LOW_BYTE_WR1:8	  ;;
		 MOV.B	   R0L,R2L		  ;;
	       ;;BSR	   WR_USED_TBL		  ;;
		 BRA	   LOW_BYTE_WR2:8	  ;;
LOW_BYTE_WR1:	 CMP.B	   #B'01100000,R2L         ;judge if TMR/CNT element
		 BEQ	   T_C_USED_WR:8	   ;
		 CMP.B	   #B'01101000,R2L         ;
		 BNE	   LOW_BYTE_WR2:8	   ;
T_C_USED_WR:   ;;BSR	   T_C_USED_UPDATE	   ;
LOW_BYTE_WR2:	 INC.L	   #1,ER4		   ;
		 MOV.B	   R0L,@ER6		   ;
		 INC.L	   #1,ER6		   ;
		 ADD.B	   R0L,R1L		   ;
		 BSR	   SWAP_R0L		   ;
		 ADD.B	   R0L,R1L		   ;
NU_BYTE_WR:	 BLD	   NU_EXIST		   ;
		 BCC	   NU_BYTE_WR1:8	   ;
		 MOV.L	   @ER3_BUFFER,ER3	   ;
		 MOV.B	   @ER3,R0L		   ;
		 INC.L	   #1,ER3		   ;
		 MOV.L	   ER3,@ER3_BUFFER	   ;
		 MOV.B	   R0L,R1H		   ;
		 AND.B	   #B'11110000,R1H         ;;
		 AND.B	   #B'11110000,R0L         ;;
		 BSR	   SWAP_R0L		   ;
		 ADD.B	   R0L,R1L		   ;
		 AND.B	   #B'00001111,R1L         ;;
		 OR.B	   R1L,R1H		   ;
		 MOV.B	   R1H,@ER5		   ;
		 INC.L	   #1,ER5		   ;
		 DEC.B	   R0H			   ;
		 BNE	   HIGH_BYTE_WR1	   ;;
		 BCLR	   JUDGE_NG		   ;
		 RTS				   ;
NU_BYTE_WR1:	 AND.B	   #H'0F,R1L               ;
		 MOV.B	   R1L,@ER5		   ;
		 INC.L	   #1,ER5		   ;
		 DEC.B	   R0H			   ;
		 BNE	   HIGH_BYTE_WR1	   ;;
		 BCLR	   JUDGE_NG		   ;
		 RTS				   ;
WR_INST_NG:	 BSET	   JUDGE_NG		   ;
		 RTS				   ;
;;
;; Input > R2H : 0,TP1,TP0,A4,A3,A2,A1,A0
;;	   R2L : P,C3,C2,C1,C0,B2,B1,B0

WR_USED_TBL:	 PUSH.L    ER6
		 PUSH.W    R0
		 MOV.W	   E2,R2
		 MOV.B	   R2H,R3L
		 AND.B	   #B'00000111,R2L
		 MOV.B	   #H'0,R3H
		 AND.B	   #B'01100000,R3L
Y_USED_JUG:	 CMP.B	   #B'00100000,R3L
		 BNE	   C_USED_JUG:8
		 MOV.B	   R2H,R3L
		 AND.B	   #B'00011111,R3L
		 BLD	   NU_EXIST	      ;
		 BCC	   Y_USED_JUG01:8     ;
		 MOV.L	   @ER3_BUFFER,ER1    ;
		 MOV.B	   @ER1,R0L	      ;
		 MOV.B	   #0,R0H	      ;
		 SHLL.W    R0		      ;
		 AND.W	   #H'01E0,R0         ;
		 ADD.W	   R0,R3	      ;
Y_USED_JUG01:	 MOV.L	   #Y_USED_TABLE,ER6
		 ADD.W	   R3,R6
		 BSET	   R2L,@ER6
		 BRA	   NON_USED_JUG
C_USED_JUG:	 CMP.B	   #B'01000000,R3L
		 BNE	   M_USED_JUG:8
		 MOV.B	   R2H,R3L
		 AND.B	   #B'00011111,R3L
		 BLD	   NU_EXIST	      ;
		 BCC	   C_USED_JUG01:8     ;
		 MOV.L	   @ER3_BUFFER,ER1    ;
		 MOV.B	   @ER1,R0L	      ;
		 MOV.B	   #0,R0H	      ;
		 SHLL.W    R0		      ;
		 AND.W	   #H'01E0,R0         ;
		 ADD.W	   R0,R3	      ;
C_USED_JUG01:	 MOV.L	   #C_USED_TABLE,ER6
		 ADD.W	   R3,R6
		 BSET	   R2L,@ER6
		 BRA	   NON_USED_JUG
M_USED_JUG:	 CMP.B	   #B'01100000,R3L
		 BNE	   NON_USED_JUG:8
		 MOV.B	   R2H,R3L
		 AND.B	   #B'00011111,R3L
		 BLD	   NU_EXIST	      ;
		 BCC	   M_USED_JUG01:8     ;
		 MOV.L	   @ER3_BUFFER,ER1    ;
		 MOV.B	   @ER1,R0L	      ;
		 MOV.B	   #0,R0H	      ;
		 SHLL.W    R0		      ;
		 AND.W	   #H'01E0,R0         ;
		 ADD.W	   R0,R3	      ;
M_USED_JUG01:	 MOV.L	   #M_USED_TABLE,ER6
		 ADD.W	   R3,R6
		 BSET	   R2L,@ER6
NON_USED_JUG:	 POP.W	   R0
		 POP.L	   ER6
		 RTS
T_C_USED_UPDATE: PUSH.L    ER6
		 MOV.W	   E2,R2
		 SHLR.B    R2H
		 SHLR.B    R2H
		 SHLR.B    R2H
		 BLD	   #0,R2L
		 BST	   #4,R2H
		 BLD	   #1,R2L
		 BST	   #5,R2H
		 BLD	   #2,R2L
		 BST	   #6,R2H
		 MOV.B	   R2H,R3L
		 MOV.B	   #0,R3H
		 MOV.L	   #T_C_USED_TABLE,ER6
		 ADD.W	   R3,R6
		 MOV.W	   E2,R2
		 AND.B	   #B'00000111,R2H
		 BSET	   R2H,@ER6
		 POP.L	   ER6
		 RTS

;******************************************************************************
;******************    JUDGE_STA_TYPE  ****************************************
;******************************************************************************
;/* Module Name:   JUDGE_STA_TYPE
;   Description:   judge state type
;   Input:	   R0L(data type)
;   Return:	   ER5(data type start address)
JUDGE_STA_TYPE:  .EQU	   $			   ;
Y_STATE_WR:	 CMP.B	   #H'00,R0L               ;limit the range ??????????
		 BNE	   C_STATE_WR:8 	   ;
		 MOV.L	   #Y_STATE,ER5 	   ;
		 BRA	   JUDGE_STAB_OK	   ;
C_STATE_WR:	 CMP.B	   #H'01,R0L               ;
		 BNE	   X_STATE_WR:8 	   ;
		 MOV.L	   #C_STATE,ER5 	   ;
		 BRA	   JUDGE_STAB_OK	   ;
X_STATE_WR:	 CMP.B	   #H'02,R0L               ;
		 BNE	   M_STATE_WR:8 	   ;
		 MOV.L	   #X_STATE,ER5 	   ;
		 BRA	   JUDGE_STAB_OK	   ;
M_STATE_WR:	 CMP.B	   #H'0A,R0L               ;
		 BNE	   V_STATE_WR:8 	   ;
		 MOV.L	   #M_STATE,ER5 	   ;
		 BRA	   JUDGE_STAB_OK	   ;
V_STATE_WR:	 CMP.B	   #H'05,R0L               ;
		 BNE	   WX_STATE_WR:8	   ;
		 MOV.L	   #V_MEMORY_ADDR,ER5	   ;
		 BRA	   JUDGE_STAW_OK	   ;
WX_STATE_WR:	 CMP.B	   #H'04,R0L               ;
		 BNE	   WY_STATE_WR:8	   ;
		 MOV.L	   #WX_MEMORY_ADDR,ER5	   ;
		 BRA	   JUDGE_STAW_OK	   ;
WY_STATE_WR:	 CMP.B	   #H'03,R0L               ;
		 BNE	   WS_STATE_WR:8	   ;
		 MOV.L	   #WY_MEMORY_ADDR,ER5	   ;
		 BRA	   JUDGE_STAW_OK	   ;
WS_STATE_WR:	 CMP.B	   #H'06,R0L               ;
		 BNE	   WC_STATE_WR:8	   ;
		 MOV.L	   #WS_MEMORY_ADDR,ER5	   ;
		 BRA	   JUDGE_STAW_OK	   ;
WC_STATE_WR:	 CMP.B	   #H'07,R0L               ;
		 BNE	   FILE_STATE_WR:8	   ;
		 MOV.L	   #WC_MEMORY_ADDR,ER5	   ;
		 BRA	   JUDGE_STAW_OK	   ;
FILE_STATE_WR:	 CMP.B	   #H'08,R0L               ;
		 BNE	   D_STATE_WR:8 	   ;
		 MOV.L	   #WC_MEMORY_ADDR+1024,ER5;+1024
		 BRA	   JUDGE_STAF_OK:8	   ;
D_STATE_WR:	 CMP.B	   #H'09,R0L               ;
		 BNE	   JUDGE_STAW_NG:8	   ;
		 MOV.L	   #D_MEMORY_ADDR,ER5	   ;
JUDGE_STAW_OK:	 BCLR	   JUDGE_NG		   ;
		 BSET	   WORD_TYPE		   ;
		 BCLR	   FILE_TYPE		   ; FILE <-> WC513
		 RTS				   ;
JUDGE_STAF_OK:	 BCLR	   JUDGE_NG		   ;
		 BSET	   WORD_TYPE		   ;
		 BSET	   FILE_TYPE		   ;
		 RTS				   ;
JUDGE_STAW_NG:	 BSET	   JUDGE_NG		   ;
		 BSET	   WORD_TYPE		   ;
		 RTS				   ;
JUDGE_STAB_OK:	 BCLR	   JUDGE_NG		   ;
		 BCLR	   WORD_TYPE		   ;
		 RTS				   ;
JUDGE_STAB_NG:	 BSET	   JUDGE_NG		   ;
		 BCLR	   WORD_TYPE		   ;
		 RTS				   ;

;******************************************************************************
;******************    JUDGE_TABLE_TYPE  **************************************
;******************************************************************************
;/* Module Name:   JUDGE_TABLE_TYPE
;   Description:   judge table type
;   Input:	   R0L(data type)
;   Return:	   ER5(data type start address)
JUDGE_TABLE_TYPE: .EQU	    $			   ;
Y_USED_TYPE:	 CMP.B	   #H'06,R0L               ;limit the range ??????????
		 BNE	   C_USED_TYPE:8	   ;
		 MOV.L	   #Y_USED_TABLE,ER5	   ;
		 BRA	   JUDGE_TABLE_OK	   ;
C_USED_TYPE:	 CMP.B	   #H'07,R0L               ;
		 BNE	   M_USED_TYPE:8	   ;
		 MOV.L	   #C_USED_TABLE,ER5	   ;
		 BRA	   JUDGE_TABLE_OK	   ;
M_USED_TYPE:	 CMP.B	   #H'0A,R0L               ;
		 BNE	   T_C_USED_TYPE:8	   ;
		 MOV.L	   #M_USED_TABLE,ER5	   ;
		 BRA	   JUDGE_TABLE_OK	   ;
T_C_USED_TYPE:	 CMP.B	   #H'08,R0L               ;
		 BRA	   JUDGE_TABLE_NG	   ;
	       ; MOV.L	   #T_C_USED_ADDR,ER5	   ;
	       ; BRA	   JUDGE_TABLE_OK	   ;
JUDGE_TABLE_OK:  BCLR	   JUDGE_NG		   ;
		 BCLR	   WORD_TYPE		   ;
		 RTS				   ;
JUDGE_TABLE_NG:  BSET	   JUDGE_NG		   ;
		 BCLR	   WORD_TYPE		   ;
		 RTS				   ;
;******************************************************************************
;******************    JUDGE_BIT_TYPE	 **************************************
;******************************************************************************
;/* Module Name:   JUDGE_TABLE_TYPE
;   Description:   judge table type
;   Input:	   R0(data type)
;   Return:	   ER5(data type start address)
;		   R3L(data bit)
JUDGE_BIT_TYPE:  MOV.W	   R0,R1		   ;
		 MOV.B	   R1L,R3L		   ;
		 AND.B	   #B'00000111,R3L         ;DATA BIT
		 AND.B	   #H'F0,R0H               ;
Y_STATE_BIT:	 CMP.B	   #H'10,R0H               ;limit the range ??????????
		 BNE	   C_STATE_BIT:8	   ;
		 MOV.L	   #Y_STATE,ER5 	   ;
		 BRA	   CAL_STATE_BIT:8	   ;
C_STATE_BIT:	 CMP.B	   #H'30,R0L               ;
		 BNE	   X_STATE_BIT:8	   ;
		 MOV.L	   #C_STATE,ER5 	   ;
		 BRA	   CAL_STATE_BIT:8	   ;
X_STATE_BIT:	 CMP.B	   #H'50,R0L               ;
		 BNE	   SC_STATE_BIT:8	   ;
		 MOV.L	   #C_STATE,ER5 	   ;
		 BRA	   CAL_STATE_BIT:8	   ;
SC_STATE_BIT:	 MOV.L	   #M_STATE,ER5 	   ;
CAL_STATE_BIT:	 SHLR.W    R1			   ;
		 SHLR.W    R1			   ;
		 SHLR.W    R1			   ;
		 AND.W	   #H'FF,R1                ;
		 ADD.W	   R1,R5		   ;
		 RTS				   ;
;******************************************************************************
;******************	  SWAP_ACC     ****************************************
;******************************************************************************
;/* Module Name:   SWAP_ACC()	NEW
;   Description:   Exchange the register between high nibble and low nibble
;   Input:	   ACC(b7 b6 b5 b4 b3 b2 b1 b0)
;   Return:	   ACC(b3 b2 b1 b0 b7 b6 b5 b4)
SWAP_ACC:
SWAP_R0L:      ROTL.B	 R0L
	       ROTL.B	 R0L
	       ROTL.B	 R0L
	       ROTL.B	 R0L
	       RTS

;******************************************************************************
;******************	  ASCII_HEX    ****************************************
;******************************************************************************
;/* Module Name:   ASCII_HEX()
;   Description:   Convert the ASCII code into the HEX code
;   Input:	   R0L(ASCII)
;   Return:	   R0L(HEX)
ASCII_HEX:     CMP.B	 #H'41,ACC
	       BCS	 ALPHA_KEY:8
OVER_A:        AND.B	 #H'0F,ACC         ;A(41H) - F(46H)
	       ADD.B	 #H'09,ACC         ;
	       RTS
ALPHA_KEY:     AND.B	 #H'0F,ACC         ;0 - 9
	       RTS

;******************************************************************************
;******************	  HEX_ASCII    ****************************************
;******************************************************************************
;/* Module Name:   HEX_ASCII()
;   Description:   Convert the HEX code into the ASCII code
;   Input:	   ACC(HEX)   H'00 H'01 H'02,,H'09 H'0A H'0B H'0C H'0D H'0E H'0F
;   Return:	   ACC(ASCII) H'30 H'31 H'32,,H'39 H'41 H'42 H'43 H'44 H'45 H'46
HEX_ASCII:     AND.B	 #H'0F,ACC
	       CMP.B	 #H'0A,ACC
	       BCS	 NUMER_KEY:8
	       ADD.B	 #H'37,ACC
	       RTS			    ;A - F
NUMER_KEY:     OR.B	 #H'30,ACC
	       RTS
;******************************************************************************
;******************    ASCII_HEX_ADDR	  *************************************
;******************************************************************************
;/* Module Name:   ASCII_HEX_ADDR()
;   Description:   Convert the ASCII to BCD CODE to HEX CODE
;   Input:	   ASCII_1000C,ASCII_100C,ASCII_10C,ASCII_0C
;   Return:	   B_W
ASCII_HEX_ADDR:
	       MOV.W	 #H'0000,B_W             ;
	       MOV.B	 @ASCII_1000C,ACC	 ;
	       BSR	 ASCII_HEX
	       BSR	 SWAP_ACC
	       MOV.B	 ACC,B_H
	       MOV.B	 @ASCII_100C,ACC
	       BSR	 ASCII_HEX
	       OR.B	 ACC,B_H
	       MOV.B	 @ASCII_10C,ACC
	       BSR	 ASCII_HEX
	       BSR	 SWAP_ACC
	       MOV.B	 ACC,B_REG
	       MOV.B	 @ASCII_0C,ACC
	       BSR	 ASCII_HEX
	       OR.B	 ACC,B_REG
	       MOV.W	 B_W,R4
	       JSR	 @BCD_HEX_W
	       MOV.W	 R4,B_W
	       RTS
;******************************************************************************
;******************    COM_FORMAT_CHK	  *************************************
;******************************************************************************
;/* Module Name: COM_FORMAT_CHK()
;   Description: Check the computer link format : (1).Checksum (2).Data length
;   Input:	 REG_R1(Byte number)
;   Return:	 COM_LNK_ERR=1(error),=0(correct)  REG_R1,REG_R2
COM_FORMAT_CHK:
	       BLD	 PG_COM_BIT		 ;
	       BCS	 PG_COM_FT_CHK:8	 ;=1, PG port computer link
	       MOV.B	 @ASCII1_3A,ACC 	 ;Check : :
	       CMP.B	 #ASCII_3AH,ACC 	 ;
	       BNE	 COM_FORM_ERR		 ;
	       MOV.B	 @ASCII2_3A,ACC 	 ;
	       CMP.B	 #ASCII_3AH,ACC 	 ;
	       BNE	 COM_FORM_ERR		 ;
	       MOV.L	 #COM_BUF1,DPTR 	 ;
	       MOV.B	 #H'00,B_REG             ;
	       BRA	 FORM_SUM_LOOP:8	 ;
PG_COM_FT_CHK: MOV.B	 @PG_STX,ACC		 ;Check : :
	       CMP.B	 #ASCII_3AH,ACC 	 ;
	       BNE	 COM_FORM_ERR		 ;
	       MOV.B	 @PG_BUF1,ACC		 ;
	       CMP.B	 #ASCII_3AH,ACC 	 ;
	       BNE	 COM_FORM_ERR		 ;
	       MOV.L	 #PG_BUF2,DPTR		 ;
	       MOV.B	 #H'00,B_REG             ;
FORM_SUM_LOOP: MOV.B	 @DPTR,ACC		 ;
	       ADD.B	 ACC,B_REG		 ;
	       INC.L	 #1,DPTR		 ;
	       DEC.B	 REG_R1 		 ;
	       BNE	 FORM_SUM_LOOP:8	 ;
	       NOT.B	 B_REG			 ;
	       ADD.B	 #1,B_REG		 ;
	       MOV.B	 @DPTR,ACC		 ;High byte
	       CMP.B	 #H'40,ACC               ;;;@ V0.5
	       BNE	 F_S_ST:8		 ;;;
	       INC.L	 #1,DPTR		 ;;;
	       MOV.B	 @DPTR,ACC		 ;;;
	       CMP.B	 #H'40,ACC               ;;;@
	       BEQ	 FORM_CR_CHK:8		 ;;;
	       BRA	 F_CSM_ERR:8		 ;;;V0.5
F_S_ST:        BSR	 ASCII_HEX		 ;
	       BSR	 SWAP_ACC		 ;
	       MOV.B	 ACC,REG_R1		 ;
	       INC.L	 #1,DPTR		 ;
	       MOV.B	 @DPTR,ACC		 ;
	       BSR	 ASCII_HEX		 ;Low byte
	       OR.B	 REG_R1,ACC		 ;
	       CMP.B	 B_REG,ACC		 ;
	       BEQ	 FORM_CR_CHK:8		 ;
F_CSM_ERR:     BSET	 COM_LNK_ERR		 ;Checksum error
	       MOV.B	 #ASCII_0,REG_R1	 ;
	       MOV.B	 #ASCII_3,REG_R2	 ;
	       RTS				 ;
FORM_CR_CHK:   INC.L	 #1,DPTR		 ;
	       MOV.B	 @DPTR,ACC		 ;
	       CMP.B	 #ASCII_CR,ACC		 ;
	       BEQ	 COM_FORM_OK:8		 ;
	       BSET	 COM_LNK_ERR		 ;Incorrect number of transfer
	       MOV.B	 #ASCII_0,REG_R1	 ;bytes error
	       MOV.B	 #ASCII_1,REG_R2	 ;
	       RTS				 ;
COM_FORM_OK:   BCLR	 COM_LNK_ERR		 ;
	       RTS				 ;
COM_FORM_ERR:  BSET	 COM_LNK_ERR		 ;Format error
	       MOV.B	 #ASCII_0,REG_R1	 ;
	       MOV.B	 #ASCII_1,REG_R2	 ;
	       RTS				 ;
;*------------------------------------------------------*;
;|   TAIAN computer link protocol			|;
;|   PG_COM_BIT = 1 : to solve PG port computer link	|;
;|   PG_COM_BIT = 0 : to solve RS422 port computer link |;
;*------------------------------------------------------*;
COMMPP_RESET1: BCLR	 PG_COM_BIT		 ;;V1.2 to prevent RS422 link
	       JMP	 @LED_BUF_REFLESH	 ;			 error
COMM_STRT:     BCLR	 RXENDF1		 ;Clear RXENDF
	       BCLR	 PG_COM_BIT		 ;;V0.E
	       MOV.B	 @COM_BUF1,ACC		 ;;
	       BSR	 ASCII_HEX		 ;;
	       BSR	 SWAP_ACC		 ;;
;;;;;;;;;;;;   SHLR.B	 ACC			 ;;VF.0
	       MOV.B	 ACC,ACC_H		 ;;
	       MOV.B	 @COM_BUF2,ACC		 ;;
	       BSR	 ASCII_HEX		 ;;
	       OR.B	 ACC_H,ACC		 ;;
	       MOV.B	 ACC,R4L		 ;;;VF.0
	       JSR	 @BCD_HEX_B		 ;;;
	       BLD	 JUDGE_NG		 ;;;
	       BCS	 COMM_RETS		 ;;;
	       MOV.B	 R4L,ACC		 ;;;
	       MOV.B	 @WS045_ADDR+1,B_REG	 ;;SYS_237_ADDR->WS045_ADDR TP02
	       CMP.B	 #H'00,ACC               ;;
	       BEQ	 CHK_CMD1:8		 ;;
	       CMP.B	 B_REG,ACC		 ;;
	       BNE	 COMMPP_RESET1		 ;;
	  ;;;; BSET	 TXENDF1		 ;; V0.E
	       BCLR	 BROADCAST_BIT		 ;;VF.3
	       BRA	 CHK_CMD10:8		 ;;
CHK_CMD1:      BSET	 BROADCAST_BIT		 ;;
CHK_CMD10:     MOV.B	 @COM_BUF3,ACC		 ;;
	       CMP.B	 #ASCII_3FH,ACC 	 ;;
	       BNE	 COMMPP_RESET1		 ;;
	       BSET	 TXENDF1		 ;; V0.E
	       MOV.B	 @COM_BUF4,ACC		 ;
	       MOV.B	 ACC,@RI_ADDR		 ;
	       MOV.L	 @COM_BUF5,BUFF_PTR1	 ;
	       BRA	 COMM_STRT_GO:8 	 ;
COMM_STRT_PG:  MOV.B	 @PG_BUF2,ACC		 ;;
	       BSR	 ASCII_HEX		 ;;
	       BSR	 SWAP_ACC		 ;;
;;;;;;;;;;;    SHLR.B	 ACC			 ;;VF.0
	       MOV.B	 ACC,ACC_H		 ;;
	       MOV.B	 @PG_BUF3,ACC		 ;;
	       BSR	 ASCII_HEX		 ;;
	       OR.B	 ACC_H,ACC		 ;;
	       MOV.B	 ACC,R4L		 ;;;VF.0
	       JSR	 @BCD_HEX_B		 ;;;
	       BLD	 JUDGE_NG		 ;;;
	       BCS	 COMM_RETS		 ;;;
	       MOV.B	 R4L,ACC		 ;;;
	       CMP.B	 #H'00,ACC               ;;
	       BEQ	 CHK_CMD2:8		 ;;
	       MOV.B	 @WS042_ADDR+1,B_REG	 ;;SYS_227_ADDR->WS042_ADDR
	       CMP.B	 B_REG,ACC		 ;;
	       BNE	 COMMPP_RESET1		 ;;
	   ;;; BSET	 TXENDF0		 ;;V0.E
	       BCLR	 BROADCAST_BIT		 ;;VF.3
	       BRA	 CHK_CMD20:8		 ;;
CHK_CMD2:      BSET	 BROADCAST_BIT		 ;;
CHK_CMD20:     MOV.B	 @PG_BUF4,ACC		 ;;
	       CMP.B	 #ASCII_3FH,ACC 	 ;;
	       BNE	 COMMPP_RESET1		 ;;
	       BSET	 TXENDF0		 ;;V0.E
	       MOV.B	 @PG_BUF5,ACC		 ;
	       MOV.B	 ACC,@PG_RI_ADDR	 ;
	       MOV.L	 @PG_BUF6,BUFF_PTR1	 ;
COMM_STRT_GO:  AND.L	 #H'FFFFFF00,BUFF_PTR1   ;
MCR_COMMAND:   CMP.L	 #CMD_MCR,BUFF_PTR1	 ; 1
	       BNE	 MRV_COMMAND:8		 ;
	       BRA	 MCR_START		 ;
MRV_COMMAND:   CMP.L	 #CMD_MRV,BUFF_PTR1	 ; 2
	       BNE	 PSR_COMMAND:8		 ;
	       BRA	 MRV_START		 ;
PSR_COMMAND:   CMP.L	 #CMD_PSR,BUFF_PTR1	 ; 3
	       BNE	 SCS_COMMAND:8		 ;
	       BRA	 PSR_START		 ;
SCS_COMMAND:   CMP.L	 #CMD_SCS,BUFF_PTR1	 ; 4
	       BNE	 WRV_COMMAND:8		 ;
	       BRA	 SCS_START		 ;
WRV_COMMAND:   CMP.L	 #CMD_WRV,BUFF_PTR1	 ; 5
	       BNE	 RTC_COMMAND:8		 ;
	       BRA	 WRV_START		 ;
RTC_COMMAND:   CMP.L	 #CMD_RTC,BUFF_PTR1	 ; 6
	       BNE	 PAS_COMMAND:8		 ;
	       BRA	 RTC_START		 ;
PAS_COMMAND:   CMP.L	 #CMD_PAS,BUFF_PTR1	 ; 7
	       BNE	 RUN_COMMAND:8		 ;
	       BRA	 PAS_START		 ;
RUN_COMMAND:   CMP.L	 #CMD_RUN,BUFF_PTR1	 ; 8	S
	       BNE	 RBP_COMMAND:8		 ;
	       BRA	 RUN_START		 ;
RBP_COMMAND:   CMP.L	 #CMD_RBP,BUFF_PTR1	 ; 9	S
	       BNE	 WBP_COMMAND:8		 ;
	       BRA	 RBP_START		 ;
WBP_COMMAND:   CMP.L	 #CMD_WBP,BUFF_PTR1	 ; 10	S
	       BNE	 STP_COMMAND:8		 ;
	       BRA	 WBP_START		 ;
STP_COMMAND:   CMP.L	 #CMD_STP,BUFF_PTR1	 ; 11	S
	       BNE	 ROM_COMMAND:8		 ;
	       BRA	 STP_START		 ;
ROM_COMMAND:   CMP.L	 #CMD_ROM,BUFF_PTR1	 ; 12	S
	       BNE	 CLR_COMMAND:8		 ;
	       BRA	 ROM_START		 ;
CLR_COMMAND:   CMP.L	 #CMD_CLR,BUFF_PTR1	 ; 13	S
	       BEQ	 CLR_START		 ;
	       BLD	 F58_RXD_EN		 ;;V0.9
	       BCC	 COMM_RETS:8		 ;;
	       BCLR	 TXENDF0		 ;;V0.E
	       JMP	 @LED_BUF_REFLESH	 ;;
COMM_RETS:     MOV.B	 #ASCII_0,REG_R1	 ; Error code :Format error
	       MOV.B	 #ASCII_1,REG_R2	 ;
	       BRA	 COM_ERR_RET		 ;
;===========   Relay monitor	  =============  ;
MCR_START:     MOV.B	 #D'12,REG_R1            ;Byte number
	       BSR	 COM_FORMAT_CHK 	 ;
	       BLD	 COM_LNK_ERR		 ;
	       BCC	 MCR_GO:8		 ;
	       BRA	 COM_ERR_RET		 ;
MCR_GO:        BLD	 PG_COM_BIT		 ;
	       BCS	 MCR_GO_1:8		 ;
	       MOV.L	 #COM_BUF9,DPTR 	 ;
	       BSR	 RELAY_HEX_ADDR 	 ;ASCII->OCT->HEX(B_W)
	       BLD	 JUDGE_NG		 ;
	       BCC	 MCR_GO_OK:8		 ;
	       MOV.B	 #ASCII_0,REG_R1	 ;
	       MOV.B	 #ASCII_1,REG_R2	 ;
	       BRA	 COM_ERR_RET		 ;
MCR_GO_OK:     BTST	 R3L,@ER5		 ;
	       BEQ	 MCR_OFF:8		 ;
	       MOV.B	 #ASCII_1,ACC		 ;
	       BRA	 MCR_DATA1:8		 ;
MCR_OFF:       MOV.B	 #ASCII_0,ACC		 ;
MCR_DATA1:     MOV.B	 ACC,@COM_BUF8		 ;
	       MOV.B	 #ASCII_23H,ACC 	 ;
	       MOV.B	 ACC,@COM_BUF3		 ;
	       MOV.W	 #D'8,DATA1_W            ;checksum number
	       BRA	 COM_LNK_RET		 ;
;
MCR_GO_1:      MOV.L	 #PG_BUF10,DPTR 	 ;
	       BSR	 RELAY_HEX_ADDR 	 ;ASCII->OCT->HEX(B_W)
	       BLD	 JUDGE_NG		 ;
	       BCC	 MCR_GO_OK1:8		 ;
	       MOV.B	 #ASCII_0,REG_R1	 ;
	       MOV.B	 #ASCII_1,REG_R2	 ;
	       BRA	 COM_ERR_RET		 ;
MCR_GO_OK1:    BTST	 R3L,@ER5		 ;
	       BEQ	 MCR_OFF1:8		 ;
	       MOV.B	 #ASCII_1,ACC		 ;
	       BRA	 MCR_DATA2:8		 ;
MCR_OFF1:      MOV.B	 #ASCII_0,ACC		 ;
MCR_DATA2:     MOV.B	 ACC,@PG_BUF9		 ;
	       MOV.B	 #ASCII_23H,ACC 	 ;
	       MOV.B	 ACC,@PG_BUF4		 ;
	       MOV.W	 #D'8,DATA1_W            ;checksum number
	       BRA	 COM_LNK_RET		 ;
;;ASCII->HEX(BYTE,BIT)->HEX+X_STATE		 ;X0001
RELAY_HEX_ADDR:  .EQU	 $			 ;
	       MOV.W	 #0,R4			 ;
	       MOV.B	 @DPTR,ACC		 ;
	       CMP.B	 #ASCII_C,ACC		 ;
	       BNE	 RELAY_HEX2:8		 ;SC128
	       MOV.B	 #H'30,ACC               ;X0384
RELAY_HEX2:    INC.L	 #1,DPTR		 ;Y0384
	       BSR	 ASCII_HEX		 ;C2048
	       BSR	 SWAP_ACC		 ;
	       OR.B	 ACC,R4H		 ;
	       MOV.B	 @DPTR,ACC		 ;
	       INC.L	 #1,DPTR		 ;
	       BSR	 ASCII_HEX		 ;
	       OR.B	 ACC,R4H		 ;
	       MOV.B	 @DPTR,ACC		 ;
	       INC.L	 #1,DPTR		 ;
	       BSR	 ASCII_HEX		 ;
	       BSR	 SWAP_ACC		 ;
	       OR.B	 ACC,R4L		 ;
	       MOV.B	 @DPTR,ACC		 ;
	       INC.L	 #1,DPTR		 ;
	       BSR	 ASCII_HEX		 ;
	       OR.B	 ACC,R4L		 ;
	       JSR	 @BCD_HEX_W		 ;
	       BLD	 JUDGE_NG		 ;
	       BCS	 RELAY_HEX_ERR		 ;
;;;;;;;;;;;;   MOV.W	 R4,R5			 ;;VF.2
	       CMP.W	 #0,R4			 ;X0000,Y0000....ERROR
	       BEQ	 RELAY_HEX_ERR		 ;
	       DEC.W	 #1,R4			 ;
	       MOV.B	 #0,R3L 		 ;
	       SHLR.W	 R4			 ;
	       BST	 #0,R3L 		 ;
	       SHLR.W	 R4			 ;
	       BST	 #1,R3L 		 ;
	       SHLR.W	 R4			 ;
	       BST	 #2,R3L 		 ;R4 : OFFSET ADDRESS
	       MOV.W	 R4,R5			 ;;VF.2
	       SUB.L	 #5,DPTR		 ;R3L: BIT NUMBER
	       MOV.B	 @DPTR,ACC		 ;
MCR_X:	       CMP.B	 #ASCII_X,ACC		 ;
	       BNE	 MCR_Y:8		 ;
	       CMP.W	 #H'30,R5                ;
	       BCC	 RELAY_HEX_ERR		 ;
	       MOV.L	 #X_STATE,ER5		 ;
	       ADD.W	 R4,R5			 ;
	       BRA	 RELAY_HEX_OK		 ;
MCR_Y:	       CMP.B	 #ASCII_Y,ACC		 ;
	       BNE	 MCR_C:8		 ;
	       CMP.W	 #H'30,R5                ;
	       BCC	 RELAY_HEX_ERR		 ;
	       MOV.L	 #Y_STATE,ER5		 ;
	       ADD.W	 R4,R5			 ;
	       BRA	 RELAY_HEX_OK		 ;
MCR_C:	       CMP.B	 #ASCII_C,ACC		 ;
	       BNE	 MCR_M:8		 ;
	       CMP.W	 #H'100,R5               ;
	       BCC	 RELAY_HEX_ERR		 ;
	       MOV.L	 #C_STATE,ER5		 ;
	       ADD.W	 R4,R5			 ;
	       BRA	 RELAY_HEX_OK		 ;
MCR_M:	       CMP.B	 #ASCII_S,ACC		 ;
	       BNE	 RELAY_HEX_ERR		 ;
	       CMP.W	 #H'10,R5                ;
	       BCC	 RELAY_HEX_ERR		 ;
	       MOV.L	 #M_STATE,ER5		 ;
	       ADD.W	 R4,R5			 ;
RELAY_HEX_OK:  BCLR	 JUDGE_NG		 ;ER5 STATE ADDRESS
	       RTS				 ;R3L BIT NUMBER
RELAY_HEX_ERR: BSET	 JUDGE_NG		 ;
	       RTS				 ;
;============  Relay set/reset	 =============== ;
SCS_START:     MOV.B	 #D'13,REG_R1            ;Byte number
	       BSR	 COM_FORMAT_CHK 	 ;
	       BLD	 COM_LNK_ERR		 ;
	       BCC	 SCS_GO:8		 ;
	       BRA	 COM_ERR_RET		 ;
SCS_GO:        BLD	 PG_COM_BIT		 ;
	       BCS	 SCS_GO_1:8		 ;
	       MOV.L	 #COM_BUF9,DPTR 	 ;
	       BSR	 RELAY_HEX_ADDR 	 ;ASCII->OCT->HEX(DPTR)
	       BLD	 JUDGE_NG		 ;;VF.2
	       BCS	 SCS_NG 		 ;;
	       MOV.B	 @COM_BUF13,B_REG	 ;
	       CMP.B	 #ASCII_0,B_REG 	 ;
	       BEQ	 SCS_RESET		 ;
	       CMP.B	 #ASCII_1,B_REG 	 ;
	       BEQ	 SCS_SET		 ;
	       MOV.B	 #ASCII_0,REG_R1	 ;
	       MOV.B	 #ASCII_1,REG_R2	 ;
	       BRA	 COM_ERR_RET		 ;
SCS_GO_1:      MOV.L	 #PG_BUF10,DPTR 	 ;
	       BSR	 RELAY_HEX_ADDR 	 ;
	       BLD	 JUDGE_NG		 ;;VF.2
	       BCS	 SCS_NG 		 ;;
	       MOV.B	 @PG_BUF14,B_REG	 ;
	       CMP.B	 #ASCII_0,B_REG 	 ;
	       BEQ	 SCS_RESET		 ;
	       CMP.B	 #ASCII_1,B_REG 	 ;
	       BEQ	 SCS_SET		 ;
SCS_NG:        MOV.B	 #ASCII_0,REG_R1	 ;
	       MOV.B	 #ASCII_1,REG_R2	 ;
	       BRA	 COM_ERR_RET		 ;
SCS_RESET:     BCLR	 R3L,@ER5		 ;
	       BRA	 SCS_OK:8		 ;
SCS_SET:       BSET	 R3L,@ER5		 ;
SCS_OK:        BLD	 PG_COM_BIT		 ;
	       BCS	 SCS_OK1:8		 ;
	       MOV.B	 #ASCII_23H,ACC 	 ;
	       MOV.B	 ACC,@COM_BUF3		 ;
	       MOV.W	 #D'7,DATA1_W            ;checksum number
	       BRA	 COM_LNK_RET		 ;
SCS_OK1:       MOV.B	 #ASCII_23H,ACC 	 ;PG PORT
	       MOV.B	 ACC,@PG_BUF4		 ;
	       MOV.W	 #D'7,DATA1_W            ;checksum number
	       BRA	 COM_LNK_RET		 ;
;;;INPUT NONE, OUTPUT ADDRESS:R6_BUFFER 	 ;
CHK_REG_ADDR:  BLD	 PG_COM_BIT		 ;
	       BCS	 CHK_REG_PG:8		 ;
	       MOV.B	 @COM_BUF9,ACC		 ;
	       MOV.B	 ACC,@ASCII_1000C	 ;
	       MOV.B	 @COM_BUF10,ACC 	 ;
	       MOV.B	 ACC,@ASCII_100C	 ;
	       MOV.B	 @COM_BUF11,ACC 	 ;
	       MOV.B	 ACC,@ASCII_10C 	 ;
	       MOV.B	 @COM_BUF12,ACC 	 ;
	       MOV.B	 ACC,@ASCII_0C		 ;
	       MOV.B	 @COM_BUF8,ACC		 ;
	       BRA	 COM_REG_X:8		 ;V1.6
CHK_REG_PG:    MOV.B	 @PG_BUF10,ACC		 ;
	       MOV.B	 ACC,@ASCII_1000C	 ;
	       MOV.B	 @PG_BUF11,ACC		 ;
	       MOV.B	 ACC,@ASCII_100C	 ;
	       MOV.B	 @PG_BUF12,ACC		 ;
	       MOV.B	 ACC,@ASCII_10C 	 ;
	       MOV.B	 @PG_BUF13,ACC		 ;
	       MOV.B	 ACC,@ASCII_0C		 ;
	       MOV.B	 @PG_BUF9,ACC		 ;
COM_REG_X:     CMP.B	 #ASCII_X,ACC		 ;;V1.6
	       BNE	 COM_REG_Y:8		 ;;
	       BSR	 ASCII_HEX_ADDR 	 ;;
	       CMP.W	 #D'385,B_W              ;;
	       BCC	 CHK_REG_ERR		 ;;
	       CMP.W	 #0,B_W 		 ;;
	       BEQ	 CHK_REG_ERR		 ;;
	       MOV.W	 #D'16,ACC_W             ;;
	       DIVXS.B	 ACC,B_W		 ;;
	       MOV.B	 #0,B_H 		 ;;
	       MOV.L	 #X_STATE,ER6	       ;;
	       SHLL.W	 B_W			 ;;
	       ADD.W	 B_W,R6 		 ;;
	       MOV.W	 R6,@R6_BUFFER		 ;;
	       BRA	 CHK_REG_OK		 ;;
COM_REG_Y:     CMP.B	 #ASCII_Y,ACC		 ;;
	       BNE	 COM_REG_C:8		 ;;
	       BSR	 ASCII_HEX_ADDR 	 ;;
	       CMP.W	 #D'385,B_W              ;;
	       BCC	 CHK_REG_ERR		 ;;
	       CMP.W	 #0,B_W 		 ;;
	       BEQ	 CHK_REG_ERR		 ;;
	       MOV.W	 #D'16,ACC_W             ;;
	       DIVXS.B	 ACC,B_W		 ;;
	       MOV.B	 #0,B_H 		 ;;
	       MOV.L	 #Y_STATE,ER6	       ;;
	       SHLL.W	 B_W			 ;;
	       ADD.W	 B_W,R6 		 ;;
	       MOV.W	 R6,@R6_BUFFER		 ;;
	       BRA	 CHK_REG_OK		 ;;
COM_REG_C:     CMP.B	 #ASCII_C,ACC		 ;;
	       BNE	 COM_REG_V:8		 ;;
	       BSR	 ASCII_HEX_ADDR 	 ;;
	       CMP.W	 #D'2049,B_W             ;;
	       BCC	 CHK_REG_ERR		 ;;
	       CMP.W	 #0,B_W 		 ;;
	       BEQ	 CHK_REG_ERR		 ;;
	       MOV.W	 #D'16,ACC_W             ;;
	       DIVXS.B	 ACC,B_W		 ;;
	       MOV.B	 #0,B_H 		 ;;
	       MOV.L	 #C_STATE,ER6	       ;;
	       SHLL.W	 B_W			 ;;
	       ADD.W	 B_W,R6 		 ;;
	       MOV.W	 R6,@R6_BUFFER		 ;;
	       BRA	 CHK_REG_OK		 ;;
COM_REG_V:     CMP.B	 #ASCII_V,ACC		 ;
	       BNE	 COM_REG_D:8		 ;
	       BSR	 ASCII_HEX_ADDR 	 ;
	       CMP.W	 #D'1025,B_W             ;
	       BCC	 CHK_REG_ERR		 ;
	       CMP.W	 #D'0,B_W                ;
	       BEQ	 CHK_REG_ERR		 ;
	       MOV.L	 #V_MEMORY_ADDR-2,ER6	 ;
	       SHLL.W	 B_W			 ;
	       ADD.W	 B_W,R6 		 ;
	       MOV.W	 R6,@R6_BUFFER		 ;
	       BRA	 CHK_REG_OK		 ;
COM_REG_D:     CMP.B	 #ASCII_D,ACC		 ;
	       BNE	 COM_REG_W:8		 ;
	       BSR	 ASCII_HEX_ADDR 	 ;
	       CMP.W	 #D'2049,B_W             ;
	       BCC	 CHK_REG_ERR		 ;
	       CMP.W	 #D'0,B_W                ;
	       BEQ	 CHK_REG_ERR		 ;
	       MOV.L	 #D_MEMORY_ADDR-2,ER6	 ;
	       SHLL.W	 B_W			 ;
	       ADD.W	 B_W,R6 		 ;
	       MOV.W	 R6,@R6_BUFFER		 ;
	       BRA	 CHK_REG_OK		 ;
COM_REG_W:     CMP.B	 #ASCII_W,ACC		 ;
	       BNE	 COM_REG_F		 ;
	       BLD	 PG_COM_BIT		 ;
	       BCS	 COM_REG_W1:8		 ;
	       MOV.B	 @COM_BUF9,ACC		 ;
	       BRA	 COM_REG_WC:8		 ;
COM_REG_W1:    MOV.B	 @PG_BUF10,ACC		 ;
COM_REG_WC:    CMP.B	 #ASCII_C,ACC		 ;
	       BNE	 COM_REG_WS:8		 ;
	       MOV.B	 #ASCII_0,ACC		 ;
	       MOV.B	 ACC,@ASCII_1000C	 ;
	       BSR	 ASCII_HEX_ADDR 	 ;
	       CMP.W	 #D'913,B_W              ;
	       BCC	 CHK_REG_ERR		 ;
	       CMP.W	 #D'0,B_W                ;
	       BEQ	 CHK_REG_ERR		 ;
	       MOV.L	 #WC_MEMORY_ADDR-2,ER6	 ;
	       SHLL.W	 B_W			 ;
	       ADD.W	 B_W,R6 		 ;
	       MOV.W	 R6,@R6_BUFFER		 ;
	       BRA	 CHK_REG_OK		 ;
COM_REG_WS:    CMP.B	 #ASCII_S,ACC		 ;
	       BNE	 CHK_REG_ERR		 ;
	       MOV.B	 #ASCII_0,ACC		 ;
	       MOV.B	 ACC,@ASCII_1000C	 ;
	       BSR	 ASCII_HEX_ADDR 	 ;
	       CMP.W	 #D'129,B_W              ;
	       BCC	 CHK_REG_ERR		 ;
	       CMP.W	 #D'0,B_W                ;
	       BEQ	 CHK_REG_ERR		 ;
	       MOV.L	 #WS_MEMORY_ADDR-2,ER6	 ;
	       SHLL.W	 B_W			 ;
	       ADD.W	 B_W,R6 		 ;
	       MOV.W	 R6,@R6_BUFFER		 ;
	       BRA	 CHK_REG_OK		 ;
COM_REG_F:     CMP.B	 #ASCII_F,ACC		 ;;;;TEST
	       BNE	 CHK_REG_ERR		 ;
	       BSR	 ASCII_HEX_ADDR 	 ;
	       CMP.W	 #D'0131,B_W             ;;File0001-File0130
	       BCC	 CHK_REG_ERR		 ;
	       CMP.W	 #D'0,B_W                ;
	       BEQ	 CHK_REG_ERR		 ;
	       DEC.W	 #1,B_W 		 ;
	       CMP.W	 #D'20,B_W               ;
	       BCC	 COM_F_OVER20:8 	 ;
COM_F_UNDER20: SHLL.W	 B_W			 ;
	       MOV.W	 #D'20,R2                ;
	       MULXU.W	 B_W,ER2		 ;
	       MOV.L	 #WC_MEMORY_ADDR+1024,ER6 ;;V1.1 WC513 TO BE FILE1
	       ADD.W	 R2,R6			 ;
	       MOV.W	 R6,@R6_BUFFER		 ;
	       BRA	 CHK_REG_OK		 ;
COM_F_OVER20:  MOV.W	 #D'20,R2                ;
	       SUB.W	 #D'20,B_W               ;;;V1.1/ 1 MAP TO FILE21
	       MULXU.W	 B_W,ER2		 ;
	       MOV.L	 #FILE21_ADDR,ER6	 ;
	       ADD.W	 R2,R6			 ;
	       MOV.W	 R6,@R6_BUFFER		 ;
	       BRA	 CHK_REG_OK		 ;
CHK_REG_ERR:   BSET	 JUDGE_NG		 ;
	       RTS				 ;
CHK_REG_OK:    BCLR	 JUDGE_NG		 ;
	       RTS				 ;
;;RETURN WN:R5_BUFFER				 ;
CHK_WN_NO:     BLD	 PG_COM_BIT		 ;
	       BCS	 CHK_WN_PG		 ;
	       MOV.B	 @COM_BUF13,ACC 	 ;
	       BSR	 ASCII_HEX		 ;
	       BSR	 SWAP_ACC		 ;
	       MOV.B	 ACC,B_REG		 ;
	       MOV.B	 @COM_BUF14,ACC 	 ;
	       BSR	 ASCII_HEX		 ;
	       OR.B	 B_REG,ACC		 ;
	       BRA	 CHK_WN_RANGE:8 	 ;
CHK_WN_PG:     MOV.B	 @PG_BUF14,ACC		 ;
	       BSR	 ASCII_HEX		 ;
	       BSR	 SWAP_ACC		 ;
	       MOV.B	 ACC,B_REG		 ;
	       MOV.B	 @PG_BUF15,ACC		 ;
	       BSR	 ASCII_HEX		 ;
	       OR.B	 B_REG,ACC		 ;
CHK_WN_RANGE:  MOV.B	 ACC,R4L		 ;;
	       JSR	 @BCD_HEX_B		 ;;
	       MOV.B	 R4L,ACC		 ;;
	       CMP.B	 #D'100,ACC              ;
	       BCC	 CHK_WN_ERR:8		 ;
	       CMP.B	 #D'0,ACC                ;
	       BEQ	 WN_100:8		 ;
	       MOV.B	 ACC,@R5_BUFFER 	 ;
	       BRA	 CHK_WN_OK:8		 ;
WN_100:        MOV.B	 #D'100,ACC              ;
	       MOV.B	 ACC,@R5_BUFFER 	 ;
CHK_WN_OK:     BCLR	 JUDGE_NG		 ;
	       RTS				 ;
CHK_WN_ERR:    BSET	 JUDGE_NG		 ;
	       RTS				 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ====	Register current value monitor	======	 ;
MRV_START:     MOV.B	 #D'14,REG_R1            ;Byte number
	       BSR	 COM_FORMAT_CHK 	 ;
	       BLD	 COM_LNK_ERR		 ;
	       BCC	 MRV_GO:8		 ;
	       BRA	 COM_ERR_RET		 ;
MRV_GO:        BSR	 CHK_REG_ADDR		 ;
	       BLD	 JUDGE_NG		 ;
	       BCS	 MRV_ERR		 ;
	       BSR	 CHK_WN_NO		 ;
	       BLD	 JUDGE_NG		 ;
	       BCS	 MRV_ERR		 ;
MRV_READ_OK:   BLD	 PG_COM_BIT		 ;
	       BCS	 MRV_READ_OK1:8 	 ;
	       MOV.L	 #COM_BUF8,BUFF_PTR1	 ;Frame pointer
	       BRA	 MRV_READ_OK2:8 	 ;
MRV_READ_OK1:  MOV.L	 #PG_BUF9,BUFF_PTR1	 ;Frame pointer
MRV_READ_OK2:  MOV.W	 @R6_BUFFER,R6		 ;Register pointer
	       MOV.W	 #H'000F,E6              ;
	       CMP.L	 #FILE21_ADDR,ER6	 ;;VF.2
	       BCS	 MRV_READ_OK3:8 	 ;;
	       BSET	 ESC_EXIST		 ;;FILE21-F130
	       BRA	 MRV_LOOP0:8		 ;;
MRV_READ_OK3:  BCLR	 ESC_EXIST		 ;;
MRV_LOOP0:     MOV.B	 @R5_BUFFER,R3L 	 ;word number
MRV_LOOP1:     BLD	 ESC_EXIST		 ;;
	       BCC	 MRV_LOOP2:8		 ;;
	       MOV.B	 @ER6,B_REG		 ;;
	       MOV.B	 #0,B_H 		 ;;
	       INC.L	 #1,ER6 		 ;;
	       BRA	 MRV_LOOP3:8		 ;;
MRV_LOOP2:     CMP.L	 #M_STATE,ER6		 ;;;V1.6
	       BCC	 MRV_LOOP21:8		 ;;;
	       MOV.B	 @ER6,B_REG		 ;;;
	       INC.L	 #1,ER6 		 ;;;
	       MOV.B	 @ER6,B_H		 ;;;
	       INC.L	 #1,ER6 		 ;;;
	       BRA	 MRV_LOOP3:8		 ;;;
MRV_LOOP21:    MOV.W	 @ER6,B_W		 ;
	       INC.L	 #2,ER6 		 ;
MRV_LOOP3:     MOV.B	 B_H,ACC		 ;
	       BSR	 SWAP_ACC		 ;
	       BSR	 HEX_ASCII		 ;
	       MOV.B	 ACC,ACC_H		 ;
	       MOV.B	 B_H,ACC		 ;
	       BSR	 HEX_ASCII		 ;
	       MOV.B	 ACC_H,@BUFF_PTR1	 ;
	       INC.L	 #1,BUFF_PTR1		 ;
	       MOV.B	 ACC,@BUFF_PTR1 	 ;
	       INC.L	 #1,BUFF_PTR1		 ;
	       MOV.B	 B_REG,ACC		 ;
	       BSR	 SWAP_ACC		 ;
	       BSR	 HEX_ASCII		 ;
	       MOV.B	 ACC,ACC_H		 ;
	       MOV.B	 B_REG,ACC		 ;
	       BSR	 HEX_ASCII		 ;
	       MOV.B	 ACC_H,@BUFF_PTR1	 ;
	       INC.L	 #1,BUFF_PTR1		 ;
	       MOV.B	 ACC,@BUFF_PTR1 	 ;
	       INC.L	 #1,BUFF_PTR1		 ;
	       DEC.B	 R3L			 ;
	       BNE	 MRV_LOOP1:8		 ;
MRV_RBP_END:   MOV.B	 #ASCII_23H,ACC 	 ;
	       BLD	 PG_COM_BIT		 ;
	       BCS	 MRV_LOOP11:8		 ;
	       MOV.B	 ACC,@COM_BUF3		 ;
	       MOV.L	 #COM_BUF1,DPTR 	 ;BUFF_PTR1:END_ADDRESS
	       BRA	 MRV_LOOP12:8		 ;
MRV_LOOP11:    MOV.B	 ACC,@PG_BUF4		 ;
	       MOV.L	 #PG_BUF2,DPTR		 ;BUFF_PTR1:END_ADDRESS
MRV_LOOP12:    MOV.B	 #H'00,B_REG             ;
MRV_SUM_LOOP:  MOV.B	 @DPTR,ACC		 ;
	       ADD.B	 ACC,B_REG		 ;
	       INC.L	 #1,DPTR		 ;
	       CMP.L	 BUFF_PTR1,DPTR 	 ;
	       BNE	 MRV_SUM_LOOP:8 	 ;
	       NOT.B	 B_REG			 ;
	       ADD.B	 #1,B_REG		 ;
	       MOV.B	 B_REG,ACC		 ;
	       BSR	 SWAP_ACC		 ;
	       BSR	 HEX_ASCII		 ;
	       MOV.B	 ACC,@BUFF_PTR1 	 ;
	       INC.L	 #1,BUFF_PTR1		 ;
	       MOV.B	 B_REG,ACC		 ;
	       BSR	 HEX_ASCII		 ;
	       MOV.B	 ACC,@BUFF_PTR1 	 ;
	       INC.L	 #1,BUFF_PTR1		 ;
	       MOV.B	 #ASCII_CR,ACC		 ;
	       MOV.B	 ACC,@BUFF_PTR1 	 ;
	       BRA	 COM_RET_END		 ;						   ;
MRV_ERR:       MOV.B	 #ASCII_0,REG_R1	 ;
	       MOV.B	 #ASCII_1,REG_R2	 ;
	       BRA	 COM_ERR_RET		 ;
; =============  PC status read      ============;
PSR_START:     MOV.B	 #D'07,REG_R1            ;Byte number
	       BSR	 COM_FORMAT_CHK 	 ;
	       BLD	 COM_LNK_ERR		 ;
	       BCC	 PSR_GO:8		 ;
	       BRA	 COM_ERR_RET		 ;
PSR_GO:        BLD	 RUN_FLAG		 ;
	       BCC	 PSR_STOP_MODE:8	 ;
	       BLD	 FAULT_FLAG		 ;
	       BCS	 PSR_ERR_MODE
	       BLD	 RUN_FLAG_1		 ;
	       BCC	 PSR_RUN_MODE:8 	 ;
PSR_STOP_MODE: MOV.B	 #ASCII_0,ACC		 ;
	       BLD	 PG_COM_BIT		 ;
	       BCS	 PSR_STOP_M1:8		 ;
	       MOV.B	 ACC,@COM_BUF8		 ;
	       BRA	 PSR_RET		 ;
PSR_STOP_M1:   MOV.B	 ACC,@PG_BUF9		 ;
	       BRA	 PSR_RET		 ;
PSR_ERR_MODE:  MOV.B	 #ASCII_2,ACC		 ;
	       BLD	 PG_COM_BIT		 ;
	       BCS	 PSR_ERR_M1:8		 ;
	       MOV.B	 ACC,@COM_BUF8		 ;
	       BRA	 PSR_RET		 ;
PSR_ERR_M1:    MOV.B	 ACC,@PG_BUF9		 ;
	       BRA	 PSR_RET		 ;
PSR_RUN_MODE:  MOV.B	 #ASCII_1,ACC		 ;
	       BLD	 PG_COM_BIT		 ;
	       BCS	 PSR_RUN_MODE1:8	 ;
	       MOV.B	 ACC,@COM_BUF8		 ;
	       BRA	 PSR_RET:8		 ;
PSR_RUN_MODE1: MOV.B	 ACC,@PG_BUF9		 ;
PSR_RET:       MOV.B	 #ASCII_23H,ACC 	 ;
	       BLD	 PG_COM_BIT		 ;
	       BCS	 PSR_RET_1:8		 ;
	       MOV.B	 ACC,@COM_BUF3		 ;
	       BRA	 PSR_RET_2:8		 ;
PSR_RET_1:     MOV.B	 ACC,@PG_BUF4		 ;
PSR_RET_2:     MOV.W	 #H'0008,DATA1_W         ;
	       BRA	 COM_LNK_RET		 ;
;;;
;;;INPUT NONE, OUTPUT ADDRESS:R6_BUFFER 	 ;
CHK_RBP_ADDR:  BLD	 PG_COM_BIT		 ;
	       BCS	 CHK_RBP_PG:8		 ;
	       MOV.B	 @COM_BUF8,ACC		 ;
	       MOV.B	 ACC,@ASCII_1000C	 ;
	       MOV.B	 @COM_BUF9,ACC		 ;
	       MOV.B	 ACC,@ASCII_100C	 ;
	       MOV.B	 @COM_BUF10,ACC 	 ;
	       MOV.B	 ACC,@ASCII_10C 	 ;
	       MOV.B	 @COM_BUF11,ACC 	 ;
	       MOV.B	 ACC,@ASCII_0C		 ;
	       BRA	 CHK_RBP_RANGE:8	 ;
CHK_RBP_PG:    MOV.B	 @PG_BUF9,ACC		 ;
	       MOV.B	 ACC,@ASCII_1000C	 ;
	       MOV.B	 @PG_BUF10,ACC		 ;
	       MOV.B	 ACC,@ASCII_100C	 ;
	       MOV.B	 @PG_BUF11,ACC		 ;
	       MOV.B	 ACC,@ASCII_10C 	 ;
	       MOV.B	 @PG_BUF12,ACC		 ;
	       MOV.B	 ACC,@ASCII_0C		 ;
CHK_RBP_RANGE: BSR	 ASCII_HEX_ADDR 	 ;
	       MOV.W	 B_W,@R5_BUFFER 	 ;
	       BLD	 PRG_4K_MODE		 ;
	       BCC	 CHK_RBP_20MR:8 	 ;
	       CMP.W	 #D'4001,B_W             ;
	       BCC	 CHK_RBP_ERR		 ;
	       BRA	 CHK_RBP_SNO:8		 ;
CHK_RBP_20MR:  CMP.W	 #D'1501,B_W             ;
	       BCC	 CHK_RBP_ERR		 ;
CHK_RBP_SNO:   BLD	 PG_COM_BIT		 ;
	       BCS	 CHK_RBP_SNO1:8 	 ;
	       MOV.B	 @COM_BUF12,ACC 	 ;
	       BSR	 ASCII_HEX		 ;
	       BSR	 SWAP_ACC		 ;
	       MOV.B	 ACC,ACC_H		 ;
	       MOV.B	 @COM_BUF13,ACC 	 ;
	       BSR	 ASCII_HEX		 ;
	       OR.B	 ACC_H,ACC		 ;
	       BRA	 CHK_RBP_SNO2:8 	 ;
CHK_RBP_SNO1:  MOV.B	 @PG_BUF13,ACC		 ;
	       BSR	 ASCII_HEX		 ;
	       BSR	 SWAP_ACC		 ;
	       MOV.B	 ACC,ACC_H		 ;
	       MOV.B	 @PG_BUF14,ACC		 ;
	       BSR	 ASCII_HEX		 ;
	       OR.B	 ACC_H,ACC		 ;
CHK_RBP_SNO2:  MOV.B	 ACC,R4L		 ;;
	       JSR	 @BCD_HEX_B		 ;;
	       MOV.B	 R4L,ACC		 ;;
	       CMP.B	 #0,ACC 		 ;
	       BEQ	 RBP_SNO_0:8		 ;
	       CMP.B	 #D'100,ACC              ;
	       BCC	 CHK_RBP_ERR:8		 ;
	       BRA	 RBP_SNO_1_99:8 	 ;
RBP_SNO_0:     MOV.B	 #D'100,ACC              ;
RBP_SNO_1_99:  MOV.B	 ACC,@R4_BUFFER 	 ;STEP NO
	       BSR	 RELOAD_PRG_SPTR	 ;
	       MOV.W	 R6,@R6_BUFFER		 ;S  PTR
	       MOV.W	 R5,@R2_BUFFER		 ;NU PTR
	       BSR	 RELOAD_PRG_EPTR	 ;
	       MOV.W	 R6,@R3_BUFFER		 ;E PTR
	       MOV.W	 @R5_BUFFER,R5		 ;READ START ADDRESS 1
	       MOV.W	 @R2_BUFFER,R2		 ;
	       ADD.W	 R5,R2			 ;
	       MOV.W	 R2,@R2_BUFFER		 ;NU PTR
	       SHLL.W	 R5			 ;
	       MOV.W	 @R6_BUFFER,R6		 ;
	       ADD.W	 R5,R6			 ;
	       MOV.W	 R6,@R6_BUFFER		 ;REAL START ADDRESS 2
	       MOV.B	 @R4_BUFFER,ACC 	 ;
	       MOV.B	 #0,ACC_H		 ;
	       DEC.B	 ACC			 ;
	       SHLL.W	 ACC_W			 ;
	       ADD.W	 ACC_W,R6		 ;
	       MOV.W	 @R3_BUFFER,R3		 ;
	       CMP.W	 R3,R6			 ;
	       BCC	 CHK_RBP_ERR		 ;
CHK_RBP_OK:    BCLR	 JUDGE_NG		 ;
	       RTS				 ;
CHK_RBP_ERR:   BSET	 JUDGE_NG		 ;
	       RTS				 ;
;;;;
CODE_INST:     ROTL.B	 ACC
	       ROTL.B	 ACC
	       ROTL.B	 ACC
	       NOT.B	 ACC
	       RTS
DECODE_INST:   NOT.B	 ACC
	       ROTR.B	 ACC
	       ROTR.B	 ACC
	       ROTR.B	 ACC
	       RTS
; ========    Read boolean program   =========== ;
RBP_START:     BLD	 COM_SECRET		 ;;VF.2
	       BCS	 PASS_ERR		 ;;
	       MOV.B	 #D'13,REG_R1            ;Byte number
	       BSR	 COM_FORMAT_CHK 	 ;
	       BLD	 COM_LNK_ERR		 ;
	       BCC	 RBP_GO:8		 ;
	       BRA	 COM_ERR_RET		 ;
RBP_GO:        BSR	 CHK_RBP_ADDR		 ;R6_BUFFER : INST
	       BLD	 JUDGE_NG		 ;R2_BUFFER : NU
	       BCS	 MRV_ERR		 ;
RBP_GOGO:      BLD	 PG_COM_BIT		 ;
	       BCS	 RBP_GOGO_1:8		 ;
	       MOV.L	 #COM_BUF8,BUFF_PTR1	 ;Frame pointer
	       BRA	 RBP_GOGO_2:8		 ;
RBP_GOGO_1:    MOV.L	 #PG_BUF9,BUFF_PTR1	 ;
RBP_GOGO_2:    MOV.W	 @R6_BUFFER,R6		 ;ER6:DPTR(INST)
	       MOV.W	 #H'000F,E6              ;
	       MOV.W	 @R2_BUFFER,R4		 ;ER4:BUFF_PTR2
	       MOV.W	 #H'000F,E4              ;
RBP_LOOP1:     MOV.B	 @DPTR,ACC		 ;INST
	       BSR	 CODE_INST		 ;;SECRET
	       MOV.B	 ACC,REG_R1		 ;
	       BSR	 SWAP_ACC		 ;
	       BSR	 HEX_ASCII		 ;
	       MOV.B	 ACC,ACC_H		 ;Hi byte(high nibble)
	       MOV.B	 REG_R1,ACC		 ;
	       BSR	 HEX_ASCII		 ;Hi byte(low nibble)
	       MOV.W	 ACC_W,DATA2_W		 ;High byte
	       INC.L	 #1,DPTR		 ;
	       MOV.B	 @DPTR,ACC		 ;
	       BSR	 CODE_INST		 ;;SECRET
	       MOV.B	 ACC,REG_R1		 ;
	       BSR	 SWAP_ACC		 ;
	       BSR	 HEX_ASCII		 ;
	       MOV.B	 ACC,ACC_H		 ;Low byte(high nibble)
	       MOV.B	 REG_R1,ACC		 ;
	       BSR	 HEX_ASCII		 ;Low byte(low nibble)
	       MOV.W	 ACC_W,DATA1_W		 ;Low byte
	       INC.L	 #1,DPTR		 ;
	       MOV.B	 @BUFF_PTR2,ACC 	 ;NU
	       MOV.B	 ACC,REG_R1		 ;
	       BSR	 SWAP_ACC		 ;
	       BSR	 HEX_ASCII		 ;
	       MOV.B	 ACC,ACC_H		 ;Hi byte(high nibble)
	       MOV.B	 REG_R1,ACC		 ;
	       BSR	 HEX_ASCII		 ;Hi byte(low nibble)
	       MOV.W	 ACC_W,DATA3_W		 ;NU
	       INC.L	 #1,BUFF_PTR2		 ;
	       MOV.W	 DATA2_W,ACC_W		 ;
	       MOV.B	 ACC_H,@BUFF_PTR1	 ;;
	       INC.L	 #1,BUFF_PTR1		 ;;
	       MOV.B	 ACC,@BUFF_PTR1 	 ;;
	       INC.L	 #1,BUFF_PTR1		 ;;
	       MOV.W	 DATA1_W,ACC_W		 ;;
	       MOV.B	 ACC_H,@BUFF_PTR1	 ;;
	       INC.L	 #1,BUFF_PTR1		 ;;
	       MOV.B	 ACC,@BUFF_PTR1 	 ;;
	       INC.L	 #1,BUFF_PTR1		 ;;
	       MOV.W	 DATA3_W,ACC_W		 ;;
	       MOV.B	 ACC_H,@BUFF_PTR1	 ;;
	       INC.L	 #1,BUFF_PTR1		 ;;
	       MOV.B	 ACC,@BUFF_PTR1 	 ;;
	       INC.L	 #1,BUFF_PTR1		 ;;
	       MOV.B	 @R4_BUFFER,ACC 	 ;;
	       DEC.B	 ACC			 ;;
	       MOV.B	 ACC,@R4_BUFFER 	 ;;
	       BNE	 RBP_LOOP1		 ;;
	       BRA	 MRV_RBP_END		 ;;
; ========    PC operation RUN	    ============ ;
RUN_START:     BLD	 REMOTE_MODE		 ;
	       BCC	 RUN_START1:8		 ;
	       BLD	 MASTER_MODE		 ;
	       BCS	 RUN_START1:8		 ;
	       BRA	 P_W_P			 ;
RUN_START1:    MOV.B	 #D'7,REG_R1             ;
	       BSR	 COM_FORMAT_CHK 	 ;
	       BLD	 COM_LNK_ERR		 ;
	       BCC	 RUN_GO:8		 ;
	       BRA	 COM_ERR_RET		 ;
RUN_GO:     ;; MOV.B	 #H'00,ACC               ;V1.1
	    ;; MOV.B	 ACC,@SYS_100_ADDR	 ;V1.1
	       BLD	 RUN_FLAG		 ;
	       BCC	 HALT_TO_RUN:8		 ;
	       BLD	 RUN_FLAG_1		 ;
	       BCS	 HALT_TO_RUN:8		 ;
	       BRA	 RUN_OK_RET:8		 ;
HALT_TO_RUN:   BSET	 REQ_RUN_FG		 ;
RUN_OK_RET:    MOV.B	 #ASCII_23H,ACC 	 ;
	       BLD	 PG_COM_BIT		 ;
	       BCS	 RUN_OK_RET1:8		 ;
	       MOV.B	 ACC,@COM_BUF3		 ;
	       BRA	 RUN_OK_RET2:8		 ;
RUN_OK_RET1:   MOV.B	 ACC,@PG_BUF4		 ;
RUN_OK_RET2:   MOV.W	 #H'0007,DATA1_W         ;checksum number
	       BRA	 COM_LNK_RET		 ;
; ========    PC operation STOP    ============= ;
STP_START:     BLD	 REMOTE_MODE		 ;
	       BCC	 HLT_START1:8		 ;
	       BLD	 MASTER_MODE		 ;
	       BCS	 HLT_START1:8		 ;
	       BRA	 P_W_P			 ;
HLT_START1:    MOV.B	 #D'7,REG_R1             ; @SET_MODE FOR PG ????
	       BSR	 COM_FORMAT_CHK 	 ;
	       BLD	 COM_LNK_ERR		 ;
	       BCC	 HLT_GO 		 ;
	       BRA	 COM_ERR_RET		 ;
HLT_GO:     ;; MOV.B	 #H'03,ACC               ;;V1.1
	    ;; MOV.B	 ACC,@SYS_100_ADDR	 ;;
	       BCLR	 RUN_FLAG		 ;
	       BSET	 RUN_FLAG_1		 ;
	    ;; MOV.B	 #ASCII_3,ACC		 ;V0.4
	    ;; MOV.B	 ACC,@SET_MODE		 ;V0.4
	       BRA	 RUN_OK_RET		 ;

; ========= Write boolean program  ============= ;
WBP_START:     BLD	 RUN_FLAG		 ;
	       BCC	 WBP_GO:8		 ;
WBP_ERR1:      MOV.B	 #ASCII_0,REG_R1	 ;Program write inhibited
	       MOV.B	 #ASCII_2,REG_R2	 ;
	       BRA	 COM_ERR_RET		 ;
WBP_GO:        BSR	 CHK_RBP_ADDR		 ;R6_BUFFER : INST
	       BLD	 JUDGE_NG		 ;R2_BUFFER : NU
	       BCS	 MRV_ERR		 ;
WBP_GOGO:      BLD	 PG_COM_BIT		 ;
	       BCS	 WBP_GOGO_1:8		 ;
	       MOV.L	 #COM_BUF14,BUFF_PTR1	 ;A.WRITE IN Frame pointer
	       BRA	 WBP_GOGO_2:8		 ;
WBP_GOGO_1:    MOV.L	 #PG_BUF15,BUFF_PTR1	 ;
WBP_GOGO_2:    MOV.W	 @R6_BUFFER,R6		 ;B.ER6:DPTR(INST)
	       MOV.W	 #H'000F,E6              ;
	       MOV.W	 @R2_BUFFER,R4		 ;C.ER4:BUFF_PTR2(NU)
	       MOV.W	 #H'000F,E4              ;
WBP_LOOP1:     MOV.B	 @BUFF_PTR1,ACC 	 ;INST HIGH
	       INC.L	 #1,BUFF_PTR1		 ;
	       BSR	 ASCII_HEX		 ;
	       BSR	 SWAP_ACC		 ;
	       MOV.B	 ACC,ACC_H		 ;Hi byte(high nibble)
	       MOV.B	 @BUFF_PTR1,ACC 	 ;
	       INC.L	 #1,BUFF_PTR1		 ;
	       BSR	 ASCII_HEX		 ;Hi byte(low nibble)
	       OR.B	 ACC_H,ACC		 ;HIGH BYTE
	       BSR	 DECODE_INST		 ;;SECRET
	       MOV.B	 ACC,B_REG		 ;
	       MOV.B	 @BUFF_PTR1,ACC 	 ;INST LOW
	       INC.L	 #1,BUFF_PTR1		 ;
	       BSR	 ASCII_HEX		 ;
	       BSR	 SWAP_ACC		 ;
	       MOV.B	 ACC,ACC_H		 ;Lo byte(high nibble)
	       MOV.B	 @BUFF_PTR1,ACC 	 ;
	       INC.L	 #1,BUFF_PTR1		 ;
	       BSR	 ASCII_HEX		 ;Lo byte(low nibble)
	       OR.B	 ACC_H,ACC		 ;LOW BYTE
	       BSR	 DECODE_INST		 ;;SECRET
	       MOV.B	 B_REG,ACC_H		 ;ACC_W
	       MOV.W	 ACC_W,DATA1_W		 ;==INST CODE==
	       MOV.B	 @BUFF_PTR1,ACC 	 ;NU
	       INC.L	 #1,BUFF_PTR1		 ;
	       BSR	 ASCII_HEX		 ;
	       BSR	 SWAP_ACC		 ;
	       MOV.B	 ACC,ACC_H		 ;(high nibble)
	       MOV.B	 @BUFF_PTR1,ACC 	 ;
	       INC.L	 #1,BUFF_PTR1		 ;
	       BSR	 ASCII_HEX		 ;(low nibble)
	       OR.B	 ACC_H,ACC		 ;==NU CODE==
	       MOV.W	 DATA1_W,@DPTR		 ;
	       INC.L	 #2,DPTR		 ;
	       MOV.B	 ACC,@BUFF_PTR2 	 ;
	       INC.L	 #1,BUFF_PTR2		 ;
	       MOV.B	 @R4_BUFFER,ACC 	 ;;
	       DEC.B	 ACC			 ;;
	       MOV.B	 ACC,@R4_BUFFER 	 ;;
	       BNE	 WBP_LOOP1		 ;;
	       BRA	 RUN_OK_RET		 ;;
;------------------------------------------------;
; DATE WRITE COMMON SUBROUTINE			 ;
;------------------------------------------------;
DATE_R_S:      MOV.B	 ACC,REG_R1		 ;
	       BSR	 SWAP_ACC		 ;
	       BSR	 HEX_ASCII		 ;
	       BLD	 PG_COM_BIT		 ;
	       BCC	 PG_T_W:8		 ;
	       SUB.L	 #H'440,DPTR             ;
PG_T_W:        MOV.B	 ACC,@DPTR		 ;
	       INC.L	 #1,DPTR		 ;
	       MOV.B	 REG_R1,ACC		 ;
	       BSR	 HEX_ASCII		 ;
	       MOV.B	 ACC,@DPTR		 ;
	       RTS				 ;
;------------------------------------------------;
; DATE WRITE COMMON SUBROUTINE	R:B_REG 	 ;
;------------------------------------------------;
DATE_W_S:      BLD	 PG_COM_BIT		 ;
	       BCC	 DATE_W_S_1:8		 ;
	       SUB.L	 #H'440,DPTR             ;
DATE_W_S_1:    MOV.B	 @DPTR,ACC		 ;
	       INC.L	 #1,DPTR		 ;
	       BSR	 ASCII_HEX		 ;
	       BSR	 SWAP_ACC		 ;
	       MOV.B	 ACC,B_REG		 ; HIGH BYTE
	       MOV.B	 @DPTR,ACC		 ;
	       BSR	 ASCII_HEX		 ; LOW BYTE
	       OR.B	 ACC,B_REG		 ;
	       RTS

; ==========	Time data read	   ============= ;
RTC_START:     BLD	 BROADCAST_BIT		 ;;
	       BCS	 RTC_END		 ;;
	       MOV.B	 #D'8,REG_R1             ;
	       BSR	 COM_FORMAT_CHK 	 ;
	       BLD	 COM_LNK_ERR		 ;
	       BCC	 RTC_GO:8		 ;
	       BRA	 COM_ERR_RET		 ;
RTC_GO:        BLD	 PG_COM_BIT		 ;
	       BCS	 RTC_GO1:8		 ;
	       MOV.B	 @COM_BUF8,ACC		 ;
	       BRA	 RTC_GO2:8		 ;
RTC_GO1:       MOV.B	 @PG_BUF9,ACC		 ;
RTC_GO2:       CMP.B	 #ASCII_0,ACC		 ;
	       BNE	 RTC_GO3:8		 ;
	       MOV.L	 #SC057_ADDR,DPTR	 ;
	       BSET	 #4,@DPTR		 ;
	       BRA	 RTC_END:8		 ;
RTC_GO3:       CMP.B	 #ASCII_1,ACC		 ;
	       BNE	 RTC_GO4:8		 ;
	       MOV.L	 #SC057_ADDR,DPTR	 ;
	       BCLR	 #4,@DPTR		 ;
	       BRA	 RTC_END:8		 ;
RTC_GO4:       CMP.B	 #ASCII_2,ACC		 ;
	       BNE	 RTC_GO5:8		 ;
	       MOV.L	 #SC057_ADDR,DPTR	 ;
	       BSET	 #5,@DPTR		 ;
	       BRA	 RTC_END:8		 ;
RTC_GO5:       CMP.B	 #ASCII_3,ACC		 ;
	       BNE	 RTC_END:8		 ;
	       MOV.L	 #SC057_ADDR,DPTR	 ;
	       BSET	 #6,@DPTR		 ;
RTC_END:       MOV.B	 #ASCII_23H,ACC 	 ;
	       BLD	 PG_COM_BIT		 ;
	       BCS	 RTC_GO_1:8		 ;
	       MOV.B	 ACC,@COM_BUF3		 ;
	       BRA	 RTC_GO_2:8		 ;
RTC_GO_1:      MOV.B	 ACC,@PG_BUF4		 ;
RTC_GO_2:      MOV.W	 #H'0007,DATA1_W         ;V0.4
	       BRA	 COM_LNK_RET		 ;
; ======					 ;
WRV_START:  ;; MOV.B	 #D'14,REG_R1            ;Byte number
	    ;  BSR	 COM_FORMAT_CHK 	 ;
	    ;  BLD	 COM_LNK_ERR		 ;
	    ;  BCC	 MRV_GO:8		 ;
	    ;  BRA	 COM_ERR_RET		 ;
WRV_GO:        BSR	 CHK_REG_ADDR		 ;
	       BLD	 JUDGE_NG		 ;
	       BCS	 MRV_ERR		 ;OK
	       BSR	 CHK_WN_NO		 ;
	       BLD	 JUDGE_NG		 ;
	       BCS	 MRV_ERR		 ;
WRV_WR_OK:     BLD	 PG_COM_BIT		 ;
	       BCS	 WRV_WR_OK1:8		 ;
	       MOV.L	 #COM_BUF15,BUFF_PTR1	 ;Frame pointer
	       BRA	 WRV_WR_OK2:8		 ;
WRV_WR_OK1:    MOV.L	 #PG_BUF16,BUFF_PTR1	 ;Frame pointer
WRV_WR_OK2:    MOV.W	 @R6_BUFFER,R6		 ;Register pointer
	       MOV.W	 #H'000F,E6              ;
	       CMP.L	 #FILE21_ADDR,ER6	 ;;VF.2
	       BCS	 WRV_WR_OK3:8		 ;;
	       BSET	 ESC_EXIST		 ;;
	       BRA	 WRV_WR_OK4:8		 ;;
WRV_WR_OK3:    BCLR	 ESC_EXIST		 ;;
WRV_WR_OK4:    MOV.B	 @R5_BUFFER,R4L 	 ;word number
WRV_LOOP1:     MOV.B	 @BUFF_PTR1,ACC 	 ;REG HIGH
	       INC.L	 #1,BUFF_PTR1		 ;
	       BSR	 ASCII_HEX		 ;
	       BSR	 SWAP_ACC		 ;
	       MOV.B	 ACC,ACC_H		 ;Hi byte(high nibble)
	       MOV.B	 @BUFF_PTR1,ACC 	 ;
	       INC.L	 #1,BUFF_PTR1		 ;
	       BSR	 ASCII_HEX		 ;Hi byte(low nibble)
	       OR.B	 ACC_H,ACC		 ;HIGH BYTE
	       MOV.B	 ACC,B_REG		 ;
	       MOV.B	 @BUFF_PTR1,ACC 	 ;REG LOW
	       INC.L	 #1,BUFF_PTR1		 ;
	       BSR	 ASCII_HEX		 ;
	       BSR	 SWAP_ACC		 ;
	       MOV.B	 ACC,ACC_H		 ;Lo byte(high nibble)
	       MOV.B	 @BUFF_PTR1,ACC 	 ;
	       INC.L	 #1,BUFF_PTR1		 ;
	       BSR	 ASCII_HEX		 ;Lo byte(low nibble)
	       OR.B	 ACC_H,ACC		 ;LOW BYTE
	       MOV.B	 B_REG,ACC_H		 ;ACC_W
	       BLD	 ESC_EXIST		 ;;VF.2
	       BCS	 WRV_LOOP2:8		 ;;
WRV_LOOP20:    CMP.L	 #M_STATE,ER6		 ;;;V1.6
	       BCC	 WRV_LOOP201:8		 ;;;
	       MOV.B	 ACC,@ER6		 ;;;
	       INC.L	 #1,ER6 		 ;;;
	       MOV.B	 ACC_H,@ER6		 ;;;
	       INC.L	 #1,ER6 		 ;;;
	       BRA	 WRV_LOOP202:8		 ;;;
WRV_LOOP201:   MOV.W	 ACC_W,@ER6		 ;==INST CODE==
	       INC.L	 #2,ER6 		 ;
WRV_LOOP202:   DEC.B	 R4L			 ;
	       BNE	 WRV_LOOP1:8		 ;
	       BRA	 RUN_OK_RET		 ;
WRV_LOOP2:     MOV.B	 ACC,@ER6		 ;;VF.2
	       INC.L	 #1,ER6 		 ;;
	       DEC.B	 R4L			 ;;
	       BNE	 WRV_LOOP1:8		 ;;
	       BRA	 RUN_OK_RET		 ;;
;;;;						 ;;
ROM_START:     BLD	 BROADCAST_BIT		 ;;VF.2
	       BCS	 RUN_OK_RET		 ;;
	       BLD	 RUN_FLAG		 ;;VF.2
	       BCC	 ROM_START_1:8		 ;;
ROM_ERR:       MOV.B	 #ASCII_0,REG_R1	 ;Can not read write EEPROM
	       MOV.B	 #ASCII_5,REG_R2	 ;
	       BRA	 COM_ERR_RET		 ;
ROM_START_1:   MOV.B	 #D'8,REG_R1             ;Byte number
	       BSR	 COM_FORMAT_CHK 	 ;
	       BLD	 COM_LNK_ERR		 ;
	       BCC	 ROM_GO:8		 ;
	       BRA	 COM_ERR_RET		 ;
ROM_GO:        BLD	 PG_COM_BIT		 ;
	       BCS	 ROM_GO1:8		 ;
	       MOV.B	 @COM_BUF8,ACC		 ;
	       BRA	 ROM_GO2:8		 ;
ROM_GO1:       MOV.B	 @PG_BUF9,ACC		 ;
ROM_GO2:       CMP.B	 #ASCII_0,ACC		 ;
	       BEQ	 ROM_RAM_ROM		 ;
	       CMP.B	 #ASCII_1,ACC		 ;
	       BEQ	 ROM_ROM_RAM		 ;
	       MOV.B	 #ASCII_0,REG_R1	 ;FRAME ERROR
	       MOV.B	 #ASCII_1,REG_R2	 ;
	       BRA	 COM_ERR_RET		 ;
;= Load memory from PACK =;			 ;
ROM_ROM_RAM:   BSET	 RUN_LED		 ;
	       MOV.B	 @LED_DRIVER,ACC	 ;
	       MOV.B	 ACC,@H'000C0000         ;
	       MOV.B	 @EE_EXIST_ADDR,ACC	 ;
	       MOV.B	 ACC,@H'000A0000         ;
	       CMP.B	 #H'37,ACC               ;
	       BNE	 ROM_ERR		 ;
	       MOV.B	 #H'00,ACC               ;
	       MOV.B	 @EE_EXIST_ADDR+1,ACC	 ;
	       MOV.B	 ACC,B_REG		 ;
	       CMP.B	 #H'C8,ACC               ;
	       BNE	 ROM_ERR		 ;
	       JSR	 @EEPROM_CHECKSUM	 ;
	       BLD	 JUDGE_NG		 ;
	       BCS	 ROM_ERR		 ;
	       JSR	 @LOAD_EEPROM		 ;
	       JSR	 @DUMP_FLASH		 ;
	       BRA	 RUN_OK_RET		 ;
; =  Dump memory to PACK  = ;			 ;
ROM_RAM_ROM:   BSET	 RUN_LED		 ;
	       MOV.B	 @LED_DRIVER,ACC	 ;
	       MOV.B	 ACC,@H'000C0000         ;
	       MOV.B	 #H'55,ACC               ;
	       MOV.B	 ACC,@H'00082EFF         ;
	       JSR	 @DELAY_10MS		 ;
	       JSR	 @DELAY_10MS		 ;
	       MOV.B	 #H'00,ACC               ;
	       MOV.B	 @H'00082EFF,ACC         ;
	       CMP.B	 #H'55,ACC               ;
	       BNE	 ROM_ERR		 ;
	       JSR	 @DUMP_EEPROM		 ;
	       BRA	 RUN_OK_RET		 ;
;;						 ;
CLR_START:     BLD	 RUN_FLAG		 ;
	       BCC	 CLR_GO:8		 ;
CLR_ERR:       MOV.B	 #ASCII_0,REG_R1	 ;Program write inhibited
	       MOV.B	 #ASCII_2,REG_R2	 ;
	       BRA	 COM_ERR_RET		 ;
CLR_GO:        MOV.B	 #D'7,REG_R1             ;Byte number
	       BSR	 COM_FORMAT_CHK 	 ;
	       BLD	 COM_LNK_ERR		 ;
	       BCC	 CLR_GO1:8		 ;
	       BRA	 COM_ERR_RET		 ;
CLR_GO1:       BSR	 CLEAR_PROGRAM		 ;R6_BUFFER : INST
	       BSR	 CLR_USED_TABLE 	 ;
	   ;;;;BSR	 INIT_SYS_MEMORY	 ;
	       BSR	 CLEAR_DATA_MEM 	 ;
	       BCLR	 SECRET_BIT		 ;
	       BCLR	 OVER_PASSWORD		 ;
	       BCLR	 COM_SECRET		 ;;VF.2
	       BRA	 RUN_OK_RET		 ;
; ======  Secret cancel, password set	======	 ;
PAS_START:     BLD	 BROADCAST_BIT		 ;;VF.2
	       BCS	 PASS_OK		 ;;
	       MOV.B	 #D'16,REG_R1            ;
	       BSR	 COM_FORMAT_CHK 	 ;
	       BLD	 COM_LNK_ERR		 ;
	       BCC	 PAS_GO:8		 ;
	       BRA	 COM_ERR_RET		 ;
PAS_GO:        BLD	 PG_COM_BIT		 ;
	       BCS	 PG_PAS_GO:8		 ;
	       MOV.B	 @COM_BUF8,ACC		 ;
	       MOV.B	 ACC,@R6L_BUFFER	 ;CON
	       MOV.L	 #COM_BUF9,DPTR 	 ;
	       BRA	 PG_PAS_GO1:8		 ;
PG_PAS_GO:     MOV.B	 @PG_BUF9,ACC		 ;
	       MOV.B	 ACC,@R6L_BUFFER	 ;CON
	       MOV.L	 #PG_BUF10,DPTR 	 ;;
PG_PAS_GO1:    MOV.B	 @DPTR+,ACC		 ;;VF.2
	       MOV.B	 ACC,@ASCII_1000C	 ;;
	       MOV.B	 @DPTR+,ACC		 ;;VF.2
	       MOV.B	 ACC,@ASCII_100C	 ;;
	       MOV.B	 @DPTR+,ACC		 ;;VF.2
	       MOV.B	 ACC,@ASCII_10C 	 ;;
	       MOV.B	 @DPTR+,ACC		 ;;VF.2
	       MOV.B	 ACC,@ASCII_0C		 ;;
	       BSR	 ASCII_HEX_ADDR 	 ;
	       MOV.W	 B_W,@R3_DATA		 ;
	       MOV.B	 @DPTR+,ACC		 ;;VF.2
	       MOV.B	 ACC,@ASCII_1000C	 ;;
	       MOV.B	 @DPTR+,ACC		 ;;VF.2
	       MOV.B	 ACC,@ASCII_100C	 ;;
	       MOV.B	 @DPTR+,ACC		 ;;VF.2
	       MOV.B	 ACC,@ASCII_10C 	 ;;
	       MOV.B	 @DPTR+,ACC		 ;;VF.2
	       MOV.B	 ACC,@ASCII_0C		 ;;
	       BSR	 ASCII_HEX_ADDR 	 ;
	       MOV.W	 B_W,@R3_DATA+2 	 ;
PASS_VERIFY:   MOV.B	 @R6L_BUFFER,ACC	 ;
	       CMP.B	 #ASCII_T,ACC		 ;
	       BNE	 PAS_1:8		 ;
	       BLD	 OVER_PASSWORD		 ;
	       BCS	 PASS_ERR		 ;
	       MOV.W	 @WS039_ADDR,E0 	 ;
	       MOV.W	 @WS040_ADDR,R0 	 ;
	       MOV.W	 @R3_DATA,E1		 ;
	       MOV.W	 @R3_DATA+2,R1		 ;
	       CMP.L	 ER0,ER1		 ;
	       BNE	 PASS_NG0:8		 ;
	       BCLR	 COM_SECRET		 ;COMPUTER LINK'S SECRET BIT
	       BRA	 PASS_OK		 ;
PASS_NG0:      CMP.L	 #0,ER0 		 ;
	       BEQ	 PASS_ERR		 ;
	       BRA	 PASS_NG		 ;
PAS_1:	       CMP.B	 #ASCII_W,ACC		 ;
	       BNE	 MRV_ERR		 ;
	       BLD	 OVER_PASSWORD		 ;
	       BCS	 PASS_ERR		 ;
	       BLD	 COM_SECRET		 ;
	       BCS	 PASS_ERR		 ;
	       BLD	 RUN_FLAG		 ;
	       BCS	 CLR_ERR		 ;
	       MOV.W	 @R3_DATA,R0		 ;
	       MOV.W	 R0,@WS039_ADDR 	 ;
	       MOV.W	 @R3_DATA+2,R0		 ;
	       MOV.W	 R0,@WS040_ADDR 	 ;
	       BSET	 COM_SECRET		 ;
	       BRA	 PASS_OK		 ;
PASS_ERR:      MOV.B	 #ASCII_0,REG_R1	 ;
	       MOV.B	 #ASCII_6,REG_R2	 ;
	       BRA	 COM_ERR_RET		 ;
PASS_NG:       MOV.W	 @WS010_ADDR,R0 	 ;
	       INC.W	 #1,R0			 ;
	       CMP.W	 #D'20,R0                ;
	       BCC	 PASS_NG_LOCK		 ;
	       BCLR	 OVER_PASSWORD		 ;
	       BRA	 PASS_NG_LOCK1:8	 ;
PASS_NG_LOCK:  BSET	 OVER_PASSWORD		 ;
PASS_NG_LOCK1: MOV.B	 #ASCII_1,ACC		 ;
	       BRA	 PASS_OK1:8		 ;
PASS_OK:       MOV.B	 #ASCII_0,ACC		 ;
PASS_OK1:      BLD	 PG_COM_BIT		 ;
	       BCS	 PASS_MODE1:8		 ;
	       MOV.B	 ACC,@COM_BUF8		 ;
	       BRA	 PSR_RET		 ;
PASS_MODE1:    MOV.B	 ACC,@PG_BUF9		 ;
	       BRA	 PSR_RET		 ;


;;;; ERROR MESSAGE RESPONSE ;;;;		 ;
NUMBER_ERR:    MOV.B	 #ASCII_0,REG_R1	 ;
	       MOV.B	 #ASCII_5,REG_R2	 ;
	       BRA	 COM_ERR_RET		 ;
P_W_P:	       MOV.B	 #ASCII_0,REG_R1	 ;
	       MOV.B	 #ASCII_E,REG_R2	 ;
	       BRA	 COM_ERR_RET		 ;
SEC_ERR_20:    MOV.B	 #ASCII_3,REG_R1	 ;
	       MOV.B	 #ASCII_0,REG_R2	 ;
	       BRA	 COM_ERR_RET		 ;
SEC_ERR_21:    MOV.B	 #ASCII_3,REG_R1	 ;
	       MOV.B	 #ASCII_1,REG_R2	 ;
	       BRA	 COM_ERR_RET		 ;
SEC_ERR_22:    MOV.B	 #ASCII_3,REG_R1	 ;
	       MOV.B	 #ASCII_2,REG_R2	 ;
	       BRA	 COM_ERR_RET		 ;
SEC_ERR_23:    MOV.B	 #ASCII_3,REG_R1	 ;
	       MOV.B	 #ASCII_3,REG_R2	 ;
	       BRA	 COM_ERR_RET		 ;
ACL_ERR_RET:   MOV.B	 #ASCII_0,REG_R1	 ;
	       MOV.B	 #ASCII_1,REG_R2	 ;
	       BRA	 COM_ERR_RET		 ;
SES_RET:       MOV.B	 #ASCII_23H,ACC 	 ;
	       BLD	 PG_COM_BIT		 ;
	       BCS	 SES_RET_1:8		 ;
	       MOV.B	 ACC,@COM_BUF3		 ;
	       BRA	 SES_RET_2:8		 ;
SES_RET_1:     MOV.B	 ACC,@PG_BUF4		 ;
SES_RET_2:     MOV.W	 #H'0007,DATA1_W         ;
	       BRA	 COM_LNK_RET		 ;
;;;;;						 ;
COM_LNK_RET:   BLD	 PG_COM_BIT		 ;
	       BCS	 COM_LNK11:8		 ;
	       MOV.W	 @COM_BUF1,ACC_W	 ;
	       BRA	 COM_LNK12:8		 ;
COM_LNK11:     MOV.W	 @PG_BUF2,ACC_W 	 ;
COM_LNK12:     CMP.W	 #H'3030,ACC_W           ;
	       BNE	 COM_LNK_RET1:8 	 ;
	       BLD	 PG_COM_BIT		 ;BROADCAST NO NEED TO RESPONSE
	       BCS	 RS422_RET:8		 ;
PG_CL_RET:     BCLR	 PG_COM_BIT		 ;
	       BCLR	 TXENDF0		 ;;V0.E
	       JMP	 @LED_BUF_REFLESH	 ;PG port return  COMM_PG_C
RS422_RET:     BCLR	 PG_COM_BIT		 ;
	       BCLR	 TXENDF1		 ;;V0.E
	       JMP	 @COMM_PG		 ;RS422 port return
COM_LNK_RET1:  BLD	 PG_COM_BIT		 ;
	       BCS	 COM_LNK_RET11:8	 ;
	       MOV.L	 #COM_BUF1,DPTR 	 ;Input DATA1_W(byte counter)
	       BRA	 COM_LNK_RET12:8	 ;
COM_LNK_RET11: MOV.L	 #PG_BUF2,DPTR		 ;
COM_LNK_RET12: MOV.B	 #H'00,B_REG             ;
COM_SUM_LOOP:  MOV.B	 @DPTR,ACC		 ;
	       ADD.B	 ACC,B_REG		 ;
	       INC.L	 #1,DPTR		 ;
	       DEC.W	 #1,DATA1_W		 ;
	       BNE	 COM_SUM_LOOP:8 	 ;
	       NOT.B	 B_REG			 ;2's complement
	       ADD.B	 #1,B_REG		 ;
	       MOV.B	 B_REG,ACC		 ;
	       BSR	 SWAP_ACC		 ;
	       BSR	 HEX_ASCII		 ;
	       MOV.B	 ACC,@DPTR		 ;High nibble
	       INC.L	 #1,DPTR		 ;
	       MOV.B	 B_REG,ACC		 ;
	       BSR	 HEX_ASCII		 ;
	       MOV.B	 ACC,@DPTR		 ;Low nibble
	       INC.L	 #1,DPTR		 ;
	       MOV.B	 #ASCII_CR,ACC		 ;
	       MOV.B	 ACC,@DPTR		 ;CR end byte
COM_RET_END:   BLD	 PG_COM_BIT		 ;
	       BCS	 COM_RET_1:8		 ;
	       MOV.L	 #ASCII1_3A,DPTR	 ;
	       MOV.B	 @DPTR,ACC		 ;
	       MOV.B	 ACC,@TDR1		 ;
	       MOV.L	 DPTR,@BUFF_PTR 	 ;
	       BCLR	 #RIE,@SCR1		 ;
	       BCLR	 #RE,@SCR1		 ;;V0.8
	       MOV.B	 @RI_ADDR,ACC		 ;
	       BRA	 COM_RET_2:8		 ;
COM_RET_1:     MOV.L	 #PG_STX,DPTR		 ;
	       MOV.B	 @DPTR,ACC		 ;
	       MOV.B	 ACC,@TDR0		 ;
	       MOV.L	 DPTR,@FRAME_PTR	 ;
	       MOV.B	 @PG_RI_ADDR,ACC	 ;
COM_RET_2:     BSR	 ASCII_HEX		 ;
	       CMP.B	 #H'0A,ACC               ;
	       BCC	 A_F_RI:8		 ;
	       INC.B	 ACC			 ;
	       BRA	 RESET_RI_BASE		 ;
A_F_RI:        CMP.B	 #H'0A,ACC               ;
	       BNE	 B_RI:8 		 ;
	       MOV.B	 #D'11,ACC               ;
	       BRA	 RESET_RI_BASE		 ;
B_RI:	       CMP.B	 #H'0B,ACC               ;
	       BNE	 C_RI:8 		 ;
	       MOV.B	 #D'21,ACC               ;
	       BRA	 RESET_RI_BASE		 ;
C_RI:	       CMP.B	 #H'0C,ACC               ;
	       BNE	 D_RI:8 		 ;
	       MOV.B	 #D'31,ACC               ;
	       BRA	 RESET_RI_BASE		 ;
D_RI:	       CMP.B	 #H'0D,ACC               ;
	       BNE	 E_RI:8 		 ;
	       MOV.B	 #D'41,ACC               ;
	       BRA	 RESET_RI_BASE		 ;
E_RI:	       CMP.B	 #H'0E,ACC               ;
	       BNE	 F_RI:8 		 ;
	       MOV.B	 #D'51,ACC               ;
	       BRA	 RESET_RI_BASE		 ;
F_RI:	       MOV.B	 #D'61,ACC               ;
RESET_RI_BASE: BLD	 PG_COM_BIT		 ;
	       BCS	 RESET_RI_BASE1:8	 ;
	       MOV.B	 ACC,@RI_ADDR		 ;
	       MOV.B	 @TIME_BASE1,ACC	 ;
	       MOV.B	 ACC,@RESP_TM_BASE	 ;
	       JMP	 @COMM_PG1		 ;
RESET_RI_BASE1: 				 ;
	       MOV.B	 ACC,@PG_RI_ADDR	 ;
	       MOV.B	 @TIME_BASE1,ACC	 ;
	       MOV.B	 ACC,@RESP_TM_BASEPG	 ;
	       BCLR	 PG_COM_BIT		 ;
	       JMP	 @COMM_PG_C		 ;V0.B	LED_BUFF_REFLESH			    ;
COM_ERR_RET:   MOV.B	 #ASCII_25H,ACC 	 ;
	       BLD	 PG_COM_BIT		 ;
	       BCS	 COM_ERR_RET_1:8	 ;
	       MOV.B	 ACC,@COM_BUF3		 ;
	       MOV.B	 REG_R1,@COM_BUF5	 ;
	       MOV.B	 REG_R2,@COM_BUF6	 ;
	       BRA	 COM_ERR_RET_2:8	 ;
COM_ERR_RET_1: BLD	 F58_RXD_EN		 ;;V0.9
	       BCC	 COM_ERR_RET_3:8	 ;;
	       BCLR	 TXENDF0		 ;;
	       JMP	 @LED_BUF_REFLESH	 ;;
COM_ERR_RET_3: MOV.B	 ACC,@PG_BUF4		 ;
	       MOV.B	 REG_R1,@PG_BUF6	 ;
	       MOV.B	 REG_R2,@PG_BUF7	 ;
COM_ERR_RET_2: MOV.W	 #H'0006,DATA1_W         ;
	       BRA	 COM_LNK_RET		 ;
						 ;
;;;;;;;;
UPDATE_SYS_ROM:  .EQU	   $			 ;
		 BLD	   RUN_FLAG		 ;;
		 BCS	   RET_OK2		 ;;
		 BCLR	   REQ_START_FG0	 ;;
		 MOV.B	   #0,R1L		 ;;
		 MOV.B	   R1L,@PG_BUF1 	 ;;For response
		 MOV.B	   @PG_BUF2,R1H 	 ;PG_BUF2 high byte address
		 MOV.B	   @PG_BUF3,R1L 	 ;PG_BUF3 low byte address
WR_256_TO_FLASH: .EQU	   $			 ;
		 CMP.W	   #H'FFFF,R1            ;
		 BEQ	   UPDATE_ROM_ZONE	 ;NO NEED TO RESPONSE
		 MOV.L	   #DUMP_FLASH1,ER5	 ;;TEST FLASH MEMORY
		 MOV.L	   #H'000FF800,ER6       ;;RAM BUFFER TO EXECUTE ROM
		 MOV.W	   #D'256,R4             ;;
		 EEPMOV.W			 ;;
		 JSR	   @H'000FF800           ;;
		 BRA	   RET_OK2		 ;;


DUMP_FLASH1:	 MOV.L	   #PG_BUF4,ER5 	 ;;DUMP PROGRAM
		 MOV.L	   #H'00010000,ER6       ;;
		 ADD.W	   R1,R6		 ;;
		 CMP.L	   #H'0001FFFF,ER6       ;;
		 BCS	   DUMP_FLA_LP:8	 ;;
		 RTS				 ;;
DUMP_FLA_LP:	 MOV.B	   #D'128,R4L            ;;
RAM_TO_FLASH:	 BCLR	   #RE,@SCR0		 ;;V0.D
		 ORC	   #B'10000000,CCR       ;;
		 MOV.B	   @LED_DRIVER,R0L	 ;;
		 OR.B	   #B'00000100,R0L       ;;
		 MOV.B	   R0L,@H'000C0000       ;;DISABLE NMI
		 BSET	   #0,@WCR		 ;;TEST 3-WAIT STATE
		 BSET	   #1,@WCR		 ;;
		 MOV.B	   #H'AA,R0L             ;;
		 MOV.B	   R0L,@H'00005555       ;;
		 MOV.B	   #H'55,R0L             ;;
		 MOV.B	   R0L,@H'00002AAA       ;;
		 MOV.B	   #H'A0,R0L             ;;
		 MOV.B	   R0L,@H'00005555       ;;
		 EEPMOV.B			 ;;
DELAY_20MS:	 MOV.W	   #D'8400,R3            ;;
DELAY_LP:	 DEC.W	   #1,R3		 ;;(1*6+2*6)*K*8192=10mS
		 BNE	   DELAY_LP:8		 ;;(1*12+2*12)*J*4096=10mS
		 MOV.B	   @LED_DRIVER,R0L	 ;;
		 AND.B	   #B'11111011,R0L       ;;
		 MOV.B	   R0L,@LED_DRIVER	 ;;V0.D
		 MOV.B	   R0L,@H'000C0000       ;;
		 BCLR	   #0,@WCR		 ;;TEST 3-WAIT STATE
		 BCLR	   #1,@WCR		 ;;
		 ANDC	   #B'01111111,CCR       ;;
		 BSET	   #RE,@SCR0		 ;;V0.D
		 RTS				 ;;

UPDATE_ROM_ZONE: MOV.L	   #H'00010000,ER5       ;;V0.B
		 MOV.B	   #H'00,R4L             ;;
CHK_ROM_LP:	 MOV.B	   @ER5+,R4H		 ;;
		 ADD.B	   R4H,R4L		 ;;
		 CMP.L	   #H'00020000,ER5       ;;
		 BNE	   CHK_ROM_LP:8 	 ;;
		 CMP.B	   #H'FF,R4L             ;;
		 BNE	   RESTORE_F		 ;;
UPDATE_ROM_ZONE1: MOV.L     #DUMP_ALL_ZONE,ER5	  ;;TEST FLASH MEMORY
		 MOV.L	   #H'000FF800,ER6       ;;RAM BUFFER TO EXECUTE ROM
		 MOV.W	   #D'256,R4             ;;
		 EEPMOV.W			 ;;
		 JMP	   @H'000FF800           ;;
DUMP_ALL_ZONE:	 MOV.W	   #D'512,R2             ;;
		 MOV.L	   #H'00010000,ER5       ;;DUMP PROGRAM
		 MOV.L	   #H'00000000,ER6       ;;
DUMP_FLA_LP1:	 MOV.L	   #H'000FEF78,ER3         ;;V0.B
		 MOV.B	   #D'128,R1L              ;;
DUMP_RAM_FIRST:  MOV.B	   @ER5+,R1H		   ;;
		 MOV.B	   R1H,@ER3		   ;;
		 INC.L	   #1,ER3		   ;;
		 DEC.B	   R1L			   ;;
		 BNE	   DUMP_RAM_FIRST:8	   ;;
		 MOV.L	   ER5,@ER3_BUFFER	   ;;
		 MOV.L	   #H'000FEF78,ER5         ;;
DUMP_FLA_LP2:	 MOV.B	   #D'128,R4L              ;;
RAM_TO_FLASH1:	 BCLR	   #RE,@SCR0		   ;;V0.B
		 ORC	   #B'10000000,CCR         ;;
		 MOV.B	   @LED_DRIVER,R0L	   ;;
		 OR.B	   #B'00000100,R0L         ;;
		 MOV.B	   R0L,@H'000C0000         ;;
		 BSET	   #0,@WCR		   ;;TEST 3-WAIT STATE
		 BSET	   #1,@WCR		   ;;
		 MOV.B	   #H'AA,R0L               ;;
		 MOV.B	   R0L,@H'00005555         ;;
		 MOV.B	   #H'55,R0L               ;;
		 MOV.B	   R0L,@H'00002AAA         ;;
		 MOV.B	   #H'A0,R0L               ;;
		 MOV.B	   R0L,@H'00005555         ;;
		 EEPMOV.B			   ;;
DELAY_20MS1:	 MOV.W	   #D'8400,R3              ;;
DELAY_LP1:	 DEC.W	   #1,R3		   ;;(1*6+2*6)*K*8192=10mS
		 BNE	   DELAY_LP1:8		   ;;(1*12+2*12)*J*4096=10mS
		 MOV.B	   @LED_DRIVER,R0L	   ;;
		 AND.B	   #B'11111011,R0L         ;;V0.D
		 MOV.B	   R0L,@LED_DRIVER	   ;;V0.D
		 MOV.B	   R0L,@H'000C0000         ;;
		 BCLR	   #0,@WCR		   ;;TEST 3-WAIT STATE
		 BCLR	   #1,@WCR		   ;;
		 ANDC	   #B'01111111,CCR         ;;
		 BSET	   #RE,@SCR0		   ;;V0.B
		 MOV.B	   @TIME_BASE1,R1H	   ;;
		 BLD	   #5,R1H		   ;;
		 BST	   RUN_LED		   ;;
		 MOV.L	   @ER3_BUFFER,ER5	   ;;
		 MOV.W	   R2,@H'000A0000          ;;RESET WDT
		 DEC.W	   #1,R2		   ;;
		 BNE	   DUMP_FLA_LP1 	   ;;
RESTORE_F:	 JSR	   @DUMP_FLASH		   ;;Restore Flash memory
		 JMP	   @H'00000162             ;;
		 .END
