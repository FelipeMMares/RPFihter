extends State

func _enter() -> void:
	move.emit(Vector2.ZERO)
	play_animation.emit(name, false)

	print("Entrou em Victory")


func _physics_process(_delta: float) -> void:
	# Permanece neste estado até o FightManager forçar Idle.
	pass


func _animation_finished() -> void:
	# Não faz transição automática.
	pass
