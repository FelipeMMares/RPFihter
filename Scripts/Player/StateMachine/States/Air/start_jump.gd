extends State


@export var jump_state: StringName = &"Jump"
@export var cancel_state: StringName = &"Idle"


func _enter() -> void:
	# Humano fica parado durante a preparação
	# do salto.
	if player_input_enabled:
		move.emit(
			Vector2.ZERO
		)

	# IMPORTANTE:
	# não chama jump.emit() aqui.

	play_animation.emit(
		&"StartJump",
		false
	)


func _physics_process(
	_delta: float
) -> void:
	if not player_input_enabled:
		return

	if player_controls == null:
		return

	# Enquanto ainda estamos no chão,
	# um toque de ↑ pode fazer parte
	# de um comando especial.
	if check_special_move():
		return


func _animation_finished() -> void:
	# CPU não possui um botão físico ↑
	# para manter pressionado.
	if not player_input_enabled:
		jump.emit()

		transition_to.emit(
			jump_state
		)

		return

	if player_controls == null:
		transition_to.emit(
			cancel_state
		)
		return

	# ↑ foi apenas tocado.
	if not player_controls.is_jump_held():
		move.emit(
			Vector2.ZERO
		)

		transition_to.emit(
			cancel_state
		)

		return

	# ↑ permaneceu pressionado até o final
	# de StartJump. Agora o salto realmente
	# acontece.

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

	jump.emit()

	transition_to.emit(
		jump_state
	)
