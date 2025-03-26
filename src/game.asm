%define TITLESCREEN_ID 1
%define GAMESCREEN_ID 2
%define DEATHSCREEN_ID 3

section code
; entry point (called from `kernel.asm`)
fn init
	call setup_palette
	call setup_titlescreen
endfn

; called every PIT interrupt from `kernel.asm`
fn tick
	cmp byte [active_screen], TITLESCREEN_ID
	je .titlescreen
	cmp byte [active_screen], GAMESCREEN_ID
	je .gamescreen
	cmp byte [active_screen], DEATHSCREEN_ID
	je .deathscreen
	unreachable

	.titlescreen:
	call titlescreen_tick
	jmp .end_switch
	.gamescreen:
	call game_tick
	jmp .end_switch
	.deathscreen:
	call deathscreen_tick
	.end_switch:
endfn

; called every keyboard event from `kernel.asm`
fn keyboard_handler
.keycode: arg 1

	pushb [ebp+.keycode]

	cmp byte [active_screen], TITLESCREEN_ID
	je .titlescreen
	cmp byte [active_screen], GAMESCREEN_ID
	je .gamescreen
	cmp byte [active_screen], DEATHSCREEN_ID
	je .deathscreen
	unreachable

	.titlescreen:
	call titlescreen_handle_input
	jmp .end_switch
	.gamescreen:
	call game_handle_input
	jmp .end_switch
	.deathscreen:
	call deathscreen_handle_input
	.end_switch:
endfn

; ==================================================================================================
; Titlescreen
; ==================================================================================================

fn setup_titlescreen
	mov byte [active_screen], TITLESCREEN_ID

	; setup the PIT with the lowest possible frequency
	push word 65535
	call setup_pit
endfn

fn titlescreen_handle_input
.keycode: arg 1

	cmp byte [ebp+.keycode], 0x02
	je .key_1
	cmp byte [ebp+.keycode], 0x03
	je .key_2
	cmp byte [ebp+.keycode], 0x04
	je .key_3
	jmp .ret

	.key_1:
	pushb 1
	jmp .end_switch
	.key_2:
	pushb 2
	jmp .end_switch
	.key_3:
	pushb 3
	.end_switch:
	call setup_gamescreen

	.ret:
endfn

%define KEYBIND_SHADOW_PHASE_OFFSET 43

; toggle text shadow color
fn titlescreen_tick
	; To further reduce the frequency of color changes, a constant value is added
	; to the byte 'keybind_shadow_phase' every tick. Because
	; 'keybind_shadow_phase' wraps around at 127 to -128, roughly half the time
	; 'keybind_shadow_phase' < 0 and the other half 'keybind_shadow_phase' >= 0,
	; but the frequency is lower.

	add byte [keybind_shadow_phase], KEYBIND_SHADOW_PHASE_OFFSET

	pushb text_shadow_color
	cmp byte [keybind_shadow_phase], 0
	jl .render
	pushb text_shadow_color2
	.render:
	call render_titlescreen
endfn

%define TITLESCREEN_HEADING_SIZE 5
%define TITLESCREEN_HEADING_POS (20 * (FB_WIDTH + 1))
%define TITLESCREEN_HEADING_SHADOW_OFFSET (3 * (FB_WIDTH - 1))

%define TITLESCREEN_INSTR_POS (120 * FB_WIDTH + 96)
%define TITLESCREEN_INSTR_COL_WIDTH 64
%define TITLESCREEN_INSTR_ROW_OFFSET (16 * FB_WIDTH)
%define TITLESCREEN_INSTR_HEADING_OFFSET 64
%define TITLESCREEN_INSTR_SHADOW_OFFSET (FB_WIDTH - 1)

%define TITLESCREEN_INSTR_COL1 (TITLESCREEN_INSTR_POS + TITLESCREEN_INSTR_COL_WIDTH / 2)
%define TITLESCREEN_INSTR_COL2 (TITLESCREEN_INSTR_POS + 3 * TITLESCREEN_INSTR_COL_WIDTH / 2)
%define TITLESCREEN_INSTR_COL3 (TITLESCREEN_INSTR_POS + 5 * TITLESCREEN_INSTR_COL_WIDTH / 2)

