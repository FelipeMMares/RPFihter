extends State


@export var fall_duration: float = 1.0
@export var get_up_state: StringName = &"GetUp"

var _time_left: float = 0.0


func _enter() -> void:
	_time_left = fall_duration

	move.emit(Vector2.ZERO)

	var character := _get_character()

	if character != null:
		character.velocity = Vector2.ZERO
		character.call(
			"set_throw_invulnerable",
			true
		)

	play_animation.emit(&"Fall", false)


func _physics_process(delta: float) -> void:
	move.emit(Vector2.ZERO)

	_time_left = maxf(
		_time_left - delta,
		0.0
	)

	if _time_left <= 0.0:
		transition_to.emit(get_up_state)


func _animation_finished() -> void:
	# A duração no chão é controlada pelo timer.
	pass


func _get_character() -> CharacterBody2D:
	return get_parent().get_parent() as CharacterBody2D
