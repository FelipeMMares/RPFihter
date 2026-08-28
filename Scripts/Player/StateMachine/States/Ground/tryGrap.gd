extends State
class_name TryGrabState

@export_group("Voice")

@export var whiff_voices: Array[AudioStream] = []
@export var play_whiff_voice: bool = false

@export_group("Animação")

@export var grab_animation: StringName = &"TryGrab"

@export_group("Regras")

@export var allow_counter_grab: bool = true

@export_group("Detecção")

@export var throw_box: ThrowBox

@export var active_start_frame: int = 1
@export var active_end_frame: int = 3


@export_group("Transições")

@export var throw_state: StringName = &"Throw"
@export var idle_state: StringName = &"Idle"


@export_group("Counter Grab")

@export var counter_window_seconds: float = 1.0


@onready var animated_sprite: AnimatedSprite2D = (
	get_parent()
	.get_parent()
	.get_node_or_null("AnimatedSprite2D")
	as AnimatedSprite2D
)


var _state_active: bool = false
var _throw_box_active: bool = false

var _grab_confirmed: bool = false
var _counter_resolved: bool = false


func _ready() -> void:
	if throw_box == null:
		printerr(
			"TryGrab: ThrowBox não configurada em ",
			get_path()
		)
		return

	if not throw_box.target_found.is_connected(
		_on_target_found
	):
		throw_box.target_found.connect(
			_on_target_found
		)


func _enter() -> void:
	_state_active = true
	_throw_box_active = false

	_grab_confirmed = false
	_counter_resolved = false

	move.emit(Vector2.ZERO)

	if throw_box != null:
		throw_box.disable()

	var character := _get_character()

	if character == null:
		transition_to.emit(idle_state)
		return

	if not character.has_method("begin_grab_attempt"):
		printerr(
			"TryGrab: ",
			character.name,
			" não possui begin_grab_attempt()."
		)

		transition_to.emit(idle_state)
		return

	character.call("begin_grab_attempt")

	play_animation.emit(
		grab_animation,
		false
	)


func _physics_process(_delta: float) -> void:
	move.emit(Vector2.ZERO)

	if _grab_confirmed or _counter_resolved:
		return

	if animated_sprite == null:
		return

	var current_frame: int = animated_sprite.frame

	var should_activate: bool = (
		current_frame >= active_start_frame
		and current_frame <= active_end_frame
	)

	if should_activate and not _throw_box_active:
		_throw_box_active = true

		if throw_box != null:
			throw_box.enable()

	elif not should_activate and _throw_box_active:
		_throw_box_active = false

		if throw_box != null:
			throw_box.disable()


func _on_target_found(
	hurtbox_area: Area2D
) -> void:
	if not _state_active:
		return

	if _grab_confirmed or _counter_resolved:
		return

	if hurtbox_area == null:
		return

	if not hurtbox_area.has_method("get_character"):
		printerr(
			"TryGrab: HurtBox detectada não possui "
			+ "get_character(): ",
			hurtbox_area.get_path()
		)
		return

	var attacker := _get_character()

	var target := (
		hurtbox_area.call("get_character")
		as CharacterBody2D
	)

	if attacker == null or target == null:
		return

	if target == attacker:
		return

	# Um personagem já capturado não pode
	# confirmar o próprio agarrão.
	if (
		attacker.has_method("is_throw_victim")
		and bool(attacker.call("is_throw_victim"))
	):
		return

	# -------------------------------------------------
	# PARRY CONTRA GRAB
	# -------------------------------------------------

	if target.has_method("try_parry_grab"):
		var grab_was_parried: bool = bool(
			target.call(
				"try_parry_grab",
				attacker
			)
		)

		if grab_was_parried:
			_counter_resolved = true
			_throw_box_active = false

			if throw_box != null:
				throw_box.disable()

			print(
				"TryGrab frustrado por Parry | atacante: ",
				attacker.name,
				" | defensor: ",
				target.name
			)

			return


	# -------------------------------------------------
	# COUNTER GRAB
	# -------------------------------------------------

	if _try_counter_grab(
		attacker,
		target
	):
		return


	# -------------------------------------------------
	# CAPTURA NORMAL
	# -------------------------------------------------

	if not target.has_method(
		"can_be_thrown"
	):
		printerr(
			"TryGrab: alvo não possui can_be_thrown(): ",
			target.name
		)
		return

	if not bool(
		target.call("can_be_thrown")
	):
		return

	_confirm_grab(
		attacker,
		target
	)

	if not bool(target.call("can_be_thrown")):
		return

	_confirm_grab(attacker, target)


