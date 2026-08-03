extends State


@export var jump_state: StringName = &"Jump"


func _enter() -> void:
	# Somente o Player lê o teclado aqui.
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

	# Precisa ficar fora do bloco player_controls.
	# O Dummy também deve receber o impulso vertical.
	jump.emit()

	play_animation.emit(
		&"StartJump",
		false
	)


func _animation_finished() -> void:
	transition_to.emit(jump_state)
