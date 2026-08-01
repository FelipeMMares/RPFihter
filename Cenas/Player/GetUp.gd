extends State


@export var idle_state: StringName = &"Idle"


func _enter() -> void:
	move.emit(Vector2.ZERO)

	var character := _get_character()

	if character != null:
		# A invencibilidade termina quando começa
		# a animação de levantar.
		character.call(
			"set_throw_invulnerable",
			false
		)

	play_animation.emit(&"GetUp", false)


func _physics_process(_delta: float) -> void:
	move.emit(Vector2.ZERO)


func _animation_finished() -> void:
	var character := _get_character()

	if character != null:
		character.call("finish_throw_sequence")

	transition_to.emit(idle_state)


func _get_character() -> CharacterBody2D:
	return get_parent().get_parent() as CharacterBody2D