fn render_titlescreen
.keybind_shadow_color: arg 1

	call clear_screen_buf

	pushb text_shadow_color
	push dword TITLESCREEN_HEADING_SIZE
	push dword TITLESCREEN_HEADING_POS + TITLESCREEN_HEADING_SHADOW_OFFSET
	push dword titlescreen_title
	call draw_str
	pushb text_color
	push dword TITLESCREEN_HEADING_SIZE
	push dword TITLESCREEN_HEADING_POS
	push dword titlescreen_title
	call draw_str

	pushb text_color
	push dword 1 ; scaling factor
	push dword TITLESCREEN_INSTR_POS - TITLESCREEN_INSTR_HEADING_OFFSET
	push dword titlescreen_str_press
	call draw_str

	pushb [ebp+.keybind_shadow_color]
	push dword 1 ; scaling factor
	push dword TITLESCREEN_INSTR_COL1 - 4 + TITLESCREEN_INSTR_SHADOW_OFFSET
	pushb '1'
	call draw_char
	pushb text_color
	push dword 1 ; scaling factor
	push dword TITLESCREEN_INSTR_COL1 - 4
	pushb '1'
	call draw_char

	pushb [ebp+.keybind_shadow_color]
	push dword 1 ; scaling factor
	push dword TITLESCREEN_INSTR_COL2 - 4 + TITLESCREEN_INSTR_SHADOW_OFFSET
	pushb '2'
	call draw_char
	pushb text_color
	push dword 1 ; scaling factor
	push dword TITLESCREEN_INSTR_COL2 - 4
	pushb '2'
	call draw_char

	pushb [ebp+.keybind_shadow_color]
	push dword 1 ; scaling factor
	push dword TITLESCREEN_INSTR_COL3 - 4 + TITLESCREEN_INSTR_SHADOW_OFFSET
	pushb '3'
	call draw_char
	pushb text_color
	push dword 1 ; scaling factor
	push dword TITLESCREEN_INSTR_COL3 - 4
	pushb '3'
	call draw_char

	pushb text_color
	push dword 1 ; scaling factor
	push dword TITLESCREEN_INSTR_POS - TITLESCREEN_INSTR_HEADING_OFFSET + TITLESCREEN_INSTR_ROW_OFFSET
	push dword titlescreen_str_constrols
	call draw_str
	pushb text_color
	push dword 1 ; scaling factor
	push dword TITLESCREEN_INSTR_COL1 + TITLESCREEN_INSTR_ROW_OFFSET - 16
	push dword titlescreen_controls1
	call draw_str
	pushb text_color
	push dword 1 ; scaling factor
	push dword TITLESCREEN_INSTR_COL2 + TITLESCREEN_INSTR_ROW_OFFSET - 24
	push dword titlescreen_controls2
	call draw_str
	pushb text_color
	push dword 1 ; scaling factor
	push dword TITLESCREEN_INSTR_COL3 + TITLESCREEN_INSTR_ROW_OFFSET - 16
	push dword titlescreen_controls3
	call draw_str

	call flush_screen_buf
endfn

titlescreen_title: db "SnakeOS", 0
titlescreen_str_press: db "Press:", 0
titlescreen_str_constrols: db "Controls:", 0
titlescreen_controls1: db "WASD", 0
titlescreen_controls2: db "Arrows", 0
titlescreen_controls3: db "IJKL", 0

; ==================================================================================================
; Death Screen
; ==================================================================================================

fn setup_deathscreen
	mov byte [active_screen], DEATHSCREEN_ID

	; setup the PIT with the lowest possible frequency
	push word 65535
	call setup_pit
endfn

fn deathscreen_handle_input
.keycode: arg 1

	cmp byte [ebp+.keycode], 0x13
	je .key_r
	cmp byte [ebp+.keycode], 0x1C
	je .key_enter
	jmp .ret

	.key_r:
	pushb [num_snakes]
	call setup_gamescreen
	jmp .end_switch
	.key_enter:
	call setup_titlescreen
	.end_switch:

	.ret:
endfn

fn deathscreen_tick
	; see 'titlescreen_tick' for an explanation

	add byte [keybind_shadow_phase], KEYBIND_SHADOW_PHASE_OFFSET

	pushb text_shadow_color
	cmp byte [keybind_shadow_phase], 0
	jl .render
	pushb text_shadow_color2
	.render:
	call render_deathscreen
endfn

%define DEATHSCREEN_HEADING_SIZE 4
%define DEATHSCREEN_HEADING_POS (16 * (FB_WIDTH + 1))
%define DEATHSCREEN_HEADING_SHADOW_OFFSET (2 * (FB_WIDTH - 1))

%define DEATHSCREEN_SCORES_POS (80 * FB_WIDTH + FB_WIDTH / 2 - 28)
%define DEATHSCREEN_INSTR_POS (164 * FB_WIDTH + FB_WIDTH / 2 - 60)
%define DEATHSCREEN_INSTR_ROW_OFFSET (12 * FB_WIDTH)
%define DEATHSCREEN_INSTR_SHADOW_OFFSET (FB_WIDTH - 1)

fn render_deathscreen
.keybind_shadow_color: arg 1

	call clear_screen_buf

	pushb text_shadow_color
	push dword DEATHSCREEN_HEADING_SIZE
	push dword DEATHSCREEN_HEADING_POS + DEATHSCREEN_HEADING_SHADOW_OFFSET
	push dword deathscreen_str_gameover
	call draw_str
	pushb text_color
	push dword DEATHSCREEN_HEADING_SIZE
	push dword DEATHSCREEN_HEADING_POS
	push dword deathscreen_str_gameover
	call draw_str

	push dword DEATHSCREEN_SCORES_POS
	call render_scores

	pushb [ebp+.keybind_shadow_color]
	push dword 1 ; scaling factor
	push dword DEATHSCREEN_INSTR_POS + DEATHSCREEN_INSTR_SHADOW_OFFSET
	pushb 'R'
	call draw_char
	pushb [ebp+.keybind_shadow_color]
	push dword 1 ; scaling factor
	push dword DEATHSCREEN_INSTR_POS + DEATHSCREEN_INSTR_ROW_OFFSET + DEATHSCREEN_INSTR_SHADOW_OFFSET
	push dword deathscreen_str_enter
	call draw_str

	pushb text_color
	push dword 1 ; scaling factor
	push dword DEATHSCREEN_INSTR_POS + 6 * FB_WIDTH - 48
	push dword deathscreen_str_press
	call draw_str
	pushb text_color
	push dword 1 ; scaling factor
	push dword DEATHSCREEN_INSTR_POS
	push dword deathscreen_instr1
	call draw_str
	pushb text_color
	push dword 1 ; scaling factor
	push dword DEATHSCREEN_INSTR_POS + DEATHSCREEN_INSTR_ROW_OFFSET
	push dword deathscreen_instr2
	call draw_str

	call flush_screen_buf
