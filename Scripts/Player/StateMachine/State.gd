extends Node
class_name State

signal transition_to(new_state, previous_state)

var animated_sprite : AnimatedSprite2D
var player_controls : PlayerControls
var character : CharacterBody2D

func _enter() -> void:
	pass
	
func _exit() -> void:
	pass

func change_state(state_name: String):
	transition_to.emit(state_name, name)
