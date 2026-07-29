extends State


@export var next_state: StringName = &"Jump"


func _enter() -> void:
	var horizontal_direction: float = 0.0

	# Para o Player, lê a direção pressionada no
	# mesmo momento em que o salto começa.
	if player_controls != null:
		horizontal_direction = Input.get_axis(
			player_controls.left,
			player_controls.right
		)

		move.emit(
			Vector2(
				horizontal_direction,
				0.0
			)
		)

	# Para o Dummy, não enviamos Vector2.ZERO.
	# Assim, uma direção definida pela DummyAI
	# pode ser preservada.
	jump.emit()

	play_animation.emit(
		&"StartJump",
		false
	)


func _animation_finished() -> void:
	transition_to.emit(next_state)
