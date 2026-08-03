extends Node2D
class_name KikokenProjectile


@export var speed: float = 420.0
@export var lifetime: float = 3.0


@onready var animated_sprite: AnimatedSprite2D = (
	$AnimatedSprite2D
)

@onready var hitbox: HitBox = $HitBox

@onready var screen_notifier: VisibleOnScreenNotifier2D = (
	$VisibleOnScreenNotifier2D
)


var source_character: CharacterBody2D = null

var movement_direction: float = 1.0
var elapsed_time: float = 0.0

var _configured: bool = false


func _ready() -> void:
	# A HitBox só será ativada depois que setup()
	# registrar quem criou o projétil.
	if hitbox != null:
		hitbox.disable()

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


func setup(
	attacker: CharacterBody2D,
	new_direction: float
) -> void:
	source_character = attacker

	movement_direction = signf(new_direction)

	if is_zero_approx(movement_direction):
		movement_direction = 1.0

	# Espelha visualmente o Kikoken.
	if animated_sprite != null:
		animated_sprite.flip_h = (
			movement_direction < 0.0
		)

	if hitbox == null:
		printerr(
			"KikokenProjectile: HitBox não encontrada."
		)
		return

	if source_character == null:
		printerr(
			"KikokenProjectile: atacante não informado."
		)
		return

	# Registra a Chun-Li como dona do projétil.
	# Assim, a HitBox ignora a HurtBox dela.
	hitbox.set_owner_character(
		source_character
	)

	_configured = true
	elapsed_time = 0.0

	# Só ativa depois que o dono foi configurado.
	hitbox.enable()

	print(
		"Kikoken configurado | dono: ",
		source_character.name,
		" | direção: ",
		movement_direction
	)


func _physics_process(delta: float) -> void:
	if not _configured:
		return

	global_position.x += (
		speed
		* movement_direction
		* delta
	)

	elapsed_time += delta

	if elapsed_time >= lifetime:
		queue_free()


func _on_hit_confirmed(
	_target: Area2D
) -> void:
	if hitbox != null:
		hitbox.disable()

	call_deferred("queue_free")


func _on_screen_exited() -> void:
	queue_free()


func _exit_tree() -> void:
	if is_instance_valid(hitbox):
		hitbox.disable()
