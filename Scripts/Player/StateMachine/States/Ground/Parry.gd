extends State
class_name ParryState


@export var parry_duration: float = 0.15
@export var return_state: StringName = &"Idle"


var _time_left: float = 0.0


func _enter() -> void:
	_time_left = parry_duration

	move.emit(Vector2.ZERO)

	var character := _get_character()

	if (
		character != null
		and character.has_method("end_guard")
	):
		character.call("end_guard")

	play_animation.emit(&"Parry", false)


func _physics_process(delta: float) -> void:
	move.emit(Vector2.ZERO)

	_time_left = maxf(
		_time_left - delta,
		0.0
	)

	if _time_left <= 0.0:
		transition_to.emit(return_state)


func _animation_finished() -> void:
	pass


func _get_character() -> CharacterBody2D:
	return (
		get_parent().get_parent()
		as CharacterBody2D
	)
