section	.rodata			; we define (global) read-only variables in .rodata section
	format_int: db "%d", 10, 0	; format string
	format_float: db "%.2f", 10, 0	; format string

section .bss
	global cors
	cors: resd 1	; pointer to the co-routines array
	STKSIZE equ 16*1024   ;16kb
	STKTarget: resb STKSIZE    ;memory allocation for stack
	STKScheduler: resb STKSIZE    ;memory allocation for stack
	STKPrinter: resb STKSIZE    ;memory allocation for stack
	normal_num: resq 1
	tmp: resd 1
	SPT: resd 1					;stack pointer backup
	SPMAIN: resd 1				;main pointer backup
	global CURR
	CURR: resd 1				;points to current co-routine stack


section .data
	global endCo
	global MAXINT
	MAXINT: dd 65535
	global numOfDrones
	numOfDrones: dd 0
	global numOfTargetsToKill
	numOfTargetsToKill: dd 0
	global steps
	steps: dd 0
	global steps_counter
	steps_counter: dd 0
	global angle
	angle: dd 0
	global maxDistance
	maxDistance: dd 0
	global seed
	seed: dd 0
	global hundred
	hundred: dd 100  	;for normalization
	global threesixty
	threesixty: dd 360
	lfsrCunt: dd 16

	global coTarget
	coTarget: dd 0 							;funcTarget- struct of target co-rotine
			  dd STKTarget + STKSIZE 
			  dq 0							;x
			  dq 0							;y
	global coScheduler
	coScheduler:  dd 0					    ;funcScheduler - struct of scheduler co-rotine
			 	  dd STKScheduler + STKSIZE
	global coPrinter
	coPrinter: 	  dd 0					    ;funcPrinter- struct of target co-rotine
			   	  dd STKPrinter + STKSIZE



section .text
  align 16
	 global main
	 global random_num
	 global scaled_num
	 global resume
	 global steps_counter
	 extern printf                  ;functions of stdlib
	 extern fprintf
	 extern malloc
	 extern free
	 extern sscanf
	 extern printer_func			;functions of co-routines
	 extern target_func
	 extern drone_func
	 extern scheduler_func

scaled_num:			;make val return from seed 0-100\0-60
	push ebp            ;;starting operations - backup the registers
	mov ebp, esp	
	pushad

	finit	
	fild dword [seed]		;load seed
	fdiv dword [MAXINT] 	;x\MAXINT
	fmul dword	[ebp+12]	;x*100
	mov eax, [ebp+8]
	fstp qword[eax]
	ffree					;free x87 aritmethic				

	popad			
	mov esp, ebp	
	pop ebp
	ret




random_num:				;generate new number
	push ebp            ;;starting operations - backup the registers
	mov ebp, esp	
	pushad

lfsr_loop:
	cmp dword [lfsrCunt], 0
	je end_random_num
	mov eax, 0				;prepare registers
	mov ebx, 0
	mov ecx, 0 
	mov edx, 0
	mov ax, word [seed]		;ax, bx, cx, dx holds the user input
	mov bx, word [seed]
	mov cx, word [seed]
	mov dx, word [seed]
	;make algo to generate from here:
	;https://en.wikipedia.org/wiki/Linear-feedback_shift_register#Fibonacci_LFSRs
	shr bx, 2				;(lfsr >> 2)
	shr cx, 3				;(lfsr >> 3)
	shr dx, 5				;(lfsr >> 5)
	xor ax, bx
	xor ax, cx
	xor ax, dx
	mov bx, word [seed]
	shl ax, 15				;(bit << 15)
	shr bx, 1				;(lfsr >> 1)
	or ax, bx
	mov [seed], ax
	sub dword [lfsrCunt], 1
	jmp lfsr_loop

end_random_num:
	mov dword [lfsrCunt], 16

	popad			
	mov esp, ebp	
	pop ebp
	ret


%macro initCo 2							;initilize co-routines
	lea eax, [%1] 						;pointer to co-rotine function
	mov [%2], eax						;connect between co_func to adress		
	mov [SPT], esp
	mov esp, [%2+4]						;pointer to co-rotine stack
	push eax 	                        ; push initial “return” address
	pushfd		                 		; push flags
	pushad		               			; push all other registers
	mov [%2+4], esp						; save new SPi value (after all the pushes)
	mov esp, [SPT]	                    ; restore ESP value
