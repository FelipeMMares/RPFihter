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
	if Input.is_action_just_pressed(player_controls.light_punch):
		transition_to.emit("LightPunch")
		return

	if Input.is_action_just_pressed(player_controls.high_punch):
		transition_to.emit("HighPunch")
		return

	if Input.is_action_just_pressed(player_controls.kick):
		transition_to.emit("Kick")
		return

	if Input.is_action_just_pressed(player_controls.low_kick):
		transition_to.emit("LowKick")
		return
