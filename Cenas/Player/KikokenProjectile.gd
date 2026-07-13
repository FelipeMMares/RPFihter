extends Node2D
class_name KikokenProjectile

@export var speed: float = 420.0
@export var lifetime: float = 3.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: HitBox = $HitBox
@onready var screen_notifier: VisibleOnScreenNotifier2D = (
	$VisibleOnScreenNotifier2D
)

var direction: float = 1.0
var elapsed_time: float = 0.0


func _ready() -> void:
	if hitbox != null:
		hitbox.enable()

		if not hitbox.hit_confirmed.is_connected(
			_on_hit_confirmed
		):
			hitbox.hit_confirmed.connect(
				_on_hit_confirmed
			)

	if (
		screen_notifier != null
		and not screen_notifier.screen_exited.is_connected(
			_on_screen_exited
		)
	):
		screen_notifier.screen_exited.connect(
			_on_screen_exited
		)

func _on_hit_confirmed(_target: Area2D) -> void:
	if hitbox != null:
		hitbox.disable()

	call_deferred("queue_free")

func setup(new_direction: float) -> void:
	if new_direction < 0.0:
		direction = -1.0
	else:
		direction = 1.0

	if animated_sprite != null:
		animated_sprite.flip_h = direction < 0.0


func _physics_process(delta: float) -> void:
	global_position.x += speed * direction * delta

	elapsed_time += delta

	if elapsed_time >= lifetime:
		queue_free()


func _on_screen_exited() -> void:
	queue_free()


func _exit_tree() -> void:
	if is_instance_valid(hitbox):
		hitbox.disable()
