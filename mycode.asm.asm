.MODEL SMALL
.STACK 100H

MAX_REC EQU 10       
NAME_LEN EQU 10      

.DATA
    ; --- FILE HANDLING DATA ---
    F_NAME     DB 'record.txt', 0   
    F_HANDLE   DW ?                 
    COMMA      DB ','               
    NEWLINE    DB 0DH, 0AH          
    MSG_SAVE   DB 13,10,'(Auto-Saved to record.txt)$'
    MSG_FERR   DB 13,10,'Error: File creation failed!$'

    ; --- INTERFACE STRINGS ---
    TITLE_MSG DB 13,10,'=== REMOTE AREA RESOURCE MANAGER ===',13,10,'$'
    MENU      DB 13,10,10,'1. Add Record'
              DB 13,10,'2. Update Record'
              DB 13,10,'3. Delete Record'
              DB 13,10,'4. Sort Records'
              DB 13,10,'5. View Data & Totals'
              DB 13,10,'6. Exit'
              DB 13,10,'Select: $'

    SORT_MENU DB 13,10,10,'--- SORT BY ---'
              DB 13,10,'1. Family Members'
              DB 13,10,'2. Water'
              DB 13,10,'3. Flour'
              DB 13,10,'4. Pulse'
              DB 13,10,'Select: $'

 
    HEADER    DB 13,10,10,'Sr  Name     Family mem    Water       Flour       Pulse'
              DB 13,10,'$'
    
    ; --- PROMPTS & ERRORS ---
    P_SR      DB 13,10,'Enter Sr (1-99): $'
    P_NAME    DB 13,10,'Enter Name : $'
    P_FAM     DB 13,10,'Family Members: $'
    P_WAT     DB 13,10,'Water (Liters): $'
    P_FLR     DB 13,10,'Flour (kg): $'
    P_PLS     DB 13,10,'Pulses (kg): $'
    ERR_DUP   DB 13,10,'ERROR: Duplicate Sr# exists!$'
    ERR_FULL  DB 13,10,'ERROR: Database Full!$'
    ERR_NF    DB 13,10,'ERROR: Record not found!$'
    MSG_DEL   DB 13,10,'Record Deleted.$'
    
    ; --- TOTALS LABELS ---
    L_TOT_F   DB 13,10,10,'Total Family: $'
    L_TOT_W   DB '      Total Water: $'
    L_TOT_FL  DB 13,10,'Total Flour:  $'
    L_TOT_P   DB '      Total Pulse: $'

    ; --- DATA ARRAYS ---
    SR_ARR    DB MAX_REC DUP(0)
    NAME_ARR  DB MAX_REC * NAME_LEN DUP(' ')
    FAM_ARR   DB MAX_REC DUP(0)
    WAT_ARR   DB MAX_REC DUP(0)
    FLR_ARR   DB MAX_REC DUP(0)
    PLS_ARR   DB MAX_REC DUP(0)
    
    COUNT     DW 0
    TEMP_VAL  DB 0
    SORT_OPT  DB 0  
    
 
    T_FAM     DW 0
    T_WAT     DW 0
    T_FLR     DW 0
    T_PLS     DW 0

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

START:
    LEA DX, TITLE_MSG
    MOV AH, 09H
    INT 21H
    
    LEA DX, MENU
    MOV AH, 09H
    INT 21H

    MOV AH, 01H
    INT 21H
    
    CMP AL, '1'
    JE DO_ADD
    CMP AL, '2'
    JE DO_UPD
    CMP AL, '3'
    JE DO_DEL
    CMP AL, '4'
    JE DO_SORT
    CMP AL, '5'
    JE DO_VIEW
    CMP AL, '6'
    JE EXIT_APP
    JMP START


