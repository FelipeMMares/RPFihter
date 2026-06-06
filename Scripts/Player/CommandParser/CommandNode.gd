extends RefCounted
class_name CommandNode

var children : Dictionary[String, CommandNode] = {}

var resulting_move : String = ""

func add_sequence(sequence: Array[String],
				  move_name : String) -> void:
	
	var current_node : CommandNode = self
	
	for action in sequence:
		if not current_node.children.has(action):
			current_node.children[action] = CommandNode.new()
		current_node = current_node.children[action]
	
	current_node.resulting_move = move_name
	
