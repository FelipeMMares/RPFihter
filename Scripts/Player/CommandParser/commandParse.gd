extends Node
class_name CommandParser

@export var commands : Array[CommandSequence] = []
@export var input_buffer : InputBuffer

var root := CommandNode.new()

func _ready() -> void:
	
	for command in commands:
		root.add_sequence(command.inputs, command.name)
