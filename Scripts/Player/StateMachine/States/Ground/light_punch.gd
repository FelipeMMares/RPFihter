extends AttackState

var _last_buffer_size: int = -1
var _parser_error_printed: bool = false

# Nomes exatos das animações no SpriteFrames.
const COMBO_ANIMATIONS: Array[StringName] = [
	&"LightPunch",
	&"LightPunch2",
	&"LightPunch3"
]


# Frames em que a hitbox começa em cada animação.
const ACTIVE_START_FRAMES: Array[int] = [
	1, # LightPunch
	2, # LightPunch2
	2  # LightPunch3
]


# Frames em que a hitbox termina em cada animação.
const ACTIVE_END_FRAMES: Array[int] = [
	3, # LightPunch
	4, # LightPunch2
	4  # LightPunch3
]


# Frame mínimo para cancelar a animação atual e iniciar a próxima.
const COMBO_TRANSITION_FRAMES: Array[int] = [
	2, # LightPunch  -> LightPunch2
	2, # LightPunch2 -> LightPunch3
	0  # LightPunch3 não possui continuação
]


# Intervalo máximo entre os inputs do combo.
const COMBO_INPUT_GAP: int = 60


var combo_stage: int = 0

var second_attack_buffered: bool = false
var third_attack_buffered: bool = false

var state_active: bool = false


@onready var animated_sprite: AnimatedSprite2D = (
	get_parent()
	.get_parent()
	.get_node_or_null("AnimatedSprite2D")
	as AnimatedSprite2D
)


func _enter() -> void:
	
	print("")
	print("================================")
	print("ENTROU NO LIGHTPUNCH.GD")
	print("command_parser: ", command_parser)
	print("player_controls: ", player_controls)
	print("================================")

	state_active = true
	combo_stage = 0
	second_attack_buffered = false
	third_attack_buffered = false

	_apply_hitbox_frames(0)

	super._enter()
	
	state_active = true

	combo_stage = 0
	second_attack_buffered = false
	third_attack_buffered = false

	# Configura os frames ativos do primeiro soco.
	_apply_hitbox_frames(0)

	# O AttackState:
	# - desativa a hitbox;
	# - toca a animação com o nome do nó, LightPunch.
	super._enter()

	print("Combo: iniciou LightPunch")


func _physics_process(delta: float) -> void:
	if not state_active:
		return

	super._physics_process(delta)

	if command_parser == null:
		if not _parser_error_printed:
			_parser_error_printed = true
			printerr(
				"LightPunch: command_parser está NULO."
			)
		return

	if command_parser.input_buffer == null:
		if not _parser_error_printed:
			_parser_error_printed = true
			printerr(
				"LightPunch: input_buffer está NULO."
			)
		return

	var current_buffer_size: int = (
		command_parser.input_buffer.buffer.size()
	)

	# Só imprime quando um novo input entra ou sai do buffer.
	if current_buffer_size != _last_buffer_size:
		_last_buffer_size = current_buffer_size

		var input_names: Array[String] = []

		for item in command_parser.input_buffer.buffer:
			input_names.append(item.action_name)

		print(
			"BUFFER DURANTE LIGHTPUNCH: ",
			input_names
		)

		var detected_move: String = (
			command_parser.peek_current_move(60)
		)

		print(
			"PEEK RETORNOU: '",
			detected_move,
			"'"
		)

	_read_combo_command()

	if animated_sprite == null:
		return

	var current_frame: int = animated_sprite.frame

	_try_advance_combo(current_frame)


func _read_combo_command() -> void:
	var detected_move: String = command_parser.peek_current_move(
		COMBO_INPUT_GAP
	)

	if detected_move.is_empty():
		return

	match detected_move:
		"light_punch_2":
			if combo_stage == 0 and not second_attack_buffered:
				second_attack_buffered = true

				print(
					"Combo: segundo LightPunch armazenado"
				)

		"light_punch_3":
			if not second_attack_buffered:
				second_attack_buffered = true

			if not third_attack_buffered:
				third_attack_buffered = true

				print(
					"Combo: terceiro LightPunch armazenado"
				)


func _try_advance_combo(current_frame: int) -> void:
	match combo_stage:
		0:
			if (
				second_attack_buffered
				and current_frame
				>= COMBO_TRANSITION_FRAMES[0]
			):
				_start_combo_stage(1)

		1:
			if (
				third_attack_buffered
				and current_frame
				>= COMBO_TRANSITION_FRAMES[1]
			):
				_start_combo_stage(2)


func _start_combo_stage(new_stage: int) -> void:
	if new_stage < 0:
		return

	if new_stage >= COMBO_ANIMATIONS.size():
		return

	if new_stage == combo_stage:
		return

	# Desliga a hitbox da animação anterior.
	if hitbox != null:
		hitbox.disable()

	_hitbox_active = false

	combo_stage = new_stage

	# Altera os frames ativos herdados do AttackState.
	_apply_hitbox_frames(combo_stage)

	var animation_name: StringName = (
		COMBO_ANIMATIONS[combo_stage]
	)

	print(
		"Combo: iniciando etapa ",
		combo_stage + 1,
		" | animação: ",
		animation_name,
		" | hitbox ativa entre os frames ",
		active_start_frame,
		" e ",
		active_end_frame
	)

	play_animation.emit(
		String(animation_name),
		false
	)


func _apply_hitbox_frames(stage: int) -> void:
	if stage < 0:
		return

	if stage >= ACTIVE_START_FRAMES.size():
		return

	active_start_frame = ACTIVE_START_FRAMES[stage]
	active_end_frame = ACTIVE_END_FRAMES[stage]


func _animation_finished() -> void:
	if not state_active:
		return

	# Segurança: desliga a hitbox quando cada animação terminar.
	if hitbox != null:
		hitbox.disable()

	_hitbox_active = false

	match combo_stage:
		0:
			# Se o segundo input foi registrado perto do final,
			# inicia a segunda animação.
			if second_attack_buffered:
				_start_combo_stage(1)
				return

		1:
			# Se o terceiro input foi registrado perto do final,
			# inicia a terceira animação.
			if third_attack_buffered:
				_start_combo_stage(2)
				return

		2:
			# A terceira animação conclui o combo.
			pass

	# Sem continuação, usa o comportamento original:
	# desativa a hitbox e retorna para next_state.
	super._animation_finished()


func _exit() -> void:
	state_active = false

	second_attack_buffered = false
	third_attack_buffered = false

	super._exit()

	# A sequência só é apagada quando o combo inteiro termina.
	if command_parser != null:
		command_parser.clear_buffer()
