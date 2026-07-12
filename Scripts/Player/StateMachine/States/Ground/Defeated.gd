extends State

func _enter() -> void:
	move.emit(Vector2.ZERO)
	play_animation.emit(name, false)

	print("Entrou em Defeated")


func _physics_process(_delta: float) -> void:
	pass


func _animation_finished() -> void:
	pass
