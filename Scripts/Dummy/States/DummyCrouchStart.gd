extends State


@export var next_state: StringName = &"CrouchWhile"


func _enter() -> void:
	move.emit(Vector2.ZERO)
	play_animation.emit("CrouchStart", false)

	print("Dummy iniciou o agachamento.")


func _animation_finished() -> void:
	transition_to.emit(next_state)
