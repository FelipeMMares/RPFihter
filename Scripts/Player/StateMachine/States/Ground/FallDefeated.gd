extends State


func _enter() -> void:
	var character := _get_character()

	if character != null:
		character.velocity.x = 0.0

		if character.has_method("end_guard"):
			character.call("end_guard")

	play_animation.emit(
		"FallDefeated",
		false
	)


func _physics_process(_delta: float) -> void:
	var character := _get_character()

	if character == null:
		return

	character.velocity.x = 0.0

	if character.is_on_floor():
		character.velocity = Vector2.ZERO


func _animation_finished() -> void:
	# Continua no estado FallDefeated.
	pass


func _get_character() -> CharacterBody2D:
	return (
		get_parent().get_parent()
		as CharacterBody2D
	)
