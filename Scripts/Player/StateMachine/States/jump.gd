extends State

var jumped: bool = false

func _enter():
	print("ENTROU NO JUMP")
	play_animation.emit(name, false)

func _physics_process(delta: float) -> void:
	check_special_move()
	if !Input.is_action_pressed(player_controls.up):
		jumped = true
		play_animation.emit(name, true)
	if player_controls.is_walking():
		var direction = Input.get_axis(
			player_controls.left,
			player_controls.right
		)
		move.emit(Vector2(direction,0))
	if get_parent().get_parent().is_on_floor():

		transition_to.emit("Idle")

func _animation_finished() -> void:
	if not jumped:
		return

	jumped = false
	transition_to.emit("Idle")
