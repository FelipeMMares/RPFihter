extends State

const PROJECTILE_SCENE: PackedScene = preload(
	"res://Cenas/Player/kikokenProjectile.tscn"
)

const ANIMATION_NAME: StringName = &"Kikoken"

# Frame em que a esfera será criada.
const PROJECTILE_SPAWN_FRAME: int = 8

var projectile_spawned: bool = false



@onready var character: CharacterBody2D = (
	get_parent().get_parent() as CharacterBody2D
)

@onready var animated_sprite: AnimatedSprite2D = (
	character.get_node_or_null("AnimatedSprite2D")
	as AnimatedSprite2D
)

@onready var spawn_point: Marker2D = (
	character.get_node_or_null("KikokenSpawn")
	as Marker2D
)


func _enter() -> void:
	projectile_spawned = false

	# Interrompe o movimento horizontal.
	move.emit(Vector2.ZERO)

	play_animation.emit(
		String(ANIMATION_NAME),
		false
	)

	print("Estado Kikoken iniciado")


func _physics_process(_delta: float) -> void:
	if animated_sprite == null:
		return

	if animated_sprite.animation != ANIMATION_NAME:
		return

	if (
		not projectile_spawned
		and animated_sprite.frame >= PROJECTILE_SPAWN_FRAME
	):
		_spawn_projectile()


func _spawn_projectile() -> void:
	projectile_spawned = true

	if character == null:
		printerr(
			"Kikoken: personagem não encontrado."
		)
		return

	if spawn_point == null:
		printerr(
			"Kikoken: KikokenSpawn não encontrado."
		)
		return

	var projectile := (
		PROJECTILE_SCENE.instantiate()
		as KikokenProjectile
	)

	if projectile == null:
		printerr(
			"Kikoken: não foi possível criar o projétil."
		)
		return

	var projectile_direction: float = 1.0

	if animated_sprite.flip_h:
		projectile_direction = -1.0

	# Adiciona primeiro à árvore para que os
	# @onready do projétil sejam inicializados.
	character.get_tree().current_scene.add_child(
		projectile
	)

	# Calcula a posição relativa ao personagem.
	var local_spawn_position: Vector2 = (
		spawn_point.position
	)

	local_spawn_position.x = (
		absf(local_spawn_position.x)
		* projectile_direction
	)

	projectile.global_position = (
		character.to_global(
			local_spawn_position
		)
	)

	# Informa ao projétil quem o criou e em qual
	# direção ele deve se mover.
	projectile.setup(
		character,
		projectile_direction
	)

	print(
		"Kikoken criado no frame ",
		animated_sprite.frame,
		" | dono: ",
		character.name,
		" | direção: ",
		projectile_direction
	)

func _animation_finished() -> void:
	transition_to.emit("Idle")
