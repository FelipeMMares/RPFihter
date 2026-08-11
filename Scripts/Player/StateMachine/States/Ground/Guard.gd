extends State
class_name GuardState

signal guard_changed(
	current_value: float,
	max_value: float
)

signal guard_broken
signal guard_reset

@export_group("Transições")

@export var guard_while_state: StringName = &"GuardWhile"
@export var idle_state: StringName = &"Idle"


@export_group("Parry")

# Aproximadamente 9 frames em 60 FPS.
@export_range(0.01, 0.50, 0.01)
var parry_window_seconds: float = 0.15


var _leaving_guard: bool = false
var _keep_guard_active: bool = false

var max_guard: float = 100.0
var current_guard: float = 100.0

func _enter() -> void:
	move.emit(Vector2.ZERO)

	_keep_guard_active = false

	var character := _get_character()

	_leaving_guard = _should_leave_guard(
		character
	)

	if _leaving_guard:
		# Ao começar a animação invertida, a defesa
		# já deixa de negar dano.
		if (
			character != null
			and character.has_method("end_guard")
		):
			character.call("end_guard")

		play_animation.emit(
			&"Guard",
			true
		)

	else:
		# A janela de Parry começa no instante em que
		# o botão de defesa é pressionado.
		if (
			character != null
			and character.has_method("begin_guard")
		):
			character.call(
				"begin_guard",
				parry_window_seconds
			)

		play_animation.emit(
			&"Guard",
			false
		)


func _physics_process(_delta: float) -> void:
	move.emit(Vector2.ZERO)


func _animation_finished() -> void:
	if _leaving_guard:
		transition_to.emit(idle_state)
		return

	# Impede que _exit() desative a defesa ao
	# trocar de Guard para GuardWhile.
	_keep_guard_active = true

	transition_to.emit(guard_while_state)


func _exit() -> void:
	if _keep_guard_active:
		return

	var character := _get_character()

	if (
		character != null
		and character.has_method("end_guard")
	):
		character.call("end_guard")


func _should_leave_guard(
	character: CharacterBody2D
) -> bool:
	# Player: verifica diretamente o botão.
	if player_controls != null:
		return not Input.is_action_pressed(
			player_controls.guard
		)

	# Dummy: a IA solicita o encerramento.
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

func reset_guard_meter() -> void:
	current_guard = max_guard

	guard_reset.emit()

	guard_changed.emit(
		current_guard,
		max_guard
	)
