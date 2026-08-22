;	    ****************************************************
;      ***********    TAIAN TP02 PLC SOFTWARE PROGRAM	 ***********
;   *************      COMPILER PLC CODE MODULE Ver:0.1   *************
;***************	   TAIAN ELECTRIC CO., LTD.	   ***************
;   *************	    Written by Michael Wei	  *************
;      ***********    Start 1997/8/04	End 1997/ ?/ ?	 ***********
;	    ****************************************************
	       .CPU		300HA
	       .EXPORT		COMPILER,BCD_HEX_W,HEX_BCD_W,BCD_HEX_B,HEX_BCD_B
	       .IMPORT		START_SCAN,EXE_OUT_D0_B,EXE_READ_BYTE
	       .IMPORT		TIMER_B2,IMIB1_GO2,IMIA2_GO2,IMIB2_GO2
	       .IMPORT		IMIB3_GO2,IMIB4_GO2,DIAG_WR_LOOP
	       .INCLUDE 	"H83005.INC"
	       .INCLUDE 	"SYMBOL02.INC"
	       .SECTION 	C_PRO,CODE,LOCATE=H'002700   ;;2550->2700
;******************************************************************************
;******************    COMPILER        ****************************************
;******************************************************************************
COMPILER:	 BCLR	   COMPILER_BIT 	 ;Start compile
		 BCLR	   LOGIC_ERR_BIT	 ;;VF.0
;;;;;;;;;;;;this part do it later ;;;;;;;;;;;;;;;;
CAL_LABEL_ADDR:  JSR	   @INIT_LABEL		 ;
		 MOV.L	   #INST_STR_ADDR,ER6	 ;Instruction code start address
		 MOV.L	   #NU_STR_ADDR,ER5	 ;read NU code;
CAL_LAB_LP:	 MOV.W	   @ER6+,R0		 ;
		 MOV.B	   @ER5+,R1L		 ;
		 JSR	   @CAL_LABEL		 ;Calculate label address only
		 BLD	   CHG_MODE		 ;;VF.3
		 BCS	   CAL_LAB_LP1:8	 ;;
		 BLD	   LOGIC_ERR_BIT	 ;
		 BCS	   END_COMPILE2 	 ;;VF.0
CAL_LAB_LP1:	 CMP.L	   #F00_END_ADDR+1,ER6	 ;
		 BCS	   CAL_LAB_LP:8 	 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;???????????
	       ; BSR	   DIAG_MEM_CLR 	 ;clear used table and initial some parameters
		 MOV.B	   #0,R0L		 ;
		 MOV.B	   R0L,@STR_NUMBER	 ;
		 MOV.B	   R0L,@MCS_NUMBER	 ;
		 MOV.B	   R0L,@SKIP_NUMBER	 ;
		 MOV.B	   R0L,@SCLK_STR	 ;
		 MOV.B	   R0L,@FOR_NEXT_NUM	 ;
		 MOV.B	   R0L,@DOUBLE_FUNC	 ;;V0.C NEW ADDED
		 MOV.B	   R0L,@JCS_ADDR	 ;;V0.C
		 MOV.B	   R0L,@JCS_ADDR+1	 ;;
		 BCLR	   LOGIC_ERR_BIT	 ;
		 BCLR	   TMR_CNT_OUT		 ;
		 BCLR	   FN_BIT		 ;
		 BCLR	   SCLK 		 ;
		 BCLR	   FOR_NEXT		 ;
		 BCLR	   F33_TOGGLE		 ;;V1.0
COMPILE_START:	 MOV.L	   #INST_STR_ADDR,ER6	 ;
		 MOV.L	   #NU_STR_ADDR,ER5	 ;
		 BLD	   LOGIC_DETECT 	 ;;V0.A
		 BCC	   NORMAL_COMPILE:8	 ;;V0.A
		 MOV.L	   #H'00020000,ER4       ;;PSEUDO ADDRESS
		 BRA	   COMPILE_LP:8 	 ;;
NORMAL_COMPILE:  MOV.L	   #MACHINE_CODE,ER4	 ;
COMPILE_LP:	 MOV.W	   @ER6+,R0		 ;read instruction code
		 MOV.B	   @ER5+,R1L		 ;read NU code
		 JSR	   @DECODE_COMPILE	 ;decode and compile
		 BLD	   CHG_MODE		 ;;VF.0
		 BCS	   COMPILE_LP1:8	 ;;
		 BLD	   LOGIC_ERR_BIT	 ;
		 BCS	   END_COMPILE2:8	 ;;VF.0
COMPILE_LP1:	 CMP.L	   #F00_END_ADDR+1,ER6	 ; TEST
		 BLS	   COMPILE_LP:8 	 ;
		 JSR	   @JUG_F07_SKIP	 ;
		 BLD	   LOGIC_ERR_BIT	 ;
		 BCS	   END_COMPILE2:8	 ;;VF.0
END_COMPILE:	 BSET	   COMPILER_BIT 	 ;
		 RTS				 ;
END_COMPILE2:	 BCLR	   COMPILER_BIT 	 ;;VF.0
		 RTS				 ;;
JUG_F07_SKIP:	 MOV.B	   @SKIP_NUMBER,R1L	 ;
		 CMP.B	   #H'00,R1L             ;
		 BNE	   F08_ENDS_LESS	 ;
		 MOV.B	   @FOR_NEXT_NUM,R1L	 ;
		 CMP.B	   #H'00,R1L             ;
		 BNE	   FOR_NEXT_ERROR	 ;
		 RTS				 ;;
CAL_LABEL:	 MOV.W	   R0,R2		 ; R0, R1L
		 AND.B	   #B'01111000,R2L       ;
		 BLD	   #7,R2H		 ;
		 BCS	   CAL_LABEL_RET:8	 ;
		 CMP.B	   #B'01111000,R2L       ;
		 BNE	   CAL_LABEL_RET:8	 ;
		 CMP.B	   #D'42,R2H             ;TEST BY F11W ,F42_LABL
		 BNE	   CAL_LABEL_RET:8	 ;
		 MOV.L	   ER6,ER3		 ;
		 SUB.L	   #INST_STR_ADDR+2,ER3  ;
		 SHLR.W    R3			 ;
		 MOV.W	   R3,@R3_BUFFER	 ;INST absolute offset address(0-4000)
		 BLD	   #0,R0L		 ;
		 BST	   #0,R1L		 ;
		 BLD	   #1,R0L		 ;
		 BST	   #1,R1L		 ;
		 BLD	   #2,R0L		 ;
		 BST	   #2,R1L		 ;
		 BLD	   #7,R0L		 ;
		 BST	   #3,R1L		 ;
		 CMP.B	   #D'128,R1L            ;
		 BCC	   CAL_LABEL_ERR:8	 ;OVER LB001-LB128
		 MOV.B	   #0,R1H		 ;     (000) (127)
		 SHLL.W    R1			 ;
		 MOV.L	   #LABEL_INST_ADDR,ER4  ;LB001-LB128
		 ADD.W	   R1,R4		 ;00000-00254
		 MOV.W	   @ER4,R3		 ;
		 CMP.W	   #END_ADDR,R3        ;;VF.3
		 BNE	   CAL_LABEL_ERR:8	 ;double label error
		 MOV.W	   @R3_BUFFER,R3	 ;
		 MOV.W	   R3,@ER4		 ;0000-4000 LABEL ADDRESS
CAL_LABEL_RET:	 BCLR	   LOGIC_ERR_BIT	 ;
		 RTS				 ;
CAL_LABEL_ERR:	 BRA	   LABEL_ERROR		 ;;VF.0

DECODE_COMPILE: .EQU	   $
		 MOV.B	   R0L,R1H
NOP_JUG:	 AND.B	   #B'01111111,R1H
		 CMP.B	   #B'00000000,R1H
		 BNE	   AND_STR_JUG:8
		 JMP	   @C_NOP
AND_STR_JUG:	 CMP.B	   #B'00000001,R1H
		 BNE	   OR_STR_JUG:8
		 JMP	   @C_AND_STR
OR_STR_JUG:	 CMP.B	   #B'00000010,R1H
		 BNE	   SEQUENCER_JUG:8
		 JMP	   @C_OR_STR
SEQUENCER_JUG:	 AND.B	   #B'01111000,R1H
		 CMP.B	   #B'00001000,R1H
		 BNE	   STR_JUG:8
		 JMP	   @C_SEQUENCER
STR_JUG:	 CMP.B	   #B'00010000,R1H
		 BNE	   STR_NOT_JUG:8
		 JSR	   @X_Y_C_ADDR
		 JMP	   @C_STR
STR_NOT_JUG:	 CMP.B	   #B'00011000,R1H
		 BNE	   AND_JUG:8
		 JSR	   @X_Y_C_ADDR
		 JMP	   @C_STR_NOT
AND_JUG:	 CMP.B	   #B'00100000,R1H
		 BNE	   AND_NOT_JUG:8
		 JSR	   @X_Y_C_ADDR
		 JMP	   @C_AND
AND_NOT_JUG:	 CMP.B	   #B'00101000,R1H
		 BNE	   OR_JUG:8
		 JSR	   @X_Y_C_ADDR
		 JMP	   @C_AND_NOT
OR_JUG: 	 CMP.B	   #B'00110000,R1H
		 BNE	   OR_NOT_JUG:8
		 JSR	   @X_Y_C_ADDR
		 JMP	   @C_OR
OR_NOT_JUG:	 CMP.B	   #B'00111000,R1H
		 BNE	   OUT_JUG:8
		 JSR	   @X_Y_C_ADDR
		 JMP	   @C_OR_NOT
OUT_JUG:	 CMP.B	   #B'01000000,R1H
		 BNE	   TMR_JUG:8
		 JSR	   @X_Y_C_ADDR
		 JMP	   @C_OUT
TMR_JUG:	 CMP.B	   #B'01100000,R1H
		 BNE	   CNT_JUG:8
		 JSR	   @TMR_CNT_ADDR
		 BLD	   JUDGE_NG
		 BCS	   RANGE_OVER
		 JMP	   @C_TMR
CNT_JUG:	 CMP.B	   #B'01101000,R1H
		 BNE	   FUNCTION_JUG:8
		 JSR	   @TMR_CNT_ADDR
		 BLD	   JUDGE_NG
		 BCS	   RANGE_OVER
		 JMP	   @C_CNT
FUNCTION_JUG:	 CMP.B	   #B'01110000,R1H
		 BEQ	   FUNCTION_JUG1:8
		 CMP.B	   #B'01111000,R1H
		 BNE	   NOT_FUNCTION:8
		 CMP.B	   #D'42,R0H
		 BEQ	   C_F42
		 BRA	   NOT_FUNCTION:8
FUNCTION_JUG1: ;;BLD	   #4,R1L		 ;C11,C10,C9,C8,C7,C6,C5,C4
	       ;;BST	   #7,R0H		 ;F00 - F255
		 MOV.L	   #FUNC_TABLE,ER3
		 MOV.B	   R0H,R2L
		 MOV.B	   #H'00,R2H
		 SHLL.W    R2
		 ADD.W	   R2,R3
		 MOV.W	   @ER3,R2
		 MOV.W	   #H'0,E2           ;
		 JMP	   @ER2
NOT_FUNCTION:	 BRA	   PROG_CHK_ERR
;
; R0H: 0,R2,R1,R0,S3,S2,S1,S0
; R0L: P,C3,C2,C1,C0,ID2,ID1,ID0
C_SEQUENCER:	 MOV.W	   #H'7902,R2       ;
		 MOV.W	   R2,@ER4	    ;
		 INC.L	   #2,ER4	    ;
		 MOV.B	   R0H,R2L
		 MOV.B	   R0H,R2H
		 AND.B	   #B'00001111,R2L
		 INC.B	   R2L
		 SHLR.B    R2H
		 SHLR.B    R2H
		 SHLR.B    R2H
		 AND.B	   #B'00001110,R2H
		 MOV.W	   R2,@ER4
		 INC.L	   #2,ER4
		 MOV.W	   #H'5E00,R2       ;
		 MOV.W	   R2,@ER4	    ;
		 INC.L	   #2,ER4	    ;
		 AND.B	   #B'00000111,R0L
C_SEQ_STR:	 CMP.B	   #B'00000000,R0L
		 BNE	   C_SEQ_STR_NOT:8
		 MOV.W	   #SEQ_STR,R2
		 MOV.W	   R2,@R3_BUFFER
		 BRA	   C_STR_SEQ:8
C_SEQ_STR_NOT:	 CMP.B	   #B'00000001,R0L
		 BNE	   C_SEQ_AND:8
		 MOV.W	   #SEQ_STR_NOT,R2  ;;V0.D #SEQ_STR->#SEQ_STR_NOT
		 MOV.W	   R2,@R3_BUFFER
C_STR_SEQ:	 BLD	   FN_BIT	    ;When meet the FN_BIT
		 BCC	   C_STR_2_SEQ:8    ;reset the STR NUMBER
C_STR_1_SEQ:	 MOV.B	   #0,R2L	    ;
		 MOV.B	   R2L,@STR_NUMBER  ;
		 MOV.B	   R2L,@SCLK_STR    ;
		 BLD	   FN_BIT	    ;
		 BCC	   C_STR_FN_SEQ:8   ;
		 BCLR	   SCLK 	    ;
		 BCLR	   FN_BIT	    ;Reset the FN_BIT
C_STR_FN_SEQ:	 BCLR	   TMR_CNT_OUT	    ;
C_STR_2_SEQ:	 MOV.B	   @STR_NUMBER,R2L  ;;VF.1
		 CMP.B	   #H'09,R2L        ;;
		 BCC	   STACK_OVER	    ;;
		 JSR	   @STR_INC	    ;
		 MOV.B	   @SCLK_STR,R2L    ;
		 INC.B	   R2L		    ;
		 MOV.B	   R2L,@SCLK_STR    ;
		 BRA	   C_SEQ_AND_J1     ;
;
C_SEQ_AND:	CMP.B	   #B'00000010,R0L
		BNE	   C_SEQ_AND_NOT:8
		MOV.W	   #SEQ_AND,R2
		MOV.W	   R2,@R3_BUFFER
		BRA	   C_SEQ_AND_J
C_SEQ_AND_NOT:	CMP.B	   #B'00000011,R0L
		BNE	   C_SEQ_OR:8
		MOV.W	   #SEQ_AND_NOT,R2
		MOV.W	   R2,@R3_BUFFER
		BRA	   C_SEQ_AND_J
C_SEQ_OR:	CMP.B	   #B'00000100,R0L
		BNE	   C_SEQ_OR_NOT:8
		MOV.W	   #SEQ_OR,R2
		MOV.W	   R2,@R3_BUFFER
		BRA	   C_SEQ_AND_J
C_SEQ_OR_NOT:	CMP.B	   #B'00000101,R0L
		BNE	   NOT_FUNCTION
		MOV.W	   #SEQ_OR_NOT,R2
		MOV.W	   R2,@R3_BUFFER
C_SEQ_AND_J:	MOV.B	   @STR_NUMBER,R2L  ;
		CMP.B	   #0,R2L	    ;
		BEQ	   STACK_UNDER	    ;
		BCLR	   FN_BIT	    ;
C_SEQ_AND_J1:	MOV.W	   @R3_BUFFER,R2    ;
		MOV.W	   R2,@ER4	    ;
		INC.L	   #2,ER4	    ;
		RTS			    ;
;
SEQ_STR:       ROTXR.B	   R0L
	       MOV.W	   #V_MEMORY_ADDR1,R3
	       ADD.B	   R2H,R3L
	       MOV.W	   @ER3,R4
	       MOV.B	   #0,R2H
	       CMP.W	   R2,R4
	       BEQ	   SEQ_STR_S:8
	       ANDC	   #B'11111110,CCR
	       RTS
SEQ_STR_S:     ORC	   #B'00000001,CCR
	       RTS
;
SEQ_STR_NOT:   ROTXR.B	   R0L
	       MOV.W	   #V_MEMORY_ADDR1,R3
	       ADD.B	   R2H,R3L
	       MOV.W	   @ER3,R4
	       MOV.B	   #0,R2H
	       CMP.W	   R2,R4
	       BEQ	   SEQ_STR_NOT_S:8
	       ORC	   #B'00000001,CCR    ;;V0.D
	       RTS
SEQ_STR_NOT_S: ANDC	   #B'11111110,CCR    ;;
	       RTS
;
SEQ_AND:       BST	   C_BIT_BUFFER
	       MOV.W	   #V_MEMORY_ADDR1,R3
	       ADD.B	   R2H,R3L
	       MOV.W	   @ER3,R4
	       MOV.B	   #0,R2H
	       CMP.W	   R2,R4
	       BEQ	   SEQ_AND_S:8
	       ANDC	   #B'11111110,CCR
	       RTS
SEQ_AND_S:     BLD	   C_BIT_BUFFER
	       RTS
;
SEQ_AND_NOT:   BST	   C_BIT_BUFFER
	       MOV.W	   #V_MEMORY_ADDR1,R3
	       ADD.B	   R2H,R3L
	       MOV.W	   @ER3,R4
	       MOV.B	   #0,R2H
	       CMP.W	   R2,R4
	       BNE	   SEQ_AND_NOT_S:8
	       ANDC	   #B'11111110,CCR
	       RTS
SEQ_AND_NOT_S: BLD	   C_BIT_BUFFER
	       RTS
;
SEQ_OR:        BST	   C_BIT_BUFFER
	       MOV.W	   #V_MEMORY_ADDR1,R3
	       ADD.B	   R2H,R3L
	       MOV.W	   @ER3,R4
	       MOV.B	   #0,R2H
	       CMP.W	   R2,R4
	       BEQ	   SEQ_OR_S:8
	       BLD	   C_BIT_BUFFER
	       RTS
SEQ_OR_S:      ORC	   #B'00000001,CCR
	       RTS
;
SEQ_OR_NOT:    BST	   C_BIT_BUFFER
	       MOV.W	   #V_MEMORY_ADDR1,R3
	       ADD.B	   R2H,R3L
	       MOV.W	   @ER3,R4
	       MOV.B	   #0,R2H
	       CMP.W	   R2,R4
	       BEQ	   SEQ_OR_NOT_S:8
	       ORC	   #B'00000001,CCR
	       RTS
SEQ_OR_NOT_S:  BLD	   C_BIT_BUFFER
	       RTS

;;;;; START TO COMPILER THE INSTRUCTION CODE  ;;;;;
C_NOP:		MOV.W		#H'4006,R2       ;
		MOV.W		R2,@ER4 	 ;BRA  disp:8
		INC.L		#2,ER4		 ;
		MOV.W		#H'0,R2          ;
		MOV.W		R2,@ER4 	 ;NOP
		INC.L		#2,ER4		 ;
		MOV.W		R2,@ER4 	 ;NOP
		INC.L		#2,ER4		 ;
		MOV.W		R2,@ER4 	 ;NOP
		INC.L		#2,ER4		 ;
		RTS				 ;
;						 ;
C_STR:		BLD		FN_BIT		 ;When meet the FN_BIT
		BCC		C_STR_2:8	 ;reset the STR NUMBER
C_STR_1:	MOV.B		#0,R2L		 ;
		MOV.B		R2L,@STR_NUMBER  ;
		MOV.B		R2L,@SCLK_STR	 ;
		BLD		FN_BIT		 ;
		BCC		C_STR_FN:8	 ;
		BCLR		SCLK		 ;
		BCLR		FN_BIT		 ;Reset the FN_BIT
C_STR_FN:	BCLR		TMR_CNT_OUT	 ;
C_STR_2:	MOV.B		@STR_NUMBER,R2L  ;;VF.1
		CMP.B		#H'09,R2L        ;;
		BCC		STACK_OVER	 ;;
		JSR		@STR_INC	 ;
		MOV.B		@SCLK_STR,R2L	 ;
		INC.B		R2L		 ;
		MOV.B		R2L,@SCLK_STR	 ;
		MOV.W		#H'1308,R2       ;;Start compiler inst code
		MOV.W		R2,@ER4 	 ;
		INC.L		#2,ER4		 ;
		MOV.W		#H'6A00,R2       ;
		MOV.W		R2,@ER4 	 ;
		INC.L		#2,ER4		 ;
		MOV.W		R0,@ER4 	 ;
		INC.L		#2,ER4		 ;
		MOV.B		#H'77,R2L        ;
		MOV.B		R2L,@ER4	 ;
		INC.L		#1,ER4		 ;
		MOV.B		R1L,@ER4	 ;
		INC.L		#1,ER4		 ;
		RTS				 ;
;						 ;
C_STR_NOT:	BLD		FN_BIT		 ;When meet the FN_BIT
		BCC		C_STR_NOT_2:8	 ;reset the STR NUMBER
C_STR_NOT_1:	MOV.B		#0,R2L		 ;
		MOV.B		R2L,@STR_NUMBER  ;
		MOV.B		R2L,@SCLK_STR	 ;
		BLD		FN_BIT		 ;
		BCC		C_STR_NOT_FN:8	 ;
		BCLR		SCLK		 ;
		BCLR		FN_BIT		 ;Reset the FN_BIT
C_STR_NOT_FN:	BCLR		TMR_CNT_OUT	 ;
C_STR_NOT_2:	MOV.B		@STR_NUMBER,R2L  ;;VF.1
		CMP.B		#H'09,R2L        ;;
		BCC		STACK_OVER	 ;;
		JSR		@STR_INC	 ;
		MOV.B		@SCLK_STR,R2L	 ;
		INC.B		R2L		 ;
		MOV.B		R2L,@SCLK_STR	 ;
		MOV.W		#H'1308,R2       ;
		MOV.W		R2,@ER4 	 ;
		INC.L		#2,ER4		 ;
		MOV.W		#H'6A00,R2       ;
		MOV.W		R2,@ER4 	 ;
		INC.L		#2,ER4		 ;
		MOV.W		R0,@ER4 	 ;
		INC.L		#2,ER4		 ;
		MOV.B		#H'77,R2L        ;
		MOV.B		R2L,@ER4	 ;
		INC.L		#1,ER4		 ;
		ADD.B		#H'80,R1L        ;
		MOV.B		R1L,@ER4	 ;
		INC.L		#1,ER4		 ;
		RTS				 ;

C_AND:		MOV.B		@STR_NUMBER,R2L  ;
		CMP.B		#0,R2L		 ;
		BEQ		STACK_UNDER	 ;
		BCLR		FN_BIT		 ;
		MOV.W		#H'6A00,R2       ;
		MOV.W		R2,@ER4 	 ;
		INC.L		#2,ER4		 ;
		MOV.W		R0,@ER4 	 ;
		INC.L		#2,ER4		 ;
		MOV.B		#H'76,R2L        ;
		MOV.B		R2L,@ER4	 ;
		INC.L		#1,ER4		 ;
		MOV.B		R1L,@ER4	 ;
		INC.L		#1,ER4		 ;
		MOV.W		#0,R2		 ;
		MOV.W		R2,@ER4 	 ;
		INC.L		#2,ER4		 ;
		RTS				 ;
;						 ;
C_AND_NOT:	MOV.B		@STR_NUMBER,R2L  ;
		CMP.B		#0,R2L		 ;
		BEQ		STACK_UNDER	 ;
		BCLR		FN_BIT		 ;
		MOV.W		#H'6A00,R2       ;
		MOV.W		R2,@ER4 	 ;
		INC.L		#2,ER4		 ;
		MOV.W		R0,@ER4 	 ;
		INC.L		#2,ER4		 ;
		MOV.B		#H'76,R2L        ;
		MOV.B		R2L,@ER4	 ;
		INC.L		#1,ER4		 ;
		ADD.B		#H'80,R1L        ;
		MOV.B		R1L,@ER4	 ;
		INC.L		#1,ER4		 ;
		MOV.W		#0,R2		 ;
		MOV.W		R2,@ER4 	 ;
		INC.L		#2,ER4		 ;
		RTS				 ;
;						 ;
C_OR:		MOV.B		@STR_NUMBER,R2L  ;
		CMP.B		#0,R2L		 ;
		BEQ		STACK_UNDER	 ;
		BCLR		FN_BIT		 ;
		MOV.W		#H'6A00,R2       ;
		MOV.W		R2,@ER4 	 ;
		INC.L		#2,ER4		 ;
		MOV.W		R0,@ER4 	 ;
		INC.L		#2,ER4		 ;
		MOV.B		#H'74,R2L        ;
		MOV.B		R2L,@ER4	 ;
		INC.L		#1,ER4		 ;
		MOV.B		R1L,@ER4	 ;
		INC.L		#1,ER4		 ;
		MOV.W		#0,R2		 ;
		MOV.W		R2,@ER4 	 ;
		INC.L		#2,ER4		 ;
		RTS				 ;
;						 ;
C_OR_NOT:	MOV.B		@STR_NUMBER,R2L  ;
		CMP.B		#0,R2L		 ;
		BEQ		STACK_UNDER	 ;
		BCLR		FN_BIT		 ;
		MOV.W		#H'6A00,R2       ;
		MOV.W		R2,@ER4 	 ;
		INC.L		#2,ER4		 ;
		MOV.W		R0,@ER4 	 ;
		INC.L		#2,ER4		 ;
		MOV.B		#H'74,R2L        ;
		MOV.B		R2L,@ER4	 ;
		INC.L		#1,ER4		 ;
		ADD.B		#H'80,R1L        ;
		MOV.B		R1L,@ER4	 ;
		INC.L		#1,ER4		 ;
		MOV.W		#0,R2		 ;
		MOV.W		R2,@ER4 	 ;
		INC.L		#2,ER4		 ;
		RTS				 ;
;						 ;
C_OUT:		.EQU		$		 ;
Y_C_USED_JUDGE: PUSH.W		R0		 ;V0.C
		PUSH.W		R1		 ;
		ADD.W		#H'2FB0,R0       ;Add offset pointer
		SHLR.B		R1L		 ;
		SHLR.B		R1L		 ;
		SHLR.B		R1L		 ;
		SHLR.B		R1L		 ;
		BTST		R1L,@ER0	 ;
		BNE		ALREADY_USED:8	 ;
		BSET		R1L,@ER0	 ;
		POP.W		R1		 ;
		POP.W		R0		 ;
		BRA		C_OUT1:8	 ;
ALREADY_USED:	POP.W		R1		 ;
		POP.W		R0		 ;
		MOV.W		@WS021_ADDR,R2	 ;
		CMP.W		#H'0001,R2       ;
		BNE		DOUBLS_OUT_ERR	 ;;
;						 ;
C_OUT1: 	BLD		TMR_CNT_OUT	 ;
		BCS		C_OUT_1:8	 ;
		MOV.B		@STR_NUMBER,R2L  ;
		CMP.B		#D'1,R2L         ;
		BEQ		C_OUT_1:8	 ;
		BCS		STACK_UNDER	 ;
		BRA		STACK_OVER	 ;
C_OUT_1:	MOV.W		#H'7902,R2       ;
		MOV.W		R2,@ER4 	 ;
		INC.L		#2,ER4		 ;
		MOV.W		R0,@ER4 	 ;
		INC.L		#2,ER4		 ;
	      ; BLD		TMR_CNT_OUT	 ;;V0.A
	      ; BCS		C_OUT_2:8	 ;;
	      ; MOV.W		#H'5E0F,R2       ;;
	      ; BRA		C_OUT_3:8	 ;;
C_OUT_2:	MOV.W		#H'5E00,R2       ;
C_OUT_3:	MOV.W		R2,@ER4 	 ;
		INC.L		#2,ER4		 ;
C_OUT_BIT0:	CMP.B		#B'00000000,R1L  ;
		BNE		C_OUT_BIT1:8	 ;
		BLD		TMR_CNT_OUT	 ;
		BCC		C_OUT_BIT00:8	 ;
		MOV.W		#OUT_SUB00,R2	 ;
		BRA		C_OUT_RET	 ;
C_OUT_BIT00:	MOV.W		#OUT_SUB0,R2	; ;V0.A
		BRA		C_OUT_RET	 ;
C_OUT_BIT1:					 ;
		CMP.B		#B'00010000,R1L  ;
		BNE		C_OUT_BIT2:8	 ;
		BLD		TMR_CNT_OUT	 ;
		BCC		C_OUT_BIT01:8	 ;
		MOV.W		#OUT_SUB01,R2	 ;
		BRA		C_OUT_RET	 ;
C_OUT_BIT01:	MOV.W		#OUT_SUB1,R2	; ;V0.A
		BRA		C_OUT_RET	 ;
C_OUT_BIT2:					 ;
		CMP.B		#B'00100000,R1L  ;
		BNE		C_OUT_BIT3:8	 ;
		BLD		TMR_CNT_OUT	 ;
		BCC		C_OUT_BIT02:8	 ;
		MOV.W		#OUT_SUB02,R2	 ;
		BRA		C_OUT_RET	 ;
C_OUT_BIT02:	MOV.W		#OUT_SUB2,R2	; ;V0.A
		BRA		C_OUT_RET	 ;
C_OUT_BIT3:					 ;
		CMP.B		#B'00110000,R1L  ;
		BNE		C_OUT_BIT4:8	 ;
		BLD		TMR_CNT_OUT	 ;
		BCC		C_OUT_BIT03:8	 ;
		MOV.W		#OUT_SUB03,R2	 ;
		BRA		C_OUT_RET	 ;
C_OUT_BIT03:	MOV.W		#OUT_SUB3,R2	; ;V0.A
		BRA		C_OUT_RET	 ;
C_OUT_BIT4:					 ;
		CMP.B		#B'01000000,R1L  ;
		BNE		C_OUT_BIT5:8	 ;
		BLD		TMR_CNT_OUT	 ;
		BCC		C_OUT_BIT04:8	 ;
		MOV.W		#OUT_SUB04,R2	 ;
		BRA		C_OUT_RET	 ;
C_OUT_BIT04:	MOV.W		#OUT_SUB4,R2	; ;V0.A
		BRA		C_OUT_RET	 ;
C_OUT_BIT5:					 ;
		CMP.B		#B'01010000,R1L  ;
		BNE		C_OUT_BIT6:8	 ;
		BLD		TMR_CNT_OUT	 ;
		BCC		C_OUT_BIT05:8	 ;
		MOV.W		#OUT_SUB05,R2	 ;
		BRA		C_OUT_RET	 ;
C_OUT_BIT05:	MOV.W		#OUT_SUB5,R2	; ;V0.A
		BRA		C_OUT_RET	 ;
C_OUT_BIT6:					 ;
		CMP.B		#B'01100000,R1L  ;
		BNE		C_OUT_BIT7:8	 ;
		BLD		TMR_CNT_OUT	 ;
		BCC		C_OUT_BIT06:8	 ;
		MOV.W		#OUT_SUB06,R2	 ;
		BRA		C_OUT_RET	 ;
C_OUT_BIT06:	MOV.W		#OUT_SUB6,R2	; ;V0.A
		BRA		C_OUT_RET	 ;
C_OUT_BIT7:					 ;
		BLD		TMR_CNT_OUT	 ;
		BCC		C_OUT_BIT07:8	 ;
		MOV.W		#OUT_SUB07,R2	 ;
		BRA		C_OUT_RET	 ;
C_OUT_BIT07:	MOV.W		#OUT_SUB7,R2	; ;V0.A
C_OUT_RET:					 ;
		MOV.W		R2,@ER4 	 ;
		INC.L		#2,ER4		 ;
		MOV.B		#1,R2L		 ;
		BSET		FN_BIT		 ;
		RTS				 ;

C_OR_STR:	MOV.B		@STR_NUMBER,R2L
		CMP.B		#9,R2L
		BHI		STACK_OVER
		CMP.B		#1,R2L
		BHI		OR_STR_1:8
		BRA		STACK_UNDER
OR_STR_1:	JSR		@STR_DEC
		BCLR		FN_BIT
		MOV.W		#H'7478,R2
		MOV.W		R2,@ER4
		INC.L		#2,ER4
		MOV.W		#H'1208,R2
		MOV.W		R2,@ER4
		INC.L		#2,ER4
		MOV.W		#H'7708,R2
		MOV.W		R2,@ER4
		INC.L		#2,ER4
		MOV.W		#H'7208,R2
		MOV.W		R2,@ER4
		INC.L		#2,ER4
		RTS
;
C_AND_STR:	MOV.B		@STR_NUMBER,R2L
		CMP.B		#9,R2L
		BHI		STACK_OVER
		CMP.B		#1,R2L
		BHI		AND_STR_1:8
		BRA		STACK_UNDER
AND_STR_1:	JSR		@STR_DEC
		BCLR		FN_BIT
		MOV.W		#H'7678,R2
		MOV.W		R2,@ER4
		INC.L		#2,ER4
		MOV.W		#H'1208,R2
		MOV.W		R2,@ER4
		INC.L		#2,ER4
		MOV.W		#H'7708,R2
		MOV.W		R2,@ER4
		INC.L		#2,ER4
		MOV.W		#H'7208,R2
		MOV.W		R2,@ER4
		INC.L		#2,ER4
		RTS
C_TMR:		PUSH.W		R2		  ;;
		PUSH.W		R1		  ;;
		MOV.B		#0,R1L		  ;;
		SHLR.W		R2		  ;
		BST		#0,R1L		  ;
		SHLR.W		R2		  ;
		BST		#1,R1L		  ;
		SHLR.W		R2		  ;
		BST		#2,R1L		  ;
		ADD.W		#H'F220,R2        ;
		MOV.W		#H'000F,E2        ;
		BTST		R1L,@ER2	  ;
		BNE		T_ALREADY_USED:8  ;
		BSET		R1L,@ER2	  ;
		POP.W		R1		  ;
		POP.W		R2		  ;
		BRA		C_TMR1:8	  ;
T_ALREADY_USED: POP.W		R1		  ;
		POP.W		R2		  ;
		MOV.W		@WS021_ADDR,R1	  ;
		CMP.W		#H'0001,R1        ;
		BNE		DOUBLS_T_C_ERR	  ;;
C_TMR1: 	MOV.B		@STR_NUMBER,R1L
		CMP.B		#D'0,R1L
		BEQ		STACK_UNDER
		CMP.B		#D'1,R1L
		BEQ		TMR_TYPE1
		CMP.B		#D'2,R1L
		BNE		STACK_OVER
		MOV.B		#D'0,R1L          ;;RESET STR_NUMBER
		MOV.B		R1L,@STR_NUMBER   ;;
TMR_TYPE2:	BSET		TMR_TYPEB
		BRA		TMR_TYPE11:8
TMR_TYPE1:	BCLR		TMR_TYPEB
TMR_TYPE11:	BLD		OPERAND_TYPE	 ;;F102
		BCC		TMR_TYPE1_D:8
		MOV.W		#H'F142,R1
		BRA		TMR_TYPE1_D1:8
TMR_TYPE1_D:	MOV.W		#H'F102,R1
TMR_TYPE1_D1:	MOV.W		R1,@ER4
		INC.L		#2,ER4
		MOV.W		#H'7902,R1
		MOV.W		R1,@ER4
		INC.L		#2,ER4
		MOV.W		R2,@ER4
		INC.L		#2,ER4
		MOV.W		#H'7903,R1
		MOV.W		R1,@ER4
		INC.L		#2,ER4
		MOV.W		R3,@ER4
		INC.L		#2,ER4
		MOV.W		#H'5E00,R1
		MOV.W		R1,@ER4
		INC.L		#2,ER4
		BLD		TMR_TYPEB
		BCC		ONE_STR:8
TWO_STR:	MOV.W		#TMR_SUB_B,R2
		BRA		ONE_STR1:8
ONE_STR:	MOV.W		#TMR_SUB_A,R2
ONE_STR1:	MOV.W		R2,@ER4
		INC.L		#2,ER4
		MOV.W		#H'7721,R2         ;;VF.6 H'7741->H'7721
		MOV.W		R2,@ER4
		INC.L		#2,ER4
		BSET		FN_BIT
		BSET		TMR_CNT_OUT	   ;;follow NOP,OUT,F40 is ok
		RTS				   ;;STR,STR NOT reset this bit
;;
C_CNT:		PUSH.W		R2		  ;;V0.C
		PUSH.W		R1		  ;;
		MOV.B		#0,R1L		  ;;
		SHLR.W		R2		  ;;
		BST		#0,R1L		  ;
		SHLR.W		R2		  ;
		BST		#1,R1L		  ;
		SHLR.W		R2		  ;
		BST		#2,R1L		  ;
		ADD.W		#H'F220,R2        ;
		MOV.W		#H'000F,E2        ;
		BTST		R1L,@ER2	  ;
		BNE		C_ALREADY_USED:8  ;
		BSET		R1L,@ER2	  ;
		POP.W		R1		  ;
		POP.W		R2		  ;
		BRA		C_CNT1:8	  ;
C_ALREADY_USED: POP.W		R1		  ;
		POP.W		R2		  ;
		MOV.W		@WS021_ADDR,R1	  ;
		CMP.W		#H'0001,R1        ;
		BNE		DOUBLS_T_C_ERR	  ;;
C_CNT1: 	MOV.B		@STR_NUMBER,R1L
		CMP.B		#D'2,R1L
		BEQ		CNT_TYPE:8
		BCS		STACK_UNDER
		BRA		STACK_OVER
CNT_TYPE:	MOV.B		#0,R1L		 ;;RESET STR_NUMBER
		MOV.B		R1L,@STR_NUMBER  ;;
		BLD		OPERAND_TYPE	 ;;F102
		BCC		CNT_TYPE1_D:8
		MOV.B		#H'42,R1L
		BRA		CNT_TYPE1_D1:8
CNT_TYPE1_D:	MOV.B		#H'02,R1L
CNT_TYPE1_D1:	BLD		SCLK
		BCC		CNT_TYPE1_D2:8
		MOV.B		@SCLK_STR,R1H
		CMP.B		#1,R1H
		BNE		PROG_CHK_ERR
		BSET		#7,R1L
		BRA		CNT_TYPE1_D3:8
CNT_TYPE1_D2:	BCLR		#7,R1L
CNT_TYPE1_D3:	MOV.B		#H'F1,R1H
		MOV.W		R1,@ER4
		INC.L		#2,ER4
		MOV.W		#H'7902,R1
		MOV.W		R1,@ER4
		INC.L		#2,ER4
		MOV.W		R2,@ER4
		INC.L		#2,ER4
		MOV.W		#H'7903,R1
		MOV.W		R1,@ER4
		INC.L		#2,ER4
		MOV.W		R3,@ER4
		INC.L		#2,ER4
		MOV.W		#H'5E00,R1
		MOV.W		R1,@ER4
		INC.L		#2,ER4
		MOV.W		#CNT_SUB,R2
		MOV.W		R2,@ER4
		INC.L		#2,ER4
		MOV.W		#H'7721,R2         ;;VF.6
		MOV.W		R2,@ER4
		INC.L		#2,ER4
		BSET		FN_BIT
		BSET		TMR_CNT_OUT	   ;;
		RTS
;;;;;;;;
C_F00:		MOV.W	  @JCS_ADDR,R2	     ;;V0.C
		CMP.W	  #0,R2 	     ;;
		BEQ	  C_F00_1:8	     ;;
		MOV.W	  R2,R6 	     ;;
		BRA	  JCS_ERROR	     ;;
C_F00_1:	MOV.B	  #H'00,R1L
		MOV.B	  R1L,@FN_TYPE
		JSR	  @C_TYPE0
		MOV.B	  #0,R1L	     ;;RESET STR_NUMBER
		MOV.B	  R1L,@STR_NUMBER    ;;
		RTS
;;;;;;;;
C_F01:		MOV.B	  @STR_NUMBER,R1L
		CMP.B	  #D'1,R1L
		BEQ	  F01_TYPE:8
		BCS	  STACK_UNDER
		BRA	  STACK_OVER
F01_TYPE:	MOV.B	  #0,R1L	   ;Reset STR number
		MOV.B	  R1L,@STR_NUMBER  ;
		MOV.B	  @MCS_NUMBER,R1L  ;WHEN CHECK MCR, MCS MUST
		INC.B	  R1L		   ;GREAT EQUAL ONE
		MOV.B	  R1L,@MCS_NUMBER  ;
		MOV.B	  #H'01,R1L
		MOV.B	  R1L,@FN_TYPE
		JSR	  @C_TYPE4
		RTS
;;;;;;;;
C_F02:	    ;;	MOV.B	  @STR_NUMBER,R1L
	    ;;	CMP.B	  #H'0,R1L
	    ;;	BNE	  STACK_OVER
		MOV.B	  @MCS_NUMBER,R1L
		CMP.B	  #H'0,R1L
		BEQ	  MCR_ERROR
		DEC.B	  R1L		      ;;V0.B, OVER 256 MCR AND 1 MCS
		MOV.B	  R1L,@MCS_NUMBER     ;;WILL CAUSE ERROR
		MOV.B	  #H'02,R1L
		MOV.B	  R1L,@FN_TYPE
		JSR	  @C_TYPE1
		MOV.B	  #0,R1L		;;;RESET STR_NUMBER
		MOV.B	  R1L,@STR_NUMBER	;;;
		RTS
;;;;;;;;
C_F03:		MOV.B	  @STR_NUMBER,R1L
		CMP.B	  #D'1,R1L
		BEQ	  F03_TYPE:8
		BCS	  STACK_UNDER
		BRA	  STACK_OVER
F03_TYPE:	MOV.W	  R6,R2 	   ;;V0.C NEW ADDED
		ADD.W	  #2,R2 	   ;;
		MOV.W	  R2,@JCS_ADDR	   ;;
		MOV.B	  #0,R1L	   ;Reset STR number
		MOV.B	  R1L,@STR_NUMBER  ;
		MOV.B	  @JCS_NUMBER,R1L  ;WHEN CHECK MCR, MCS MUST
		INC.B	  R1L		   ;GREAT EQUAL ONE
		MOV.B	  R1L,@JCS_NUMBER  ;
		MOV.B	  #H'03,R1L
		MOV.B	  R1L,@FN_TYPE
		JSR	  @C_TYPE4
		RTS
;;;;;;;;
C_F04:		MOV.B	  @JCS_NUMBER,R1L
		CMP.B	  #H'0,R1L
		BEQ	  JCR_ERROR
		DEC.B	  R1L		     ;;V0.B
		MOV.B	  R1L,@JCS_NUMBER    ;;
		MOV.W	  #0,R2 	     ;;V0.C
		MOV.W	  R2,@JCS_ADDR	     ;;
		MOV.B	  #H'04,R1L
		MOV.B	  R1L,@FN_TYPE
		JSR	  @C_TYPE1
		MOV.B	  #D'0,R1L           ;;
		MOV.B	  R1L,@STR_NUMBER    ;;RESET STR_NUMBER
		RTS
;;;;;;;;
C_F05:		MOV.B	  #H'05,R1L
		MOV.B	  R1L,@FN_TYPE
		JSR	  @C_TYPE3
		RTS
;;;;;;;;
C_F06:		MOV.B	  #H'06,R1L
		MOV.B	  R1L,@FN_TYPE
		JSR	  @C_TYPE31	      ;;;V1.3
		RTS
;;;;;;;;
C_F07:		MOV.B	  @STR_NUMBER,R1L
		CMP.B	  #D'1,R1L
		BEQ	  F07_TYPE:8
		BCS	  STACK_UNDER
		BRA	  STACK_OVER
F07_TYPE:	MOV.B	  @SKIP_NUMBER,R1L ;For F08_ENDS diagnostic
		INC.B	  R1L		   ;
		MOV.B	  R1L,@SKIP_NUMBER ;
		MOV.B	  #H'0,R1L         ;
		MOV.B	  R1L,@STR_NUMBER  ;
		MOV.W	  #H'7902,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'0000,R2       ;store F08_ENDS address
		MOV.W	  R2,@ER4	   ;if =0000, not reloaded
		INC.L	  #2,ER4	   ;  ~=0000, already reloaded
		MOV.W	  #H'5E00,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.B	  #7,R1L	   ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @CAL_FUNC_ADDR   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		RTS			   ;
;;;;;;;
C_F08:	    ;	MOV.B	  @STR_NUMBER,R1L
	    ;	CMP.B	  #D'0,R1L
	    ;	BNE	  STACK_OVER
F08_TYPE:	MOV.B	  @SKIP_NUMBER,R1L ;For F08_ENDS diagnostic
		CMP.B	  #D'0,R1L
		BEQ	  F08_ENDS_OVER
		DEC.B	  R1L
		MOV.B	  R1L,@SKIP_NUMBER
F07_S_START:	PUSH.L	  ER4
		MOV.W	  R4,@F08_ENDS_ADDR
		PUSH.L	  ER5
		PUSH.L	  ER6
		DEC.L	  #2,ER6
F07_S_ST2:	DEC.L	  #2,ER6
		SUB.L	  #8,ER4
		CMP.L	  #INST_STR_ADDR,ER6
		BEQ	  F07_S_END
		MOV.W	  @ER6,R2
		AND.W	  #H'FF7B,R2
		CMP.W	  #H'0770,R2
		BNE	  F07_S_ST2:8
		INC.L	  #2,ER4
		MOV.W	  @ER4,R2
		CMP.W	  #H'0000,R2
		BNE	  F07_S_ST3:8
		MOV.W	  @F08_ENDS_ADDR,R2
		MOV.W	  R2,@ER4
		BRA	  F07_S_END:8
F07_S_ST3:	DEC.L	  #2,ER4
		BRA	  F07_S_ST2
F07_S_END:	POP.L	  ER6
		POP.L	  ER5
		POP.L	  ER4
		MOV.W	  #H'4006,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'0000,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		BSET	  FN_BIT	   ;
		MOV.B	  #D'0,R1L         ;;RESET STR_NUMBER
		MOV.B	  R1L,@STR_NUMBER  ;;
		RTS			   ;
C_F09:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F09_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F09_TYPE:	MOV.B	  #9,R1L	   ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE5	   ;
		RTS
;;;;;;;
C_F10:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'4,R1L         ;
		BEQ	  F10_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F10_TYPE:	MOV.B	  #D'10,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE12	   ;
		MOV.B	  #D'0,R1L         ;;RESET STR_NUMBER
		MOV.B	  R1L,@STR_NUMBER  ;;
		RTS			   ;
;;;;;;;;
C_F11:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F11_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F11_TYPE:	MOV.B	  #D'11,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE7	   ;
		RTS			   ;
;;;;;;;;
C_F12:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F12_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F12_TYPE:	MOV.B	  #D'12,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE7	   ;
		RTS			   ;
;;;;;;;;
C_F13:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F13_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F13_TYPE:	MOV.B	  #D'13,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE9	   ;
		RTS			   ;
;;;;;;;;
C_F14:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F14_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F14_TYPE:	MOV.B	  #D'14,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE9	   ;
		RTS			   ;
;;;;;;;;
C_F15:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F15_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F15_TYPE:	MOV.B	  #D'15,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE8	   ;
		RTS			   ;
;;;;;;;;
C_F16:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'3,R1L         ;
		BEQ	  F16_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F16_TYPE:	MOV.B	  #D'16,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE11	   ;
		BSET	  TMR_CNT_OUT	   ;
		MOV.B	  #D'0,R1L         ;;RESET STR_NUMBER
		MOV.B	  R1L,@STR_NUMBER  ;;
		RTS			   ;
;;;;;;;;
C_F17:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F17_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F17_TYPE:	MOV.B	  #D'17,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE7	   ;
		RTS			   ;
;;;;;;;;
C_F18:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F18_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F18_TYPE:	MOV.B	  #D'18,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE9	   ;
		RTS			   ;
;;;;;;;;
C_F19:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F19_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F19_TYPE:	MOV.B	  #D'19,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE9	   ;
		RTS			   ;
;;;;;;;;
C_F20:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F20_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F20_TYPE:	MOV.B	  #D'20,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE7	   ;
		RTS			   ;
;;;;;;;;
C_F21:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F21_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F21_TYPE:	MOV.B	  #D'21,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE7	   ;
		RTS			   ;
;;;;;;;;
C_F22:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F22_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F22_TYPE:	MOV.B	  #D'22,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE7	   ;
		RTS			   ;
;;;;;;;;
C_F23:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F23_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F23_TYPE:	MOV.B	  #D'23,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE50	   ;
		RTS			   ;
;;;;;;;;
C_F24:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F24_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F24_TYPE:	MOV.B	  #D'24,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE50	   ;
		RTS			   ;
;;;;;;;;
C_F25:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F25_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F25_TYPE:	MOV.B	  #D'25,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE5	   ;
		RTS			   ;
;;;;;;;;
C_F26:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F26_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F26_TYPE:	MOV.B	  #D'26,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE5	   ;
		RTS			   ;
;;;;;;;;
C_F27:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F27_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F27_TYPE:	MOV.B	  #D'27,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE7	   ;
		RTS			   ;
;;;;;;;;
C_F28:		BRA	  NOT_FUNCTION	   ;NOT EXIST
;;;;;;;;
C_F29:		BRA	  NOT_FUNCTION	   ;NOT EXIST
;;;;;;;;
C_F30:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F30_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F30_TYPE:	MOV.B	  #D'30,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE7	   ;
		RTS			   ;
;;;;;;;;
C_F31:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F31_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F31_TYPE:	MOV.B	  #D'31,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE7	   ;
		RTS			   ;
;;;;;;;;
C_F32:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F32_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F32_TYPE:	MOV.B	  #D'32,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE9	   ;
		RTS			   ;
;;;;;;;;
C_F33:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F33_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F33_TYPE:	BLD	  #0,R0L	   ;
		BCS	  F33_TWO_WORD:8   ;
F33_THREE_WORD: MOV.B	  #D'33,R1L        ;F33 ADDRESS->F33_THREE
		MOV.B	  R1L,@FN_TYPE	   ;
		BLD	  #2,R0L	   ;;V1.0
		BST	  BITN0 	   ;;
		BLD	  #7,R0L	   ;;
		BST	  BITN1 	   ;;
		JSR	  @C_TYPE7_F33	   ;
		RTS			   ;
F33_TWO_WORD:	MOV.B	  #D'35,R1L        ;F35 ADDRESS->F33_TWO
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE5_F33	   ;
		RTS			   ;
;;;;;;;;
C_F34:	      ; MOV.B	  @STR_NUMBER,R1L  ;
	      ; CMP.B	  #D'1,R1L         ;
	      ; BEQ	  F34_TYPE:8	   ;
	      ; BCS	  STACK_UNDER	   ;
	      ; BRA	  STACK_OVER	   ;
F34_TYPE:     ; MOV.B	  #D'34,R1L        ;
	      ; MOV.B	  R1L,@FN_TYPE	   ;
	      ; JSR	  @C_TYPE4	   ;
		MOV.W	  #H'4006,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'0000,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.B	  R2L,@SCLK_STR    ;FOR CNT,F10,F16
	      ;;BSET	  FN_BIT	   ;
		BSET	  SCLK		   ;
		RTS			   ;
;;;;;;;;				   ;
C_F35:		BRA	  NOT_FUNCTION	   ;
;;;;;;;;				   ;
C_F36:		BRA	  NOT_FUNCTION	   ;
;;;;;;;;				   ;
C_F37:		BRA	  NOT_FUNCTION	   ;
;;;;;;;;				   ;
C_F38:		BRA	  NOT_FUNCTION	   ;
;;;;;;;;				   ;
C_F39:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F39_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F39_TYPE:	MOV.B	  #D'39,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE9	   ;
		RTS			   ;
;;;;;;;;
C_F40:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F40_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F40_TYPE:	MOV.B	  #D'40,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE9	   ;
		RTS			   ;
;;;;;;;;
C_F41:		MOV.W	  #H'0501,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'4004,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'0000,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		RTS			   ;
;;;;;;;;				   ;
C_F42:		MOV.W	  #H'4006,R2       ; LB001-LB128
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'0000,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'0000,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'0000,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.B	  #D'0,R1L         ;;RESET STR_NUMBER
		MOV.B	  R1L,@STR_NUMBER  ;;
		RTS			   ;
;;;;;;;;
C_F43:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F43_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F43_TYPE:	MOV.W	  @ER6,R2	   ;
		SHLR.B	  R2H		   ;
		BST	  #7,R2L	   ;
		AND.W	  #H'0FFF,R2       ;
		SHLL.W	  R2		   ;
		MOV.L	  #LABEL_INST_ADDR,ER3 ;LB001-LB128
		ADD.W	  R2,R3 	   ;00000-00254
		MOV.W	  @ER3,R2	   ;
		CMP.W	  #END_ADDR,R2	   ;;VF.3
		BEQ	  LABEL_ERROR	   ;No label error  V0.E
		MOV.B	  #D'43,R2L        ;
		MOV.B	  R2L,@FN_TYPE	   ;
		JSR	  @C_TYPE6	   ;
		RTS			   ;
;;;;;;;;
C_F44:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F44_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F44_TYPE:	MOV.W	  @ER6,R2	   ;
		SHLR.B	  R2H		   ;
		BST	  #7,R2L	   ;
		AND.W	  #H'0FFF,R2       ;
		SHLL.W	  R2		   ;
		MOV.L	  #LABEL_INST_ADDR,ER3 ;LB001-LB128
		ADD.W	  R2,R3 	   ;00000-00254
		MOV.W	  @ER3,R2	   ;
		CMP.W	  #END_ADDR,R2	   ;;VF.3
		BEQ	  LABEL_ERROR	   ;No label error  V0.E
		MOV.B	  #D'44,R2L        ;
		MOV.B	  R2L,@FN_TYPE	   ;
		JSR	  @C_TYPE5	   ;
		RTS			   ;
;;;;;;;;
C_F45:		MOV.B	  #D'45,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE0	   ;
		RTS			   ;
;;;;;;;;
C_F46:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F46_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F46_TYPE:	MOV.B	  #H'0,R1L         ;;V0.C
		MOV.B	  R1L,@STR_NUMBER  ;;
		MOV.B	  @FOR_NEXT_NUM,R1L;
		CMP.B	  #0,R1L	   ;
		BNE	  FOR_NEXT_ERROR   ;;V0.D
F46_TYPE0:	MOV.B	  #1,R1L	   ;
		MOV.B	  R1L,@FOR_NEXT_NUM;
F46_TYPE1:	MOV.B	  #D'46,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE5	   ;
		RTS			   ;
;;;;;;;;
C_F47:		MOV.B	  @FOR_NEXT_NUM,R1L;
		CMP.B	  #1,R1L	   ;
		BNE	  FOR_NEXT_ERROR   ;
		MOV.B	  #0,R1L	   ;
		MOV.B	  R1L,@FOR_NEXT_NUM;
		MOV.B	  R1L,@STR_NUMBER  ;V0.D
		MOV.B	  #D'47,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE1	   ;
		RTS			   ;
;;;;;;;;
C_F48:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F48_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F48_TYPE:	MOV.B	  #D'48,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE6	   ;
		RTS			   ;
;;;;;;;;
C_F49:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F49_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F49_TYPE:	MOV.B	  #D'49,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE6_1	   ;V0.B
		RTS			   ;
;;;;;;;;
C_F50:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F50_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F50_TYPE:	MOV.B	  #D'50,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE13	   ;
		RTS			   ;
;;;;;;;
C_F51:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F51_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F51_TYPE:	MOV.B	  #D'51,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE7_1	   ;V0.8
		RTS			   ;
;;;;;;;
C_F52:		BLD	  F52_USED	   ;;V0.C
		BCS	  DOUBLS_FUNC_ERR  ;;
		BSET	  F52_USED	   ;;
		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F52_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F52_TYPE:	MOV.B	  #D'52,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE10_1	   ;
		MOV.B	  #H'FF,R1L        ;;
		MOV.B	  R1L,@F52_TENK    ;;
		RTS			   ;
;
C_F53:		BLD	  F53_USED	   ;;V0.C
		BCS	  DOUBLS_FUNC_ERR  ;;
		BSET	  F53_USED	   ;;
		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F53_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F53_TYPE:	MOV.B	  #D'53,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE10_1	   ;
		RTS			   ;
;
C_F54:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F54_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F54_TYPE:	MOV.B	  #D'54,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE15	   ;
		RTS			   ;
;
C_F55:		BLD	  F55_USED	   ;;V0.C
		BCS	  DOUBLS_FUNC_ERR  ;;
		BSET	  F55_USED	   ;;
		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F55_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F55_TYPE:	MOV.B	  #D'55,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE15	   ;
		RTS			   ;
;
C_F56:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F56_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F56_TYPE:	MOV.B	  #D'56,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE10	   ;
		RTS			   ;
;
C_F57:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F57_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F57_TYPE:	MOV.B	  #D'57,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE10	   ;
		RTS			   ;
;
C_F58:		BLD	  F58_USED	   ;;V0.C
		BCS	  DOUBLS_FUNC_ERR  ;;
		BSET	  F58_USED	   ;;
		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F58_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F58_TYPE:	MOV.B	  #D'58,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE9	   ;
		RTS			   ;
;
C_F59:		BLD	  F59_USED	   ;;V0.C
		BCS	  DOUBLS_FUNC_ERR  ;;
		BSET	  F59_USED	   ;;
		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F59_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F59_TYPE:	MOV.B	  #D'59,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE9	   ;
		RTS			   ;
;
C_F60:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F60_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F60_TYPE:	MOV.B	  #D'60,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE16	   ;
		RTS			   ;
;
C_F61:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F61_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F61_TYPE:	MOV.B	  #D'61,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE16	   ;
		RTS			   ;
;					   ;
C_F62:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F62_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F62_TYPE:	MOV.B	  #D'62,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE10	   ;
		RTS			   ;
;					   ;
C_F63:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F63_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F63_TYPE:	MOV.B	  #D'63,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE10	   ;
		RTS			   ;
;;NEW ADD FOR RTD AND TMC
C_F64:		MOV.B	  @STR_NUMBER,R1L  ;V1.61 start
		CMP.B	  #D'1,R1L         ;
		BEQ	  F64_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F64_TYPE:	MOV.B	  #D'64,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE9	   ;
		RTS			   ;
;
C_F65:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F65_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F65_TYPE:	MOV.B	  #D'65,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE9	   ;
		RTS			   ;
;
C_F66:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F66_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F66_TYPE:	MOV.B	  #D'66,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE9	   ;
		RTS			   ;
;
C_F67:		MOV.B	  @STR_NUMBER,R1L  ;
		CMP.B	  #D'1,R1L         ;
		BEQ	  F67_TYPE:8	   ;
		BCS	  STACK_UNDER	   ;
		BRA	  STACK_OVER	   ;
F67_TYPE:	MOV.B	  #D'67,R1L        ;
		MOV.B	  R1L,@FN_TYPE	   ;
		JSR	  @C_TYPE9	   ;
		RTS			   ;V1.61    end
;
FUNC_TABLE     .DATA.W	 C_F00
	       .DATA.W	 C_F01
	       .DATA.W	 C_F02
	       .DATA.W	 C_F03
	       .DATA.W	 C_F04
	       .DATA.W	 C_F05
	       .DATA.W	 C_F06
	       .DATA.W	 C_F07
	       .DATA.W	 C_F08	   ;C_F08 to test F45_RET
	       .DATA.W	 C_F09
	       .DATA.W	 C_F10
	       .DATA.W	 C_F11	   ;C_F11 to test F42_LABEL
	       .DATA.W	 C_F12
	       .DATA.W	 C_F13	   ;C_F13 to test F43_JMP
	       .DATA.W	 C_F14	   ;C_F14 to test F44_CALL
	       .DATA.W	 C_F15
	       .DATA.W	 C_F16
	       .DATA.W	 C_F17
	       .DATA.W	 C_F18
	       .DATA.W	 C_F19
	       .DATA.W	 C_F20
	       .DATA.W	 C_F21
	       .DATA.W	 C_F22
	       .DATA.W	 C_F23
	       .DATA.W	 C_F24
	       .DATA.W	 C_F25
	       .DATA.W	 C_F26
	       .DATA.W	 C_F27
	       .DATA.W	 C_F28
	       .DATA.W	 C_F29
	       .DATA.W	 C_F30
	       .DATA.W	 C_F31
	       .DATA.W	 C_F32
	       .DATA.W	 C_F33
	       .DATA.W	 C_F34
	       .DATA.W	 C_F35	 ; NOP
	       .DATA.W	 C_F36	 ; NOP
	       .DATA.W	 C_F37	 ; NOP
	       .DATA.W	 C_F38	 ; NOP
	       .DATA.W	 C_F39
	       .DATA.W	 C_F40
	       .DATA.W	 C_F41
	       .DATA.W	 C_F42
	       .DATA.W	 C_F43
	       .DATA.W	 C_F44
	       .DATA.W	 C_F45
	       .DATA.W	 C_F46
	       .DATA.W	 C_F47
	       .DATA.W	 C_F48
	       .DATA.W	 C_F49
	       .DATA.W	 C_F50
	       .DATA.W	 C_F51
	       .DATA.W	 C_F52
	       .DATA.W	 C_F53
	       .DATA.W	 C_F54
	       .DATA.W	 C_F55
	       .DATA.W	 C_F56
	       .DATA.W	 C_F57
	       .DATA.W	 C_F58
	       .DATA.W	 C_F59
	       .DATA.W	 C_F60
	       .DATA.W	 C_F61
	       .DATA.W	 C_F62
	       .DATA.W	 C_F63
	       .DATA.W	 C_F64 ;V1.61
	       .DATA.W	 C_F65 ;V1.61
	       .DATA.W	 C_F66 ;V1.61
	       .DATA.W	 C_F67 ;V1.61
;
;;;;;;;; SOLVER START ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
F00_SUB:       MOV.B	 @INT_KIND,R2L		 ;
	       CMP.B	 #H'88,R2L               ;
	       BNE	 F00_SUB1:8		 ;
	       MOV.B	 #H'99,R2L               ;
	       MOV.B	 R2L,@INT_KIND		 ;
F00_SUB1:      JMP	 @F45_SUB		 ;
;						 ;
F01_SUB:       BIAND	 #MCS,R1L		 ;
	       BST	 #2,R1H 		 ;
F01_JCS_JUG:   BTST	 #JCS,R1L		 ;No change
	       BNE	 F01_RET		 ;
F01_SKIP_JUG:  BTST	 #FUN_SKIP,R1L		 ;
	       BNE	 F01_RET		 ;
F01_GO:        BLD	 #2,R1H 		 ;
	       BCC	 MCS_RESET		 ;
	       BCLR	 #MCS,R1L		 ;
	       RTS				 ;
MCS_RESET:     BSET	 #MCS,R1L		 ;
F01_RET:       RTS				 ;
;						 ;
F02_SUB:       BCLR	 #MCS,R1L		 ;
	       RTS				 ;
;
F03_SUB:       BIAND	 #MCS,R1L		 ;
	       BST	 #2,R1H 		 ;
F03_JCS_JUG:   BTST	 #JCS,R1L		 ;
	       BNE	 F03_RET		 ;
F03_SKIP_JUG:  BTST	 #FUN_SKIP,R1L		 ;
	       BNE	 F03_RET		 ;
F03_GO:        BLD	 #2,R1H 		 ;
	       BCC	 JCS_RESET		 ;
	       BSET	 #JCS,R1L		 ;
	       RTS				 ;
JCS_RESET:     BCLR	 #JCS,R1L		 ;
F03_RET:       RTS				 ;
;
F04_SUB:       BCLR	 #JCS,R1L		 ;
	       RTS				 ;
;
F05_SUB:       BTST	 #JCS,R1L		 ;;V0.4 NEW ADDED
	       BNE	 F05_RET:8		 ;;V0.4
	       BIAND	 #MCS,R1L		 ;;V0.4
	       BST	 #2,R1H 		 ;Push ACC
	       BAND	 #1,R1H 		 ;b1*ACC->ACC'
	       BST	 #3,R1H 		 ;Push ACC'
	       BLD	 #2,R1H 		 ;
	       BST	 #1,R1H 		 ;
	       MOV.L	 @ER7,ER4		 ;
	       SUB.W	 #5,R4			 ;
	       MOV.B	 R1H,@ER4		 ;
	       BLD	 #3,R1H 		 ;
	       BCS	 F05_GO:8		 ;
	       RTS				 ;
F05_GO:        BCLR	 #2,R1H 		 ;
F05_RET:       RTS				 ;
;						 ;
F06_SUB:       BTST	 #JCS,R1L		 ;;V0.4 NEW ADDED
	       BNE	 F05_RET:8		 ;;V0.4
	       BIAND	 #MCS,R1L		 ;;V0.4
	       BST	 #2,R1H 		 ;Push ACC
	       BILD	 #2,R1H 		 ;not ACC
	       BAND	 #1,R1H 		 ;b1*-ACC->ACC'
	       BST	 #3,R1H 		 ;Push ACC'
	       BLD	 #2,R1H 		 ;
	       BST	 #1,R1H 		 ;
	       MOV.L	 @ER7,ER4		 ;
	       SUB.W	 #5,R4			 ;
	       MOV.B	 R1H,@ER4		 ;
	       BLD	 #3,R1H 		 ;
	       BCS	 F06_GO:8		 ;
	       BCLR	 #2,R1H 		 ;
	       RTS				 ;
F06_GO:        BSET	 #2,R1H 		 ;
	       RTS				 ;
;
F07_SUB:       .EQU	 $			 ;
F07_JCS_JUG:   BTST	 #JCS,R1L		 ;;V0.4
	       BNE	 F07_RET		 ;;V0.4
	       BIAND	 #MCS,R1L		 ;
	       BST	 #2,R1H 		 ;
	       BCC	 F07_RET		 ;
F07_SKIP_JUG:  BTST	 #FUN_SKIP,R1L		 ;
	       BNE	 F07_RET		 ;
F07_GO:        MOV.L	 @ER7,ER3		 ;
	       MOV.W	 R2,R3			 ;
	       MOV.L	 ER3,@ER7		 ;
F07_RET:       RTS				 ;

F08_SUB:       RTS		      ;;Pseudo instruction
;
F09_SUB:
F09_JCS_JUG:   BTST	 #JCS,R1L		 ;;V0.4
	       BNE	 F09_RET		 ;;
	       BIAND	 #1,R1H
	       BST	 #3,R1H
	       BLD	 #2,R1H
	       BST	 #1,R1H
	       MOV.L	 @ER7,ER4
	       SUB.W	 #13,R4
	       MOV.B	 R1H,@ER4
	       BLD	 #3,R1H
	       BCS	 F09_SKIP_JUG:8
	       BLD	 #ONLS,R1H     ;R1L->R1H
	       BOR	 FOR_NEXT
	       BAND	 #2,R1H
	       BCC	 F09_RET
F09_SKIP_JUG:  BTST	 #FUN_SKIP,R1L
	       BNE	 F09_RET
F09_GO:        BLD	 #4,R1H
	       BCS	 F09_WORD
	       CMP.W	 #WORD_RANGE,R2
	       BCS	 F09_GO_RELAY
	       INC.L	 #1,ER2
F09_GO_RELAY:  MOV.B	 @ER2,R3L
	       ROTR.B	 R3L
	       ROTR.B	 R3L
	       ROTR.B	 R3L
	       ROTR.B	 R3L
	       MOV.B	 R3L,@ER2
	       RTS
F09_WORD:      CMP.W	 #WORD_RANGE,R2
	       BCC	 F09_WORD_DATA
	       MOV.B	 @ER2,R3L
	       INC.L	 #1,ER2
	       MOV.B	 @ER2,R3H
	       MOV.B	 R3L,@ER2
	       DEC.L	 #1,ER2
	       MOV.B	 R3H,@ER2
	       RTS
F09_WORD_DATA: MOV.W	 @ER2,R3
	       MOV.B	 R3L,R4L
	       MOV.B	 R3H,R3L
	       MOV.B	 R4L,R3H
	       MOV.W	 R3,@ER2
F09_RET        RTS


;
F10_SUB:
F10_JCS_JUG:   BTST	 #JCS,R1L	    ;;V0.4
	       BNE	 F10_RET	    ;;V0.4
	       BLD	 #7,R0L
	       BIAND	 #MCS,R1L
	       BST	 #0,R1H
	       BIAND	 #1,R1H
	       BST	 #3,R1H
	       BLD	 #0,R1H
	       BST	 #1,R1H
	       MOV.L	 @ER7,ER4
	       SUB.W	 #D'13,R4
	       MOV.B	 R1H,@ER4
;F10_SKIP_JUG:	BTST	  #FUN_SKIP,R1L
;		BNE	  F10_RET
F10_TR_RS_JUG: BLD	 #2,R1H
	       BCS	 F10_RESET
	       BLD	 #3,R1H
	       BCS	 F10_GO:8
	       BLD	 #ONLS,R1H
	       BOR	 FOR_NEXT
	       BAND	 #0,R1H
	       BCC	 F10_RET_RESETF
F10_GO:        MOV.W	 #0,R3
	       BLD	 #4,R1H
	       BCS	 F10W_GO
	       CMP.W	 #WORD_RANGE,R2 	 ;judge if X,Y,C
	       BCS	 F10_D_RELAY:8		 ;if relay, xfer high/low byte
	       INC.L	 #1,ER2
F10_D_RELAY:   MOV.B	 @ER2,R3L
	       BLD	 #5,R0L
	       BCS	 F10_ROTXL
F10_ROTXR:     BLD	 #6,R0L
	       ROTXR.B	 R3L
	       MOV.B	 R3L,@ER2
	       MOV.L	 #SC041_ADDR,ER2
	       BST	 #1,@ER2		 ;C0242 CARRY
	       BIST	 #0,@ER2		 ;C0241 NON-CARRY
	       BRA	 F10_JUG_ZERO
F10_ROTXL:     BLD	 #6,R0L
	       ROTXL.B	 R3L
	       MOV.B	 R3L,@ER2
	       MOV.L	 #SC041_ADDR,ER2
	       BST	 #1,@ER2		 ;C0242 CARRY
	       BIST	 #0,@ER2		 ;C0241 NON-CARRY
F10_JUG_ZERO:  CMP.B	 #0,R3L
	       BNE	 F10_ZERO_RS
	       BSET	 #2,@ER2
	       RTS
F10_ZERO_RS:   BCLR	 #2,@ER2
	       RTS
;
F10W_GO:       CMP.W	 #WORD_RANGE,R2 	 ;judge if X,Y,C
	       BCC	 F10W_D_DATA:8		 ;if relay, xchg high/low byte
	       MOV.B	 @ER2,R3L
	       INC.L	 #1,ER2
	       MOV.B	 @ER2,R3H
F10W_D_RELAY:  BLD	 #5,R0L
	       BCS	 F10W_ROTXL_R
F10W_ROTXR_R:  BLD	 #6,R0L
	       ROTXR.W	 R3
	       MOV.B	 R3H,@ER2
	       DEC.L	 #1,ER2
	       MOV.B	 R3L,@ER2
	       BRA	 F10W_ROTOK:8
F10W_ROTXL_R:  BLD	 #6,R0L
	       ROTXL.W	 R3
	       MOV.B	 R3H,@ER2
	       DEC.L	 #1,ER2
	       MOV.B	 R3L,@ER2
	       BRA	 F10W_ROTOK:8
F10W_D_DATA:   MOV.W	 @ER2,R3
	       BLD	 #5,R0L
	       BCS	 F10W_ROTXL
F10W_ROTXR:    BLD	 #6,R0L
	       ROTXR.W	 R3
	       MOV.W	 R3,@ER2
	       BRA	 F10W_ROTOK:8
F10W_ROTXL:    BLD	 #6,R0L
	       ROTXL.W	 R3
	       MOV.W	 R3,@ER2
F10W_ROTOK:    MOV.L	 #SC041_ADDR,ER2
	       BST	 #1,@ER2		 ;C0242 CARRY
	       BIST	 #0,@ER2		 ;C0241 NON-CARRY
F10W_JUG_ZERO: CMP.W	 #0,R3
	       BNE	 F10W_ZERO_RS
	       BSET	 #2,@ER2
	       RTS
F10W_ZERO_RS:  BCLR	 #2,@ER2
	       RTS
F10_RESET:     MOV.W	 #0,R3
	       BLD	 #4,R1H
	       BCS	 F10W_RESET
	       CMP.W	 #WORD_RANGE,R2
	       BCS	 F10_RESET1:8
	       INC.L	 #1,ER2
F10_RESET1:    MOV.B	 R3L,@ER2
	       BRA	 F10_FLAG_RS

F10W_RESET:    MOV.B	 R3L,@ER2
	       INC.L	 #1,ER2
	       MOV.B	 R3L,@ER2
F10_FLAG_RS:   MOV.B	 @SC041_ADDR,R2L
	       AND.B	 #H'F0,R2L
	       MOV.B	 R2L,@SC041_ADDR
F10_RET:       RTS
F10_RET_RESETF: JSR	 @FLAG_RESET
		RTS

;
F11_SUB:       .EQU	 $
F11_JCS_JUG:   BTST	 #JCS,R1L
	       BNE	 F11_RET
	       BLD	 #2,R1H
	       BST	 #1,R1H
	       MOV.L	 @ER7,ER4
	       SUB.W	 #21,R4
	       MOV.B	 R1H,@ER4
	       BLD	 #3,R1H
	       BCS	 F11_GO:8
	       BLD	 #ONLS,R1H	 ;R1L->R1H
	       BOR	 FOR_NEXT
	       BAND	 #2,R1H
	       BCC	 F11_RET
F11_GO:        BLD	 #5,R1H
	       BCS	 F11D_GO
	       BLD	 #4,R1H
	       BCS	 F11W_GO
F11B_GO:       CMP.W	 #WORD_RANGE,R2
	       BCS	 F11B_XYC:8
	       INC.W	 #1,R2
F11B_XYC:      BLD	 #6,R1H
	       BCC	 F11B_DATA_M:8
	       CMP.W	 #WORD_RANGE,R3
	       BCS	 F11B_R_M:8
	       INC.W	 #1,R3
F11B_R_M:      MOV.B	 @ER3,R4L
	       MOV.B	 R4L,R3L
F11B_DATA_M:   MOV.B	 R3L,@ER2
	       BRA	 F11_RET
;;
F11W_GO:       BLD	 #6,R1H
	       BCC	 F11W_D_JUG:8
	       CMP.W	 #WORD_RANGE,R3
	       BCC	 F11W_REG_M:8
	       MOV.B	 @ER3,R4L
	       INC.W	 #1,R3
	       MOV.B	 @ER3,R4H
	       BRA	 F11W_REG_M1:8
F11W_REG_M:    MOV.W	 @ER3,R4
F11W_REG_M1:   MOV.W	 R4,R3
F11W_D_JUG:    CMP.W	 #WORD_RANGE,R2
	       BCC	 F11W_DATA_M:8
	       MOV.B	 R3L,@ER2
	       INC.L	 #1,ER2
	       MOV.B	 R3H,@ER2
	       BRA	 F11_RET
F11W_DATA_M:   MOV.W	 R3,@ER2
	       BLD	 HSC_MODE		 ;;V1.6
	       BCC	 F11_RET
HSC1_CHK:      CMP.L	 #V1001_ADDR,ER2	 ;;V1.6
	       BNE	 HSC2_CHK:8
	       BSET	 HSC1_SET
HSC2_CHK:      CMP.L	 #V1003_ADDR,ER2	 ;;V1.6
	       BNE	 HSC3_CHK:8
	       BSET	 HSC2_SET
HSC3_CHK:      CMP.L	 #V1005_ADDR,ER2	 ;;V1.6
	       BNE	 HSC4_CHK:8
	       BSET	 HSC3_SET
HSC4_CHK:      CMP.L	 #V1007_ADDR,ER2	 ;;V1.6
	       BNE	 F11_RET
	       BSET	 HSC4_SET
	       BRA	 F11_RET
;;
F11D_GO:       BLD	 #6,R1H
	       BCC	 F11D_D_JUG
	       CMP.W	 #WORD_RANGE,R3
	       BCC	 F11D_V_JUG:8
F11D_R_JUG:    CMP.W	 #WORD_RANGE,R2   ;1
	       BCC	 F11D_R_R_V:8
F11D_R_R_R:    MOV.W	 @ER3,R4
	       MOV.W	 R4,@ER2
	       INC.L	 #2,ER3
	       INC.L	 #2,ER2
	       MOV.W	 @ER3,R4
	       MOV.W	 R4,@ER2
	       BRA	 F11_RET
F11D_R_R_V:    MOV.B	 @ER3,R4L
	       INC.L	 #1,ER3
	       MOV.B	 @ER3,R4H
	       INC.L	 #1,ER3
	       MOV.W	 R4,@ER2
	       INC.L	 #2,ER2
	       MOV.B	 @ER3,R4L
	       INC.L	 #1,ER3
	       MOV.B	 @ER3,R4H
	       MOV.W	 R4,@ER2
	       BRA	 F11_RET
F11D_V_JUG:    CMP.W	 #WORD_RANGE,R2   ;2
	       BCC	 F11D_R_R_R:8
	       BRA	 F11D_R_R_V:8
F11D_D_JUG:    CMP.W	 #WORD_RANGE,R2   ;3
	       BCC	 F11D_D_D_V
F11D_D_D_R:    MOV.B	 R3L,@ER2
	       INC.L	 #1,ER2
	       MOV.B	 R3H,@ER2
	       INC.L	 #1,ER2
	       MOV.B	 #0,R3L
	       MOV.B	 R3L,@ER2
	       INC.L	 #1,ER2
	       MOV.B	 R3L,@ER2
	       BRA	 F11_RET
F11D_D_D_V:    MOV.W	 R3,@ER2
	       INC.L	 #2,ER2
	       MOV.W	 #0,R3
	       MOV.W	 R3,@ER2
F11_RET:       BLD	 #2,R1H
	       RTS
;
F12_SUB:       .EQU	 $
F12_JCS_JUG:   BTST	 #JCS,R1L
	       BNE	 F12_RET
	       BLD	 #2,R1H
	       BST	 #1,R1H
	       MOV.L	 @ER7,ER4
	       SUB.W	 #21,R4
	       MOV.B	 R1H,@ER4
	       BLD	 #3,R1H
	       BCS	 F12_GO:8
	       BLD	 #ONLS,R1H	 ;R1L->R1H
	       BOR	 FOR_NEXT
	       BAND	 #2,R1H
	       BCC	 F12_RET_RESETF
F12_GO:        BLD	 #5,R1H 	 ;V0.B
	       BCS	 F12D_GO	 ;
	       BLD	 #4,R1H 	 ;
	       BCS	 F12W_GO	 ;
F12B_GO:       BLD	 #6,R1H
	       BCC	 F12B_DATA
F12B_REG:      CMP.W	 #WORD_RANGE,R3
	       BCS	 F12B_REG_R:8
	       INC.W	 #1,R3
F12B_REG_R:    MOV.B	 @ER3,R4L
	       CMP.B	 #H'64,R4L
	       BCS	 F12B_REG_R0:8
	       BRA	 F12_NON_BCD
F12B_REG_R0:   JSR	 @HEX_BCD_B
F12B_REG_R1:   CMP.W	 #WORD_RANGE,R2
	       BCS	 F12B_REG_R2
	       INC.W	 #1,R2
F12B_REG_R2:   MOV.B	 R4L,@ER2
	       BRA	 F12_RET
F12B_DATA:     CMP.W	 #H'64,R3
	       BCS	 F12B_DATA1:8
	       BRA	 F12_NON_BCD
F12B_DATA1:    MOV.B	 R3L,R4L
	       JSR	 @HEX_BCD_B
	       BRA	 F12B_REG_R1:8
F12W_GO:       BLD	 #6,R1H
	       BCC	 F12W_DATA
F12W_REG:      CMP.W	 #WORD_RANGE,R3
	       BCC	 F12W_REG_V
	       MOV.B	 @ER3,R4L
	       INC.W	 #1,R3
	       MOV.B	 @ER3,R4H
	       BRA	 F12W_REG_V1:8
F12W_REG_V:    MOV.W	 @ER3,R4
F12W_REG_V1:   CMP.W	 #H'2710,R4
	       BCS	 F12W_REG_V2:8
	       BRA	 F12_NON_BCD
F12W_REG_V2:   JSR	 @HEX_BCD_W
	       CMP.W	 #WORD_RANGE,R2
	       BCC	 F12W_REG_V3:8
	       MOV.B	 R4L,@ER2
	       INC.W	 #1,R2
	       MOV.B	 R4H,@ER2
	       BRA	 F12_RET
F12W_REG_V3:   MOV.W	 R4,@ER2
	       BRA	 F12_RET
F12W_DATA:     CMP.W	 #H'2710,R3
	       BCS	 F12W_DATA1:8
	       BRA	 F12_NON_BCD:8
F12W_DATA1:    MOV.W	 R3,R4
	       JSR	 @HEX_BCD_W
	       CMP.W	 #WORD_RANGE,R2
	       BCC	 F12W_DATA2:8
	       MOV.B	 R4L,@ER2
	       INC.W	 #1,R2
	       MOV.B	 R4H,@ER2
	       BRA	 F12_RET:8
F12W_DATA2:    MOV.W	 R4,@ER2
	       BRA	 F12_RET:8
F12_NON_BCD:   MOV.L	 #SC041_ADDR,ER4
	       BSET	 #3,@ER4
	       BRA	 F12_RET1:8
F12_RET:       MOV.L	 #SC041_ADDR,ER4
	       BCLR	 #3,@ER4
F12_RET1:      BLD	 #2,R1H
	       RTS
F12_RET_RESETF: JSR	 @FLAG_RESET
	       BLD	#2,R1H
	       RTS
F12D_GO:       BLD	 #6,R1H
	       BCC	 F12D_DATA
F12D_REG:      CMP.W	 #WORD_RANGE,R3
	       BCC	 F12D_REG_V:8
	       MOV.B	 @ER3+,R4L
	       MOV.B	 @ER3+,R4H
	       MOV.B	 @ER3+,R5L
	       MOV.B	 @ER3+,R5H
	       MOV.W	 R5,E4
	       BRA	 F12D_REG_V1:8
F12D_REG_V:    MOV.W	 @ER3,R4
	       INC.L	 #2,ER3
	       MOV.W	 @ER3,E4
F12D_REG_V1:   CMP.L	 #H'5F5E100,ER4
	       BCS	 F12D_REG_V2:8
	       BRA	 F12_NON_BCD
F12D_REG_V2:   JSR	 @HEX_BCD_D
	       CMP.W	 #WORD_RANGE,R2
	       BCC	 F12D_REG_V3:8
	       MOV.B	 R4L,@ER2
	       INC.W	 #1,R2
	       MOV.B	 R4H,@ER2
	       INC.W	 #1,R2
	       MOV.W	 E4,R4
	       MOV.B	 R4L,@ER2
	       INC.W	 #1,R2
	       MOV.B	 R4H,@ER2
	       BRA	 F12_RET
F12D_REG_V3:   MOV.W	 R4,@ER2
	       INC.W	 #2,R2
	       MOV.W	 E4,@ER2
	       BRA	 F12_RET
F12D_DATA:     MOV.W	 R3,R4
	       JSR	 @HEX_BCD_W
	       CMP.W	 #WORD_RANGE,R2
	       BCC	 F12D_DATA2:8
	       MOV.B	 R4L,@ER2
	       INC.W	 #1,R2
	       MOV.B	 R4H,@ER2
	       INC.W	 #1,R2
	       MOV.W	 #0,R4
	       MOV.W	 R4,@ER2
	       BRA	 F12_RET:8
F12D_DATA2:    MOV.W	 R4,@ER2
	       MOV.W	 #0,R4
	       INC.W	 #2,R2
	       MOV.W	 R4,@ER2
	       BRA	 F12_RET
;;
;;;;;;;;;; PID function : PID mode+Auto tuning mode 
;;;;; Adding Error Signal for Auto tuning fail   if  (Set value-initial condition)<0.6*(Set value-0)

F13_SUB:        BIAND  #MCS,R1L
	       BST	 #2,R1H
	       BCC	 F13_RET
F13_JCS_JUG:   BTST	 #JCS,R1L
	          BNE	 F13_RET
F13_SKIP_JUG:  BTST	 #FUN_SKIP,R1L
		BNE	 F13_RET

;;;;;;;;;;;MAIN SUBROUTINE

F13_AUTO_CHECK:  MOV.B @(D'11:24,ER4),R1L
                                    BTST #2,R1L   ;;; check autotuning mode  or PID mode
                                    BNE  F13_TIME_CHECK2
                                    
                                    MOV.B @(D'75:24,ER4),R1L  ;;; move conditional flag to R1L
		 BTST #4,R1L
		 BNE F13_TIME_CHECK
		 
		 MOV.B @(D'11:24,ER4),R1L   ;;;; check positive logic or negative logic
		 BTST #4,R1L
		 BNE F13_PID_ERROR_CHECK1 ;;; Negative Logic
		 BRA F13_PID_ERROR_CHECK2  ;;; Positive Logic


F13_PID_ERROR_CHECK1:
		 MOV.W #60,R1
		 MOV.W @ER4,R5   ;;; move reference r(n) to R5
		 MOV.W #0,E5
   		 MULXU.W R1,ER5  
	  	 MOV.W #100,R1
		 DIVXU.W R1,ER5  ;;; 0.6*r(n) on R5
		 MOV.W #1600,R1
		 ADD.W R1,R5   ;;; 1600+0.6r(n)
		 MOV.W @ER3,R6  ;;; move y(n) to R6
		 CMP.W  R5,R6
		 BCS  F13_PID_ERROR
		 		
		 MOV.B @(D'75:24,ER4),R1L
		 BSET #4,R1L
		 MOV.B R1L,@(D'75:24,ER4)
		 
		 MOV.B @(D'10:24,ER4),R1L
 	                   BCLR #1,R1L
	                   MOV.B R1L,@(D'10:24,ER4)
		 BRA F13_RET

F13_PID_ERROR_CHECK2:		 
		 MOV.W #60,R1
		 MOV.W @ER4,R5   ;;; move reference r(n) to R5
		 MOV.W #0,E5
   		 MULXU.W R1,ER5  
	  	 MOV.W #100,R1
		 DIVXU.W R1,ER5  ;;; 0.6*(r(n)-0) on R5
		 MOV.W @ER3,R6   ;;; move y(n) to R6
		 CMP.W  R6,R5
		 BCS  F13_PID_ERROR
		 		 		
		 MOV.B @(D'75:24,ER4),R1L
		 BSET #4,R1L
		 MOV.B R1L,@(D'75:24,ER4)
		 MOV.B @(D'10:24,ER4),R1L
 	                   BCLR #1,R1L
	                   MOV.B R1L,@(D'10:24,ER4)
	                   BRA F13_RET

F13_PID_ERROR:  
	                 MOV.B @(D'10:24,ER4),R1L
 	                 BSET #1,R1L
	                 MOV.B R1L,@(D'10:24,ER4)
	                 BRA F13_RET
	                 
F13_TIME_CHECK:  
		 MOV.W @TIME_BASE,R5     ;;; read present counter on R5
		 MOV.W R5,E1	;;;move present counter to E1
		 
		 MOV.B @(D'75:24,ER4),R1L  ;;; move conditional flag to R1L
		 BTST #0,R1L
		 BNE F13_TIME_CHECK2
		 
		 MOV.W E1,@(D'58:24,ER4)  ;;; move counter values to memory as initial timer values
		 MOV.W @ER3,R6  ;;; read initial sensor data  y(0)
		 MOV.W R6,@(D'70:24,ER4)  ;;; move y(0) to memory
		 BRA F13_TIME_CHECK2
		                  
		 
F13_TIME_CHECK2:  MOV.W @TIME_BASE,R5     ;;; read present counter on R5
		 MOV.W R5,E1	;;;move present counter to E1
		 MOV.W @(D'2:24,ER4),R6       ;;; move sample time Ts to R6
		 MOV.W @(D'36:24,ER4),R1     ;;; read previous counter on R1
		 SUB.W  R1,R5    ;;; compute T(new)-T(old) on R5
		 CMP.W R5,R6	;;; compare Ts v.s (Tnew-Told)
		 BCS  F13_TIME_COMPUTE
		 
		 		 
		 ;;;; check if it is relay output mode
		 MOV.B @(D'11:24,ER4),R1L  ;;; move conditional flag to R1L
		 BTST #3,R1L    ;;; check if it is  relay output
		 BNE F13_PID_RELAY_OUT1
		 BRA F13_RET

F13_TIME_COMPUTE: 
		MOV.W E1,@(D'36:24,ER4)   ;;; move present counter to previous counter memory
	            	MOV.B @(D'11:24,ER4),R1L  ;;; move conditional flag to R1L
		BTST #2,R1L	  ;;; check  PID mode or Auto-tuning mode
		BNE  F13_PID_SUB0   ;;; branch to PID mode
		MOV.B @(D'75:24,ER4),R1L
		BTST #0,R1L
		BNE F13_PID_AUTO2
		BSET #0,R1L
		MOV.B R1L,@(D'75:24,ER4)
		MOV.B @(D'11:24,ER4),R1L   ;;;; check positive logic or negative logic
		BTST #4,R1L
		BNE F13_PID_AUTO0  ;;; to compute 0.05*(y(0)-r(n)) and 0.5*(y(0)-r(n))
		BRA F13_PID_AUTO1  ;;; to compute 0.05*(r(n)-y(0)) and 0.5*(r(n)-y(0))
;;; Negative Logic		
F13_PID_AUTO0: 	MOV.W @ER4,R5   ;;; move reference r(n) to R5
		MOV.W @(D'70:24,ER4),R6  ;;; move y(0) to R6
		SUB.W  R5,R6  ;;; compute y(0)-r(n) on R6
		MOV.W #0,E6
		MOV.W #5,R1	
		MULXU.W R1,ER6
		MOV.W #100,R1
		DIVXU.W R1,ER6  ;;; compute 0.05*(y(0)-r(n)) on R6
		MOV.W  R6,@(D'50:24,ER4) ;;;;move 0.05*(y(0)-r(n)) to memory
		MOV.W @ER4,R5   ;;; move reference r(n) to R5
		MOV.W @(D'70:24,ER4),R6  ;;; Read y(0)  on R6
		SUB.W  R5,R6  ;;; compute y(0)-r(n) on R6
		MOV.W #0,E6
		MOV.W #50,R1	
		MULXU.W R1,ER6
		MOV.W #100,R1
		DIVXU.W R1,ER6  ;;; compute 0.5*(y(0)-r(n)) on R6
		MOV.W  R6,@(D'54:24,ER4) ;;; move 0.5*(y(0)-r(n)) to memory
		BRA  F13_PID_AUTO2	
		
;;; Postive Logic
F13_PID_AUTO1:     MOV.W @ER4,R6   ;;; move reference r(n) to R6
		MOV.W @(D'70:24,ER4),R5  ;;; move y(0) to R5
		SUB.W  R5,R6  ;;; compute r(n)-y(0) on R6
		MOV.W #0,E6
		MOV.W #5,R1	
		MULXU.W R1,ER6
		MOV.W #100,R1
		DIVXU.W R1,ER6  ;;; compute 0.05*(r(n)-y(0)) on R6
		MOV.W  R6,@(D'50:24,ER4)  ;;; move 0.05*(r(n)-y(0)) to memory
		MOV.W @ER4,R6   ;;; Move reference r(n) to R6
		MOV.W @(D'70:24,ER4),R5  ;;; Read y(0)
		SUB.W  R5,R6  ;;; compute [r(n)-y(0)] on R6
		MOV.W #0,E6
		MOV.W #50,R1	
		MULXU.W R1,ER6
		MOV.W #100,R1
		DIVXU.W R1,ER6  ;;; compute 0.5*[r(n)-y(0)] on R6
		MOV.W  R6,@(D'54:24,ER4) ;;; move 0.5*[r(n)-y(0)] to memory
		BRA  F13_PID_AUTO2

F13_PID_AUTO2:  	MOV.B @(D'11:24,ER4),R1L
		BTST #4,R1L
		BNE F13_PID_AUTO3N   ;;; Autotuning mode (Negative logic)
		BRA F13_PID_AUTO3P    ;;; Autotuning mode (Positive logic)

F13_PID_AUTO3N:   MOV.B @(D'75:24,ER4),R1L  ;;; move conditional flag to R1L
		BTST #1,R1L   ;;; To see if it needs to compare [y(0)-y(n)] with 0.05*[y(0)-r(n)] 
		BNE  F13_PID_AUTO4
		MOV.W @(D'50:24,ER4),R5  ;;; move 0.05*(y(0)-r(n)) to R5
		MOV.W @(D'70:24,ER4),R6  ;;; move y(0) to R6
		SUB.W R5,R6    ;;; compute y(0)-0.05*[y(0)-r(n)]  on R6
		MOV.W @ER3,R5  ;;; move y(n) to R5		
		CMP.W R6,R5  ;;; (y(0)-y(n)) v.s. 0.05*(y(0)-r(n))
		BCS F13_PID_AUTO3_COMP
		BRA F13_PID_AUTO4
		
				
F13_PID_AUTO3P:   MOV.B @(D'75:24,ER4),R1L  ;;; move conditional flag to R1L
		BTST #1,R1L   ;;; To see if it needs to compare [y(n)-y(0)] with 0.05*[r(n)-y(0)]
		BNE   F13_PID_AUTO4
		MOV.W @(D'70:24,ER4),R6  ;;; move y(0) to R6
		MOV.W @(D'50:24,ER4),R5  ;;; move 0.05*(r(n)-y(0)) to R5
		ADD.W R6,R5   ;;;; compute y(0)+0.05*(r(n)-y(0)) on R5
		MOV.W @ER3,R6  ;;; move y(n) to R6
		CMP.W R6,R5  ;;; (y(n)-y(0)) v.s. 0.05*(r(n)-y(0))
		BCS F13_PID_AUTO3_COMP
		BRA F13_PID_AUTO4

F13_PID_AUTO3_COMP:   
		           MOV.W @TIME_BASE,R5  ;;; read present counter to evaluate time-interval
		           MOV.W @(D'58:24,ER4),E5  ;;; read 1st-reading counter value
		           SUB.W E5,R5   ;;; compute time-interval on R5(i.e. Dead time L)
 		           MOV.B @(D'75:24,ER4),R1L  ;;; move conditional flag to R1L
		           BSET #1,R1L
		           MOV.B R1L,@(D'75:24,ER4)
		           
		           MOV.B @(D'11:24,ER4),R1L
		           BTST #4,R1L
		           BNE F13_PID_AUTO3_COMPN   ;;; (Negative logic) Modifiy dead-time
		           
		           ;;; modify dead time
		           MOV.W @ER4,R6   ;;; move reference r(n) to R6
		           MOV.W #0,E5
		           MULXU.W R6,ER5
		           MOV.W @(D'70:24,ER4),R1   ;;; move y(0) to R1
		           SUB.W R1,R6  ;;; compute r(n)-y(0) on R6
		           DIVXU.W R6,ER5  ;;; modified dead time on R5
		           MOV.W R5,@(D'62:24,ER4)   ;;;move Dead Time (L) to memory
		           BRA F13_PID_AUTO4
		           

F13_PID_AUTO3_COMPN:	
           		           ;;; modify dead time
		           MOV.W @ER4,R6   ;;; move reference r(n) to R6
		           MOV.W #4000,E6
		           SUB.W R6,E6  ;;; compute 4000-r(n) on E6
		           MOV.W #0,E5
		           MULXU.W E6,ER5   ;;;;[4000-r(n)]*(L)  on ER5
		           
		           MOV.W @(D'70:24,ER4),R1   ;;; move y(0) to R1
		           SUB.W R6,R1  ;;; compute y(0)-r(n) on R1
		           DIVXU.W R1,ER5  ;;; modified dead time on R5
		           MOV.W R5,@(D'62:24,ER4)   ;;;move Dead Time (L) to memory
		           BRA F13_PID_AUTO4	           

F13_PID_AUTO4:     MOV.B @(D'11:24,ER4),R1L
		BTST #4,R1L
		BNE F13_PID_AUTO4N   ;;; Autotuning mode (negative logic)
		BRA F13_PID_AUTO4P    ;;; Autotuning mode (positive logic)
		
F13_PID_AUTO4N:	MOV.W @(D'54:24,ER4),R5  ;;; move 0.5*(y(0)-r(n)) to R5
		MOV.W @(D'70:24,ER4),R6  ;;; move y(0) to R6
		SUB.W R5,R6    ;;; compute y(0)-0.5*[y(0)-r(n)]  on R6
		MOV.W @ER3,R5  ;;; move y(n) to R5		
		CMP.W R6,R5  ;;; (y(0)-y(n)) v.s. 0.05*(y(0)-r(n))
		BCS F13_PID_AUTO4_COMP
		BRA F13_PID_AUTO_FULL_OUTPUT

F13_PID_AUTO4P:	
		MOV.W @(D'70:24,ER4),R6  ;;; move y(0) to R6
		MOV.W @(D'54:24,ER4),R5  ;;; move 0.5*(r(n)-y(0)) to R5
		ADD.W R6,R5   ;;;; compute y(0)+0.5*(r(n)-y(0)) on R5
		MOV.W @ER3,R6  ;;; move y(n) to R6
		CMP.W R6,R5  ;;; (y(n)-y(0)) v.s. 0.05*(r(n)-y(0))
		BCS F13_PID_AUTO4_COMP
		BRA F13_PID_AUTO_FULL_OUTPUT
				
F13_PID_AUTO4_COMP:  
		           MOV.W @TIME_BASE,R5  ;;; read present counter to evaluate Time-interval
		           MOV.W @(D'58:24,ER4),E5  ;;; read 1st-reading counter value
		           SUB.W E5,R5   ;;;compute time-interval (L+deltaT) on R5
		           
		           MOV.B @(D'11:24,ER4),R1L
		           BTST #4,R1L
		           BNE F13_PID_AUTO4_COMPN   ;;; (Negative logic) Modifiy rising time
		           
		           ;;;   modify rising time
		           MOV.W @ER4,R6   ;;; move reference r(n) to R6
		           MOV.W #0,E5
		           MULXU.W R6,ER5  ;;;r(n)*(L+deltaT) on ER5
		           MOV.W @(D'70:24,ER4),R1   ;;; move y(0) to R1
		           SUB.W R1,R6  ;;; compute r(n)-y(0) on R6
		           DIVXU.W R6,ER5  ;;; [r(n)*(L+deltaT)]/[r(n)-y(0)]on R5		    		           		           
		       
		           MOV.W @(D'62:24,ER4),R6  ;;;move Dead-Time (L) on R6
		           SUB.W R6,R5  ;;; compute modified Delta T on R5
		           				       
		           MOV.W R5,@(D'66:24,ER4)   ;;;move rising-time (delta T) to memory
		            
		           ;;; Determine the type of PID controller
		           MOV.B @(D'11:24,ER4),R1L
		           BTST #1,R1L   
		           BNE F13_PID_PARA_COMP3   ;;; PID control
		           BTST #0,R1L   
		           BNE F13_PID_PARA_COMP2   ;;; PI control
		           BRA F13_PID_PARA_COMP1   ;;; P control


F13_PID_AUTO4_COMPN:	
    		          MOV.W @ER4,R6   ;;; move reference r(n) to R6
		           MOV.W #4000,E6
		           SUB.W R6,E6  ;;; compute 4000-r(n) on E6
		           MOV.W #0,E5
		           MULXU.W E6,ER5   ;;; [4000-r(n)]*(L+deltaT) on ER5
		           
		           MOV.W @(D'70:24,ER4),R1   ;;; move y(0) to R1
		           SUB.W R6,R1  ;;; compute [y(0)-r(n)] on R1
		           DIVXU.W R1,ER5  ;;; [4000-r(n)]*(L+deltaT)/[y(0)-r(n)] on R5	    		           		           
		       
		           MOV.W @(D'62:24,ER4),R6  ;;;move Dead-Time (L) on R6
		           SUB.W R6,R5  ;;; compute modified Delta T on R5
		           MOV.W R5,@(D'66:24,ER4)   ;;;move rising-time (delta T) to memory
		            
		           ;;; Determine the type of PID controller
		           MOV.B @(D'11:24,ER4),R1L
		           BTST #1,R1L   
		           BNE F13_PID_PARA_COMP3   ;;; PID control
		           BTST #0,R1L   
		           BNE F13_PID_PARA_COMP2   ;;; PI control
		           BRA F13_PID_PARA_COMP1   ;;; P control	           

F13_PID_AUTO_FULL_OUTPUT:
		MOV.B @(D'11:24,ER4),R1L
		BTST #3,R1L
		BNE  F13_PID_AUTO_FULL_OUTPUT1  ;;;full  relay output
		MOV.W #4000,R1   ;;; u(n)=4000
		MOV.W R1,@ER2   ;;; full scale output 
		BRA F13_RET

F13_PID_AUTO_FULL_OUTPUT1:
		 MOV.B @(D'10:24,ER4),R1L
		 BSET #0,R1L
		 MOV.B R1L,@(D'10:24,ER4)  
		 BRA F13_RET	


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;		     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;     P- Controller     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 

F13_PID_PARA_COMP1:    MOV.W @(D'66:24,ER4),R6  ;;; move rising-time (delta T) to R6
		           MOV.W #0,E6
		           MOV.W #569,R5
		           MULXU.W R5,ER6 ;;;  569*(delta T)  
		           MOV.W @(D'62:24,ER4),R5  ;;; move dead-time (L) to R5
		           DIVXU.W R5,ER6   ;;; compute Kp on R6
		           MOV.W R6,@(D'76:24,ER4)  ;;; move Kp to memory
		           MOV.W #0,R6
		           MOV.W R6,@(D'78:24,ER4) ;;; D-gain set 0
		           MOV.W #32767,R6
		           MOV.W R6,@(D'80:24,ER4) ;;; I-gain set 32767	
		           MOV.B @(D'11:24,ER4),R1L  ;;; rewrite the condition flag
		           BSET #2,R1L	
	 	           MOV.B R1L,@(D'11:24,ER4)  
	 	           
	 	           MOV.W @(D'76:24,ER4),R6   ;;; move Auto-mode P gain to PID-mode P gain
		           MOV.W R6,@(D'4:24,ER4)
		           MOV.W @(D'78:24,ER4),R6   ;;; move Auto-mode D gain to PID-mode D gain
		           MOV.W R6,@(D'6:24,ER4)
		           MOV.W @(D'80:24,ER4),R6   ;;; move Auto-mode I gain to PID-mode I gain
		           MOV.W R6,@(D'8:24,ER4)
	 	           BRA F13_RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;     PI- Controller       ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

F13_PID_PARA_COMP2:    MOV.W @(D'66:24,ER4),R6  ;;; move rising-time (delta T) to R6
		           MOV.W #0,E6
		           MOV.W #512,R5
		           MULXU.W R5,ER6 ;;;  512*(delta T)  		     		         		           
		           MOV.W @(D'62:24,ER4),R5  ;;; move dead-time (L) to R5
		           DIVXU.W R5,ER6   ;;; compute  Kp  on R6
		           MOV.W R6,@(D'76:24,ER4)  ;;; move Kp to memory	
		            ;;;; Start I-gain computing
		           MOV.W @(D'62:24,ER4),R6  ;;; move dead-time (L) to R6		     		       		     		           
		           MOV.W #0,E6
		            ;;;MOV.W #768,R1   ;;;;;;Tuning Parameters 
		           MOV.W #14000,R1 
		           MULXU.W R1,ER6		           
		           MOV.W @(D'2:24,ER4),R1  ;;; move (Ts) on R1		
		           DIVXU.W R1,ER6   ;;; compute 768(L/Ts) on R6
		           
		           ;;;; Check I-gain value
		           MOV.W #32000,R1 
		           CMP.W R1,R6
		           BCS  F13_PID_PARA_COMP21
		           
		           MOV.W #32767,R1
		           CMP.W R6,R1
		           BCS  F13_PID_PARA_COMP22
		           ;;;; D-gain=0
		           MOV.W #0,R1
		           MOV.W R1,@(D'78:24,ER4) ;;; D-gain set 0
		           MOV.B @(D'11:24,ER4),R1L  ;;; rewrite the condition flag
		           BSET #2,R1L	
	 	           MOV.B R1L,@(D'11:24,ER4)  
	 	           
	 	           MOV.W @(D'76:24,ER4),R6   ;;; move Auto-mode P gain to PID-mode P gain
		           MOV.W R6,@(D'4:24,ER4)
		           MOV.W @(D'78:24,ER4),R6   ;;; move Auto-mode D gain to PID-mode D gain
		           MOV.W R6,@(D'6:24,ER4)
		           MOV.W @(D'80:24,ER4),R6   ;;; move Auto-mode I gain to PID-mode I gain
		           MOV.W R6,@(D'8:24,ER4)	
	 	           BRA F13_RET
		           

F13_PID_PARA_COMP21:  MOV.W #32600,R6		           		           
                                               MOV.W R6,@(D'80:24,ER4)  ;;; move 32600  to memory
		            ;;;; D-gain=0
 		           MOV.W #0,R1
		           MOV.W R1,@(D'78:24,ER4) ;;; D-gain set 0
		           MOV.B @(D'11:24,ER4),R1L  ;;; rewrite the condition flag
		           BSET #2,R1L	
	 	           MOV.B R1L,@(D'11:24,ER4)
	 	           
	 	           MOV.W @(D'76:24,ER4),R6   ;;; move Auto-mode P gain to PID-mode P gain
		           MOV.W R6,@(D'4:24,ER4)
		           MOV.W @(D'78:24,ER4),R6   ;;; move Auto-mode D gain to PID-mode D gain
		           MOV.W R6,@(D'6:24,ER4)
		           MOV.W @(D'80:24,ER4),R6   ;;; move Auto-mode I gain to PID-mode I gain
		           MOV.W R6,@(D'8:24,ER4)
	 	             
	                             BRA F13_RET

F13_PID_PARA_COMP22:  MOV.W #32700,R6		           		           
                                                  MOV.W R6,@(D'80:24,ER4)  ;;; move 32700  to memory
		            ;;;; D-gain=0
 		           MOV.W #0,R1
		           MOV.W R1,@(D'78:24,ER4) ;;; D-gain set 0
		           MOV.B @(D'11:24,ER4),R1L  ;;; rewrite the condition flag
		           BSET #2,R1L	
	 	           MOV.B R1L,@(D'11:24,ER4)  
	 	           
	 	           MOV.W @(D'76:24,ER4),R6   ;;; move Auto-mode P gain to PID-mode P gain
		           MOV.W R6,@(D'4:24,ER4)
		           MOV.W @(D'78:24,ER4),R6   ;;; move Auto-mode D gain to PID-mode D gain
		           MOV.W R6,@(D'6:24,ER4)
		           MOV.W @(D'80:24,ER4),R6   ;;; move Auto-mode I gain to PID-mode I gain
		           MOV.W R6,@(D'8:24,ER4)
	                             BRA F13_RET	                            
	                          	                            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   PID- Controller ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

F13_PID_PARA_COMP3:    ;;;; Start P-gain computing
		           MOV.W @(D'66:24,ER4),R6  ;;; move rising-time (delta T) to R6
		           MOV.W #0,E6
		           MOV.W #683,R5
		           MULXU.W R5,ER6    ;;; 683*(delta T)  		      
		           MOV.W @(D'62:24,ER4),R5  ;;; move dead-time (L) to R5
		           DIVXU.W R5,ER6   ;;; compute  683(delta T)/L on R6
		           MOV.W R6,@(D'76:24,ER4)  ;;; move Kp to memory
		           
		           ;;;; Start D-gain computing
		           MOV.W @(D'62:24,ER4),R6  ;;; move dead-time (L) to R6
 		           MOV.W #0,E6
 		           MOV.W #128,R5
		           MULXU.W R5,ER6
 		           MOV.W @(D'2:24,ER4),R1  ;;; move (Ts) on R1	
 		           DIVXU.W R1,ER6   ;;; compute 128(L/Ts) on R6
		           MOV.W  R6,@(D'78:24,ER4) ;;; move (Td/Ts)=128(L/Ts) to memory
	  	           
	  	           ;;;;	Start I-gain computing
	  	          MOV.W @(D'62:24,ER4),R6  ;;; move dead-time (L) to R6
		          MOV.W #0,E6
		          ;;;;MOV.W #512,R1   ;;;;;;Tuning Parameters 
		          MOV.W #14000,R1    
		          MULXU.W R1,ER6		        
		          MOV.W @(D'2:24,ER4),R1  ;;; move  Ts on R1		      
		          DIVXU.W R1,ER6   ;;; compute 512(L/Ts) on R6
		         ;;;; Check I-gain value
		          MOV.W #32000,R1 
		          CMP.W R1,R6
		          BCS  F13_PID_PARA_COMP31
		           
		          MOV.W #32767,R1
		          CMP.W R6,R1
		          BCS  F13_PID_PARA_COMP32
		       
		          MOV.W R6,@(D'80:24,ER4)  ;;; move (Ti/Ts)=512(L/Ts) to memory                                          
          		          MOV.B @(D'11:24,ER4),R1L  ;;; Rewrite the condition flag
		          BSET #2,R1L	
	 	          MOV.B R1L,@(D'11:24,ER4)  
	 	          
	 	          MOV.W @(D'76:24,ER4),R6   ;;; move Auto-mode P gain to PID-mode P gain
		           MOV.W R6,@(D'4:24,ER4)
		           MOV.W @(D'78:24,ER4),R6   ;;; move Auto-mode D gain to PID-mode D gain
		           MOV.W R6,@(D'6:24,ER4)
		           MOV.W @(D'80:24,ER4),R6   ;;; move Auto-mode I gain to PID-mode I gain
		           MOV.W R6,@(D'8:24,ER4)
	                            BRA F13_RET
		         
F13_PID_PARA_COMP31: MOV.W #32700,R6		           		           
                                              MOV.W R6,@(D'80:24,ER4)  ;;; (Ti/Ts) output 32700
		           MOV.B @(D'11:24,ER4),R1L  ;;; Rewrite the condition flag
		           BSET #2,R1L	
	 	           MOV.B R1L,@(D'11:24,ER4)  
	 	           
	 	           MOV.W @(D'76:24,ER4),R6   ;;; move Auto-mode P gain to PID-mode P gain
		           MOV.W R6,@(D'4:24,ER4)
		           MOV.W @(D'78:24,ER4),R6   ;;; move Auto-mode D gain to PID-mode D gain
		           MOV.W R6,@(D'6:24,ER4)
		           MOV.W @(D'80:24,ER4),R6   ;;; move Auto-mode I gain to PID-mode I gain
		           MOV.W R6,@(D'8:24,ER4)
	                            BRA F13_RET

F13_PID_PARA_COMP32: MOV.W #32750,R6		           		           
                                              MOV.W R6,@(D'80:24,ER4) ;;; (Ti/Ts) output 32750
 		           MOV.B @(D'11:24,ER4),R1L  ;;; Rewrite the condition flag
		           BSET #2,R1L	
	 	           MOV.B R1L,@(D'11:24,ER4)  
	 	           
	 	           MOV.W @(D'76:24,ER4),R6   ;;; move Auto-mode P gain to PID-mode P gain
		           MOV.W R6,@(D'4:24,ER4)
		           MOV.W @(D'78:24,ER4),R6   ;;; move Auto-mode D gain to PID-mode D gain
		           MOV.W R6,@(D'6:24,ER4)
		           MOV.W @(D'80:24,ER4),R6   ;;; move Auto-mode I gain to PID-mode I gain
		           MOV.W R6,@(D'8:24,ER4)
	                             BRA F13_RET	                            		        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	PID Mode	     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;		        
		                                              
F13_PID_SUB0:	MOV.B @(D'75:24,ER4),R1L  ;;; move conditional flag to R1L
		BTST #3,R1L
		BNE F13_PID_SUB1
		MOV.L #2000,ER6	               ;;; initialize u(n-1)
		MOV.L ER6,@(D'20:24,ER4)
		BSET #3,R1L
		MOV.B R1L,@(D'75:24,ER4)
		BRA F13_PID_SUB1

F13_PID_SUB1:
	    	MOV.W @(D'8:24,ER4),R1  ;;; move (Ti/Ts) to R1 		
	    	MOV.W #32767,E1   ;;; move 32767 to E1
		SUB.W R1,E1  ;;; move 32767-(Ti/Ts) to E1
		MOV.W E1,@(D'12:24,ER4)  ;;; move result to memory
		
		;;;;;;; Compute A0
		MOV.W @(D'6:24,ER4),R1   ;;; move (Td/Ts) to R1
		ADD.W E1,R1    ;;; Compute (Td/Ts)+(32767-Ti/Ts)
		ADD.W #256,R1
		MOV.W @(D'4:24,ER4),R6     ;;; move Kp to R6
		MULXU.W R1,ER6   ;;; perform Kp*(1+Td/Ts+Ts/Ti)  32bits data
		MOV.L ER6,@(D'24:24,ER4)    ;;;move result A0 to memory
		
		;;;;;;; Compute A1
		MOV.W @(D'6:24,ER4),R1   ;;; move (Td/Ts) to R1
		MOV.W R1,E1  ;;; 
		ADD.W E1,R1  ;;;  compute (Td/Ts)*2
		ADD.W #256,R1  ;;; compute (1+2*(Td/Ts))
		MOV.W @(D'4:24,ER4),R6     ;;; move Kp to R6 
		MULXU.W R1,ER6   ;;; perform Kp*(1+2*Td/Ts)
		MOV.L ER6,@(D'28:24,ER4)  ;;;move result A1 to memory
		;;;; Compute A2
		MOV.W @(D'6:24,ER4),R1   ;;; move (Td/Ts) to R1
		MOV.W @(D'4:24,ER4),R6     ;;; move Kp to R6 
		MULXU.W R1,ER6   ;;; perform Kp*(Td/Ts)
		MOV.L ER6,@(D'32:24,ER4)  ;;;move result A2 to memory
		BRA F13_PID_SUB2
		
F13_PID_SUB2:	;;;;;; Compute A0*e(n)
		MOV.B @(D'11:24,ER4),R1L  ;;; move conditional flag to R1L
		BTST #4,R1L
		BNE F13_PID_SUB2N  ;;; Negative logic e(n)=y(n)-r(n)
		BRA F13_PID_SUB2P  ;;; Positive logic e(n)=r(n)-y(n)


F13_PID_SUB2P:	MOV.W @ER3,R1   ;;; move y(n) to R1
		MOV.W @ER4,R6   ;;; move reference r(n) to R6
		SUB.W R1,R6   ;;; Compute e(n)=r(n)-y(n) to obtain signed 16 bits data
		MOV.W R6,@(D'14:24,ER4)  ;;; move e(n) to memory
		BRA F13_PID_SUB21

F13_PID_SUB2N:	MOV.W @ER3,R6   ;;; move y(n) to R6
		MOV.W @ER4,R1   ;;; move reference r(n) to R1
		SUB.W R1,R6   ;;; compute e(n)=y(n)-r(n) to obtain signed 16 bits data
		MOV.W R6,@(D'14:24,ER4)  ;;; move e(n) to memory 	
		BRA F13_PID_SUB21

F13_PID_SUB21:	MOV.L @(D'24:24,ER4),ER1   ;;; move A0 to ER1
		PUSH.L ER2
		BCLR #7,R2L
		MOV.L ER1,ER1
		BPL  F13_MULS1
		NEG.L ER1
		BNOT #7,R2L
F13_MULS1:    	MOV.W R6,R6
		BPL  F13_MULS2
		NEG.W R6
		BNOT #7,R2L
F13_MULS2:	MOV.W E1,R5
		MULXU.W R6,ER1
		MULXU.W R6,ER5
		ADD.W R5,E1
		BCC  F13_MULS3
		INC.W #1,E5
F13_MULS3:	BTST #7,R2L
		BEQ F13_MULS4
		NOT.L ER1
		NOT.W E5   
		INC.L #1,ER1
		BNE  F13_MULS4
		INC.W #1,E5
F13_MULS4:    	POP.L ER2
		MOV.L  ER1,@(D'38:24,ER4)   ;;;move A0*e(n)  to memory
		MOV.W E5,@(D'42:24,ER4)
		;;;; Compute A1*e(n-1)
		MOV.W @(D'16:24,ER4),R6  ;;; move e(n-1) to R6
		MOV.L @(D'28:24,ER4),ER1  ;;; move A1 to ER1
		PUSH.L ER2	;;;; perform A1*e(n-1)
		BCLR #7,R2L
		MOV.L ER1,ER1
		BPL  F13_MULS5
		NEG.L ER1
		BNOT #7,R2L
F13_MULS5:    	MOV.W R6,R6
		BPL  F13_MULS6
		NEG.W R6
		BNOT #7,R2L
F13_MULS6:	MOV.W E1,R5
		MULXU.W R6,ER1
		MULXU.W R6,ER5
		ADD.W R5,E1
		BCC  F13_MULS7
		INC.W #1,E5
F13_MULS7:	BTST #7,R2L
		BEQ F13_MULS8
		NOT.L ER1
		NOT.W E5   
		INC.L #1,ER1
		BNE  F13_MULS8
		INC.W #1,E5
F13_MULS8:    	POP.L ER2
		MOV.L  ER1,@(D'44:24,ER4)   ;;;move A1*e(n-1)  to memory
		MOV.W E5,@(D'48:24,ER4)
		;;;; Compute A2*e(n-2)
		MOV.W @(D'18:24,ER4),R6  ;;; move e(n-2) to R6
		MOV.L @(D'32:24,ER4),ER1  ;;; move A2 to ER1
		PUSH.L ER2	;;;; perform A2*e(n-2)
		BCLR #7,R2L
		MOV.L ER1,ER1
		BPL  F13_MULS9
		NEG.L ER1
		BNOT #7,R2L
F13_MULS9:    	MOV.W R6,R6
		BPL  F13_MULS10
		NEG.W R6
		BNOT #7,R2L
F13_MULS10:	MOV.W E1,R5
		MULXU.W R6,ER1
		MULXU.W R6,ER5
		ADD.W R5,E1
		BCC  F13_MULS11
		INC.W #1,E5
F13_MULS11:	BTST #7,R2L
		BEQ F13_MULS12
		NOT.L ER1
		NOT.W E5   
		INC.L #1,ER1
		BNE  F13_MULS12
		INC.W #1,E5
F13_MULS12:    	POP.L ER2
		 ;;;;;; To perform  A0*e(n)+A2*e(n-2)  48 bits addition
		MOV.W E5,R5;
		PUSH.L  ER2    
		MOV.L  @(D'38:24,ER4),ER6   ;;;move A0*e(n)  to ER6 and R2
		MOV.W @(D'42:24,ER4),R2
		ADD.L  ER6,ER1
		ADDX.B R2L,R5L
		ADDX.B R2H,R5H
		 ;;; To perform  A0*e(n)+A2*e(n-2)-A1*e(n-1)  48 bits subtraction
		MOV.L  @(D'44:24,ER4),ER6   ;;;move A1*e(n-1)  to ER6 and R2
		MOV.W @(D'48:24,ER4),R2
		SUB.L ER6,ER1
		SUBX.B R2L,R5L
		SUBX.B R2H,R5H  ;;;Result=A0*e(n)+A2*e(n-2)-A1*e(n-1) on ER1 and R5
		POP.L ER2
		;;;;;;;; To perform truncation to obatin 32 bits data
		MOV.W E1,R1 
		MOV.W R5,E1  ;;; Result=A0*e(n)+A2*e(n-2)-A1*e(n-1) on ER1 
		;;;; Compute u(n)
		MOV.L @(D'20:24,ER4),ER5  ;;; move u(n-1) to ER5  (32bits data)
		MOV.L #2000,ER6
		SUB.L ER6,ER5  ;;; u(n-1)-2000
		BRA F13_PID_COM1
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Compute output value  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					
F13_PID_COM1:	ADD.L ER5,ER1  ;;; compute u(n)
		BRA F13_PID_SUB3
		
F13_PID_SUB3:	;;;; Judge u(n) to see if saturation or not
		MOV.W #2000,R6
		MOV.W #0,E6
		ADD.L ER6,ER1   ;;; u(n)+2000				
		MOV.L ER1,@(D'20:24,ER4)   ;;; update u(n-1) on memory
		BMI  F13_PID_ZERO_OUT
		MOV.W #4000,R6
		MOV.W #0,E6
		CMP.L  ER1,ER6    ;;; u(n)+2000  v.s.  4000
		BCS  F13_PID_FULL_OUT
		BRA F13_PID_OUT
F13_PID_ZERO_OUT: MOV.W #0,R1   ;;; u(n)=0
		   BRA F13_PID_OUT
F13_PID_FULL_OUT: MOV.W #4000,R1   ;;; u(n)=4000
		   BRA F13_PID_OUT
F13_PID_OUT:  MOV.B @(D'11:24,ER4),R5L  ;;; move conditional flag to R5L
	           BTST #3,R5L
	           BNE F13_PID_RELAY_OUT
	           MOV.W R1,@ER2  
	           ;;;; update some data	        
	          MOV.W @(D'16:24,ER4),R1   
	          MOV.W R1,@(D'18:24,ER4)  ;;; update e(n-2)
	          MOV.W @(D'14:24,ER4),R1  
	          MOV.W R1,@(D'16:24,ER4)  ;;; update e(n-1)
	          BRA F13_RET		

F13_PID_RELAY_OUT: 
	           MOV.W #2000,R6
	           CMP.W R6,R1   ;;; to see if u(n) is within 2000-4000
	           BCS  F13_PID_RELAY_OUT_ZERO
	           SUB.W R6,R1 ;;; u(n)-2000		
	           MOV.W @(D'2:24,ER4),R6   ;;; move Ts to R6
	           MOV.W #0,E6
	           MULXU.W R1,ER6    
	           MOV.W #2000,R1
	           DIVXU.W  R1,ER6   ;;; compute counts for relay output(high) on R6
	           MOV.W R6,@(D'72:24,ER4)  ;;; move counts to memory
 	           ;;;; update some data	        
	          MOV.W @(D'16:24,ER4),R1   
	          MOV.W R1,@(D'18:24,ER4)  ;;; Update e(n-2)
	          MOV.W @(D'14:24,ER4),R1  
	          MOV.W R1,@(D'16:24,ER4)  ;;; Update e(n-1)
	          BRA F13_PID_RELAY_OUT1

F13_PID_RELAY_OUT_ZERO: 
		          MOV.W #0,R6
		          MOV.W R6,@(D'72:24,ER4)  ;;; move counts to memory
		            ;;;; update some data	        
		          MOV.W @(D'16:24,ER4),R1   
		          MOV.W R1,@(D'18:24,ER4)  ;;; Update e(n-2)
		          MOV.W @(D'14:24,ER4),R1  
		          MOV.W R1,@(D'16:24,ER4)  ;;; Update e(n-1)
		          BRA F13_PID_RELAY_OUT1
F13_PID_RELAY_OUT1:  
		 MOV.W @TIME_BASE,R5     ;;; read present counter on R5
		 MOV.W @(D'36:24,ER4),R1     ;;; read previous counter on R1
		 SUB.W  R1,R5    ;;; compute T(new)-T(old) on R5
		 MOV.W @(D'72:24,ER4),R6     ;;; read relay output counts on R6
		 CMP.W R5,R6	;;; compare relay output counts with  (Tnew-Told)	
		 BCS F13_PID_RELAY_OUT2
		 ;;;; relay output high
		 MOV.B @(D'10:24,ER4),R1L
		 BSET #0,R1L
		 MOV.B R1L,@(D'10:24,ER4)   
		 BRA F13_RET	
F13_PID_RELAY_OUT2:
		 ;;;; relay output low
		 MOV.B @(D'10:24,ER4),R1L
		 BCLR #0,R1L
		 MOV.B R1L,@(D'10:24,ER4)  
		 BRA F13_RET	
F13_RET:       RTS
F13_RET_RESETF: JSR	 @FLAG_RESET
		RTS
;
;
	       
	       

;;;
F14_SUB:       .EQU	 $
F14_JCS_JUG:   BTST	 #JCS,R1L
	       BNE	 F14_RET
	       MOV.L	 @ER7,ER5
	       SUB.W	 #D'29,R5
	       MOV.B	 R1H,@ER5
	       BLD	 #3,R1H
	       BCS	 F14_GO:8
	       BLD	 #ONLS,R1H	   ;R1L->R1H
	       BOR	 FOR_NEXT
	       BAND	 #2,R1H
	       BCC	 F13_RET_RESETF    ;;V0.8 BUG MODIFY
F14_GO:        BLD	 #5,R1H
	       BCS	 F14D_GO
	       BLD	 #4,R1H
	       BCS	 F14W_GO
F14B_GO:       JSR	 @CAL_S1_S2	  ;
	       MOV.B	 @R3_DATA,R3L	  ;
	       MOV.B	 @R4_DATA,R4L	  ;
	       MOV.B	 #0,R4H 	  ;
	       MOV.B	 #0,R3H 	  ;
	       SUB.W	 R4,R3		  ;
	       BCC	 F14B_CHK_FLAG:8  ;
	       JSR	 @FLAG_CARRY	  ;
	       NOT.B	 R3L		  ;;
	       ADD.B	 #1,R3L 	  ;;
	       BRA	 F14B_SAVE:8	  ;
F14B_CHK_FLAG: CMP.W	 #0,R3		  ;
	       BNE	 F14B_NON_CARRY:8 ;
	       JSR	 @FLAG_ZERO	  ;
	       BRA	 F14B_SAVE:8	  ;
F14B_NON_CARRY: JSR	 @FLAG_NON_CARRY  ;
F14B_SAVE:     CMP.W	 #WORD_RANGE,R2   ;
	       BCS	 F14B_D_R:8	  ;
	       INC.W	 #1,R2		  ;
F14B_D_R:      MOV.B	 R3L,@ER2	  ;
	       RTS			  ;
F14W_GO:       JSR	 @CAL_S1_S2
	       MOV.W	 @R3_DATA,R3
	       MOV.W	 @R4_DATA,R4
	       MOV.W	 #0,E3
	       MOV.W	 #0,E4
	       MOV.W	 #H'000F,E2              ;;V0.B
	       SUB.L	 ER4,ER3
	       BCC	 F14W_CHK_FLAG:8  ;
	       NOT.W	 R3		  ;;
	       ADD.W	 #1,R3		  ;;
	       JSR	 @FLAG_CARRY	  ;
	       BRA	 F14W_SAVE:8	  ;
F14W_CHK_FLAG: CMP.L	 #0,ER3 	  ;
	       BNE	 F14W_NON_CARRY:8 ;
	       JSR	 @FLAG_ZERO	  ;
	       BRA	 F14W_SAVE:8	  ;
F14W_NON_CARRY: JSR	 @FLAG_NON_CARRY  ;
F14W_SAVE:     CMP.W	 #WORD_RANGE,R2   ;
	       BCC	 F14W_D_R:8
	       MOV.B	 R3L,@ER2
	       INC.W	 #1,R2
	       MOV.B	 R3H,@ER2
	       MOV.W	 #H'000F,E3
	       MOV.W	 #H'000F,E4
	       RTS
F14W_D_R:      MOV.W	 R3,@ER2
	       MOV.W	 #H'000F,E3
	       MOV.W	 #H'000F,E4
	       RTS
F14D_GO:       JSR	 @CAL_S1_S2
	       MOV.L	 @R4_DATA,ER4
	       MOV.L	 @R3_DATA,ER3
	       SUB.L	 ER4,ER3
	       BCC	 F14D_NO_CARRY:8
	       NOT.L	 ER3
	       ADD.L	 #1,ER3
	       JSR	 @FLAG_CARRY
	       BRA	 F14D_GO1:8
F14D_NO_CARRY: CMP.L	 #0,ER3
	       BNE	 F14D_NO_CARRY1:8
	       JSR	 @FLAG_ZERO
	       BRA	 F14D_GO1:8
F14D_NO_CARRY1: JSR	 @FLAG_NON_CARRY
F14D_GO1:      CMP.W	 #WORD_RANGE,R2
	       BCC	 F14D_V_M:8
F14D_R_M:      MOV.B	 R3L,@ER2
	       INC.L	 #1,ER2
	       MOV.B	 R3H,@ER2
	       INC.L	 #1,ER2
	       MOV.W	 E3,R4
	       MOV.B	 R4L,@ER2
	       INC.L	 #1,ER2
	       MOV.B	 R4H,@ER2
	       MOV.W	 #H'000F,E3
	       MOV.W	 E3,E4
	       RTS
F14D_V_M:      MOV.W	 R3,@ER2
	       INC.L	 #2,ER2
	       MOV.W	 E3,@ER2
	       MOV.W	 #H'000F,E3
	       MOV.W	 E3,E4
	       RTS
F14_RET:       RTS
;
F15_SUB:       BLD	 #2,R1H
	       BCC	 F15_RESET_FLAG
	       BLD	 #5,R1H 		 ;;V0.B
	       BCS	 F15D_GO		 ;;
	       BLD	 #4,R1H 		 ;;
	       BCS	 F15W_GO		 ;;
F15B_GO:       CMP.W	 #WORD_RANGE,R2
	       BCS	 F15B_XYC:8
	       INC.W	 #1,R2
F15B_XYC:      BLD	 #6,R1H
	       BCC	 F15B_DATA_M:8
	       CMP.W	 #WORD_RANGE,R3
	       BCS	 F15B_R_M:8
	       INC.W	 #1,R3
F15B_R_M:      MOV.B	 @ER3,R3L
F15B_DATA_M:   MOV.B	 @ER2,R2L
	       CMP.B	 R2L,R3L
	       BNE	 F15B_NON_EQU:8
	       JSR	 @FLAG_ZERO
	       BRA	 F15_RET
F15B_NON_EQU:  BCS	 F15B_CARRY:8
	       JSR	 @FLAG_CARRY		 ;;V0.B
	       BRA	 F15_RET
F15B_CARRY:    JSR	 @FLAG_NON_CARRY	 ;;V0.B
	       BRA	 F15_RET
;;
F15W_GO:       BLD	 #6,R1H
	       BCC	 F15W_D_JUG:8
	       CMP.W	 #WORD_RANGE,R3
	       BCC	 F15W_REG_M:8		 ;;V0.B
	       MOV.B	 @ER3,R4L
	       INC.W	 #1,R3
	       MOV.B	 @ER3,R4H
	       BRA	 F15W_REG_M1:8
F15W_REG_M:    MOV.W	 @ER3,R4
F15W_REG_M1:   MOV.W	 R4,R3

F15W_D_JUG:    CMP.W	 #WORD_RANGE,R2
	       BCC	 F15W_DATA_M:8
	       MOV.B	 @ER2,R4L
	       INC.W	 #1,R2
	       MOV.B	 @ER2,R4H
	       BRA	 F15W_DATA_M1:8
F15W_DATA_M:   MOV.W	 @ER2,R4
F15W_DATA_M1:  MOV.W	 R4,R2			 ;;V0.B BIG BUG
	       CMP.W	 R2,R3			 ;;ORIGINAL LABEL IN THIS LINE
	       BNE	 F15W_NON_EQU:8
	       JSR	 @FLAG_ZERO
	       BRA	 F15_RET
F15W_NON_EQU:  BCS	 F15W_CARRY:8
	       JSR	 @FLAG_CARRY	     ;;V0.B
	       BRA	 F15_RET
F15W_CARRY:    JSR	 @FLAG_NON_CARRY     ;;V0.B
	       BRA	 F15_RET
F15_RET:       BLD	 #2,R1H
	       RTS
F15_RESET_FLAG: .EQU	 $
	       JSR	 @FLAG_RESET
	       BLD	 #2,R1H
	       RTS
F15D_GO:       BLD	 #6,R1H
	       BCS	 F15D_GO1:8		 ;;V0.C
	       MOV.W	 #0,E3			 ;;V0.C
	       BRA	 F15D_D_JUG:8		 ;;R3=DATA
F15D_GO1:      CMP.W	 #WORD_RANGE,R3
	       BCC	 F15D_REG_M:8		 ;;V0.B F15D_D_JUG->F15D_REG_M
	       MOV.B	 @ER3+,R4L
	       MOV.B	 @ER3+,R4H
	       MOV.B	 @ER3+,R5L
	       MOV.B	 @ER3+,R5H
	       MOV.W	 R5,E4
	       BRA	 F15D_REG_M1:8
F15D_REG_M:    MOV.W	 @ER3,R4
	       INC.W	 #2,R3
	       MOV.W	 @ER3,E4
F15D_REG_M1:   MOV.L	 ER4,ER3

F15D_D_JUG:    CMP.W	 #WORD_RANGE,R2
	       BCC	 F15D_DATA_M:8
	       MOV.B	 @ER2+,R4L
	       MOV.B	 @ER2+,R4H
	       MOV.B	 @ER2+,R5L
	       MOV.B	 @ER2+,R5H
	       MOV.W	 R5,E4
	       BRA	 F15D_DATA_M1:8
F15D_DATA_M:   MOV.W	 @ER2,R4
	       INC.W	 #2,R2
	       MOV.W	 @ER2,E4
F15D_DATA_M1:  MOV.L	 ER4,ER2		 ;;V0.C
	       CMP.L	 ER2,ER3		 ;ER2:S1, ER3:S2
	       BNE	 F15D_NON_EQU:8
	       JSR	 @FLAG_ZERO		 ;S1=S2
	       BRA	 F15D_RET
F15D_NON_EQU:  BCS	 F15D_CARRY:8		 ;
	       JSR	 @FLAG_CARRY		 ;S1<S2
	       BRA	 F15D_RET
F15D_CARRY:    JSR	 @FLAG_NON_CARRY	 ;S1>S2
F15D_RET:      MOV.W	 #H'000F,E2
	       MOV.W	 #H'000F,E3
	       MOV.W	 #H'000F,E4
	       BLD	 #2,R1H
	       RTS
;
F16_SUB:
F16_JCS_JUG:   BTST	 #JCS,R1L
	       BNE	 UD_CNT_RET
	       MOV.W	 R3,@R3_BUFFER
	       BIAND	 #1,R1H
	       BST	 #3,R1H
	       BLD	 #0,R1H
	       BST	 #1,R1H
	       MOV.L	 @ER7,ER4
	       SUB.W	 #D'23,R4
	       MOV.B	 R1H,@ER4
;F16_SKIP_JUG:	BTST	  #FUN_SKIP,R1L
;		BNE	  UD_CNT_RET
F16_TR_RS_JUG: BLD	 #2,R1H
	       BCS	 UD_CNT_RESET
	       BLD	 #3,R1H
	       BCS	 UD_CNT_GO:8
	       BLD	 #ONLS,R1H	;NEW
	       BOR	 FOR_NEXT
	       BAND	 #0,R1H 	;
	       BCC	 UD_CNT_RET1	;
UD_CNT_GO:     BLD	 #6,R0L
	       BCS	 UP_CNT:8
DOWN_CNT:      MOV.W	 @ER2,R4
	       CMP.W	 #0,R4
	       BEQ	 UD_CNT_SET
	       DEC.W	 #1,R4
	       BNE	 DOWN_CNT_C:8
	       MOV.W	 R4,@ER2
	       BRA	 UD_CNT_SET
DOWN_CNT_C:    MOV.W	 R4,@ER2
	       BRA	 UD_CNT_RET
UP_CNT:        MOV.W	 @ER2,R4
	       BLD	 #6,R1H
	       BCC	 UP_CNT_DATA:8
	       MOV.W	 @ER3,R5
	       MOV.W	 R5,R3
UP_CNT_DATA:   CMP.W	 R4,R3
	       BEQ	 UD_CNT_SET
	       INC.W	 #1,R4
	       CMP.W	 R3,R4
	       BCS	 UP_CNT_C:8
	       MOV.W	 R3,@ER2
	       BRA	 UD_CNT_SET
UP_CNT_C:      MOV.W	 R4,@ER2
	       MOV.L	 @ER7,ER4
	       SUB.W	 #D'23,R4
	       BCLR	 #4,@ER4	  ;7->4
	       BCLR	 #4,R1H 	  ;7->4
UD_CNT_RET:    BLD	 #4,R1H 	  ;7->4
	       RTS
UD_CNT_RET1:   BLD	 #6,R0L
	       BCS	 UD_CNT_RET2
	       MOV.W	 @ER2,R4
	       CMP.W	 #0,R4
	       BEQ	 UD_CNT_SET:8
UD_CNT_NO_ACT: MOV.L	 @ER7,ER4
	       SUB.W	 #D'23,R4
	       BCLR	 #4,@ER4	  ;7->4
	       BCLR	 #4,R1H 	  ;7->4
	       RTS
UD_CNT_RET2:   MOV.W	 @ER2,R4
	       BLD	 #6,R1H
	       BCC	 UD_CNT_RET3:8
	       MOV.W	 @ER3,R5
	       MOV.W	 R5,R3
UD_CNT_RET3:   CMP.W	 R3,R4
	       BEQ	 UD_CNT_SET:8
	       BRA	 UD_CNT_NO_ACT
UD_CNT_SET:    MOV.L	 @ER7,ER4
	       SUB.W	 #D'23,R4
	       BSET	 #4,@ER4	  ;7->4
	       BSET	 #4,R1H 	  ;7->4
	       RTS
UD_CNT_RESET:  BLD	 #6,R0L
	       BCS	 UP_CNT_RESET
DN_CNT_RESET:  MOV.W	 @R3_BUFFER,R3
	       BLD	 #6,R1H
	       BCC	 UD_RESET_OK:8
	       MOV.W	 @ER3,R4
	       MOV.W	 R4,R3
	       BRA	 UD_RESET_OK:8
UP_CNT_RESET:  MOV.W	 #0,R3
UD_RESET_OK:   MOV.W	 R3,@ER2
	       MOV.L	 @ER7,ER4
	       SUB.W	 #D'23,R4
	       BCLR	 #4,@ER4	  ;NEW ADDED
	       BCLR	 #4,R1H 	  ;7->4
	       RTS
;
F18_SUB:       .EQU	 $
F18_JCS_JUG:   BTST	 #JCS,R1L
	       BNE	 F18_RET
	       MOV.L	 @ER7,ER5
	       SUB.W	 #D'29,R5
	       MOV.B	 R1H,@ER5
	       BLD	 #3,R1H
	       BCS	 F18_GO:8
	       BLD	 #ONLS,R1H	   ;R1L->R1H
	       BOR	 FOR_NEXT	   ;
	       BAND	 #2,R1H 	   ;
	       BCC	 F13_RET_RESETF
F18_GO:        BLD	 #5,R1H
	       BCS	 F18D_GO
F18W_GO:       MOV.W	 #H'000F,E3        ;
	       MOV.W	 #H'000F,E4        ;
	       MOV.W	 @ER3,R5	   ;
	       BLD	 #6,R1H 	   ;
	       BCS	 F18W_GO_V:8	   ;
	       MOV.W	 R4,R3		   ;
	       BRA	 F18W_GO_V1:8	   ;
F18W_GO_V:     MOV.W	 @ER4,R3	   ;
F18W_GO_V1:    MOV.W	 #0,E5
	       MULXU.W	 R3,ER5
	       MOV.W	 R5,@ER2
	       INC.W	 #2,R2
	       MOV.W	 E5,@ER2
	       MOV.L	 #SC041_ADDR,ER2	 ;;V0.B
	       BCLR	 #3,@ER2		 ;;
F18_RET:       RTS
;
F18D_GO:       MOV.W	 #H'000F,E3
	       MOV.W	 #H'000F,E4
	       MOV.W	 @ER3+,R5
	       MOV.W	 @ER3,E5
	       MOV.L	 ER5,ER3
	       BLD	 #6,R1H
	       BCS	 F18D_GO_V:8
	       MOV.W	 R4,R5
	       MOV.W	 #0,E5
	       BRA	 F18D_GO_V1:8
F18D_GO_V:     MOV.W	 @ER4+,R5
	       MOV.W	 @ER4,E5
F18D_GO_V1:    MOV.L	 ER5,ER4		 ;;ER3*ER4
	       MOV.W	 #0,E6
	       MOV.W	 R3,R6
	       MOV.W	 E3,R5
	       MOV.W	 E4,E5
	       MULXU.W	 R4,ER3
	       MULXU.W	 R5,ER4
	       MULXU.W	 E5,ER6
	       MULXU.W	 E5,ER5
	       ADD.L	 ER6,ER4
	       BCC	 MUL2:8
	       INC.W	 #1,E5
MUL2:	       ADD.W	 R4,E3
	       BCC	 MUL3:8
	       INC.L	 #1,ER5
MUL3:	       ADD.W	 E4,R5
	       BCC	 MUL4:8
	       INC.W	 #1,E5
MUL4:	       CMP.L	 #0,ER5
	       BNE	 F18_19_ERR
	       MOV.W	 R3,@ER2
	       INC.W	 #2,R2
	       MOV.W	 E3,@ER2
	       MOV.L	 #SC041_ADDR,ER6
	       BCLR	 #3,@ER6
	       MOV.W	 #H'000F,E3
	       MOV.W	 E3,E4
	       RTS
;
F19_SUB:       .EQU	 $
F19_JCS_JUG:   BTST	 #JCS,R1L
	       BNE	 F19_RET
	       MOV.L	 @ER7,ER5
	       SUB.W	 #D'29,R5
	       MOV.B	 R1H,@ER5
	       BLD	 #3,R1H
	       BCS	 F19_GO:8
	       BLD	 #ONLS,R1H	   ;R1L->R1H
	       BOR	 FOR_NEXT
	       BAND	 #2,R1H
	       BCC	 F13_RET_RESETF
F19_GO:        BLD	 #5,R1H
	       BCS	 F19D_GO
F19W_GO:       MOV.W	 #H'000F,E3
	       MOV.W	 #H'000F,E4
	       MOV.W	 @ER3,R5
	       BLD	 #6,R1H
	       BCS	 F19W_GO_V:8
	       MOV.W	 R4,R3
	       BRA	 F19W_GO_V1:8
F19W_GO_V:     MOV.W	 @ER4,R3
F19W_GO_V1:    CMP.W	 #0,R3
	       BEQ	 F18_19_ERR:8
	       MOV.W	 #0,E5
	       DIVXU.W	 R3,ER5
	       MOV.W	 #H'000F,E2
	       MOV.W	 R5,@ER2
	       INC.W	 #2,R2
	       MOV.W	 E5,@ER2
F18_19_RET:    MOV.L	 #SC041_ADDR,ER4
	       BCLR	 #3,@ER4
	       MOV.W	 #H'000F,E3
	       MOV.W	 E3,E4
F19_RET:       RTS
F18_19_ERR:    MOV.L	 #SC041_ADDR,ER4
	       BSET	 #3,@ER4
	       MOV.W	 #H'000F,E3
	       RTS
F19D_GO:       MOV.W	 @ER3+,R5	 ;;
	       MOV.W	 @ER3,E5	 ;;
	       MOV.L	 ER5,ER3	 ;;
	       BLD	 #6,R1H
	       BCS	 F19D_GO_V:8
	       MOV.W	 R4,R5
	       MOV.W	 #0,E5
	       BRA	 F19D_GO_V1:8
F19D_GO_V:     MOV.W	 @ER4+,R5	 ;;
	       MOV.W	 @ER4,E5	 ;;
F19D_GO_V1:    MOV.L	 ER5,ER4	 ;;
	       BEQ	 F18_19_ERR	 ;;
	       MOV.B	 #32,R6L
	       SUB.L	 ER5,ER5
DIV1:	       SHLL.L	 ER3
	       ROTXL.L	 ER5
	       SUB.L	 ER4,ER5
	       BCC	 DIV2:8
	       ADD.L	 ER4,ER5
	       BRA	 DIV3:8
DIV2:	       BSET	 #0,R3L
DIV3:	       DEC.B	 R6L
	       BNE	 DIV1:8
	       MOV.W	 #H'000F,E2
	       MOV.W	 R3,@ER2
	       INC.W	 #2,R2
	       MOV.W	 E3,@ER2
	       INC.W	 #2,R2
	       MOV.W	 R5,@ER2
	       INC.W	 #2,R2
	       MOV.W	 E5,@ER2
	       INC.W	 #2,R2
	       BRA	 F18_19_RET
;
F17_SUB:       MOV.B	 #D'17,R5L
	       BRA	 FUN_17_31:8
F20_SUB:       MOV.B	 #D'20,R5L
	       BRA	 FUN_17_31:8
F21_SUB:       MOV.B	 #D'21,R5L
	       BRA	 FUN_17_31:8
F22_SUB:       MOV.B	 #D'22,R5L
	       BRA	 FUN_17_31:8
F27_SUB:       MOV.B	 #D'27,R5L
	       BRA	 FUN_17_31:8
F30_SUB:       MOV.B	 #D'30,R5L
	       BRA	 FUN_17_31:8
F31_SUB:       MOV.B	 #D'31,R5L
FUN_17_31:     MOV.B	 R5L,@FN_TYPE
F17_JCS_JUG:   BTST	 #JCS,R1L
	       BNE	 F17_RET
	       BLD	 #2,R1H
	       BST	 #1,R1H
	       MOV.L	 @ER7,ER4
	       SUB.W	 #21,R4
	       MOV.B	 R1H,@ER4
	       BLD	 #3,R1H
	       BCS	 F17_22_CAL:8
	       BLD	 #ONLS,R1H	  ;R1L->R1H
	       BOR	 FOR_NEXT
	       BAND	 #2,R1H
	       BCC	 F17_RET_RESETF
F17_22_CAL:    MOV.B	 @FN_TYPE,R5L
	       CMP.B	 #D'17,R5L
	       BEQ	 F17_GO
	       CMP.B	 #D'20,R5L
	       BEQ	 F20_GO
	       CMP.B	 #D'21,R5L
	       BEQ	 F21_GO
	       CMP.B	 #D'22,R5L
	       BEQ	 F22_GO
	       CMP.B	 #D'27,R5L
	       BEQ	 F27_GO
	       CMP.B	 #D'30,R5L
	       BEQ	 F30_GO
	       BRA	 F31_GO
F17_OK_RET:    MOV.L	 #SC041_ADDR,ER3
	       BCLR	 #3,@ER3
	       MOV.W	 #H'000F,E4
F17_RET:       BLD	 #2,R1H
	       RTS
F17_RET_RESETF: MOV.B	 @FN_TYPE,R5L
		CMP.B	 #D'17,R5L
		BNE	 F17_RET:8
		JSR	 @FLAG_RESET
		BRA	 F17_RET:8
F17_ERR_RET:   MOV.L	 #SC041_ADDR,ER3
	       BSET	 #3,@ER3
	       BLD	 #2,R1H
	       RTS


;
F17_GO:        BLD	 #5,R1H 		 ;V0.A
	       BCS	 F17D_GO		 ;
	       BLD	 #4,R1H 		 ;
	       BCS	 F17W_GO		 ;
F17B_GO:       BLD	 #6,R1H
	       BCS	 F17_V:8
	       MOV.B	 R3L,R4L
	       BRA	 F17_R1:8
F17_V:	       CMP.W	 #WORD_RANGE,R3
	       BCS	 F17_R:8
	       INC.W	 #1,R3
F17_R:	       MOV.B	 @ER3,R4L
F17_R1:        JSR	 @BCD_HEX_B
	       BLD	 JUDGE_NG
	       BCS	 F17_ERR_RET
	       CMP.W	 #WORD_RANGE,R2
	       BCS	 F17_S
	       INC.W	 #1,R2
F17_S:	       MOV.B	 R4L,@ER2
	       BRA	 F17_OK_RET
;
F17W_GO:       BLD	 #6,R1H
	       BCS	 F17W_V:8
	       MOV.W	 R3,R4
	       BRA	 F17W_R1:8
F17W_V:        CMP.W	 #WORD_RANGE,R3
	       BCC	 F17W_V1:8
	       MOV.B	 @ER3,R4L
	       INC.W	 #1,R3
	       MOV.B	 @ER3,R4H
	       BRA	 F17W_R1:8
F17W_V1:       MOV.W	 @ER3,R4
F17W_R1:       JSR	 @BCD_HEX_W
	       BLD	 JUDGE_NG
	       BCS	 F17_ERR_RET
	       CMP.W	 #WORD_RANGE,R2
	       BCC	 F17W_S:8
	       MOV.B	 R4L,@ER2
	       INC.W	 #1,R2
	       MOV.B	 R4H,@ER2		 ;;V0.B ER4->ER2
	       BRA	 F17_OK_RET
F17W_S:        MOV.W	 R4,@ER2
	       BRA	 F17_OK_RET
F17D_GO:       BLD	 #6,R1H 		 ;;V0.B
	       BCS	 F17D_V:8
	       MOV.W	 R3,R4
	       MOV.W	 #0,E4
	       BRA	 F17D_R1:8
F17D_V:        CMP.W	 #WORD_RANGE,R3
	       BCC	 F17D_V1:8
	       MOV.B	 @ER3+,R4L
	       MOV.B	 @ER3+,R4H
	       MOV.B	 @ER5+,R5L
	       MOV.B	 @ER5+,R5H
	       MOV.W	 R5,E4
	       BRA	 F17D_R1:8
F17D_V1:       MOV.W	 @ER3,R4
	       INC.W	 #2,R3
	       MOV.W	 @ER3,E4
F17D_R1:       JSR	 @BCD_HEX_D
	       BLD	 JUDGE_NG
	       BCS	 F17_ERR_RET
	       CMP.W	 #WORD_RANGE,R2
	       BCC	 F17D_S:8
	       MOV.B	 R4L,@ER2
	       INC.W	 #1,R2
	       MOV.B	 R4H,@ER2		 ;;V0.B
	       MOV.W	 E4,R4
	       INC.W	 #1,R2
	       MOV.B	 R4L,@ER2
	       INC.W	 #1,R2
	       MOV.B	 R4H,@ER2
	       BRA	 F17_OK_RET
F17D_S:        MOV.W	 R4,@ER2
	       INC.W	 #2,R2
	       MOV.W	 E4,@ER2
	       BRA	 F17_OK_RET
;
;;   BITN1  BITN0
;;	0      0	 F20 AND   COMMON USED SAME SUBROUTINE
;;	0      1	 F21 ORL
;;	1      0	 F22 XOR
F22_GO:        BSET	 BITN1
	       BCLR	 BITN0
	       BRA	 F20_GO1:8
F21_GO:        BCLR	 BITN1
	       BSET	 BITN0
	       BRA	 F20_GO1:8
F20_GO:        BCLR	 BITN1
	       BCLR	 BITN0
F20_GO1:       BLD	 #4,R1H
	       BCS	 F20W_GO
F20B_GO:       BLD	 #6,R1H
	       BCS	 F20_V:8
	       MOV.B	 R3L,R4L
	       BRA	 F20_R1:8
F20_V:	       CMP.W	 #WORD_RANGE,R3
	       BCS	 F20_R:8
	       INC.W	 #1,R3
F20_R:	       MOV.B	 @ER3,R4L	  ;;S
F20_R1:        CMP.W	 #WORD_RANGE,R2
	       BCS	 F20_S:8
	       INC.W	 #1,R2
F20_S:	       MOV.B	 @ER2,R4H	  ;;D
	       BLD	 BITN1
	       BCC	 F20_21_JUDGE:8
F22_XOR:       XOR.B	 R4L,R4H
	       BRA	 F20_AND1:8
F20_21_JUDGE:  BLD	 BITN0
	       BCC	 F20_AND:8
	       OR.B	 R4L,R4H
	       BRA	 F20_AND1:8
F20_AND:       AND.B	 R4L,R4H
F20_AND1:      MOV.B	 R4H,@ER2
	       CMP.B	 #H'00,R4H
	       BEQ	 F20_C243_1:8
F20_C243_0:    MOV.L	 #SC041_ADDR,ER4
	       BCLR	 #2,@ER4
	       BLD	 #2,R1H
	       RTS
F20_C243_1:    MOV.L	 #SC041_ADDR,ER4
	       BSET	 #2,@ER4
	       BLD	 #2,R1H
	       RTS

;
F20W_GO:       BLD	 #6,R1H
	       BCS	 F20W_V:8
	       MOV.W	 R3,R4
	       BRA	 F20W_R1:8
F20W_V:        CMP.W	 #WORD_RANGE,R3
	       BCC	 F20W_V1:8
	       MOV.B	 @ER3,R4L
	       INC.W	 #1,R3
	       MOV.B	 @ER3,R4H
	       BRA	 F20W_R1:8
F20W_V1:       MOV.W	 @ER3,R4
F20W_R1:       CMP.W	 #WORD_RANGE,R2
	       BCC	 F20W_S:8
	       MOV.B	 @ER2,R5L
	       INC.W	 #1,R2
	       MOV.B	 @ER2,R5H
	       BRA	 F20W_S1:8
F20W_S:        MOV.W	 @ER2,R5
F20W_S1:       BLD	 BITN1
	       BCC	 F20W_21W_JUG:8
	       XOR.W	 R4,R5
	       BRA	 F20W_AND1:8
F20W_21W_JUG:  BLD	 BITN0
	       BCC	 F20W_AND:8
	       OR.W	 R4,R5
	       BRA	 F20W_AND1:8
F20W_AND:      AND.W	 R4,R5
F20W_AND1:     CMP.W	 #WORD_RANGE,R2
	       BCC	 F20W_S2:8
	       MOV.B	 R5H,@ER2
	       DEC.W	 #1,R2
	       MOV.B	 R5L,@ER2
	       BRA	 F20W_S3:8
F20W_S2:       MOV.W	 R5,@ER2
F20W_S3:       CMP.W	 #0,R5
	       BEQ	 F20_C243_1
	       BRA	 F20_C243_0
;

F23_SUB:       MOV.B	 #D'23,R5L
	       BRA	 FUN_23_26:8
F24_SUB:       MOV.B	 #D'24,R5L
	       BRA	 FUN_23_26:8
F25_SUB:       MOV.B	 #D'25,R5L
	       BRA	 FUN_23_26:8
F26_SUB:       MOV.B	 #D'26,R5L
FUN_23_26:     MOV.B	 R5L,@FN_TYPE
F23_JCS_JUG:   BTST	 #JCS,R1L
	       BNE	 F23_RET:8
	       BIAND	 #1,R1H
	       BST	 #3,R1H
	       BLD	 #2,R1H
	       BST	 #1,R1H
	       MOV.L	 @ER7,ER4
	       SUB.W	 #13,R4
	       MOV.B	 R1H,@ER4
	       BLD	 #3,R1H
	       BCS	 F23_F26_GO:8
	       BLD	 #ONLS,R1H	     ;R1L->R1H
	       BOR	 FOR_NEXT
	       BAND	 #2,R1H
	       BCC	 F23_RET:8
;F23_SKIP_JUG:	BTST	  #FUN_SKIP,R1L
;		BNE	  F23_RET:8
F23_F26_GO:    MOV.B	 @FN_TYPE,R5L
	       CMP.B	 #D'23,R5L
	       BEQ	 F23_GO
	       CMP.B	 #D'24,R5L
	       BEQ	 F24_GO
	       CMP.B	 #D'25,R5L
	       BEQ	 F25_GO
	       BRA	 F26_GO
F23_RET:       RTS
;

;;R2H: R10, R9,  R8,  T1, T0, B2, B1, B0
;;R2L: R7 , R6,  R5,  R4, R3, R2, R1, R0
F24_GO:        BSET	 JUDGE_NG
	       BRA	 F23_GO1:8
F23_GO:        BCLR	 JUDGE_NG
F23_GO1:       MOV.B	 R2H,R3L
	       MOV.B	 R2H,R3H
	       AND.B	 #B'00000111,R3H   ;;R3H byte number
	       ROTL.B	 R2H
	       ROTL.B	 R2H
	       ROTL.B	 R2H
	       AND.B	 #B'00000111,R2H   ;;R2 byte address
	       AND.B	 #B'00011000,R3L
F23_X:	       CMP.B	 #B'00000000,R3L
	       BNE	 F23_Y:8
	       MOV.L	 #X_STATE,ER4
	       ADD.W	 R2,R4
	       BRA	 F23_24_JUG:8
F23_Y:	       CMP.B	 #B'00001000,R3L
	       BNE	 F23_C:8
	       MOV.L	 #Y_STATE,ER4
	       ADD.W	 R2,R4
	       BRA	 F23_24_JUG:8
F23_C:	       CMP.B	 #B'00010000,R3L
	       BNE	 F23_M:8
	       MOV.L	 #C_STATE,ER4
	       ADD.W	 R2,R4
	       BRA	 F23_24_JUG:8
F23_M:	       MOV.L	 #M_STATE,ER4
	       ADD.W	 R2,R4
F23_24_JUG:    BLD	 JUDGE_NG
	       BCS	 F24_RESET:8
	       BSET	 R3H,@ER4
	       RTS
F24_RESET:     BCLR	 R3H,@ER4
	       BCLR	 JUDGE_NG
	       RTS
;
F25_GO:        MOV.W	 #H'000F,E2
	       CMP.W	 #WORD_RANGE,R2
	       BCC	 F25_V:8
	       MOV.B	 @ER2,R3L
	       INC.L	 #1,ER2
	       MOV.B	 @ER2,R3H
	       INC.W	 #1,R3
	       MOV.B	 R3H,@ER2
	       DEC.L	 #1,ER2
	       MOV.B	 R3L,@ER2
	       RTS
F25_V:	       MOV.W	 @ER2,R3
	       INC.W	 #1,R3
	       MOV.W	 R3,@ER2
	       RTS
F26_GO:        CMP.W	 #WORD_RANGE,R2
	       BCC	 F26_V:8
	       MOV.B	 @ER2,R3L
	       INC.L	 #1,ER2
	       MOV.B	 @ER2,R3H
	       DEC.W	 #1,R3
	       MOV.B	 R3H,@ER2
	       DEC.L	 #1,ER2
	       MOV.B	 R3L,@ER2
	       RTS
F26_V:	       MOV.W	 @ER2,R3
	       DEC.W	 #1,R3
	       MOV.W	 R3,@ER2
	       RTS
;;;
F27_GO:        BLD	 #4,R1H
	       BCS	 F27W_GO
F27B_GO:       BLD	 #6,R1H
	       BCS	 F27_V:8
	       MOV.B	 R3L,R4L	  ;;S
	       BRA	 F27_R1:8
F27_V:	       CMP.W	 #WORD_RANGE,R3
	       BCS	 F27_R:8
	       INC.W	 #1,R3
F27_R:	       MOV.B	 @ER3,R4L	  ;;S
F27_R1:        MOV.B	 #0,R4H
	       MOV.B	 #8,R5L
F27_R2:        SHLR.B	 R4L
	       BCC	 F27_NO_INC:8
	       INC.B	 R4H
F27_NO_INC:    DEC.B	 R5L
	       BNE	 F27_R2:8
	       CMP.W	 #WORD_RANGE,R2
	       BCS	 F27_S:8
	       INC.W	 #1,R2
F27_S:	       MOV.B	 R4H,@ER2	  ;;D
	       BLD	 #2,R1H
	       RTS
;
F27W_GO:       BLD	 #6,R1H
	       BCS	 F27W_V:8
	       MOV.W	 R3,R4		   ;;S
	       BRA	 F27W_R1:8
F27W_V:        CMP.W	 #WORD_RANGE,R3
	       BCC	 F27W_V1:8
	       MOV.B	 @ER3,R4L
	       INC.W	 #1,R3
	       MOV.B	 @ER3,R4H
	       BRA	 F27W_R1:8
F27W_V1:       MOV.W	 @ER3,R4	   ;;S
F27W_R1:       MOV.B	 #0,R5L
	       MOV.B	 #D'16,R5H
F27W_R2:       SHLR.W	 R4
	       BCC	 F27W_R3:8
	       INC.B	 R5L		   ;;S' 1
F27W_R3:       DEC.B	 R5H
	       BNE	 F27W_R2:8
	       CMP.W	 #WORD_RANGE,R2
	       BCS	 F27W_R:8
	       MOV.W	 R5,@ER2
	       BLD	 #2,R1H
	       RTS
F27W_R:        MOV.B	 R5L,@ER2
	       INC.W	 #1,R2
	       MOV.B	 R5H,@ER2
	       BLD	 #2,R1H
	       RTS
;
F31_GO:        BSET	 JUDGE_NG
	       BLD	 #6,R1H        ;;V0.C
	       BCS	 F31_GO_V:8    ;;
	       MOV.W	 R3,R5	       ;;
	       BRA	 V_RANGE_J:8   ;;
F31_GO_V:      CMP.W	 #WORD_RANGE,R3;;
	       BCC	 F31_GO_V1:8   ;;
	       MOV.B	 @ER3+,R5L     ;;
	       MOV.B	 @ER3,R5H      ;;
	       BRA	 V_RANGE_J:8   ;;
F31_GO_V1:     MOV.W	 @ER3,R5       ;@R3->R2
	       BRA	 V_RANGE_J:8   ;;
F30_GO:        BCLR	 JUDGE_NG      ;;
	       BLD	 #6,R1H        ;;
	       BCS	 F30_GO_V:8    ;;
	       MOV.W	 R2,R5	       ;;
	       BRA	 V_RANGE_J:8   ;;
F30_GO_V:      CMP.W	 #WORD_RANGE,R2;;
	       BCC	 F30_GO_V1:8   ;;
	       MOV.B	 @ER2+,R5L     ;;
	       MOV.B	 @ER2,R5H      ;;
	       BRA	 V_RANGE_J:8   ;;
F30_GO_V1:     MOV.W	 @ER2,R5       ;R3->@R2
V_RANGE_J:     CMP.W	 #0,R5
	       BEQ	 F30_31_ERR
	       CMP.W	 #D'1025,R5
	       BCC	 D_RANGE_J:8
	       SUB.W	 #1,R5
	       SHLL.W	 R5
	       MOV.L	 #V_MEMORY_ADDR,ER4
	       ADD.W	 R5,R4
	       BRA	 F30_31_JUG
D_RANGE_J:     CMP.W	 #D'3073,R5
	       BCC	 WC_RANGE_J:8
	       SUB.W	 #D'1025,R5
	       SHLL.W	 R5
	       MOV.L	 #D_MEMORY_ADDR,ER4
	       ADD.W	 R5,R4
	       BRA	 F30_31_JUG
WC_RANGE_J:    BLD	 JUDGE_NG
	       BCC	 F30_31_RET
	       CMP.W	 #D'3985,R5
	       BCC	 FILE21_130_J:8
	       SUB.W	 #D'3073,R5
	       SHLL.W	 R5
	       MOV.L	 #WC_MEMORY_ADDR,ER4
	       ADD.W	 R5,R4
	       BRA	 F30_31_JUG:8
FILE21_130_J:  CMP.W	 #D'6185,R5
	       BCC	 X_RANGE_J:8
	       SUB.W	 #D'3985,R5
	       MOV.L	 #FILE21_ADDR,ER4
	       ADD.W	 R5,R4
	       BRA	 F30_31_JUG:8
X_RANGE_J:     CMP.W	 #D'6233,R5
	       BCC	 Y_RANGE_J:8
	       SUB.W	 #D'6185,R5
	       MOV.L	 #X_STATE,ER4
	       ADD.W	 R5,R4
	       BRA	 F30_31_JUG:8
Y_RANGE_J:     CMP.W	 #D'6281,R5
	       BCC	 C_RANGE_J:8
	       SUB.W	 #D'6233,R5
	       MOV.L	 #Y_STATE,ER4
	       ADD.W	 R5,R4
	       BRA	 F30_31_JUG:8
C_RANGE_J:     CMP.W	 #D'6537,R5
	       BCC	 F30_31_ERR
	       SUB.W	 #D'6281,R5
	       MOV.L	 #C_STATE,ER4
	       ADD.W	 R5,R4
F30_31_JUG:    BLD	 JUDGE_NG
	       BCC	 F30_IDXT:8
F31_IDXF:      CMP.L	 #FILE21_ADDR,ER4
	       BCC	 F31_IDXF_FILE:8
	       CMP.W	 #WORD_RANGE,R4
	       BCC	 F31_IDXF1:8
	       MOV.B	 @ER4+,R5L
	       MOV.B	 @ER4,R5H
	       BRA	 F31_W_STRT:8
F31_IDXF1:     MOV.W	 @ER4,R5
	       BRA	 F31_W_STRT:8
F31_IDXF_FILE: MOV.B	 @ER4,R5L
	       MOV.B	 #0,R5H
F31_W_STRT:    CMP.W	 #WORD_RANGE,R2
	       BCC	 F31_W_STRT1:8
	       MOV.B	 R5L,@ER2
	       INC.L	 #1,ER2
	       MOV.B	 R5H,@ER2
	       BRA	 F30_31_RET:8
F31_W_STRT1:   MOV.W	 R5,@ER2
	       BRA	 F30_31_RET:8
F30_IDXT:      BLD	 #6,R1H
	       BCS	 F30_IDXT1:8
	       MOV.W	 R3,@ER4
	       BRA	 F30_31_RET:8
F30_IDXT1:     CMP.W	 #WORD_RANGE,R3
	       BCC	 F30_IDXT2:8
	       MOV.B	 @ER3+,R5L
	       MOV.B	 @ER3,R5H
	       MOV.W	 R5,@ER4
	       BRA	 F30_31_RET:8
F30_IDXT2:     MOV.W	 @ER3,R5
	       MOV.W	 R5,@ER4
F30_31_ERR:    .EQU	 $
F30_31_RET:    BLD	 #2,R1H
	       RTS
;;
F34_SUB:       BIAND	 #MCS,R1L
	       BST	 #2,R1H
	       BCC	 F34_RET:8
F34_JCS_JUG:   BTST	 #JCS,R1L
	       BNE	 F34_RET:8
F34_GO:        BSET	 #ONLS,R1H	    ;R1L->R1H
F34_RET:       RTS



F28_SUB:       RTS
F29_SUB:       RTS
F32_SUB:
F32_JCS_JUG:   BTST	 #JCS,R1L
	       BNE	 F32_RET
	       MOV.L	 @ER7,ER5
	       SUB.W	 #D'29,R5
	       MOV.B	 R1H,@ER5
	       BLD	 #3,R1H
	       BCS	 F32_GO:8
	       BLD	 #ONLS,R1H
	       BOR	 FOR_NEXT
	       BAND	 #2,R1H
	       BCC	 F13_RET_RESETF
F32_GO:        BLD	 #6,R1H
	       BCC	 CHK_N_RANGE:8
	       MOV.W	 @ER4,R5
	       MOV.W	 R5,R4
CHK_N_RANGE:   CMP.W	 #0,R4
	       BEQ	 F32_OK_RET
	       CMP.W	 #D'1025,R4
	       BCC	 F32_ERR_RET
CHK_D_V_RANGE: MOV.W	 R4,@R3_BUFFER
	       MOV.W	 R2,@R2_BUFFER
	       DEC.W	 #1,R4
	       SHLL.W	 R4
	       CMP.W	 #D_MEMORY_ADDR1,R2
	       BCC	 CHK_D_D_RANGE:8
	       ADD.W	 R4,R2
	       CMP.W	 #D_MEMORY_ADDR1,R2
	       BCC	 F32_ERR_RET
	       BRA	 F32_START:8
CHK_D_D_RANGE: CMP.W	 #WS_MEMORY_ADDR1,R2
	       BCC	 F32_OK_RET:8
	       ADD.W	 R4,R2
	       CMP.W	 #WS_MEMORY_ADDR1,R2
	       BCC	 F32_ERR_RET
F32_START:     MOV.W	 @R3_BUFFER,R4
	       MOV.W	 @R2_BUFFER,R2
F32_START_LP:  MOV.W	 @ER3+,R5
	       MOV.W	 R5,@ER2
	       INC.L	 #2,ER2
	       DEC.W	 #1,R4
	       BNE	 F32_START_LP:8
F32_OK_RET:    MOV.L	 #SC041_ADDR,ER4
	       BCLR	 #3,@ER4
F32_RET:       RTS
F32_ERR_RET:   MOV.L	 #SC041_ADDR,ER4
	       BSET	 #3,@ER4
	       RTS

F33_SUB_TWO:   BTST	 #JCS,R1L
	       BNE	 F33_RET
	       BIAND	 #1,R1H
	       BST	 #3,R1H
	       BLD	 #2,R1H
	       BST	 #1,R1H
	       MOV.L	 @ER7,ER4
	       SUB.W	 #15,R4
	       MOV.B	 R1H,@ER4
	       BLD	 #3,R1H
	       BCS	 F33_SKIP_JUG1:8
	       BLD	 #ONLS,R1H     ;R1L->R1H
	       BOR	 FOR_NEXT
	       BAND	 #2,R1H
	       BCC	 F33_RET_RESETF  ;;V0.8 BUG MODIFY
F33_SKIP_JUG1: BTST	 #FUN_SKIP,R1L
	       BNE	 F33_RET
F33_TWO_GO:    MOV.W	 R2,R6		  ;;V0.C
	       MOV.W	 #H'000F,E6       ;;
	       SHLR.B	 R6H		  ;;
	       BST	 #7,R6L 	  ;;
	       AND.B	 #H'03,R6H        ;;
	       SHLL.W	 R6		  ;;
	       ADD.W	 #V_MEMORY_ADDR1,R6 ;;
	       MOV.W	 @ER6,R5	  ;;
	       BLD	 #4,R1H 	  ;;
	       BCC	 F33_2_BYTE:8	  ;;
F33_2_WORD:    CMP.W	 #D'130,R5        ;;
	       BCC	 F33_ERR_RET	  ;;
	       BRA	 F33_TWO_GO1:8	  ;;
F33_2_BYTE:    CMP.W	 #D'131,R5        ;;
	       BCC	 F33_ERR_RET	  ;;
F33_TWO_GO1:   MOV.B	 #4,R4L
	       MOV.B	 R4L,@F33_TX_CNT
	       MOV.B	 #D'33,R4L
	       MOV.B	 R4L,@F33_TX_BUFF
	       MOV.B	 R3L,@F33_TX_BUFF+1
	       MOV.B	 R2H,@F33_TX_BUFF+2
	       MOV.B	 R2L,@F33_TX_BUFF+3
	       BSET	 TD_MOD
F33_RET:       BLD	 #2,R1H
	       MOV.L	 #SC041_ADDR,ER6	 ;;V0.B
	       BCLR	 #3,@ER6		 ;;
	       RTS
F33_RET_RESETF: JSR	 @FLAG_RESET
     ;;;;;;;   BCLR	 TD_MOD 		 ;;VF.2
	       BLD	 #2,R1H
	       RTS
F33_ERR_RET:   JSR	 @FLAG_ERROR		 ;V0.B
	       BCLR	 TD_MOD 		 ;;VF.2
	       BLD	 #2,R1H 		 ;
	       RTS				 ;
;;;;;;;
F33_SUB_THREE: .EQU	 $
	       BTST	 #JCS,R1L
	       BNE	 F33_RET
	       BLD	 #2,R1H
	       BST	 #1,R1H
	       MOV.B	 R4L,@R4_DATA
	       MOV.L	 @ER7,ER4
	       SUB.W	 #23,R4
	       MOV.B	 R1H,@ER4
	       BLD	 #3,R1H
	       BCS	 F33_SKIP_JUG2:8
	       BLD	 #ONLS,R1H	  ;R1L->R1H
	       BOR	 FOR_NEXT
	       BAND	 #2,R1H
	       BCC	 F33_RET_RESETF       ;
F33_SKIP_JUG2: BTST	 #FUN_SKIP,R1L
	       BNE	 F33_RET
F33_THREE_GO:  MOV.W	 R3,R6		  ;;V1.1
	       SHLR.B	 R6H		  ;;V1.1
	       BST	 #7,R6L 	  ;;V1.1
	       AND.B	 #H'03,R6H        ;;V1.1
	       INC.W	 #1,R6		  ;;V1.1
	       MOV.W	 R6,@R3_DATA	  ;;V1.1
	       MOV.W	 R2,R6		  ;;V0.C
	       MOV.W	 #H'000F,E6       ;;
	       SHLR.B	 R6H		  ;;
	       BST	 #7,R6L 	  ;;
	       AND.B	 #H'03,R6H        ;;
	       SHLL.W	 R6		  ;;
	       ADD.W	 #V_MEMORY_ADDR1,R6 ;;
	       MOV.W	 @ER6,R5	  ;;
	       CMP.W	 #0,R5		  ;;;VF.6
	       BEQ	 F33_ERR_RET	  ;;;
	       BLD	 #4,R1H 	  ;;
	       BCC	 F33_3_BYTE:8	  ;;
F33_3_WORD:    CMP.W	 #D'130,R5        ;;
	       BCC	 F33_ERR_RET	  ;;
	       BLD	 OP05_MODE	  ;;VF.6
	       BCC	 F33_THREE_GO1	  ;;VF.6
	       MOV.W	 R5,@V0600_ADDR   ;;VF.6
	       INC.W	 #1,R5		  ;;VF.6
	       MOV.W	 R5,@V0601_ADDR   ;;VF.6
	       DEC.W	 #1,R5		  ;;VF.6
	       MOV.W	 #D'13,R4         ;;
	       MOV.W	 R4,@V0604_ADDR   ;;
	       MOV.W	 @R3_DATA,R4	  ;;V1.1
	       MOV.W	 R4,@V0615_ADDR   ;;V1.1
	       MOV.W	 R4,@V0616_ADDR   ;;V1.1
	       BRA	 F33_THREE_GO1:8  ;;
F33_3_BYTE:    CMP.W	 #D'131,R5        ;;
	       BCC	 F33_ERR_RET	  ;;
	       BLD	 OP05_MODE	  ;;VF.6
	       BCC	 F33_THREE_GO1:8  ;;VF.6
	       MOV.W	 @V0600_ADDR,R4   ;;V1.1
	       CMP.W	 #0,R4		  ;;
	       BNE	 F33_X_LINE:8	  ;;
	       BCLR	 F33_TOGGLE	  ;;
F33_X_LINE:    BLD	 F33_TOGGLE	  ;;
	       BCS	 F33_3_BYTE0:8	  ;;
	       MOV.W	 R5,@V0600_ADDR   ;;
	       MOV.W	 @R3_DATA,R4	  ;;V1.1
	       MOV.W	 R4,@V0615_ADDR   ;;V1.1
	       BRA	 F33_3_BYTE01:8   ;;
F33_3_BYTE0:   MOV.W	 R5,@V0601_ADDR   ;;
	       MOV.W	 @R3_DATA,R4	  ;;V1.1
	       MOV.W	 R4,@V0616_ADDR   ;;V1.1
F33_3_BYTE01:  BNOT	 F33_TOGGLE	  ;;
F33_3_BYTE1:   MOV.W	 #D'13,R4         ;;
	       MOV.W	 R4,@V0604_ADDR   ;;
F33_THREE_GO1: MOV.B	 #6,R4H
	       MOV.B	 R4H,@F33_TX_CNT  ;;VF.2 R4L->R4H
	       MOV.B	 #D'33,R4H
	       MOV.B	 R4H,@F33_TX_BUFF
	       MOV.B	 @R4_DATA,R4L
	       MOV.B	 R4L,@F33_TX_BUFF+1
	       MOV.B	 R2H,@F33_TX_BUFF+2
	       MOV.B	 R2L,@F33_TX_BUFF+3
	       MOV.B	 R3H,@F33_TX_BUFF+4
	       MOV.B	 R3L,@F33_TX_BUFF+5
	       BSET	 TD_MOD
	       BRA	 F33_RET
;
F35_SUB:
F36_SUB:
F37_SUB:
F38_SUB:
;
F39_RET:       RTS
F39_SUB:
F39_JCS_JUG:   BTST	 #JCS,R1L
	       BNE	 F39_RET:8
	       MOV.L	 @ER7,ER5
	       SUB.W	 #D'29,R5
	       MOV.B	 R1H,@ER5
	       BLD	 #3,R1H
	       BCS	 F39_GO:8
	       BLD	 #ONLS,R1H
	       BOR	 FOR_NEXT
	       BAND	 #2,R1H
	       BCC	 F39_RET:8
F39_GO:        CMP.W	 #0,R4
	       BEQ	 F39_RET
	       CMP.W	 #9,R4		 ;ONLY R4L = n
	       BCC	 F39_RET
	       MOV.W	 R4,@R3_BUFFER	 ;;PUSH R4 (R4L = n)
	       CMP.W	 #WORD_RANGE,R3
	       BCS	 F39_S_RELAY:8
	       INC.W	 #1,R3
F39_S_RELAY:   MOV.B	 @ER3,R6L	 ;R6L = S's content
	       MOV.L	 #F39_TABLE,ER5
	       DEC.W	 #1,R4		 ;;V0.B
	       ADD.W	 R4,R5
	       MOV.B	 @ER5,R6H
	       AND.B	 R6H,R6L	 ;R6L effective decode content
	       MOV.B	 R6L,@R6L_BUFFER ;S's effective decode content
	       CMP.W	 #WORD_RANGE,R2
	       BCC	 F39_D_V_00	 ;
F39_D_R_00:    MOV.L	 #F39_TABLE1,ER5
	       ADD.W	 R4,R5
	       MOV.B	 @ER5,R4L	 ;R4L how many byte need to decode
	       MOV.W	 R2,@R2_BUFFER
	       CMP.B	 #0,R4L
	       BEQ	 F39_R_SETBIT	 ;2 bit & 4 bit
F39_D_R_01:    MOV.B	 #0,R4H
	       MOV.B	 R4H,@ER2
	       INC.L	 #1,ER2
	       DEC.B	 R4L
	       BEQ	 F39_D_R_02:8	;;V0.B
	       CMP.L	 #M_STATE,ER2	;;
	       BCC	 F39_RET	;;
	       BRA	 F39_D_R_01:8	;;
F39_D_R_02:    MOV.B	 #0,R6H
	       MOV.B	 #8,R5L
	       DIVXU.B	 R5L,R6        ;R6L
	       MOV.B	 R6H,R5L       ;BSET R5L,@
	       MOV.B	 #0,R6H
	       MOV.W	 @R2_BUFFER,R2
	       ADD.W	 R6,R2
	       BSET	 R5L,@ER2
	       BRA	 F39_RET
F39_R_SETBIT:  MOV.W	 @R3_BUFFER,R4
	       CMP.B	 #1,R4L
	       BNE	 F39_R_SETBIT2:8
	       MOV.W	 @R2_BUFFER,R2
	       MOV.B	 @ER2,R4H
	       AND.B	 #B'11111100,R4H
	       BSET	 R6L,R4H
	       MOV.B	 R4H,@ER2
	       BRA	 F39_RET
F39_R_SETBIT2: MOV.W	 @R2_BUFFER,R2
	       MOV.B	 @ER2,R4H
	       AND.B	 #B'11110000,R4H
	       BSET	 R6L,R4H
	       MOV.B	 R4H,@ER2
	       BRA	 F39_RET
;;;;
F39_D_V_00:    MOV.L	 #F39_TABLE2,ER5
	       ADD.W	 R4,R5
	       MOV.B	 @ER5,R4L	 ;R4L how many word need to decode
	       MOV.W	 R2,@R2_BUFFER
	       CMP.B	 #0,R4L
	       BEQ	 F39_V_SETBIT	 ;2 bit & 4 bit & 8 bit
F39_D_V_01:    MOV.W	 #0,R5
	       MOV.W	 R5,@ER2
	       INC.L	 #2,ER2
	       DEC.B	 R4L
	       BEQ	 F39_D_V_02:8
	       CMP.L	 #WS_MEMORY_ADDR,ER2
	       BCC	 F39_RET
F39_D_V_02:    MOV.B	 #0,R6H
	       MOV.B	 #8,R5L
	       DIVXU.B	 R5L,R6        ;R6L
	       MOV.B	 R6H,R5L       ;BSET R5L,@
	       MOV.B	 #0,R6H
	       MOV.W	 @R2_BUFFER,R2
	       ADD.W	 R6,R2
	       XOR.W	 #H'0001,R2    ;change high/low byte
	       BSET	 R5L,@ER2
	       BRA	 F39_RET
F39_V_SETBIT:  MOV.W	 @R2_BUFFER,R2
	       INC.W	 #1,R2
	       MOV.B	 @ER2,R4H
	       MOV.W	 @R3_BUFFER,R5
	       CMP.B	 #1,R5L
	       BNE	 F39_V_SETBIT1:8
	       AND.B	 #B'11111100,R4H
	       BSET	 R6L,R4H
	       MOV.B	 R4H,@ER2
	       BRA	 F39_RET
F39_V_SETBIT1: CMP.B	 #2,R5L
	       BNE	 F39_V_SETBIT2:8
	       AND.B	 #B'11110000,R4H
	       BSET	 R6L,R4H
	       MOV.B	 R4H,@ER2
	       BRA	 F32_RET
F39_V_SETBIT2: AND.B	 #B'00000000,R4H
	       BSET	 R6L,R4H
	       MOV.B	 R4H,@ER2
	       BRA	 F39_RET
F39_TABLE      .DATA.B	 1
	       .DATA.B	 3
	       .DATA.B	 7
	       .DATA.B	 15
	       .DATA.B	 31
	       .DATA.B	 63
	       .DATA.B	 127
	       .DATA.B	 255
F39_TABLE1     .DATA.B	 0
	       .DATA.B	 0
	       .DATA.B	 1
	       .DATA.B	 2
	       .DATA.B	 4
	       .DATA.B	 8
	       .DATA.B	 16
	       .DATA.B	 32
F39_TABLE2     .DATA.B	 0
	       .DATA.B	 0
	       .DATA.B	 0
	       .DATA.B	 1
	       .DATA.B	 2
	       .DATA.B	 4
	       .DATA.B	 8
	       .DATA.B	 16

F40_RESET_F:   MOV.L	 #SC041_ADDR,ER6	 ;;V0.C
	       MOV.B	 @ER6,R5L		 ;
	       AND.B	 #B'11110000,R5L         ;
	       MOV.B	 R5L,@ER6		 ;
	       RTS
F40_RET:       MOV.L	 #SC041_ADDR,ER6	 ;
	       BCLR	 #3,@ER6		 ;
	       RTS
F40_ERR_RET:   MOV.L	 #SC041_ADDR,ER6	 ;
	       BSET	 #3,@ER6		 ;
	       RTS
F40_SUB:       .EQU	 $
F40_JCS_JUG:   BTST	 #JCS,R1L
	       BNE	 F40_RET
	       MOV.L	 @ER7,ER5
	       SUB.W	 #D'29,R5
	       MOV.B	 R1H,@ER5
	       BLD	 #3,R1H
	       BCS	 F40_GO:8
	       BLD	 #ONLS,R1H
	       BOR	 FOR_NEXT
	       BAND	 #2,R1H
	       BCC	 F40_RESET_F	 ;;V0.C
F40_GO:        CMP.W	 #0,R4
	       BEQ	 F40_RET
	       CMP.W	 #9,R4		 ;ONLY R4L = n
	       BCC	 F40_RET
	       MOV.W	 R4,@R3_BUFFER
	       MOV.L	 #F40_TABLE2,ER5 ;;V0.B
	       DEC.W	 #1,R4		 ;;V0.B
	       ADD.W	 R4,R5		 ;;
	       INC.W	 #1,R4		 ;;
	       MOV.B	 @ER5,R6L	 ;;
	       MOV.B	 R6L,@R6_BUFFER  ;;
	       CMP.W	 #WORD_RANGE,R3
	       BCC	 F40_S_V
F40_S_R:       CMP.W	 #3,R4		 ;
	       BCS	 F40_S_R_2	 ;2 bit & 4 bit
	       MOV.L	 #F40_TABLE,ER5  ;
	       DEC.W	 #1,R4		 ;;V0.B
	       ADD.W	 R4,R5		 ;
	       MOV.B	 @ER5,R6L	 ;
	       MOV.B	 R6L,R5H	 ;
	       INC.B	 R5H		 ;byte counter
	       MOV.B	 #0,R6H 	 ;R6H to be bit counter
	       ADD.W	 R6,R3		 ;
F40_ROT0:      MOV.B	 #8,R6L 	 ;bit shift counter
	       MOV.B	 @ER3,R5L	 ;
F40_ROT1:      SHLL.B	 R5L		 ;
	       BCS	 F40_CAL_D:8	 ;
	       INC.B	 R6H		 ;
	       DEC.B	 R6L		 ;
	       BNE	 F40_ROT1:8	 ;
	       DEC.L	 #1,ER3 	 ;
	       DEC.B	 R5H		 ;
	       BNE	 F40_ROT0:8	 ;
	       BRA	 F40_ERR_RET	 ;;Nothing scan V0.C
F40_CAL_D:     CMP.B	 #0,R6H 	 ;256=1 or ALL=0
	       BNE	 F40_CAL_D1:8	 ;V0.C NO bit = 1, then jump to error
F40_CAL_D0:    CMP.B	 #0,R5H 	 ;;
	       BEQ	 F40_ERR_RET	 ;;
	       MOV.B	 @R6_BUFFER,R5L  ;;V0.C
	       BRA	 F40_CAL_D2:8	 ;;
F40_CAL_D1:    MOV.B	 @R6_BUFFER,R5L  ;;V0.B
	       SUB.B	 R6H,R5L	 ;
F40_CAL_D2:    CMP.W	 #WORD_RANGE,R2  ;
	       BCS	 F40_CAL_D_R:8	 ;
	       MOV.B	 #0,R6L 	 ;
	       MOV.B	 R6L,@ER2	 ;
	       INC.L	 #1,ER2 	 ;
	       MOV.B	 R5L,@ER2	 ;
	       BRA	 F40_RET	 ;V0.C
F40_CAL_D_R:   MOV.B	 R5L,@ER2	 ;V0.B
	       BRA	 F40_RET	 ;V0.C

F40_S_R_2:     CMP.W	 #1,R4		 ;2 bit & 4 bit
	       BNE	 F40_S_R_3:8	 ;
	       MOV.B	 @ER3,R5L	 ;
	       AND.B	 #B'00000011,R5L ;
	       CMP.B	 #H'0,R5L
	       BEQ	 F40_ERR_RET	 ;;V0.C
	       BLD	 #1,R5L 	 ;;V0.C
	       BCC	 F40_S_R_21:8	 ;;
	       MOV.B	 #1,R5H 	 ;;
	       BRA	 F40_D_CAL	 ;;
F40_S_R_21:    MOV.B	 #0,R5H 	 ;;V0.C
	       BRA	 F40_D_CAL
;
F40_S_R_3:     MOV.B	 @ER3,R5L	 ;
	       AND.B	 #B'00001111,R5L ;
	       CMP.B	 #H'0,R5L
	       BEQ	 F40_ERR_RET	 ;;V0.C
	       BLD	 #3,R5L 	 ;;
	       BCC	 F40_S_R_31:8	 ;;
	       MOV.B	 #3,R5H 	 ;;
	       BRA	 F40_D_CAL:8	 ;;
F40_S_R_31:    BLD	 #2,R5L 	 ;;
	       BCC	 F40_S_R_32:8	 ;;
	       MOV.B	 #2,R5H 	 ;;
	       BRA	 F40_D_CAL:8	 ;;
F40_S_R_32:    BLD	 #1,R5L 	 ;;V0.C
	       BCC	 F40_S_R_33:8	 ;;
	       MOV.B	 #1,R5H 	 ;;
	       BRA	 F40_D_CAL:8	 ;;
F40_S_R_33:    MOV.B	 #0,R5H 	 ;;
F40_D_CAL:     CMP.W	 #WORD_RANGE,R2  ;;
	       BCS	 F40_D_CAL1:8
	       MOV.B	 #0,R5L
	       MOV.B	 R5L,@ER2
	       INC.L	 #1,ER2
F40_D_CAL1:    MOV.B	 R5H,@ER2
	       BRA	 F40_RET	 ;;V0.C
;;;;;;;;;;;;;
F40_S_V:       CMP.W	 #4,R4		 ;
	       BCS	 F40V_S_R_2	 ;2 bit & 4 bit
	       MOV.L	 #F40_TABLE1,ER5 ;
	       DEC.W	 #1,R4		 ;;V0.B
	       ADD.W	 R4,R5		 ;
	       MOV.B	 @ER5,R6L	 ;
	       MOV.B	 R6L,R5H	 ;
	       INC.B	 R5H		 ;word counter
	       MOV.B	 #0,R6H 	 ;R6H to be bit counter
	       SHLL.W	 R6		 ;?
	       ADD.W	 R6,R3		 ;
F40V_ROT0:     MOV.B	 #D'16,R6L       ;bit shift counter
	       MOV.W	 @ER3,R4	 ;
F40V_ROT1:     SHLL.W	 R4		 ;
	       BCS	 F40V_CAL_D:8	 ;
	       INC.B	 R6H		 ;
	       DEC.B	 R6L		 ;
	       BNE	 F40V_ROT1:8	 ;
	       DEC.L	 #2,ER3 	 ;
	       DEC.B	 R5H		 ;
	       BNE	 F40V_ROT0:8	 ;
	       BRA	 F40_ERR_RET	 ;;V0.C
F40V_CAL_D:    CMP.B	 #0,R6H 	 ;
	       BNE	 F40V_CAL_D1:8	 ;V0.C NO bit = 1, then jump to error
F40V_CAL_D0:   CMP.B	 #0,R5H 	 ;;
	       BEQ	 F40_ERR_RET	 ;;
	       MOV.B	 @R6_BUFFER,R5L  ;;V0.C
	       BRA	 F40V_CAL_D2:8	 ;;
F40V_CAL_D1:   MOV.B	 @R6_BUFFER,R5L  ;;V0.B
	       SUB.B	 R6H,R5L	 ;;
F40V_CAL_D2:   CMP.W	 #WORD_RANGE,R2  ;
	       BCS	 F40V_CAL_D_R:8  ;
	       MOV.B	 #0,R6L 	 ;
	       MOV.B	 R6L,@ER2	 ;V0.B
	       INC.L	 #1,ER2 	 ;
	       MOV.B	 R5L,@ER2	 ;
	       BRA	 F40_RET      ;V0.C
F40V_CAL_D_R:  MOV.B	 R5L,@ER2	 ;;V0.B
	       BRA	 F40_RET      ;


F40V_S_R_2:    CMP.W	 #1,R4		 ;2 bit & 4 bit & 8 bit
	       BNE	 F40V_S_R_3:8	 ;
	       INC.L	 #1,ER3 	 ;
	       MOV.B	 @ER3,R5L	 ;
	       AND.B	 #B'00000011,R5L ;
	       CMP.B	 #H'0,R5L        ;
	       BEQ	 F40_ERR_RET	 ;V0.C
	       BLD	 #1,R5L 	 ;
	       BCC	 F40V_S_R_21:8	 ;
	       MOV.B	 #1,R5H 	 ;
	       BRA	 F40V_D_CAL	 ;;V0.C
F40V_S_R_21:   MOV.B	 #0,R5H 	 ;;
	       BRA	 F40V_D_CAL	 ;
;
F40V_S_R_3:    CMP.W	 #2,R4		 ;2 bit & 4 bit & 8 bit
	       BNE	 F40V_S_R_4:8	 ;
	       INC.L	 #1,ER3 	 ;
	       MOV.B	 @ER3,R5L	 ;
	       AND.B	 #B'00001111,R5L ;
	       CMP.B	 #H'0,R5L        ;
	       BEQ	 F40_ERR_RET	 ;V0.C
	       BLD	 #3,R5L 	 ;
	       BCC	 F40V_S_R_31:8	 ;
	       MOV.B	 #3,R5H 	 ;
	       BRA	 F40V_D_CAL	 ;
F40V_S_R_31:   BLD	 #2,R5L 	 ;
	       BCC	 F40V_S_R_32:8	 ;
	       MOV.B	 #2,R5H 	 ;
	       BRA	 F40V_D_CAL	 ;;
F40V_S_R_32:   BLD	 #1,R5L 	 ;
	       BCC	 F40V_S_R_33:8	 ;
	       MOV.B	 #1,R5H 	 ;
	       BRA	 F40V_D_CAL	 ;;
F40V_S_R_33:   MOV.B	 #0,R5H 	 ;
	       BRA	 F40V_D_CAL	 ;
;
F40V_S_R_4:    MOV.B	 @ER3,R5L	 ;
	       CMP.B	 #H'0,R5L        ;
	       BEQ	 F40_ERR_RET	 ;V0.C
	       MOV.B	 #0,R5H 	 ;
	       MOV.B	 #8,R6L 	 ;
F40V_S_R_41:   SHLL.B	 R5L		 ;
	       BCS	 F40V_S_R_42:8	 ;
	       INC.B	 R5H		 ;
	       DEC.B	 R6L		 ;
	       BNE	 F40V_S_R_41:8	 ;
F40V_S_R_42:   MOV.B	 #8,R6L 	 ;
	       SUB.B	 R5H,R6L	 ;
	       MOV.B	 R6L,R5H	 ;
F40V_D_CAL:    CMP.W	 #WORD_RANGE,R2  ;
	       BCS	 F40V_D_CAL1:8	 ;
	       MOV.B	 #0,R5L 	 ;
	       MOV.B	 R5L,@ER2	 ;
	       INC.L	 #1,ER2 	 ;
F40V_D_CAL1:   MOV.B	 R5H,@ER2	 ;
	       BRA	 F40_RET	 ;V0.C
;
F40_TABLE      .DATA.B	 0
	       .DATA.B	 0
	       .DATA.B	 0
	       .DATA.B	 1
	       .DATA.B	 3
	       .DATA.B	 7
	       .DATA.B	 15
	       .DATA.B	 31
F40_TABLE1     .DATA.B	 0
	       .DATA.B	 0
	       .DATA.B	 0
	       .DATA.B	 0
	       .DATA.B	 1
	       .DATA.B	 3
	       .DATA.B	 7
	       .DATA.B	 15
F40_TABLE2     .DATA.B	 0	       ;N=1  V0.B
	       .DATA.B	 0	       ;  2
	       .DATA.B	 7	       ;  3  V0.C 0->7
	       .DATA.B	 15	       ;  4
	       .DATA.B	 31	       ;  5
	       .DATA.B	 63	       ;  6
	       .DATA.B	 127	       ;  7
	       .DATA.B	 255	       ;  8



;
F41_SUB:       RTS
F42_SUB:       RTS
;
F43_SUB:       BTST	 #JCS,R1L
	       BNE	 F43_RET:8
F43_SKIP_JUG:  BTST	 #FUN_SKIP,R1L
	       BNE	 F43_RET:8
F43_GO:        MOV.L	 #LABEL_INST_ADDR,ER3
	       AND.W	 #H'007F,R2            ;only bit0 - bit6 available
	       SHLL.W	 R2
	       ADD.W	 R2,R3
	       MOV.W	 @ER3,R2
	       MOV.L	 #MACHINE_CODE,ER3
	       SHLL.W	 R2
	       SHLL.W	 R2
	       SHLL.W	 R2
	       ADD.W	 R2,R3
	       MOV.L	 @ER7,ER4
	       MOV.W	 R3,R4
	       MOV.L	 ER4,@ER7
	       MOV.B	 #H'99,R2L
	       MOV.B	 R2L,@INT_KIND	       ;Return to START_SCAN
	       RTS
F43_RET:       BLD	 #2,R1H
	       RTS
;
F44_SUB:
F44_JCS_JUG:   BTST	 #JCS,R1L
	       BNE	 F44_RET:8
	       BIAND	 #1,R1H
	       BST	 #3,R1H
	       BLD	 #2,R1H
	       BST	 #1,R1H
	       MOV.L	 @ER7,ER4
	       SUB.W	 #13,R4
	       MOV.B	 R1H,@ER4
	       BLD	 #3,R1H
	       BCS	 F44_GO:8
	       BLD	 #ONLS,R1H
	       BOR	 FOR_NEXT
	       BAND	 #2,R1H
	       BCC	 F44_RET:8
F44_GO:        MOV.L	 @ER7,ER4
	       INC.W	 #2,R4
	       MOV.W	 R4,@LABEL_RET_BUFFER
	       MOV.W	 R0,@R0_BUFFER		;;;?????
	       MOV.W	 R1,@R1_BUFFER		;;;?????
	       BLD	 #2,R1H
	       BST	 C_CALL_BUFFER
	       MOV.W	 #0,R0
	       MOV.W	 #0,R1
	       MOV.L	 #LABEL_INST_ADDR,ER3
	       AND.W	 #H'007F,R2
	       SHLL.W	 R2
	       ADD.W	 R2,R3
	       MOV.W	 @ER3,R2
	       MOV.L	 #MACHINE_CODE,ER3
	       SHLL.W	 R2
	       SHLL.W	 R2
	       SHLL.W	 R2
	       ADD.W	 R2,R3
	       MOV.L	 @ER7,ER4
	       MOV.W	 R3,R4
	       MOV.L	 ER4,@ER7
	       MOV.B	 #H'88,R2L
	       MOV.B	 R2L,@INT_KIND	       ;Return to this function
F44_RET:       RTS
;;;;;
F45_SUB:       MOV.B	 @INT_KIND,R2L
CALL_RET:      CMP.B	 #H'88,R2L
	       BNE	 TEN_MSEC_RET:8
	       MOV.W	 @LABEL_RET_BUFFER,R3
	       MOV.W	 #H'000F,E3
	       MOV.W	 @R0_BUFFER,R0
	       MOV.W	 @R1_BUFFER,R1
	       BLD	 C_CALL_BUFFER
	       JMP	 @ER3
TEN_MSEC_RET:  CMP.B	 #H'66,R2L
	       BNE	 IMIB1_RET:8
	       JMP	 @TIMER_B2
IMIB1_RET:     CMP.B	 #H'11,R2L
	       BNE	 IMIA2_RET:8
	       JMP	 @IMIB1_GO2
IMIA2_RET:     CMP.B	 #H'22,R2L
	       BNE	 IMIB2_RET:8
	       JMP	 @IMIA2_GO2
IMIB2_RET:     CMP.B	 #H'33,R2L
	       BNE	 IMIB3_RET:8
	       JMP	 @IMIB2_GO2
IMIB3_RET:     CMP.B	 #H'44,R2L
	       BNE	 IMIB4_RET:8
	       JMP	 @IMIB3_GO2
IMIB4_RET:     CMP.B	 #H'55,R2L
	       BNE	 JUMP_RET:8
	       JMP	 @IMIB4_GO2
JUMP_RET:      BCLR	 USER_WDT_ERR		 ;;VF.3
	       JMP	 @START_SCAN
;
F46_SUB:
F46_JCS_JUG:   BTST	 #JCS,R1L
	       BNE	 F46_RET:8
	       BIAND	 #1,R1H
	       BST	 #3,R1H
	       BLD	 #2,R1H
	       BST	 #1,R1H
	       MOV.L	 @ER7,ER4
	       SUB.W	 #13,R4
	       MOV.B	 R1H,@ER4
	       BLD	 #3,R1H
	       BCS	 F46_GO:8		 ;;V0.8 BUG MODIFY
	       BLD	 #ONLS,R1H		 ;;
    ;;;;;;;    BOR	 FOR_NEXT		 ;;
	       BAND	 #2,R1H 		 ;;
	       BCC	 F46_RET:8		 ;;
F46_GO:        MOV.L	 @ER7,ER4		 ;;
	       INC.L	 #2,ER4 		 ;;
	       MOV.L	 ER4,@FOR_NEXT_ADDR	 ;For next return used
	       CMP.W	 #0,R2			 ;n 1-256
	       BNE	 F46_GO1:8
	  ;;;  BCLR	 FOR_NEXT		 ;;V0.9
	       BRA	 F46_RET:8		 ;;
F46_GO1:       CMP.W	 #D'257,R2
	       BCS	 F46_GO11:8
	    ;; BCLR	 FOR_NEXT
	       BRA	 F46_RET:8
F46_GO11:      BSET	 FOR_NEXT
F46_GO2:       MOV.W	 R2,@FOR_NEXT_LPNUM	 ;For next loop number
	       BCLR	 #FUN_SKIP,R1L		 ;V0.9
	       RTS
F46_RET:       BCLR	 FOR_NEXT
	       BSET	 #FUN_SKIP,R1L
	       BLD	 #JCS,R1L		 ;;V0.9
	       BST	 JCS_BIT		 ;;
	       BSET	 #JCS,R1L		 ;;
	       RTS
;;
F47_SUB:       BLD	 FOR_NEXT
	       BCC	 F46_47_END:8
	       MOV.W	 @FOR_NEXT_LPNUM,R2
	       CMP.W	 #0,R2
	       BEQ	 F46_47_END:8
	       DEC.W	 #1,R2
	       BEQ	 F46_47_END:8
	       MOV.W	 R2,@FOR_NEXT_LPNUM
	       MOV.L	 @ER7,ER3
	       MOV.L	 @FOR_NEXT_ADDR,ER2
	       MOV.W	 R2,R3
	       MOV.L	 ER3,@ER7
	       RTS
F46_47_END:    BCLR	 #FUN_SKIP,R1L
	       BCLR	 FOR_NEXT
	       BLD	 JCS_BIT		 ;;V0.9
	       BST	 #JCS,R1L		 ;;
	       RTS
;
F48_SUB:       BTST	 #JCS,R1L	     ;
	       BNE	 F48_RET	     ;
F48_GO:        BCLR	 JUDGE_NG	     ;
F48_GO1:       CMP.W	 #Y_STATE1,R2	     ;
	       BCS	 X_B_REFRESH	     ;
	       CMP.W	 #C_STATE1,R2	     ;Y's area refresh
	       BCC	 F48_RET	     ;
	       BLD	 JUDGE_NG	     ;
	       BCC	 Y_STATE_F48:8	     ;
Y_STATE_F49:   BTST	 R3L,@ER2	     ;F49 Y's areae refresh
	       BNE	 Y_STATE_F49_1:8     ;
	       MOV.L	 #OUT_STR_ADDR,ER4   ;
	       MOV.W	 @R2_BUFFER,R2	     ;;V0.B
	       ADD.W	 R2,R4		     ;
	       BSET	 R3L,@ER4	     ;
	       BRA	 Y_OUT_R:8	     ;
Y_STATE_F49_1: MOV.L	 #OUT_STR_ADDR,ER4   ;
	       MOV.W	 @R2_BUFFER,R2	     ;;V0.B
	       ADD.W	 R2,R4		     ;
	       BCLR	 R3L,@ER4	     ;
	       BRA	 Y_OUT_R:8	     ;
Y_STATE_F48:   MOV.B	 @ER2,R3H	     ;F48 Y's areae refresh
	       MOV.B	 #0,R2H 	     ;
	       MOV.L	 #OUT_STR_ADDR,ER4   ;
	       ADD.W	 R2,R4		     ;
	       SUB.W	 #H'30,R4            ;
	       MOV.B	 R3H,@ER4	     ;
Y_OUT_R:       MOV.B	 @DOUT_IO_NO,REG_R2  ;
	       MOV.L	 #OUT_STR_ADDR-1,DPTR;
	       PUSH.W	 R0		     ;
	       PUSH.W	 R1		     ;
	       JSR	 @EXE_OUT_D0_B	     ;
	       POP.W	 R1		     ;
	       POP.W	 R0		     ;
	       BSET	 STB_B		     ;
	       MOV.B	 R2L,@STB_A	     ;
	       BCLR	 STB_B		     ;
	       BSET	 IO_INT_BIT	     ;
	       BRA	 F48_RET	     ;
X_B_REFRESH:   MOV.B	 @DINP_IO_NO,REG_R2  ;X's area refresh
	       MOV.L	 #IN_STR_ADDR,DPTR   ;
	       BSET	 PS		     ;
	       NOP			     ;
	       BCLR	 PS		     ;
	       PUSH.W	 R0		     ;
	       PUSH.W	 R1		     ;
	       JSR	 @EXE_READ_BYTE      ;
	       POP.W	 R1		     ;
	       POP.W	 R0		     ;
	       BSET	 IO_INT_BIT	     ;;VF.0 TP02
	       MOV.L	 #IN_STR_ADDR,ER4    ;
	       MOV.B	 R2H,@R6_BUFFER      ;;V0.B
	       MOV.B	 #0,R2H 	     ;
	       ADD.W	 R2,R4		     ;
	       MOV.W	 R4,@R3_BUFFER	     ;;IN_STR_BUFFER
	       MOV.B	 @ER4,R5L	     ;
	       BLD	 JUDGE_NG	     ;
	       BCC	 X_INP_R:8	     ;
	       MOV.L	 #X_STATE,ER4	     ;
	       MOV.W	 @R2_BUFFER,R2	     ;
	       ADD.W	 R2,R4		     ;
	       MOV.W	 @R3_BUFFER,R2	     ;;IN_STR_BUFFER
	       MOV.B	 @R4_BUFFER,R3L      ;;V0.B
	       BTST	 R3L,@ER2	     ;
	       BNE	 X_B_R1:8	     ;
	       BCLR	 R3L,@ER4	     ;
	       BRA	 F48_RET:8	     ;
X_B_R1:        BSET	 R3L,@ER4	     ;
	       BRA	 F48_RET:8	     ;
X_INP_R:       MOV.B	 @R6_BUFFER,R2H      ;;V0.B
	       MOV.B	 R5L,@ER2	     ;F48 X
F48_RET:       BLD	 #2,R1H 	     ;
	       RTS			     ;
;
F49_SUB:       BTST	 #JCS,R1L	     ;
	       BNE	 F48_RET	     ;
	       BSET	 JUDGE_NG	     ;
F49_SET_D2_1:  MOV.B	 R2H,R4L
	       MOV.B	 R2H,R4H
	       AND.B	 #B'00000111,R4H     ;;R4H bit number
	       ROTL.B	 R2H
	       ROTL.B	 R2H
	       ROTL.B	 R2H
	       AND.B	 #B'00000111,R2H     ;;R2 byte address
	       AND.B	 #B'00011000,R4L
	       MOV.W	 R2,@R2_BUFFER	     ;;V0.B
F49_Y:	       CMP.B	 #B'00001000,R4L
	       BNE	 F49_X:8
	       MOV.L	 #Y_STATE,ER5
	       ADD.W	 R2,R5
	       BRA	 F49_GO:8
F49_X:	       MOV.L	 #X_STATE,ER5
	       ADD.W	 R2,R5
F49_GO:        MOV.W	 R5,R2
	       MOV.B	 R4H,R3L
	       MOV.B	 R4H,@R4_BUFFER      ;;V0.B bit number
	       MOV.B	 #0,R3H
	       BRA	 F48_GO1	     ;
;  0 -> 0
;  0 -> 1  reset timer
;  1 -> 0  reset timer
;  1 -> 1
F50_SUB:       MOV.B	 R5L,@R6L_BUFFER   ;Byte number buffer , 0-7
	       MOV.W	 R2,@R2_BUFFER	   ;Y,C absolute address
	       MOV.W	 R3,@R3_BUFFER	   ;V address
	       MOV.W	 R4,@R4_BUFFER	   ;n
	       AND.B	 #B'00000111,R5L   ;
	       JSR	 @BIT_S_R	   ;
F50_TR_R:      BLD	 #2,R1H 	    ;b2 : current cycle
	       BXOR	 #0,R1H 	    ;b0 : last cycle
	       BST	 #1,R1H 	    ;
	       BLD	 #2,R1H 	    ;
	       BST	 #0,R1H 	    ;
	       BLD	 #1,R1H 	    ;
	       BCC	 F50_TR_R1:8	    ;
	       BSET	 #3,R1H 	    ;;TR already been trigger
F50_TR_R1:     MOV.L	 @ER7,ER4	    ;
	       SUB.W	 #D'31,R4           ;
	       MOV.B	 R1H,@ER4	    ;
	       BLD	 PULSE_EN	    ;;V0.8 BUG MODIFY, FIRST SCAN NO
	       BCC	 F50_RET2	    ;;OPERATION
	       BLD	 #3,R1H 	    ;;
	       BCC	 F50_RET2	    ;;
	       BLD	 #1,R1H 	    ;
	       BCC	 F50_GO:8	    ;
F50_RST_TMR:   MOV.W	 #0,R4		    ;RESET TIMER(OFF->ON or ON->OFF)
	       MOV.W	 R4,@ER3	    ;
F50_GO:        BLD	 #2,R1H 	    ;
	       BCC	 F50_GO1:8	    ;
	       BSET	 F50_BIT1	    ;TR = ON
F50_GO1:       BLD	 #1,R1H 	    ;
	       BCC	 F50_TMR:8	    ;
	       BLD	 #2,R1H 	    ;
	       BCS	 F50_GO2:8	    ;
	       BSET	 F50_BIT1	    ;ON->OFF
	       BCLR	 F50_BIT3	    ;
	       BRA	 F50_TMR:8	    ;
F50_GO2:       BSET	 F50_BIT3	    ;OFF->ON
F50_TMR:       MOV.W	 @R3_BUFFER,R3	    ;
	       SUB.W	 #V_MEMORY_ADDR1,R3 ;
	       SHLR.W	 R3		    ;
	       CMP.W	 #D'250,R3          ;VF.6 #D'251->D'250
	       BCC	 F50_10MS	    ;
	       MOV.B	 @TIME_DIFF_10MS,R5L;A
	       MOV.L	 #T_C_STATUS,ER2    ;ER4->ER2
	       ADD.W	 R3,R2		    ;
	       MOV.B	 @ER2,R6L	    ;B
	       ADD.B	 R5L,R6L	    ;
	       MOV.B	 R6L,@ER2	    ;
	       MOV.B	 #0,R6H 	    ;
	       MOV.B	 #D'10,R5L          ;
	       DIVXU.B	 R5L,R6 	    ;R6H:F R6L:E
	       CMP.B	 #5,R6L 	    ;
	       BEQ	 F50_INC_V:8	    ;!!!!!!!!IMPORTANT!!!!!!!
	       MOV.B	 R6H,@ER2	    ;
F50_INC_V:     MOV.W	 @R3_BUFFER,R3	    ;
	       MOV.W	 @ER3,R5	    ;V current value
	       MOV.B	 #0,R6H 	    ;
	       ADD.W	 R6,R5		    ;R5: V cuurrent value
	       MOV.W	 R5,@ER3	    ;
	       BRA	 F50_V_COMPARE:8    ;
F50_10MS:      .EQU	 $		    ;
	       MOV.B	 @TIME_DIFF_10MS,R6L;A
	       BRA	 F50_INC_V:8	    ;
F50_V_COMPARE: MOV.W	 @R4_BUFFER,R4	    ;
	       BLD	 #6,R1H 	    ;
	       BCC	 F50_D_N	    ;
F50_D_TYPE:    MOV.W	 @ER4,R6	    ;
	       MOV.W	 R6,R4		    ;
F50_D_N:       CMP.W	 R4,R5		    ;
	       BCS	 F50_RET	    ;
F50_T_OVER:    MOV.W	 R4,@ER3	    ;;;;????
	       BLD	 #2,R1H
	       BCS	 F50_T_OVER1:8
	       BCLR	 F50_BIT1
	       BRA	 F50_RET:8
F50_T_OVER1:   BCLR	 F50_BIT3
F50_RET:       BILD	 #2,R1H
	       BAND	 F50_BIT1
	       BST	 F50_BIT2
	       BILD	 F50_BIT3
	   ;;; BAND	 #2,R1H
	       BAND	 F50_BIT1	      ;;VF.5
	       BST	 F50_BIT4
	       MOV.B	 @R6L_BUFFER,R5L
	       MOV.W	 @R2_BUFFER,R2
	       JSR	 @BIT_S_W
F50_RET2:      BLD	 #2,R1H
	       RTS			    ;
;
F51_SUB:       .EQU	 $		    ;;V0.8
F51_JCS_JUG:   BTST	 #JCS,R1L
	       BNE	 F51_RET
	       BLD	 #2,R1H
	       BST	 #1,R1H
	       MOV.L	 @ER7,ER4
	       SUB.W	 #21,R4
	       MOV.B	 R1H,@ER4
F51_REST:      BLD	 #3,R1H
	       BCS	 F51_GO:8
	       BLD	 #ONLS,R1H	  ;R1L->R1H
	       BOR	 FOR_NEXT
	       BAND	 #2,R1H
	       BCC	 F51_RET
F51_GO:        BLD	 #4,R1H
	       BCS	 F51W_GO
;;
F51B_GO:       .EQU	 $
;;R2H: R10, R9,  R8,  TP1, TP0, B2, B1, B0
;;R2L: R7 , R6,  R5,  R4, R3, R2, R1, R0
F51B_GO1:      MOV.B	 R2H,R4L
	       MOV.B	 R2H,R4H
	       AND.B	 #B'00000111,R4H   ;; R4H: bit number
	       ROTL.B	 R2H
	       ROTL.B	 R2H
	       ROTL.B	 R2H
	       AND.B	 #B'00000111,R2H   ;; R2: byte address
	       AND.B	 #B'00011000,R4L   ;; R4L: coil type(X/Y/C)
F51_X:	       CMP.B	 #B'00000000,R4L
	       BNE	 F51_Y:8
	       MOV.L	 #X_STATE,ER5
	       ADD.W	 R2,R5
	       BRA	 F51B_V_D_J:8
F51_Y:	       CMP.B	 #B'00001000,R4L
	       BNE	 F51_C:8
	       MOV.L	 #Y_STATE,ER5
	       ADD.W	 R2,R5
	       BRA	 F51B_V_D_J:8
F51_C:	       CMP.B	 #B'00010000,R4L
	       BNE	 F51_M:8
	       MOV.L	 #C_STATE,ER5
	       ADD.W	 R2,R5
	       BRA	 F51B_V_D_J:8
F51_M:	       MOV.L	 #M_STATE,ER5
	       ADD.W	 R2,R5
F51B_V_D_J:    BLD	 #6,R1H
	       BCC	 F51B_S_N
F51B_S_V:      MOV.W	 @ER3,R6
	       MOV.W	 R6,R3
F51B_S_N:      CMP.W	 #0,R3		   ;RESET NUMBER = 0
	       BEQ	 F51_RET
F51B_CLR_LP:   BCLR	 R4H,@ER5
	       INC.B	 R4H
	       CMP.B	 #H'8,R4H
	       BNE	 F51B_R_NO:8
	       MOV.B	 #0,R4H
	       INC.L	 #1,ER5
F51B_R_NO:     DEC.W	 #1,R3
	       BNE	 F51B_CLR_LP:8
F51_RET:       BLD	 #2,R1H
	       RTS
;;
F51W_GO:       BLD	 #6,R1H
	       BCC	 F51W_S_V:8
	       MOV.W	 @ER3,R4
	       MOV.W	 R4,R3
F51W_S_V:      CMP.W	 #0,R3
	       BEQ	 F51_RET:8
	       MOV.W	 #0,R4
	       CMP.W	 #V_MEMORY_ADDR1,R2
	       BCC	 F51W_RESET
F51W_BYTE_R:   MOV.B	 R4L,@ER2
	       INC.L	 #1,ER2
	       CMP.L	 #M_STATE,ER2
	       BCC	 F51_RET
	       DEC.W	 #1,R3
	       BNE	 F51W_BYTE_R:8
	       BRA	 F51_RET
F51W_RESET:    MOV.W	 R4,@ER2
	       INC.L	 #2,ER2
	       CMP.L	 #WS_MEMORY_ADDR,ER2
	       BCC	 F51_RET
	       DEC.W	 #1,R3
	       BNE	 F51W_RESET:8
	       BRA	 F51_RET
;
F52_SUB:       BLD	 #2,R1H 	   ;;V0.A
	       BCC	 F52_RESET_FLAG    ;;
	       MOV.W	 R2,@R2_BUFFER
	       MOV.W	 R3,@R3_BUFFER
;;R2H: R10, R9,  R8,  T1, T0, B2, B1, B0
;;R2L: R7 , R6,  R5,  R4, R3, R2, R1, R0
	       MOV.W	 R4,R5		   ;CHECK X RELAY ADDRESS
	       AND.B	 #B'00000111,R5H   ;;R5H byte number
	       ROTL.B	 R4H
	       ROTL.B	 R4H
	       ROTL.B	 R4H
	       AND.B	 #B'00000111,R4H   ;
	       MOV.L	 #X_STATE,ER6
	       ADD.W	 R4,R6		   ;
	       MOV.L	 ER6,ER4	   ;ER4 X ADDRESS
	       MOV.B	 #H'FF,R5L
	       MOV.B	 #D'10,R6L
F52_DECO_LP1:  BTST	 R5H,@ER4
	       BEQ	 F52_DECO_LP11:8
	       MOV.B	 R6L,@F52_TENK1    ;SCAN CODE
	       INC.B	 R5L		   ;SCAN NUMBER
F52_DECO_LP11: INC.B	 R5H
	       CMP.B	 #8,R5H
	       BNE	 F52_DECO_LP2:8
	       MOV.B	 #0,R5H
	       INC.W	 #1,R4
F52_DECO_LP2:  DEC.B	 R6L
	       BNE	 F52_DECO_LP1:8
F52_DECO_OK:   MOV.B	 @F52_TENK,R6L	    ;NEW
	       CMP.B	 #H'FF,R5L
	       BEQ	 F52_NO_KEYIN
	       CMP.B	 #D'00,R5L
	       BNE	 F52_NOT_BCD
	       MOV.B	 @F52_TENK1,R5H
	       MOV.B	 #D'10,R5L
	       SUB.B	 R5H,R5L
	       CMP.B	 R5L,R6L
	       BNE	 F52_SCAN_OK	     ;SAME LAST SCAN CODE
	       MOV.L	 #SC041_ADDR,ER6
	       BCLR	 #3,@ER5
	       MOV.B	 R5L,@F52_TENK
	       BRA	 F52_RET
F52_NOT_BCD:   MOV.L	 #SC041_ADDR,ER6
	       BSET	 #3,@ER5
	       MOV.B	 R5L,@F52_TENK
	       BRA	 F52_RET
F52_NO_KEYIN:  MOV.L	 #SC065_ADDR,ER6
	       BCLR	 #0,@ER6		;CLR SC065
	       MOV.B	 R5L,@F52_TENK
	       BRA	 F52_RET
F52_SCAN_OK:   MOV.B	 R5L,@F52_TENK
	       MOV.L	 #SC065_ADDR,ER6
	       BSET	 #0,@ER6		;SET SC065
F52_SHIFT_IN:  MOV.W	 @R2_BUFFER,R2
	       MOV.W	 #H'000F,E2
	       MOV.W	 @ER2,R6
	       INC.L	 #2,ER2
	       MOV.W	 @ER2,E6
	       SHLL.L	 ER6
	       SHLL.L	 ER6
	       SHLL.L	 ER6
	       SHLL.L	 ER6
	       AND.B	 #H'0F,R5L
	       OR.B	 R5L,R6L
	       MOV.W	 E6,@ER2
	       DEC.L	 #2,ER2
	       MOV.W	 R6,@ER2
F52_SET_D2:    MOV.W	 @R3_BUFFER,R2
;;R2H: R10, R9,  R8,  T1, T0, B2, B1, B0
;;R2L: R7 , R6,  R5,  R4, R3, R2, R1, R0
F52_SET_D2_1:  MOV.B	 R2H,R4L
	       MOV.B	 R2H,R4H
	       AND.B	 #B'00000111,R4H   ;;R4H byte number
	       ROTL.B	 R2H
	       ROTL.B	 R2H
	       ROTL.B	 R2H
	       AND.B	 #B'00000111,R2H   ;;R2 byte address
	       AND.B	 #B'00011000,R4L
F52_Y:	       CMP.B	 #B'00001000,R4L
	       BNE	 F52_C:8
	       MOV.L	 #Y_STATE,ER5
	       ADD.W	 R2,R5
	       BRA	 F52_SET_D2_2:8
F52_C:	       MOV.L	 #C_STATE,ER5
	       ADD.W	 R2,R5
F52_SET_D2_2:  MOV.L	 ER5,ER6
	       MOV.B	 #D'10,R2L
F52B_CLR_LP:   BCLR	 R4H,@ER5
	       INC.B	 R4H
	       CMP.B	 #H'8,R4H
	       BNE	 F52B_R_NO:8
	       MOV.B	 #0,R4H
	       INC.L	 #1,ER5
F52B_R_NO:     DEC.B	 R2L
	       BNE	 F52B_CLR_LP:8
	       MOV.B	 @F52_TENK,R4L
	       CMP.B	 #H'8,R4L
	       BCC	 F52B_INC1:8
	       BSET	 R4L,@ER6
	       BRA	 F52_RET
F52B_INC1:     SUBX.B	 #8,R4L
	       INC.L	 #1,ER6
	       BSET	 R4L,@ER6
F52_RET:       BLD	 #2,R1H
	       RTS
F52_RESET_FLAG: .EQU	 $
	       JSR	 @FLAG_RESET
	       BLD	 #2,R1H
	       RTS
;
F53_SUB:       MOV.W	 R2,@R2_BUFFER	   ;R2->D address
	       MOV.W	 R3,@R3_BUFFER	   ;R3->X address
	       MOV.W	 R4,@R4_BUFFER	   ;R4->Y address
F53_CHK_X:     MOV.W	 R3,R5		   ;CHECK X RELAY ADDRESS
	       AND.B	 #B'00000111,R5H   ;;R5H relay number
	       MOV.B	 R5H,@R5_BUFFER    ;;R5H buffer
	       ROTL.B	 R3H		   ;
	       ROTL.B	 R3H		   ;
	       ROTL.B	 R3H		   ;
	       AND.B	 #B'00000111,R3H   ;
	       MOV.L	 #X_STATE,ER6	   ;
	       ADD.W	 R3,R6		   ;
	       MOV.L	 ER6,ER3	   ;ER3 X ADDRESS
F53_CHK_Y:     MOV.W	 R4,R5		   ;CHECK Y RELAY ADDRESS
	       AND.B	 #B'00000111,R5H   ;;R5H relay number
	       MOV.B	 R5H,@R5_BUFFER+1  ;;R5L buffer
	       ROTL.B	 R4H		   ;
	       ROTL.B	 R4H		   ;
	       ROTL.B	 R4H		   ;
	       AND.B	 #B'00000111,R4H   ;
	       MOV.L	 #Y_STATE,ER6	   ;
	       ADD.W	 R4,R6		   ;
	       MOV.L	 ER6,ER4	   ;ER4 Y ADDRESS
	       MOV.W	 R4,@R4_BUFFER	   ;
F53_SCAN_X:    MOV.L	 ER3,ER2
	       MOV.B	 @R5_BUFFER,R5L
	       JSR	 @BIT_S_R
	       MOV.B	 #0,R5L
	       BLD	 F50_BIT1
	       BST	 #0,R5L
	       BLD	 F50_BIT2
	       BST	 #1,R5L
	       BLD	 F50_BIT3
	       BST	 #2,R5L
	       BLD	 F50_BIT4
	       BST	 #3,R5L
	       CMP.B	 #0,R5L
	       BNE	 F53_CMP1:8
	       MOV.B	 #H'80,R5L           ;;NOTHING SCAN
	       BRA	 F53_CAL:8
F53_CMP1:      CMP.B	 #B'00000001,R5L
	       BNE	 F53_CMP2:8
	       MOV.B	 #0,R5L
	       BRA	 F53_CAL:8
F53_CMP2:      CMP.B	 #B'00000010,R5L
	       BNE	 F53_CMP3:8
	       MOV.B	 #1,R5L
	       BRA	 F53_CAL:8
F53_CMP3:      CMP.B	 #B'00000100,R5L
	       BNE	 F53_CMP4:8
	       MOV.B	 #2,R5L
	       BRA	 F53_CAL:8
F53_CMP4:      CMP.B	 #B'00001000,R5L
	       BEQ	 F53_CMP4_1:8
	       MOV.B	 #H'80,R5L
	       BRA	 F53_CAL:8
F53_CMP4_1:    MOV.B	 #3,R5L
F53_CAL:       MOV.B	 R5L,@R5_BUFFER   ;X INPUT CODE(0,1,2,3,FF)
F53_SCAN_Y:    MOV.L	 ER4,ER2
	       MOV.B	 @R5_BUFFER+1,R5L
	       JSR	 @BIT_S_R
	       MOV.B	 #0,R5L
	       BLD	 F50_BIT2     ;1
	       BST	 #0,R5L       ;
	       BLD	 F50_BIT3     ;2
	       BST	 #1,R5L       ;
	       BLD	 F50_BIT4     ;3
	       BST	 #2,R5L       ;
	       BLD	 F50_BIT1     ;4
	       BST	 #3,R5L
	       CMP.B	 #0,R5L
	       BEQ	 F53_NOT_INITIAL  ;;NOT YET SET SCAN CODE
F53_CMP11:     CMP.B	 #B'00000001,R5L
	       BNE	 F53_CMP21:8
	       MOV.B	 #0,R5H
	       BRA	 F53_CAL_IN:8
F53_CMP21:     CMP.B	 #B'00000010,R5L
	       BNE	 F53_CMP31:8
	       MOV.B	 #D'4,R5H
	       BRA	 F53_CAL_IN:8
F53_CMP31:     CMP.B	 #B'00000100,R5L
	       BNE	 F53_CMP41:8
	       MOV.B	 #D'8,R5H
	       BRA	 F53_CAL_IN:8
F53_CMP41:     CMP.B	 #B'00001000,R5L
	       BNE	 F53_NOT_INITIAL  ;;NOT YET SET SCAN CODE
	       MOV.B	 #D'12,R5H
F53_CAL_IN:    MOV.B	 @R5_BUFFER,R5L
	       ADD.B	 R5H,R5L
F53_CAL_IN1:   BLD	 F50_BIT1
	       BCC	 F53_CAL_IN2:8
	       MOV.B	 R5L,@F50_BIT1_BUFF
	       BRA	 F53_Y_ROTATE
F53_CAL_IN2:   BLD	 F50_BIT2
	       BCC	 F53_CAL_IN3:8
	       MOV.B	 R5L,@F50_BIT2_BUFF
	       BRA	 F53_Y_ROTATE
F53_CAL_IN3:   BLD	 F50_BIT3
	       BCC	 F53_CAL_IN4:8
	       MOV.B	 R5L,@F50_BIT3_BUFF
	       BRA	 F53_Y_ROTATE
F53_CAL_IN4:   MOV.B	 R5L,@F50_BIT4_BUFF
	       MOV.B	 @F50_BIT1_BUFF,R5H
	       MOV.B	 @F50_BIT2_BUFF,R6L
	       MOV.B	 @F50_BIT3_BUFF,R6H
	       BLD	 #7,R5L
	       BAND	 #7,R5H
	       BAND	 #7,R6L
	       BAND	 #7,R6H
	       BCS	 F53_RELEASE_RELAY
	       CMP.B	 #H'80,R5L
	       BCC	 F53_CAL_IN5:8
	       BRA	 F53_SCAN_CODE:8
F53_CAL_IN5:   CMP.B	 #H'80,R5H
	       BCC	 F53_CAL_IN6:8
	       MOV.B	 R5H,R5L
	       BRA	 F53_SCAN_CODE:8
F53_CAL_IN6:   CMP.B	 #H'80,R6H
	       BCC	 F53_CAL_IN7:8
	       MOV.B	 R6H,R5L
	       BRA	 F53_SCAN_CODE:8
F53_CAL_IN7:   CMP.B	 #H'80,R6L
	       BCC	 F53_RELEASE_RELAY
	       MOV.B	 R6L,R5L
F53_SCAN_CODE: MOV.B	 @F53_SCAN,R6L	  ;;LAST CYCLE'S SCAN CODE
	       CMP.B	 R5L,R6L
	       BEQ	 F53_Y_ROTATE
	       MOV.W	 @WS001_ADDR,R4   ;;;VF.3  SCAN TIME<10mS, debounce !
	       CMP.W	 #D'10,R4         ;;;
	       BCC	 F53_SCAN_CD1:8   ;;;
	       BLD	 F53_SCAN_BOUNCE  ;;;
	       BCS	 F53_SCAN_CD0:8   ;;;
	       BSET	 F53_SCAN_BOUNCE  ;;;
	       BRA	 F53_Y_ROTATE	  ;;;
F53_SCAN_CD0:  BCLR	 F53_SCAN_BOUNCE  ;;;
F53_SCAN_CD1:  MOV.B	 R5L,@F53_SCAN
F53_NEW_DATA_IN:  .EQU	 $
	       CMP.B	 #D'10,R5L
	       BCC	 F53_A_F_PRESSED
F53_DATA_OK:   MOV.W	 @R2_BUFFER,R2
	       MOV.L	 @ER2,ER6
	       MOV.W	 E6,E5
	       MOV.W	 R6,E6
	       MOV.W	 E5,R6
	       SHLL.L	 ER6
	       SHLL.L	 ER6
	       SHLL.L	 ER6
	       SHLL.L	 ER6
	       AND.B	 #H'0F,R5L
	       OR.B	 R5L,R6L
	       MOV.W	 E6,E5
	       MOV.W	 R6,E6
	       MOV.W	 E5,R6
	       MOV.L	 ER6,@ER2
	       MOV.L	 #SC065_ADDR,ER6
	       BSET	 #1,@ER6	    ;SET SC066 ON
	       BRA	 F53_Y_ROTATE
F53_A_F_PRESSED: .EQU	 $
	       MOV.L	 #SC065_ADDR,ER6
	       MOV.B	 @ER6,R5H
	       AND.B	 #B'00000011,R5H
	       MOV.B	 R5H,@ER6
F53_SC067:     CMP.B	 #D'10,R5L
	       BNE	 F53_SC068:8
	       BSET	 #2,@ER6
	       BRA	 F53_Y_ROTATE
F53_SC068:     CMP.B	 #D'11,R5L
	       BNE	 F53_SC069:8
	       BSET	 #3,@ER6
	       BRA	 F53_Y_ROTATE
F53_SC069:     CMP.B	 #D'12,R5L
	       BNE	 F53_SC070:8
	       BSET	 #4,@ER6
	       BRA	 F53_Y_ROTATE
F53_SC070:     CMP.B	 #D'13,R5L
	       BNE	 F53_SC071:8
	       BSET	 #5,@ER6
	       BRA	 F53_Y_ROTATE
F53_SC071:     CMP.B	 #D'14,R5L
	       BNE	 F53_SC072:8
	       BSET	 #6,@ER6
	       BRA	 F53_Y_ROTATE
F53_SC072:     BSET	 #7,@ER6
	       BRA	 F53_Y_ROTATE
F53_RELEASE_RELAY: .EQU  $
	       MOV.B	 #H'FF,R4L
	       MOV.B	 R4L,@F53_SCAN
	       MOV.L	 #SC065_ADDR,ER6
	       BCLR	 #1,@ER6	  ;;SET SC066 OFF
F53_Y_ROTATE:  .EQU	 $
	       MOV.B	 @R5_BUFFER+1,R5L ;;RELAY Y NUMBER
	       MOV.W	 @R4_BUFFER,R2	  ;;RELAY Y ADDRESS
	       MOV.W	 #H'000F,E2       ;;
F53_SCAN_NUM:  BLD	 F50_BIT4
	       BST	 F50_BIT5
	       BLD	 F50_BIT3
	       BST	 F50_BIT4
	       BLD	 F50_BIT2
	       BST	 F50_BIT3
	       BLD	 F50_BIT1
	       BST	 F50_BIT2
	       BLD	 F50_BIT5
	       BST	 F50_BIT1
	       JSR	 @BIT_S_W	    ;;REFRESH Yxxxx
F53_STILL_SAME: .EQU	 $
F53_DOUBLE_PRESS: .EQU	 $
F53_RET:       BLD	 #2,R1H
	       RTS
F53_NOT_INITIAL: .EQU	 $
	       BCLR	 F53_BIT_IN
	       MOV.B	 #H'FF,R4L
	       MOV.B	 R4L,@F53_SCAN
	       MOV.B	 @R5_BUFFER+1,R5H ;;RELAY Y NUMBER
	       MOV.W	 @R4_BUFFER,R2	  ;;RELAY Y ADDRESS
	       MOV.W	 #H'000F,E2       ;;
F53_NOT_Y1:    BSET	 R5H,@ER2
F53_NOT_Y2:    INC.B	 R5H
	       CMP.B	 #H'8,R5H
	       BCS	 F53_NOT_Y2_1:8
	       MOV.B	 #0,R5H
	       INC.L	 #1,ER2
F53_NOT_Y2_1:  BCLR	 R5H,@ER2
F53_NOT_Y3:    INC.B	 R5H
	       CMP.B	 #H'8,R5H
	       BCS	 F53_NOT_Y3_1:8
	       MOV.B	 #0,R5H
	       INC.L	 #1,ER2
F53_NOT_Y3_1:  BCLR	 R5H,@ER2
F53_NOT_Y4:    INC.B	 R5H
	       CMP.B	 #H'8,R5H
	       BCS	 F53_NOT_Y4_1:8
	       MOV.B	 #0,R5H
	       INC.L	 #1,ER2
F53_NOT_Y4_1:  BCLR	 R5H,@ER2
	       BRA	 F53_RET
;
F54_SUB:       .EQU	 $
	       MOV.W	 @WS001_ADDR,R5     ;;
	       CMP.W	 #H'0005,R5         ;
	       BCC	 F54_SUB1:8	    ;
	       BSET	 F54_FILTER	    ;
	       BRA	 F54B_GO:8	    ;
F54_SUB1:      BCLR	 F54_FILTER	    ;
F54B_GO:       MOV.B	 @ER4,R5L	    ;;Y's data
	       MOV.B	 R5L,@R5L_BUFFER    ;;PUSH Y's data
	       BLD	 #5,R1H
	       BCS	 F54B_Y1:8	    ;;double word
	       BLD	 #4,R1H
	       BCS	 F54B_GO1:8	    ;;word
	       AND.B	 #B'00001111,R5L    ;;byte
	       BRA	 F54B_Y1:8
F54B_GO1:      AND.B	 #B'00111111,R5L
F54B_Y1:       CMP.B	 #H'1,R5L
	       BNE	 F54B_Y2:8
	       MOV.B	 @ER3,R5H
	       BLD	 #5,R1H
	       BCS	 F54B_Y11:8	    ;;double word
	       BLD	 #4,R1H
	       BCS	 F54B_Y12:8	    ;;word
	       BRA	 F54B_Y13:8
F54B_Y11:      ADD.L	 #7,ER2
	       BRA	 F54B_Y14:8
F54B_Y12:      ADD.L	 #5,ER2
	       BRA	 F54B_Y14:8
F54B_Y13:      ADD.L	 #3,ER2
F54B_Y14:      MOV.B	 #H'2,R5L
	       BRA	 F54_RET
;;
F54B_Y2:       CMP.B	 #H'2,R5L
	       BNE	 F54B_Y3:8
	       MOV.B	 @ER3,R5H
F54B_Y21:      MOV.B	 #H'4,R5L
	       BRA	 F54_RET
;;
F54B_Y3:       CMP.B	 #H'4,R5L
	       BNE	 F54B_Y4:8
	       MOV.B	 @ER3,R5H
	       INC.L	 #1,ER2
F54B_Y31:      MOV.B	 #H'8,R5L
	       BRA	 F54_RET
;;
F54B_Y4:       CMP.B	 #H'8,R5L
	       BNE	 F54B_Y5:8
	       MOV.B	 @ER3,R5H
	       ADD.L	 #2,ER2
F54B_Y40:      BLD	 #5,R1H 	 ;;
	       BCS	 F54B_Y41:8	 ;;double word
	       BLD	 #4,R1H 	 ;;
	       BCS	 F54B_Y41:8	 ;;word
	       MOV.B	 #H'01,R5L       ;;byte
	       BRA	 F54_RET
F54B_Y41:      MOV.B	 #H'10,R5L
	       BRA	 F54_RET
;;
F54B_Y5:       CMP.B	 #H'10,R5L
	       BNE	 F54B_Y6:8
	       MOV.B	 @ER3,R5H
	       ADD.L	 #3,ER2
F54B_Y52:      MOV.B	 #H'20,R5L
	       BRA	 F54_RET
;;
F54B_Y6:       CMP.B	 #H'20,R5L
	       BNE	 F54B_Y7:8
	       MOV.B	 @ER3,R5H
	       ADD.L	 #4,ER2
F54B_Y60:      BLD	 #5,R1H 	 ;;
	       BCS	 F54B_Y61:8	 ;;double word
	       MOV.B	 #H'01,R5L       ;;
	       BRA	 F54_RET	 ;;
F54B_Y61:      MOV.B	 #H'40,R5L
	       BRA	 F54_RET
;;
F54B_Y7:       CMP.B	 #H'40,R5L
	       BNE	 F54B_Y8:8
	       MOV.B	 @ER3,R5H
	       ADD.L	 #5,ER2
F54B_Y72:      MOV.B	 #H'80,R5L
	       BRA	 F54_RET
;;
F54B_Y8:       CMP.B	 #H'80,R5L
	       BNE	 F54B_Y_RESET:8
	       MOV.B	 @ER3,R5H
	       ADD.L	 #6,ER2
F54B_Y_RESET:  MOV.B	 #H'01,R5L
F54_RET:       BLD	 F54_FILTER
	       BCC	 F54_RET0:8
	       BLD	 F54_FILTER_ON
	       BCS	 F54_RET00:8
F54_RET0:      MOV.B	 R5H,@ER2
F54_RET00:     MOV.B	 @R5L_BUFFER,R5H
	       BLD	 #5,R1H
	       BCS	 F54_RET2:8	    ;;double word
	       BLD	 #4,R1H
	       BCS	 F54_RET1:8	    ;;word
	       AND.B	 #B'11110000,R5H
	       OR.B	 R5H,R5L
	       BRA	 F54_RET2:8
F54_RET1:      AND.B	 #B'11000000,R5H
	       OR.B	 R5H,R5L
F54_RET2:      BLD	 F54_FILTER
	       BCC	 F54_RET3:8
	       BLD	 F54_FILTER_ON
	       BCS	 F54_RET3:8
	       BSET	 F54_FILTER_ON
	       BLD	 #2,R1H
	       RTS
F54_RET3:      MOV.B	 R5L,@ER4
	       BCLR	 F54_FILTER_ON
	       BLD	 #2,R1H
	       RTS
;;;;;;
F55_DSW_SUB:   MOV.W	 @F55_DSW,R6
	       AND.B	 #H'F0,R6L
	       OR.B	 R5H,R6L
	       ROTR.W	 R6
	       ROTR.W	 R6
	       ROTR.W	 R6
	       ROTR.W	 R6
	       MOV.W	 R6,@F55_DSW
	       RTS
F55W_DSW_SUB:  MOV.L	 @F55_DSW,ER6
	       AND.B	 #H'F0,R6L
	       OR.B	 R5H,R6L
	       ROTR.L	 ER6
	       ROTR.L	 ER6
	       ROTR.L	 ER6
	       ROTR.L	 ER6
	       MOV.L	 ER6,@F55_DSW
	       RTS
F55_DSW_SUB1:  MOV.B	 @R5L_BUFFER,R5H
	       AND.B	 #B'11110000,R5H
	       OR.B	 R5H,R5L
	       MOV.B	 R5L,@ER4
	       RTS



F55_SUB:       .EQU	 $
	       BLD	 #2,R1H
	       BCC	 F55_RESET_FLAG
F55B_GO:       MOV.B	 @ER4,R5L	    ;;Y's data
	       MOV.B	 R5L,@R5L_BUFFER
	       BLD	 #4,R1H
	       BCS	 F55B_Y1:8	    ;;Word
	       AND.B	 #B'00001111,R5L
F55B_Y1:       CMP.B	 #H'1,R5L
	       BNE	 F55B_Y2:8
	       MOV.L	 #SC073_ADDR,ER6
	       BSET	 #0,@ER6
	       MOV.B	 @ER3,R5H
	       AND.B	 #H'0F,R5H
	       CMP.B	 #H'0A,R5H
	       BCC	 F55_NOT_BCD
	       BLD	 #4,R1H
	       BCS	 F55W_Y1:8
	       BSR	 F55_DSW_SUB	   ;;;;;;
F55B_REFRESH:  MOV.W	 @F55_DSW,R6
	       MOV.W	 R6,@ER2
	       MOV.B	 #B'00000010,R5L
	       BSR	 F55_DSW_SUB1
	       BRA	 F55_RET
F55W_Y1:       BSR	 F55W_DSW_SUB
	       MOV.L	 @F55_DSW,ER6
	       MOV.W	 R6,@ER2
	       INC.L	 #2,ER2
	       MOV.W	 E6,@ER2
	       MOV.B	 #B'00000010,R5L
	       MOV.B	 R5L,@ER4
	       BRA	 F55_RET
;;;;
F55B_Y2:       CMP.B	 #H'2,R5L
	       BNE	 F55B_Y3:8
	       MOV.L	 #SC073_ADDR,ER6
	       BCLR	 #0,@ER6
	       MOV.B	 @ER3,R5H
	       AND.B	 #H'0F,R5H
	       CMP.B	 #H'0A,R5H
	       BCC	 F55_NOT_BCD
	       BLD	 #4,R1H
	       BCS	 F55W_Y2:8
	       BSR	 F55_DSW_SUB	   ;;;;;;
	       MOV.B	 #B'00000100,R5L
	       BSR	 F55_DSW_SUB1
	       BRA	 F55_RET
F55W_Y2:       BSR	 F55W_DSW_SUB
	       MOV.B	 #B'00000100,R5L
	       MOV.B	 R5L,@ER4
	       BRA	 F55_RET
;;;;;
F55B_Y3:       CMP.B	 #H'4,R5L
	       BNE	 F55B_Y4:8
	       MOV.B	 @ER3,R5H
	       AND.B	 #H'0F,R5H
	       CMP.B	 #H'0A,R5H
	       BCC	 F55_NOT_BCD
	       BLD	 #4,R1H
	       BCS	 F55W_Y3:8
	       BSR	 F55_DSW_SUB	   ;;;;;;
	       MOV.B	 #B'00001000,R5L
	       BSR	 F55_DSW_SUB1
	       BRA	 F55_RET
F55W_Y3:       BSR	 F55W_DSW_SUB
	       MOV.B	 #B'00001000,R5L
	       MOV.B	 R5L,@ER4
	       BRA	 F55_RET
;;;;;
F55B_Y4:       CMP.B	 #H'8,R5L
	       BNE	 F55B_Y5:8
	       MOV.B	 @ER3,R5H
	       AND.B	 #H'0F,R5H
	       CMP.B	 #H'0A,R5H
	       BCC	 F55_NOT_BCD
	       BLD	 #4,R1H
	       BCS	 F55W_Y4:8
	       BSR	 F55_DSW_SUB	   ;;;;;;
	       MOV.B	 #B'00000001,R5L
	       BSR	 F55_DSW_SUB1
	       BRA	 F55_RET
F55W_Y4:       BSR	 F55W_DSW_SUB
	       MOV.B	 #B'00010000,R5L
	       MOV.B	 R5L,@ER4
	       BRA	 F55_RET
;;;;;;;;
F55B_Y5:       CMP.B	 #H'10,R5L
	       BNE	 F55B_Y6:8
	       MOV.B	 @ER3,R5H
	       AND.B	 #H'0F,R5H
	       CMP.B	 #H'0A,R5H
	       BCC	 F55_NOT_BCD
F55W_Y5:       BSR	 F55W_DSW_SUB
	       MOV.B	 #B'00100000,R5L
	       MOV.B	 R5L,@ER4
	       BRA	 F55_RET
;;;;;;;
F55B_Y6:       CMP.B	 #H'20,R5L
	       BNE	 F55B_Y7:8
	       MOV.B	 @ER3,R5H
	       AND.B	 #H'0F,R5H
	       CMP.B	 #H'0A,R5H
	       BCC	 F55_NOT_BCD
F55W_Y6:       BSR	 F55W_DSW_SUB
	       MOV.B	 #B'01000000,R5L
	       MOV.B	 R5L,@ER4
	       BRA	 F55_RET
;;;;;;
F55B_Y7:       CMP.B	 #H'40,R5L
	       BNE	 F55B_Y8:8
	       MOV.B	 @ER3,R5H
	       AND.B	 #H'0F,R5H
	       CMP.B	 #H'0A,R5H
	       BCC	 F55_NOT_BCD
F55W_Y7:       BSR	 F55W_DSW_SUB
	       MOV.B	 #B'10000000,R5L
	       MOV.B	 R5L,@ER4
	       BRA	 F55_RET
;;;;;;
F55B_Y8:       CMP.B	 #H'80,R5L
	       BNE	 F55B_Y_RESET:8
	       MOV.B	 @ER3,R5H
	       AND.B	 #H'0F,R5H
	       CMP.B	 #H'0A,R5H
	       BCC	 F55_NOT_BCD
F55W_Y8:       BSR	 F55W_DSW_SUB
F55B_Y_RESET:  MOV.B	 #B'00000001,R5L
	       MOV.B	 R5L,@ER4
F55_RET:       MOV.L	 #SC041_ADDR,DPTR
	       BCLR	 #3,@DPTR
	       BLD	 #2,R1H
	       RTS
F55_NOT_BCD:   MOV.L	 #SC041_ADDR,DPTR
	       BSET	 #3,@DPTR
	       BLD	 #2,R1H
	       RTS
F55_RESET_FLAG: .EQU	 $
	       JSR	 @FLAG_RESET
	       BLD	 #2,R1H
	       RTS
;;;;;
F56_SUB:       MOV.L	 @ER7,ER5
	       SUB.W	 #6,R5
	       INC.B	 R4H
	       SHLL.B	 R4L
	       CMP.B	 R4L,R4H
	       BCS	 F56_SUB1:8
	       MOV.B	 #H'0,R4H
F56_SUB1:      MOV.B	 R4H,@ER5
F56_N_1:       CMP.B	 #2,R4L
	       BNE	 F56_N_2:8
	       MOV.W	 @ER2,R5
	       MOV.B	 @ER3,R6L
F56_N_1_OUT:   AND.B	 #H'0F,R5L
	       AND.B	 #H'E0,R6L
	       OR.B	 R5L,R6L
	       MOV.B	 R6L,@ER3
	       BRA	 F56_RET
;
F56_N_2:       CMP.B	 #4,R4L
	       BNE	 F56_N_3:8
	       MOV.W	 @ER2,R5		 ;D
F56_N_2_OUT0:  CMP.B	 #H'00,R4H
	       BNE	 F56_N_2_OUT00:8
	       AND.B	 #H'0F,R5L
	       MOV.B	 #B'00100000,R6H
	       OR.B	 R5L,R6H
	       MOV.B	 @ER3,R5L
	       AND.B	 #H'C0,R5L
	       OR.B	 R5L,R6H
	       MOV.B	 R6H,@ER3
	       BRA	 F56_RET
F56_N_2_OUT00: CMP.B	 #H'01,R4H
	       BNE	 F56_N_2_OUT1:8
	       BRA	 F56_N_2_RET
F56_N_2_OUT1:  CMP.B	 #H'02,R4H
	       BNE	 F56_N_2_RET
	       ROTR.B	 R5L
	       ROTR.B	 R5L
	       ROTR.B	 R5L
	       ROTR.B	 R5L
	       MOV.B	 #B'00010000,R6H
	       AND.B	 #H'0F,R5L
	       OR.B	 R5L,R6H
	       MOV.B	 @ER3,R5L
	       AND.B	 #H'C0,R5L
	       OR.B	 R5L,R6H
	       MOV.B	 R6H,@ER3
	       BRA	 F56_RET
F56_N_2_RET:   MOV.B	 @ER3,R5L
	       AND.B	 #H'C0,R5L
	       MOV.B	 #B'00110000,R6H
	       OR.B	 R5L,R6H
	       MOV.B	 R6H,@ER3
	       BRA	 F56_RET
;;
F56_N_3:       CMP.B	 #6,R4L
	       BNE	 F56_N_4:8
	       MOV.W	 @ER2,R5		 ;D
F56_N_3_OUT0:  CMP.B	 #H'00,R4H
	       BNE	 F56_N_3_OUT00:8
	       AND.B	 #H'0F,R5L
	       MOV.B	 #B'01100000,R6H
	       OR.B	 R5L,R6H
	       MOV.B	 @ER3,R5L
	       AND.B	 #H'80,R5L
	       OR.B	 R5L,R6H
	       MOV.B	 R6H,@ER3
	       BRA	 F56_RET
F56_N_3_OUT00: CMP.B	 #H'01,R4H
	       BNE	 F56_N_3_OUT1:8
	       BRA	 F56_N_3_RET
F56_N_3_OUT1:  CMP.B	 #H'02,R4H
	       BNE	 F56_N_3_OUT10:8
	       ROTR.B	 R5L
	       ROTR.B	 R5L
	       ROTR.B	 R5L
	       ROTR.B	 R5L
	       MOV.B	 #B'11010000,R6H
	       AND.B	 #H'0F,R5L
	       OR.B	 R5L,R6H
	       MOV.B	 @ER3,R5L
	       AND.B	 #H'80,R5L
	       OR.B	 R5L,R6H
	       MOV.B	 R6H,@ER3
	       BRA	 F56_RET
F56_N_3_OUT10: CMP.B	 #H'03,R4H
	       BNE	 F56_N_3_OUT2:8
	       BRA	 F56_N_3_RET
F56_N_3_OUT2:  CMP.B	 #H'04,R4H
	       BNE	 F56_N_3_RET:8
	       AND.B	 #H'0F,R5H
	       MOV.B	 #B'10110000,R6H
	       OR.B	 R5H,R6H
	       MOV.B	 @ER3,R5L
	       AND.B	 #H'80,R5L
	       OR.B	 R5L,R6H
	       MOV.B	 R6H,@ER3
	       BRA	 F56_RET
F56_N_3_RET:   MOV.B	 @ER3,R5L
	       AND.B	 #H'80,R5L
	       MOV.B	 #B'01110000,R6H
	       OR.B	 R5L,R6H
	       MOV.B	 R6H,@ER3
	       BRA	 F56_RET
;;
F56_N_4:       CMP.B	 #8,R4L
	       BNE	 F56_RET
	       MOV.W	 @ER2,R5		 ;D
F56_N_4_OUT0:  CMP.B	 #H'00,R4H
	       BNE	 F56_N_4_OUT00:8
	       AND.B	 #H'0F,R5L
	       MOV.B	 #B'11100000,R6H
	       OR.B	 R5L,R6H
	       MOV.B	 R6H,@ER3
	       BRA	 F56_RET
F56_N_4_OUT00: CMP.B	 #H'01,R4H
	       BNE	 F56_N_4_OUT1:8
	       BRA	 F56_N_4_RET
F56_N_4_OUT1:  CMP.B	 #H'02,R4H
	       BNE	 F56_N_4_OUT10:8
	       ROTR.B	 R5L
	       ROTR.B	 R5L
	       ROTR.B	 R5L
	       ROTR.B	 R5L
	       MOV.B	 #B'11010000,R6H
	       AND.B	 #H'0F,R5L
	       OR.B	 R5L,R6H
	       MOV.B	 R6H,@ER3
	       BRA	 F56_RET
F56_N_4_OUT10: CMP.B	 #H'03,R4H
	       BNE	 F56_N_4_OUT2:8
	       BRA	 F56_N_4_RET
F56_N_4_OUT2:  CMP.B	 #H'04,R4H
	       BNE	 F56_N_4_OUT20:8
	       AND.B	 #H'0F,R5H
	       MOV.B	 #B'10110000,R6H
	       OR.B	 R5H,R6H
	       MOV.B	 R6H,@ER3
	       BRA	 F56_RET
F56_N_4_OUT20: CMP.B	 #H'05,R4H
	       BNE	 F56_N_4_OUT3:8
	       BRA	 F56_N_4_RET
F56_N_4_OUT3:  CMP.B	 #H'06,R4H
	       BNE	 F56_N_4_RET:8
	       ROTR.B	 R5H
	       ROTR.B	 R5H
	       ROTR.B	 R5H
	       ROTR.B	 R5H
	       MOV.B	 #B'01110000,R6H
	       AND.B	 #H'0F,R5H
	       OR.B	 R5H,R6H
	       MOV.B	 R6H,@ER3
	       BRA	 F56_RET
F56_N_4_RET:   MOV.B	 #B'11110000,R6H
	       MOV.B	 R6H,@ER3
F56_RET:       BLD	 #2,R1H
	       RTS

;;;;;
F57_SUB:       PUSH.W	 R1
	       MOV.B	 @ER2,R5L
	       MOV.W	 R2,@R2_BUFFER
	       INC.L	 #1,ER2
	       MOV.B	 @ER2,R5H
	       MOV.W	 @ER3,R6       ;COMPARE DATA R6
F57_CMP_LOOP1: MOV.B	 #0,R1L
	       MOV.B	 #D'8,R1H     ;;;   R2 <= R6 <= R3 (bit on)
F57_CMP_LP1:   MOV.W	 @ER4,R2      ;;;   R2 > R3 (bit off)
	       INC.L	 #2,ER4
	       MOV.W	 @ER4,R3
	       INC.L	 #2,ER4
	       BSR	 F57_CMP1
	       INC.B	 R1L
	       DEC.B	 R1H
	       BNE	 F57_CMP_LP1:8
	       BRA	 F57_CMP_LOOP2:8
F57_CMP1:      CMP.W	 R2,R3
	       BCS	 F57_BIT_OFF1:8
	       CMP.W	 R2,R6
	       BCS	 F57_BIT_OFF1:8
	       CMP.W	 R6,R3
	       BCS	 F57_BIT_OFF1:8
	       BSET	 R1L,R5L
	       RTS
F57_BIT_OFF1:  BCLR	 R1L,R5L
	       RTS
F57_CMP2:      CMP.W	 R2,R3
	       BCS	 F57_BIT_OFF2:8
	       CMP.W	 R2,R6
	       BCS	 F57_BIT_OFF2:8
	       CMP.W	 R6,R3
	       BCS	 F57_BIT_OFF2:8
	       BSET	 R1L,R5H
	       RTS
F57_BIT_OFF2:  BCLR	 R1L,R5H
	       RTS

F57_CMP_LOOP2: MOV.B	 #0,R1L
	       MOV.B	 #D'8,R1H     ;;;   R2 <= R6 <= R3 (bit on)
F57_CMP_LP2:   MOV.W	 @ER4,R2      ;;;   R2 > R3 (bit off)
	       INC.L	 #2,ER4
	       MOV.W	 @ER4,R3
	       INC.L	 #2,ER4
	       BSR	 F57_CMP2
	       INC.B	 R1L
	       DEC.B	 R1H
	       BNE	 F57_CMP_LP2:8
	       MOV.W	 @R2_BUFFER,R2
	       MOV.B	 R5L,@ER2
	       INC.L	 #1,ER2
	       MOV.B	 R5H,@ER2
F57_RET:       POP.W	 R1
	       BLD	 #2,R1H
	       RTS
;;;;;;
F58_SUB:       BTST	 #JCS,R1L
	       BNE	 F58_RET
	       BLD	 PGBRT
	       BCS	 F58_RET_PG	  ;;VF.5
	       BLD	 F59_TXD_EN
	       BCS	 F58_RET
	       MOV.L	 @ER7,ER5
	       SUB.W	 #D'29,R5
	       MOV.B	 R1H,@ER5
	       BLD	 #3,R1H
	       BCS	 F58_SKIP_JUG:8
	       BLD	 #2,R1H
	       BCC	 F58_DISABLE
	       BLD	 PGBRT_STATUS1	   ;;VF.5
	       BCS	 F58_MONITOR:8	   ;;
	       BSET	 PGBRT_STATUS1	   ;;
	       BRA	 F58_GO:8	   ;;
F58_SKIP_JUG:  BTST	 #FUN_SKIP,R1L
	       BNE	 F58_RET
F58_GO:        BCLR	 #TE,@SCR0	   ;;;;;;V1.6 RS422 CHANGE TO RS485
	       CMP.W	 #0,R4		   ;;OFF -> ON
	       BNE	 F58_GO1:8
	       INC.W	 #1,R3
	       MOV.W	 #H'000F,E3        ;;VF.5
	       MOV.B	 @ER3,R4L
	       MOV.B	 R4L,@F58_END_CODE
	       BCLR	 F58_RXD_BYTE
	;;;    BCLR	 F58_RXD_F0	     ;;VF.5
	       BRA	 F58_GO2:8
F58_GO1:       BSET	 F58_RXD_BYTE
	       INC.W	 #1,R3
	       MOV.B	 @ER3,R6L
	       CMP.B	 #0,R6L
	       BEQ	 F58_RET
	       MOV.B	 R6L,@BYTE_COUNTER
F58_GO2:       BSET	 F58_RXD_EN
	       BCLR	 REQ_START_FG0
	       BCLR	 F58_RXD_F0	      ;;VF.5
	       BRA	 F58_RET
F58_DISABLE:   BCLR	 F58_RXD_EN
	       MOV.L	 #SC073_ADDR,ER5
	       BCLR	 #1,@ER5
	       BRA	 F58_RET
F58_MONITOR:   BLD	 F58_RXD_F0
	       BCC	 F58_RET
	       MOV.W	 R2,@R2_BUFFER	   ;;;
	       MOV.B	 @PG_STX,R2L
	       CMP.B	 #ASCII_3AH,R2L
	       BNE	 F58_MONITOR1:8
	       MOV.B	 @PG_BUF1,R2L
	       CMP.B	 #ASCII_3AH,R2L
	       BNE	 F58_MONITOR1:8
	       BCLR	 TXENDF0	   ;;IF EXECUTE F58, NO NEED TO RESPONSE
	       BRA	 F58_MONITOR2:8    ;;COMPUTER LINK FORMAT
F58_MONITOR1:;;BCLR	 RXENDF0	   ;;VF.5
F58_MONITOR2:  BCLR	 F58_RXD_F0	   ;;
	       MOV.L	 #PG_STX,ER5
	       BLD	 F58_RXD_BYTE
	       BCC	 F58_END_CD:8
	       INC.W	 #1,R3		   ;;LOW BYTE
	       MOV.B	 @ER3,R2H	   ;;BYTE NUMBER
	       BRA	 F58_MOVE:8
F58_END_CD:    MOV.B	 #0,R2H
	       MOV.B	 #D'255,R2L
	       MOV.B	 @F58_END_CODE,R4L ;;END CODE
F58_CHK_LEN:   MOV.B	 @ER5+,R4H	   ;;VF.5
	       INC.B	 R2H
	       CMP.B	 R4L,R4H
	       BEQ	 F58_MOVE:8
	       DEC.B	 R2L
	       BNE	 F58_CHK_LEN:8
	       BRA	 F58_RET
F58_MOVE:      MOV.B	 R2H,R3L	   ;;BYTE NUMBER
	       MOV.L	 #PG_STX,ER5
	       MOV.W	 @R2_BUFFER,R2
	       MOV.W	 #H'000F,E2
	       INC.W	 #1,R2
F58_MOVE_LP:   MOV.B	 @ER5+,R3H	   ;;VF.5
	       MOV.B	 R3H,@ER2
	       INC.L	 #2,ER2
	       DEC.B	 R3L
	       BNE	 F58_MOVE_LP:8
	       MOV.L	 #SC073_ADDR,ER5
	       BSET	 #1,@ER5
F58_RET:       RTS
F58_RET_PG:    BCLR	 PGBRT_STATUS1
	       RTS
;;;;;;;
F59_SUB:       BTST	 #JCS,R1L
	       BNE	 F59_RET
	       BLD	 PGBRT
	       BCS	 F59_RET
	       MOV.L	 @ER7,ER5
	       SUB.W	 #D'29,R5
	       MOV.B	 R1H,@ER5
	       BLD	 #3,R1H
	       BCS	 F59_SKIP_JUG:8
	       BLD	 #2,R1H
	       BCC	 F59_DISABLE:8	   ;;OFF -> OFF
	       BRA	 F59_RET	   ;;ON  -> ON
F59_SKIP_JUG:  BTST	 #FUN_SKIP,R1L
	       BNE	 F59_RET
	       BRA	 F59_GO:8	   ;;OFF-> ON
F59_DISABLE:   MOV.L	 #SC073_ADDR,ER5
	       BCLR	 #2,@ER5
	       BRA	 F59_RET
F59_GO:        MOV.W	 R2,@R2_BUFFER
	       CMP.W	 #0,R4
	       BEQ	 F59_END_CODE:8
	       INC.W	 #1,R3		   ;;LOW BYTE
	       MOV.B	 @ER3,R2H	   ;;BYTE NUMBER
	       CMP.B	 #0,R2H
	       BEQ	 F59_RET
	       MOV.B	 R2H,@BYTE_COUNTER
	       BRA	 F59_MOVE:8
F59_END_CODE:  MOV.B	 #0,R6H
	       MOV.B	 #D'255,R6L
	       INC.W	 #1,R3
	       MOV.B	 @ER3,R4L	   ;;END CODE
F59_CHK_LEN:   MOV.W	 @R2_BUFFER,R2
	       INC.W	 #1,R2
F59_CHK_LP:    MOV.B	 @ER2,R4H
	       INC.L	 #2,ER2
	       INC.B	 R6H
	       CMP.B	 R4L,R4H
	       BEQ	 F59_MOVE0:8
	       DEC.B	 R6L
	       BNE	 F59_CHK_LP:8
F59_MOVE0:     MOV.B	 R6H,@BYTE_COUNTER
F59_MOVE:      MOV.B	 @BYTE_COUNTER,R3L
	       MOV.L	 #PG_STX,ER5
	       MOV.W	 @R2_BUFFER,R2
	       INC.W	 #1,R2
F59_MOVE_LP:   MOV.B	 @ER2,R3H
	       MOV.B	 R3H,@ER5
	       INC.L	 #1,ER5
	       INC.L	 #2,ER2
	       DEC.B	 R3L
	       BNE	 F59_MOVE_LP:8
	       MOV.L	 #PG_STX,DPTR		 ;
	       MOV.B	 @DPTR,ACC		 ;
	       MOV.L	 DPTR,@FRAME_PTR	 ; Frame pointer
	       BSET	 F59_TXD_EN		 ;
	       BCLR	 #RE,@SCR0		 ;;NEW
	       BSET	 #TE,@SCR0		 ;;;V1.4
	       MOV.B	 ACC,@TDR0		 ;
	       BCLR	 #TDRE,@SSR0		 ;Start transmit
	       MOV.B	 @BYTE_COUNTER,R3L	 ;;V1.3
	       DEC.B	 R3L			 ;;
	       BEQ	 F59_ONE_BYTE:8 	 ;;
	       MOV.B	 R3L,@BYTE_COUNTER	 ;;
	       BSET	 #TIE,@SCR0		 ;Enable TXI interrupt
F59_RET:       RTS
F59_ONE_BYTE:  BSET	 #TEIE,@SCR0		 ;
	       RTS

;;;;;;	V1019 : MINIUTE , V1020 : HOUR
F60_SUB:       MOV.B	 @MINUTE_ADDR,R5L
	       MOV.B	 @HOUR_ADDR,R5H
	       CMP.W	 R4,R5
	       BNE	 F60_61_RET:8
F60_SET_RELAY: BSET	 R3L,@ER2
F60_61_RET:    BLD	 #2,R1H
	       RTS
;;;;;;
F61_SUB:       MOV.B	 @MINUTE_ADDR,R5L
	       MOV.B	 @HOUR_ADDR,R5H
	       CMP.W	 R4,R5
	       BNE	 F60_61_RET:8
F60_RST_RELAY: BCLR	 R3L,@ER2
	       BRA	 F60_61_RET
;;;;;;
F62_SUB:       BSET	 #7,R1H
F62_SUB1:      BLD	 #6,R1H
	       BCC	 F62_DATA
F62_REGIST:    INC.W	 #1,R4
	       MOV.B	 @ER4,R5L
	       MOV.B	 #0,R4H
	       MOV.B	 R5L,R4L
	       BRA	 F62_GO:8
F62_DATA:      CMP.W	 #D'257,R4
	       BCS	 F62_GO:8
	       MOV.W	 #D'256,R4
F62_GO:        CMP.W	 #0,R4
	       BEQ	 F62_RET
	       INC.W	 #1,R2
	       INC.W	 #1,R3
F62_LOOP:      MOV.B	 @ER3,R5L
	       BLD	 #7,R1H
	       BCC	 F62_LOOP0:8
	       BSR	 HEX_TO_ASCII
	       BRA	 F62_LOOP1:8
F62_LOOP0:     BSR	 ASCII_TO_HEX
F62_LOOP1:     MOV.B	 R5L,@ER2
	       INC.L	 #2,ER2
	       INC.L	 #2,ER3
	       CMP.L	 #LABEL_INST_ADDR,ER2
	       BCC	 F62_RET
	       CMP.L	 #WC_MEMORY_ADDR,ER2
	       BCC	 F62_CHK:8
	       CMP.L	 #WS_MEMORY_ADDR,ER2
	       BCC	 F62_RET
F62_CHK:       DEC.W	 #1,R4
	       BNE	 F62_LOOP:8
F62_RET:       BLD	 #2,R1H
	       RTS
;
;;;INPUT : R5L ,  OUTPUT : R5L
HEX_TO_ASCII:  .EQU	 $
		CMP.B	  #H'10,R5L
		BCC	  HEX_ASCII_RET:8
		MOV.B	  #0,R5H
		SHLL.W	  R5
		MOV.L	  #ASCII_TABLE,ER6
		ADD.W	  R5,R6
		MOV.W	  @ER6,R5
HEX_ASCII_RET:	RTS
;
ASCII_TABLE    .DATA.W	  H'0030
	       .DATA.W	  H'0031
	       .DATA.W	  H'0032
	       .DATA.W	  H'0033
	       .DATA.W	  H'0034
	       .DATA.W	  H'0035
	       .DATA.W	  H'0036
	       .DATA.W	  H'0037
	       .DATA.W	  H'0038
	       .DATA.W	  H'0039
	       .DATA.W	  H'0041
	       .DATA.W	  H'0042
	       .DATA.W	  H'0043
	       .DATA.W	  H'0044
	       .DATA.W	  H'0045
	       .DATA.W	  H'0046
;;;;;;;;
ASCII_TO_HEX:  MOV.B	 R5L,R5H
	       AND.B	 #H'7F,R5H
	       .SWITCH.B (R5H)
	       .CASE	 #H'30
		MOV.B	 #H'0,R5L
		BRA	 ASCII_HEX_RET
	       .CASE	 #H'31
		MOV.B	 #H'1,R5L
		BRA	 ASCII_HEX_RET
	       .CASE	 #H'32
		MOV.B	 #H'2,R5L
		BRA	 ASCII_HEX_RET
	       .CASE	 #H'33
		MOV.B	 #H'3,R5L
		BRA	 ASCII_HEX_RET
	       .CASE	 #H'34
		MOV.B	 #H'4,R5L
		BRA	 ASCII_HEX_RET
	       .CASE	 #H'35
		MOV.B	 #H'5,R5L
		BRA	 ASCII_HEX_RET
	       .CASE	 #H'36
		MOV.B	 #H'6,R5L
		BRA	 ASCII_HEX_RET
	       .CASE	 #H'37
		MOV.B	 #H'7,R5L
		BRA	 ASCII_HEX_RET
	       .CASE	 #H'38
		MOV.B	 #H'8,R5L
		BRA	 ASCII_HEX_RET
	       .CASE	 #H'39
		MOV.B	 #H'9,R5L
		BRA	 ASCII_HEX_RET
	       .CASE	 #H'41
		MOV.B	 #H'A,R5L
		BRA	 ASCII_HEX_RET
	       .CASE	 #H'42
		MOV.B	 #H'B,R5L
		BRA	 ASCII_HEX_RET
	       .CASE	 #H'43
		MOV.B	 #H'C,R5L
		BRA	 ASCII_HEX_RET
	       .CASE	 #H'44
		MOV.B	 #H'D,R5L
		BRA	 ASCII_HEX_RET
	       .CASE	 #H'45
		MOV.B	 #H'E,R5L
		BRA	 ASCII_HEX_RET
	       .CASE	 #H'46
		MOV.B	 #H'F,R5L
		BRA	 ASCII_HEX_RET
	       .OTHERS
	       .ENDS
ASCII_HEX_RET: RTS
;;;;;;
F63_SUB:       BCLR	 #7,R1H
	       BRA	 F62_SUB1
;;;;;;
;=====================================================================
;|		 (NEW  ADD)   RTD   TMJ    TMK	 TMT		      |
;|			      F64   F65    F66	 F67	V1.61  start  |
;======================================================================
;R3->input D or V    ,R4->n	,R2->output D or V
;
F64_SUB:       .EQU	 $
F64_JCS_JUG:   BTST	 #JCS,R1L
	       BNE	 F64_RET
	       MOV.L	 @ER7,ER5
	       SUB.W	 #D'29,R5
	       MOV.B	 R1H,@ER5
	       BLD	 #3,R1H
	       BCS	 F64W_GO:8
	       BLD	 #ONLS,R1H	   ;R1L->R1H
	       BOR	 FOR_NEXT
	       BAND	 #2,R1H
	       BCC	 F64_RET_RESETF    ;;V0.8 BUG MODIFY
F64W_GO:       JSR	 @CAL_S1_S2
	       MOV.W	 @R3_DATA,R3	;;V/D
	       MOV.W	 @R4_DATA,R4	;;n
	       MOV.W	 #0,E3
	       MOV.W	 #0,E4
	       MOV.W	 #H'000F,E2         ;;V0.B
;if  1 =< R3 =< 8 ,then do this function
	       CMP.W	 #H'0009,R3            ;
	       BCS	 F64_GO1
	       JSR	 @FLAG_ERROR
	       RTS
F64_GO1:       CMP.W	 #D'1,R3
	       BCC	 F64_GO2
	       JSR	 @FLAG_ERROR
	       RTS
;if 0 <= R4 <= 1 ,then do this function
F64_GO2:       CMP.W	 #H'2,R4           ;
	       BCC	 F64_RET
; ********* find the V(input) and WS(shift)  address and value **************
	       DEC.W	 #1,R3
	       MOV.W	 R3,@CHANNEL_BUFFER    ;V1.633
	       SHLL.W	 R3
	       ADD.L	 #V0961_ADDR,ER3       ;keep V_value in R3
	       MOV.W	 @ER3,R3
F_64AA:        MOV.W	 #0,E4
	       CMP.W	 #H'0FFF,R3            ;D'4095=H'0FFF
	       BNE	 F64_NOT_OVERRANGE     ;
	       JSR	 @FLAG_ERROR	       ;
F64_NOT_OVERRANGE;
	       MOV.B	 R4L,@TO_C_OR_F        ;
;******************** Find BREAK_POINT, SLOPE, SHIFT value  *****************
	       MOV.L	 #PT100_BREAK_POINT,ER4
F64_FIND_BREAK_POINT_LOOP:
	       MOV.W	 @ER4,E3
	       CMP.W	 E3,R3
	       BCS	 FIND_SLOPE0
	       INC.L	 #2,ER4
	       BRA	 F64_FIND_BREAK_POINT_LOOP
FIND_SLOPE0:   SUB.L	#PT100_BREAK_POINT,ER4
	       MOV.W	R4,E3
FIND_SLOPE:    MOV.L	#PT100_BLOCK_SLOPE,ER4
	       ADD.W	E3,R4
	       MOV.W	@ER4,R4
	       MOV.W	R4,@SENSOR_SLOPE
FIND_SHIFT:    MOV.L	#PT100_BLOCK_SHIFT,ER4
	       SHLL.W	E3
	       ADD.W	E3,R4
	       MOV.L	@ER4,ER4
	       MOV.L	ER4,@SENSOR_SHIFT
	       MOV.W	@SENSOR_SLOPE,R4     ;
;****************** start do the formula:  y=a*x-b **************************
	       MULXU.W	 R4,ER3 	    ;
	       MOV.L	 @SENSOR_SHIFT,ER4  ;
	       SUB.L	 ER4,ER3	    ;
	       BCC	 F64W_CHK_FLAG_C    ;IF +,JUMP TO F64W_C_POSITIVE

	       NOT.L	 ER3		    ;do "- C"
	       ADD.L	 #1,ER3 	    ;
	       MOV.B	 @TO_C_OR_F,R4L     ;
	       CMP.B	 #1,R4L 	    ;
	       BNE	 F64_A1
	       BRA	 F64W_NEGATIVE_C_GET_F
;;
F64_A1:        JSR	 @FLAG_CARRY	    ;
F64W_C_POSITIVE:			    ;
	       MOV.W	 #H'2710,R4         ;H'2710=D'10000
	       DIVXU.W	 R4,ER3 	    ;
	       PUSH.W	 E3	      ;; start:
	       MOV.W	 #H'A,R4      ;; change 1 degree to 0.3 degree
	       MULXU.W	 R4,ER3       ;;
	       POP.W	 E3	      ;;
	       PUSH.W	 R3	      ;;
	       MOV.W	 E3,R3	      ;;
	       MOV.W	 #H'0,E3      ;;
	       MOV.W	 #D'1000,R4   ;;
	       DIVXU.W	 R4,ER3       ;;
	       MOV.W	 R3,E3	      ;;
	       POP.W	 R3	      ;;
	       ADD.W	 E3,R3	      ;; end
	       MOV.W	 R3,@NOW_TEMP		;;V1.633
	       MOV.B	 @SC017_ADDR,R1L	;;;
	       BLD	 #4,R1L 		;;;
	       BCC	 F64_CONT_GO		;;;
	       MOV.W	 @CHANNEL_BUFFER,R4	;;V1.633
	       SHLL.W	 R4			;;
	       MOV.L	 #AD_RUN_TIMES1,ER3	;;
	       ADD.W	 R4,R3			;;
	       MOV.W	 @ER3,R4		;;
	       CMP.W	 #D'1,R4                ;;
	       BCC	 F64_CONT_GO		;;
;						   ;;
;						   ;;
;******FIRST INTO THIS FUNCTION ***************************************
	       MOV.W	 @CHANNEL_BUFFER,R4	 ;;
	       SHLL.W	 R4			 ;;
	       MOV.L	 #WS067_ADDR,ER3	 ;;
	       ADD.W	 R4,R3			 ;;
	       MOV.W	 @ER3,R4		 ;;R1=WS0XX_ADDR's value
	       CMP.W	 #0,R4			 ;;
	       BEQ	 F64_DO1		 ;;
	       MOV.W	 @NOW_TEMP,E4		 ;;
	       SUB.W	 R4,E4			 ;;
	       MOV.L	 #WS067_ADDR,ER3	 ;;
	       MOV.W	 @CHANNEL_BUFFER,R4	 ;;
	       SHLL.W	 R4			 ;;
	       ADD.W	 R4,R3			 ;;
	       MOV.W	 E4,@ER3		 ;;AD_CHx_OFFSET's value

;;OVER THAN 2ND INTO THIS FUNCTION						 ;;
F64_CONT_GO:
	       MOV.W	 @CHANNEL_BUFFER,R4	;;V1.633
	       SHLL.W	 R4			;;
	       MOV.L	 #AD_RUN_TIMES1,ER3	;;
	       ADD.W	 R4,R3			;;
	       MOV.W	 @ER3,R4		;;
	       CMP.W	 #D'1,R4                ;;
	       BCS	 F64_DO3		;;
	       INC.W	 #1,R4			;; ;;
	       MOV.W	 R4,@ER3		;; ;;
	       MOV.B	 @SC017_ADDR,R1L	;;
	       BCLR	 #4,R1L 		;;
	       MOV.B	 R1L,@SC017_ADDR

F64_DO3:       MOV.W	 @CHANNEL_BUFFER,R4	;;
	       SHLL.W	 R4			;;
	       MOV.L	 #WS067_ADDR,ER3	;;
	       ADD.W	 R4,R3			;;
	       MOV.W	 @ER3,R4		;;get AD_CHx_OFFSET's value
	       MOV.W	 @NOW_TEMP,R3		;;
	       SUB.W	 R4,R3			;;

	  ;	BCC	  F64_DO2		 ;;
	  ;	NOT.W	  R3			 ;;
	  ;	ADD.W	  #1,R3 		 ;;
	       BRA	 F64_DO2		;;

F64_DO1:       MOV.W	 @NOW_TEMP,R3
F64_DO2:       MOV.B	 @TO_C_OR_F,R4L    ;
	       CMP.B	 #1,R4L 	   ;
	       BNE	 F64W_SAVE	   ;
;change +C to +F
	       MOV.W	 #H'0009,R4        ;F=(9/5)C+320
	       MULXU.W	 R4,ER3 	   ;
	       MOV.W	 #H'0005,R4        ;
	       DIVXU.W	 R4,ER3 	   ;
	       ADD.W	 #H'140,R3          ;D'320=H'200
	       JSR	 @FLAG_NON_CARRY   ;
	       BRA	 F64W_SAVE	   ;
;
F64W_NEGATIVE_C_GET_F:
	       MOV.W	 #H'2710,R4         ;H'2710=D'10000
	       DIVXU.W	 R4,ER3 	    ;
	       PUSH.W	 E3	      ; start:
	       MOV.W	 #H'A,R4      ; change 1 degree to 0.3 degree
	       MULXU.W	 R4,ER3       ;
	       POP.W	 E3	      ;
	       PUSH.W	   R3	      ;
	       MOV.W	 E3,R3	      ;
	       MOV.W	 #H'0,E3      ;
	       MOV.W	 #D'1000,R4   ;
	       DIVXU.W	 R4,ER3       ;
	       MOV.W	 R3,E3	      ;
	       POP.W	 R3	      ;
	       ADD.W	 E3,R3	      ; end
	       MOV.W	 #H'0000,E3        ;
	       MOV.W	 #H'0009,R4        ;F=(9/5)C+320
	       MULXU.W	 R4,ER3 	   ;
	       MOV.W	 #H'0005,R4        ;
	       DIVXU.W	 R4,ER3 	   ;
	       MOV.W	 R3,R4		   ;
	       MOV.W	 #H'140,R3          ;
	       SUB.W	 R4,R3		   ;D'320=H'140
	       BCC	 F64W_CHK_FLAG_F:8 ;
	       NOT.L	 ER3		   ;
	       ADD.L	 #1,ER3 	   ;
	       JSR	 @FLAG_CARRY	   ;
	       BRA	 F64W_SAVE
;
;
F64W_CHK_FLAG_C: CMP.L	   #0,ER3	    ;
		 BNE	   F64W_NON_CARRY_C ;
		 JSR	   @FLAG_ZERO	    ;
		 BRA	   F64W_C_POSITIVE  ;
F64W_CHK_FLAG_F: CMP.L	   #0,ER3	    ;
		 BNE	   F64W_NON_CARRY_F ;
		 JSR	   @FLAG_ZERO	    ;
		 BRA	   F64W_SAVE:8	    ;
F64W_NON_CARRY_C: JSR	   @FLAG_NON_CARRY0  ;
		  BRA	    F64W_C_POSITIVE  ;
F64W_NON_CARRY_F: JSR	   @FLAG_NON_CARRY0  ;
F64W_SAVE:     CMP.W	 #WORD_RANGE,R2      ;
	       BCC	 F64W_D_R:8
	       MOV.B	 R3L,@ER2
	       INC.W	 #1,R2
	       MOV.B	 R3H,@ER2
	       MOV.W	 #H'000F,E3
	       MOV.W	 #H'000F,E4
	       RTS
F64W_D_R:      MOV.W	 R3,@ER2
	       MOV.W	 #H'000F,E3
	       MOV.W	 #H'000F,E4
F64_RET:       RTS
F64_RET_RESETF:  JSR	 @FLAG_RESET
		 RTS
PT100_BLOCK_SLOPE:  .DATA.W  1928,1982,2025,2059,2089,2122,2154,2188
		    .DATA.W  2223,2258,2296,2335,2374,2414,2458,2501
		    .DATA.W  2539,2539
PT100_BLOCK_SHIFT:  .DATA.L  2449546,2481922,2517796,2554424,2594881
		    .DATA.L  2646643,2705949,2774109,2854973,2942724
		    .DATA.L  3044208,3158261,3282402,3418465,3575296
		    .DATA.L  3735445,3884903,3884903
PT100_BREAK_POINT:  .DATA.W  596,848,1095,1338,1577,1813,2045,2273,2498,2720
		    .DATA.W  2937,3152,3362,3569,3773,3973,4096
;
;
F65_SUB:       .EQU	 $
F65_JCS_JUG:   BTST	 #JCS,R1L
	       BNE	 F65_RET
	       MOV.L	 @ER7,ER5
	       SUB.W	 #D'29,R5
	       MOV.B	 R1H,@ER5
	       BLD	 #3,R1H
	       BCS	 F65W_GO:8
	       BLD	 #ONLS,R1H	   ;R1L->R1H
	       BOR	 FOR_NEXT
	       BAND	 #2,R1H
	       BCC	 F65_RET_RESETF    ;;V0.8 BUG MODIFY
F65W_GO:       JSR	 @CAL_S1_S2
	       MOV.W	 @R3_DATA,R3
	       MOV.W	 @R4_DATA,R4
	       MOV.W	 #0,E3
	       MOV.W	 #0,E4
	       MOV.W	 #H'000F,E2         ;;V0.B
;if  1 =< R3 =< 8 ,then do this function
	       CMP.W	 #H'0009,R3         ;
	       BCS	 F65_GO1
	       JSR	 @FLAG_ERROR
	       RTS
F65_GO1:       CMP.W	 #D'1,R3
	       BCC	 F65_GO2
	       JSR	 @FLAG_ERROR
	       RTS
;**************judge 1 or 2 module in use  *********************************
F65_GO2:       DEC.W	 #1,R3		       ;;V1.633
	       MOV.W	 R3,@CHANNEL_BUFFER    ;;
	       INC.W	 #1,R3		       ;;
	       CMP.W	 #5,R3		  ;
	       BCC	 N2_MODULE	  ;
;************* get 1st module's on_board_sensor's thermal value ************
;************* and transfer to degree C  ***********************************
	       PUSH.L	 ER3
	       PUSH.W	 R4
	       MOV.W	 @V0969_ADDR,R3
	       MOV.W	 #D'1221,R4
	       MULXU.W	 R4,ER3
	       SUB.L	 #D'2730000,ER3
	       MOV.L	 ER3,@ON_BOARD_SENSOR_THM
	       POP.W	 R4
	       POP.L	 ER3
	       BRA	 F65_FIND_V_WS
;*************** get 2nd module's on_board_sensor's thermal value **********
;*************** and transfer to degree C **********************************
N2_MODULE:     PUSH.L	 ER3
	       PUSH.W	 R4
	       MOV.W	 @V0970_ADDR,R3
	       MOV.W	 #D'1221,R4
	       MULXU.W	 R4,ER3
	       SUB.L	 #D'2730000,ER3
	       MOV.L	 ER3,@ON_BOARD_SENSOR_THM
	       POP.W	 R4
	       POP.L	 ER3
;****** find the V(input) and WS(shift)  address and get it's value ********
F65_FIND_V_WS:	 DEC.W	   #1,R3
	       SHLL.W	 R3
	       MOV.W	 R3,E4
	       ADD.L	 #V0961_ADDR,ER3
	       MOV.W	 @ER3,R3	  ;R3 save the V_value
	 ;	PUSH.W	  R3
	 ;	MOV.W	  E4,R3
	 ;	ADD.L	  #WS067_ADDR,ER3
	 ;	MOV.W	  @ER3,R3
	 ;	MOV.W	  R3,E4 	   ;E4 save the WS_value
	 ;	POP.W	  R3
	 ;	CMP.W	  #D'450,E4
	 ;	BCS	  F65AA
	 ;	CMP.W	  #D'530,E4
	 ;	BCC	  F65AA
	 ;	ADD.W	  #D'492,R3
	 ;	SUB.W	  E4,R3
	 ;	BCC	  F65AA
	 ;	MOV.W	  #0,R3
	 ;	BRA	  F65W_SAVE
F65AA:	       MOV.W	 #0,E4
	       CMP.W	 #H'0FFF,R3         ;D'4095=H'0FFF
	       BNE	 F65_NOT_OVERRANGE  ;
	       JSR	 @FLAG_ERROR	    ;
F65_NOT_OVERRANGE: MOV.B   R4L,@TO_C_OR_F
;************ Find  J_BREAK_POINT, SLOPE, SHIFT ****************************
	       MOV.L	 #J_BREAK_POINT,ER4
F65_FIND_BREAK_POINT_LOOP:
	       MOV.W	 @ER4,E3
	       CMP.W	 E3,R3
	       BCS	 F65_FIND_SLOPE0
	       INC.L	 #2,ER4
	       BRA	 F65_FIND_BREAK_POINT_LOOP
F65_FIND_SLOPE0:   SUB.L    #J_BREAK_POINT,ER4
	       MOV.W	R4,E3
FIND_SLOPE_J:
	       MOV.L	#J_BLOCK_SLOPE,ER4
	       ADD.W	E3,R4
	       MOV.W	@ER4,R4
	       MOV.W	R4,@SENSOR_SLOPE     ;R4=2275
FIND_SHIFT_J:	 MOV.L	  #J_BLOCK_SHIFT,ER4
	       SHLL.W	E3		    ;
	       ADD.W	E3,R4
	       MOV.L	@ER4,ER4
	       MOV.L	ER4,@SENSOR_SHIFT
	       MOV.W	@SENSOR_SLOPE,R4    ;
;*************** start do the formula:	y=a*x-b ****************************
	       MOV.W	 #0,E3
	       MULXU.W	 R4,ER3 	    ;
	       MOV.L	 @ON_BOARD_SENSOR_THM,ER4   ;OK
	       ADD.L	 ER4,ER3	    ;OK
	       MOV.L	 @SENSOR_SHIFT,ER4  ;
	       SUB.L	 ER4,ER3	    ;
	       BCC	 F65W_CHK_FLAG_C    ;IF +,JUMP TO F65W_C_POSITIVE
	       NOT.L	 ER3		    ;do negative part
	       ADD.L	 #1,ER3 	    ;
	       MOV.B	 @TO_C_OR_F,R4L     ;
	       CMP.B	 #1,R4L 	    ;
	       BNE	 F65_A1
	       BRA	 F65W_NEGATIVE_C_GET_F
F65_A1:        JSR	 @FLAG_CARRY	    ;
F65W_C_POSITIVE:
	       MOV.W	 #H'2710,R4         ;H'2710=D'10000
	       DIVXU.W	 R4,ER3 	    ;
	       PUSH.W	 E3	      ; start:
	       MOV.W	 #H'A,R4      ; change 1 degree to 0.3 degree
	       MULXU.W	 R4,ER3       ;
	       POP.W	 E3	      ;
	       PUSH.W	 R3	      ;
	       MOV.W	 E3,R3	      ;
	       MOV.W	 #H'0,E3      ;
	       MOV.W	 #D'1000,R4   ;
	       DIVXU.W	 R4,ER3       ;
	       MOV.W	 R3,E3	      ;
	       POP.W	 R3	      ;
	       ADD.W	 E3,R3	      ; end
	       MOV.W	 R3,@NOW_TEMP		;;V1.633
	       MOV.B	 @SC017_ADDR,R1L	;;;
	       BLD	 #4,R1L 		;;;
	       BCC	 F65_CONT_GO		;;;
	       MOV.W	 @CHANNEL_BUFFER,R4	;;V1.633
	       SHLL.W	 R4			;;
	       MOV.L	 #AD_RUN_TIMES1,ER3	;;
	       ADD.W	 R4,R3			;;
	       MOV.W	 @ER3,R4		;;
	       CMP.W	 #D'1,R4                ;;
	       BCC	 F65_CONT_GO		;;
	 ;	INC.W	  #1,R4 		 ;;
	 ;	MOV.W	  R4,@ER3		 ;;
;
;******FIRST INTO THIS FUNCTION ***************************************
	       MOV.W	 @CHANNEL_BUFFER,R4	;;
	       SHLL.W	 R4			 ;;
	       MOV.L	 #WS067_ADDR,ER3	 ;;
	       ADD.W	 R4,R3			 ;;
	       MOV.W	 @ER3,R4		 ;;R1=WS0XX_ADDR's value
	       CMP.W	 #0,R4			 ;;
	       BEQ	 F65_DO1		 ;;
	       MOV.W	 @NOW_TEMP,E4
	       SUB.W	 R4,E4			 ;;
	       MOV.L	 #WS067_ADDR,ER3	 ;;
	       MOV.W	 @CHANNEL_BUFFER,R4	 ;;
	       SHLL.W	 R4			 ;;
	       ADD.W	 R4,R3
	       MOV.W	 E4,@ER3		 ;;AD_CHx_OFFSET's value

;;OVER THAN 2ND INTO THIS FUNCTION						 ;;
F65_CONT_GO:
	       MOV.W	 @CHANNEL_BUFFER,R4	;;V1.633
	       SHLL.W	 R4			;;
	       MOV.L	 #AD_RUN_TIMES1,ER3	;;
	       ADD.W	 R4,R3			;;
	       MOV.W	 @ER3,R4		;;
	       CMP.W	 #D'1,R4                ;;
	       BCS	 F65_DO3		;;
	       INC.W	 #1,R4			;; ;;
	       MOV.W	 R4,@ER3		;; ;;
	       MOV.B	 @SC017_ADDR,R1L	;;
	       BCLR	 #4,R1L 		;;
	       MOV.B	 R1L,@SC017_ADDR

F65_DO3:       MOV.W	 @CHANNEL_BUFFER,R4	;;
	       SHLL.W	 R4			;;
	       MOV.L	 #WS067_ADDR,ER3      ;;
	       ADD.W	 R4,R3			 ;;
	       MOV.W	 @ER3,R4		 ;;get AD_CHx_OFFSET's value
	       MOV.W	 @NOW_TEMP,R3
	       SUB.W	 R4,R3			 ;;

      ; 	BCC	  F65_DO2    ;
      ; 	NOT.W	  R3		    ;
      ; 	ADD.W	  #1,R3 	    ;
	       BRA	 F65_DO2		;;

F65_DO1:       MOV.W	 @NOW_TEMP,R3
F65_DO2:       MOV.B	 @TO_C_OR_F,R4L    ;
	       CMP.B	 #1,R4L 	   ;
	       BNE	 F65W_SAVE	   ;
;change +C to +F
	       MOV.W	 #H'0009,R4        ;F=(9/5)C+32.0
	       MULXU.W	 R4,ER3 	   ;
	       MOV.W	 #H'0005,R4        ;
	       DIVXU.W	 R4,ER3 	   ;
	       ADD.W	 #H'140,R3          ;D'320=H'140
	       JSR	 @FLAG_NON_CARRY0   ;
	       BRA	 F65W_SAVE	   ;
F65W_NEGATIVE_C_GET_F:
	       MOV.W	 #H'2710,R4         ;H'2710=D'10000
	       DIVXU.W	 R4,ER3 	    ;
	       PUSH.W	 E3	      ; start:
	       MOV.W	 #H'A,R4      ; change 1 degree to 0.3 degree
	       MULXU.W	 R4,ER3       ;
	       POP.W	 E3	      ;
	       PUSH.W	 R3	      ;
	       MOV.W	 E3,R3	      ;
	       MOV.W	 #H'0,E3      ;
	       MOV.W	 #D'1000,R4   ;
	       DIVXU.W	 R4,ER3       ;
	       MOV.W	 R3,E3	      ;
	       POP.W	 R3	      ;
	       ADD.W	 E3,R3	      ; end
	       MOV.W	 #H'0000,E3        ;
	       MOV.W	 #H'0009,R4        ;F=(9/5)C+320
	       MULXU.W	 R4,ER3 	   ;
	       MOV.W	 #H'0005,R4        ;
	       DIVXU.W	 R4,ER3 	   ;
	       MOV.W	 R3,R4
	       MOV.W	 #H'140,R3
	       SUB.W	 R4,R3		   ;D'320=H'140
	       BCC	 F65W_CHK_FLAG_F:8 ;
	       NOT.L	 ER3		   ;
	       ADD.L	 #1,ER3 	   ;
	       JSR	 @FLAG_CARRY	   ;
	       BRA	 F65W_SAVE
F65W_CHK_FLAG_C: CMP.L	   #0,ER3	    ;
		 BNE	   F65W_NON_CARRY_C ;
		 JSR	   @FLAG_ZERO	    ;
		 BRA	   F65W_C_POSITIVE  ;
F65W_CHK_FLAG_F: CMP.L	   #0,ER3	    ;
		 BNE	   F65W_NON_CARRY_F ;
		 JSR	   @FLAG_ZERO	    ;
		 BRA	   F65W_SAVE:8	;
F65W_NON_CARRY_C: JSR	   @FLAG_NON_CARRY0  ;
		  BRA	    F65W_C_POSITIVE ;
F65W_NON_CARRY_F: JSR	   @FLAG_NON_CARRY0  ;
F65W_SAVE:     CMP.W	 #WORD_RANGE,R2   ;
	       BCC	 F65W_D_R:8
	       MOV.B	 R3L,@ER2
	       INC.W	 #1,R2
	       MOV.B	 R3H,@ER2
	       MOV.W	 #H'000F,E3
	       MOV.W	 #H'000F,E4
	       RTS
F65W_D_R:      MOV.W	 R3,@ER2
	       MOV.W	 #H'000F,E3
	       MOV.W	 #H'000F,E4
F65_RET:       RTS
F65_RET_RESETF:  JSR	 @FLAG_RESET
		 RTS
J_BLOCK_SLOPE:	.DATA.W  2771,2510,2361,2275,2227,2205,2199,2203,2210,2214
		.DATA.W  2211,2194,2163,2116,2056,1994,1939,1899,1899
J_BLOCK_SHIFT:	.DATA.L  1305381,1230594,1158233,1098296,1054765,1029355
		.DATA.L  1021511,1027970,1041215,1048951,1042029,999425
		.DATA.L  914072,774258,584446,370165,164588,9871,9871
J_BREAK_POINT:	.DATA.W  292,491,703,923,1147,1374,1602,1829,2055,2281,2507
		.DATA.W  2735,2966,3203,3446,3696,3954,4096
;
;
F66_SUB:       .EQU	 $
F66_JCS_JUG:   BTST	 #JCS,R1L
	       BNE	 F66_RET
	       MOV.L	 @ER7,ER5
	       SUB.W	 #D'29,R5
	       MOV.B	 R1H,@ER5
	       BLD	 #3,R1H
	       BCS	 F66W_GO:8
	       BLD	 #ONLS,R1H	   ;R1L->R1H
	       BOR	 FOR_NEXT
	       BAND	 #2,R1H
	       BCC	 F66_RET_RESETF    ;;V0.8 BUG MODIFY
F66W_GO:       JSR	 @CAL_S1_S2
	       MOV.W	 @R3_DATA,R3
	       MOV.W	 @R4_DATA,R4
	       MOV.W	 #0,E3
	       MOV.W	 #0,E4
	       MOV.W	 #H'000F,E2         ;;V0.B
;if  1 =< R3 =< 8 ,then do this function
	       CMP.W	 #H'0009,R3            ;
	       BCS	 F66_GO1
	       JSR	 @FLAG_ERROR
	       RTS
F66_GO1:       CMP.W	 #D'1,R3
	       BCC	 F66_GO2
	       JSR	 @FLAG_ERROR
	       RTS
;************** judge 1 or 2 module in use **********************************
F66_GO2:       DEC.W	 #1,R3		       ;;V1.633
	       MOV.W	 R3,@CHANNEL_BUFFER    ;;
	       INC.W	 #1,R3		       ;;
	       CMP.W	 #5,R3		       ;
	       BCC	 F66_N2_MODULE	       ;
;********** get 1st module's on_board_sensor's thermal value ***************
;********** and transfer to degree C  **************************************
	       PUSH.L	 ER3
	       PUSH.W	 R4
	       MOV.W	 @V0969_ADDR,R3
	       MOV.W	 #D'1221,R4
	       MULXU.W	 R4,ER3
	       SUB.L	 #D'2730000,ER3
	       MOV.L	 ER3,@ON_BOARD_SENSOR_THM
	       POP.W	 R4
	       POP.L	 ER3
	       BRA	 F66_FIND_V_WS
;************ get 2nd module's on_board_sensor's thermal value *************
;************ and transfer to degree C *************************************
F66_N2_MODULE:	   PUSH.L    ER3
	       PUSH.W	 R4
	       MOV.W	 @V0970_ADDR,R3
	       MOV.W	 #D'1221,R4
	       MULXU.W	 R4,ER3
	       SUB.L	 #H'2730000,ER3
	       MOV.L	 ER3,@ON_BOARD_SENSOR_THM
	       POP.W	 R4
	       POP.L	 ER3
;******* find the V(input) and WS(shift)  address and get it's value *******
F66_FIND_V_WS:	 DEC.W	   #1,R3
	       SHLL.W	 R3
	       MOV.W	 R3,E4
	       ADD.L	 #V0961_ADDR,ER3
	       MOV.W	 @ER3,R3	   ;R3 save the V_value
	 ;	PUSH.W	  R3
	 ;	MOV.W	  E4,R3
	 ;	ADD.L	  #WS067_ADDR,ER3
	 ;	MOV.W	  @ER3,R3
	 ;	MOV.W	  R3,E4 	   ;E4 save the WS_value
	 ;	POP.W	  R3
	 ;	CMP.W	  #D'450,E4
	 ;	BCS	  F66AA
	 ;	CMP.W	  #D'530,E4
	 ;	BCC	  F66AA
	 ;	ADD.W	  #D'492,R3
	 ;	SUB.W	  E4,R3
	 ;	BCC	  F66AA
	 ;	MOV.W	  #0,R3
	 ;	BRA	  F66W_SAVE
F66AA:	       MOV.W	 #0,E4
	       CMP.W	 #H'0FFF,R3         ;D'4095=H'0FFF
	       BNE	 F66_NOT_OVERRANGE  ;
	       JSR	 @FLAG_ERROR	    ;
F66_NOT_OVERRANGE: MOV.B   R4L,@TO_C_OR_F
	       MOV.L	 #K_BREAK_POINT,ER4
F66_FIND_BREAK_POINT_LOOP:
	       MOV.W	 @ER4,E3
	       CMP.W	 E3,R3
	       BCS	 F66_FIND_SLOPE0
	       INC.L	 #2,ER4
	       BRA	 F66_FIND_BREAK_POINT_LOOP
F66_FIND_SLOPE0:   SUB.L    #K_BREAK_POINT,ER4
	       MOV.W	R4,E3
FIND_SLOPE_K:
	       MOV.L	#K_BLOCK_SLOPE,ER4
	       ADD.W	E3,R4
	       MOV.W	@ER4,R4
	       MOV.W	R4,@SENSOR_SLOPE     ;R4=2275
FIND_SHIFT_K:	 MOV.L	  #K_BLOCK_SHIFT,ER4
	       SHLL.W	E3		    ;
	       ADD.W	E3,R4
	       MOV.L	@ER4,ER4
	       MOV.L	ER4,@SENSOR_SHIFT
	       MOV.W	@SENSOR_SLOPE,R4    ;
;**************** start do the formula:  y=a*x-b ***************************
	       MOV.W	 #0,E3
	       MULXU.W	 R4,ER3 	    ;
	       MOV.L	 @ON_BOARD_SENSOR_THM,ER4
	       ADD.L	 ER4,ER3	    ;
	       MOV.L	 @SENSOR_SHIFT,ER4  ;
	       SUB.L	 ER4,ER3	    ;
	       BCC	 F66W_CHK_FLAG_C    ;
	       NOT.L	 ER3		    ;do negative part
	       ADD.L	 #1,ER3 	    ;
	       MOV.B	 @TO_C_OR_F,R4L     ;
	       CMP.B	 #1,R4L 	    ;
	       BNE	 F66_A1
	       BRA	 F66W_NEGATIVE_C_GET_F
F66_A1:        JSR	 @FLAG_CARRY	    ;
F66W_C_POSITIVE:
	       MOV.W	 #H'2710,R4         ;H'2710=D'10000
	       DIVXU.W	 R4,ER3 	    ;
	       PUSH.W	 E3	      ; start:
	       MOV.W	 #H'A,R4      ; change 1 degree to 0.3 degree
	       MULXU.W	 R4,ER3       ;
	       POP.W	 E3	      ;
	       PUSH.W	 R3	      ;
	       MOV.W	 E3,R3	      ;
	       MOV.W	 #H'0,E3      ;
	       MOV.W	 #D'1000,R4   ;
	       DIVXU.W	 R4,ER3       ;
	       MOV.W	 R3,E3	      ;
	       POP.W	 R3	      ;
	       ADD.W	 E3,R3	      ; end
	       MOV.W	 R3,@NOW_TEMP	 ;V1.633

	       MOV.B	 @SC017_ADDR,R1L	;;;
	       BLD	 #4,R1L 		;;;
	       BCC	 F66_CONT_GO		;;;
	       MOV.W	 @CHANNEL_BUFFER,R4	;;V1.633
	       SHLL.W	 R4			;;
	       MOV.L	 #AD_RUN_TIMES1,ER3	;;
	       ADD.W	 R4,R3			;;
	       MOV.W	 @ER3,R4		;;
	       CMP.W	 #D'1,R4                ;;
	       BCC	 F66_CONT_GO		;;
	   ;	INC.W	  #1,R4 		 ;;
	   ;	MOV.W	  R4,@ER3		 ;;
;
;******FIRST INTO THIS FUNCTION ***************************************
	       MOV.W	 @CHANNEL_BUFFER,R4	 ;;
	       SHLL.W	 R4			 ;;
	       MOV.L	 #WS067_ADDR,ER3	 ;;
	       ADD.W	 R4,R3			 ;;
	       MOV.W	 @ER3,R4		 ;;R1=WS0XX_ADDR's value
	       CMP.W	 #0,R4			 ;;
	       BEQ	 F66_DO1		 ;;
	       MOV.W	 @NOW_TEMP,E4		 ;;
	       SUB.W	 R4,E4			 ;;
	       MOV.L	 #WS067_ADDR,ER3	 ;;
	       MOV.W	 @CHANNEL_BUFFER,R4	 ;;
	       SHLL.W	 R4			 ;;
	       ADD.W	 R4,R3			 ;;
	       MOV.W	 E4,@ER3		 ;;AD_CHx_OFFSET's value

;;OVER THAN 2ND INTO THIS FUNCTION						 ;;
F66_CONT_GO:
	       MOV.W	 @CHANNEL_BUFFER,R4	;;V1.633
	       SHLL.W	 R4			;;
	       MOV.L	 #AD_RUN_TIMES1,ER3	;;
	       ADD.W	 R4,R3			;;
	       MOV.W	 @ER3,R4		;;
	       CMP.W	 #D'1,R4                ;;
	       BCS	 F66_DO3		;;
	       INC.W	 #1,R4			;; ;;
	       MOV.W	 R4,@ER3		;; ;;
	       MOV.B	 @SC017_ADDR,R1L	;;
	       BCLR	 #4,R1L 		;;
	       MOV.B	 R1L,@SC017_ADDR	;;

F66_DO3:       MOV.W	 @CHANNEL_BUFFER,R4	;;
	       SHLL.W	 R4			;;
	       MOV.L	 #WS067_ADDR,ER3	;;
	       ADD.W	 R4,R3			;;
	       MOV.W	 @ER3,R4		;;get AD_CHx_OFFSET's value
	       MOV.W	 @NOW_TEMP,R3		;;
	       SUB.W	 R4,R3			;;

	  ;	BCC	  F66_DO2		 ;;
	  ;	NOT.W	  R3			 ;;
	  ;	ADD.W	  #1,R3 		 ;;
	       BRA	 F66_DO2

F66_DO1:       MOV.W	 @NOW_TEMP,R3
F66_DO2:       MOV.B	 @TO_C_OR_F,R4L    ;
	       CMP.B	 #1,R4L 	   ;
	       BNE	 F66W_SAVE	   ;
;change +C to +F
	       MOV.W	 #H'0009,R4        ;F=(9/5)C+32.0
	       MULXU.W	 R4,ER3 	   ;
	       MOV.W	 #H'0005,R4        ;
	       DIVXU.W	 R4,ER3 	   ;
	       ADD.W	 #H'140,R3          ;D'320=H'140
	       JSR	 @FLAG_NON_CARRY0   ;
	       BRA	 F66W_SAVE	   ;
F66W_NEGATIVE_C_GET_F:
	       MOV.W	 #H'2710,R4         ;H'2710=D'10000
	       DIVXU.W	 R4,ER3 	    ;
	       PUSH.W	 E3	      ; start:
	       MOV.W	 #H'A,R4      ; change 1 degree to 0.3 degree
	       MULXU.W	 R4,ER3       ;
	       POP.W	 E3	      ;
	       PUSH.W	 R3	      ;
	       MOV.W	 E3,R3	      ;
	       MOV.W	 #H'0,E3      ;
	       MOV.W	 #D'1000,R4   ;
	       DIVXU.W	 R4,ER3       ;
	       MOV.W	 R3,E3	      ;
	       POP.W	 R3	      ;
	       ADD.W	 E3,R3	      ; end
	       MOV.W	 #H'0000,E3        ;
	       MOV.W	 #H'0009,R4        ;F=(9/5)C+32.0
	       MULXU.W	 R4,ER3 	   ;
	       MOV.W	 #H'0005,R4        ;
	       DIVXU.W	 R4,ER3 	   ;
	       MOV.W	 R3,R4
	       MOV.W	 #H'140,R3
	       SUB.W	 R4,R3		   ;D'320=H'140
	       BCC	 F66W_CHK_FLAG_F:8 ;
	       NOT.L	 ER3		   ;
	       ADD.L	 #1,ER3 	   ;
	       JSR	 @FLAG_CARRY	   ;
	       BRA	 F66W_SAVE
F66W_CHK_FLAG_C: CMP.L	   #0,ER3	    ;
		 BNE	   F66W_NON_CARRY_C ;
		 JSR	   @FLAG_ZERO	    ;
		 BRA	   F66W_C_POSITIVE  ;
F66W_CHK_FLAG_F: CMP.L	   #0,ER3	    ;
		 BNE	   F66W_NON_CARRY_F ;
		 JSR	   @FLAG_ZERO	    ;
		 BRA	   F66W_SAVE:8	;
F66W_NON_CARRY_C: JSR	   @FLAG_NON_CARRY0  ;
		  BRA	    F66W_C_POSITIVE ;
F66W_NON_CARRY_F: JSR	   @FLAG_NON_CARRY0  ;
F66W_SAVE:     CMP.W	 #WORD_RANGE,R2   ;
	       BCC	 F66W_D_R:8
	       MOV.B	 R3L,@ER2
	       INC.W	 #1,R2
	       MOV.B	 R3H,@ER2
	       MOV.W	 #H'000F,E3
	       MOV.W	 #H'000F,E4
	       RTS
F66W_D_R:      MOV.W	 R3,@ER2
	       MOV.W	 #H'000F,E3
	       MOV.W	 #H'000F,E4
F66_RET:       RTS
F66_RET_RESETF:  JSR	 @FLAG_RESET
		 RTS
K_BLOCK_SLOPE:	.DATA.W  4483,3663,3230,3012,2943,2989,3053,3030,2970,2929
		.DATA.W  2902,2881,2869,2863,2868,2880,2901,2929,2961,2996
		.DATA.W  3033,3071,3111,3154,3200,3200,3200
K_BLOCK_SHIFT:	.DATA.L  1889213,1727544,1583435,1477580,1433891,1472671
		.DATA.L  1535775,1508055,1428078,1367708,1322896,1284791
		.DATA.L  1259438,1248101,1259220,1289832,1348086,1428277
		.DATA.L  1525207,1636551,1763922,1897791,2047203,2214115
		.DATA.L  2397737,2397737,2397737
K_BREAK_POINT:	.DATA.W  200,337,491,657,827,994,1158,1323,1491,1662,1834
		.DATA.W  2008,2182,2357,2531,2705,2877,3048,3217,3384,3548
		.DATA.W  3711,3872,4030,4095
;
;
;
;
F67_SUB:       .EQU	 $
F67_JCS_JUG:   BTST	 #JCS,R1L
	       BNE	 F67_RET
	       MOV.L	 @ER7,ER5
	       SUB.W	 #D'29,R5
	       MOV.B	 R1H,@ER5
	       BLD	 #3,R1H
	       BCS	 F67W_GO:8
	       BLD	 #ONLS,R1H	   ;R1L->R1H
	       BOR	 FOR_NEXT
	       BAND	 #2,R1H
	       BCC	 F67_RET_RESETF    ;;V0.8 BUG MODIFY
F67W_GO:       JSR	 @CAL_S1_S2
	       MOV.W	 @R3_DATA,R3
	       MOV.W	 @R4_DATA,R4
	       MOV.W	 #0,E3
	       MOV.W	 #0,E4
	       MOV.W	 #H'000F,E2         ;;V0.B
;if  1 =< R3 =< 8 ,then do this function
	       CMP.W	 #H'0009,R3            ;
	       BCS	 F67_GO1
	       JSR	 @FLAG_ERROR
	       RTS
F67_GO1:       CMP.W	 #D'1,R3
	       BCC	 F67_GO2
	       JSR	 @FLAG_ERROR
	       RTS
;************** judge 1 or 2 module in use **********************************
F67_GO2:       DEC.W	 #1,R3		       ;;V1.633
	       MOV.W	 R3,@CHANNEL_BUFFER    ;;
	       INC.W	 #1,R3		       ;;
	       CMP.W	 #5,R3		  ;
	       BCC	 F67_N2_MODULE	      ;
;********** get 1st module's on_board_sensor's thermal value ***************
;********** and transfer to degree C  **************************************
	       PUSH.L	 ER3
	       PUSH.W	 R4
	       MOV.W	 @V0969_ADDR,R3
	       MOV.W	 #D'1221,R4
	       MULXU.W	 R4,ER3
	       SUB.L	 #D'2730000,ER3
	       MOV.L	 ER3,@ON_BOARD_SENSOR_THM
	       POP.W	 R4
	       POP.L	 ER3
	       BRA	 F67_FIND_V_WS
;************ get 2nd module's on_board_sensor's thermal value *************
;************ and transfer to degree C *************************************
F67_N2_MODULE:	   PUSH.L    ER3
	       PUSH.W	 R4
	       MOV.W	 @V0970_ADDR,R3
	       MOV.W	 #D'1221,R4
	       MULXU.W	 R4,ER3
	       SUB.L	 #H'2730000,ER3
	       MOV.L	 ER3,@ON_BOARD_SENSOR_THM
	       POP.W	 R4
	       POP.L	 ER3
;******* find the V(input) and WS(shift)  address and get it's value *******
F67_FIND_V_WS:	 DEC.W	   #1,R3
	       SHLL.W	 R3
	       MOV.W	 R3,E4
	       ADD.L	 #V0961_ADDR,ER3
	       MOV.W	 @ER3,R3	   ;R3 save the V_value
	    ;	PUSH.W	  R3
	    ;	MOV.W	  E4,R3
	    ;	ADD.L	  #WS067_ADDR,ER3
	    ;	MOV.W	  @ER3,R3
	    ;	MOV.W	  R3,E4 	   ;E4 save the WS_value
	    ;	POP.W	  R3
	    ;	CMP.W	  #D'450,E4
	    ;	BCS	  F67AA
	    ;	CMP.W	  #D'530,E4
	    ;	BCC	  F67AA
	    ;	ADD.W	  #D'492,R3
	    ;	SUB.W	  E4,R3
	    ;	BCC	  F67AA
	    ;	MOV.W	  #0,R3
	    ;	BRA	  F67W_SAVE
F67AA:	       MOV.W	 #0,E4
	       CMP.W	 #H'0FFF,R3         ;D'4095=H'0FFF
	       BNE	 F67_NOT_OVERRANGE  ;
	       JSR	 @FLAG_ERROR	    ;
F67_NOT_OVERRANGE: MOV.B   R4L,@TO_C_OR_F
	       MOV.L	 #T_BREAK_POINT,ER4
F67_FIND_BREAK_POINT_LOOP:
	       MOV.W	 @ER4,E3
	       CMP.W	 E3,R3
	       BCS	 F67_FIND_SLOPE0
	       INC.L	 #2,ER4
	       BRA	 F67_FIND_BREAK_POINT_LOOP
F67_FIND_SLOPE0:   SUB.L    #T_BREAK_POINT,ER4
	       MOV.W	R4,E3
FIND_SLOPE_T:
	       MOV.L	#T_BLOCK_SLOPE,ER4
	       ADD.W	E3,R4
	       MOV.W	@ER4,R4
	       MOV.W	R4,@SENSOR_SLOPE     ;R4=2275
FIND_SHIFT_T:	 MOV.L	  #T_BLOCK_SHIFT,ER4
	       SHLL.W	E3		    ;
	       ADD.W	E3,R4
	       MOV.L	@ER4,ER4
	       MOV.L	ER4,@SENSOR_SHIFT
	       MOV.W	@SENSOR_SLOPE,R4    ;
;**************** start do the formula:  y=a*x-b ***************************
	       MOV.W	 #0,E3
	       MULXU.W	 R4,ER3 	    ;
	       MOV.L	 @ON_BOARD_SENSOR_THM,ER4
	       ADD.L	 ER4,ER3	    ;
	       MOV.L	 @SENSOR_SHIFT,ER4  ;
	       SUB.L	 ER4,ER3	    ;
	       BCC	 F67W_CHK_FLAG_C    ;
	       NOT.L	 ER3		    ;do negative part
	       ADD.L	 #1,ER3 	    ;
	       MOV.B	 @TO_C_OR_F,R4L     ;
	       CMP.B	 #1,R4L 	    ;
	       BNE	 F67_A1
	       BRA	 F67W_NEGATIVE_C_GET_F
F67_A1:        JSR	 @FLAG_CARRY	    ;
F67W_C_POSITIVE:
	       MOV.W	 #H'2710,R4         ;H'2710=D'10000
	       DIVXU.W	 R4,ER3 	    ;
	       PUSH.W	 E3	      ; start:
	       MOV.W	 #H'A,R4      ; change 1 degree to 0.3 degree
	       MULXU.W	 R4,ER3       ;
	       POP.W	 E3	      ;
	       PUSH.W	 R3	      ;
	       MOV.W	 E3,R3	      ;
	       MOV.W	 #H'0,E3      ;
	       MOV.W	 #D'1000,R4   ;
	       DIVXU.W	 R4,ER3       ;
	       MOV.W	 R3,E3	      ;
	       POP.W	 R3	      ;
	       ADD.W	 E3,R3	      ; end
	       MOV.W	 R3,@NOW_TEMP	 ;V1.633

	       MOV.B	 @SC017_ADDR,R1L	;;;
	       BLD	 #4,R1L 		;;;
	       BCC	 F67_CONT_GO		;;;
	       MOV.W	 @CHANNEL_BUFFER,R4	;;V1.633
	       SHLL.W	 R4			;;
	       MOV.L	 #AD_RUN_TIMES1,ER3	;;
	       ADD.W	 R4,R3			;;
	       MOV.W	 @ER3,R4		;;
	       CMP.W	 #D'1,R4                ;;
	       BCC	 F67_CONT_GO		;;
	;	INC.W	  #1,R4 		 ;;
	;	MOV.W	  R4,@ER3		 ;;
;
;******FIRST INTO THIS FUNCTION ***************************************
	       MOV.W	 @CHANNEL_BUFFER,R4	;;
	       SHLL.W	 R4			 ;;
	       MOV.L	 #WS067_ADDR,ER3	 ;;
	       ADD.W	 R4,R3			 ;;
	       MOV.W	 @ER3,R4		 ;;R1=WS0XX_ADDR's value
	       CMP.W	 #0,R4			 ;;
	       BEQ	 F67_DO1		 ;;
	       MOV.W	 @NOW_TEMP,E4
	       SUB.W	 R4,E4			 ;;
	       MOV.L	 #WS067_ADDR,ER3	 ;;
	       MOV.W	 @CHANNEL_BUFFER,R4	;;
	       SHLL.W	 R4			 ;
	       ADD.W	 R4,R3
	       MOV.W	 E4,@ER3		 ;;AD_CHx_OFFSET's value

;;OVER THAN 2ND INTO THIS FUNCTION						 ;;
F67_CONT_GO:
	       MOV.W	 @CHANNEL_BUFFER,R4	;;V1.633
	       SHLL.W	 R4			;;
	       MOV.L	 #AD_RUN_TIMES1,ER3	;;
	       ADD.W	 R4,R3			;;
	       MOV.W	 @ER3,R4		;;
	       CMP.W	 #D'1,R4                ;;
	       BCS	 F67_DO3		;;
	       INC.W	 #1,R4			;; ;;
	       MOV.W	 R4,@ER3		;; ;;
	       MOV.B	 @SC017_ADDR,R1L	;;
	       BCLR	 #4,R1L 		;;
	       MOV.B	 R1L,@SC017_ADDR

F67_DO3:       MOV.W	 @CHANNEL_BUFFER,R4	;;
	       SHLL.W	 R4			;;
	       MOV.L	 #WS067_ADDR,ER3      ;;
	       ADD.W	 R4,R3			 ;;
	       MOV.W	 @ER3,R4		 ;;get AD_CHx_OFFSET's value
	       MOV.W	 @NOW_TEMP,R3
	       SUB.W	 R4,R3			 ;;

	       BCC	 F67_DO2	   ;
	  ;	NOT.W	  R3		    ;
	  ;	ADD.W	  #1,R3 	    ;
	       BRA	 F67_DO2

F67_DO1:       MOV.W	 @NOW_TEMP,R3	   ;
F67_DO2:       MOV.B	 @TO_C_OR_F,R4L    ;
	       CMP.B	 #1,R4L 	   ;
	       BNE	 F67W_SAVE	   ;

;change +C to +F
	       MOV.W	 #H'0009,R4        ;F=(9/5)C+32.0
	       MULXU.W	 R4,ER3 	   ;
	       MOV.W	 #H'0005,R4        ;
	       DIVXU.W	 R4,ER3 	   ;
	       ADD.W	 #H'140,R3          ;D'320=H'140
	       JSR	 @FLAG_NON_CARRY0   ;
	       BRA	 F67W_SAVE	   ;
F67W_NEGATIVE_C_GET_F:
	       MOV.W	 #H'2710,R4         ;H'2710=D'10000
	       DIVXU.W	 R4,ER3 	    ;
	       PUSH.W	 E3	      ; start:
	       MOV.W	 #H'A,R4      ; change 1 degree to 0.3 degree
	       MULXU.W	 R4,ER3       ;
	       POP.W	 E3	      ;
	       PUSH.W	 R3	      ;
	       MOV.W	 E3,R3	      ;
	       MOV.W	 #H'0,E3      ;
	       MOV.W	 #D'1000,R4   ;
	       DIVXU.W	 R4,ER3       ;
	       MOV.W	 R3,E3	      ;
	       POP.W	 R3	      ;
	       ADD.W	 E3,R3	      ; end
	       MOV.W	 #H'0000,E3        ;
	       MOV.W	 #H'0009,R4        ;F=(9/5)C+32.0
	       MULXU.W	 R4,ER3 	   ;
	       MOV.W	 #H'0005,R4        ;
	       DIVXU.W	 R4,ER3 	   ;
	       MOV.W	 R3,R4
	       MOV.W	 #H'140,R3
	       SUB.W	 R4,R3		   ;D'320=H'140
	       BCC	 F67W_CHK_FLAG_F:8 ;
	       NOT.L	 ER3		   ;
	       ADD.L	 #1,ER3 	   ;
	       JSR	 @FLAG_CARRY	   ;
	       BRA	 F67W_SAVE
F67W_CHK_FLAG_C: CMP.L	   #0,ER3	    ;
		 BNE	   F67W_NON_CARRY_C ;
		 JSR	   @FLAG_ZERO	    ;
		 BRA	   F67W_C_POSITIVE  ;
F67W_CHK_FLAG_F: CMP.L	   #0,ER3	    ;
		 BNE	   F67W_NON_CARRY_F ;
		 JSR	   @FLAG_ZERO	    ;
		 BRA	   F67W_SAVE:8	;
F67W_NON_CARRY_C: JSR	   @FLAG_NON_CARRY0  ;
		  BRA	    F67W_C_POSITIVE ;
F67W_NON_CARRY_F: JSR	   @FLAG_NON_CARRY0  ;
F67W_SAVE:     CMP.W	 #WORD_RANGE,R2   ;
	       BCC	 F67W_D_R:8
	       MOV.B	 R3L,@ER2
	       INC.W	 #1,R2
	       MOV.B	 R3H,@ER2
	       MOV.W	 #H'000F,E3
	       MOV.W	 #H'000F,E4
	       RTS
F67W_D_R:      MOV.W	 R3,@ER2
	       MOV.W	 #H'000F,E3
	       MOV.W	 #H'000F,E4
F67_RET:       RTS
F67_RET_RESETF:  JSR	 @FLAG_RESET
		 RTS
T_BLOCK_SLOPE:	.DATA.W  7448,6866,6383,5958,5633,5327,5043,4809,4588,4393
		.DATA.W  4210,4053,3915,3781,3657,3550,3447,3354,3266,3189
		.DATA.W  3124,3065,3005,2939,2880,2826,2772,2721,2675,2628
		.DATA.W  2590,2555,2515,2484,2450,2419,2389,2361,2338,2309
		.DATA.W  2285,2261,2240,2217,2199,2177,2161,2143,2126,2109
		.DATA.W  2109
T_BLOCK_SHIFT:	.DATA.L  2241640,2215081,2185836,2153370,2123033
		.DATA.L  2089347,2052572,2017589,1980206,1942914
		.DATA.L  1903547,1865888,1829600,1791109,1751851
		.DATA.L  1715476,1677333,1639842,1602363,1566740
		.DATA.L  1535174,1504142,1470697,1432016,1395459
		.DATA.L  1359660,1322056,1285184,1250360,1212505
		.DATA.L  1180405,1149741,1112828,1082995,1049512
		.DATA.L  1016918,984752,953143,926346,890418
		.DATA.L  861410,830000,802182,769384,743460
		.DATA.L  711865,687348,658719,631340,603619,603619
T_BREAK_POINT:	.DATA.W  46,61,76,93,111,129,149,170,192
		.DATA.W  215,238,263,289,315,342,371,400,429,460
		.DATA.W  491,523,556,589,623,658,693,730,766,804
		.DATA.W  842,880,920,959,1000,1041,1082,1124,1166,1209
		.DATA.W  1252,1296,1340,1385,1430,1475,1521,1568,1614,1661
		.DATA.W  4096
;**************************	  V1.61  end	  *************************
;**************************************************************************
;;
;;
;;
;ONE STR
TMR_SUB_A:	BIAND		#MCS,R1L
		BST		#2,R1H		   ;push ACC
TMRA_JCS_JUG:	BTST		#JCS,R1L
		BNE		TMRA_RET
TMRA_FUN_SKIP:	BTST		#FUN_SKIP,R1L
		BNE		TMRA_RET
TMRA_TR_JUDGE:	BLD		#2,R1H
		BCC		TMRA_RESET
TMRA_GO:	MOV.W		R2,@R2_BUFFER	   ;
V1_V250_JUG:	CMP.W		#D'250,R2          ;VF.6 #D'251->D'250
		BCC		V251_V256_10MS	   ;
		MOV.B		@TIME_DIFF_10MS,R5L;A
		MOV.L		#T_C_STATUS,ER4    ;
		ADD.W		R2,R4		   ;
		MOV.B		@ER4,R6L	   ;B
		ADD.B		R5L,R6L 	   ;
		MOV.B		R6L,@ER4	   ;
		MOV.B		#0,R6H		   ;
		MOV.B		#D'10,R5L          ;
		DIVXU.B 	R5L,R6		   ;R6H:F R6L:E
		CMP.B		#0,R6L		   ;
		BEQ		INC_V:8 	   ;!!!!!!!!IMPORTANT!!!!!!!
		MOV.B		R6H,@ER4	   ;
INC_V:		SHLL.W		R2		   ;
		MOV.L		#V_MEMORY_ADDR,ER4 ;
		ADD.W		R2,R4		   ;
		MOV.W		@ER4,R5 	   ;V current value
		MOV.B		#0,R6H		   ;
		ADD.W		R6,R5		   ;R5: V cuurrent value
		MOV.W		R5,@ER4 	   ;
		BRA		TMR_V_COMPARE:8    ;
V251_V256_10MS: .EQU		$		   ;
		MOV.B		@TIME_DIFF_10MS,R6L;A
		SHLL.W		R2		   ;
		MOV.L		#V_MEMORY_ADDR,ER4 ;
		ADD.W		R2,R4		   ;C->V
		MOV.W		@ER4,R5 	   ;V current value
		MOV.B		#0,R6H		   ;
		ADD.W		R6,R5		   ;R6: V cuurrent value
		MOV.W		R5,@ER4 	   ;
TMR_V_COMPARE:	MOV.L		@ER7,ER4	   ;
		SUB.W		#D'13,R4           ;
		BLD		#6,@ER4 	   ;=1:register, =0:immediate
		BCS		TMR_D_REGISTER	   ;
TMR_D_TYPE:	CMP.W		R3,R5		   ;
		BCC		TMR_SET_COIL	   ;
		BCLR		#4,R1H		   ;7->4
		BRA		TMRA_RET	   ;
TMR_D_REGISTER: MOV.W		#H'000F,E3         ;
		MOV.W		@ER3,R4 	   ;
		MOV.W		R4,R3		   ;
		CMP.W		R3,R5		   ;
		BCC		TMR_SET_COIL	   ;
		BCLR		#4,R1H		   ;7->4
		BRA		TMRA_RET	   ;
TMR_SET_COIL:	MOV.W		@R2_BUFFER,R2	   ;
		SHLL.W		R2		   ;
		MOV.L		#V_MEMORY_ADDR,ER4 ;
		ADD.W		R2,R4		   ;
		MOV.W		R3,@ER4 	   ;V current value
		BSET		#4,R1H		   ;7->4
		MOV.L		@ER7,ER4	   ;
		SUB.W		#D'13,R4           ;
		BSET		#4,@ER4 	   ;set OUT(7->4)
TMRA_RET:	RTS				   ;

TMRA_RESET:	MOV.L		@ER7,ER4	   ;
		SUB.W		#D'13,R4           ;
		BCLR		#7,@ER4 	   ;reset OUT
		MOV.W		#0,R4		   ;Reset current value Vxxx
		MOV.L		#T_C_STATUS,ER5    ;
		ADD.W		R2,R5		   ;
		MOV.B		R4L,@ER5	   ;Reset accumulator
		MOV.L		#V_MEMORY_ADDR,ER5 ;
		SHLL.W		R2		   ;
		ADD.W		R2,R5		   ;
		MOV.W		R4,@ER5 	   ;
		BCLR		#4,R1H		   ;reset OUT (7->4)
		RTS
;TWO STR
TMR_SUB_B:	BIAND		#MCS,R1L	   ;
		BST		#2,R1H		   ;push ACC(RS)
		BLD		#7,R0L		   ;
		BIAND		#MCS,R1L	   ;
		BST		#3,R1H		   ;push TR
TMRB_JCS_JUG:	BTST		#JCS,R1L	   ;
		BNE		TMRA_RET	   ;
TMRB_FUN_SKIP:	BTST		#FUN_SKIP,R1L	   ;
		BNE		TMRA_RET	   ;
TMRB_TR_RS_JUG: BLD		#2,R1H		   ;
		BCS		TMRA_RESET	   ;RS=1
		BLD		#3,R1H		   ;
		BCS		TMRA_GO 	   ;judge TR
		MOV.W		R2,@R2_BUFFER	   ;;V0.8 FOR BUG MODIFY
		BRA		CNT_RET1	   ;NEW
CNT_SUB:
CNT_JCS_JUG:	BTST		#JCS,R1L
		BNE		CNT_RET
CNT_FUN_SKIP:	BTST		#FUN_SKIP,R1L
		BNE		CNT_RET
		BIAND		#MCS,R1L
		BST		#2,R1H
		BLD		#7,R0L
		BIAND		#MCS,R1L
		BST		#0,R1H
		BIAND		#1,R1H
		BST		#3,R1H
		BLD		#0,R1H
		BST		#1,R1H
		MOV.L		@ER7,ER4
		SUB.W		#D'13,R4
		MOV.B		R1H,@ER4
CNT_TR_RS_JUG:	BLD		#2,R1H
		BCS		CNT_RESET
		MOV.W		R2,@R2_BUFFER	  ;;
		BLD		#3,R1H
		BCS		CNT_GO:8
		BLD		#ONLS,R1H
		BAND		#0,R1H
		BCC		CNT_RET1
CNT_GO:     ;;	MOV.W		R2,@R2_BUFFER	   ;
		SHLL.W		R2		   ;
		MOV.L		#V_MEMORY_ADDR,ER4 ;
		ADD.W		R2,R4		   ;C->V
		MOV.W		@ER4,R5 	   ;V current value
		INC.W		#1,R5		   ;
		MOV.W		R5,@ER4 	   ;
CNT_V_COMPARE:;;MOV.L		@ER7,ER4	   ;
	      ;;SUB.W		#D'13,R4           ;
	      ;;BLD		#6,@ER4 	   ;
		BLD		#6,R1H		   ;=1:register, =0:immediate
		BCS		CNT_D_REGISTER	   ;
CNT_D_TYPE:	CMP.W		R3,R5		   ;
		BCC		CNT_SET_COIL	   ;
		BCLR		#4,R1H		   ;7->4
		BRA		CNT_RET 	   ;
CNT_D_REGISTER: MOV.W		#H'000F,E3         ;
		MOV.W		@ER3,R4 	   ;
		MOV.W		R4,R3		   ;
		CMP.W		R3,R5		   ;
		BCC		CNT_SET_COIL	   ;
		BCLR		#4,R1H		   ;7->4
		BRA		CNT_RET 	   ;
CNT_SET_COIL:	MOV.W		@R2_BUFFER,R2	   ;
		SHLL.W		R2		   ;
		MOV.L		#V_MEMORY_ADDR,ER4 ;
		ADD.W		R2,R4		   ;
		MOV.W		R3,@ER4 	   ;V current value
		BSET		#4,R1H		   ;7->4
		MOV.L		@ER7,ER4	   ;
		SUB.W		#D'13,R4           ;
		BSET		#4,@ER4 	   ;set OUT
CNT_RET:	RTS				   ;
;
CNT_RET1:	MOV.W		@R2_BUFFER,R2	   ;;;
		SHLL.W		R2		   ;
		MOV.L		#V_MEMORY_ADDR,ER4 ;
		ADD.W		R2,R4		   ;C->V
		MOV.W		@ER4,R5 	   ;V current value
		BLD		#6,R1H		   ;=1:register, =0:immediate
		BCS		CNT_RET3:8	   ;
CNT_RET2:	CMP.W		R3,R5		   ;
		BCC		CNT_SET_COIL	   ;
		BCLR		#4,R1H		   ;7->4
		BRA		CNT_RET 	   ;
CNT_RET3:	MOV.W		#H'000F,E3         ;
		MOV.W		@ER3,R4 	   ;
		MOV.W		R4,R3		   ;
		CMP.W		R3,R5		   ;
		BCC		CNT_SET_COIL	   ;
		BCLR		#4,R1H		   ;7->4
		BRA		CNT_RET 	   ;
CNT_RESET:	MOV.L		@ER7,ER4	   ;
		SUB.W		#D'13,R4           ;
		BCLR		#4,@ER4 	   ;reset OUT(7->4)
		MOV.W		#0,R4		   ;Reset current value Vxxx
		MOV.L		#T_C_STATUS,ER5    ;
		ADD.W		R2,R5		   ;
		MOV.B		R4L,@ER5	   ;Reset accumulator
		MOV.L		#V_MEMORY_ADDR,ER5 ;
		SHLL.W		R2		   ;
		ADD.W		R2,R5		   ;
		MOV.W		R4,@ER5 	   ;
		BCLR		#4,R1H		   ;reset OUT(7->4)
		RTS				   ;

;;Calculate TMR/CNT address and data type
;Input: R0H: 0,R6,R5,R4,R3,R2,R1,R0
;	R0L: P,C3,C2,C1,C0,R9,R8,R7
;	R1L: 0, 0, 0, 0,CSUM3,CSUM2,CSUM1,CSUM0
;ER6+2: R0H: T3 ,    D,   T2, T1/D11,T0/D10,R9/D9,R8/D8,R7/D7
;	R0L: P	,R6/D6,R5/D5,  R4/D4, R3/D3,R2/D2,R1/D1,R0/D0
;ER5+1: R1L: D15,  D14,  D13,R10/D12, CSUM3,CSUM2,CSUM1,CSUM0
;Output R2 : #V_REG(0-1023, means V1-V1024)
;	R3 : #PRESET_DATA(R:0-2047 means absolute address for register type)
;	OPERAND_TYPE-> 1 : Register(R10-R0) V1-V1024,D1-D2048,WX1-WX24,WY1-WY27
;		       0 : Immediate data(D15-D0)
;	JUDGE_NG-> 1 : error range
;Register can not be used : ER6,ER5,ER4
TMR_CNT_ADDR:	 MOV.B	   R0H,R2L		  ;
		 BLD	   #0,R0L		  ;
		 BST	   #7,R2L		  ;
		 BLD	   #1,R0L		  ;
		 BST	   #0,R2H		  ;
		 BLD	   #2,R0L		  ;
		 BST	   #1,R2H		  ;
		 AND.W	   #B'0000001111111111,R2 ;000000RRRRRRRRRR
		 MOV.W	   @ER6+,R0		  ;	 9876543210
		 MOV.B	   @ER5+,R1L		  ;
		 BLD	   #6,R0H		  ;
		 BST	   OPERAND_TYPE 	  ;
		 BCS	   TMR_CNT_REG		  ;
TMR_CNT_DATA:	 SHLR.B    R0H			  ;
		 BST	   #7,R0L		  ;
		 BLD	   #4,R1L		  ;
		 BST	   #4,R0H		  ;
		 BLD	   #5,R1L		  ;
		 BST	   #5,R0H		  ;
		 BLD	   #6,R1L		  ;
		 BST	   #6,R0H		  ;
		 BLD	   #7,R1L		  ;
		 BST	   #7,R0H		  ;
		 MOV.W	   R0,R3		  ;
		 BRA	   TMR_CNT_OK		  ;
TMR_CNT_REG:	 MOV.B	   R0H,R1H		  ;PUSH R0H
		 SHLR.B    R0H			  ;
		 BST	   #7,R0L		  ;
		 BLD	   #4,R1L		  ;
		 BST	   #2,R0H		  ;
		 MOV.W	   R0,R3		  ;
		 AND.W	   #H'07FF,R3             ;
		 SHLL.W    R3			  ;absolute address
		 AND.B	   #B'10111000,R1H        ;
TC_WY_JUG:	 CMP.B	   #B'10011000,R1H        ;
		 BNE	   TC_WX_JUG:8		  ;
		 MOV.L	   #WY_MEMORY_ADDR,ER0	  ;
		 ADD.W	   R0,R3		  ;
		 BRA	   TMR_CNT_OK:8 	  ;
TC_WX_JUG:	 CMP.B	   #B'10100000,R1H        ;
		 BNE	   TC_V_JUG:8		  ;
		 MOV.L	   #WX_MEMORY_ADDR,ER0	  ;
		 ADD.W	   R0,R3		  ;
		 BRA	   TMR_CNT_OK:8 	  ;
TC_V_JUG:	 CMP.B	   #B'10101000,R1H        ;
		 BNE	   TC_D_JUG:8		  ;
		 MOV.L	   #V_MEMORY_ADDR,ER0	  ;
		 ADD.W	   R0,R3		  ;
		 BRA	   TMR_CNT_OK:8 	  ;
TC_D_JUG:	 CMP.B	   #B'10110000,R1H        ;
		 BNE	   TMR_CNT_ERR:8	  ;
		 MOV.L	   #D_MEMORY_ADDR,ER0	  ;
		 ADD.W	   R0,R3		  ;
TMR_CNT_OK:	 BCLR	   JUDGE_NG		  ;
		 RTS				  ;
TMR_CNT_ERR:	 BSET	   JUDGE_NG		  ;
		 RTS				  ;

;;Calculate X,Y,C,M address and bit number
;Input	R0H: 0,TP1,TP0,A4,A3,A2,A1,A0
;	R0L: P, C3, C2,C1,C0,B2,B1,B0
;	R1L: A8,A7,A6,A5,CSUM3,CSUM2,CSUM1,CSUM0
;Output R0 : (addr:16)
;	R1L: #bitost
X_Y_C_ADDR:	 MOV.B	   R0H,R2L	      ;
		 MOV.B	   #H'0,R2H           ;
		 BLD	   #4,R1L	      ;
		 BST	   #5,R2L	      ;
		 BLD	   #5,R1L	      ;
		 BST	   #6,R2L	      ;
		 BLD	   #6,R1L	      ;
		 BST	   #7,R2L	      ;
		 BLD	   #7,R1L	      ;
		 BST	   #0,R2H	      ;
		 MOV.B	   R0L,R1L	      ;PUSH R0L
		 AND.B	   #B'01100000,R0H    ;
X_ADDR: 	 CMP.B	   #B'00000000,R0H    ;
		 BNE	   Y_ADDR:8	      ;
		 MOV.L	   #X_STATE,ER0       ;
		 BRA	   X_Y_C_ADDR1:8      ;
Y_ADDR: 	 CMP.B	   #B'00100000,R0H    ;
		 BNE	   C_ADDR:8	      ;
		 MOV.L	   #Y_STATE,ER0       ;
		 BRA	   X_Y_C_ADDR1:8      ;
C_ADDR: 	 CMP.B	   #B'01000000,R0H    ;
		 BNE	   M_ADDR:8	      ;
		 MOV.L	   #C_STATE,ER0       ;
		 BRA	   X_Y_C_ADDR1:8      ;
M_ADDR: 	 MOV.L	   #M_STATE,ER0       ;
X_Y_C_ADDR1:	 ADD.W	   R2,R0	      ;addr:16
		 SHLL.B    R1L		      ;
		 SHLL.B    R1L		      ;
		 SHLL.B    R1L		      ;
		 SHLL.B    R1L		      ;
		 AND.B	   #B'01110000,R1L    ;#bitost
		 RTS

;;Calculate FUNCTION source address and data type
;Input: R0H: 0,C10,C9,C8,C7,C6,C5,C4
;	R0L: BITN1(P),C3,C2,C1,C0,BITN0,WN1,WN0
;	R1L: 0, 0, 0,C11,CSUM3,CSUM2,CSUM1,CSUM0
;ER6+2: R0H: 1	,  1,  T2,  T1, T0, R9, R8, R7
;	R0L: P	, R6,  R5,  R4, R3, R2, R1, R0
;ER5+1: R1L: 0	,  0  , 0, R10, CSUM3,CSUM2,CSUM1,CSUM0
;ER6+2: R0H: 1	,  1,  T2,  T1, T0, R9, R8, R7
;	R0L: P	, R6,  R5,  R4, R3, R2, R1, R0
;ER5+1: R1L: 0	,  0  , 0, R10, CSUM3,CSUM2,CSUM1,CSUM0
;ER6+2: R0H: 1	,  D,	T2, T1/D11,T0/D10,R9/D9,R8/D8,R7/D7
;	R0L: P	,R6/D6,R5/D5,  R4/D4, R3/D3,R2/D2,R1/D1,R0/D0
;ER5+1: R1L: D15,  D14,  D13,R10/D12, CSUM3,CSUM2,CSUM1,CSUM0
;Output R2 : #V_REG(0-1023, means V1-V1024)
;	R3 : #PRESET_DATA(R:0-2047 means absolute address for register type)
;	SECOND_WORD : (register absolute address)
;	THIRD_WORD  : (register absolute address)
;	FOURTH_WORD : (0-65535 or register absolute address)
;	OPERAND_TYPE-> 1 : Register(R10-R0) V1-V1024,D1-D2048,WX1-WX24,WY1-WY27
;	(last word)	   X1-X384,Y1-Y384,C1-C2048
;		       0 : Immediate data(D15-D0)
;	BITN1,BITN0 -> 00:8 bit, 01:16 bit, 10:32 bit
;	JUDGE_NG-> 1 : error range
;Register can not be used : ER6,ER5,ER4 	  ;
FUN_DATA_ADDR:	 BLD	   #2,R0L		  ;
		 BST	   BITN0		  ;
		 BLD	   #7,R0L		  ;;;;FOR NEW PU12
		 BST	   BITN1		  ;;;;
	      ;;;BCLR	   BITN1		  ;;;;FOR OLD PU02/TEST
		 AND.B	   #H'03,R0L              ;
		 MOV.B	   R0L,@BYTE_COUNT	  ;INSTRUCTION LENGTH
		 MOV.L	   #SECOND_WORD,ER2	  ;
D_OPERAND_CAL:	 MOV.W	   @ER6+,R0		  ;
		 MOV.B	   @ER5+,R1L		  ;
		 BLD	   #6,R0H		  ;
		 BST	   OPERAND_TYPE 	  ;
		 BCS	   OPERAND_REG:8	  ;
OPERAND_DATA:	 SHLR.B    R0H			  ;
		 BST	   #7,R0L		  ;
		 BLD	   #4,R1L		  ;
		 BST	   #4,R0H		  ;
		 BLD	   #5,R1L		  ;
		 BST	   #5,R0H		  ;
		 BLD	   #6,R1L		  ;
		 BST	   #6,R0H		  ;
		 BLD	   #7,R1L		  ;
		 BST	   #7,R0H		  ;
		 MOV.W	   R0,R3		  ;
		 BRA	   FUNC_LAST_JUG	  ;
OPERAND_REG:	 MOV.B	   R0H,R1H		  ;PUSH R0H
		 SHLR.B    R0H			  ;
		 BST	   #7,R0L		  ;
		 BLD	   #4,R1L		  ;
		 BST	   #2,R0H		  ;
		 MOV.W	   R0,R3		  ;
		 AND.W	   #H'07FF,R3             ;
		 SHLL.W    R3			  ;absolute address
		 AND.B	   #B'10111000,R1H        ;
F_WY_JUG:	 CMP.B	   #B'10011000,R1H        ;
		 BNE	   F_WX_JUG:8		  ;
		 MOV.L	   #WY_MEMORY_ADDR,ER0	  ;
		 ADD.W	   R0,R3		  ;
		 BRA	   FUNC_LAST_JUG	  ;
F_WX_JUG:	 CMP.B	   #B'10100000,R1H        ;
		 BNE	   F_WC_JUG:8		  ;
		 MOV.L	   #WX_MEMORY_ADDR,ER0	  ;
		 ADD.W	   R0,R3		  ;
		 BRA	   FUNC_LAST_JUG	  ;
F_WC_JUG:	 CMP.B	   #B'10111000,R1H        ;VF.6 #B'10100000->#B'10111000
		 BNE	   F_V_JUG:8		  ;
		 MOV.L	   #WC_MEMORY_ADDR,ER0	  ;
		 ADD.W	   R0,R3		  ;
		 BRA	   FUNC_LAST_JUG	  ;
F_V_JUG:	 CMP.B	   #B'10101000,R1H        ;
		 BNE	   F_D_JUG:8		  ;
		 MOV.L	   #V_MEMORY_ADDR,ER0	  ;
		 ADD.W	   R0,R3		  ;
		 BRA	   FUNC_LAST_JUG	  ;
F_D_JUG:	 CMP.B	   #B'10110000,R1H        ;
		 BNE	   F_X_JUG:8		  ;
		 MOV.L	   #D_MEMORY_ADDR,ER0	  ;
		 ADD.W	   R0,R3		  ;
		 BRA	   FUNC_LAST_JUG	  ;
F_X_JUG:	 CMP.B	   #B'10010000,R1H        ;
		 BNE	   F_Y_JUG:8		  ;
		 MOV.L	   #X_STATE,ER0 	  ;
		 SHLR.W    R3			  ;
		 ADD.W	   R0,R3		  ;
		 BRA	   FUNC_LAST_JUG	  ;
F_Y_JUG:	 CMP.B	   #B'10000000,R1H        ;
		 BNE	   F_C_JUG:8		  ;
		 MOV.L	   #Y_STATE,ER0 	  ;
		 SHLR.W    R3			  ;
		 ADD.W	   R0,R3		  ;
		 BRA	   FUNC_LAST_JUG	  ;
F_C_JUG:	 MOV.L	   #C_STATE,ER0 	  ;
		 SHLR.W    R3			  ;
		 ADD.W	   R0,R3		  ;
FUNC_LAST_JUG:	 MOV.W	   R3,@ER2		  ;
		 INC.L	   #2,ER2		  ;
		 MOV.B	   @BYTE_COUNT,R0L	  ;
		 DEC.B	   R0L			  ;
		 MOV.B	   R0L,@BYTE_COUNT	  ;
		 BNE	   D_OPERAND_CAL	  ;
FUNC_JUG_OK:	 BCLR	   JUDGE_NG		  ;
		 RTS				  ;
FUNC_JUG_NG:	 BSET	   JUDGE_NG		  ;
		 RTS				  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;F23,F24,F48,F49 USED;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;
;R0H: 1  ,  1,	T2,  T1, T0, B2, B1, B0
;R0L: P  , R6,	R5,  R4, R3, R2, R1, R0
;R1L: R10, R9,	R8,  R7, CSUM3,CSUM2,CSUM1,CSUM0
;
;R0:  R10, R9,	R8,  T1, T0, B2, B1, B0
;     R7 , R6,	R5,  R4, R3, R2, R1, R0
;T1  T0
; 0   0 : X0001-X0384
; 0   1 : Y0001-Y0384
; 1   0 : C0001-C2048
; 1   1 : M0001-M0128
;SECOND_WORD : (register absolute address)
;;;;;;;;;;;;;;;;;;;;;;;;
FUN_RELAY_ADDR:  BLD	   #2,R0L		  ;
		 BST	   BITN0		  ;
		 BLD	   #7,R0L		  ;
		 BST	   BITN1		  ;;;;FOR OLD PU02/TEST
		 MOV.W	   @ER6+,R0		  ;
		 MOV.B	   @ER5+,R1L		  ;
		 BLD	   #4,R1L		  ;R7
		 BST	   #7,R0L		  ;
		 BLD	   #5,R1L		  ;R8
		 BST	   #5,R0H		  ;
		 BLD	   #6,R1L		  ;R9
		 BST	   #6,R0H		  ;
		 BLD	   #7,R1L		  ;R10
		 BST	   #7,R0H		  ;
		 MOV.W	   R0,@SECOND_WORD	  ;
		 BCLR	   JUDGE_NG
		 RTS
;;;;;;;Return : @R3_DATA->S1's real content
;;;;;;; 	@R4_DATA->S2's real content
;;;;;;;
CAL_S1_S2:	 MOV.W	   #H'000F,E3
		 MOV.W	   E3,E4
		 BLD	   #5,R1H
		 BCS	   S1_S2_DW
		 BLD	   #4,R1H
		 BCS	   S1_S2_W
;;;1
S1_S2_B:	 BLD	   #6,R1H
		 BCS	   S2_BYTE:8
		 MOV.B	   R4L,@R4_DATA
		 BRA	   S1_BYTE:8
S2_BYTE:	 CMP.W	   #WORD_RANGE,R4
		 BCS	   S2_R_B:8
		 INC.W	   #1,R4
S2_R_B: 	 MOV.B	   @ER4,R4L
		 MOV.B	   R4L,@R4_DATA
S1_BYTE:	 CMP.W	   #WORD_RANGE,R3
		 BCS	   S1_R_B:8
		 INC.W	   #1,R3
S1_R_B: 	 MOV.B	   @ER3,R4L
		 MOV.B	   R4L,@R3_DATA
		 RTS
;;;2
S1_S2_W:	 BLD	   #6,R1H
		 BCS	   S2_WORD:8
		 MOV.W	   R4,@R4_DATA
		 BRA	   S1_WORD:8
S2_WORD:	 CMP.W	   #WORD_RANGE,R4
		 BCC	   S2_V:8
		 MOV.B	   @ER4,R5L
		 INC.W	   #1,R4
		 MOV.B	   @ER4,R5H
		 BRA	   S2_V2:8
S2_V:		 MOV.W	   @ER4,R5
S2_V2:		 MOV.W	   R5,@R4_DATA
S1_WORD:	 CMP.W	   #WORD_RANGE,R3
		 BCC	   S1_V:8
		 MOV.B	   @ER3,R5L
		 INC.W	   #1,R3
		 MOV.B	   @ER3,R5H
		 BRA	   S1_V2:8
S1_V:		 MOV.W	   @ER3,R5
S1_V2:		 MOV.W	   R5,@R3_DATA
		 RTS
;;;;3
S1_S2_DW:	 BLD	   #6,R1H
		 BCS	   S2_DW:8
		 MOV.W	   #0,E4
		 MOV.L	   ER4,@R4_DATA
		 BRA	   S1_DW:8
S2_DW:		 CMP.W	   #WORD_RANGE,R4
		 BCC	   S2_V_DW:8
		 MOV.B	   @ER4,R5L
		 INC.W	   #1,R4
		 MOV.B	   @ER4,R5H
		 INC.W	   #1,R4
		 MOV.B	   @ER4,R6L
		 INC.W	   #1,R4
		 MOV.B	   @ER4,R6H
		 MOV.W	   R6,E5
		 BRA	   S2_V_DW1:8
S2_V_DW:	 MOV.W	   @ER4,R5
		 INC.L	   #2,ER4
		 MOV.W	   @ER4,E5
S2_V_DW1:	 MOV.L	   ER5,@R4_DATA
S1_DW:		 CMP.W	   #WORD_RANGE,R3
		 BCC	   S1_V_DW:8
		 MOV.B	   @ER3,R4L
		 INC.W	   #1,R3
		 MOV.B	   @ER3,R4H
		 INC.W	   #1,R3
		 MOV.B	   @ER3,R5L
		 INC.W	   #1,R3
		 MOV.B	   @ER3,R5H
		 MOV.W	   R5,E4
		 BRA	   S1_V_DW1:8
S1_V_DW:	 MOV.W	   @ER3,R4
		 INC.L	   #2,ER3
		 MOV.W	   @ER3,E4
S1_V_DW1:	 MOV.L	   ER4,@R3_DATA
		 RTS

;  WS006 : Boolean program error address
;  WS009 : 00->normal
;	 : 01->User memory diagnostic error
;     01 : 09->No enough ENDS(F-08) existed
;	 : 0A->Accumulator of the TMR/CNT over range
;     01 : 0B->ENDS(F-08) too much
;     02 : 0E->The special function is double used(F-52,F-53,F-55,F-58,F-59)
;	 : 16->Program check error
;	 : 18->Cannot use F34_SCLK
;     03 : 20->STACK OVER
;     04 : 21->STACK UNDER
;     05 : 22->MCR ERROR
;     06 : 23->JCS ERROR
;     07 : 24->JCR ERROR
;     11 : 25->DOUBLE OUT
;      8 : 26->DOUBLE TMR/CNT ERROR
;      9 : 27->FOR/NEXT ERROR
;     11 : 28->NO LABEL ERROR
;     10 : 29->DOUBLE LABEL ERROR
;	 : 2A->ONLS/ONLR ERROR
F08_ENDS_OVER:	MOV.B		#D'01,R1L
		BRA		ERROR_STATUS
F08_ENDS_LESS:	MOV.B		#D'01,R1L
		BRA		ERROR_STATUS
RANGE_OVER:	MOV.B		#D'08,R1L
		BRA		ERROR_STATUS
DOUBLS_FUNC_ERR: MOV.B		#D'02,R1L        ;;V0.C NEW ADDED
		BRA		ERROR_STATUS	 ;
PROG_CHK_ERR:	MOV.B		#D'12,R1L
		BRA		ERROR_STATUS
STACK_OVER:	MOV.B		#D'03,R1L
		BRA		ERROR_STATUS
STACK_UNDER:	MOV.B		#D'04,R1L
		BRA		ERROR_STATUS
DOUBLS_OUT_ERR: MOV.B		#D'11,R1L
		BRA		ERROR_STATUS
DOUBLS_T_C_ERR: MOV.B		#D'08,R1L          ;;V0.B
		DEC.W		#2,R6		   ;;
		BRA		ERROR_STATUS	   ;;
MCR_ERROR:	MOV.B		#D'05,R1L
		BRA		ERROR_STATUS
JCS_ERROR:	MOV.B		#D'06,R1L
		BRA		ERROR_STATUS
JCR_ERROR:	MOV.B		#D'07,R1L
		BRA		ERROR_STATUS
FOR_NEXT_ERROR: MOV.B		#D'09,R1L
		BRA		ERROR_STATUS
LABEL_ERROR:	MOV.B		#D'10,R1L
;;ONLS_ONLR_ERR:  MOV.B 	  #H'2A,R1L
;;		  BRA		  ERROR_STATUS
ERROR_STATUS:	MOV.B		R1L,@WS009_ADDR+1   ;ERROR KIND
		SHLR.W		R6		    ;
		DEC.W		#1,R6		    ;
		MOV.W		R6,@WS006_ADDR	    ;ERROR ADDRESS
		BSET		LOGIC_ERR_BIT	    ;
		RTS				    ;
					       ;	  |   MCS_BIT
OUT_SUB0:	BIAND		#MCS,R1L       ;   MCS	  |    0  1
		BTST		#JCS,R1L       ; -----------------------
		BNE		OUT_RET0:8     ; ACC   0  |    0  1
		BST		#0,@ER2        ;       1  |    0  0
OUT_RET0:	RTS			       ;
;					       ;
OUT_SUB1:	BIAND		#MCS,R1L       ;	  |   JCS_BIT
		BTST		#JCS,R1L       ;   JCS	  |    0  1
		BNE		OUT_RET1:8     ; -----------------------
		BST		#1,@ER2        ; ACC   0  |    0  0
OUT_RET1:	RTS			       ;       1  |    0  1
;					       ;
OUT_SUB2:	BIAND		#MCS,R1L
		BTST		#JCS,R1L
		BNE		OUT_RET2:8
		BST		#2,@ER2
OUT_RET2:	RTS
;
OUT_SUB3:	BIAND		#MCS,R1L
		BTST		#JCS,R1L
		BNE		OUT_RET3:8
		BST		#3,@ER2
OUT_RET3:	RTS
;
OUT_SUB4:	BIAND		#MCS,R1L
		BTST		#JCS,R1L
		BNE		OUT_RET4:8
		BST		#4,@ER2
OUT_RET4:	RTS
;
OUT_SUB5:	BIAND		#MCS,R1L
		BTST		#JCS,R1L
		BNE		OUT_RET5:8
		BST		#5,@ER2
OUT_RET5:	RTS
;
OUT_SUB6:	BIAND		#MCS,R1L
		BTST		#JCS,R1L
		BNE		OUT_RET6:8
		BST		#6,@ER2
OUT_RET6:	RTS
;
OUT_SUB7:	BIAND		#MCS,R1L
		BTST		#JCS,R1L
		BNE		OUT_RET7:8
		BST		#7,@ER2
OUT_RET7:	RTS
;

OUT_SUB00:
		BTST		#JCS,R1L
		BNE		OUT_RET00:8
;;		BTST		#FUN_SKIP,R1L	 ;;V0.9
;;		BNE		OUT_RET00:8	 ;;
		BST		#2,R1H
		BLD		#4,R1H
		BST		#0,@ER2
		BLD		#2,R1H
OUT_RET00:	RTS
;
OUT_SUB01:
		BTST		#JCS,R1L
		BNE		OUT_RET01:8
;;		BTST		#FUN_SKIP,R1L
;;		BNE		OUT_RET01:8
		BST		#2,R1H
		BLD		#4,R1H
		BST		#1,@ER2
		BLD		#2,R1H
OUT_RET01:	RTS
;
OUT_SUB02:
		BTST		#JCS,R1L
		BNE		OUT_RET02:8
;;		BTST		#FUN_SKIP,R1L
;;		BNE		OUT_RET02:8
		BST		#2,R1H
		BLD		#4,R1H
		BST		#2,@ER2
		BLD		#2,R1H
OUT_RET02:	RTS
;
OUT_SUB03:
		BTST		#JCS,R1L
		BNE		OUT_RET03:8
;;		BTST		#FUN_SKIP,R1L
;;		BNE		OUT_RET03:8
		BST		#2,R1H
		BLD		#4,R1H
		BST		#3,@ER2
		BLD		#2,R1H
OUT_RET03:	RTS
;
OUT_SUB04:
		BTST		#JCS,R1L
		BNE		OUT_RET04:8
;;		BTST		#FUN_SKIP,R1L
;;		BNE		OUT_RET04:8
		BST		#2,R1H
		BLD		#4,R1H
		BST		#4,@ER2
		BLD		#2,R1H
OUT_RET04:	RTS
;
OUT_SUB05:
		BTST		#JCS,R1L
		BNE		OUT_RET05:8
;;		BTST		#FUN_SKIP,R1L
;;		BNE		OUT_RET05:8
		BST		#2,R1H
		BLD		#4,R1H
		BST		#5,@ER2
		BLD		#2,R1H
OUT_RET05:	RTS
;
OUT_SUB06:
		BTST		#JCS,R1L
		BNE		OUT_RET06:8
;;		BTST		#FUN_SKIP,R1L
;;		BNE		OUT_RET06:8
		BST		#2,R1H
		BLD		#4,R1H
		BST		#6,@ER2
		BLD		#2,R1H
OUT_RET06:	RTS
;
OUT_SUB07:
		BTST		#JCS,R1L
		BNE		OUT_RET07:8
;;		BTST		#FUN_SKIP,R1L
;;		BNE		OUT_RET07:8
		BST		#2,R1H
		BLD		#4,R1H
		BST		#7,@ER2
		BLD		#2,R1H
OUT_RET07:	RTS

STR_INC:	MOV.B		@STR_NUMBER,R2L
		INC.B		R2L
		MOV.B		R2L,@STR_NUMBER
		RTS
STR_DEC:	MOV.B		@STR_NUMBER,R2L
		DEC.B		R2L
		MOV.B		R2L,@STR_NUMBER
		RTS

;;;;;;;
C_TYPE0:	MOV.W	  #H'5A00,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		JSR	  @CAL_FUNC_ADDR   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'0000,R2       ;
		MOV.W	  R2,@ER4	   ;NOP
		INC.L	  #2,ER4	   ;
		MOV.W	  R2,@ER4	   ;NOP
		INC.L	  #2,ER4	   ;
		BSET	  FN_BIT	   ;
		RTS			   ;
C_TYPE1:	MOV.W	  #H'5E00,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		JSR	  @CAL_FUNC_ADDR   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'4002,R2       ;
		MOV.W	  R2,@ER4	   ;BRA NEXT:8
		INC.L	  #2,ER4	   ;
		MOV.W	  #0,R2 	   ;
		MOV.W	  R2,@ER4	   ;NOP
		INC.L	  #2,ER4	   ;
		BSET	  FN_BIT	   ;
		RTS			   ;
;
C_TYPE31:	MOV.W	  #H'F100,R2       ;;V1.3 FOR F06 BUG
		BRA	  C_TYPE3_MODE:8   ;;
C_TYPE3:	MOV.W	  #H'F102,R2       ;
C_TYPE3_MODE:	MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'5E00,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		JSR	  @CAL_FUNC_ADDR   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7721,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
;;;;		BSET	  FN_BIT	   ;;V0.D
		RTS			   ;
;
C_TYPE4:	MOV.W	  #H'5E00,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		JSR	  @CAL_FUNC_ADDR   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7721,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'0000,R2       ;
		MOV.W	  R2,@ER4	   ;NOP
		INC.L	  #2,ER4	   ;
		BSET	  FN_BIT	   ;
		RTS			   ;
;
C_TYPE50:	JSR	  @FUN_RELAY_ADDR  ;
		BRA	  C_TYPE51:8	   ;
C_TYPE5:	JSR	  @FUN_DATA_ADDR   ;
C_TYPE51:	MOV.B	  #H'F1,R2H        ;F102    ER6,ER5->ER4
		MOV.B	  #H'02,R2L        ;          R0,R1
		BLD	  BITN0 	   ;
		BST	  #4,R2L	   ;
		BLD	  BITN1 	   ;
		BST	  #5,R2L	   ;
		BLD	  OPERAND_TYPE	   ;
		BST	  #6,R2L	   ;
		BLD	  SCLK		   ;
		BST	  #7,R2L	   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'76F9,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'6721,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7902,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  @SECOND_WORD,R2  ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'5E00,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		JSR	  @CAL_FUNC_ADDR   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7721,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		BSET	  FN_BIT	   ;
		RTS			   ;
;
C_TYPE5_F33:	MOV.B	  #H'F1,R2H        ;F102    ER6,ER5->ER4
		MOV.B	  #H'02,R2L        ;          R0,R1
		BLD	  BITN0 	   ;
		BST	  #4,R2L	   ;
		BLD	  BITN1 	   ;
		BST	  #5,R2L	   ;
		BLD	  OPERAND_TYPE	   ;
		BST	  #6,R2L	   ;
		BLD	  SCLK		   ;
		BST	  #7,R2L	   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'76F9,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'6721,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7902,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  @ER6+,R2	   ;;;F33 USED ONLY
		INC.L	  #1,ER5	   ;;VF.6 BIG BUG
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.B	  #H'FB,R2L        ;
		MOV.B	  R2L,@ER4	   ;
		INC.L	  #1,ER4	   ;
		MOV.B	  R0L,@ER4	   ;
		INC.L	  #1,ER4	   ;
		MOV.W	  #H'5E00,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		JSR	  @CAL_FUNC_ADDR   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		BSET	  FN_BIT	   ;
		RTS			   ;
;
C_TYPE6:	JSR	  @FUN_DATA_ADDR   ;
		MOV.B	  #H'F1,R2H        ;F102    ER6,ER5->ER4
		MOV.B	  #H'02,R2L        ;          R0,R1
		BLD	  BITN0 	   ;
		BST	  #4,R2L	   ;
		BLD	  BITN1 	   ;
		BST	  #5,R2L	   ;
		BLD	  OPERAND_TYPE	   ;
		BST	  #6,R2L	   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'76F9,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'6721,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'4408,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7902,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  @SECOND_WORD,R2  ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'5E00,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		JSR	  @CAL_FUNC_ADDR   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		BSET	  FN_BIT	   ;
		RTS			   ;
;;
C_TYPE6_1:	JSR	  @FUN_DATA_ADDR   ;FOR F49_IORB V0.B
		MOV.B	  #H'F1,R2H        ;F102    ER6,ER5->ER4
		MOV.B	  #H'02,R2L        ;          R0,R1
		BLD	  BITN0 	   ;
		BST	  #4,R2L	   ;
		BLD	  BITN1 	   ;
		BST	  #5,R2L	   ;
		BLD	  OPERAND_TYPE	   ;
		BST	  #6,R2L	   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'76F9,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'6721,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'4408,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7902,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		PUSH.L	  ER6		   ;;
		PUSH.L	  ER5		   ;;
		SUB.L	  #2,ER6	   ;;
		SUB.L	  #1,ER5	   ;;
		MOV.W	  @ER6,R0	   ;;
		MOV.B	  @ER5,R1L	   ;;
		JSR	  @FUN_RELAY_ADDR  ;;
		POP.L	  ER5		   ;;
		POP.L	  ER6		   ;;
		MOV.W	  @SECOND_WORD,R2  ;;;;CHANGE TO RELAY ADDRESS
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'5E00,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		JSR	  @CAL_FUNC_ADDR   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		BSET	  FN_BIT	   ;
		RTS			   ;
;
C_TYPE7:	JSR	  @FUN_DATA_ADDR   ;
		MOV.B	  #H'F1,R2H        ;F102    ER6,ER5->ER4
		MOV.B	  #H'02,R2L        ;          R0,R1
		BLD	  BITN0 	   ;
C_TYPE7_1_J:	BST	  #4,R2L	   ;
		BLD	  BITN1 	   ;
		BST	  #5,R2L	   ;
		BLD	  OPERAND_TYPE	   ;
		BST	  #6,R2L	   ;
		BLD	  SCLK		   ;
		BST	  #7,R2L	   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'76F9,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'6721,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7691,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'6731,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7902,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  @SECOND_WORD,R2  ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7903,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  @THIRD_WORD,R2   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'5E00,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		JSR	  @CAL_FUNC_ADDR   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		BSET	  FN_BIT	   ;
		MOV.W	  #H'0000,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		RTS			   ;
;C_TYPE7_1: FOR F51_ZRST only		   ;;V0.8  MODIFY C_F51 TOO
C_TYPE7_1:	JSR	  @FUN_DATA_ADDR   ;
		MOV.B	  #H'F1,R2H        ;F102    ER6,ER5->ER4
		MOV.B	  #H'02,R2L        ;          R0,R1
		BLD	  BITN0 	   ;
		BCS	  C_TYPE7_1_J	   ;
		BST	  #4,R2L	   ;
		BLD	  BITN1 	   ;
		BST	  #5,R2L	   ;
		BLD	  OPERAND_TYPE	   ;
		BST	  #6,R2L	   ;
		BLD	  SCLK		   ;
		BST	  #7,R2L	   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		PUSH.L	  ER6		   ;;
		PUSH.L	  ER5		   ;;
		SUB.L	  #4,ER6	   ;;
		SUB.L	  #2,ER5	   ;;
		MOV.W	  @ER6,R0	   ;;
		MOV.B	  @ER5,R1L	   ;;
		JSR	  @FUN_RELAY_ADDR  ;;
		POP.L	  ER5		   ;;
		POP.L	  ER6		   ;;
		MOV.W	  #H'76F9,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'6721,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7691,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'6731,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7902,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  @SECOND_WORD,R2  ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7903,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  @THIRD_WORD,R2   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'5E00,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		JSR	  @CAL_FUNC_ADDR   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		BSET	  FN_BIT	   ;
		MOV.W	  #H'0000,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		RTS			   ;
;
C_TYPE7_F33:	MOV.B	  #H'F1,R2H        ;F102    ER6,E
		MOV.B	  #H'02,R2L        ;          R0,
		BLD	  BITN0 	   ;
		BST	  #4,R2L	   ;
		BLD	  BITN1 	   ;
		BST	  #5,R2L	   ;
		BLD	  OPERAND_TYPE	   ;
		BST	  #6,R2L	   ;
		BLD	  SCLK		   ;
		BST	  #7,R2L	   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'76F9,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'6721,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7691,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'6731,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7902,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  @ER6+,R2	   ;F33 USED ONLY
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7903,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  @ER6+,R2	   ;F33 USED ONLY
		INC.L	  #2,ER5	   ;;VF.6 BIG BUG
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.B	  #H'FC,R2L        ;
		MOV.B	  R2L,@ER4	   ;
		INC.L	  #1,ER4	   ;
		MOV.B	  R0L,@ER4	   ;
		INC.L	  #1,ER4	   ;
		MOV.W	  #H'5E00,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		JSR	  @CAL_FUNC_ADDR   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		BSET	  FN_BIT	   ;
		RTS			   ;
;
C_TYPE8:	JSR	  @FUN_DATA_ADDR   ;
		MOV.B	  #H'F1,R2H        ;F102    ER6,ER5->ER4
		MOV.B	  #H'02,R2L        ;          R0,R1
		BLD	  BITN0 	   ;
		BST	  #4,R2L	   ;
		BLD	  BITN1 	   ;
		BST	  #5,R2L	   ;
		BLD	  OPERAND_TYPE	   ;
		BST	  #6,R2L	   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'76F9,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'6721,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.B	  @FN_TYPE,R2L	   ;;V0.A ADD RESET FLAG
		CMP.B	  #D'15,R2L        ;;
		BNE	  C_TYPE8_1:8	   ;;
		MOV.W	  #H'0000,R2       ;;
		BRA	  C_TYPE8_2:8	   ;;
C_TYPE8_1:	MOV.W	  #H'4410,R2       ;
C_TYPE8_2:	MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7369,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'460C,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7902,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  @SECOND_WORD,R2  ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7903,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  @THIRD_WORD,R2   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'5E00,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		JSR	  @CAL_FUNC_ADDR   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		BSET	  FN_BIT	   ;
		RTS			   ;
;
C_TYPE9:	JSR	  @FUN_DATA_ADDR   ;
		MOV.B	  #H'F1,R2H        ;F102    ER6,ER5->ER4
		MOV.B	  #H'02,R2L        ;          R0,R1
		BLD	  BITN0 	   ;
		BST	  #4,R2L	   ;
		BLD	  BITN1 	   ;
		BST	  #5,R2L	   ;
		BLD	  OPERAND_TYPE	   ;
		BST	  #6,R2L	   ;
		BLD	  SCLK		   ;
		BST	  #7,R2L	   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'76F9,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'6721,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7691,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'6731,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7721,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'6711,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7902,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  @SECOND_WORD,R2  ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7903,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  @THIRD_WORD,R2   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7904,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  @FOURTH_WORD,R2  ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'5E00,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		JSR	  @CAL_FUNC_ADDR   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7721,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		BSET	  FN_BIT	   ;
		RTS			   ;
;
C_TYPE10:	JSR	  @FUN_DATA_ADDR   ;
		MOV.B	  #H'F1,R2H        ;F102    ER6,ER5->ER4
		MOV.B	  #H'02,R2L        ;          R0,R1
		BLD	  BITN0 	   ;
		BST	  #4,R2L	   ;
		BLD	  BITN1 	   ;
		BST	  #5,R2L	   ;
		BLD	  OPERAND_TYPE	   ;
		BST	  #6,R2L	   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'76F9,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'6721,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'4418,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7369,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'4614,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7349,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'4610,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7902,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  @SECOND_WORD,R2  ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7903,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  @THIRD_WORD,R2   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7904,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  @FOURTH_WORD,R2  ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'5E00,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		JSR	  @CAL_FUNC_ADDR   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		BSET	  FN_BIT	   ;
		RTS			   ;
;
C_TYPE10_1:	JSR	  @FUN_DATA_ADDR   ;
		MOV.B	  #H'F1,R2H        ;F102    ER6,ER5->ER4
		MOV.B	  #H'02,R2L        ;          R0,R1
		BLD	  BITN0 	   ;
		BST	  #4,R2L	   ;
		BLD	  BITN1 	   ;
		BST	  #5,R2L	   ;
		BLD	  OPERAND_TYPE	   ;
		BST	  #6,R2L	   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'76F9,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'6721,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.B	  @FN_TYPE,R2L	   ;; V0.A ADD RESET FLAG
		CMP.B	  #D'52,R2L        ;;
		BNE	  C_TYPE10_1_1:8   ;;
		MOV.W	  #H'0000,R2       ;;
		BRA	  C_TYPE10_1_2:8   ;;
C_TYPE10_1_1:	MOV.W	  #H'4418,R2       ;
C_TYPE10_1_2:	MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7369,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'4614,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7349,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'4610,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7902,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  @SECOND_WORD,R2  ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7903,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		PUSH.L	  ER6		   ;;
		PUSH.L	  ER5		   ;;
		SUB.L	  #4,ER6	   ;;
		SUB.L	  #2,ER5	   ;;
		MOV.W	  @ER6,R0	   ;;
		MOV.B	  @ER5,R1L	   ;;
		JSR	  @FUN_RELAY_ADDR  ;;
		POP.L	  ER5		   ;;
		POP.L	  ER6		   ;;
		MOV.W	  @SECOND_WORD,R2  ;;;;CHANGE TO RELAY ADDRESS
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7904,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		PUSH.L	  ER6		   ;;
		PUSH.L	  ER5		   ;;
		SUB.L	  #2,ER6	   ;;
		SUB.L	  #1,ER5	   ;;
		MOV.W	  @ER6,R0	   ;;
		MOV.B	  @ER5,R1L	   ;;
		JSR	  @FUN_RELAY_ADDR  ;;
		POP.L	  ER5		   ;;
		POP.L	  ER6		   ;;
		MOV.W	  @SECOND_WORD,R2  ;;;;CHANGE TO RELAY ADDRESS
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'5E00,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		JSR	  @CAL_FUNC_ADDR   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		BSET	  FN_BIT	   ;
		RTS			   ;
;
C_TYPE11:	JSR	  @FUN_DATA_ADDR   ;
C_TYPE110:	PUSH.W	  R1		    ;;V0.C
		MOV.W	  @SECOND_WORD,R2   ;;
		SUB.W	  #V_MEMORY_ADDR1,R2 ;
		SHLR.W	  R2		    ;;
		MOV.B	  #0,R1L	    ;;
		SHLR.W	  R2		    ;
		BST	  #0,R1L	    ;
		SHLR.W	  R2		    ;
		BST	  #1,R1L	    ;
		SHLR.W	  R2		    ;
		BST	  #2,R1L	    ;
		ADD.W	  #H'F220,R2        ;
		MOV.W	  #H'000F,E2        ;
		BTST	  R1L,@ER2	    ;
		BNE	  F16_ALREADY_USED:8 ;
		BSET	  R1L,@ER2	    ;
		POP.W	  R1		    ;
		BRA	  C_TYPE11_GO:8     ;
F16_ALREADY_USED: POP.W   R1		    ;
		MOV.W	  @WS021_ADDR,R1    ;
		CMP.W	  #H'0001,R1        ;
		BEQ	  C_TYPE11_GO:8     ;
		DEC.W	  #2,R6 	    ;
		BRA	  DOUBLS_T_C_ERR    ;;
C_TYPE11_GO:	MOV.B	  #H'F1,R2H        ;F102    ER6,ER5->ER4
		MOV.B	  #H'02,R2L        ;          R0,R1
		BLD	  BITN0 	   ;
		BST	  #4,R2L	   ;
		BLD	  BITN1 	   ;
		BST	  #5,R2L	   ;
		BLD	  OPERAND_TYPE	   ;
		BST	  #6,R2L	   ;
		BLD	  SCLK		   ;
		BCC	  C_TYPE11_1:8	   ;
		MOV.B	  @SCLK_STR,R2H    ;
		CMP.B	  #1,R2H	   ;
		BNE	  PROG_CHK_ERR	   ;
		BSET	  #7,R2L	   ;
		BRA	  C_TYPE11_2:8	   ;
C_TYPE11_1:	BCLR	  #7,R2L	   ;
C_TYPE11_2:	MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'76F9,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'6721,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7778,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'76F9,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'6701,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7902,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  @SECOND_WORD,R2  ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7903,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  @THIRD_WORD,R2   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'5E00,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		JSR	  @CAL_FUNC_ADDR   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		BSET	  FN_BIT	   ;
		RTS			   ;
;
C_TYPE12:	JSR	  @FUN_DATA_ADDR   ;
		MOV.B	  #H'F1,R2H        ;F102    ER6,ER5->ER4
		MOV.B	  #H'02,R2L        ;          R0,R1
		BLD	  BITN0 	   ;
		BST	  #4,R2L	   ;
		BLD	  BITN1 	   ;
		BST	  #5,R2L	   ;
		BLD	  OPERAND_TYPE	   ;
		BST	  #6,R2L	   ;
		BLD	  SCLK		   ;
		BCC	  C_TYPE12_1:8	   ;
		MOV.B	  @SCLK_STR,R2H    ;
		CMP.B	  #1,R2H	   ;
		BNE	  PROG_CHK_ERR	   ;
		BSET	  #7,R2L	   ;
		BRA	  C_TYPE12_2:8	   ;
C_TYPE12_1:	BCLR	  #7,R2L	   ;
C_TYPE12_2:	MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'76F9,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'6721,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7902,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  @SECOND_WORD,R2  ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'5E00,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		JSR	  @CAL_FUNC_ADDR   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'0000,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		BSET	  FN_BIT	   ;
		RTS			   ;
;
C_TYPE13:	JSR	  @FUN_DATA_ADDR   ;
C_TYPE130:	PUSH.W	  R1		    ;;V0.C
		MOV.W	  @THIRD_WORD,R2    ;;
		SUB.W	  #V_MEMORY_ADDR1,R2 ;
		SHLR.W	  R2		    ;;
		MOV.B	  #0,R1L	    ;;
		SHLR.W	  R2		    ;
		BST	  #0,R1L	    ;
		SHLR.W	  R2		    ;
		BST	  #1,R1L	    ;
		SHLR.W	  R2		    ;
		BST	  #2,R1L	    ;
		ADD.W	  #H'F220,R2        ;
		MOV.W	  #H'000F,E2        ;
		BTST	  R1L,@ER2	    ;
		BNE	  F50_ALREADY_USED:8 ;
		BSET	  R1L,@ER2	    ;
		POP.W	  R1		    ;
		BRA	  C_TYPE13_GO:8     ;
F50_ALREADY_USED: POP.W   R1		    ;
		MOV.W	  @WS021_ADDR,R1    ;
		CMP.W	  #H'0001,R1        ;
		BEQ	  C_TYPE13_GO:8     ;
		DEC.W	  #2,R6 	    ;
		DEC.W	  #2,R6 	    ;
		BRA	  DOUBLS_T_C_ERR    ;;
C_TYPE13_GO:	MOV.B	  #H'F1,R2H        ;F102    ER6,ER5->ER4
		MOV.B	  #H'02,R2L        ;          R0,R1
		BLD	  BITN0 	   ;
		BST	  #4,R2L	   ;
		BLD	  BITN1 	   ;
		BST	  #5,R2L	   ;
		BLD	  OPERAND_TYPE	   ;
		BST	  #6,R2L	   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		PUSH.L	  ER6		   ;
		PUSH.L	  ER5		   ;
		PUSH.W	  R4		   ;
		SUB.L	  #6,ER6	   ;
		SUB.L	  #3,ER5	   ;
		JSR	  @FUN_RELAY_ADDR  ;
;;R2H: R10, R9,  R8,  T1, T0, B2, B1, B0   ;
;;R2L: R7 , R6,  R5,  R4, R3, R2, R1, R0   ;
		MOV.W	  @SECOND_WORD,R2  ;
		MOV.B	  R2H,R4L	   ;
		MOV.B	  R2H,R4H	   ;
		AND.B	  #B'00000111,R4H  ;;R4H byte number
		MOV.B	  R4H,@R4_BUFFER   ;
		ROTL.B	  R2H		   ;
		ROTL.B	  R2H		   ;
		ROTL.B	  R2H		   ;
		AND.B	  #B'00000111,R2H  ;;R2 byte address
		AND.B	  #B'00011000,R4L  ;
F50_Y:		CMP.B	  #B'00001000,R4L  ;
		BNE	  F50_C:8	   ;
		MOV.L	  #Y_STATE,ER5	   ;
		BRA	  F50_M:8	   ;
F50_C:		MOV.L	  #C_STATE,ER5	   ;
F50_M:		ADD.W	  R2,R5 	   ;
		MOV.W	  R5,@SECOND_WORD  ;
		POP.W	  R4		   ;
		POP.L	  ER5		   ;
		POP.L	  ER6		   ;
C_TYPE13_1:	MOV.W	  #H'76F9,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'6721,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7369,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'4616,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7349,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'4612,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.B	  #H'FD,R2L        ;
		MOV.B	  R2L,@ER4	   ;
		INC.L	  #1,ER4	   ;
		MOV.B	  @R4_BUFFER,R2L   ;
		MOV.B	  R2L,@ER4	   ;
		INC.L	  #1,ER4	   ;
		MOV.W	  #H'7902,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  @SECOND_WORD,R2  ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7903,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  @THIRD_WORD,R2   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7904,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  @FOURTH_WORD,R2  ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'5E00,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		JSR	  @CAL_FUNC_ADDR   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		BSET	  FN_BIT	   ;
		RTS			   ;
;;;
C_TYPE15:	JSR	  @FUN_DATA_ADDR   ;
		MOV.B	  #H'F1,R2H        ;F102    ER6,ER5->ER4
		MOV.B	  #H'02,R2L        ;          R0,R1
		BLD	  BITN0 	   ;
		BST	  #4,R2L	   ;
		BLD	  BITN1 	   ;
		BST	  #5,R2L	   ;
		BLD	  OPERAND_TYPE	   ;
		BST	  #6,R2L	   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'6721,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7369,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'4618,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7349,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'4614,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'76F9,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.B	  @FN_TYPE,R2L	   ;;V0.A
		CMP.B	  #D'55,R2L        ;;
		BNE	  C_TYPE15_1:8	   ;;
		MOV.W	  #H'6721,R2       ;;
		BRA	  C_TYPE15_2:8	   ;;
C_TYPE15_1:	MOV.W	  #H'4410,R2       ;
C_TYPE15_2:	MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7902,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  @SECOND_WORD,R2  ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7903,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  @THIRD_WORD,R2   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7904,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  @FOURTH_WORD,R2  ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'5E00,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		JSR	  @CAL_FUNC_ADDR   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		BSET	  FN_BIT	   ;
		RTS			   ;
;;;;
C_TYPE16:	JSR	  @FUN_DATA_ADDR   ;
		MOV.B	  #H'F1,R2H        ;F102    ER6,ER5->ER4
		MOV.B	  #H'02,R2L        ;          R0,R1
		BLD	  BITN0 	   ;
		BST	  #4,R2L	   ;
		BLD	  BITN1 	   ;
		BST	  #5,R2L	   ;
		BLD	  OPERAND_TYPE	   ;
		BST	  #6,R2L	   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'6721,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7369,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'4618,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7349,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'4614,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'76F9,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'4410,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7902,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		PUSH.L	  ER6		   ;
		PUSH.L	  ER5		   ;
		PUSH.W	  R4		   ;
		SUB.L	  #6,ER6	   ;
		SUB.L	  #3,ER5	   ;
		JSR	  @FUN_RELAY_ADDR  ;
;;R2H: R10, R9,  R8,  T1, T0, B2, B1, B0   ;
;;R2L: R7 , R6,  R5,  R4, R3, R2, R1, R0   ;
		MOV.W	  @SECOND_WORD,R2  ;
		MOV.B	  R2H,R4L	   ;
		MOV.B	  R2H,R4H	   ;
		AND.B	  #B'00000111,R4H  ;;R4H byte number
		MOV.B	  R4H,@R4_BUFFER   ;
		ROTL.B	  R2H		   ;
		ROTL.B	  R2H		   ;
		ROTL.B	  R2H		   ;
		AND.B	  #B'00000111,R2H  ;;R2 byte address
		AND.B	  #B'00011000,R4L  ;
F60_Y:		CMP.B	  #B'00001000,R4L  ;
		BNE	  F60_C:8	   ;
		MOV.L	  #Y_STATE,ER5	   ;
		BRA	  F60_M:8	   ;
F60_C:		MOV.L	  #C_STATE,ER5	   ;
F60_M:		ADD.W	  R2,R5 	   ;
		MOV.W	  R5,@SECOND_WORD  ;
		POP.W	  R4		   ;
		POP.L	  ER5		   ;
		POP.L	  ER6		   ;
		MOV.W	  @SECOND_WORD,R2  ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7903,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.B	  @R4_BUFFER,R2L   ;
		MOV.B	  #0,R2H	   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'7904,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		PUSH.L	  ER6		   ;
		PUSH.L	  ER5		   ;
		SUB.L	  #1,ER6	   ;
		MOV.B	  @ER6,R0L	   ;
		SUB.L	  #2,ER6	   ;
		MOV.B	  @ER6,R0H	   ;
		POP.L	  ER5		   ;
		POP.L	  ER6		   ;
		MOV.W	  R0,@ER4	   ;
		INC.L	  #2,ER4	   ;
		MOV.W	  #H'5E00,R2       ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		JSR	  @CAL_FUNC_ADDR   ;
		MOV.W	  R2,@ER4	   ;
		INC.L	  #2,ER4	   ;
		BSET	  FN_BIT	   ;
		RTS			   ;
;
CAL_FUNC_ADDR:	MOV.L	  #SOLVER_TABLE,ER3
		MOV.B	  @FN_TYPE,R2L
		MOV.B	  #H'00,R2H
		SHLL.W	  R2
		ADD.W	  R2,R3
		MOV.W	  @ER3,R2
		RTS
;
SOLVER_TABLE   .DATA.W	 F00_SUB
	       .DATA.W	 F01_SUB
	       .DATA.W	 F02_SUB
	       .DATA.W	 F03_SUB
	       .DATA.W	 F04_SUB
	       .DATA.W	 F05_SUB
	       .DATA.W	 F06_SUB
	       .DATA.W	 F07_SUB
	       .DATA.W	 F08_SUB
	       .DATA.W	 F09_SUB
	       .DATA.W	 F10_SUB
	       .DATA.W	 F11_SUB
	       .DATA.W	 F12_SUB
	       .DATA.W	 F13_SUB
	       .DATA.W	 F14_SUB
	       .DATA.W	 F15_SUB
	       .DATA.W	 F16_SUB
	       .DATA.W	 F17_SUB
	       .DATA.W	 F18_SUB
	       .DATA.W	 F19_SUB
	       .DATA.W	 F20_SUB
	       .DATA.W	 F21_SUB
	       .DATA.W	 F22_SUB
	       .DATA.W	 F23_SUB
	       .DATA.W	 F24_SUB
	       .DATA.W	 F25_SUB
	       .DATA.W	 F26_SUB
	       .DATA.W	 F27_SUB
	       .DATA.W	 F28_SUB
	       .DATA.W	 F29_SUB
	       .DATA.W	 F30_SUB
	       .DATA.W	 F31_SUB
	       .DATA.W	 F32_SUB
	       .DATA.W	 F33_SUB_THREE
	       .DATA.W	 F34_SUB
	       .DATA.W	 F33_SUB_TWO  ;NOP
	       .DATA.W	 F36_SUB      ;NOP
	       .DATA.W	 F37_SUB      ;NOP
	       .DATA.W	 F38_SUB      ;NOP
	       .DATA.W	 F39_SUB
	       .DATA.W	 F40_SUB
	       .DATA.W	 F41_SUB      ;NOP
	       .DATA.W	 F42_SUB
	       .DATA.W	 F43_SUB
	       .DATA.W	 F44_SUB
	       .DATA.W	 F45_SUB
	       .DATA.W	 F46_SUB
	       .DATA.W	 F47_SUB
	       .DATA.W	 F48_SUB
	       .DATA.W	 F49_SUB
	       .DATA.W	 F50_SUB
	       .DATA.W	 F51_SUB
	       .DATA.W	 F52_SUB
	       .DATA.W	 F53_SUB
	       .DATA.W	 F54_SUB
	       .DATA.W	 F55_SUB
	       .DATA.W	 F56_SUB
	       .DATA.W	 F57_SUB
	       .DATA.W	 F58_SUB
	       .DATA.W	 F59_SUB
	       .DATA.W	 F60_SUB
	       .DATA.W	 F61_SUB
	       .DATA.W	 F62_SUB
	       .DATA.W	 F63_SUB
	       .DATA.W	 F64_SUB ;V1.61
	       .DATA.W	 F65_SUB ;V1.61
	       .DATA.W	 F66_SUB ;V1.61
	       .DATA.W	 F67_SUB ;V1.61
;;;;;;;
INIT_LABEL:    MOV.W	 #END_ADDR,R0	     ;;VF.3
	       MOV.W	 #D'128,R1
	       MOV.L	 #LABEL_INST_ADDR,ER3
INIT_LAB_LP:   MOV.W	 R0,@ER3
	       INC.L	 #2,ER3
	       DEC.W	 #1,R1
	       BNE	 INIT_LAB_LP:8
INIT_USED_TAB: MOV.B	 #H'00,R0L               ;;V0.C
	       MOV.W	 #D'352,R1               ;
	       MOV.L	 #Y_USED_TABLE,ER3	 ;
INIT_USED_LP:  MOV.B	 R0L,@ER3		 ;
	       INC.L	 #1,ER3 		 ;
	       DEC.W	 #1,R1			 ;
	       BNE	 INIT_USED_LP:8 	 ;
	       RTS				 ;
;******************************************************************************
;*  1 byte HEX code ----> 1 byte BCD code     (Max 63H	---> 99D)	      *
;******************************************************************************
;*   ÚÄÄÂÄÄ¿	    ÚÄÄÂÄÄ¿						      *
;*   ³R4L  ³ =====> ³R4L  ³						      *
;*   ÀÄÄÁÄÄÙ	    ÀÄÄÁÄÄÙ						      *
;* (HEX CODE)	    (BCD CODE)						      *
;******************************************************************************
HEX_BCD_B:	PUSH.W	 R5
		MOV.B	 #8,R5L
		MOV.B	 #0,R4H
HEX_BCD_B_GO:	SHAL.B	 R4L
		ADDX.B	 R4H,R4H
		DAA	 R4H
		DEC.B	 R5L
		BNE	 HEX_BCD_B_GO:8
		MOV.B	 R4H,R4L
		POP.W	 R5
		RTS
;******************************************************************************
;*  1 word HEX code ----> 1 word BCD code     (Max 270F ---> 9999	      *
;******************************************************************************
;*   ÚÄÄÂÄÄ¿	    ÚÄÄÂÄÄ¿						      *
;*   ³ R4  ³ =====> ³ R4  ³						      *
;*   ÀÄÄÁÄÄÙ	    ÀÄÄÁÄÄÙ						      *
;*    Hi Lo	     Hi Lo						      *
;* (HEX CODE)	    (BCD CODE)						      *
;******************************************************************************
HEX_BCD_W:	PUSH.W	 R5
		PUSH.W	 R6
		MOV.B	 #16,R5L
		MOV.W	 #0,R6
HEX_BCD_W_GO:	SHAL.W	 R4
		ADDX.B	 R6L,R6L
		DAA	 R6L
		ADDX.B	 R6H,R6H
		DAA	 R6H
		DEC.B	 R5L
		BNE	 HEX_BCD_W_GO:8
		MOV.W	 R6,R4
		POP.W	 R6
		POP.W	 R5
		RTS
;******************************************************************************
;*1 double word HEX code -> 1 double word BCD code (Max 5F5E0FF -> 99999999)  *
;******************************************************************************
;*   ÚÄÄÂÄÄÂÄÄÂÄÄ¿	  ÚÄÄÂÄÄÂÄÄÂÄÄ¿ 				      *
;*   ³	E4 ³  R4 ³ =====> ³  E4 ³  R4 ³     V0.B NEW ADDED		      *
;*   ÀÄÄÁÄÄÁÄÄÁÄÄÙ	  ÀÄÄÁÄÄÁÄÄÁÄÄÙ 				      *
;*    Hi Lo Hi Lo	   Hi Lo Hi Lo					      *
;*    (HEX CODE)	   (BCD CODE)					      *
;******************************************************************************
HEX_BCD_D:	PUSH.L	 ER5
		PUSH.L	 ER6
		PUSH.W	 R3
		MOV.B	 #32,R5L
		MOV.W	 #0,R6
		MOV.W	 #0,R3
HEX_BCD_D_GO:	SHAL.L	 ER4
		ADDX.B	 R6L,R6L
		DAA	 R6L
		ADDX.B	 R6H,R6H
		DAA	 R6H
		ADDX.B	 R3L,R3L
		DAA	 R3L
		ADDX.B	 R3H,R3H
		DAA	 R3H
		DEC.B	 R5L
		BNE	 HEX_BCD_D_GO:8
		MOV.W	 R6,R4
		MOV.W	 R3,E4
		POP.W	 R3
		POP.L	 ER6
		POP.L	 ER5
		RTS
;******************************************************************************
;*  1 byte BCD code ----> 1 byte HEX code     (Max 99 ---> FF)		      *
;******************************************************************************
;*   ÚÄÄÂÄÄ¿	    ÚÄÄÂÄÄ¿						      *
;*   ³ R4L ³ =====> ³ R4L ³						      *
;*   ÀÄÄÁÄÄÙ	    ÀÄÄÁÄÄÙ						      *
;*    Hi Lo	     Hi Lo						      *
;* (BCD CODE)	   (HEX CODE)						      *
;******************************************************************************
BCD_HEX_B:	PUSH.W	 R5
		MOV.B	 R4L,R5H
		AND.B	 #H'0F,R5H
		CMP.B	 #H'0A,R5H
		BCC	 BCD_HEX_ERR:8
		MOV.B	 R4L,R5H
		AND.B	 #H'F0,R5H
		CMP.B	 #H'A0,R5H
		BCC	 BCD_HEX_ERR:8
		MOV.B	 R4L,R5H
		AND.B	 #H'0F,R5H
		AND.B	 #H'F0,R4L
		ROTR.B	 R4L
		ROTR.B	 R4L
		ROTR.B	 R4L
		ROTR.B	 R4L
		MOV.B	 #H'A,R5L
		MULXU.B  R5L,R4
		ADD.B	 R5H,R4L
		BCLR	 JUDGE_NG
		POP.W	 R5
		RTS
BCD_HEX_ERR:	BSET	 JUDGE_NG
		POP.W	 R5
		RTS
;******************************************************************************
;*  1 word BCD code ----> 1 word HEX code     (Max 9999 ---> FFFF)	      *
;******************************************************************************
;*   ÚÄÄÂÄÄ¿	    ÚÄÄÂÄÄ¿	   R4HH,R4HL,R4LH,R4LL			      *
;*   ³ R4  ³ =====> ³ R4  ³	   xAAA xAA    xA			      *
;*   ÀÄÄÁÄÄÙ	    ÀÄÄÁÄÄÙ						      *
;*    Hi Lo	     Hi Lo						      *
;* (BCD CODE)	   (HEX CODE)						      *
;******************************************************************************
BCD_HEX_W:	PUSH.L	 ER5
		PUSH.L	 ER6
		MOV.W	 R4,R5
		AND.B	 #H'0F,R5H
		CMP.B	 #H'0A,R5H
		BCC	 BCD_HEX_WERR:8 	 ;V0.B
		MOV.B	 R4H,R5H
		AND.B	 #H'F0,R5H
		CMP.B	 #H'A0,R5H
		BCC	 BCD_HEX_WERR:8 	 ;V0.B
		AND.B	 #H'0F,R5L
		CMP.B	 #H'0A,R5L
		BCC	 BCD_HEX_WERR:8 	 ;V0.B
		MOV.B	 R4L,R5L
		AND.B	 #H'F0,R5L
		CMP.B	 #H'A0,R5L
		BCC	 BCD_HEX_WERR:8 	 ;V0.B
		MOV.W	 R4,R5
		MOV.W	 R5,E5
		AND.W	 #H'000F,R4              ;1
		AND.B	 #H'F0,R5L
		ROTR.B	 R5L
		ROTR.B	 R5L
		ROTR.B	 R5L
		ROTR.B	 R5L
		MOV.W	 #H'A,R6
		MULXU.B  R5L,R6
		ADD.W	 R6,R4			 ;2
		MOV.B	 R5H,R5L
		AND.W	 #H'000F,R5
		MOV.L	 #H'64,ER6
		MULXU.W  R5,ER6
		ADD.W	 R6,R4
		MOV.W	 E5,R5
		MOV.B	 R5H,R5L
		ROTR.B	 R5L
		ROTR.B	 R5L
		ROTR.B	 R5L
		ROTR.B	 R5L
		AND.W	 #H'000F,R5
		MOV.L	 #H'3E8,ER6
		MULXU.W  R5,ER6
		ADD.W	 R6,R4
		BCLR	 JUDGE_NG
		POP.L	 ER6
		POP.L	 ER5
		RTS
BCD_HEX_WERR:	BSET	 JUDGE_NG		 ;;V0.B
		POP.L	 ER6
		POP.L	 ER5
		RTS
;******************************************************************************
;*  2 word BCD code ----> 2 word HEX code     (Max 99999999 ->05F5E0FF)       *
;******************************************************************************
;*   Use : AX,BX,R3,R4			    R2H R3H			      *
;*   ÚÄÄÂÄÄÂÄÄÂÄÄ¿     ÚÄÄÂÄÄÂÄÄÂÄÄ¿	     ³	³			      *
;*   ³ E4  ³ R4  ³ ===>³  E4 ³	R4 ³	     99 99 99 99		      *
;*   ÀÄÄÁÄÄÁÄÄÁÄÄÙ     ÀÄÄÁÄÄÁÄÄÁÄÄÙ	      ³  ³ ÀÄÂÄÙ		      *
;*    99 99 99 99  ---> 05 F5 E0 FF	     R2L R3L ÀÄÄÄÄBCD_HEX_START DO IT *
;*	BCD CODE	  HEX CODE					      *
;******************************************************************************
BCD_HEX_D:	.EQU		$
		JSR	 @BCD_HEX_W		 ;R4
		BLD	 JUDGE_NG
		BCS	 BCD_HEX_DERR		 ;
		MOV.W	 R4,@R4_BUFFER		 ;Low words
		MOV.W	 E4,R4
		MOV.W	 R4,R5
		AND.B	 #H'0F,R5H
		CMP.B	 #H'0A,R5H
		BCC	 BCD_HEX_DERR		 ;V0.B
		MOV.B	 R4H,R5H
		AND.B	 #H'F0,R5H
		CMP.B	 #H'A0,R5H
		BCC	 BCD_HEX_DERR		 ;V0.B
		AND.B	 #H'0F,R5L
		CMP.B	 #H'0A,R5L
		BCC	 BCD_HEX_DERR		 ;V0.B
		MOV.B	 R4L,R5L
		AND.B	 #H'F0,R5L
		CMP.B	 #H'A0,R5L
		BCC	 BCD_HEX_DERR		 ;V0.B
		PUSH.W	 R2
		PUSH.W	 R3
		PUSH.L	 ER5
		PUSH.L	 ER6
		MOV.L	 #0,ER6
		MOV.W	 E4,R5
		AND.W	 #H'0F0F,R5
		MOV.B	 R5L,R3L
		MOV.B	 R5H,R2L
		MOV.W	 E4,R5
		AND.W	 #H'F0F0,R5
		SHLR.W	 R5
		SHLR.W	 R5
		SHLR.W	 R5
		SHLR.W	 R5
		MOV.B	 R5L,R3H
		MOV.B	 R5H,R2H
X_2710: 	CMP.B	 #0,R3L
		BEQ	 X_186A0:8
		MOV.L	 #H'2710,ER5
		ADD.L	 ER5,ER6
		DEC.B	 R3L
		BRA	 X_2710:8
X_186A0:	CMP.B	 #0,R3H
		BEQ	 X_F4240:8
		MOV.L	 #H'186A0,ER5
		ADD.L	 ER5,ER6
		DEC.B	 R3H
		BRA	 X_186A0:8
X_F4240:	CMP.B	 #0,R2L
		BEQ	 X_989680:8
		MOV.L	 #H'F4240,ER5
		ADD.L	 ER5,ER6
		DEC.B	 R2L
		BRA	 X_F4240:8
X_989680:	CMP.B	 #0,R2H
		BEQ	 RET_BCD32:8
		MOV.L	 #H'989680,ER5
		ADD.L	 ER5,ER6
		DEC.B	 R2H
		BRA	 X_989680:8
RET_BCD32:	MOV.L	 ER6,ER4
		MOV.W	 @R4_BUFFER,R6
		MOV.W	 #0,E6
		ADD.L	 ER6,ER4
		POP.L	 ER6
		POP.L	 ER5
		POP.W	 R3
		POP.W	 R2
		BCLR	 JUDGE_NG
		RTS
BCD_HEX_DERR:	BSET	 JUDGE_NG
		RTS
;
FLAG_ZERO:	MOV.L		#SC041_ADDR,ER6
		MOV.B		@ER6,R5L
		AND.B		#B'11110000,R5L
		OR.B		#B'00000100,R5L   ;;V0.B 00000101->00000100
		MOV.B		R5L,@ER6
		RTS
;
;**************** FLAG_NON_CARRY0, clear SC41-SC44 to 0  *******************
FLAG_NON_CARRY0:  MOV.L 	  #SC041_ADDR,ER6   ;V1.61 start
		  MOV.B 	  @ER6,R5L	    ;
		  AND.B 	  #B'11110000,R5L   ;
		  OR.B		  #B'00000000,R5L   ;
		  MOV.B 	  R5L,@ER6	    ;
		  RTS				    ;V1.61 end
FLAG_NON_CARRY: MOV.L		#SC041_ADDR,ER6
		MOV.B		@ER6,R5L
		AND.B		#B'11110000,R5L
		OR.B		#B'00000001,R5L
		MOV.B		R5L,@ER6
		RTS
;
FLAG_CARRY:	MOV.L		#SC041_ADDR,ER6
		MOV.B		@ER6,R5L
		AND.B		#B'11110000,R5L
		OR.B		#B'00000010,R5L
		MOV.B		R5L,@ER6
		RTS
;;
FLAG_ERROR:	MOV.L		#SC041_ADDR,ER6
		MOV.B		@ER6,R5L
		AND.B		#B'11110000,R5L
		OR.B		#B'00001000,R5L
		MOV.B		R5L,@ER6
		RTS
;;;
FLAG_RESET:	MOV.L		#SC041_ADDR,ER6
		MOV.B		@ER6,R5L
		AND.B		#B'11110000,R5L
		MOV.B		R5L,@ER6
		RTS
;;
BIT_S_R:       .EQU	 $
F50_BIT1_J:    BTST	 R5L,@ER2	   ;
	       BEQ	 F50_R1_OFF:8
	       BSET	 F50_BIT1
	       BRA	 F50_BIT2_J:8
F50_R1_OFF:    BCLR	 F50_BIT1
;
F50_BIT2_J:    INC.B	 R5L
	       CMP.B	 #8,R5L
	       BNE	 F50_BIT2_J1:8
	       MOV.B	 #0,R5L
	       INC.W	 #1,R2
F50_BIT2_J1:   BTST	 R5L,@ER2
	       BEQ	 F50_R2_OFF:8
	       BSET	 F50_BIT2
	       BRA	 F50_BIT3_J:8
F50_R2_OFF:    BCLR	 F50_BIT2
;
F50_BIT3_J:    INC.B	 R5L
	       CMP.B	 #8,R5L
	       BNE	 F50_BIT3_J1:8
	       MOV.B	 #0,R5L
	       INC.W	 #1,R2
F50_BIT3_J1:   BTST	 R5L,@ER2
	       BEQ	 F50_R3_OFF:8
	       BSET	 F50_BIT3
	       BRA	 F50_BIT4_J:8
F50_R3_OFF:    BCLR	 F50_BIT3
;
F50_BIT4_J:    INC.B	 R5L
	       CMP.B	 #8,R5L
	       BNE	 F50_BIT4_J1:8
	       MOV.B	 #0,R5L
	       INC.W	 #1,R2
F50_BIT4_J1:   BTST	 R5L,@ER2
	       BEQ	 F50_R4_OFF:8
	       BSET	 F50_BIT4
	       RTS
F50_R4_OFF:    BCLR	 F50_BIT4
BIT_S_RET:     RTS
;;;;
BIT_S_W:       .EQU	 $			 ;
F50_BIT1_REF:  AND.B	 #B'000000111,R5L        ;
	       BLD	 F50_BIT1		 ;
	       BCC	 F50_BIT1_RST:8 	 ;
	       BSET	 R5L,@ER2		 ;
	       BRA	 F50_BIT2_REF:8 	 ;
F50_BIT1_RST:  BCLR	 R5L,@ER2		 ;
F50_BIT2_REF:  INC.B	 R5L			 ;
	       CMP.B	 #8,R5L 		 ;
	       BNE	 F50_BIT2_REF1:8	 ;
	       MOV.B	 #0,R5L 		 ;
	       INC.W	 #1,R2			 ;
F50_BIT2_REF1: BLD	 F50_BIT2		 ;
	       BCC	 F50_BIT2_RST:8 	 ;
	       BSET	 R5L,@ER2		 ;
	       BRA	 F50_BIT3_REF:8 	 ;
F50_BIT2_RST:  BCLR	 R5L,@ER2		 ;
F50_BIT3_REF:  INC.B	 R5L			 ;
	       CMP.B	 #8,R5L 		 ;
	       BNE	 F50_BIT3_REF1:8	 ;
	       MOV.B	 #0,R5L 		 ;
	       INC.W	 #1,R2			 ;
F50_BIT3_REF1: BLD	 F50_BIT3		 ;
	       BCC	 F50_BIT3_RST:8 	 ;
	       BSET	 R5L,@ER2		 ;
	       BRA	 F50_BIT4_REF:8 	 ;
F50_BIT3_RST:  BCLR	 R5L,@ER2		 ;
F50_BIT4_REF:  INC.B	 R5L			 ;
	       CMP.B	 #8,R5L 		 ;
	       BNE	 F50_BIT4_REF1:8	 ;
	       MOV.B	 #0,R5L 		 ;
	       INC.W	 #1,R2			 ;
F50_BIT4_REF1: BLD	 F50_BIT4		 ;
	       BCC	 F50_BIT4_RST:8 	 ;
	       BSET	 R5L,@ER2		 ;
	       RTS				 ;
F50_BIT4_RST:  BCLR	 R5L,@ER2		 ;
	       RTS				 ;
		.END				 ;