endfn

deathscreen_str_gameover: db "Game Over", 0
deathscreen_str_press: db "Press", 0
deathscreen_instr1: db "R to Restart", 0
deathscreen_instr2: db "Enter for Titlescreen", 0
deathscreen_str_enter: db "Enter", 0

; ==================================================================================================
; Game Screen
; ==================================================================================================

%define MAX_SNAKES 3
%define MAX_TARGETS 2

%define WORLD_SIZE FB_HEIGHT
%define SNAKE_SIZE 8
%define TARGET_SIZE SNAKE_SIZE
; in pixels / second
%define SNAKE_SPEED 30
%define SNAKE_TURN_GAP 1
; length increase of the snake upon reaching a target
%define SNAKE_TARGET_GROWTH (2 * SNAKE_SIZE)
%define INIT_SNAKE_LEN (5 * SNAKE_SIZE)

%define SNAKE_FADEOUT_TICKS 15
%define SNAKE_HEAD_LEN (SNAKE_SIZE + 1)
%define GAMESCREEN_SCORES_POS (WORLD_SIZE + 32 + 4 * FB_WIDTH)

; ========================== [General Note - Representation of Positions] ==========================
; Positions are represented as a 32-bit number using the following bijection:
; (x, y) <-> x + y * 'FB_WIDTH'
; ========================= [General Note - Representation of Directions] ==========================
; Directions are represented as an 8-bit number using the following mapping:
; 0 <-> right
; 1 <-> up
; 2 <-> left
; 3 <-> down

fn setup_gamescreen
.num_snakes: arg 1

	mov byte [active_screen], GAMESCREEN_ID

	pushb [ebp+.num_snakes]
	call setup_snakes

	pushb MAX_TARGETS
	call setup_targets

	; setting up the PIT with a divisor results in the following frequency:
	; freq = 1193182 / divisor
	; thus, the divisor must be:
	; divisor = 1193182 / freq
	%define GAME_PIT_DIVISOR (1193182 / SNAKE_SPEED)
	static_assert {GAME_PIT_DIVISOR >= 1}
	push word GAME_PIT_DIVISOR
	call setup_pit
endfn

fn game_tick
	call update_snakes
	test eax, eax
	jnz .active_game
	call setup_deathscreen
	jmp .ret
	.active_game:
	call handle_collisions

	call render_game

	.ret:
endfn

fn game_handle_input
.keycode: arg 1

	mov al, [ebp+.keycode]
	cmp al, 0x20
	je .key_d
	cmp al, 0x11
	je .key_w
	cmp al, 0x1e
	je .key_a
	cmp al, 0x1f
	je .key_s
	cmp al, 0x26
	je .key_l
	cmp al, 0x17
	je .key_i
	cmp al, 0x24
	je .key_j
	cmp al, 0x25
	je .key_k
	cmp al, 0x4d
	je .key_right
	cmp al, 0x48
	je .key_up
	cmp al, 0x4b
	je .key_left
	cmp al, 0x50
	je .key_down
	jmp .ret

	.key_d:
	mov byte [snake1+snake_t.input_buf], 0
	jmp .end_switch
	.key_w:
	mov byte [snake1+snake_t.input_buf], 1
	jmp .end_switch
	.key_a:
	mov byte [snake1+snake_t.input_buf], 2
	jmp .end_switch
	.key_s:
	mov byte [snake1+snake_t.input_buf], 3
	jmp .end_switch
	.key_right:
	mov byte [snake2+snake_t.input_buf], 0
	jmp .end_switch
	.key_up:
	mov byte [snake2+snake_t.input_buf], 1
	jmp .end_switch
	.key_left:
	mov byte [snake2+snake_t.input_buf], 2
	jmp .end_switch
	.key_down:
	mov byte [snake2+snake_t.input_buf], 3
	jmp .end_switch
	.key_l:
	mov byte [snake3+snake_t.input_buf], 0
	jmp .end_switch
	.key_i:
	mov byte [snake3+snake_t.input_buf], 1
	jmp .end_switch
	.key_j:
	mov byte [snake3+snake_t.input_buf], 2
	jmp .end_switch
	.key_k:
	mov byte [snake3+snake_t.input_buf], 3
	.end_switch:

	.ret:
endfn

; smallest "unit" of snakes: a 1 pixel wide and 'SNAKE_SIZE' long line
struc snake_segment_t
; position of the segment
; The exact meaning of '.pos' depends on the direction '.dir': '.pos' represents
; the left edge of the segment relative to the direction of movement ('.dir'),
; i.e. if '.dir' is right, '.pos' indicates the position of the top pixel, but
; if '.dir' is left, '.pos' indicates the position of the bottom pixel.
.pos: resb 4
; see [General Note - Representation of Directions]
.dir: resb 1
endstruc
struc snake_t
	; number of segments
	; must be >= 'SNAKE_HEAD_LEN'
	.len: resb 4
	; indicates the snake's status and fadeout opacity:
	; 0 <-> snake is alive
	; 1 to 'SNAKE_FADEOUT_TICKS' <-> snake is dead and fading out
	; 'SNAKE_FADEOUT_TICKS' + 1 <-> snake is dead and invisible
	.dead: resb 1
	; temporary field to make snake movement easier, not part of the actual snake
	.next_head: resb snake_segment_t_size
	; contains '.len' segments in the order of the snake, starting from the head
	; NOTE: a snake can have at most ceil(WORLD_SIZE^2 / SNAKE_SIZE) segments
	.segments: resb (snake_segment_t_size * WORLD_SIZE * WORLD_SIZE + SNAKE_SIZE - 1) / SNAKE_SIZE

	.score: resb 2

	; see also [General Note - Representation of Directions]

	; After the snake has turned, another turn in the same direction would cause a
	; self-collision. To prevent this specific self-collision, the blocked
	; direction after a direction change is stored in '.blocked_dir'. If there is
	; no blocked directions, '.blocked_dir' contains -1.
	.blocked_dir: resb 1
	; number of ticks since the last direction change, used to reset
	; '.blocked_dir' to -1
	.last_dir_change: resb 4
	; next proposed direction by the player
	.input_buf: resb 1
