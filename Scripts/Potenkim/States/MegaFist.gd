extends State


@export_group("Hitbox")

@export var hitbox: Area2D

@export_range(0, 30, 1)
var active_start_frame: int = 2

@export_range(0, 30, 1)
var active_end_frame: int = 5


@export_group("Movimento")

@export var forward_speed: float = 240.0

@export var upward_speed: float = 420.0


@export_group("Estado")

@export var landing_state: StringName = &"Idle"


var _direction: float = 1.0
var _hitbox_active: bool = false
var _has_left_ground: bool = false


func _enter() -> void:
	_set_hitbox_enabled(false)

	_has_left_ground = false

	var character := _get_character()

	if character == null:
		transition_to.emit(
			landing_state
		)
		return

	_direction = _get_facing_direction()

	# Impulso horizontal.
	character.velocity.x = (
		forward_speed
		* _direction
	)

	# Impulso vertical.
	# Y negativo = para cima.
	character.velocity.y = (
		-upward_speed
	)

	play_animation.emit(
		&"MegaFist",
		false
	)


func _physics_process(
	_delta: float
) -> void:
	var character := _get_character()

	if character == null:
		return

	var state_machine := (
		get_parent() as StateMachine
	)

	if state_machine == null:
		return

	var sprite := (
		state_machine.animated_sprite
	)

	if sprite == null:
		return

	# ------------------------------------------------
	# DETECTA SE REALMENTE SAIU DO CHÃO
	# ------------------------------------------------

	if not character.is_on_floor():
		_has_left_ground = true


	# ------------------------------------------------
	# MANTÉM O AVANÇO
	# ------------------------------------------------

	if _has_left_ground:
		character.velocity.x = (
			forward_speed
			* _direction
		)


	# ------------------------------------------------
	# HITBOX
	# ------------------------------------------------

	if (
		StringName(sprite.animation)
		== &"MegaFist"
	):
		var current_frame: int = (
			sprite.frame
		)

		var should_be_active: bool = (
			current_frame
			>= active_start_frame
			and current_frame
			<= active_end_frame
		)

		if (
			should_be_active
			!= _hitbox_active
		):
			_set_hitbox_enabled(
				should_be_active
			)


	# ------------------------------------------------
	# ATERRISSAGEM
	# ------------------------------------------------

	if (
		_has_left_ground
		and character.is_on_floor()
		and character.velocity.y >= 0.0
	):
		character.velocity.x = 0.0

		_set_hitbox_enabled(false)

		transition_to.emit(
			landing_state
		)


func _animation_finished() -> void:
	# Não volta para Idle aqui.
	#
	# Mega Fist só termina quando
	# Potemkin toca o chão.
	pass


func _exit() -> void:
	var character := _get_character()

	if character != null:
		character.velocity.x = 0.0

	_set_hitbox_enabled(false)


func _get_facing_direction() -> float:
	var character := _get_character()

	if character == null:
		return 1.0

	var facing_controller := (
		character.get_node_or_null(
			"FacingController"
		) as FacingController
	)

	if facing_controller == null:
		return 1.0

	if facing_controller.is_facing_right():
		return 1.0

	return -1.0


func _set_hitbox_enabled(
	active: bool
) -> void:
	_hitbox_active = active

	if hitbox == null:
		return

	hitbox.monitoring = active
	hitbox.monitorable = active

	for child in hitbox.get_children():
		if child is CollisionShape2D:
			child.set_deferred(
				"disabled",
				not active
			)


func _get_character() -> CharacterBody2D:
	return (
		get_parent().get_parent()
		as CharacterBody2D
	)
