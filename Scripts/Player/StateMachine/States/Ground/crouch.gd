extends State

var leaving := false

func _enter():

	leaving = false
	play_animation.emit(name, false)

func _physics_process(delta):

	if !leaving and !Input.is_action_pressed(player_controls.down):

		leaving = true

		play_animation.emit(name, true)

func _animation_finished():

	if leaving:
		transition_to.emit("Idle")
	else:
		transition_to.emit("IdleCrouched")
