extends State


@export var crouch_end_state: StringName = &"CrouchEnd"

@export_group("Ataques agachados")

@export var light_punch_state: StringName = &"CrouchLightPunch"
@export var high_punch_state: StringName = &"CrouchHighPunch"
@export var kick_state: StringName = &"CrouchKick"
@export var low_kick_state: StringName = &"CrouchLowKick"


func _enter() -> void:
	move.emit(Vector2.ZERO)

	set_crouching_hurtbox(true)

	play_animation.emit(
		"CrouchWhile",
		false
	)


func _physics_process(_delta: float) -> void:
	move.emit(Vector2.ZERO)

	# O Dummy não possui PlayerControls.
	# Seus ataques serão escolhidos pelo DummyAI.
	if not player_input_enabled:
		return

	if player_controls == null:
		return

	# Especial sempre possui prioridade
	# sobre ataques agachados normais.
	if check_special_move():
		# O especial volta para HurtBox normal.
		set_crouching_hurtbox(
			false
		)
		return

	if Input.is_action_just_pressed(
		player_controls.light_punch
	):
		transition_to.emit(light_punch_state)
		return

	if Input.is_action_just_pressed(
		player_controls.high_punch
	):
		transition_to.emit(high_punch_state)
		return

	if Input.is_action_just_pressed(
		player_controls.kick
	):
		transition_to.emit(kick_state)
		return

	if Input.is_action_just_pressed(
		player_controls.low_kick
	):
		transition_to.emit(low_kick_state)
		return

	# A liberação do agachamento é verificada depois
	# dos ataques para não cancelar um ataque iniciado
	# no mesmo frame.
	if not Input.is_action_pressed(
		player_controls.down
	):
		transition_to.emit(crouch_end_state)
