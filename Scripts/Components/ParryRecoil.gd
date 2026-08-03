extends State
class_name ParryRecoilState


@export var recoil_duration: float = 0.25
@export var return_state: StringName = &"Idle"


var _time_left: float = 0.0


func _enter() -> void:
	_time_left = recoil_duration

	var character := _get_character()

	if character == null:
		transition_to.emit(return_state)
		return

	var recoil_velocity: float = float(
		character.call(
			"consume_parry_recoil_velocity"
		)
	)

	character.velocity.x = recoil_velocity

	# Pode usar uma animação própria ou a animação Hurt.
	play_animation.emit(&"ParryRecoil", false)


func _physics_process(delta: float) -> void:
	var character := _get_character()

	if character == null:
		return

	_time_left = maxf(
		_time_left - delta,
		0.0
	)

	if _time_left <= 0.0:
		character.velocity.x = 0.0
		transition_to.emit(return_state)


func _exit() -> void:
	var character := _get_character()

	if character != null:
		character.velocity.x = 0.0


func _animation_finished() -> void:
	# O recuo termina pelo timer.
	pass


func _get_character() -> CharacterBody2D:
	return (
		get_parent().get_parent()
		as CharacterBody2D
	)
