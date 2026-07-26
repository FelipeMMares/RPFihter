extends Area2D
class_name PlayerHurtBox


signal received_hit(hit_data: HitData)


@export var health: Health
@export var state_machine: StateMachine

var character: CharacterBody2D

@onready var collision_shape: CollisionShape2D = (
	get_node_or_null("CollisionShape2D") as CollisionShape2D
)


func _ready() -> void:
	character = _find_character()

	if character == null:
		printerr(
			"PlayerHurtBox: CharacterBody2D não encontrado."
		)
		return

	if health == null:
		health = character.get_node_or_null(
			"Health"
		) as Health

	if state_machine == null:
		state_machine = character.get_node_or_null(
			"StateMachine"
		) as StateMachine

	# A HurtBox pertence exclusivamente à camada 2.
	collision_layer = 0
	set_collision_layer_value(2, true)

	# A HurtBox não precisa procurar outras áreas.
	collision_mask = 0
	monitoring = false

	# Mas precisa permitir que uma HitBox a encontre.
	monitorable = true

	var shape_found := false

	for child in get_children():
		if child is CollisionShape2D:
			var collision_shape := child as CollisionShape2D
			shape_found = true

			if collision_shape.shape == null:
				printerr(
					"PlayerHurtBox: CollisionShape2D sem Shape."
				)
			else:
				collision_shape.set_deferred(
					"disabled",
					false
				)

				print(
					"PlayerHurtBox Shape | caminho: ",
					collision_shape.get_path(),
					" | shape: ",
					collision_shape.shape,
					" | posição global: ",
					collision_shape.global_position
				)

	if not shape_found:
		printerr(
			"PlayerHurtBox: CollisionShape2D não encontrada."
		)

	print(
		"PlayerHurtBox pronta | caminho: ",
		get_path(),
		" | layer: ",
		collision_layer,
		" | mask: ",
		collision_mask,
		" | monitoring: ",
		monitoring,
		" | monitorable: ",
		monitorable
	)

func receive_hit(hit_data: HitData) -> void:
	if hit_data == null:
		printerr("PlayerHurtBox recebeu HitData nulo.")
		return

	if health == null:
		printerr("PlayerHurtBox: Health não encontrada.")
		return

	if health.is_defeated():
		return

	print(
		"PLAYER RECEBEU GOLPE | dano: ",
		hit_data.damage
	)

	received_hit.emit(hit_data)

	health.take_damage(hit_data.damage)

	if health.is_defeated():
		return

	if state_machine == null:
		printerr(
			"PlayerHurtBox: StateMachine não encontrada."
		)
		return

	state_machine.receive_hit(hit_data)


func get_character() -> CharacterBody2D:
	return character


func _find_character() -> CharacterBody2D:
	var current_node: Node = get_parent()

	while current_node != null:
		if current_node is CharacterBody2D:
			return current_node as CharacterBody2D

		current_node = current_node.get_parent()

	return null
