extends Area2D
class_name HurtBox


@export var health: Health
@export var state_machine: StateMachine

var character: CharacterBody2D


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

	for child in get_children():
		if child is CollisionShape2D:
			var collision_shape := child as CollisionShape2D
			found_shape = true

			if collision_shape.shape == null:
				printerr(
					"HurtBox sem Shape: ",
					collision_shape.get_path()
				)
			else:
				collision_shape.set_deferred(
					"disabled",
					false
				)

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


func receive_hit(hit_data: HitData) -> void:
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
