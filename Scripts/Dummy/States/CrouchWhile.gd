extends State


func _enter() -> void:
	move.emit(Vector2.ZERO)
	play_animation.emit("CrouchWhile", false)

	print("Dummy está mantendo o agachamento.")


func _physics_process(_delta: float) -> void:
	# Permanece parado enquanto a IA mantém este estado.
	move.emit(Vector2.ZERO)
