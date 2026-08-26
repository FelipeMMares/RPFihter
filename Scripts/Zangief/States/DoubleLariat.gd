extends State


@export_group("Hitbox")

@export var hitbox: Area2D

@export_range(0, 60, 1)
var active_start_frame: int = 2

@export_range(0, 60, 1)
var active_end_frame: int = 12


@export_group("Estado")

@export var return_state: StringName = &"Idle"


var _hitbox_active: bool = false


func _enter() -> void:
	move.emit(Vector2.ZERO)

	_set_hitbox_enabled(false)

	play_animation.emit(
		&"DoubleLariat",
		false
	)


func _physics_process(
	_delta: float
) -> void:
	move.emit(Vector2.ZERO)

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
		!= &"DoubleLariat"
	):
		return

	var current_frame := sprite.frame

	var should_be_active := (
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
	_set_hitbox_enabled(false)

	transition_to.emit(
		return_state
	)


func _exit() -> void:
	_set_hitbox_enabled(false)
