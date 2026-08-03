extends State
class_name GuardWhileState


@export var guard_transition_state: StringName = &"Guard"


var _leaving_to_guard_transition: bool = false


func _enter() -> void:
	_leaving_to_guard_transition = false

	move.emit(Vector2.ZERO)

	play_animation.emit(
		&"GuardWhile",
		false
	)


func _physics_process(_delta: float) -> void:
	move.emit(Vector2.ZERO)

	var character := _get_character()

	if _should_release_guard(character):
		# A defesa termina imediatamente ao soltar
		# o botão, antes da animação invertida.
		if (
			character != null
			and character.has_method("end_guard")
		):
			character.call("end_guard")

		_leaving_to_guard_transition = true

		# Retorna para Guard, que perceberá que o
		# botão não está pressionado e tocará a
		# animação ao contrário.
		transition_to.emit(
			guard_transition_state
		)


func _exit() -> void:
	# Na saída normal para a animação invertida,
	# end_guard() já foi chamado.
	if _leaving_to_guard_transition:
		return

	# Proteção para transições forçadas como:
	# Parry, Stun, Throw, Hurt etc.
	var character := _get_character()

	if (
		character != null
		and character.has_method("end_guard")
	):
		character.call("end_guard")


func _animation_finished() -> void:
	# GuardWhile é mantido pelo botão.
	pass


func _should_release_guard(
	character: CharacterBody2D
) -> bool:
	if player_controls != null:
		return not Input.is_action_pressed(
			player_controls.guard
		)

	if (
		character != null
		and character.has_method(
			"consume_guard_release_request"
		)
	):
		return bool(
			character.call(
				"consume_guard_release_request"
			)
		)

	return false


func _get_character() -> CharacterBody2D:
	return (
		get_parent().get_parent()
		as CharacterBody2D
	)
