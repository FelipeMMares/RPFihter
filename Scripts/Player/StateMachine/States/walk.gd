extends State

func _enter():

	print("ENTER WALK")

	animated_sprite.play("Walk")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	
	var direction : float = \
	Input.get_axis(player_controls.left, player_controls.right)
	
	if direction != 0:
		if direction > 0:
			animated_sprite.play(name)
		else:
			animated_sprite.play_backwards(name)
		
		character.velocity.x = direction * 150
	else:
		character.velocity.x = 0
		transition_to.emit("Idle")

	character.move_and_slide()
