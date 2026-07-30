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


func _physics_process(_delta: float) -> void:
	var character := _get_character()

	if character == null:
		return

	# Impede que o estado considere que aterrissou
	# antes de realmente sair do chão.
	if not character.is_on_floor():
		_has_left_ground = true

	if player_controls != null:
		var horizontal_direction: float = Input.get_axis(
			player_controls.left,
			player_controls.right
		)

		# Mantém o controle horizontal durante o salto.
		move.emit(
			Vector2(
				horizontal_direction,
				0.0
			)
		)

		if _has_left_ground:
			if _try_air_attack():
				return

	if (
		_has_left_ground
		and character.is_on_floor()
		and character.velocity.y >= 0.0
	):
		move.emit(Vector2.ZERO)
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