DO_ADD:
    MOV BX, COUNT
    CMP BX, MAX_REC
    JAE DB_FULL

    LEA DX, P_SR
    MOV AH, 09H
    INT 21H
    CALL INPUT_NUM
    MOV TEMP_VAL, AL

    CALL CHECK_DUPLICATE
    CMP AX, 1
    JE DUP_MSG_SHOW

    MOV BX, COUNT
    MOV AL, TEMP_VAL
    MOV SR_ARR[BX], AL

    LEA DX, P_NAME
    MOV AH, 09H
    INT 21H
    
    MOV AX, COUNT
    MOV CX, NAME_LEN
    MUL CX
    MOV DI, AX
    CALL INPUT_STRING

    LEA DX, P_FAM
    MOV AH, 09H
    INT 21H
    CALL INPUT_NUM
    MOV BX, COUNT
    MOV FAM_ARR[BX], AL

    LEA DX, P_WAT
    MOV AH, 09H
    INT 21H
    CALL INPUT_NUM
    MOV BX, COUNT
    MOV WAT_ARR[BX], AL

    LEA DX, P_FLR
    MOV AH, 09H
    INT 21H
    CALL INPUT_NUM
    MOV BX, COUNT
    MOV FLR_ARR[BX], AL

    LEA DX, P_PLS
    MOV AH, 09H
    INT 21H
    CALL INPUT_NUM
    MOV BX, COUNT
    MOV PLS_ARR[BX], AL

    INC COUNT
    
 
    CALL SAVE_DATABASE
    JMP START

DUP_MSG_SHOW:
    LEA DX, ERR_DUP
    MOV AH, 09H
    INT 21H
    JMP START

DB_FULL:
    LEA DX, ERR_FULL
    MOV AH, 09H
    INT 21H
    JMP START


DO_UPD:
    LEA DX, P_SR
    MOV AH, 09H
    INT 21H
    CALL INPUT_NUM
    MOV TEMP_VAL, AL
    
    CALL CHECK_DUPLICATE
    CMP AX, 0
    JE REC_NOT_FOUND

    PUSH BX
    LEA DX, P_NAME
    MOV AH, 09H
    INT 21H
    POP BX
    
    PUSH BX
    MOV AX, BX
    MOV CX, NAME_LEN
    MUL CX
    MOV DI, AX
    CALL INPUT_STRING
    POP BX 
    
    LEA DX, P_FAM
    MOV AH, 09H
    INT 21H
    CALL INPUT_NUM
    MOV FAM_ARR[BX], AL 

    LEA DX, P_WAT
    MOV AH, 09H
    INT 21H
    CALL INPUT_NUM
    MOV WAT_ARR[BX], AL

    LEA DX, P_FLR
    MOV AH, 09H
    INT 21H
    CALL INPUT_NUM
    MOV FLR_ARR[BX], AL

    LEA DX, P_PLS
    MOV AH, 09H
    INT 21H
    CALL INPUT_NUM
    MOV PLS_ARR[BX], AL
    
 
    CALL SAVE_DATABASE
    JMP START


DO_DEL:
    LEA DX, P_SR
    MOV AH, 09H
    INT 21H
    CALL INPUT_NUM
    MOV TEMP_VAL, AL
    
    CALL CHECK_DUPLICATE
    CMP AX, 0
    JE REC_NOT_FOUND
    
    MOV SR_ARR[BX], 0
    LEA DX, MSG_DEL
    MOV AH, 09H
    INT 21H
    
    
    CALL SAVE_DATABASE
    JMP START

REC_NOT_FOUND:
    LEA DX, ERR_NF
    MOV AH, 09H
    INT 21H
    JMP START


DO_SORT:
    LEA DX, SORT_MENU
    MOV AH, 09H
    INT 21H
    MOV AH, 01H
    INT 21H
    MOV SORT_OPT, AL
    
    MOV CX, COUNT
    CMP CX, 1
    JBE START 
    DEC CX

OUTER_LOOP:
    PUSH CX
    MOV SI, 0
