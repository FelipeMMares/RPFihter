extends State


@export var next_state: StringName = &"Idle"


func _enter() -> void:
	move.emit(Vector2.ZERO)
	play_animation.emit("CrouchEnd", false)

	print("Dummy está saindo do agachamento.")


func _animation_finished() -> void:
	transition_to.emit(next_state)
