; -----------------------------------------------------------------------------
; Program: Data Conversion
; Description: This program prompts the user to enter a number, then it displays
;              the entered number, half of the entered number, and double the 
;              entered number. The program continues to prompt for input until 
;              a blank input is entered.
; -----------------------------------------------------------------------------

section .data
    AskforInput db "Please enter a number: ", 0  ; Prompt message for user input
    lenAskforInput equ $ - AskforInput           ; Length of the prompt message
    ReturnInput db "The entered number is: ", 0  ; Message to display entered number
    lenReturnInput equ $ - ReturnInput           ; Length of the entered number message
    ReturnHalfInput db "Half of the entered number is: ", 0  ; Message to display half the number
    lenReturnHalfInput equ $ - ReturnHalfInput   ; Length of the half number message
    ReturnDoubleInput db "Double of the entered number is: ", 0  ; Message to display double the number
    lenReturnDoubleInput equ $ - ReturnDoubleInput  ; Length of the double number message
    Sign db 0            ; Reserve 1 byte for sign
    newline db 10, 0     ; Newline character (ASCII 10)        

section .bss
    buffer resb 15       ; Buffer for user input
    string resb 15       ; Buffer for input number
    TempStorage resb 15  ; Buffer for temporary storage
    Inputlen resb 2      ; Buffer for input length
    Outputlen resb 1     ; Buffer for output length
    OutputBuffer resb 1  ; Buffer for output

section .text
    global _start

_start:
    ; ---------------------The start of the main program-----------------------------
while_loop:
    ; Ask the users for input
    push AskforInput         ; Push the prompt message onto the stack
    push lenAskforInput      ; Push the length of the prompt message onto the stack
    call print               ; Call the print subroutine to display the prompt
    add rsp, 16              ; Clear the stack (16 from 8*2 because 2 arguments in 64 bit)        

    mov rsi, buffer          ; Move buffer into rsi, so it can be used in the clearbuffer subroutine
    call clearbuffer         ; Call the clearbuffer subroutine to clear the buffer

    ; Read the user input
    push buffer              ; Push the buffer address onto the stack
    call iread               ; Call the iread subroutine to read user input
    add rsp, 8               ; Clear the stack (8 because 1 argument in 64 bit) 

    ; Exit if blank
    cmp byte [buffer], 10    ; Compare the first byte of the buffer with newline character
    je End_Program           ; If it is a newline, jump to End_Program

    ; Return the user input
    push ReturnInput         ; Push the message to display entered number onto the stack
    push lenReturnInput      ; Push the length of the message onto the stack
    call print               ; Call the print subroutine to display the message
    add rsp, 16              ; Clear the stack

    push rbx                 ; Push the entered number onto the stack
    call iprint              ; Call the iprint subroutine to print the entered number
    add rsp, 8               ; Clear the stack

    ; Half and Return the result
    mov rbp, rbx             ; Save the user input (stored as number) in rbp because rbx will be updated
    call prln                ; Call the prln subroutine to print a new line
    push ReturnHalfInput     ; Push the message to display half the number onto the stack
    push lenReturnHalfInput  ; Push the length of the message onto the stack
    call print               ; Call the print subroutine to display the message

    mov rax, rbp             ; Load the user input (stored as number) from rbp into rax
    sar rax, 1               ; Divide the number by 2
    push rax                 ; Push the half of number as argument onto the stack for iprint subroutine
    call iprint              ; Call the iprint subroutine to print the half number
    add rsp, 8               ; Clear the stack
    call prln                ; Call the prln subroutine to print a new line

    ; Return double of the value
    push ReturnDoubleInput   ; Push the message to display double the number onto the stack
    push lenReturnDoubleInput  ; Push the length of the message onto the stack
    call print               ; Call the print subroutine to display the message

    mov rbx, rbp             ; Load the user input (stored as number) from rbp into rbx
    shl rbx, 1               ; Multiply the number by 2 to obtain double the value
    push rbx                 ; Push the double of the number as argument onto the stack for iprint subroutine
    call iprint              ; Call the iprint subroutine to print the double number
    add rsp, 8               ; Clear the stack
    call prln                ; Call the prln subroutine to print a new line
    call prln                ; Call the prln subroutine to print another new line

    mov rsi, OutputBuffer    ; Reset output buffer
    call clearbuffer         ; Call the clearbuffer subroutine to clear the buffer

    mov byte[Sign], 0        ; Reset the sign               
    jmp while_loop           ; Jump back to the start of the while loop
    
; ---------------------------Sub Routine 1: print--------------------------------
print:
    ; Print the number input by the user
    mov rax, 1              ; syscall: write
    mov rdi, 1              ; file descriptor: stdout
    mov rsi, [rsp + 8*2]    ; 2nd argument: address of the string to print
    mov rdx, [rsp + 8]      ; 1st argument: length of the string to print
    syscall                 ; Make the system call
    ret                     ; Return from the subroutine

