section	.rodata			; we define (global) read-only variables in .rodata section
	format_target: db "%.2f,%.2f" , 10 , 0
	format_drone: db "%d,%.2f,%.2f,%.2f,%d" , 10 , 0


section .bss			   ; we define (global) uninitialized variables in .bss section
	tmp: resd 1

section .data
	 


section .text
  align 16
  global printer_func
  extern coPrinter
  extern steps
  extern coTarget
  extern cors
  extern printf
  extern numOfDrones
  extern resume
  extern coScheduler

printer_func:

	lea eax, [coTarget+16]		;printing y of target
	push dword [eax+4]		
	push dword [eax]

	lea eax, [coTarget+8]		;printing x of target
	push dword [eax+4]		
	push dword [eax]
	
	push format_target
	call printf
	add esp, 20

	mov ecx, 0
	mov edi, 0						;indicator for current drone
	print_drones:
		mov esi, [cors+edi]			;esi points to current drone
		mov [tmp], ecx				;backup ecx

		push dword [esi+36]		;print numOfTatgets

		lea eax, [esi+28]
		push dword [eax+4]		;print alpha
		push dword [eax]

		lea eax, [esi+20]
		push dword [eax+4]		;print y
		push dword [eax]

		lea eax, [esi+12]
		push dword [eax+4]		;print x
		push dword [eax]

		push dword [esi+8]			;prints id

		push format_drone
		call printf
		add esp, 36
		
		add edi,4
		mov ecx, [tmp]
		inc ecx
		cmp ecx, [numOfDrones]
		jne print_drones

back_to_scheduler:
		lea ebx, [coScheduler]
		call resume
jmp printer_func