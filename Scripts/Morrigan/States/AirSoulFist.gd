extends State


@export_group("Projétil")

@export var projectile_scene: PackedScene

@export_node_path("Marker2D")
var spawn_marker_path: NodePath

@export_range(0, 60, 1)
var spawn_frame: int = 3


@export_group("Trajetória")

@export_range(
	0.1,
	2.0,
	0.05
)
var downward_amount: float = 0.75


@export_group("Estado")

@export var return_state: StringName = &"Jump"


var _projectile_spawned: bool = false


func _enter() -> void:
	_projectile_spawned = false

	# Zera somente a intenção horizontal enviada
	# pelo State.
	move.emit(
		Vector2.ZERO
	)

	play_animation.emit(
		"AirSoulFist",
		false
	)


func _physics_process(
	_delta: float
) -> void:
	if _projectile_spawned:
		return

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
		!= &"AirSoulFist"
	):
		return

	if sprite.frame < spawn_frame:
		return

	if _spawn_projectile():
		_projectile_spawned = true


func _spawn_projectile() -> bool:
	if projectile_scene == null:
		printerr(
			"AirSoulFist: Projectile Scene não configurada."
		)
		return false

	var character := (
		get_parent().get_parent()
		as CharacterBody2D
	)

	if character == null:
		return false

	var spawn_marker := (
		character.get_node_or_null(
			spawn_marker_path
		) as Marker2D
	)

	if spawn_marker == null:
		printerr(
			"AirSoulFist: Spawn Marker não encontrado."
		)
		return false

	var projectile := (
		projectile_scene.instantiate()
		as Node2D
	)

	if projectile == null:
		return false

	var world := character.get_parent()

	if world == null:
		projectile.queue_free()
		return false

	world.add_child(
		projectile
	)

	projectile.global_position = (
		spawn_marker.global_position
	)

	var facing: float = (
		_get_facing_direction()
	)

	var direction := Vector2(
		facing,
		downward_amount
	).normalized()

	if projectile.has_method(
		"setup"
	):
		projectile.call(
			"setup",
			direction
		)

	return true


func _get_facing_direction() -> float:
	var state_machine := (
		get_parent() as StateMachine
	)

	if state_machine == null:
		return 1.0

	if state_machine.animated_sprite == null:
		return 1.0

	if state_machine.animated_sprite.flip_h:
		return -1.0

	return 1.0


func _animation_finished() -> void:
	transition_to.emit(
		return_state
	)
