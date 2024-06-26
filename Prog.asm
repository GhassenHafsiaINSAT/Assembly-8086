STACK SEGMENT PARA STACK 
	DB 64 DUP (' ') 			; DB stands for define byte, we fill the stack with 64 spaces .  
STACK ENDS 						; S is for the SEGMENT

DATA SEGMENT PARA 'DATA'

	WINDOW_WIDTH DW 140h
	WINDOW_Height DW 0C8h
	WINDOW_Bounce DW 6 			; variable to check the collision early 
	TIME_AUX DB 0 				; variable used when checking of the time has changed
	GAME_ACTIVE DB 1
	WINNER_INDEX DB 0
	
	TEXT_PLAYER_ONE_POINTS DB '0','$'
	TEXT_PLAYER_TWO_POINTS DB '0','$'
	TEXT_GAME_OVER DB 'GAME OVER', '$'
	TEXT_GAME_WINNER DB 'PLAYER 0 WON', '$'
	TEXT_GAME_OVER_RESTART DB 'press R to restart the game', '$'

	
	BALL_ORIGINAL_X DW 6Eh		; The starting X position of the ball 
	BALL_ORIGINAL_Y DW 64h		; The starting Y position of the ball 
	BALL_X DW 0A0h 				; Current X position of the ball, DW stands for define word 16 bits
	BALL_Y DW 04h 				; Current Y position of the ball 
	BALL_SIZE DW 04h 			; DEFAULT ball size (4 pixels)
	BALL_Velocity_X DW 05h		; DEFAULT ball X velocity 
	BALL_Velocity_Y DW 02h		; DEFAULT ball Y velocity 
	
	PADDLE_LEFT_X DW 0Ah		; Current X position for the left paddle
	PADDLE_LEFT_Y DW 0Ah		; Current Y position for the left paddle
	
	PLAYER_ONE_POINTS DB 0		; Current points of the left player 
	
	PADDLE_RIGHT_X DW 130h		; Current X position for the right paddle
	PADDLE_RIGHT_Y DW 0Ah		; Current Y position for the right paddle
	
	PADDLE_WIDTH DW 05h			; DEFAULT paddle width
	PADDLE_HEIGHT DW 1Fh		; DEFAULT paddle height
	
	PLAYER_TWO_POINTS DB 0		; Current points of the right player 

	
	PADDLE_VELOCITY DW 05h		; DEFAULT paddle velocity

DATA ENDS 

