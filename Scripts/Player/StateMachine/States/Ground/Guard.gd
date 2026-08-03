extends State
class_name GuardState


@export var idle_state: StringName = &"Idle"

# Quantos frames físicos após entrar em Guard
# podem resultar em Parry.
@export_range(1, 15, 1)
var parry_window_frames: int = 4


func _enter() -> void:
	move.emit(Vector2.ZERO)

	var character := _get_character()

	if character != null:
		character.call(
			"begin_guard",
			parry_window_frames
		)

	play_animation.emit(&"Guard", false)


func _physics_process(_delta: float) -> void:
	move.emit(Vector2.ZERO)

	# Player: permanece defendendo enquanto
	# o botão estiver pressionado.
	if player_controls != null:
		if not Input.is_action_pressed(
			player_controls.guard
		):
			transition_to.emit(idle_state)


func _exit() -> void:
	var character := _get_character()

	if (
		character != null
		and character.has_method("end_guard")
	):
		character.call("end_guard")


func _animation_finished() -> void:
	# Guard é controlado pelo botão, não pelo
	# término da animação.
	pass


func _get_character() -> CharacterBody2D:
	return (
		get_parent().get_parent()
		as CharacterBody2D
	)
