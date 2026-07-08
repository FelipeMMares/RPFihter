extends State

func _enter() -> void:
	play_animation.emit(name, false)

func _physics_process(delta: float) -> void:
	move.emit(Vector2.ZERO)
	check_special_move()
	if player_controls.is_walking():
		transition_to.emit("Walk")
		
	if player_controls.just_crouched():
		transition_to.emit("Crouch")
	
	if player_controls.is_jumping():
		print("PEDIU PULO")
		transition_to.emit("StartJump")
