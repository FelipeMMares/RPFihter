extends Area2D
class_name HurtBox

@export var health: Health
@export var state_machine: StateMachine

@export_group("Formas da HurtBox")

@export var head_shape: CollisionShape2D
@export var torso_shape: CollisionShape2D
@export var feet_shape: CollisionShape2D
@export var crouch_shape: CollisionShape2D

var character: CharacterBody2D
var crouching: bool = false
var invulnerable: bool = false

func _ready() -> void:
	character = _find_character()

	if character == null:
		printerr(
			"HurtBox: CharacterBody2D proprietário não encontrado em ",
			get_path()
		)
		return

	if health == null:
		health = character.get_node_or_null("Health") as Health

	if state_machine == null:
		state_machine = (
			character.get_node_or_null("StateMachine")
			as StateMachine
		)

	# HurtBoxes ficam exclusivamente na camada 2.
	collision_layer = 0
	set_collision_layer_value(2, true)

	collision_mask = 0
	monitoring = false
	monitorable = true

	var found_shape := false

	_validate_hurtbox_shapes()
	set_crouching(false)

	if not found_shape:
		printerr(
			"HurtBox sem CollisionShape2D: ",
			get_path()
		)

	print(
		"HurtBox pronta | personagem: ",
		character.name,
		" | caminho: ",
		get_path(),
		" | layer: ",
		collision_layer,
		" | monitorable: ",
		monitorable
	)

	set_crouching(false)

func _validate_hurtbox_shapes() -> void:
	if head_shape == null:
		printerr("HurtBox: HeadShape não configurada.")

	if torso_shape == null:
		printerr("HurtBox: TorsoShape não configurada.")

	if feet_shape == null:
		printerr("HurtBox: FeetShape não configurada.")

	if crouch_shape == null:
		printerr("HurtBox: CrouchShape não configurada.")

func receive_hit(hit_data: HitData) -> void:
	if invulnerable:
		return
	
	if hit_data == null:
		printerr(
			"HurtBox de ",
			character.name,
			" recebeu HitData nulo."
		)
		return

	if health == null:
		printerr(
			"HurtBox de ",
			character.name,
			": Health não encontrada."
		)
		return

	if health.is_defeated():
		return

	print(
		"PERSONAGEM ATINGIDO | alvo: ",
		character.name,
		" | dano: ",
		hit_data.damage
	)

	health.take_damage(hit_data.damage)

	if health.is_defeated():
		return

	if state_machine == null:
		printerr(
			"HurtBox de ",
			character.name,
			": StateMachine não encontrada."
		)
		return

	if state_machine.has_state(&"Hurt"):
		state_machine.receive_hit(hit_data)
	else:
		printerr(
			"StateMachine de ",
			character.name,
			" não possui estado Hurt."
		)


func get_character() -> CharacterBody2D:
	return character


func _find_character() -> CharacterBody2D:
	var current_node: Node = get_parent()

	while current_node != null:
		if current_node is CharacterBody2D:
			return current_node as CharacterBody2D

		current_node = current_node.get_parent()

	return null

func set_crouching(active: bool) -> void:
	crouching = active

	# Em pé: cabeça, torso e pés ficam ativos.
	_set_shape_active(
		head_shape,
		not crouching
	)

	_set_shape_active(
		torso_shape,
		not crouching
	)

	_set_shape_active(
		feet_shape,
		not crouching
	)

	# Agachado: somente a forma reduzida fica ativa.
	_set_shape_active(
		crouch_shape,
		crouching
	)


func _set_shape_active(
	collision_shape: CollisionShape2D,
	active: bool
) -> void:
	if collision_shape == null:
		return

	# Mudanças em formas de colisão durante a física
	# devem ser feitas de forma deferred.
	collision_shape.set_deferred(
		"disabled",
		not active
	)

func set_invulnerable(active: bool) -> void:
	invulnerable = active


func is_invulnerable() -> bool:
	return invulnerable
