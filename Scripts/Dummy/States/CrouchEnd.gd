extends State


@export var next_state: StringName = &"Idle"


func _enter() -> void:
	move.emit(Vector2.ZERO)

	# Continua com a forma agachada enquanto
	# ainda está levantando.
	set_crouching_hurtbox(true)

	play_animation.emit(
		"CrouchEnd",
		false
	)


func _animation_finished() -> void:
	set_crouching_hurtbox(false)

	transition_to.emit(next_state)
