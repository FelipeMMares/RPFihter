extends State


@export var landing_state: StringName = &"Idle"

@export_group("Ataques aéreos")

@export var light_punch_state: StringName = &"AirLightPunch"
@export var high_punch_state: StringName = &"AirHighPunch"
@export var kick_state: StringName = &"AirKick"
@export var low_kick_state: StringName = &"AirLowKick"


func _enter() -> void:
	play_animation.emit(&"Jump", false)


func _physics_process(_delta: float) -> void:
	var character := _get_character()

	if character == null:
		return

	# Somente o Player possui PlayerControls.
	# Os ataques do Dummy são decididos pelo DummyAI.
	if player_controls != null:
		var horizontal_direction: float = Input.get_axis(
			player_controls.left,
			player_controls.right
		)

		move.emit(
			Vector2(
				horizontal_direction,
				0.0
			)
		)

		# Não permite iniciar um ataque aéreo já no chão.
		if not character.is_on_floor():
			if _try_air_attack():
				return

	# Caso não tenha atacado, Jump retorna para Idle
	# normalmente quando tocar no chão.
	if (
		character.is_on_floor()
		and character.velocity.y >= 0.0
	):
		transition_to.emit(landing_state)


func _try_air_attack() -> bool:
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
	var current_node: Node = get_parent()

	while current_node != null:
		if current_node is CharacterBody2D:
			return current_node as CharacterBody2D

		current_node = current_node.get_parent()

	return null