%endmacro



%macro save_arg 1 				;save value for arg
	lea ebx, [%1]				;push the adress of the variable
	push ebx
	push format_int
	mov dword edx, [esi+edi*4]	; get function first argument (pointer to string)
	push edx
	call sscanf					;make it int
	add esp, 12

%endmacro



main: 
	push ebp            ;;starting operations - backup the registers
	mov ebp, esp	
	pushad	

	mov edi, 1 					;counter for args
	mov esi, dword [ebp+12]		; points to argv
argsFromCommand:
	save_arg numOfDrones 	;saving all the 6 arguments from command line
	inc edi
	save_arg numOfTargetsToKill
	inc edi
	save_arg steps
	mov ebx, [steps]
	mov [steps_counter], ebx	;for scheduler
	inc edi
	save_arg angle
	lea ebx, [angle]			;push the adress of the angle
	push ebx
	push format_float
	mov dword edx, [esi+edi*4]	; get function first argument (pointer to string)
	push edx
	call sscanf					;make it int
	add esp, 12
	inc edi
	save_arg maxDistance
	inc edi
	save_arg seed


initilize_coTarget:
	initCo target_func, coTarget
	call random_num
	lea esi, [coTarget+8]
	push dword [hundred]
	push esi
	call scaled_num				  	;generates x for co_target
	call random_num
	lea esi, [coTarget+16]
	push dword [hundred]
	push esi
	call scaled_num				  	;generates y for co_target


initilize_coPrinter:
	initCo printer_func, coPrinter 	
	
initilize_scheduler:
	initCo scheduler_func, coScheduler

makeDrones:
	mov ebx , [numOfDrones]		;making co-rotines pointers array:
	mov eax, 4
	mul ebx
	push eax
	call malloc					;malloc for cors array
cc:
	add esp, 4
	mov dword [cors], eax


	mov ecx, [numOfDrones]		;counter for numOfDrones
	mov edi, 0					;indicates location 
	mov esi, 1					;for drone id
	initilize_loop:				;initilize drones
		mov [tmp], ecx
		push 40
		call malloc
		add esp, 4

		mov dword [cors+edi], eax
		mov ebx, eax
		push 4
		call malloc
		add esp, 4
		mov [ebx], eax		; pointer to drone function
	
		push STKSIZE
		call malloc
		add esp, 4
		add eax, STKSIZE
		mov [ebx+4], eax		;pointer to head of stack
		lea ecx, [ebx]

		initCo drone_func, ecx	;initilize co-routine  

		mov [ebx+8], esi			;id
		inc esi

		call random_num			;generates x
		lea ecx, [ebx+12]
		push dword [hundred]
		push ecx				;pusx x adress
		call scaled_num				

		call random_num			;generates y
		lea ecx, [ebx+20]
		push dword [hundred]
		push ecx
		call scaled_num	

		call random_num				;generates alpha
		lea ecx, [ebx+28]
		push dword [threesixty]
		push ecx
		call scaled_num
						
		mov dword [ebx+36], 0	;score

		add edi, 4
		mov ecx, [tmp]
		dec ecx
		jnz initilize_loop

startCo:
	pushad						; save registers of main ()
	mov [SPMAIN], esp			; save ESP of main ()
	lea ebx, [coScheduler]		; gets a pointer to a scheduler struct 
	jmp do_resume				; resume a scheduler co-routine



resume:							; save state of current co-routine
	pushfd
	pushad
	mov edx, [CURR]
	mov [edx+4], esp   			; save current ESP

do_resume:  					; load ESP for resumed co-routine
	mov esp, [ebx+4]			; points to coScheduler stack
	mov [CURR], ebx
	popad  						; restore resumed co-routine state
	popfd	
	ret        					; "return" to resumed co-routine

endCo:
	mov	esp, [SPMAIN]           ; restore ESP of main()
	popad						; restore registers of main()			
	mov esp, ebp	
	pop ebp
	ret
	
