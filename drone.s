section	.rodata			; we define (global) read-only variables in .rodata section
	format_float: db "%.2f", 10, 0	; format string
	format_win: db "Drone id %d: I am a winner" ,10, 0

section .bss			   ; we define (global) uninitialized variables in .bss section
	global curr_drone
	curr_drone: resd 1	   ; points to curr_drone
	gamma: resq 1


section .data
	 sixty: dd 60  	;for normalization
	 fifty: dd 50
	 oneTwenty: dd 120
	 oneEighty: dd 180
	 threesixty: dq 360.0
	 zero: dq 0.0
	 pai: dq 3.14

	 random_angle: dq 0
	 random_distance: dq 0
	 new_position: dq 0

	 x_flag: dd 0
	 tmp:dq 0


section .text
  align 16
  global drone_func
  extern seed
  extern MAXINT
  extern coScheduler
  extern coPrinter
  extern steps
  extern coTarget
  extern cors
  extern printf
  extern resume
  extern scaled_num
  extern random_num
  extern hundred
  extern angle 			   ;=beta
  extern maxDistance
  extern numOfTargetsToKill
  extern endCo
  extern CURR

make_new_angle:			   ;generates new random_angle (-60 to 60)
	push ebp            
	mov ebp, esp	
	pushad

	call random_num
	finit
	fild dword [seed]
	fidiv dword [MAXINT]		;div with MAXINT
	fimul dword [oneTwenty]		;*120
	fisub dword [sixty]			;- 60
	lea eax, [random_angle]
	fstp qword [eax]	;stores num in random_angle
	ffree

	popad			
	mov esp, ebp	
	pop ebp
	ret


make_new_distance:			   ;generates new random_distance (0 to 50)
	push ebp            
	mov ebp, esp	
	pushad

	call random_num
	finit
	fild dword [seed]
	fidiv dword [MAXINT]		;div with MAXINT
	fimul dword [fifty]			;*50
	lea eax, [random_distance]
	fstp qword [eax]	;stores num in random_angle
	ffree

	popad			
	mov esp, ebp	
	pop ebp
	ret

add_angle:
	push ebp            
	mov ebp, esp	
	pushad

	mov ebx, [curr_drone]		;ebx points to the curr_drone 
	mov eax, 0
	finit

	fld qword [ebx+28]         	;loads the current angle of the drone
	fadd qword [random_angle]	;adds the new angle

	check_angles:
		fld qword [threesixty]
		fcomi st0,st1
		jb bigger_360
		fstp qword [tmp]
		fld qword [zero]
		fcomi st0, st1
		ja below_0
		fstp qword [tmp]
		jmp store

		below_0:
			fstp qword [tmp]
			fadd qword [threesixty]
			jmp store

		bigger_360:
			fstp qword [tmp]
			fsub qword [threesixty]

	store:						;return the reminder for 360(modulu) for the new_position
		fstp qword [ebx+28]		;stores num in drone angle
		ffree

	popad			
	mov esp, ebp	
	pop ebp
	ret


move_distance:
	push ebp            
	mov ebp, esp	
	pushad

	calc_new_x:
		mov dword [x_flag], 1
		mov ebx, [curr_drone]	;ebx points to the curr_drone
		mov eax, 0
		fld qword [ebx+28]		;load drone angle
		fmul qword [pai] 		;moving alpha to radians : a*pai\180
		fidiv dword [oneEighty]	;make the resault in radians
		fcos					;cosinus alpha
		fmul qword [random_distance]			
		fadd qword [ebx+12]		;new x = x + delta d * (cos alph)
		jmp check_board_size	;check range 0-100

		store_x:
			fstp qword [ebx+12]		;stores num in drone x
			ffree

	calc_new_y:
		mov dword [x_flag], 0
		mov ebx, [curr_drone]	;ebx points to the curr_drone
		mov eax, 0
		fld qword [ebx+28]		;load drone angle
		fmul qword [pai] 		;moving alpha to radians : a*pai\180
		fidiv dword [oneEighty]	;make the resault in radians
		fsin					;sinus alpha
		fmul qword [random_distance]			
		fadd qword [ebx+20]		;new y = y + delta d * (sin alph)
		jmp check_board_size	;check range 0-100

		store_y:
			fstp qword [ebx+20]		;stores num in drone y
			ffree
			jmp fin_move_distance