endstruc

%define INIT_SNAKE_POS_Y (WORLD_SIZE - INIT_SNAKE_LEN - 2 * SNAKE_SIZE)
static_assert {INIT_SNAKE_POS_Y > 0}
%define INIT_SNAKE_POS_LEFT (INIT_SNAKE_POS_Y * FB_WIDTH + WORLD_SIZE / 4 - SNAKE_SIZE / 2)
%define INIT_SNAKE_POS_MIDDLE (INIT_SNAKE_POS_Y * FB_WIDTH + WORLD_SIZE / 2 - SNAKE_SIZE / 2)
%define INIT_SNAKE_POS_RIGHT (INIT_SNAKE_POS_Y * FB_WIDTH + 3 * WORLD_SIZE / 4 - SNAKE_SIZE / 2)
fn setup_snakes
.num_snakes: arg 1

	cmp byte [ebp+.num_snakes], 1
	je .case_1
	cmp byte [ebp+.num_snakes], 2
	je .case_2_or_3
	cmp byte [ebp+.num_snakes], 3
	je .case_2_or_3
	unreachable

	.case_1:
	push dword INIT_SNAKE_LEN
	pushb 1 ; dir
	push dword INIT_SNAKE_POS_MIDDLE
	push snake1
	call setup_snake
	jmp .end_switch

	; setup all 3 snakes, although not all are necessarily used
	.case_2_or_3:
	push dword INIT_SNAKE_LEN
	pushb 1 ; dir
	push dword INIT_SNAKE_POS_LEFT
	push snake1
	call setup_snake

	push dword INIT_SNAKE_LEN
	pushb 1 ; dir
	push dword INIT_SNAKE_POS_RIGHT
	push snake2
	call setup_snake

	push dword INIT_SNAKE_LEN
	pushb 1 ; dir
	push dword INIT_SNAKE_POS_MIDDLE
	push snake3
	call setup_snake
	.end_switch:

	mov al, [ebp+.num_snakes]
	mov [num_snakes], al
endfn
fn setup_snake
.out: arg 4
.pos: arg 4 ; position of the snake's head
.dir: arg 1 ; direction the snake is facing
.len: arg 4

	mov edi, [ebp+.out]

	mov eax, [ebp+.pos]
	lea edx, [edi+snake_t.segments]
	mov ecx, [ebp+.len]
	.loop:
		mov eax, [ebp+.pos]
		mov dword [edx + snake_segment_t.pos], eax
		mov al, [ebp+.dir]
		mov byte [edx + snake_segment_t.dir], al

		; move '.pos' 1 pixel in the opposite direction of '.dir'
		pushb [ebp+.dir]
		call get_dir_offset
		sub [ebp+.pos], eax

		add edx, snake_segment_t_size
	loop .loop

	mov eax, [ebp+.len]
	mov dword [edi+snake_t.len], eax
	mov byte [edi+snake_t.dead], 0
	mov word [edi+snake_t.score], 0
	mov byte [edi+snake_t.input_buf], -1
	mov byte [edi+snake_t.blocked_dir], -1
	mov byte [edi+snake_t.last_dir_change], 0
endfn

fn setup_targets
.num_targets: arg 1

	mov byte [num_targets], 0

	.loop:
		; NOTE: 'fill_object_buf' depends on 'num_targets'
		call fill_object_buf

		inc byte [num_targets]
		pushb [num_targets]
		call setup_target

		mov al, [num_targets]
		cmp al, [ebp+.num_targets]
	jb .loop
endfn
; NOTE: depends on 'object_buf'
fn setup_target
.target_idx: arg 1

	movzx edx, byte [ebp+.target_idx]
	.loop:
		call get_random_target_pos
		mov [targets + 4 * (edx - 1)], eax
		pushb [ebp+.target_idx]
		push eax
		call check_target_pos
		test eax, eax
	jz .loop
endfn
fn get_random_target_pos
.x: local 4
.y: local 4

	; NOTE: Because the world frame is one pixel wide, the valid range for the x
	;       and y coordinates of a target is between 1 and
	;       'WORLD_SIZE' - 'TARGET_SIZE' - 1.
	call get_random
	xor edx, edx
	mov ebx, WORLD_SIZE - TARGET_SIZE - 2
	div ebx
	inc edx
	mov [ebp+.x], edx
	call get_random
	xor edx, edx
	mov ebx, WORLD_SIZE - TARGET_SIZE - 2
	div ebx
	inc edx
	mov [ebp+.y], edx

	mov eax, [ebp+.y]
	mov ebx, FB_WIDTH
	mul ebx
	add eax, [ebp+.x]
endfn

