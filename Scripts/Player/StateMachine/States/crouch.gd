extends State

var crouched: bool = false

func _enter():
	play_animation.emit(name, false)

func _physics_process(delta: float) -> void:
	
	check_special_move()
	if !Input.is_action_pressed(player_controls.down):
		crouched = true
		play_animation.emit(name, true)

func _animation_finished() -> void:
	if not crouched:
		return
	
	crouched = false
	transition_to.emit("Idle")
