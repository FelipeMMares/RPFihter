extends State


@export_group("Hitbox")

@export var hitbox: Area2D

@export_range(0, 60, 1)
var active_start_frame: int = 4

@export_range(0, 60, 1)
var active_end_frame: int = 7


@export_group("Movimento")

@export var advance_speed: float = 260.0

@export_range(0, 60, 1)
var movement_end_frame: int = 6


@export_group("Estado")

@export var return_state: StringName = &"Idle"


var _hitbox_active: bool = false
var _direction: float = 1.0


func _enter() -> void:
	_set_hitbox_enabled(false)

	var character := _get_character()

	if character == null:
		transition_to.emit(
			return_state
		)
		return

	_direction = _get_facing_direction()

	character.velocity.x = (
		advance_speed * _direction
	)

	play_animation.emit(
		&"BanishingFlat",
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

	var sprite := state_machine.animated_sprite

	if sprite == null:
		return

	if (
		StringName(sprite.animation)
		!= &"BanishingFlat"
	):
		return

	var current_frame := sprite.frame

	# Movimento para frente.
	if current_frame <= movement_end_frame:
		character.velocity.x = (
			advance_speed * _direction
		)
	else:
		character.velocity.x = 0.0

	# Hitbox.
	var should_be_active := (
		current_frame >= active_start_frame
		and current_frame <= active_end_frame
	)

	if should_be_active != _hitbox_active:
		_set_hitbox_enabled(
			should_be_active
		)


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

	return (
		1.0
		if facing_controller.is_facing_right()
		else -1.0
	)


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


func _animation_finished() -> void:
	var character := _get_character()

	if character != null:
		character.velocity.x = 0.0

	_set_hitbox_enabled(false)

	transition_to.emit(
		return_state
	)


func _exit() -> void:
	var character := _get_character()

	if character != null:
		character.velocity.x = 0.0

	_set_hitbox_enabled(false)


func _get_character() -> CharacterBody2D:
	return (
		get_parent().get_parent()
		as CharacterBody2D
	)
