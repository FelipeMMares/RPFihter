extends State

func _physics_process(delta: float) -> void:
	check_special_move()
	
	
	var direction : float = \
	Input.get_axis(player_controls.left, player_controls.right)
	
	var detected_move := command_parser.get_current_special_move()

	if detected_move != "":
		print("🔥 Movimento detectado:", detected_move)

		match detected_move:
			"teste_combo":
				print("Combo detectado!")
			"hadouken":
				print("Hadouken!")
			"shoryuken":
				print("Shoryuken!")
			"tatsumaki":
				print("Tatsumaki!")
	
	if direction != 0:
		play_animation.emit(name, direction < 0)
		move.emit(Vector2(direction, 0))
	
	else:
		move.emit(Vector2.ZERO)
		transition_to.emit("Idle")
	
	if player_controls.is_jumping():
		transition_to.emit("Jump")
		return

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