; move alive snakes and update the fadeout opacity of dead snakes
; returns:
; - eax = 1 if the game is still active (at least on snake alive or fading out)
; - eax = 0 otherwise
fn update_snakes
.active_game: local 4

	mov dword [ebp+.active_game], 0

	mov esi, snakes
	movzx ecx, byte [num_snakes]
	.loop:
		cmp byte [esi+snake_t.dead], 0
		jne .dead_snake

		push esi
		call process_snake_input
		push esi
		call move_snake
		mov dword [ebp+.active_game], 1
		jmp .continue

		.dead_snake:
		cmp byte [esi+snake_t.dead], SNAKE_FADEOUT_TICKS
		ja .continue
		inc byte [esi+snake_t.dead]
		mov dword [ebp+.active_game], 1

		.continue:
		add esi, snake_t_size
	loop .loop

	mov eax, [ebp+.active_game]
endfn

fn move_snake
.snake: arg 4

	mov esi, [ebp+.snake]

	inc dword [esi+snake_t.last_dir_change]
	cmp dword [esi+snake_t.last_dir_change], SNAKE_SIZE + SNAKE_TURN_GAP
	jl .keep_blocked_dir
	mov byte [esi+snake_t.blocked_dir], -1
	.keep_blocked_dir:

	; move the snake head and store the result in '.next_head'
	sub esp, snake_segment_t_size
	memcpy [esp], [esi+snake_t.segments], snake_segment_t_size
	lea edi, [esi+snake_t.next_head]
	push edi
	call move_snake_segment

	; shift the snake segments, i.e. each segment is set to the segment before it
	; (the head is set to '.next_head')
	mov ecx, [esi+snake_t.len]
	lea ecx, [snake_segment_t_size * ecx]
	lea edi, [esi + snake_t.segments + ecx - 1]
	lea esi, [esi + snake_t.segments + ecx - snake_segment_t_size - 1]
	std
	rep movsb
endfn
fn move_snake_segment
.out: arg 4
.segment: arg snake_segment_t_size

	mov edi, [ebp+.out]
	memcpy [edi], [ebp+.segment], snake_segment_t_size

	pushb [ebp+.segment+snake_segment_t.dir]
	call get_dir_offset
	add dword [edi+snake_segment_t.pos], eax
endfn

fn process_snake_input
.snake: arg 4

	mov esi, [ebp+.snake]

	mov dl, [esi+snake_t.input_buf]
	cmp byte dl, -1
	je .ret
	cmp dl, [esi+snake_t.blocked_dir]
	je .ret

	mov byte [esi+snake_t.input_buf], -1

	; compute the turn direction 'dl', such that:
	; new_dir = old_dir + 'dl' (mod 4)
	sub dl, [esi+snake_t.segments+snake_segment_t.dir]
	and dl, 0b11

	test dl, dl
	jz .ret
	cmp dl, 2
	je .ret

	pushb dl
	push esi
	call turn_snake

	.ret:
endfn
; change the direction of the snake to (old_dir + '.delta_dir') mod 4
; This means that the first 'SNAKE_SIZE' segment are changed so that they face
; the new direction.
fn turn_snake
.snake: arg 4
.delta_dir: arg 1 ; assumed to be either 1 or 3
.new_dir: local 1
; the new 'SNAKE_SIZE'-th segment facing the new direction
.base_segment: local snake_segment_t_size

	mov esi, [ebp+.snake]

	mov al, [esi+snake_t.segments+snake_segment_t.dir]
	add al, [ebp+.delta_dir]
	and al, 0b11
	mov [ebp+.new_dir], al

	mov bl, [ebp+.new_dir]
	mov [ebp+.base_segment+snake_segment_t.dir], bl
	mov eax, [esi+snake_t.segments+snake_segment_t.pos]
	mov [ebp+.base_segment+snake_segment_t.pos], eax

	; when turning right, '.base_segment' is already correct, but when turning
	; left, the position of '.base_segment' needs to be adjusted
	cmp byte [ebp+.delta_dir], 3
	je .right_turn
	pushb [esi+snake_t.segments+snake_segment_t.dir]
	call get_dir_offset
	mov edx, eax
	pushb [ebp+.new_dir]
	call get_dir_offset
	add eax, edx
	mov ebx, SNAKE_SIZE - 1
	imul ebx
	sub [ebp+.base_segment+snake_segment_t.pos], eax
	.right_turn:

	; '.base_segment' now contains the correctly facing 'SNAKE_SIZE'-th segment,
	; the remaining segments can be obtained by moving '.base_segment' one step in
	; its direction.
	lea edi, [esi+snake_t.segments + (SNAKE_SIZE - 1) * snake_segment_t_size]
	mov ecx, SNAKE_SIZE
	.loop:
		memcpy [edi], [ebp+.base_segment], snake_segment_t_size

		sub esp, snake_segment_t_size
		memcpy [esp], [ebp+.base_segment], snake_segment_t_size
		lea edx, [ebp+.base_segment]
		push edx
		call move_snake_segment

		sub edi, snake_segment_t_size
	loop .loop

	mov al, [ebp+.new_dir]
	add al, [ebp+.delta_dir]
	and al, 0b11
	mov byte [esi+snake_t.blocked_dir], al
	mov dword [esi+snake_t.last_dir_change], 0
endfn

; extend the snake by appending the last segment '.len_inc' times
fn extend_snake
.snake: arg 4
.len_inc: arg 4

	mov esi, [ebp+.snake]

	mov eax, [esi+snake_t.len]
	lea eax, [snake_segment_t_size * eax]
	lea edi, [esi+snake_t.segments + eax]
	mov ecx, [ebp+.len_inc]
	.loop:
		memcpy [edi], [edi-snake_segment_t_size], snake_segment_t_size
		add edi, snake_segment_t_size
	loop .loop

	mov eax, [ebp+.len_inc]
	add [esi+snake_t.len], eax
