extends State

@export var jump_state: StringName = &"StartJump"
@export var walk_state: StringName = &"Walk"
@export var crouch_state: StringName = &"Crouch"

func _enter() -> void:
	play_animation.emit(name, false)

func _physics_process(delta: float) -> void:
	move.emit(Vector2.ZERO)
	check_special_move()
	
		# Dummy não possui controles
	if player_controls == null:
		return
	
	var throw_direction: float = (
		player_controls.get_throw_direction()
	)

	if not is_zero_approx(throw_direction):
		var character := (
			get_parent().get_parent()
			as CharacterBody2D
		)

		if (
			character != null
			and character.has_method(
				"queue_throw_direction"
			)
		):
			character.call(
				"queue_throw_direction",
				throw_direction
			)

			transition_to.emit(&"Throw")
			return
	
	if player_controls.is_jumping():
		print("PEDIU PULO")
		transition_to.emit("StartJump")
	
	if player_controls.is_walking():
		transition_to.emit("Walk")
		
	if player_controls.just_crouched():
		transition_to.emit("Crouch")
	

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
