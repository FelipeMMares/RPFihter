extends Node2D


@export_group("Movimento")

@export var speed: float = 420.0

@export var lifetime: float = 4.0


var _direction: Vector2 = Vector2.RIGHT

var _remaining_lifetime: float = 0.0


func _ready() -> void:
	_remaining_lifetime = lifetime


func setup(
	direction: Vector2
) -> void:
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT

	_direction = direction.normalized()

	rotation = _direction.angle()


func _physics_process(
	delta: float
) -> void:
	global_position += (
		_direction
		* speed
		* delta
	)

	_remaining_lifetime -= delta

	if _remaining_lifetime <= 0.0:
		queue_free()