INNER_LOOP:
    CMP SORT_OPT, '1'
    JE CMP_FAM
    CMP SORT_OPT, '2'
    JE CMP_WAT
    CMP SORT_OPT, '3'
    JE CMP_FLR
    CMP SORT_OPT, '4'
    JE CMP_PLS
    JMP NO_SWAP 

CMP_FAM:
    MOV AL, FAM_ARR[SI]
    CMP AL, FAM_ARR[SI+1]
    JMP CHECK_SWAP
CMP_WAT:
    MOV AL, WAT_ARR[SI]
    CMP AL, WAT_ARR[SI+1]
    JMP CHECK_SWAP
CMP_FLR:
    MOV AL, FLR_ARR[SI]
    CMP AL, FLR_ARR[SI+1]
    JMP CHECK_SWAP
CMP_PLS:
    MOV AL, PLS_ARR[SI]
    CMP AL, PLS_ARR[SI+1]

CHECK_SWAP:
    JBE NO_SWAP          
    CALL SWAP_ALL_ARRAYS
NO_SWAP:
    INC SI
    LOOP INNER_LOOP
    POP CX
    LOOP OUTER_LOOP
    
 
    CALL SAVE_DATABASE
    JMP START


DO_VIEW:
    MOV T_FAM, 0
    MOV T_WAT, 0
    MOV T_FLR, 0
    MOV T_PLS, 0

    LEA DX, HEADER
    MOV AH, 09H
    INT 21H

    MOV SI, 0
    MOV CX, COUNT
    JCXZ VIEW_END

PRINT_LOOP:
    CMP SR_ARR[SI], 0
    JE SKIP_PRINT
    
    MOV DL, 13
    MOV AH, 02H
    INT 21H
    MOV DL, 10
    INT 21H

    MOV AL, SR_ARR[SI]
    XOR AH, AH
    CALL PRINT_NUM
    CALL PRINT_TAB_SMALL 

    CALL PRINT_NAME_AT_SI
    
    MOV AL, FAM_ARR[SI]
    XOR AH, AH
    ADD T_FAM, AX
    CALL PRINT_NUM
    CALL PRINT_TAB       

    MOV AL, WAT_ARR[SI]
    XOR AH, AH
    ADD T_WAT, AX
    CALL PRINT_NUM
    CALL PRINT_TAB       
    
    MOV AL, FLR_ARR[SI]
    XOR AH, AH
    ADD T_FLR, AX
    CALL PRINT_NUM
    CALL PRINT_TAB       

    MOV AL, PLS_ARR[SI]
    XOR AH, AH
    ADD T_PLS, AX
    CALL PRINT_NUM

SKIP_PRINT:
    INC SI
    LOOP PRINT_LOOP

    LEA DX, L_TOT_F
    MOV AH, 09H
    INT 21H
    MOV AX, T_FAM
    CALL PRINT_NUM
    
    LEA DX, L_TOT_W
    MOV AH, 09H
    INT 21H
    MOV AX, T_WAT
    CALL PRINT_NUM

    LEA DX, L_TOT_FL
    MOV AH, 09H
    INT 21H
    MOV AX, T_FLR
    CALL PRINT_NUM

    LEA DX, L_TOT_P
    MOV AH, 09H
    INT 21H
    MOV AX, T_PLS
    CALL PRINT_NUM

VIEW_END:
    JMP START

EXIT_APP:
    MOV AH, 4CH
    INT 21H
MAIN ENDP

SAVE_DATABASE PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    ; Create/Overwrite File
    MOV AH, 3CH
    MOV CX, 0
    LEA DX, F_NAME
    INT 21H
    JC SAVE_ERR_P
    MOV F_HANDLE, AX

    MOV SI, 0
    MOV CX, COUNT
    JCXZ CLOSE_FILE_P
    
