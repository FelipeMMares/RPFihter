extends State

func _enter() -> void:
	# Usa o nome do próprio estado para tocar a animação.
	# Como o nó se chama Walk, toca "Walk".
	play_animation.emit(name, false)

func _physics_process(delta: float) -> void:
	check_special_move()
	# O Dummy não possui PlayerControls.
	# A direção dele será controlada pelo DummyAI.
	if player_controls == null:
		return

	var direction: float = Input.get_axis(
		player_controls.left,
		player_controls.right
	)

	if is_zero_approx(direction):
		move.emit(Vector2.ZERO)
		transition_to.emit("Idle")
		return

	move.emit(Vector2(direction, 0.0))
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
