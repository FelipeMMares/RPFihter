extends State


@export var next_state: StringName = &"Jump"


func _enter() -> void:
	print(name, ": solicitando salto")

	# Com move() corrigido, isso para somente o eixo X.
	move.emit(Vector2.ZERO)

	# Chama jump() no CharacterBody2D.
	jump.emit()

	play_animation.emit("StartJump", false)


func _animation_finished() -> void:
	transition_to.emit(next_state)
