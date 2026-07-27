extends Node
class_name State

signal transition_to(new_state, previous_state)
signal move(direction: Vector2)
signal jump()
signal play_animation(name: String, backwards: bool)

var player_controls : PlayerControls
var command_parser : CommandParser

func _enter() -> void:
	pass
	
func _exit() -> void:
	pass

func _animation_finished() -> void:
	pass

func check_special_move():

	if command_parser == null:
		return

	var move = command_parser.get_current_special_move()

	if move == "":
		return

	print("🔥 Movimento detectado:", move)

	match move:

		"teste_combo":
			print("Combo detectado!")

		"hadouken":
			print("Executar Hadouken")

		"shoryuken":
			print("Executar Shoryuken")

func set_crouching_hurtbox(active: bool) -> void:
	var character := (
		get_parent().get_parent()
		as CharacterBody2D
	)

	if character == null:
		printerr(
			name,
			": personagem não encontrado."
		)
		return

	if not character.has_method("set_crouching"):
		printerr(
			character.name,
			" não possui set_crouching()."
		)
		return

	character.call(
		"set_crouching",
		active
	)