endfn

; ==================================================================================================
; Collisions
; ==================================================================================================

; 'MAX_TARGETS' must be less than 255, because the the IDs used for targets
; range from 1 to 'MAX_TARGETS', but the ID 255 is already used for blocking
; objects.
static_assert {MAX_TARGETS < 255}
%define BLOCKER_ID 255

fn handle_collisions
	call fill_object_buf

	mov esi, snakes
	movzx ecx, byte [num_snakes]
	.loop:
		cmp byte [esi+snake_t.dead], 0
		jne .continue
		push esi
		call handle_snake_collisions
		.continue:
		add esi, snake_t_size
	loop .loop
endfn

fn fill_object_buf
	; clear object buffer
	xor al, al
	mov ecx, FB_SIZE
	mov edi, object_buf
	cld
	rep stosb

	; NOTE: The snakes must be added to the object buffer *after* the targets to
	;       ensure that any targets inside the snake are overdrawn. This is
	;       necessary because when a target is reached, it can be placed at the
	;       same position again, causing it to be inside the snake on the next
	;       frame.

	mov esi, targets
	mov dl, 1
	.targets_loop:
		cmp dl, byte [num_targets]
		ja .end_targets_loop

		push dword object_buf
		pushb dl
		push dword [esi]
		call draw_target

		add esi, 4
		inc dl
	jmp .targets_loop
	.end_targets_loop:

	mov esi, snakes
	movzx ecx, byte [num_snakes]
	.snakes_loop:
		cmp byte [esi+snake_t.dead], 0
		jne .continue

		; NOTE: The collision detection checks every position of the first segment
		;       for colliding objects. To prevent detecting the snake's own first
		;       segment as a collision, it's not added to the object buffer.
		pushb BLOCKER_ID
		push dword [esi+snake_t.len]
		push dword 1 ; skip first segment
		push dword object_buf
		push esi
		call draw_snake_segments_in_range

		.continue:
		add esi, snake_t_size
	loop .snakes_loop

	push dword object_buf
	pushb BLOCKER_ID
	call draw_world_frame
endfn

fn handle_snake_collisions
.snake: arg 4

	mov esi, [ebp+.snake]

	mov edx, [esi+snake_t.segments+snake_segment_t.pos]
	pushb [esi+snake_t.segments+snake_segment_t.dir]
	dec byte [esp]
	and byte [esp], 0b11
	call get_dir_offset
	mov ebx, eax

	; loop over every position of the first segment to check for collisions
	mov ecx, SNAKE_SIZE
	.loop:
		mov al, [object_buf + edx]
		test al, al
		jz .continue

		cmp al, BLOCKER_ID
		jne .skip_blocker_coll_handler
		mov byte [esi+snake_t.dead], 1
		; retract the colliding segment
		memcpy [esi+snake_t.segments], [esi+snake_t.segments+snake_segment_t_size], snake_segment_t_size
		.skip_blocker_coll_handler:

		cmp al, byte [num_targets]
		ja .skip_target_coll_handler
		; reposition the colliding target
		pushb al
		call setup_target
		call fill_object_buf

		push dword SNAKE_TARGET_GROWTH
		push esi
		call extend_snake
		inc word [esi+snake_t.score]
		.skip_target_coll_handler:

		.continue:
		add edx, ebx
	loop .loop
endfn

; checks whether '.pos' is a valid position to place the target '.target_idx'
; A position is considered valid iff the target wouldn't collide with another
; object.
fn check_target_pos
.pos: arg 4
.target_idx: arg 1

	mov dl, [ebp+.target_idx]

	mov eax, [ebp+.pos]
	lea edi, [object_buf + eax]

	mov cl, TARGET_SIZE
	.vert_loop:
		mov ch, TARGET_SIZE
		.hor_loop:
			cmp byte [edi], 0
			je .continue
			cmp byte [edi], dl
			jne .ret_false
			.continue:
			inc edi
			dec ch
		jnz .hor_loop
		add edi, FB_WIDTH - TARGET_SIZE
		dec cl
	jnz .vert_loop

	mov eax, 1
	jmp .ret
	.ret_false:
	xor eax, eax
	.ret:
endfn

; ==================================================================================================
; Rendering
; ==================================================================================================

fn render_game
	call clear_screen_buf

	push dword screen_buf
	pushb frame_color
	call draw_world_frame

	push dword GAMESCREEN_SCORES_POS
	call render_scores

	call render_snakes
	call render_targets

	call flush_screen_buf
endfn

