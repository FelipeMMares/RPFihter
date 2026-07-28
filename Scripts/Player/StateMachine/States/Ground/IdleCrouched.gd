extends State


@export_group("Ataques agachados")

@export var light_punch_state: StringName = &"CrouchLightPunch"
@export var high_punch_state: StringName = &"CrouchHighPunch"
@export var kick_state: StringName = &"CrouchKick"
@export var low_kick_state: StringName = &"CrouchLowKick"

@export_group("Saída")

@export var idle_state: StringName = &"Idle"


func _enter() -> void:
	set_crouching_hurtbox(true)

	move.emit(Vector2.ZERO)

	play_animation.emit(&"CrouchWhile", false)


func _physics_process(_delta: float) -> void:
	move.emit(Vector2.ZERO)

	if player_controls == null:
		return

	# Ao soltar o agachamento, retorna imediatamente
	# para Idle e restaura a HurtBox em pé.
	if not Input.is_action_pressed(player_controls.down):
		transition_to.emit(&"Crouch")
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

	check_special_move()
