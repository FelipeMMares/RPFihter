extends Area2D
class_name HurtBox

signal hurt(hit_data: HitData)

var character: CharacterBody2D


func _ready() -> void:
	character = _find_character()

	if character == null:
		printerr(
			"HurtBox ",
			name,
			": CharacterBody2D proprietário não encontrado."
		)
		return

	print(
		"HurtBox pronta: ",
		name,
		" | personagem: ",
		character.name
	)


func receive_hit(hit_data: HitData) -> void:
	if hit_data == null:
		printerr(
			"HurtBox ",
			name,
			": recebeu HitData nulo."
		)
		return

	hurt.emit(hit_data)


func get_character() -> CharacterBody2D:
	return character


func _find_character() -> CharacterBody2D:
	var current_node: Node = get_parent()

	while current_node != null:
		if current_node is CharacterBody2D:
			return current_node as CharacterBody2D

		current_node = current_node.get_parent()

	return null
