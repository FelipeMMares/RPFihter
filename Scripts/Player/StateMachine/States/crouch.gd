extends State

func _enter() -> void:
	animated_sprite.play(name)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if Input.is_action_just_released(player_controls.down):
		animated_sprite.animation_finished.connect(_animation_finished, CONNECT_ONE_SHOT)
		animated_sprite.play("Crouch")

func _animation_finished() -> void:
	transition_to.emit("Idle")
