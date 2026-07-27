extends State


@export var next_state: StringName = &"CrouchWhile"


func _enter() -> void:
	move.emit(Vector2.ZERO)

	set_crouching_hurtbox(true)

	play_animation.emit(
		"CrouchStart",
		false
	)


func _animation_finished() -> void:
	transition_to.emit(next_state)