func _confirm_grab(
	attacker: CharacterBody2D,
	target: CharacterBody2D
) -> void:
	if _grab_confirmed or _counter_resolved:
		return

	if attacker == null or target == null:
		return

	if attacker == target:
		return

	if not attacker.has_method(
		"reserve_as_throw_attacker"
	):
		printerr(
			"TryGrab: atacante não possui "
			+ "reserve_as_throw_attacker(): ",
			attacker.name
		)
		return

	if not target.has_method("begin_throw_capture"):
		printerr(
			"TryGrab: alvo não possui "
			+ "begin_throw_capture(): ",
			target.name
		)
		return

	var attacker_reserved: bool = bool(
		attacker.call(
			"reserve_as_throw_attacker"
		)
	)

	if not attacker_reserved:
		return

	var captured: bool = bool(
		target.call(
			"begin_throw_capture",
			attacker
		)
	)

	if not captured:
		if attacker.has_method(
			"release_throw_attacker_reservation"
		):
			attacker.call(
				"release_throw_attacker_reservation"
			)

		return

	_grab_confirmed = true
	_throw_box_active = false

	if throw_box != null:
		throw_box.disable()

	if not attacker.has_method("queue_grab_target"):
		target.call("cancel_throw_capture")
		attacker.call(
			"release_throw_attacker_reservation"
		)
		return

	attacker.call(
		"queue_grab_target",
		target
	)

	if attacker.has_method("end_grab_attempt"):
		attacker.call("end_grab_attempt")

	print(
		"TryGrab confirmado | atacante: ",
		attacker.name,
		" | vítima: ",
		target.name
	)

	transition_to.emit(throw_state)


func _try_counter_grab(
	attacker: CharacterBody2D,
	target: CharacterBody2D
) -> bool:
	if not target.has_method("is_trying_grab"):
		return false

	if not bool(target.call("is_trying_grab")):
		return false

	if not attacker.has_method(
		"get_grab_attempt_started_msec"
	):
		return false

	if not target.has_method(
		"get_grab_attempt_started_msec"
	):
		return false

	var attacker_time: int = int(
		attacker.call(
			"get_grab_attempt_started_msec"
		)
	)

	var target_time: int = int(
		target.call(
			"get_grab_attempt_started_msec"
		)
	)

	if attacker_time < 0 or target_time < 0:
		return false

	var time_difference: int = absi(
		attacker_time - target_time
	)

	var counter_window_msec: int = int(
		counter_window_seconds * 1000.0
	)

	if time_difference <= counter_window_msec:
		_counter_resolved = true
		_throw_box_active = false

		if throw_box != null:
			throw_box.disable()

		if attacker.has_method(
			"resolve_grab_counter_with"
		):
			attacker.call(
				"resolve_grab_counter_with",
				target
			)
		else:
			printerr(
				"TryGrab: atacante não possui "
				+ "resolve_grab_counter_with(): ",
				attacker.name
			)

			transition_to.emit(idle_state)

		print(
			"Counter Grab! Diferença: ",
			time_difference,
			" ms"
		)

		return true

	# Fora da janela, a tentativa mais antiga
	# permanece com prioridade.
	if attacker_time > target_time:
		return true

	return false


func _animation_finished() -> void:
	if _grab_confirmed or _counter_resolved:
		return

	transition_to.emit(idle_state)


func _exit() -> void:
	_state_active = false
	_throw_box_active = false

	if throw_box != null:
		throw_box.disable()

	# Não apaga o alvo nem a direção quando
	# a captura foi confirmada.
	if _grab_confirmed:
		return

	var character := _get_character()

	if (
		character != null
		and character.has_method(
			"cancel_grab_attempt"
		)
	):
		character.call("cancel_grab_attempt")


func _get_character() -> CharacterBody2D:
	return (
		get_parent().get_parent()
		as CharacterBody2D
	)
