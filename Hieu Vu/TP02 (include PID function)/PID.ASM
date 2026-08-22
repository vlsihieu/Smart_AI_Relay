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
	       
	       