extends State

func _enter() -> void:
	play_animation.emit(name, false)

func _physics_process(delta: float) -> void:
	
	if player_controls.is_walking():
		transition_to.emit("Walk")
		
	if player_controls.just_crouched():
		transition_to.emit("Crouch")
