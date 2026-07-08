extends Node
class_name State

signal transition_to(new_state, previous_state)
signal move(direction: Vector2)
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
