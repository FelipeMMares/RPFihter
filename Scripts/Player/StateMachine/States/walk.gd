extends State


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	var direction : float = \
	Input.get_axis(player_controls.left, player_controls.right)
	
	if direction != 0:
		character.velocity.x = direction * 50
	else:
		character.velocity.x = 0
		transition_to.emit("Idle")

	character.move_and_slide()
