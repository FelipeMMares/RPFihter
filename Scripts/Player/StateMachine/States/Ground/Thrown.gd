extends State


@export var thrown_animation: StringName = &"Hurt"


func _enter() -> void:
	move.emit(Vector2.ZERO)

	set_crouching_hurtbox(false)

	play_animation.emit(
		thrown_animation,
		false
	)


func _physics_process(_delta: float) -> void:
	var character := _get_character()

	if character == null:
		return

	if character.has_method(
		"update_throw_capture"
	):
		character.call(
			"update_throw_capture"
		)


# A animação terminar não encerra o estado.
# O atacante controla quando a vítima é liberada.
func _animation_finished() -> void:
	pass


func _get_character() -> CharacterBody2D:
	return (
		get_parent().get_parent()
		as CharacterBody2D
	)
