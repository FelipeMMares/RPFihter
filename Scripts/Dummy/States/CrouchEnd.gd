extends State


@export var next_state: StringName = &"Idle"


func _enter() -> void:
	move.emit(
		Vector2.ZERO
	)

	set_crouching_hurtbox(
		true
	)

	play_animation.emit(
		&"CrouchEnd",
		false
	)


func _physics_process(
	_delta: float
) -> void:
	if not player_input_enabled:
		return

	if check_special_move():
		set_crouching_hurtbox(
			false
		)
		return


func _animation_finished() -> void:
	set_crouching_hurtbox(
		false
	)

	transition_to.emit(
		next_state
	)