CODE SEGMENT PARA 'CODE' 
	MAIN PROC FAR 					; FAR means that the call is far, it crosses segment boundaries.
	ASSUME CS:CODE,DS:DATA,SS:STACK ; assume as code, data and stack segments the respective registers.  
	PUSH DS 						; push the DS segment to the stack
	SUB AX,AX						; clean the AX register	
	PUSH AX							; push the AX register to the stack 
	MOV AX,DATA						; save on the AX register the content of the DATA segment 
	MOV DS,AX 						; save the DS segment the content of AX register   
	POP AX							; release the top item of the stack to the AX register  
		
		CALL CLEAR_SCREEN
		CHECK_TIME:
			
			CMP GAME_ACTIVE,00h
			JE SHOW_GAME_OVER
			MOV AH,2Ch 			; get the system time 
			INT 21h    			; return: CH=hour, CL=minute, DH=second, DL=1/100 seconds 
			CMP DL,TIME_AUX 
			JE CHECK_TIME
			
			MOV TIME_AUX,DL
			
			CALL CLEAR_SCREEN
			CALL MOVE_BALL
			CALL DRAW_BALL
			CALL MOVE_PADDLES
			CALL DRAW_PADDLES
			CALL DRAW_SCORE_INTERFACE
			
			JMP CHECK_TIME
			
			SHOW_GAME_OVER:
				CALL DRAW_GAME_OVER
				JMP CHECK_TIME
			
		RET 					; RET is the return, the exit of the procedure.  
	MAIN ENDP 					; P is for procedure.  
	
	DRAW_BALL PROC NEAR 		; near is to say it belongs to the same code segment so the main procedure can call it.  
		MOV CX,BALL_X 			; Set the initial column (X).
		MOV DX,BALL_Y 			; set the initial line (Y).
		
		DRAW_BALL_HORIZENTAL: 
			MOV AH,0Ch 			; Set the configuration to writing a pixel.
			MOV AL,0Fh 			; Choose white as color.
			MOV BH,00h 			; Choose the page number.
			INT 10h 			; execute the configuration.
			
			INC CX				; CX = CX + 1, advance to the next column  
			MOV AX,CX  
			SUB AX,BALL_X
			CMP AX,BALL_SIZE
			JNG DRAW_BALL_HORIZENTAL
			
			MOV CX,BALL_X
			INC DX 				; advance to the next line.  
			
			MOV AX,DX 
			SUB AX,BALL_Y
			CMP AX,BALL_SIZE
			JNG DRAW_BALL_HORIZENTAL 	
		RET
	DRAW_BALL ENDP
	
	CLEAR_SCREEN PROC NEAR
		MOV AH,00h 				; Set the configuration to video mode.  
		MOV AL,13h 				; Choose the video mode.    
		INT 10h					; Execute the configuration.

		MOV AH,0Bh 				; Set the configuration 
		MOV BH,00h 				; to the background color.
		MOV BL,00h 				; set black as background color.
		INT 10h 				; Execute the configuration.  
		RET
	CLEAR_SCREEN ENDP
	
	MOVE_BALL PROC NEAR
		
		MOV AX,BALL_Velocity_X
		ADD BALL_X,AX			; move the ball vetically
		
		MOV AX,WINDOW_Bounce
		CMP BALL_X,AX
		JL GIVE_POINTS_TO_PLAYER_TWO
		
		MOV AX,WINDOW_WIDTH
		SUB AX,BALL_SIZE	
		SUB AX,WINDOW_Bounce	
		CMP BALL_X,AX
		JG GIVE_POINTS_TO_PLAYER_ONE
		JMP MOVE_BALL_VERTICALLY 
		
		GIVE_POINTS_TO_PLAYER_ONE: 
			INC PLAYER_ONE_POINTS
			CALL RESET_BALL_POSITION  ; reset ball position in the center of the screen
			CALL UPDATE_TEXTE_PLAYER_ONE
			CMP PLAYER_ONE_POINTS,05h
			JGE GAME_OVER
			RET
			
		GIVE_POINTS_TO_PLAYER_TWO: 
			INC PLAYER_TWO_POINTS
			CALL RESET_BALL_POSITION
			CALL UPDATE_TEXTE_PLAYER_TWO
			CMP PLAYER_TWO_POINTS,05h
			JGE GAME_OVER			
			RET
			
		GAME_OVER:
			CMP PLAYER_ONE_POINTS,05h
			JNL WINNER_IS_PLAYER_ONE
			JMP WINNER_IS_PLAYER_TWO
			
			WINNER_IS_PLAYER_ONE:
				MOV WINNER_INDEX,01h
				JMP CONTINUE_GAME_OVER
			
			WINNER_IS_PLAYER_TWO:
				MOV WINNER_INDEX,02h
				JMP CONTINUE_GAME_OVER	
			
			CONTINUE_GAME_OVER:
				MOV PLAYER_TWO_POINTS,00h
				MOV PLAYER_ONE_POINTS,00h 
				CALL UPDATE_TEXTE_PLAYER_ONE
				CALL UPDATE_TEXTE_PLAYER_TWO
				MOV GAME_ACTIVE,00h
				RET
		
		MOVE_BALL_VERTICALLY:
			MOV AX,BALL_Velocity_Y 
			ADD BALL_Y,AX			; move the ball vetically
		
		MOV AX,WINDOW_Bounce
		CMP BALL_Y,AX
		JL NEG_VELOCITY_Y
		
		MOV AX,WINDOW_Height
		SUB AX,BALL_SIZE	
		SUB AX,WINDOW_Bounce	
		CMP BALL_Y,AX
		JG NEG_VELOCITY_Y
		
		
		
		MOV AX,BALL_X
		ADD AX,BALL_SIZE
		CMP AX,PADDLE_RIGHT_X
		JNG CHECK_COLLISION_WITH_LEFT_PADDLE
		
		MOV AX,PADDLE_RIGHT_X
		ADD AX,PADDLE_WIDTH
		CMP BALL_X,AX
		JNL CHECK_COLLISION_WITH_LEFT_PADDLE
		
		MOV AX,BALL_Y
		ADD AX,BALL_SIZE
		CMP AX,PADDLE_RIGHT_Y
		JNG CHECK_COLLISION_WITH_LEFT_PADDLE
		
		MOV AX,PADDLE_RIGHT_Y
		ADD AX,PADDLE_HEIGHT
		CMP BALL_Y,AX
		JNL CHECK_COLLISION_WITH_LEFT_PADDLE
		
		JMP NEG_Velocity_X
		
		CHECK_COLLISION_WITH_LEFT_PADDLE:
		
		MOV AX,BALL_X
		ADD AX,BALL_SIZE
		CMP AX,PADDLE_LEFT_X
		JNG EXIT_COLLISION_CHECK
			
		MOV AX,PADDLE_LEFT_X
		ADD AX,PADDLE_WIDTH
		CMP BALL_X,AX
		JNL EXIT_COLLISION_CHECK
			
		MOV AX,BALL_Y
		ADD AX,BALL_SIZE
		CMP AX,PADDLE_LEFT_Y
		JNG EXIT_COLLISION_CHECK
			
		MOV AX,PADDLE_LEFT_Y
		ADD AX,PADDLE_HEIGHT
		CMP BALL_Y,AX
		JNL EXIT_COLLISION_CHECK
		
		JMP NEG_VELOCITY_X
		
		NEG_VELOCITY_Y: 
			NEG BALL_Velocity_Y
			RET	
		NEG_VELOCITY_X:
			NEG BALL_Velocity_X 		
			RET
		EXIT_COLLISION_CHECK:
			RET
			
	MOVE_BALL ENDP
	
	UPDATE_TEXTE_PLAYER_ONE PROC NEAR
		SUB AX,AX 
		MOV AL,PLAYER_ONE_POINTS
		
		ADD AL,30h
		MOV [TEXT_PLAYER_ONE_POINTS],AL
		RET
	UPDATE_TEXTE_PLAYER_ONE ENDP
	
	UPDATE_TEXTE_PLAYER_TWO PROC NEAR
		SUB AX,AX 
		MOV AL,PLAYER_TWO_POINTS
		ADD AL,30h
		MOV [TEXT_PLAYER_TWO_POINTS],AL
		RET
	UPDATE_TEXTE_PLAYER_TWO ENDP

	
	RESET_BALL_POSITION PROC NEAR
		MOV AX,BALL_ORIGINAL_X
		MOV BALL_X,AX
		
		MOV AX,BALL_ORIGINAL_Y
		MOV BALL_Y,AX
		RET	
	RESET_BALL_POSITION ENDP 
	
	DRAW_SCORE_INTERFACE PROC NEAR 
		
		MOV AH,02h  	; set cursor position 
		MOV BH,00h		; set page number  
		MOV DH,04h		; set row
		MOV DL,06h		; set column
		INT 10h
		
		MOV AH,09h 						; write string to standard output  
		LEA DX,TEXT_PLAYER_ONE_POINTS   ; give DX a pointer to the string TEXT_PLAYER_ONE_POINTS
		INT 21h 
		
		MOV AH,02h  	; set cursor position 
		MOV BH,00h		; set page number  
		MOV DH,04h		; set row
		MOV DL,1Fh		; set column
		INT 10h
		
		MOV AH,09h 						; write string to standard output  
		LEA DX,TEXT_PLAYER_TWO_POINTS   ; give DX a pointer to the string TEXT_PLAYER_ONE_POINTS
		INT 21h 
		
		RET
	DRAW_SCORE_INTERFACE ENDP
	
	DRAW_PADDLES PROC NEAR 
		MOV CX,PADDLE_LEFT_X
		MOV DX,PADDLE_LEFT_Y
		
		DRAW_PADDLE_LEFT_HORIZENTAL: 
			MOV AH,0Ch 				; set the configuration to writing a pixel.
			MOV AL,0Fh 				; Choose white as color.
			MOV BH,00h 				; choose the page number.
			INT 10h 				; execute the configuration.
			
			INC CX					; CX = CX + 1, advance to the next column  
			MOV AX,CX  
			SUB AX,PADDLE_LEFT_X
			CMP AX,PADDLE_WIDTH
			JNG DRAW_PADDLE_LEFT_HORIZENTAL	
			
			MOV CX,PADDLE_LEFT_X
			INC DX 					; advance to the next line.  
			
			MOV AX,DX 
			SUB AX,PADDLE_LEFT_Y
			CMP AX,PADDLE_HEIGHT
			JNG DRAW_PADDLE_LEFT_HORIZENTAL 	
			
		MOV CX,PADDLE_RIGHT_X
		MOV DX,PADDLE_RIGHT_Y
		
		DRAW_PADDLE_RIGHT_HORIZENTAL: 
			MOV AH,0Ch 				; set the configuration to writing a pixel.
			MOV AL,0Fh 				; Choose white as color.
			MOV BH,00h 				; choose the page number.
			INT 10h 				; execute the configuration.
			
			INC CX					; CX = CX + 1, advance to the next column  
			MOV AX,CX  
			SUB AX,PADDLE_RIGHT_X
			CMP AX,PADDLE_WIDTH
			JNG DRAW_PADDLE_RIGHT_HORIZENTAL	
			
			MOV CX,PADDLE_RIGHT_X
			INC DX 					; advance to the next line.  
			
			MOV AX,DX 
			SUB AX,PADDLE_RIGHT_Y
			CMP AX,PADDLE_HEIGHT
			JNG DRAW_PADDLE_RIGHT_HORIZENTAL			
			
		RET
	DRAW_PADDLES ENDP
	
	DRAW_GAME_OVER PROC NEAR 
		CALL CLEAR_SCREEN
		; shows the menu title 
		MOV AH,02h  	; set cursor position 
		MOV BH,00h		; set page number  
		MOV DH,04h		; set row
		MOV DL,04h		; set column
		INT 10h
		
		MOV AH,09h 						; write string to standard output  
		LEA DX,TEXT_GAME_OVER  ; give DX a pointer to the string TEXT_PLAYER_ONE_POINTS
		INT 21h 
		; shows the winner 
		MOV AH,02h  	; set cursor position 
		MOV BH,00h		; set page number  
		MOV DH,06h		; set row
		MOV DL,04h		; set column
		INT 10h
		
		CALL UPDATE_WINNER_TEXT
		
		MOV AH,09h 						; write string to standard output  
		LEA DX,TEXT_GAME_WINNER  ; give DX a pointer to the string TEXT_PLAYER_ONE_POINTS
		INT 21h 
		
		; show the play again message 
		MOV AH,02h  	; set cursor position 
		MOV BH,00h		; set page number  
		MOV DH,08h		; set row
		MOV DL,04h		; set column
		INT 10h
		
		CALL UPDATE_WINNER_TEXT
		
		MOV AH,09h 						; write string to standard output  
		LEA DX,TEXT_GAME_OVER_RESTART  ; give DX a pointer to the string TEXT_GAME_OVER_RESTART
		INT 21h 
		
		; waits for a key press 
		MOV AH,00h
		INT 16h
		CMP AL,'r'
		JE RESTART_GAME
		
		RET
		
		RESTART_GAME:
			MOV GAME_ACTIVE,01h
			RET
	DRAW_GAME_OVER ENDP
	
	UPDATE_WINNER_TEXT PROC NEAR 
		MOV AL,WINNER_INDEX
		ADD AL,30h
		MOV [TEXT_GAME_WINNER+7],AL
		RET
	UPDATE_WINNER_TEXT ENDP 
	
	MOVE_PADDLES PROC NEAR 
		MOV AH,01h 
		INT 16h
		JE CHECK_RIGHT_PADDLE_MOVEMENT
		
		
		MOV AH,00h
		INT 16h
			
		CMP AL,7Ah 						; 'z' keyword is pressed 
		JE MOVE_LEFT_PADDLE_UP
			
		CMP AL,73h 						; 's' keyword is pressed 
		JE MOVE_LEFT_PADDLE_DOWN
		JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
		MOVE_LEFT_PADDLE_UP:
			MOV AX,PADDLE_VELOCITY
			SUB PADDLE_LEFT_Y,AX
			MOV AX,WINDOW_Bounce
			CMP PADDLE_LEFT_Y,AX
			JL FIX_PADDLE_LEFT_TOP_POSITION
			JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
			FIX_PADDLE_LEFT_TOP_POSITION:
				MOV AX,WINDOW_Bounce
				MOV PADDLE_LEFT_Y,AX
				JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
		MOVE_LEFT_PADDLE_DOWN:
			MOV AX,PADDLE_VELOCITY
			ADD PADDLE_LEFT_Y,AX
			MOV AX,WINDOW_Height
			SUB AX,WINDOW_Bounce
			SUB AX,PADDLE_HEIGHT
			CMP PADDLE_LEFT_Y,AX
			JG FIX_PADDLE_LEFT_BOTTOM_POSITION
			JMP CHECK_RIGHT_PADDLE_MOVEMENT
			FIX_PADDLE_LEFT_BOTTOM_POSITION:
				MOV PADDLE_LEFT_Y,AX
				JMP CHECK_RIGHT_PADDLE_MOVEMENT
		
		CHECK_RIGHT_PADDLE_MOVEMENT:
		
		CMP AL,6Fh 						; 'o' keyword is pressed 
		JE MOVE_RIGHT_PADDLE_UP
			
		CMP AL,6Ch  					; 'l' keyword is pressed 
		JE MOVE_RIGHT_PADDLE_DOWN
		JMP EXIT_PADDLE_MOVEMENT
		
		MOVE_RIGHT_PADDLE_UP: 
			MOV AX,PADDLE_VELOCITY
			SUB PADDLE_RIGHT_Y,AX
		 	MOV AX,WINDOW_Bounce
			CMP PADDLE_RIGHT_Y,AX
			JL FIX_PADDLE_RIGHT_TOP_POSITION
			JMP EXIT_PADDLE_MOVEMENT
				
			FIX_PADDLE_RIGHT_TOP_POSITION:
				MOV PADDLE_RIGHT_Y,AX
				JMP EXIT_PADDLE_MOVEMENT
		
		MOVE_RIGHT_PADDLE_DOWN:
			MOV AX,PADDLE_VELOCITY
			ADD PADDLE_RIGHT_Y,AX
			MOV AX,WINDOW_Height
			SUB AX,WINDOW_Bounce
			SUB AX,PADDLE_HEIGHT
			CMP PADDLE_RIGHT_Y,AX
			JG FIX_PADDLE_RIGHT_BOTTOM_POSITION
			JMP EXIT_PADDLE_MOVEMENT
			
			FIX_PADDLE_RIGHT_BOTTOM_POSITION:
				MOV PADDLE_RIGHT_Y,AX
				JMP EXIT_PADDLE_MOVEMENT
		
		
		EXIT_PADDLE_MOVEMENT:
			RET
		
	MOVE_PADDLES ENDP
	
	
CODE ENDS 
END