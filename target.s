section	.rodata			; we define (global) read-only variables in .rodata section
	


section .bss			   ; we define (global) uninitialized variables in .bss section

section .data
	 


section .text
  align 16
  global target_func
  extern seed
  extern scaled_num
  extern random_num
  extern coTarget
  extern coScheduler
  extern resume
  extern hundred
  extern curr_drone


target_func:
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

	mov ebx, [curr_drone]
	call resume
jmp target_func