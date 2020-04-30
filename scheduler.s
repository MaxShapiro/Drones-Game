section	.rodata			; we define (global) read-only variables in .rodata section
	

section .bss			   ; we define (global) uninitialized variables in .bss section

section .data
	counter: dd 0		;counter for steps
	 


section .text
  align 16
  global scheduler_func
  extern coPrinter
  extern steps
  extern cors
  extern printf
  extern cors
  extern resume
  extern numOfDrones
  extern steps_counter


scheduler_func:
	mov edi, [counter]
	mov ebx, [cors+4*edi]		;ebx points to the next drone to activate
	call resume					;do mission of drone

	add dword [counter], 1		;i++
	mov ecx, [numOfDrones]		;round-rob
	cmp ecx, [counter]			;if i > numOfDrones
	jne check_for_print
	mov dword [counter], 0

check_for_print:
	sub dword [steps_counter], 1		;check if did k steps
	cmp dword [steps_counter], 0		;if i == k
	jne fin


printer:
	mov ecx, [steps]			;initilize steps_counter again
	mov [steps_counter], ecx
	lea ebx, [coPrinter]		;do mission of printer
	call resume

fin:
	jmp scheduler_func