; render snakes ordered from most transparent to least transparent
; (this prevents issues when one snake moves over another snake that is fading
; out)
fn render_snakes
; auxiliary array of 3 words, where each entry consists of:
; - first byte: snake index
; - second byte: the 'snake_t.dead' value of the corresponding snake
.snake_array: local 6

	xor al, al
	lea edi, [ebp+.snake_array]
	mov ecx, 6
	cld
	rep stosb

	mov esi, snakes
	lea edi, [ebp+.snake_array]
	xor cl, cl
	.fill_array_loop:
		mov [edi], cl
		mov al, [esi+snake_t.dead]
		mov [edi + 1], al

		add esi, snake_t_size
		add edi, 2
		inc cl
		cmp cl, [num_snakes]
	jb .fill_array_loop

	; sort '.snake_array' in descending order
	; NOTE: Because the 'snake_t.dead' value is the MSB of every element, the
	;       array is sorted from most transparent to least transparent snake.
	%macro _compare_and_xchg 2
		mov ax, [%1]
		mov bx, [%2]
		cmp ax, bx
		jae %%skip
		mov [%1], bx
		mov [%2], ax
		%%skip:
	%endmacro
	_compare_and_xchg {ebp+.snake_array}, {ebp+.snake_array + 2}
	_compare_and_xchg {ebp+.snake_array}, {ebp+.snake_array + 4}
	_compare_and_xchg {ebp+.snake_array + 2}, {ebp+.snake_array + 4}

	lea esi, [ebp+.snake_array]
	movzx ecx, byte [num_snakes]
	.render_loop:
		; skip completely dead snakes
		cmp byte [esi + 1], SNAKE_FADEOUT_TICKS
		ja .continue

		movzx eax, byte [esi]
		mov ebx, snake_t_size
		mul ebx
		lea edi, [snakes + eax]

		mov al, [esi]
		; there are 'SNAKE_FADEOUT_TICKS + 1' colors for each snake
		mov bl, SNAKE_FADEOUT_TICKS + 1
		mul bl
		add al, snake_head_colors

		pushb al
		push edi
		call render_snake

		.continue:
		add esi, 2
	loop .render_loop
endfn
fn render_snake
.snake: arg 4
.head_color: arg 1

	mov esi, [ebp+.snake]
	mov bl, [esi+snake_t.dead]

	; draw snake head (segments 0 to 'SNAKE_HEAD_LEN' - 1)
	pushb [ebp+.head_color]
	add [esp], bl ; fadeout
	push dword SNAKE_HEAD_LEN
	push dword 0
	push dword screen_buf
	push esi
	call draw_snake_segments_in_range

	; draw snake tail (segments SNAKE_HEAD_LEN to 'snake_t.len' - 1)
	pushb snake_body_colors
	add [esp], bl ; fadeout
	push dword [esi+snake_t.len]
	push dword SNAKE_HEAD_LEN
	push dword screen_buf
	push esi
	call draw_snake_segments_in_range
endfn

; draw snake segments from '.start_idx' to '.end_idx' - 1
fn draw_snake_segments_in_range
.snake: arg 4
.out_buf: arg 4
.start_idx: arg 4
.end_idx: arg 4
.color: arg 1

	mov esi, [ebp+.snake]

	mov eax, [ebp+.start_idx]
	lea eax, [snake_segment_t_size * eax]
	lea edx, [esi+snake_t.segments + eax]

	mov ecx, [ebp+.end_idx]
	sub ecx, [ebp+.start_idx]
	cmp ecx, 0
	jle .ret
	.render_loop:
		pushb [ebp+.color]
		push dword [ebp+.out_buf]
		sub esp, snake_segment_t_size
		memcpy [esp], [edx], snake_segment_t_size
		call draw_snake_segment

		add edx, snake_segment_t_size
	loop .render_loop

	.ret:
endfn
fn draw_snake_segment
.segment: arg snake_segment_t_size
.out_buf: arg 4
.color: arg 1

	mov edi, [ebp+.out_buf]
	add edi, [ebp+.segment+snake_segment_t.pos]

	; calculate the offset to get to the next pixel of the segment
	pushb [ebp+.segment+snake_segment_t.dir]
	; rotate the dir by -pi/2
	dec byte [esp]
	and byte [esp], 0b11
	call get_dir_offset
	mov ebx, eax

	mov ecx, SNAKE_SIZE
	mov al, [ebp+.color]
	.loop:
		mov [edi], al
		add edi, ebx
	loop .loop
endfn

%define SCORES_ROW_OFFSET (15 * FB_WIDTH)
score_row_headings:
db "P1:", 0
db "P2:", 0
db "P3:", 0
score_row_heading_len: equ 4
scores_heading: db "Scores:", 0
fn render_scores
.pos: arg 4

	mov edi, [ebp+.pos]

	pushb text_color
	push dword 1 ; scaling factor
	push edi
	push dword scores_heading
	call draw_str
	add edi, SCORES_ROW_OFFSET

	mov esi, snakes
	xor ecx, ecx
	.snakes_loop:
		pushb text_color
		push dword 1 ; scaling factor
		push edi
		lea eax, [score_row_headings + ecx * score_row_heading_len]
		push eax
		call draw_str

		push dword score_num_buf
		push word [esi+snake_t.score]
		call num_to_str

		pushb snake_score_colors
		add [esp], cl
		push dword 1 ; scaling factor
		push edi
		add dword [esp], score_row_heading_len * 8 - 4
		push dword score_num_buf
		call draw_str

		add edi, SCORES_ROW_OFFSET
		add esi, snake_t_size
		inc cl
		cmp cl, [num_snakes]
	jb .snakes_loop
endfn

fn render_targets
	mov esi, targets
	movzx ecx, byte [num_targets]
	.targets_loop:
		push dword screen_buf
		pushb target_color
		push dword [esi]
		call draw_target
		add esi, 4
	loop .targets_loop
endfn
fn draw_target
.pos: arg 4
.color: arg 1
.out_buf: arg 4

	mov edi, [ebp+.out_buf]
	add edi, [ebp+.pos]

	mov bl, [ebp+.color]
	mov cl, TARGET_SIZE
	.vert_loop:
		mov ch, TARGET_SIZE
		.hor_loop:
			mov [edi], bl
			inc edi
			dec ch
		jnz .hor_loop
		add edi, FB_WIDTH - TARGET_SIZE
		dec cl
	jnz .vert_loop
