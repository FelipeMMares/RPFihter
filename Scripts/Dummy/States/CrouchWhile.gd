extends State


func _enter() -> void:
	move.emit(Vector2.ZERO)

	# Proteção adicional caso o estado tenha sido
	# acessado diretamente.
	set_crouching_hurtbox(true)

	play_animation.emit(
		"CrouchWhile",
		false
	)


func _physics_process(_delta: float) -> void:
	move.emit(Vector2.ZERO)
