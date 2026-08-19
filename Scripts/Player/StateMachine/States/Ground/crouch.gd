extends State


@export var crouch_while_state: StringName = &"CrouchWhile"
@export var idle_state: StringName = &"Idle"


var _leaving_crouch: bool = false

var _ai_crouch_prepared: bool = false
var _ai_leaving_crouch: bool = false


func prepare_ai_crouch(
	leaving: bool
) -> void:
	_ai_leaving_crouch = leaving
	_ai_crouch_prepared = true


func _enter() -> void:
	move.emit(Vector2.ZERO)


	# =========================
	# CPU
	# =========================

	if not player_input_enabled:
		if not _ai_crouch_prepared:
			printerr(
				"Crouch: entrada da IA não foi preparada."
			)
			return

		_leaving_crouch = (
			_ai_leaving_crouch
		)

		_ai_crouch_prepared = false

		set_crouching_hurtbox(
			true
		)

		# false:
		# Idle -> CrouchWhile
		#
		# true:
		# CrouchWhile -> Idle
		play_animation.emit(
			&"Crouch",
			_leaving_crouch
		)

		return


	# =========================
	# JOGADOR HUMANO
	# =========================

	if player_controls == null:
		return

	if Input.is_action_pressed(
		player_controls.down
	):
		_leaving_crouch = false

		set_crouching_hurtbox(
			true
		)

		play_animation.emit(
			&"Crouch",
			false
		)

	else:
		_leaving_crouch = true

		set_crouching_hurtbox(
			true
		)

		play_animation.emit(
			&"Crouch",
			true
		)


func _physics_process(
	_delta: float
) -> void:
	move.emit(Vector2.ZERO)


func _animation_finished() -> void:
	if _leaving_crouch:
		set_crouching_hurtbox(
			false
		)

		transition_to.emit(
			idle_state
		)

	else:
		transition_to.emit(
			crouch_while_state
		)