check_board_size:
	fild dword [hundred]
	fcomi st0, st1
	jb bigger_100				;if > 100

	fstp qword [tmp]			
	fld qword [zero]
	fcomi st0, st1
	ja under_0					;if<0

	fstp qword [tmp]
	cmp dword [x_flag], 1
	je store_x
	jmp store_y

	under_0:
		fstp qword [tmp]
		fiadd dword [hundred]
		cmp dword [x_flag], 1
		je store_x
		jmp store_y


	bigger_100:
		fstp qword [tmp]
	    fisub dword [hundred]
		cmp dword [x_flag], 1
		je store_x
		jmp store_y

			
fin_move_distance:
	popad			
	mov esp, ebp	
	pop ebp
	ret


mayDestroy:
	push ebp            
	mov ebp, esp	
	pushad

	mov ebx, [curr_drone]	;ebx points to the curr_drone
	finit
	fld qword [coTarget+16]		;loads target y
	fsub qword [ebx+20]		;y2-y1

	fld qword [coTarget+8]		;loads target x
	fsub qword [ebx+12]		;x2-x1
	fpatan 					;arctan2(y2-y1, x2-x1)
	fimul dword [oneEighty] 		;moving gamma from radians : a*180\pi
	fdiv qword [pai]	;make the resault in angles
	fstp qword [gamma]		;stores gamma
	fld qword [ebx+28]		;load drones alpha
	fsub qword [gamma]		;alpha-gamma
	fabs					;abs(alpha-gamma)


	fild dword [oneEighty]	;note , check if (alpha-gamma)>pi
	fcomi st0, st1
	ja continue

	finit 					;note - compare alph & gamma
	fld qword [gamma]
	fld qword [ebx+28]
	fcomi st0, st1
	jb change_alpha

	fstp qword [tmp]		;remove alpha
	fadd qword [threesixty]	;change gamma
	fsub qword [ebx+28]		;gamma-alpha
	fabs
	fld qword [tmp]			;for garbage
	jmp continue

	change_alpha:
	fsub qword [threesixty]
	fsub qword [ebx+28]		;gamma-alpha
	fabs
	fild dword [oneEighty]

	continue:
	fstp qword [tmp]
	fild dword [angle]		;check <beta
	fcomi
	jbe fin_mayDestroy

	below_beta:
		mov ebx, [curr_drone]	;ebx points to the curr_drone
		mov ecx, [coTarget]		;ecx points to the coTarget
		finit
		fld qword [coTarget+16]		;loads target y
		fsub qword [ebx+20]		;y2-y1
		fld qword [coTarget+16]		;loads target y
		fsub qword [ebx+20]		;y2-y1
		fmulp					;(y2-y1)^2

		fld qword [coTarget+8]		;loads target x
		fsub qword [ebx+12]		;x2-x1
		fld qword [coTarget+8]		;loads target x
		fsub qword [ebx+12]		;x2-x1
		fmulp					;(x2-x1)^2

		faddp 					;((x2-x1)^2)+((y2-y1)^2)
		fsqrt 					;sqrt(((x2-x1)^2)+((y2-y1)^2))

		fild dword [maxDistance]	;check if <d
		fcomi st0, st1
		jbe fin_mayDestroy

		lea ebx, [coTarget]		;killing
		call resume
	
		mov ebx, [curr_drone]
		mov ecx, [ebx+36]		
		inc ecx					;drone score++
		mov dword [ebx+36], ecx	
		cmp ecx, [numOfTargetsToKill]
		jne fin_mayDestroy		
		push dword [ebx+8]		;drone id
		push format_win			;printinf the winner
		call printf
		add esp, 8
		jmp endCo				;finishes rhe game

fin_mayDestroy:
	popad			
	mov esp, ebp	
	pop ebp
	ret


drone_func:
	mov ebx, [CURR]
	mov [curr_drone], ebx		;backup pointer to current drone
	
	call make_new_angle
	call make_new_distance
	call add_angle				;compute & adds the new angle to the drone
	call move_distance			;move drone in delta d
	call mayDestroy

end:
	lea ebx, [coScheduler]		;do mission of printer
	call resume

jmp drone_func
	