SAVE_LOOP_P:
    CMP SR_ARR[SI], 0
    JE SKIP_SAVE_P

   
    MOV AL, SR_ARR[SI]
    XOR AH, AH
    CALL WRITE_NUM_TO_FILE
    CALL WRITE_COMMA
    
    
    CALL WRITE_NAME_TO_FILE
    CALL WRITE_COMMA

   
    MOV AL, FAM_ARR[SI]
    XOR AH, AH
    CALL WRITE_NUM_TO_FILE
    CALL WRITE_COMMA
    
   
    MOV AL, WAT_ARR[SI]
    XOR AH, AH
    CALL WRITE_NUM_TO_FILE
    CALL WRITE_COMMA
    
    
    MOV AL, FLR_ARR[SI]
    XOR AH, AH
    CALL WRITE_NUM_TO_FILE
    CALL WRITE_COMMA

    
    MOV AL, PLS_ARR[SI]
    XOR AH, AH
    CALL WRITE_NUM_TO_FILE
    
    CALL WRITE_NEWLINE

SKIP_SAVE_P:
    INC SI
    LOOP SAVE_LOOP_P

CLOSE_FILE_P:
    MOV AH, 3EH
    MOV BX, F_HANDLE
    INT 21H
    LEA DX, MSG_SAVE
    MOV AH, 09H
    INT 21H
    JMP END_SAVE_P

SAVE_ERR_P:
    LEA DX, MSG_FERR
    MOV AH, 09H
    INT 21H

END_SAVE_P:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SAVE_DATABASE ENDP



SWAP_ALL_ARRAYS PROC
    
    MOV AL, SR_ARR[SI]
    MOV AH, SR_ARR[SI+1]
    MOV SR_ARR[SI+1], AL
    MOV SR_ARR[SI], AH

    
    MOV AL, FAM_ARR[SI]
    MOV AH, FAM_ARR[SI+1]
    MOV FAM_ARR[SI+1], AL
    MOV FAM_ARR[SI], AH

   
    MOV AL, WAT_ARR[SI]
    MOV AH, WAT_ARR[SI+1]
    MOV WAT_ARR[SI+1], AL
    MOV WAT_ARR[SI], AH

    
    MOV AL, FLR_ARR[SI]
    MOV AH, FLR_ARR[SI+1]
    MOV FLR_ARR[SI+1], AL
    MOV FLR_ARR[SI], AH

   
    MOV AL, PLS_ARR[SI]
    MOV AH, PLS_ARR[SI+1]
    MOV PLS_ARR[SI+1], AL
    MOV PLS_ARR[SI], AH

     
    PUSH CX
    PUSH BX
    PUSH DI
    
    MOV AX, SI
    MOV CX, NAME_LEN
    MUL CX
    MOV BX, AX      
    
    MOV DI, BX
    ADD DI, NAME_LEN 
    
    MOV CX, NAME_LEN
SWAP_NM:
    MOV AL, NAME_ARR[BX]
    MOV AH, NAME_ARR[DI]
    MOV NAME_ARR[DI], AL
    MOV NAME_ARR[BX], AH
    INC BX
    INC DI
    LOOP SWAP_NM
    
    POP DI
    POP BX
    POP CX
    RET
SWAP_ALL_ARRAYS ENDP

WRITE_NUM_TO_FILE PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    CMP AX, 0
    JNE W_NZ
    MOV TEMP_VAL, '0'
    MOV AH, 40H
    MOV BX, F_HANDLE
    MOV CX, 1
    LEA DX, TEMP_VAL
    INT 21H
    JMP W_RET

W_NZ:
    MOV BX, 10
    XOR CX, CX
W_DIG:
    XOR DX, DX
    DIV BX
    PUSH DX
    INC CX
    CMP AX, 0
    JNE W_DIG
W_WRT:
    POP DX
    ADD DL, 30H
    MOV TEMP_VAL, DL 
    
    PUSH CX 
    MOV AH, 40H
    MOV BX, F_HANDLE
    MOV CX, 1
    LEA DX, TEMP_VAL
    INT 21H
    POP CX
    
    LOOP W_WRT
W_RET:  
    POP DX
    POP CX
    POP BX
    POP AX
    RET
WRITE_NUM_TO_FILE ENDP

