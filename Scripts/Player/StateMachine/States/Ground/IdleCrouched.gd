extends State

func _enter():

	play_animation.emit(name, false)

func _physics_process(delta):

	check_special_move()

	move.emit(Vector2.ZERO)

	if !Input.is_action_pressed(player_controls.down):

		transition_to.emit("Crouch")