; ---------------------------Sub Routine 2: iread--------------------------------
iread:
    ; Read input from the user
    mov rax, 0              ; syscall: read
    mov rdi, 0              ; file descriptor: stdin
    mov rcx, [rsp + 8]      ; moves the value at the memory address [rsp + 8] into the rcx register.
    mov rdx, 15             ; number of bytes to read
    syscall                 ; Make the system call
    mov [Inputlen], al      ; Store the length of the input

    mov rsi, [rsp + 8]      ; address of number
    mov rcx, rax            ; length of the input
    dec rcx                 ; decrement the length for zero-based indexing
    xor rdx, rdx            ; initialize rdx to zero
    xor rbx, rbx            ; initialize rbx to zero
    xor rax, rax            ; initialize rax to zero

    ; Check for negative sign
    mov al, [rsi]           ; load the first character
    cmp al, '-'             ; compare whether it's '-'
    jne ispositive          ; if not '-', jump to ispositive
    inc rsi                 ; move to the next character
    dec rcx                 ; decrement length for negative sign
    mov byte [Sign], 1      ; save sign as 1 for negative
ispositive:
    cmp rcx, 0              ; check if length is zero
    je finish_conversion    ; if zero, jump to finish_conversion
convert_loop:
    mov al, [rsi + rdx]     ; load the front character from number one by one; rdx starts from 0 and increment with each character
    sub al, 48              ; convert character to integer
    imul rbx, rbx, 10       ; multiply rbx by 10
    add rbx, rax            ; add integer to rbx
    inc rdx                 ; increment the index
    dec rcx                 ; decrement character count
    jnz convert_loop        ; repeat until done
finish_conversion:
    cmp byte [Sign], 1      ; check if the sign indicates a negative number
    jne end_conversion      ; if not, skip negation
    imul rbx, -1            ; convert positive to negative
end_conversion:
    mov [string], rbx       ; save the integer in input
    mov rax, [Inputlen]     ; return the input
    mov rbx, [string]       ; move the input to rbx
    ret                     ; return from the subroutine

; ---------------------------Sub Routine 3: iprint --------------------------------
iprint:
    ; Print the integer number
    mov rax, [rsp + 8]      ; Load the integer number in both rax and rbx for ise
    mov rbx, [rsp + 8]
    cmp rax, 0              ; check if rax is smaller than zero
    jl NegativeNumber       ; if rax smaller than zero, then jump to NegativeNumber
    jmp ConvertPositive     ; if rax not smaller than zero, jump to ConvertPositive 
NegativeNumber:
    neg rax                 ; turn rax into positive
    mov byte[Sign], 1       ; set the sign to negative
ConvertPositive:
    mov byte [Outputlen], 0 ; reset output length
    call Convert_to_ascii   ; call the Convert_to_ascii subroutine
    mov rax, 1              ; syscall: write
    mov rdi, 1              ; file descriptor: stdout
    mov rsi, OutputBuffer   ; address of the output buffer
    mov rdx, Outputlen      ; length of the output
    syscall                 ; make the system call
    ret                     ; return from the subroutine

Convert_to_ascii:
    ; Convert the integer to ASCII
    mov rdi, OutputBuffer   ; RDI points to the output buffer
    xor rcx, rcx            ; Reset digit counter

conversion_loop:
    push rbx
    mov rbx, 10             ; divisor
    xor rdx, rdx            ; clear RDX for division
    div rbx                 ; divide RAX by 10
    pop rbx
    add dl, 48              ; convert remainder to ASCII
    push rdx                ; save ASCII character
    inc rcx                 ; increment digit counter
    inc byte [Outputlen]    ; increment length
    test rax, rax           ; check if RAX is zero
    jnz conversion_loop     ; repeat if not zero

    ; Handle negative sign for half value
    cmp byte[Sign], 1
    jne PopNumberOut        ; If not negative, skip adding sign
    mov byte [rdi], '-'     ; Add negative sign
    inc rdi                 ; Move to the next position
    inc byte [Outputlen]    ; Increment output length for sign

PopNumberOut:
    pop rdx                 ; Pop last digit from the stack
    mov [rdi], dl           ; Store digit in output buffer
    inc rdi                 ; Move to next position
    dec rcx                 ; Decrement counter
    jnz PopNumberOut        ; Repeat until all digits are stored

    mov byte [rdi], 0       ; Null-terminate the string
    inc byte [Outputlen]    ; Account for the null terminator
    ret                     ; return from the subroutine

; ---------------------------Sub Routine 4: clearbuffer --------------------------------
clearbuffer:
    ; Clear the buffer
    push rcx                ; Saves rcx onto the stack, ensuring it can be restored later
    mov rdi, rsi            ; rsi should point to the buffer to clear
    mov rcx, 15             ; assuming max buffer size is 15 bytes
    xor rax, rax            ; clear rax (set to zero)
clear_loop:
    mov [rdi], al           ; set each byte to zero
    inc rdi                 ; move to the next byte
    dec rcx                 ; decrement the counter
    jnz clear_loop          ; repeat until all bytes are cleared
    pop rcx                 ; Restore rcx
    ret                     ; return from the subroutine

; ---------------------------Sub Routine 5: print a newline -------------------------------
prln:
    ; Print a newline character
    mov rax, 1              ; syscall: write
    mov rdi, 1              ; file descriptor: stdout
    mov rsi, newline        ; address of the newline character
    mov rdx, 1              ; length of the newline character
    syscall                 ; make the system call
    ret                     ; return from the subroutine

; ---------------------------Sub Routine 6: End program -------------------------------
End_Program:
    ; Exit the program
    mov rax, 60             ; syscall: exit
    xor rdi, rdi            ; status: 0
    syscall                 ; make the system call