WRITE_NAME_TO_FILE PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV AX, SI
    MOV CX, NAME_LEN
    MUL CX
    MOV BX, AX 
    
    MOV AH, 40H
    LEA DX, NAME_ARR
    ADD DX, BX
    MOV CX, NAME_LEN
    MOV BX, F_HANDLE
    INT 21H
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
WRITE_NAME_TO_FILE ENDP

WRITE_COMMA PROC
    MOV AH, 40H
    MOV BX, F_HANDLE
    MOV CX, 1
    LEA DX, COMMA
    INT 21H
    RET
WRITE_COMMA ENDP

WRITE_NEWLINE PROC
    MOV AH, 40H
    MOV BX, F_HANDLE
    MOV CX, 2
    LEA DX, NEWLINE
    INT 21H
    RET
WRITE_NEWLINE ENDP

CHECK_DUPLICATE PROC
    MOV BX, 0
    MOV CX, COUNT
    JCXZ NO_DUP
DUP_L:
    MOV AL, SR_ARR[BX]
    CMP AL, TEMP_VAL
    JE IS_DUP
    INC BX
    LOOP DUP_L
NO_DUP:
    MOV AX, 0
    RET
IS_DUP:
    MOV AX, 1
    RET
CHECK_DUPLICATE ENDP

INPUT_NUM PROC
    PUSH BX
    PUSH CX
    XOR BX, BX
    XOR CX, CX
IN_DIGIT:
    MOV AH, 01H
    INT 21H
    CMP AL, 13
    JE END_IN
    SUB AL, 30H
    MOV CL, AL
    MOV AX, 10
    MUL BL
    ADD AL, CL
    MOV BL, AL
    JMP IN_DIGIT
END_IN:
    MOV AL, BL
    POP CX
    POP BX
    RET
INPUT_NUM ENDP

INPUT_STRING PROC
    PUSH CX
    PUSH DI
    MOV CX, NAME_LEN
    PUSH DI
    PUSH CX
CLR_L:
    MOV NAME_ARR[DI], ' '
    INC DI
    LOOP CLR_L
    POP CX
    POP DI
RD_STR:
    MOV AH, 01H
    INT 21H
    CMP AL, 13
    JE END_STR
    MOV NAME_ARR[DI], AL
    INC DI
    LOOP RD_STR
END_STR:
    POP DI
    POP CX
    RET
INPUT_STRING ENDP

PRINT_NAME_AT_SI PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    MOV AX, SI
    MOV CX, NAME_LEN
    MUL CX
    MOV BX, AX
    MOV CX, NAME_LEN
P_N_L:
    MOV DL, NAME_ARR[BX]
    MOV AH, 02H
    INT 21H
    INC BX
    LOOP P_N_L
    
    MOV DL, ' '
    INT 21H
    INT 21H
    INT 21H
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_NAME_AT_SI ENDP

PRINT_NUM PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    CMP AX, 0
    JNE NON_ZERO
    MOV DL, '0'
    MOV AH, 02H
    INT 21H
    JMP P_RET
NON_ZERO:
    MOV BX, 10
    XOR CX, CX
DIG_L:
    XOR DX, DX
    DIV BX
    PUSH DX
    INC CX
    CMP AX, 0
    JNE DIG_L
PRN_L:
    POP DX
    ADD DL, 30H
    MOV AH, 02H
    INT 21H
    LOOP PRN_L
P_RET:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_NUM ENDP

PRINT_TAB PROC
    MOV DL, ' '
    MOV AH, 02H
    INT 21H
    INT 21H
    INT 21H
    INT 21H
    INT 21H
    INT 21H
    INT 21H
    INT 21H
    INT 21H
    INT 21H
    INT 21H
    RET
PRINT_TAB ENDP

PRINT_TAB_SMALL PROC
    MOV DL, ' '
    MOV AH, 02H
    INT 21H
    INT 21H
    INT 21H
    RET
PRINT_TAB_SMALL ENDP

END MAIN