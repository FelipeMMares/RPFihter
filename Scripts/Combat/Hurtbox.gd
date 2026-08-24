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

	var found_shape: bool = (
		head_shape != null
		and torso_shape != null
		and feet_shape != null
		and crouch_shape != null
	)

	_validate_hurtbox_shapes()
	set_crouching(false)

	if not found_shape:
		printerr(
			"HurtBox sem todas as CollisionShape2D: ",
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

func receive_hit(
	hit_data: HitData,
	attacker: CharacterBody2D = null
) -> int:
	if invulnerable:
		return CombatHitResult.Type.IGNORED

	var character := get_character()

	if character == null:
		return CombatHitResult.Type.IGNORED

	# Guarda o estado ANTES de processar o golpe.
	# Isso é importante porque o golpe pode quebrar
	# a defesa e mudar o estado depois.
	var was_guarding: bool = false

	if state_machine != null:
		var current_state: StringName = (
			state_machine.get_current_state_name()
		)

		var guard_is_active: bool = false

		if character.has_method(
			"is_guard_active"
		):
			guard_is_active = bool(
				character.call(
					"is_guard_active"
				)
			)

		was_guarding = (
			guard_is_active
			and (
				current_state == &"Guard"
				or current_state == &"GuardWhile"
			)
		)

	if character.has_method(
		"receive_combat_hit"
	):
		character.call(
			"receive_combat_hit",
			hit_data,
			attacker
		)

		if was_guarding:
			return CombatHitResult.Type.GUARD

		return CombatHitResult.Type.HIT

	printerr(
		"HurtBox: personagem ",
		character.name,
		" não possui receive_combat_hit()."
	)

	if health == null:
		printerr(
			"HurtBox de ",
			character.name,
			": Health não encontrada."
		)
		return CombatHitResult.Type.IGNORED

	if health.is_defeated():
		return CombatHitResult.Type.IGNORED

	print(
		"PERSONAGEM ATINGIDO | alvo: ",
		character.name,
		" | dano: ",
		hit_data.damage
	)

	health.take_damage(
		hit_data.damage
	)

	if health.is_defeated():
		return CombatHitResult.Type.HIT

	if state_machine == null:
		printerr(
			"HurtBox de ",
			character.name,
			": StateMachine não encontrada."
		)

		return CombatHitResult.Type.HIT

	if state_machine.has_state(
		&"Hurt"
	):
		state_machine.receive_hit(
			hit_data
		)
	else:
		printerr(
			"StateMachine de ",
			character.name,
			" não possui estado Hurt."
		)

	return CombatHitResult.Type.HIT

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
