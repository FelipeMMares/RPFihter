extends Node2D


@export_group("Movimento")

@export var speed: float = 420.0

@export var lifetime: float = 4.0


@onready var hitbox: HitBox = (
	$HitBox
)

@onready var collision_detector: Area2D = (
	$CollisionDetector
)


var _direction: Vector2 = Vector2.RIGHT

var _remaining_lifetime: float = 0.0

var _owner_character: CharacterBody2D = null

var _destroying: bool = false


func _ready() -> void:
	_remaining_lifetime = lifetime

	if collision_detector == null:
		printerr(
			"SoulFistProjectile: "
			+ "CollisionDetector não encontrado."
		)
		return

	# O sensor físico do projétil pode detectar
	# qualquer camada.
	collision_detector.collision_mask = 0

	for layer in range(1, 33):
		collision_detector.set_collision_mask_value(
			layer,
			true
		)

	collision_detector.monitoring = true
	collision_detector.monitorable = false

	if not collision_detector.body_entered.is_connected(
		_on_body_entered
	):
		collision_detector.body_entered.connect(
			_on_body_entered
		)

	if not collision_detector.area_entered.is_connected(
		_on_area_entered
	):
		collision_detector.area_entered.connect(
			_on_area_entered
		)

	if (
		hitbox != null
		and not hitbox.hit_confirmed.is_connected(
			_on_hit_confirmed
		)
	):
		hitbox.hit_confirmed.connect(
			_on_hit_confirmed
		)


func setup(
	direction: Vector2,
	owner_character: CharacterBody2D = null
) -> void:
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT

	_direction = direction.normalized()

	_owner_character = owner_character

	rotation = _direction.angle()

	# Como a HitBox do projétil não está dentro
	# do CharacterBody2D, informamos manualmente
	# quem disparou.
	if hitbox != null:
		hitbox.set_owner_character(
			_owner_character
		)

		hitbox.enable()


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
		_destroy_projectile()


# ==================================================
# COLISÕES COM PHYSICSBODY
# Parede, StaticBody2D, CharacterBody2D etc.
# ==================================================

func _on_body_entered(
	body: Node2D
) -> void:
	if body == null:
		return

	if _belongs_to_owner(body):
		return

	_destroy_projectile()


# ==================================================
# COLISÕES COM AREAS
# HurtBox, sensores, outras áreas etc.
# ==================================================

func _on_area_entered(
	area: Area2D
) -> void:
	if area == null:
		return

	# Nunca destruir por tocar uma HitBox.
	if area is HitBox:
		return

	# Não colide com HurtBox ou outras áreas
	# pertencentes ao próprio personagem.
	if _belongs_to_owner(area):
		return

	# Se for uma HurtBox de combate, deixamos
	# a HitBox processar o dano primeiro.
	#
	# hit_confirmed será emitido logo depois
	# e destruirá o projétil.
	if area.has_method("receive_hit"):
		return

	# Qualquer outra Area2D válida destrói.
	_destroy_projectile()


# ==================================================
# ACERTO EM PERSONAGEM
# ==================================================

func _on_hit_confirmed(
	_target: Area2D
) -> void:
	_destroy_projectile()


# ==================================================
# VERIFICA SE O OBJETO PERTENCE AO ATIRADOR
# ==================================================

func _belongs_to_owner(
	node: Node
) -> bool:
	if node == null:
		return false

	if _owner_character == null:
		return false

	if node == _owner_character:
		return true

	return _owner_character.is_ancestor_of(
		node
	)


func _destroy_projectile() -> void:
	if _destroying:
		return

	_destroying = true

	queue_free()
