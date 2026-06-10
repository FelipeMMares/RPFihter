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
