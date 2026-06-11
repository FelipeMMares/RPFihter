extends State

func _physics_process(delta: float) -> void:
	
	var direction : float = \
	Input.get_axis(player_controls.left, player_controls.right)
	
	if command_parser.get_current_special_move() == "test":
		printerr("funfou!")
	
	if direction != 0:
		play_animation.emit(name, direction < 0)
		move.emit(Vector2(direction, 0))
	
	else:
		move.emit(Vector2.ZERO)
		transition_to.emit("Idle")
