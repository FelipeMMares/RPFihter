extends State
class_name StunState


@export var stun_duration: float = 3.0
@export var return_state: StringName = &"Idle"


var _time_left: float = 0.0


func _enter() -> void:
	_time_left = stun_duration

	move.emit(Vector2.ZERO)

	var character := _get_character()

	if character != null:
		character.call("end_guard")

	play_animation.emit(&"Stun", false)


func _physics_process(delta: float) -> void:
	move.emit(Vector2.ZERO)

	_time_left = maxf(
		_time_left - delta,
		0.0
	)

	if _time_left <= 0.0:
		transition_to.emit(return_state)


func _exit() -> void:
	var character := _get_character()

	if (
		character != null
		and character.has_method(
			"reset_guard_durability"
		)
	):
		character.call(
			"reset_guard_durability"
		)


func _animation_finished() -> void:
	# A duração é controlada pelo timer.
	pass


func _get_character() -> CharacterBody2D:
	return (
		get_parent().get_parent()
		as CharacterBody2D
	)
