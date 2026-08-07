extends Node
class_name State

signal transition_to(new_state)
signal move(direction: Vector2)
signal jump()
signal play_animation(name: String, backwards: bool)

var player_controls : PlayerControls
var command_parser : CommandParser
var player_input_enabled: bool = true

func _enter() -> void:
	pass
	
func _exit() -> void:
	pass

func _animation_finished() -> void:
	pass

func check_special_move() -> bool:
	if command_parser == null:
		return false

	var move_name: String = (
		command_parser.get_current_special_move()
	)

	if move_name.is_empty():
		return false

	print(
		"🔥 Movimento detectado: ",
		move_name
	)

	# Impede que combos normais sejam tratados
	# como estados de ataques especiais.
	if not command_parser.is_special_move(
		move_name
	):
		print(
			"Movimento reconhecido, mas não é especial: ",
			move_name
		)
		return false

	var state_machine := (
		get_parent() as StateMachine
	)

	if state_machine == null:
		printerr(
			"State: não foi possível encontrar a StateMachine."
		)
		return false

	var special_state := StringName(
		move_name
	)

	if not state_machine.has_state(
		special_state
	):
		printerr(
			"Especial reconhecido, mas o estado não existe: ",
			special_state
		)
		return false

	print(
		"✅ Entrando no estado especial: ",
		special_state
	)

	var character := (
		get_parent().get_parent()
		as CharacterBody2D
	)

	if character == null:
		printerr(
			"State: personagem não encontrado."
		)
		return false

	if not character.has_method(
		"request_special_attack"
	):
		printerr(
			character.name,
			" não possui request_special_attack()."
		)
		return false

	var special_started: bool = bool(
		character.call(
			"request_special_attack",
			special_state
		)
	)

	return special_started


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
