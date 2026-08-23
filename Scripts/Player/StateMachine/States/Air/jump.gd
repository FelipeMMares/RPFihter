extends State


@export var landing_state: StringName = &"Idle"

@export_group("Ataques aéreos")

@export var light_punch_state: StringName = &"AirLightPunch"
@export var high_punch_state: StringName = &"AirHighPunch"
@export var kick_state: StringName = &"AirKick"
@export var low_kick_state: StringName = &"AirLowKick"


var _has_left_ground: bool = false


func _enter() -> void:
	_has_left_ground = false

	play_animation.emit(
		&"Jump",
		false
	)


func _physics_process(
	_delta: float
) -> void:
	var character := _get_character()

	if character == null:
		return

	# Esta parte vale para humano e CPU.
	if not character.is_on_floor():
		_has_left_ground = true

	# Somente o humano lê o controle diretamente.
	if (
		player_input_enabled
		and player_controls != null
	):
		var horizontal_direction: float = (
			Input.get_axis(
				player_controls.left,
				player_controls.right
			)
		)

		move.emit(
			Vector2(
				horizontal_direction,
				0.0
			)
		)

		if _has_left_ground:
			# Especiais aéreos têm prioridade
			# sobre ataques normais aéreos.
			if _try_air_special():
				return

			if _try_air_attack():
				return

	# Humano e CPU precisam detectar aterrissagem.
	if (
		_has_left_ground
		and character.is_on_floor()
		and character.velocity.y >= 0.0
	):
		move.emit(
			Vector2.ZERO
		)

		transition_to.emit(
			landing_state
		)


func _try_air_attack() -> bool:
	if player_controls == null:
		return false

	if Input.is_action_just_pressed(
		player_controls.light_punch
	):
		transition_to.emit(light_punch_state)
		return true

	if Input.is_action_just_pressed(
		player_controls.high_punch
	):
		transition_to.emit(high_punch_state)
		return true

	if Input.is_action_just_pressed(
		player_controls.kick
	):
		transition_to.emit(kick_state)
		return true

	if Input.is_action_just_pressed(
		player_controls.low_kick
	):
		transition_to.emit(low_kick_state)
		return true

	return false


func _get_character() -> CharacterBody2D:
	return (
		get_parent().get_parent()
		as CharacterBody2D
	)

func _try_air_special() -> bool:
	if command_parser == null:
		return false

	var move_name: String = (
		command_parser.get_current_special_move()
	)

	if move_name.is_empty():
		return false

	# Ignora combos normais.
	if not command_parser.is_special_move(
		move_name
	):
		return false

	var air_state: StringName = &""

	# Traduz o comando terrestre para
	# sua versão aérea.
	match StringName(move_name):

		&"SoulFist":
			air_state = &"AirSoulFist"

		_:
			# Qualquer outro especial é
			# proibido durante Jump.
			return false

	var character := _get_character()

	if character == null:
		return false

	if not character.has_method(
		"request_special_attack"
	):
		return false

	print(
		"Especial aéreo reconhecido | ",
		move_name,
		" -> ",
		air_state
	)

	return bool(
		character.call(
			"request_special_attack",
			air_state
		)
	)
