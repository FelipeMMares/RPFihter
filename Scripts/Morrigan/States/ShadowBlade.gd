extends State


@export_group("Movimento")

@export var vertical_velocity: float = -500.0

@export var horizontal_velocity: float = 0.0


@export_group("Frames ativos")

@export_range(0, 60, 1)
var active_start_frame: int = 2

@export_range(0, 60, 1)
var active_end_frame: int = 5


@export_group("HitBox")

@export_node_path("Area2D")
var hitbox_path: NodePath


@export_group("Estado")

@export var ground_return_state: StringName = &"Idle"

@export var air_return_state: StringName = &"Jump"


var _hitbox_active: bool = false


func _enter() -> void:
	_set_hitbox_enabled(
		false
	)

	var character := (
		get_parent().get_parent()
		as CharacterBody2D
	)

	if character != null:
		character.velocity.y = (
			vertical_velocity
		)

	move.emit(
		Vector2(
			horizontal_velocity,
			0.0
		)
	)

	play_animation.emit(
		"ShadowBlade",
		false
	)


func _physics_process(
	_delta: float
) -> void:
	var state_machine := (
		get_parent() as StateMachine
	)

	if state_machine == null:
		return

	if state_machine.animated_sprite == null:
		return

	var sprite := (
		state_machine.animated_sprite
	)

	if (
		StringName(sprite.animation)
		!= &"ShadowBlade"
	):
		return

	var current_frame: int = (
		sprite.frame
	)

	var should_be_active: bool = (
		current_frame >= active_start_frame
		and current_frame <= active_end_frame
	)

	if should_be_active != _hitbox_active:
		_set_hitbox_enabled(
			should_be_active
		)


func _set_hitbox_enabled(
	active: bool
) -> void:
	_hitbox_active = active

	var character := (
		get_parent().get_parent()
		as CharacterBody2D
	)

	if character == null:
		return

	var hitbox := (
		character.get_node_or_null(
			hitbox_path
		) as Area2D
	)

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


func _exit() -> void:
	_set_hitbox_enabled(
		false
	)


func _animation_finished() -> void:
	_set_hitbox_enabled(
		false
	)

	var character := (
		get_parent().get_parent()
		as CharacterBody2D
	)

	if character == null:
		transition_to.emit(
			ground_return_state
		)
		return

	if character.is_on_floor():
		transition_to.emit(
			ground_return_state
		)
	else:
		transition_to.emit(
			air_return_state
		)
