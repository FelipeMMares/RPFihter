extends Node
class_name CommandParser

@export var commands : Array[CommandSequence] = []
@export var input_buffer : InputBuffer

var root := CommandNode.new()

func _ready() -> void:
	
	for command in commands:
		if command and command.is_valid():
			root.add_sequence(command.inputs, command.name)

func get_current_special_move() -> String:
	var current_node = root
	var current_frame = Engine.get_physics_frames()
	
	for i in range(input_buffer.buffer.size()-1, -1, -1):
		var input = input_buffer.get_input_at(i)
		
		if current_node.children.has(input.action_name):
			current_node = current_node.children[input.action_name]
			
			if current_node.resulting_move != "":
				printerr("funfou!")
				input_buffer.buffer.clear()
				return current_node.resulting_move
		
		else:
			break
	
	return ""