endfn

fn draw_world_frame
.color: arg 1
.out_buf: arg 4

	mov bl, [ebp+.color]

	mov edi, [ebp+.out_buf]
	mov ecx, WORLD_SIZE
	.hor_loop:
		mov byte [edi], bl
		mov byte [edi + FB_WIDTH * (WORLD_SIZE - 1)], bl
		inc edi
	loop .hor_loop

	mov edi, [ebp+.out_buf]
	mov ecx, WORLD_SIZE
	.vert_loop:
		mov byte [edi], bl
		mov byte [edi + WORLD_SIZE - 1], bl
		add edi, FB_WIDTH
	loop .vert_loop
endfn

; get offset to move one step in the direction '.dir'
fn get_dir_offset
.dir: arg 1

	cmp byte [ebp+.dir], 0
	je .right_dir
	cmp byte [ebp+.dir], 1
	je .up_dir
	cmp byte [ebp+.dir], 2
	je .left_dir
	cmp byte [ebp+.dir], 3
	je .down_dir
	unreachable
	.right_dir:
	mov eax, 1
	jmp .ret
	.up_dir:
	mov eax, -FB_WIDTH
	jmp .ret
	.left_dir:
	mov eax, -1
	jmp .ret
	.down_dir:
	mov eax, FB_WIDTH

	.ret:
endfn

; ==================================================================================================
; Color Palette
; ==================================================================================================

; NOTE: Colors are represented using 18-bit RGB, i.e. each color component must
;       range from 0 to 63.
palette:
	db 0, 0, 0 ; black

	text_shadow_color_ptr:
	frame_color_ptr: db 13, 2, 22
	target_color_ptr: db 44, 6, 6
	snake_score_colors_ptr:
	db 16, 28, 15
	db 15, 16, 28
	db 28, 15, 16

	text_shadow_color2_ptr:
	db 30, 30, 30
	text_color_ptr: db 42, 42, 42

	; NOTE: the fadeout colors are calculated in 'setup_palette'
	snake_body_colors_ptr: db 30, 30, 30
	times 3 * SNAKE_FADEOUT_TICKS db 0
	snake_head_colors_ptr:
	db 9, 20, 8
	times 3 * SNAKE_FADEOUT_TICKS db 0
	db 8, 9, 20
	times 3 * SNAKE_FADEOUT_TICKS db 0
	db 20, 8, 9
	times 3 * SNAKE_FADEOUT_TICKS db 0
static_assert {($ - palette) <= 255 * 3}

frame_color: equ (frame_color_ptr - palette) / 3
target_color: equ (target_color_ptr - palette) / 3
snake_score_colors: equ (snake_score_colors_ptr - palette) / 3
snake_body_colors: equ (snake_body_colors_ptr - palette) / 3
snake_head_colors: equ (snake_head_colors_ptr - palette) / 3

text_color: equ (text_color_ptr - palette) / 3
; The color 0x07 is assumed to be a good color for text, so it should remain the
; text color even after the custom palette has been set.
static_assert {text_color == 0x07}
text_shadow_color: equ (text_shadow_color_ptr - palette) / 3
text_shadow_color2: equ (text_shadow_color2_ptr - palette) / 3

fn setup_palette
	push dword snake_body_colors_ptr
	call calculate_snake_fadeout_colors

	mov ecx, MAX_SNAKES
	mov esi, snake_head_colors_ptr
	.loop:
		push esi
		call calculate_snake_fadeout_colors
		add esi, 3 * (SNAKE_FADEOUT_TICKS + 1)
	loop .loop

	push dword palette
	call set_vga_palette
endfn
; calculate the fadeout colors
; '.colors_ptr' should point to an array of 'SNAKE_FADEOUT_TICKS' + 1 colors.
; The first color in the array is used as the base color, while the following
; entries are filled with the fadeout colors.
fn calculate_snake_fadeout_colors
.colors_ptr: arg 4
.base_color: local 3
.loop_counter: local 1

	mov edi, [ebp+.colors_ptr]
	memcpy [ebp+.base_color], [edi], 3

	mov byte [ebp+.loop_counter], SNAKE_FADEOUT_TICKS
	.colors_loop:
		mov ecx, 3
		.color_components_loop:
			mov al, [ebp+.base_color + ecx - 1]
			mul byte [ebp+.loop_counter]
			mov bl, SNAKE_FADEOUT_TICKS + 1
			div bl
			mov [edi + ecx - 1], al
		loop .color_components_loop

		add edi, 3
		dec byte [ebp+.loop_counter]
	jnz .colors_loop
endfn

section bss
; contains the ID of the currently active screen
; The following IDs are recognized:
; 'TITLESCREEN_ID', 'GAMESCREEN_ID', 'DEATHSCREEN_ID'
active_screen: resb 1

keybind_shadow_phase: resb 1

; maps each pixel to the ID of the object occupying it, with the possible ID's
; being:
; 0 <-> empty
; 1 to 'MAX_TARGETS' <-> target with corresponding index
; 'BLOCKER_ID' <-> blocking object (world frame or body of a snake)
object_buf: resb FB_SIZE

num_snakes: resb 1
snakes:
snake1: resb snake_t_size
snake2: resb snake_t_size
snake3: resb snake_t_size

num_targets: resb 1
; contains the position of every target,
; see [General Note - Representation of Positions]
targets:
resb 4 * MAX_TARGETS

score_num_buf: resb 6
